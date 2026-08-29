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
     */
    public function run(): void
    {
        $this->call([
            FamilySeeder::class,
        ]);
    }
}
