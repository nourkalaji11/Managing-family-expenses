<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * spending_limit يصبح nullable، وnull تعني "لم يُحدَّد سقف".
 *
 * ---------------------------------------------------------------------------
 * كان العمود NOT NULL DEFAULT 0، فلم تكن هناك قيمة تعني "لم يقرر ولي الأمر
 * بعد". النتيجة أن كل ابن يُنشأ دون سقف يبدأ عند 0، و
 * TransactionController::store يقارن `($totalSpent + $amount) > $limit`،
 * فيُرفض عليه **كل** مصروف مهما صغر — برسالة تقول إن المبلغ يتجاوز سقفه، وهو
 * سقف لم يضعه أحد. ابن مجمَّد كلياً دون أن يختار ذلك أحد.
 *
 * التمييز الآن صريح:
 *   null → لا سقف. لا يُفحص شيء.
 *   0    → سقف صفر، وضعه ولي الأمر عمداً لتجميد الصرف.
 * وهما حالتان متعاكستان كانتا تُكتبان بالرقم نفسه.
 *
 * الصفوف القائمة تبقى 0 ولا تُحوَّل إلى null: لا يمكن للترحيل أن يعرف أيها
 * كان "صفراً مقصوداً" وأيها كان القيمة الافتراضية، وتخمين ذلك يعني رفع سقف
 * وضعه ولي أمر فعلاً. من أراد إزالة سقف يزيله من الشاشة.
 * ---------------------------------------------------------------------------
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->decimal('spending_limit', 15, 2)->nullable()->default(null)->change();
        });
    }

    public function down(): void
    {
        // العودة تتطلب قيمة لكل صف: null لا تسع في عمود NOT NULL. تُكتب 0،
        // وهو ما كان الافتراضي أصلاً.
        DB::table('users')->whereNull('spending_limit')->update(['spending_limit' => 0]);

        Schema::table('users', function (Blueprint $table) {
            $table->decimal('spending_limit', 15, 2)->default(0)->nullable(false)->change();
        });
    }
};
