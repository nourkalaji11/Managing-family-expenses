<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\AppNotification;
use App\Models\Budget;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * سقف سحب الابن، والإشعارات التي ترفعها الأحداث المالية.
 *
 * الإشعارات ليست ميزة تجميلية هنا: هي الطريقة الوحيدة التي يعرف بها ولي الأمر
 * أن ابناً تجاوز ميزانية أو حاول تجاوز سقفه. اختبارها يعني اختبار أنها تُرفع
 * من الحدث الصحيح وتذهب إلى الشخص الصحيح.
 */
class SpendingLimitAndNotificationsTest extends TestCase
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
            'spending_limit' => 300,
        ]);

        $this->category = Category::create(['name' => 'Food']);
        $this->account = Account::create([
            'name' => 'Wallet',
            'balance' => 10000,
            'user_id' => $this->parent->id,
        ]);
    }

    private function payload(array $overrides = []): array
    {
        return array_merge([
            'account_id' => $this->account->id,
            'category_id' => $this->category->id,
            'amount' => 100,
            'type' => 'expense',
            'date' => now()->toDateString(),
        ], $overrides);
    }

    // -------------------------------------------------------------------------
    // The ceiling
    // -------------------------------------------------------------------------

    public function test_a_member_may_spend_up_to_their_ceiling_and_no_further(): void
    {
        $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 250]))
            ->assertCreated();

        // 250 already spent, so 100 more would cross 300.
        //
        // `remaining` is compared numerically: the controller casts to float
        // but json_encode drops a zero fraction, so the wire value is `50` and
        // assertJsonPath compares strictly.
        $blocked = $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 100]))
            ->assertForbidden();

        $this->assertEqualsWithDelta(50, $blocked->json('remaining'), 0.001);
        $this->assertEqualsWithDelta(300, $blocked->json('spending_limit'), 0.001);

        $this->assertSame(1, Transaction::where('user_id', $this->child->id)->count());
    }

    public function test_a_parent_is_not_capped(): void
    {
        $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['amount' => 9000]))
            ->assertCreated();
    }

    public function test_the_ceiling_cannot_be_dodged_by_editing_an_older_row(): void
    {
        // Only checking on create would let a member book 1, then edit it to
        // 5000 — the limit has to be enforced on update as well, with the row's
        // own old amount excluded from the running total.
        $created = $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 50]))
            ->json('data.id');

        $this->actingAs($this->child)
            ->putJson("/api/transactions/{$created}", $this->payload(['amount' => 5000]))
            ->assertForbidden();

        $this->assertSame(50.0, (float) Transaction::find($created)->amount);
    }

    public function test_a_transfer_does_not_consume_the_ceiling(): void
    {
        $second = Account::create([
            'name' => 'Savings',
            'balance' => 100,
            'user_id' => $this->parent->id,
        ]);

        // Moving money between the family's own accounts is not spending, so it
        // must not eat into an allowance meant to cap what leaves the family.
        $this->actingAs($this->child)
            ->postJson('/api/transfers', [
                'from_account_id' => $this->account->id,
                'to_account_id' => $second->id,
                'amount' => 5000,
                'category_id' => $this->category->id,
                'date' => now()->toDateString(),
            ])
            ->assertCreated();

        // The full ceiling is still available afterwards.
        $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 300]))
            ->assertCreated();
    }

    // -------------------------------------------------------------------------
    // Notifications
    // -------------------------------------------------------------------------

    public function test_a_members_expense_notifies_the_parent_and_not_the_member(): void
    {
        $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 40]))
            ->assertCreated();

        $this->assertDatabaseHas('app_notifications', [
            'user_id' => $this->parent->id,
            'type' => AppNotification::TYPE_MEMBER_SPENT,
        ]);

        // Telling someone about a thing they just did themselves is noise.
        $this->assertDatabaseMissing('app_notifications', [
            'user_id' => $this->child->id,
            'type' => AppNotification::TYPE_MEMBER_SPENT,
        ]);
    }

    public function test_a_parents_own_expense_notifies_nobody(): void
    {
        $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload())
            ->assertCreated();

        $this->assertSame(
            0,
            AppNotification::where('type', AppNotification::TYPE_MEMBER_SPENT)->count()
        );
    }

    public function test_a_blocked_attempt_notifies_both_sides(): void
    {
        $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 9999]))
            ->assertForbidden();

        // The member, so they can see why after the error toast is gone; the
        // parent, because repeated attempts mean the ceiling is too tight.
        foreach ([$this->child->id, $this->parent->id] as $recipient) {
            $this->assertDatabaseHas('app_notifications', [
                'user_id' => $recipient,
                'type' => AppNotification::TYPE_LIMIT_BLOCKED,
            ]);
        }
    }

    public function test_crossing_a_budget_notifies_once_not_on_every_later_expense(): void
    {
        Budget::create([
            'limit_amount' => 100,
            'current_spending' => 0,
            'start_date' => now()->startOfMonth()->toDateString(),
            'end_date' => now()->endOfMonth()->toDateString(),
            'user_id' => $this->parent->id,
            'category_id' => $this->category->id,
        ]);

        // Under the limit: silence.
        $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['amount' => 60]))
            ->assertCreated();
        $this->assertSame(
            0,
            AppNotification::where('type', AppNotification::TYPE_BUDGET_EXCEEDED)->count()
        );

        // This one crosses it.
        $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['amount' => 60]))
            ->assertCreated();
        $this->assertSame(
            1,
            AppNotification::where('type', AppNotification::TYPE_BUDGET_EXCEEDED)->count()
        );

        // Already over: a second alert would train the user to ignore them.
        $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['amount' => 60]))
            ->assertCreated();
        $this->assertSame(
            1,
            AppNotification::where('type', AppNotification::TYPE_BUDGET_EXCEEDED)->count()
        );
    }

    public function test_a_member_cannot_mark_another_users_notification_as_read(): void
    {
        $theirs = AppNotification::create([
            'user_id' => $this->parent->id,
            'type' => AppNotification::TYPE_MEMBER_SPENT,
            'title' => 't',
            'message' => 'm',
            'seen' => false,
        ]);

        $this->actingAs($this->child)
            ->postJson("/api/notifications/{$theirs->id}/read")
            ->assertNotFound();

        $this->assertFalse($theirs->fresh()->seen);
    }

    public function test_the_unread_count_covers_the_whole_collection_not_the_page(): void
    {
        // The badge means "unread for you", so a paginated response still has
        // to report the total.
        for ($i = 0; $i < 25; $i++) {
            AppNotification::create([
                'user_id' => $this->parent->id,
                'type' => AppNotification::TYPE_MEMBER_SPENT,
                'title' => "t{$i}",
                'message' => 'm',
                'seen' => false,
            ]);
        }

        $this->actingAs($this->parent)
            ->getJson('/api/notifications?per_page=10')
            ->assertOk()
            ->assertJsonCount(10, 'data')
            ->assertJsonPath('meta.unread_count', 25)
            ->assertJsonPath('meta.total', 25);
    }

    // -------------------------------------------------------------------------
    // Transfer visibility — a parent oversees the family's transfers too
    // -------------------------------------------------------------------------

    public function test_a_parent_sees_and_can_undo_a_members_transfer(): void
    {
        $second = Account::create([
            'name' => 'Savings',
            'balance' => 0,
            'user_id' => $this->parent->id,
        ]);

        $group = $this->actingAs($this->child)
            ->postJson('/api/transfers', [
                'from_account_id' => $this->account->id,
                'to_account_id' => $second->id,
                'amount' => 200,
                'category_id' => $this->category->id,
                'date' => now()->toDateString(),
            ])
            ->json('data.transfer_group_id');

        // TransferController originally filtered on the caller's own id, so a
        // parent could neither see nor reverse a child's transfer — the one
        // resource that did not follow the family scoping rule.
        $this->actingAs($this->parent)
            ->getJson('/api/transfers')
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $this->actingAs($this->parent)
            ->deleteJson("/api/transfers/{$group}")
            ->assertOk();

        $this->assertSame(10000.0, (float) $this->account->fresh()->balance);
    }
}
