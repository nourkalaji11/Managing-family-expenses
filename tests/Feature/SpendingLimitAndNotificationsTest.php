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
    // -------------------------------------------------------------------------
    // "Nearly out of allowance" — the warning that arrives BEFORE a refusal
    // -------------------------------------------------------------------------

    public function test_crossing_eighty_percent_warns_both_the_member_and_the_parent(): void
    {
        // The ceiling is 300, so the threshold is 240. This one write takes the
        // child from 0 to 250 — across it.
        $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 250]))
            ->assertCreated();

        $type = AppNotification::TYPE_LIMIT_APPROACHING;

        $this->assertSame(1, AppNotification::where('user_id', $this->child->id)
            ->where('type', $type)->count(), 'the member is warned');

        $this->assertSame(1, AppNotification::where('user_id', $this->parent->id)
            ->where('type', $type)->count(), 'the parent is warned too');

        // The parent's copy has to name the child: a warning that does not say
        // whose allowance is running out cannot be acted on.
        $parentNote = AppNotification::where('user_id', $this->parent->id)
            ->where('type', $type)->first();

        $this->assertStringContainsString('Child', $parentNote->message);
        $this->assertEqualsWithDelta(50, $parentNote->data['remaining'], 0.001);
        $this->assertSame(83, $parentNote->data['percent']);
    }

    public function test_the_warning_fires_on_crossing_not_on_every_later_expense(): void
    {
        // 250 crosses the 240 threshold.
        $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 250]))
            ->assertCreated();

        // 40 more stays inside the ceiling (290 of 300) and past the threshold.
        // Warning again here would turn the list into noise, and the one
        // warning that mattered would be lost in it.
        $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 40]))
            ->assertCreated();

        $this->assertSame(1, AppNotification::where('user_id', $this->child->id)
            ->where('type', AppNotification::TYPE_LIMIT_APPROACHING)->count());
    }

    public function test_staying_under_the_threshold_warns_nobody(): void
    {
        // 200 of 300 is 67% — below the 80% threshold.
        $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 200]))
            ->assertCreated();

        $this->assertSame(0, AppNotification::where('type', AppNotification::TYPE_LIMIT_APPROACHING)->count());
    }

    public function test_a_parent_is_never_warned_about_their_own_spending(): void
    {
        // A parent has no ceiling to approach.
        $this->actingAs($this->parent)
            ->postJson('/api/transactions', $this->payload(['amount' => 9000]))
            ->assertCreated();

        $this->assertSame(0, AppNotification::where('type', AppNotification::TYPE_LIMIT_APPROACHING)->count());
    }

    public function test_a_member_with_no_ceiling_is_never_warned(): void
    {
        $uncapped = User::create([
            'name' => 'Uncapped',
            'email' => 'uncapped@test.local',
            'password' => Hash::make('password123'),
            'role' => 'member',
        ]);

        $this->actingAs($uncapped)
            ->postJson('/api/transactions', $this->payload(['amount' => 5000]))
            ->assertCreated();

        $this->assertSame(0, AppNotification::where('type', AppNotification::TYPE_LIMIT_APPROACHING)->count());
    }

    // -------------------------------------------------------------------------
    // A parent adding a child, and seeing what each child spent
    // -------------------------------------------------------------------------

    public function test_a_parent_creates_a_member_account(): void
    {
        $response = $this->actingAs($this->parent)
            ->postJson('/api/users', [
                'name' => 'New Child',
                'email' => 'new@test.local',
                'password' => 'password123',
                'spending_limit' => 500,
            ])
            ->assertCreated();

        $this->assertSame('member', $response->json('data.role'));

        $created = User::where('email', 'new@test.local')->first();
        $this->assertNotNull($created);
        $this->assertEqualsWithDelta(500, $created->spending_limit, 0.001);

        // The password is hashed, never stored as typed.
        $this->assertNotSame('password123', $created->password);
        $this->assertTrue(Hash::check('password123', $created->password));

        // Setting the ceiling at creation records the same notification that
        // setting it afterwards would.
        $this->assertSame(1, AppNotification::where('user_id', $created->id)
            ->where('type', AppNotification::TYPE_LIMIT_UPDATED)->count());
    }

    public function test_a_parent_cannot_create_another_parent(): void
    {
        $this->actingAs($this->parent)
            ->postJson('/api/users', [
                'name' => 'Sneaky',
                'email' => 'sneaky@test.local',
                'password' => 'password123',
                // Ignored: the role is fixed server-side. Honouring it would
                // make this endpoint a one-step privilege escalation.
                'role' => 'parent',
            ])
            ->assertCreated();

        $this->assertSame('member', User::where('email', 'sneaky@test.local')->first()->role);
    }

    public function test_a_member_cannot_create_accounts(): void
    {
        $this->actingAs($this->child)
            ->postJson('/api/users', [
                'name' => 'Nope',
                'email' => 'nope@test.local',
                'password' => 'password123',
            ])
            ->assertForbidden();

        $this->assertNull(User::where('email', 'nope@test.local')->first());
    }

    public function test_creating_a_member_rejects_a_duplicate_email(): void
    {
        $this->actingAs($this->parent)
            ->postJson('/api/users', [
                'name' => 'Clash',
                'email' => $this->child->email,
                'password' => 'password123',
            ])
            ->assertStatus(422);
    }

    public function test_the_family_list_reports_what_each_member_spent(): void
    {
        $this->actingAs($this->child)
            ->postJson('/api/transactions', $this->payload(['amount' => 120]))
            ->assertCreated();

        $rows = collect($this->actingAs($this->parent)->getJson('/api/users')->assertOk()->json('data'))
            ->keyBy('id');

        $this->assertEqualsWithDelta(120, $rows[$this->child->id]['spent'], 0.001);
        $this->assertEqualsWithDelta(180, $rows[$this->child->id]['remaining'], 0.001);

        // A parent has no ceiling, so "remaining" is null rather than 0 — the
        // two mean opposite things and one number cannot carry both.
        $this->assertNull($rows[$this->parent->id]['remaining']);
        $this->assertEqualsWithDelta(0, $rows[$this->parent->id]['spent'], 0.001);
    }

    public function test_a_transfer_leg_does_not_count_against_what_a_member_spent(): void
    {
        $other = Account::create([
            'name' => 'Savings',
            'balance' => 1000,
            'user_id' => $this->parent->id,
        ]);

        $this->actingAs($this->child)->postJson('/api/transfers', [
            'from_account_id' => $this->account->id,
            'to_account_id' => $other->id,
            'amount' => 200,
            'category_id' => $this->category->id,
            'date' => now()->toDateString(),
        ])->assertCreated();

        $rows = collect($this->actingAs($this->parent)->getJson('/api/users')->json('data'))->keyBy('id');

        // Moving money between the family's own accounts is not spending, so
        // the figure the parent reads matches the one that will block the next
        // purchase.
        $this->assertEqualsWithDelta(0, $rows[$this->child->id]['spent'], 0.001);
    }
}
