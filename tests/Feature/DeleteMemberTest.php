<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Budget;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * حذف ابن من العائلة — DELETE /api/users/{id}.
 *
 * ---------------------------------------------------------------------------
 * أخطر ما في هذه النقطة ليس الصلاحية بل الـ cascade: accounts وbudgets
 * وtransactions كلها معرَّفة onDelete('cascade')، فحذف مستخدم واحد يمكن أن
 * يمحو حساب العائلة الرئيسي وتاريخه كاملاً لمجرد أن ذلك الابن هو من أنشأه.
 *
 * لذلك الاختبارات هنا تُثبت شيئين معاً: أن الحذف يعمل لمن يحق حذفه، وأن ما لا
 * يجوز أن يُمحى لا يُمحى — لا بالحذف ولا بالتتالي.
 * ---------------------------------------------------------------------------
 */
class DeleteMemberTest extends TestCase
{
    use RefreshDatabase;

    private User $parent;
    private User $child;

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
            'spending_limit' => 1500,
        ]);
    }

    private function accountFor(User $user): Account
    {
        return Account::create([
            'name' => 'Shared current account',
            'balance' => 1000,
            'user_id' => $user->id,
        ]);
    }

    private function categoryFor(User $user): Category
    {
        return Category::create([
            'name' => 'Food',
            'user_id' => $user->id,
        ]);
    }

    public function test_a_parent_can_delete_a_child_with_no_transactions(): void
    {
        Sanctum::actingAs($this->parent);

        $this->deleteJson("/api/users/{$this->child->id}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('users', ['id' => $this->child->id]);
    }

    public function test_deleting_a_child_revokes_their_sessions(): void
    {
        $token = $this->child->createToken('phone')->plainTextToken;
        $this->assertSame(1, $this->child->tokens()->count());

        Sanctum::actingAs($this->parent);
        $this->deleteJson("/api/users/{$this->child->id}")->assertStatus(200);

        $this->assertDatabaseCount('personal_access_tokens', 0);
        $this->assertNotEmpty($token);
    }

    public function test_a_child_with_transactions_is_refused_and_kept(): void
    {
        $account = $this->accountFor($this->parent);
        $category = $this->categoryFor($this->parent);

        Transaction::create([
            'amount' => 100,
            'type' => 'expense',
            'date' => now()->toDateString(),
            'account_id' => $account->id,
            'category_id' => $category->id,
            'user_id' => $this->child->id,
        ]);

        Sanctum::actingAs($this->parent);

        $this->deleteJson("/api/users/{$this->child->id}")
            ->assertStatus(422)
            ->assertJsonPath('transactions_count', 1);

        // لا الابن ذهب ولا معاملته.
        $this->assertDatabaseHas('users', ['id' => $this->child->id]);
        $this->assertDatabaseCount('transactions', 1);
    }

    public function test_shared_accounts_created_by_the_child_survive_and_move_to_the_parent(): void
    {
        $account = $this->accountFor($this->child);

        Sanctum::actingAs($this->parent);
        $this->deleteJson("/api/users/{$this->child->id}")->assertStatus(200);

        // بدون النقل كان الـ cascade سيمحو حساب العائلة مع الابن.
        $this->assertDatabaseHas('accounts', [
            'id' => $account->id,
            'user_id' => $this->parent->id,
        ]);
    }

    public function test_budgets_created_by_the_child_survive_and_move_to_the_parent(): void
    {
        $category = $this->categoryFor($this->parent);
        $budget = Budget::create([
            'limit_amount' => 500,
            'current_spending' => 0,
            'start_date' => now()->startOfMonth()->toDateString(),
            'end_date' => now()->endOfMonth()->toDateString(),
            'user_id' => $this->child->id,
            'category_id' => $category->id,
        ]);

        Sanctum::actingAs($this->parent);
        $this->deleteJson("/api/users/{$this->child->id}")->assertStatus(200);

        $this->assertDatabaseHas('budgets', [
            'id' => $budget->id,
            'user_id' => $this->parent->id,
        ]);
    }

    public function test_a_member_cannot_delete_anyone(): void
    {
        $other = User::create([
            'name' => 'Sibling',
            'email' => 'sibling@test.local',
            'password' => Hash::make('password123'),
            'role' => 'member',
        ]);

        Sanctum::actingAs($this->child);

        $this->deleteJson("/api/users/{$other->id}")->assertStatus(403);
        $this->assertDatabaseHas('users', ['id' => $other->id]);
    }

    public function test_a_parent_cannot_delete_another_parent(): void
    {
        $otherParent = User::create([
            'name' => 'Other parent',
            'email' => 'parent2@test.local',
            'password' => Hash::make('password123'),
            'role' => 'parent',
        ]);

        Sanctum::actingAs($this->parent);

        $this->deleteJson("/api/users/{$otherParent->id}")->assertStatus(422);
        $this->assertDatabaseHas('users', ['id' => $otherParent->id]);
    }

    public function test_a_parent_cannot_delete_themselves(): void
    {
        Sanctum::actingAs($this->parent);

        $this->deleteJson("/api/users/{$this->parent->id}")->assertStatus(422);
        $this->assertDatabaseHas('users', ['id' => $this->parent->id]);
    }

    public function test_deleting_an_unknown_member_is_a_404(): void
    {
        Sanctum::actingAs($this->parent);

        $this->deleteJson('/api/users/999999')->assertStatus(404);
    }

    public function test_the_endpoint_requires_authentication(): void
    {
        $this->deleteJson("/api/users/{$this->child->id}")->assertStatus(401);
        $this->assertDatabaseHas('users', ['id' => $this->child->id]);
    }
}
