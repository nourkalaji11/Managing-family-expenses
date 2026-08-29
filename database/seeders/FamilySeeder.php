<?php

namespace Database\Seeders;

use App\Models\Account;
use App\Models\Budget;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * عائلة كاملة جاهزة للتشغيل.
 *
 * ---------------------------------------------------------------------------
 * قبل هذا الملف كان `php artisan migrate` يترك قاعدة بيانات فارغة تماماً: لا
 * مستخدم لتسجيل الدخول، ولا حساب ولا فئة — و`POST /transactions` يرفض أي طلب
 * لأن `exists:accounts,id` و`exists:categories,id` لا تجدان شيئاً. أي مطوّر
 * جديد كان عليه أن يبني كل ذلك بيده قبل أن يرى شاشة واحدة تعمل.
 *
 * البيانات هنا **بيانات تطوير** لا عيّنة عرض: كلمات المرور معروفة ومكتوبة في
 * الملف، ولهذا يمتنع الـseeder عن العمل خارج بيئة local — انظر run().
 * ---------------------------------------------------------------------------
 */
class FamilySeeder extends Seeder
{
    /** كلمة مرور الحسابين. معروفة عمداً؛ بيئة التطوير فقط. */
    public const PASSWORD = 'password123';

    public function run(): void
    {
        // حارس: زرع مستخدمين بكلمة مرور مكتوبة في مستودع عام كارثة على أي بيئة
        // غير محلية. الفشل الصريح أفضل من إنشائهم بصمت على سيرفر حقيقي.
        if (! app()->environment('local', 'testing')) {
            $this->command?->error(
                'FamilySeeder يعمل في بيئة local أو testing فقط: يزرع كلمات مرور معروفة.'
            );
            return;
        }

        // idempotent: تشغيله مرتين لا يضاعف الصفوف. firstOrCreate على البريد،
        // وهو العمود الفريد الوحيد في users.
        $parent = User::firstOrCreate(
            ['email' => 'parent@family.com'],
            [
                'name'     => 'ولي الأمر',
                'password' => Hash::make(self::PASSWORD),
                'role'     => 'parent',
            ]
        );

        $child = User::firstOrCreate(
            ['email' => 'child@family.com'],
            [
                'name'           => 'الابن',
                'password'       => Hash::make(self::PASSWORD),
                'role'           => 'member',
                'spending_limit' => 500,
            ]
        );

        // الفئات عامة (لا user_id في المخطط)، والترتيب هنا مقصود: تطبيق الموبايل
        // يشتق لون كل فئة وأيقونتها من معرّفها في CategoryVisuals، فأول ثلاثة
        // تحصل على ألوان التصميم الثلاثة بدل ألوان احتياطية.
        $categories = [];
        foreach (['طعام', 'سكن', 'مواصلات', 'تسوق', 'فواتير', 'صحة'] as $name) {
            $categories[$name] = Category::firstOrCreate(['name' => $name]);
        }

        // الحسابات مشتركة بين أفراد العائلة رغم أن العمود يسجّل من أنشأها —
        // انظر ScopesToFamily. الرصيد السالب متعمَّد: بطاقة ائتمان مكشوفة حالة
        // حقيقية، وهي ما يُظهر التنسيق الأحمر في التطبيق.
        $accounts = [];
        foreach ([
            ['محفظة نقدية', 1250.00],
            ['حساب بنكي', 18450.50],
            ['بطاقة ائتمان', -4800.00],
            ['حساب الادخار', 9600.00],
        ] as [$name, $balance]) {
            $accounts[$name] = Account::firstOrCreate(
                ['name' => $name, 'user_id' => $parent->id],
                ['balance' => $balance]
            );
        }

        // العمليات تُكتب مباشرةً لا عبر الكنترولر: مروراً به كان كل صف سيعدّل
        // الرصيد مرة ثانية، فتصبح الأرصدة أعلاه غير صحيحة.
        //
        // لا تُزرع إن وُجدت عمليات أصلاً، حتى لا يضيف التشغيل الثاني نسخة ثانية.
        if (Transaction::count() === 0) {
            $today = now();

            foreach ([
                // [المبلغ, النوع, الوصف, الفئة, الحساب, المالك, قبل كم يوم]
                [245.50, 'expense', 'ستاربكس', 'طعام', 'حساب بنكي', $parent, 0],
                [8500.00, 'income', 'الراتب الشهري', 'فواتير', 'حساب بنكي', $parent, 1],
                [1200.00, 'expense', 'إيجار الشهر', 'سكن', 'حساب بنكي', $parent, 2],
                [180.00, 'expense', 'بنزين', 'مواصلات', 'محفظة نقدية', $parent, 3],
                [420.00, 'expense', 'ملابس وأحذية', 'تسوق', 'محفظة نقدية', $parent, 5],
                [95.00, 'expense', 'صيدلية', 'صحة', 'محفظة نقدية', $child, 8],
                [310.00, 'expense', 'سوبرماركت', 'طعام', 'حساب بنكي', $parent, 11],
            ] as [$amount, $type, $description, $category, $account, $owner, $daysAgo]) {
                Transaction::create([
                    'amount'      => $amount,
                    'type'        => $type,
                    'description' => $description,
                    'date'        => $today->copy()->subDays($daysAgo)->toDateString(),
                    'user_id'     => $owner->id,
                    'account_id'  => $accounts[$account]->id,
                    'category_id' => $categories[$category]->id,
                ]);
            }
        }

        // ميزانيتان تغطيان الشهر الحالي: واحدة ضمن الحد وواحدة متجاوَزة، فتظهر
        // حالتا البطاقة في التطبيق دون أن يضطر أحد لإنشائهما.
        //
        // current_spending لا يُملأ هنا: لا شيء يكتب هذا العمود، وBudgetController
        // يحسب القيمة عند القراءة — انظر index.
        $start = now()->startOfMonth()->toDateString();
        $end   = now()->endOfMonth()->toDateString();

        foreach ([['طعام', 800.00], ['مواصلات', 150.00]] as [$category, $limit]) {
            Budget::firstOrCreate(
                [
                    'category_id' => $categories[$category]->id,
                    'user_id'     => $parent->id,
                ],
                [
                    'limit_amount'     => $limit,
                    'current_spending' => 0,
                    'start_date'       => $start,
                    'end_date'         => $end,
                ]
            );
        }

        $this->command?->info(sprintf(
            'عائلة جاهزة: %s / %s (كلمة المرور: %s) — %d فئة، %d حساب، %d عملية، %d ميزانية.',
            $parent->email,
            $child->email,
            self::PASSWORD,
            count($categories),
            count($accounts),
            Transaction::count(),
            Budget::count()
        ));
    }
}
