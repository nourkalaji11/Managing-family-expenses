<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * الثابت الوحيد الذي لا يجوز أن ينكسر: رصيد الحساب يساوي دائماً أثر عملياته.
 *
 * ---------------------------------------------------------------------------
 * ثلاث دوال كانت تخرقه:
 *   - update كانت جسماً فارغاً يرد 200 دون أن يكتب شيئاً، فالنموذج يبلّغ
 *     المستخدم بنجاح الحفظ بينما لم يتغيّر شيء.
 *   - update بعد تنفيذها كان يجب أن تلغي أثر المبلغ القديم قبل تطبيق الجديد،
 *     وإلا بقي أثر المبلغ السابق في الرصيد إلى الأبد.
 *   - destroy كانت تحذف دون أن تعيد ما اقتطعته.
 *
 * كل اختبار هنا يفشل على واحدة من تلك الحالات.
 * ---------------------------------------------------------------------------
 */
class BalanceIntegrityTest extends TestCase
{
    use RefreshDatabase;

    private User $parent;
    private Account $wallet;
    private Account $bank;
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

        $this->category = Category::create(['name' => 'Food']);

        $this->wallet = Account::create([
            'name' => 'Wallet',
            'balance' => 1000,
            'user_id' => $this->parent->id,
        ]);
        $this->bank = Account::create([
            'name' => 'Bank',
            'balance' => 5000,
            'user_id' => $this->parent->id,
        ]);
    }

    private function balance(Account $account): float
    {
        return (float) $account->fresh()->balance;
    }

    private function payload(array $overrides = []): array
    {
        return array_merge([
            'account_id' => $this->wallet->id,
            'category_id' => $this->category->id,
            'amount' => 200,
            'type' => 'expense',
            'description' => 'test',
            'date' => now()->toDateString(),
        ], $overrides);
    }

    // -------------------------------------------------------------------------
    // store
    // -------------------------------------------------------------------------

    public function test_an_expense_lowers_the_balance_and_an_income_raises_it(): void
    {
        $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['amount' => 200]))
            ->assertCreated();
        $this->assertSame(800.0, $this->balance($this->wallet));

        $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload([
                'amount' => 50,
                'type' => 'income',
            ]))
            ->assertCreated();
        $this->assertSame(850.0, $this->balance($this->wallet));
    }

    // -------------------------------------------------------------------------
    // update
    // -------------------------------------------------------------------------

    public function test_editing_an_amount_reverses_the_old_one_before_applying_the_new(): void
    {
        $created = $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['amount' => 200]))
            ->assertCreated()
            ->json('data.id');

        $this->assertSame(800.0, $this->balance($this->wallet));

        $this->actingAs($this->parent)
            ->putJson("/api/transactions/{$created}", $this->payload(['amount' => 50]))
            ->assertOk();

        // 1000 - 50, not 1000 - 200 - 50 and not an unchanged 800.
        $this->assertSame(950.0, $this->balance($this->wallet));
    }

    public function test_editing_actually_writes_the_row(): void
    {
        // update() used to be an empty body that returned 200 without touching
        // the database — the worst failure mode for a form, because the UI
        // reports success every time.
        $created = $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['description' => 'before']))
            ->json('data.id');

        $this->actingAs($this->parent)
            ->putJson("/api/transactions/{$created}", $this->payload([
                'description' => 'after',
            ]))
            ->assertOk();

        $this->assertSame('after', Transaction::find($created)->description);
    }

    public function test_moving_a_transaction_to_another_account_moves_the_effect_with_it(): void
    {
        $created = $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['amount' => 300]))
            ->json('data.id');

        $this->assertSame(700.0, $this->balance($this->wallet));

        $this->actingAs($this->parent)
            ->putJson("/api/transactions/{$created}", $this->payload([
                'amount' => 300,
                'account_id' => $this->bank->id,
            ]))
            ->assertOk();

        $this->assertSame(1000.0, $this->balance($this->wallet));
        $this->assertSame(4700.0, $this->balance($this->bank));
    }

    public function test_changing_the_amount_on_the_same_account_does_not_lose_one_of_the_two_writes(): void
    {
        // Same-account edits load the model once rather than twice: two
        // instances of the same row would each save, and the second would
        // overwrite the first.
        $created = $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['amount' => 100]))
            ->json('data.id');

        $this->assertSame(900.0, $this->balance($this->wallet));

        $this->actingAs($this->parent)
            ->putJson("/api/transactions/{$created}", $this->payload([
                'amount' => 400,
                'type' => 'income',
            ]))
            ->assertOk();

        // 900 + 100 (reverse the expense, back to the opening 1000) + 400
        // (apply the income). Losing either write would land on 1000 or 1300.
        $this->assertSame(1400.0, $this->balance($this->wallet));
    }

    // -------------------------------------------------------------------------
    // destroy
    // -------------------------------------------------------------------------

    public function test_deleting_a_transaction_restores_the_balance(): void
    {
        $created = $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['amount' => 250]))
            ->json('data.id');

        $this->assertSame(750.0, $this->balance($this->wallet));

        $this->actingAs($this->parent)
            ->deleteJson("/api/transactions/{$created}")
            ->assertOk();

        $this->assertSame(1000.0, $this->balance($this->wallet));
        $this->assertDatabaseMissing('transactions', ['id' => $created]);
    }

    // -------------------------------------------------------------------------
    // transfers
    // -------------------------------------------------------------------------

    public function test_a_transfer_moves_both_balances_and_nets_to_zero(): void
    {
        $this->actingAs($this->parent)
            ->postJson('/api/transfers', [
                'from_account_id' => $this->wallet->id,
                'to_account_id' => $this->bank->id,
                'amount' => 300,
                'category_id' => $this->category->id,
                'date' => now()->toDateString(),
            ])
            ->assertCreated();

        $this->assertSame(700.0, $this->balance($this->wallet));
        $this->assertSame(5300.0, $this->balance($this->bank));

        // The family is no richer or poorer.
        $this->assertSame(6000.0, (float) Account::sum('balance'));

        // Two rows, one group.
        $legs = Transaction::whereNotNull('transfer_group_id')->get();
        $this->assertCount(2, $legs);
        $this->assertCount(1, $legs->pluck('transfer_group_id')->unique());
    }

    public function test_a_transfer_leg_cannot_be_edited_or_deleted_on_its_own(): void
    {
        $group = $this->actingAs($this->parent)
            ->postJson('/api/transfers', [
                'from_account_id' => $this->wallet->id,
                'to_account_id' => $this->bank->id,
                'amount' => 300,
                'category_id' => $this->category->id,
                'date' => now()->toDateString(),
            ])
            ->json('data.transfer_group_id');

        $leg = Transaction::where('transfer_group_id', $group)->first();

        // Either operation on one leg alone leaves the other on its old value
        // and one balance wrong, so both are refused.
        $this->actingAs($this->parent)
            ->putJson("/api/transactions/{$leg->id}", $this->payload())
            ->assertStatus(422);

        $this->actingAs($this->parent)
            ->deleteJson("/api/transactions/{$leg->id}")
            ->assertStatus(422);

        $this->assertSame(700.0, $this->balance($this->wallet));
    }

    public function test_undoing_a_transfer_restores_both_balances(): void
    {
        $group = $this->actingAs($this->parent)
            ->postJson('/api/transfers', [
                'from_account_id' => $this->wallet->id,
                'to_account_id' => $this->bank->id,
                'amount' => 300,
                'category_id' => $this->category->id,
                'date' => now()->toDateString(),
            ])
            ->json('data.transfer_group_id');

        $this->actingAs($this->parent)
            ->deleteJson("/api/transfers/{$group}")
            ->assertOk();

        $this->assertSame(1000.0, $this->balance($this->wallet));
        $this->assertSame(5000.0, $this->balance($this->bank));
        $this->assertSame(0, Transaction::whereNotNull('transfer_group_id')->count());
    }

    public function test_a_transfer_to_the_same_account_is_rejected(): void
    {
        $this->actingAs($this->parent)
            ->postJson('/api/transfers', [
                'from_account_id' => $this->wallet->id,
                'to_account_id' => $this->wallet->id,
                'amount' => 300,
                'category_id' => $this->category->id,
                'date' => now()->toDateString(),
            ])
            ->assertStatus(422);

        $this->assertSame(1000.0, $this->balance($this->wallet));
    }

    // -------------------------------------------------------------------------
    // delete guards on the resources a transaction points at
    // -------------------------------------------------------------------------

    public function test_an_account_holding_transactions_cannot_be_deleted(): void
    {
        // The foreign key cascades, so an unguarded delete would silently take
        // the family's financial history with it.
        $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload())
            ->assertCreated();

        $this->actingAs($this->parent)
            ->deleteJson("/api/accounts/{$this->wallet->id}")
            ->assertStatus(409);

        $this->assertDatabaseHas('accounts', ['id' => $this->wallet->id]);
    }

    public function test_a_category_in_use_cannot_be_deleted(): void
    {
        $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload())
            ->assertCreated();

        $this->actingAs($this->parent)
            ->deleteJson("/api/categories/{$this->category->id}")
            ->assertStatus(409);

        $this->assertDatabaseHas('categories', ['id' => $this->category->id]);
    }
}
