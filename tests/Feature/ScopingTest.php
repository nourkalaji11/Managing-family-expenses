<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Budget;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * ما يحق لكل دور رؤيته والوصول إليه.
 *
 * ---------------------------------------------------------------------------
 * كل دوال index كانت تعمل بلا شرط `where`، فأي مستخدم مسجَّل دخوله يقرأ بيانات
 * كل العائلات المالية. هذه الاختبارات هي ما يمنع عودة ذلك بصمت: كل واحد منها
 * يفشل على الكود السابق لـScopesToFamily.
 *
 * القصر على index وحده لا يكفي — يكفي تخمين رقم في المسار — ولهذا تُختبر
 * show وupdate وdestroy مستقلةً عن القائمة.
 * ---------------------------------------------------------------------------
 */
class ScopingTest extends TestCase
{
    use RefreshDatabase;

    private User $parent;
    private User $child;
    private Account $account;
    private Category $category;

    protected function setUp(): void
    {
        parent::setUp();

        $this->parent = User::create([
            'name' => 'Parent',
            'email' => 'parent@test.local',
            'password' => Hash::make('password123'),
            'role' => 'parent',
        ]);

        $this->child = User::create([
            'name' => 'Child',
            'email' => 'child@test.local',
            'password' => Hash::make('password123'),
            'role' => 'member',
            'spending_limit' => 500,
        ]);

        $this->category = Category::create(['name' => 'Food']);
        $this->account = Account::create([
            'name' => 'Shared wallet',
            'balance' => 1000,
            'user_id' => $this->parent->id,
        ]);
    }

    private function transactionFor(User $owner, float $amount = 100): Transaction
    {
        return Transaction::create([
            'amount' => $amount,
            'type' => 'expense',
            'description' => 'x',
            'date' => now()->toDateString(),
            'user_id' => $owner->id,
            'account_id' => $this->account->id,
            'category_id' => $this->category->id,
        ]);
    }

    private function budgetFor(User $owner): Budget
    {
        return Budget::create([
            'limit_amount' => 300,
            'current_spending' => 0,
            'start_date' => now()->startOfMonth()->toDateString(),
            'end_date' => now()->endOfMonth()->toDateString(),
            'user_id' => $owner->id,
            'category_id' => $this->category->id,
        ]);
    }

    // -------------------------------------------------------------------------
    // Index scoping
    // -------------------------------------------------------------------------

