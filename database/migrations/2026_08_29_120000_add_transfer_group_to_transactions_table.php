<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * التحويل بين حسابين يُسجَّل كعمليتين مرتبطتين: مصروف من الحساب المصدر
     * وإيراد للحساب الهدف. هذا العمود هو ما يربطهما.
     *
     * لماذا عمليتان لا جدول منفصل: التحويل يحرّك رصيدَي حسابين، وهذا بالضبط ما
     * تفعله العملية المالية — فيظهر التحويل في سجل المعاملات كما يتوقع
     * المستخدم، ويستفيد من نفس منطق الرصيد المطبَّق في store/update/destroy
     * بدل تكراره في مكان ثانٍ.
     *
     * العمود nullable لأن الغالبية العظمى من الصفوف عمليات عادية، ومفهرس لأن
     * كل قراءة له هي "أعطني الطرف الآخر من هذا التحويل".
     */
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            // UUID نصي وليس مفتاحاً أجنبياً: الطرفان يُنشآن معاً في نفس
            // DB::transaction، فلا يوجد صف أب يسبقهما ليشير إليه.
            $table->string('transfer_group_id', 36)->nullable()->after('description');
            $table->index('transfer_group_id');
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropIndex(['transfer_group_id']);
            $table->dropColumn('transfer_group_id');
        });
    }
};
