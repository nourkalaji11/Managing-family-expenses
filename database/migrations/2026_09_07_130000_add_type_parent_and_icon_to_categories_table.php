<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * تحويل الفئات من قائمة مسطّحة إلى شجرة مصنَّفة.
 *
 * ---------------------------------------------------------------------------
 * كان الجدول اسماً وحسب، فلا يستطيع تمييز فئة دخل من فئة مصروف، ولا وضع
 * "المطاعم" تحت "الغذاء". النتيجة أن نموذج إضافة معاملة يعرض "الراتب" كخيار
 * لمصروف، وأن شاشة الفئات قائمة واحدة طويلة بلا ترتيب.
 *
 *   type      → أي تبويب تنتمي إليه الفئة: دخل، مصروف، دين.
 *   parent_id → الفئة الأب، وnull للمجموعات الرئيسية. مقيَّد بنفس الجدول
 *               وonDelete('cascade')، فحذف مجموعة يأخذ فروعها معها — وهو
 *               الصحيح: فرع بلا أبيه لا موضع له في أي تبويب.
 *   icon      → اسم الأيقونة، يقرؤه العميل. نص لا رقم، حتى لا يرتبط الخادم
 *               بمجموعة أيقونات بعينها.
 *
 * القيم الافتراضية تُبقي الصفوف الموجودة صالحة: فئة قديمة بلا نوع هي مصروف،
 * وهو ما كانت عليه عملياً.
 * ---------------------------------------------------------------------------
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->string('type', 20)->default('expense')->after('name')->index();
            $table->foreignId('parent_id')->nullable()->after('type')
                ->constrained('categories')->cascadeOnDelete();
            $table->string('icon', 60)->nullable()->after('parent_id');
        });
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropConstrainedForeignId('parent_id');
            $table->dropColumn(['type', 'icon']);
        });
    }
};
