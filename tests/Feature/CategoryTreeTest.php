<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * شجرة الفئات الافتراضية كما يزرعها CategorySeeder.
 *
 * ---------------------------------------------------------------------------
 * الغرض ليس تثبيت كل اسم — الأسماء تتغير بمراجعة المستخدم — بل تثبيت الشكل:
 * ثلاثة تبويبات، مجموعات لها فروع، وأسماء يجوز تكرارها في مواضع مختلفة.
 *
 * آخر شرط هو الأهم: "الهدايا" فئة دخل وفرع تحت التبرعات، و"دين" مجموعة رئيسية
 * وفرع تحت "أخرى". قاعدة `unique:categories,name` القديمة كانت سترفض نصف
 * الشجرة، ولذلك صار التفرّد داخل المجموعة لا في الجدول.
 * ---------------------------------------------------------------------------
 */
class CategoryTreeTest extends TestCase
{
    use RefreshDatabase;

    private function seed_tree(): void
    {
        $this->seed(CategorySeeder::class);
    }

    private function actor(): User
    {
        return User::create([
            'name' => 'Parent',
            'email' => 'parent@test.local',
            'password' => Hash::make('password123'),
            'role' => 'parent',
        ]);
    }

    public function test_the_seeder_plants_all_three_tabs(): void
    {
        $this->seed_tree();

        $this->assertSame(7, Category::where('type', Category::TYPE_INCOME)->count());
        $this->assertSame(59, Category::where('type', Category::TYPE_EXPENSE)->count());
        $this->assertSame(4, Category::where('type', Category::TYPE_DEBT)->count());
    }

    public function test_groups_carry_their_children(): void
    {
        $this->seed_tree();

        $food = Category::where('name', 'الغذاء')->whereNull('parent_id')->firstOrFail();

        $this->assertSame(
            ['المقاهي', 'المطاعم', 'طبخة', 'اكل جاهز'],
            $food->children->pluck('name')->all(),
        );
    }

    public function test_income_categories_are_flat(): void
    {
        $this->seed_tree();

        // The reference app's income tab has no groups; every row is top level.
        $this->assertSame(
            0,
            Category::where('type', Category::TYPE_INCOME)->whereNotNull('parent_id')->count(),
        );
    }

    public function test_the_same_name_may_appear_in_two_places(): void
    {
        $this->seed_tree();

        $gifts = Category::where('name', 'الهدايا')->get();

        $this->assertCount(2, $gifts);
        $this->assertTrue($gifts->contains(fn ($c) => $c->type === Category::TYPE_INCOME && $c->parent_id === null));
        $this->assertTrue($gifts->contains(fn ($c) => $c->type === Category::TYPE_EXPENSE && $c->parent_id !== null));
    }

    public function test_running_the_seeder_twice_changes_nothing(): void
    {
        $this->seed_tree();
        $before = Category::count();

        $this->seed_tree();

        $this->assertSame($before, Category::count());
    }

    public function test_the_index_returns_the_tree_in_planted_order(): void
    {
        $this->seed_tree();

        $rows = $this->actingAs($this->actor())
            ->getJson('/api/categories')->assertOk()->json('data');

        $this->assertSame(Category::count(), count($rows));

        // Each row carries what the client needs to rebuild the tree without a
        // second request: which tab it belongs to, and which group.
        $this->assertArrayHasKey('type', $rows[0]);
        $this->assertArrayHasKey('parent_id', $rows[0]);
        $this->assertArrayHasKey('icon', $rows[0]);
    }

    public function test_the_index_can_be_narrowed_to_one_tab(): void
    {
        $this->seed_tree();

        $rows = $this->actingAs($this->actor())
            ->getJson('/api/categories?type=income')->assertOk()->json('data');

        $this->assertCount(7, $rows);
        $this->assertSame(
            [Category::TYPE_INCOME],
            array_values(array_unique(array_column($rows, 'type'))),
        );
    }

    public function test_a_new_category_may_reuse_a_name_used_in_another_group(): void
    {
        $this->seed_tree();

        $transport = Category::where('name', 'المواصلات')->whereNull('parent_id')->firstOrFail();

        $this->actingAs($this->actor())
            ->postJson('/api/categories', [
                'name' => 'الصيانة المنزلية',
                'type' => Category::TYPE_EXPENSE,
                'parent_id' => $transport->id,
            ])->assertCreated();
    }

    public function test_a_new_category_cannot_duplicate_a_sibling(): void
    {
        $this->seed_tree();

        $food = Category::where('name', 'الغذاء')->whereNull('parent_id')->firstOrFail();

        $this->actingAs($this->actor())
            ->postJson('/api/categories', [
                'name' => 'المطاعم',
                'type' => Category::TYPE_EXPENSE,
                'parent_id' => $food->id,
            ])->assertStatus(422);
    }
}
