<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     *
     * كان هذا الملف ينشئ `Test User` عبر UserFactory، وهو ما يفشل دائماً:
     * users.role عمود NOT NULL بلا قيمة افتراضية، والمصنع لا يضبطه — فكل
     * `php artisan db:seed` كان ينتهي بخرق قيد سلامة.
     *
     * FamilySeeder يزرع عائلة كاملة يمكن تسجيل الدخول بها فوراً، ويمتنع عن
     * العمل خارج بيئة local أو testing.
     *
     * CategorySeeder على النقيض: شجرة الفئات بيانات مرجعية لا بيانات تجربة،
     * ويلزم تشغيلها في الإنتاج أيضاً — تطبيق بلا فئات لا يقبل أي عملية، لأن
     * transactions.category_id غير قابل للإفراغ. ولذلك يُنفَّذ أولاً: العائلة
     * المزروعة تسجّل عمليات تشير إلى فئات يجب أن تكون موجودة قبلها.
     */
    public function run(): void
    {
        $this->call([
            CategorySeeder::class,
            FamilySeeder::class,
        ]);
    }
}
