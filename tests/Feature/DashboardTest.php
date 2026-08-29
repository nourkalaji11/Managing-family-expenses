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
 * لوحة التحكم، والعدّادات التي أغنت العميل عن الحساب على الجهاز.
 *
 * كانت /dashboard ترد بأربعة أرقام لا تكفي لرسم الشاشة، فيتجاهلها التطبيق
 * ويجمّع كل شيء بنفسه من /accounts و/transactions. هذه الاختبارات تثبّت أن ما
 * يعود الآن يطابق ما كان العميل يحسبه، بما في ذلك الحالات التي كان يخطئ فيها
 * ساكتاً — التحويلات، والتنبيهات التي لم تكن تظهر أبداً.
 */
class DashboardTest extends TestCase
{
    use RefreshDatabase;

    private User $parent;
    private User $child;
    private Account $wallet;
    private Account $bank;
    private array $categories = [];

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

        foreach (['Food', 'Rent', 'Transport', 'Shopping'] as $name) {
            $this->categories[$name] = Category::create(['name' => $name]);
        }

        $this->wallet = Account::create([
            'name' => 'Wallet',
            'balance' => 1000,
            'user_id' => $this->parent->id,
        ]);
        $this->bank = Account::create([
            'name' => 'Bank',
            'balance' => 4000,
            'user_id' => $this->parent->id,
        ]);
    }


    /**
     * قيمة رقمية من الاستجابة، مقارَنة بالقيمة لا بالنوع.
     *
     * json_encode يسقط الكسر الصفري، فـ5000.0 تصل كـ5000 صحيحاً — و
     * assertJsonPath يقارن مقارنة صارمة فتفشل على كل رقم عشري.
     */
    private function assertJsonNumber($response, string $path, float $expected): void
    {
        $this->assertEqualsWithDelta($expected, $response->json($path), 0.001, $path);
    }

    private function tx(
        float $amount,
        string $type,
        string $category,
        ?User $owner = null,
        ?string $group = null,
    ): Transaction {
        return Transaction::create([
            'amount' => $amount,
            'type' => $type,
            'description' => 'x',
            'date' => now()->toDateString(),
            'user_id' => ($owner ?? $this->parent)->id,
            'account_id' => $this->wallet->id,
            'category_id' => $this->categories[$category]->id,
            'transfer_group_id' => $group,
        ]);
    }

    // -------------------------------------------------------------------------
    // Totals
    // -------------------------------------------------------------------------

    public function test_the_parent_dashboard_carries_everything_the_screen_draws(): void
    {
        $this->tx(1000, 'income', 'Food');
        $this->tx(300, 'expense', 'Rent');

        $this->actingAs($this->parent)
            ->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'role',
                    'total_balance',
                    'income',
                    'expenses',
                    'remaining',
                    'breakdown',
                    'recent_transactions',
                    'primary_account',
                    'alerts',
                ],
            ])
            ;

        $response = $this->actingAs($this->parent)->getJson('/api/dashboard');
        $this->assertJsonNumber($response, 'data.total_balance', 5000);
        $this->assertJsonNumber($response, 'data.income', 1000);
        $this->assertJsonNumber($response, 'data.expenses', 300);
        $this->assertJsonNumber($response, 'data.remaining', 700);
    }

    public function test_transfers_are_excluded_from_income_and_expenses(): void
    {
        $this->tx(500, 'income', 'Food');
        $this->tx(200, 'expense', 'Rent');

        // Both legs of one transfer. Counting them would add 300 to income and
        // 300 to expenses without a riyal entering or leaving the family.
        $this->tx(300, 'expense', 'Food', null, 'group-1');
        $this->tx(300, 'income', 'Food', null, 'group-1');

        $response = $this->actingAs($this->parent)->getJson('/api/dashboard')->assertOk();
        $this->assertJsonNumber($response, 'data.income', 500);
        $this->assertJsonNumber($response, 'data.expenses', 200);
    }

    public function test_remaining_goes_negative_rather_than_being_floored(): void
    {
        $this->tx(100, 'income', 'Food');
        $this->tx(400, 'expense', 'Rent');

        // Flooring it at zero would tell a family that overspent that they
        // broke even.
        $response = $this->actingAs($this->parent)->getJson('/api/dashboard');
        $this->assertJsonNumber($response, 'data.remaining', -300);
    }

    // -------------------------------------------------------------------------
    // Breakdown
    // -------------------------------------------------------------------------

    public function test_the_breakdown_keeps_the_top_three_and_folds_the_rest_into_other(): void
    {
        $this->tx(400, 'expense', 'Rent');
        $this->tx(300, 'expense', 'Food');
        $this->tx(200, 'expense', 'Transport');
        $this->tx(100, 'expense', 'Shopping');

        $breakdown = $this->actingAs($this->parent)
            ->getJson('/api/dashboard')
            ->assertOk()
            ->json('data.breakdown');

        $this->assertCount(4, $breakdown);

        // Ordered by spend, so the ring reads largest first.
        $this->assertSame('Rent', $breakdown[0]['category']);
        $this->assertEqualsWithDelta(400, $breakdown[0]['total'], 0.001);
        $this->assertEqualsWithDelta(0.4, $breakdown[0]['fraction'], 0.001);

        // The fourth is the synthetic slice: no row in `categories`, which is
        // what a null category_id signals to the client.
        $this->assertTrue($breakdown[3]['is_other']);
        $this->assertNull($breakdown[3]['category_id']);
        $this->assertEqualsWithDelta(100, $breakdown[3]['total'], 0.001);

        // The ring always closes.
        $this->assertEqualsWithDelta(
            1.0,
            array_sum(array_column($breakdown, 'fraction')),
            0.001
        );
    }

    public function test_the_breakdown_is_empty_when_nothing_was_spent(): void
    {
        $this->tx(500, 'income', 'Food');

        $this->actingAs($this->parent)
            ->getJson('/api/dashboard')
            ->assertJsonCount(0, 'data.breakdown');
    }

    public function test_recent_transactions_are_the_three_newest(): void
    {
        foreach (range(1, 5) as $i) {
            $this->tx($i * 10, 'expense', 'Food');
        }

        $this->actingAs($this->parent)
            ->getJson('/api/dashboard')
            ->assertJsonCount(3, 'data.recent_transactions')
            // Eager-loaded, so the client can render the account and category
            // names without a second request.
            ->assertJsonStructure([
                'data' => ['recent_transactions' => [['account', 'category']]],
            ]);
    }

    // -------------------------------------------------------------------------
    // Role
    // -------------------------------------------------------------------------

    public function test_a_member_sees_only_their_own_figures_plus_their_ceiling(): void
    {
        $this->tx(900, 'expense', 'Rent');                 // parent's
        $this->tx(60, 'expense', 'Food', $this->child);    // theirs

        $response = $this->actingAs($this->child)->getJson('/api/dashboard')->assertOk();

        $response->assertJsonPath('data.role', 'member');
        $this->assertJsonNumber($response, 'data.expenses', 60);
        $this->assertJsonNumber($response, 'data.spending_limit', 500);
        $this->assertJsonNumber($response, 'data.spent_of_limit', 60);
        $this->assertJsonNumber($response, 'data.remaining_limit', 440);

        // Alerts are a parent's oversight tool.
        $this->assertArrayNotHasKey('alerts', $response->json('data'));
    }

    public function test_a_transfer_does_not_eat_into_the_reported_remaining_limit(): void
    {
        $this->tx(100, 'expense', 'Food', $this->child);
        $this->tx(300, 'expense', 'Food', $this->child, 'group-1');

        // The figure shown has to match the rule that blocks the spend,
        // otherwise the user is told they have less than they can actually use.
        $response = $this->actingAs($this->child)->getJson('/api/dashboard');
        $this->assertJsonNumber($response, 'data.spent_of_limit', 100);
        $this->assertJsonNumber($response, 'data.remaining_limit', 400);
    }

    // -------------------------------------------------------------------------
    // Alerts
    // -------------------------------------------------------------------------

    public function test_alerts_report_budgets_that_are_actually_over(): void
    {
        Budget::create([
            'limit_amount' => 100,
            'current_spending' => 0,
            'start_date' => now()->startOfMonth()->toDateString(),
            'end_date' => now()->endOfMonth()->toDateString(),
            'user_id' => $this->child->id,
            'category_id' => $this->categories['Food']->id,
        ]);

        $this->tx(150, 'expense', 'Food', $this->child);

        // The old filter compared against budgets.current_spending, a column
        // nothing writes — so this array was always empty, and a parent was
        // never told about anything.
        $alerts = $this->actingAs($this->parent)
            ->getJson('/api/dashboard')
            ->assertOk()
            ->json('data.alerts');

        $this->assertCount(1, $alerts);
        $this->assertSame('Child', $alerts[0]['user_name']);
        $this->assertSame('Food', $alerts[0]['category']);
        $this->assertEqualsWithDelta(50, $alerts[0]['over_by'], 0.001);
    }

    public function test_a_budget_within_its_limit_raises_no_alert(): void
    {
        Budget::create([
            'limit_amount' => 500,
            'current_spending' => 0,
            'start_date' => now()->startOfMonth()->toDateString(),
            'end_date' => now()->endOfMonth()->toDateString(),
            'user_id' => $this->parent->id,
            'category_id' => $this->categories['Food']->id,
        ]);

        $this->tx(100, 'expense', 'Food');

        $this->actingAs($this->parent)
            ->getJson('/api/dashboard')
            ->assertJsonCount(0, 'data.alerts');
    }

    // -------------------------------------------------------------------------
    // Counts that used to be computed on the device
    // -------------------------------------------------------------------------

    public function test_accounts_carry_their_transaction_count(): void
    {
        $this->tx(10, 'expense', 'Food');
        $this->tx(20, 'expense', 'Food');

        $accounts = $this->actingAs($this->parent)
            ->getJson('/api/accounts')
            ->assertOk()
            ->json('data');

        $wallet = collect($accounts)->firstWhere('id', $this->wallet->id);
        $bank = collect($accounts)->firstWhere('id', $this->bank->id);

        $this->assertSame(2, $wallet['transactions_count']);
        $this->assertSame(0, $bank['transactions_count']);
    }

    public function test_categories_carry_transaction_and_budget_counts_excluding_transfers(): void
    {
        $this->tx(10, 'expense', 'Food');
        // A transfer's category is filler the form had to pick, so counting it
        // would inflate an unrelated category's tile.
        $this->tx(50, 'expense', 'Food', null, 'group-1');

        Budget::create([
            'limit_amount' => 100,
            'current_spending' => 0,
            'start_date' => now()->startOfMonth()->toDateString(),
            'end_date' => now()->endOfMonth()->toDateString(),
            'user_id' => $this->parent->id,
            'category_id' => $this->categories['Food']->id,
        ]);

        $food = collect(
            $this->actingAs($this->parent)->getJson('/api/categories')->json('data')
        )->firstWhere('id', $this->categories['Food']->id);

        $this->assertSame(1, $food['transactions_count']);
        $this->assertSame(1, $food['budgets_count']);
    }
}