    public function test_parent_sees_every_transaction_and_member_sees_only_their_own(): void
    {
        $this->transactionFor($this->parent);
        $this->transactionFor($this->parent);
        $this->transactionFor($this->child);

        $this->actingAs($this->parent)
            ->getJson('/api/transactions')
            ->assertOk()
            ->assertJsonCount(3, 'data');

        $this->actingAs($this->child)
            ->getJson('/api/transactions')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_the_user_id_filter_narrows_but_cannot_widen_a_members_view(): void
    {
        $this->transactionFor($this->parent);
        $this->transactionFor($this->child);

        // Asking for the parent's rows must not hand them over: the filter is
        // applied on top of the scope, never instead of it.
        $this->actingAs($this->child)
            ->getJson('/api/transactions?user_id=' . $this->parent->id)
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_parent_sees_every_budget_and_member_sees_only_their_own(): void
    {
        $this->budgetFor($this->parent);
        $this->budgetFor($this->child);

        $this->actingAs($this->parent)
            ->getJson('/api/budgets')->assertOk()->assertJsonCount(2, 'data');

        $this->actingAs($this->child)
            ->getJson('/api/budgets')->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_accounts_stay_shared_so_a_member_has_somewhere_to_spend_from(): void
    {
        // Deliberately NOT scoped: accounts.user_id records who created an
        // account, not who may spend from it. Scoping it would leave a member
        // with no account to book a transaction against, which is the whole
        // point of the app for them.
        $this->actingAs($this->parent)
            ->getJson('/api/accounts')->assertOk()->assertJsonCount(1, 'data');

        $this->actingAs($this->child)
            ->getJson('/api/accounts')->assertOk()->assertJsonCount(1, 'data');
    }

    // -------------------------------------------------------------------------
    // Direct access by id — scoping the list does not protect the row
    // -------------------------------------------------------------------------

    public function test_a_member_cannot_read_update_or_delete_another_users_transaction(): void
    {
        $theirs = $this->transactionFor($this->parent);

        $payload = [
            'account_id' => $this->account->id,
            'category_id' => $this->category->id,
            'amount' => 1,
            'type' => 'expense',
            'date' => now()->toDateString(),
        ];

        // 404 rather than 403 throughout: a 403 would confirm the row exists,
        // which is itself information the caller is not entitled to.
        $this->actingAs($this->child)->getJson("/api/transactions/{$theirs->id}")
            ->assertNotFound();
        $this->actingAs($this->child)->putJson("/api/transactions/{$theirs->id}", $payload)
            ->assertNotFound();
        $this->actingAs($this->child)->deleteJson("/api/transactions/{$theirs->id}")
            ->assertNotFound();

        $this->assertDatabaseHas('transactions', ['id' => $theirs->id]);
    }

    public function test_a_parent_can_read_a_members_transaction(): void
    {
        $theirs = $this->transactionFor($this->child);

        $this->actingAs($this->parent)
            ->getJson("/api/transactions/{$theirs->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $theirs->id);
    }

    public function test_a_member_cannot_delete_another_users_budget(): void
    {
        $theirs = $this->budgetFor($this->parent);

        $this->actingAs($this->child)
            ->deleteJson("/api/budgets/{$theirs->id}")
            ->assertNotFound();

        $this->assertDatabaseHas('budgets', ['id' => $theirs->id]);
    }

    // -------------------------------------------------------------------------
    // Family listing and limits
    // -------------------------------------------------------------------------

    public function test_a_member_listing_the_family_sees_only_themselves(): void
    {
        $this->actingAs($this->parent)
            ->getJson('/api/users')->assertOk()->assertJsonCount(2, 'data');

        $this->actingAs($this->child)
            ->getJson('/api/users')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $this->child->id);
    }

    public function test_only_a_parent_may_set_a_spending_limit(): void
    {
        $this->actingAs($this->child)
            ->putJson("/api/users/{$this->child->id}/limit", ['spending_limit' => 9999])
            ->assertForbidden();

        $this->actingAs($this->parent)
            ->putJson("/api/users/{$this->child->id}/limit", ['spending_limit' => 750])
            ->assertOk();

        $this->assertEquals(750, $this->child->fresh()->spending_limit);
    }

    public function test_a_limit_cannot_be_set_on_a_parent(): void
    {
        // A parent is not capped by TransactionController::store, so a ceiling
        // on one is a number that reads as a constraint while constraining
        // nothing.
        $this->actingAs($this->parent)
            ->putJson("/api/users/{$this->parent->id}/limit", ['spending_limit' => 500])
            ->assertStatus(422);
    }

    // -------------------------------------------------------------------------
    // Registration
    // -------------------------------------------------------------------------

    public function test_a_client_cannot_self_register_with_an_arbitrary_role(): void
    {
        // `role` used to be `nullable|string`, so editing one field in the
        // request was enough to become an admin.
        $this->postJson('/api/register', [
            'name' => 'Sneaky',
            'email' => 'sneaky@test.local',
            'password' => 'password123',
            'role' => 'admin',
        ])->assertStatus(422);

        $this->assertDatabaseMissing('users', ['email' => 'sneaky@test.local']);
    }

    public function test_a_role_created_as_parent_is_treated_as_a_parent(): void
    {
        // The app sends 'parent' while the old code compared against 'admin'
        // literally, so a parent account made in the app got the member
        // dashboard and could not manage limits.
        $this->postJson('/api/register', [
            'name' => 'New parent',
            'email' => 'new@test.local',
            'password' => 'password123',
            'role' => 'parent',
        ])->assertCreated();

        $created = User::firstWhere('email', 'new@test.local');
        $this->assertTrue($created->isParent());

        $this->actingAs($created)
            ->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonStructure(['data' => ['total_balance', 'alerts']]);
    }
}
