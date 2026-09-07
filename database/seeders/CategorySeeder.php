<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

/**
 * شجرة الفئات الافتراضية.
 *
 * ---------------------------------------------------------------------------
 * منقولة عن التطبيق المرجعي الذي أرسله المستخدم: ثلاثة تبويبات (دخل، مصروف،
 * دين)، وداخل كل تبويب مجموعات رئيسية تحتها فروع.
 *
 * **ما لم يكن في الصور** موسوم بـ`// ‏[مضاف]` في القوائم أدناه. لقطات الشاشة
 * الستّ لم تغطِّ القائمة كاملة — انقطعت بين "أحذية" وما بعدها تحت التسوق، وبين
 * "الإيجار" وبداية "أخرى"، ولم يصل تبويب الديون أصلاً — فأُكملت تلك المواضع
 * بأسماء منطقية. راجعها وصحّحها؛ تعديل نص هنا أرخص من تخمينه لاحقاً من داخل
 * التطبيق.
 *
 * الفئات مشتركة بين أفراد العائلة: جدول categories بلا user_id، وهذا مقصود —
 * "المطاعم" هي نفسها لكل من يسجّل عليها، وما يختلف هو العمليات لا التصنيف.
 *
 * التنفيذ آمن للتكرار: كل فئة تُطابَق بالاسم والنوع والأب، فتشغيل السيدر مرتين
 * لا ينشئ نسخاً ثانية ولا يلمس فئة أضافها المستخدم بنفسه.
 * ---------------------------------------------------------------------------
 */
class CategorySeeder extends Seeder
{
    /**
     * تبويب الدخل — بلا مجموعات، كما في الصورة الأولى.
     */
    private const INCOME = [
        ['الراتب', 'salary'],
        ['المكافآت', 'bonus'],
        ['الهدايا', 'gift'],
        ['المبيعات', 'sale'],
        ['الإضافي', 'extra'],
        ['أخرى', 'other'],
        ['إضافة رصيد', 'top_up'],
    ];

    /**
     * تبويب المصروف. كل عنصر: [الاسم، الأيقونة، الفروع].
     */
    private const EXPENSE = [
        ['سحب رصيد', 'cash_out', []],
        ['تحويل رصيد', 'transfer', [
            ['دفعة الكريديت', 'credit_payment'],
        ]],
        ['الغذاء', 'food', [
            ['المقاهي', 'cafe'],
            ['المطاعم', 'restaurant'],
            ['طبخة', 'home_cooking'],
            ['اكل جاهز', 'fast_food'],
        ]],
        ['التسوق', 'shopping', [
            ['اكسسوارات', 'accessories'],
            ['ملابس', 'clothes'],
            ['الكترونيات', 'electronics'],
            ['أحذية', 'shoes'],
            ['مستحضرات تجميل', 'cosmetics'],   // [مضاف]
            ['اكل', 'groceries'],
        ]],
        ['المواصلات', 'transport', [
            ['البنزين', 'fuel'],
            ['الصيانة', 'car_service'],
            ['الجراج', 'parking'],
            ['الأجرة', 'taxi'],
            ['تكسي للشركة', 'company_taxi'],
            ['نول', 'public_transport'],
        ]],
        ['فواتير', 'bills', [
            ['الكهرباء', 'electricity'],
            ['الغاز', 'gas'],
            ['الإنترنت', 'internet'],
            ['الإتصالات', 'phone'],
            ['الإيجار', 'rent'],
            ['الماء', 'water'],                 // [مضاف]
        ]],
        ['أخرى', 'other', [
            ['دين', 'debt'],
            ['غيث', 'misc'],
        ]],
        ['الأسرة', 'family', [
            ['الأطفال', 'children'],
            ['الصيانة المنزلية', 'home_repair'],
            ['الخدمات', 'services'],
            ['الحيوانات الأليفة', 'pets'],
        ]],
        ['مصاريف شغل', 'work', []],
        ['دين', 'debt', []],
        ['التعليم', 'education', [
            ['كتب دراسية', 'books'],
            ['الدورات التدريبية', 'courses'],
        ]],
        ['إستثمار', 'investment', []],
        ['الترفيه', 'entertainment', [
            ['العاب', 'games'],
            ['أفلام و صوتيات', 'movies'],
        ]],
        ['الرسوم و الإشتراكات', 'subscriptions', []],
        ['التبرعات و الهدايا', 'donations', [
            ['الصدقة', 'charity'],
            ['الزكاة', 'zakat'],
            ['الهدايا', 'gift'],
        ]],
        ['الصحة و اللياقة البدنيه', 'health', [
            ['الأطباء', 'doctor'],
            ['الأدوية', 'medicine'],
            ['العناية الشخصية', 'personal_care'],
            ['الانشطة الرياضية', 'sports'],
        ]],
        ['التأمينات', 'insurance', []],
        ['السفر', 'travel', []],
        ['السحب النقدي', 'atm', []],
    ];

    /**
     * تبويب الديون.
     *
     * ‏**كله [مضاف]**: التبويب موجود في التطبيق المرجعي لكن لم تصلني صورة له،
     * وهذه الأسماء الأربعة هي ما يقتضيه المعنى. صحّحها إن اختلفت.
     */
    private const DEBT = [
        ['سلفة', 'borrow'],
        ['تسديد سلفة', 'repay'],
        ['دين لي', 'lent'],
        ['دين عليّ', 'owed'],
    ];

    public function run(): void
    {
        foreach (self::INCOME as [$name, $icon]) {
            $this->upsert($name, Category::TYPE_INCOME, $icon, null);
        }

        foreach (self::EXPENSE as [$name, $icon, $children]) {
            $group = $this->upsert($name, Category::TYPE_EXPENSE, $icon, null);

            foreach ($children as [$childName, $childIcon]) {
                $this->upsert($childName, Category::TYPE_EXPENSE, $childIcon, $group->id);
            }
        }

        foreach (self::DEBT as [$name, $icon]) {
            $this->upsert($name, Category::TYPE_DEBT, $icon, null);
        }
    }

    /**
     * ينشئ الفئة إن لم تكن موجودة.
     *
     * المطابقة على الثلاثة معاً لا على الاسم وحده: "الهدايا" فئة دخل وفرع تحت
     * التبرعات في آنٍ واحد، و"دين" مجموعة رئيسية وفرع تحت "أخرى". مطابقة
     * بالاسم فقط كانت ستدمجها وتُسقط نصف الشجرة.
     */
    private function upsert(string $name, string $type, ?string $icon, ?int $parentId): Category
    {
        return Category::firstOrCreate(
            ['name' => $name, 'type' => $type, 'parent_id' => $parentId],
            ['icon' => $icon],
        );
    }
}
