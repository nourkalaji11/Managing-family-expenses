<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('budgets', function (Blueprint $table) {
            $table->id(); // الـ P.K للميزانية
            $table->decimal('limit_amount', 15, 2); // الحد الأقصى للميزانية (المبلغ المحدد)
            $table->decimal('current_spending', 15, 2)->default(0.00); // الإنفاق الحالي المأخوذ من المصاريف الفريضة
            $table->date('start_date'); // تاريخ بداية الميزانية
            $table->date('end_date'); // تاريخ نهاية الميزانية
            
            // ربط الميزانية بالمستخدم والتصنيف (المفاتيح الأجنبية F.K)
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('category_id')->constrained('categories')->onDelete('cascade');
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('budgets');
    }
};
