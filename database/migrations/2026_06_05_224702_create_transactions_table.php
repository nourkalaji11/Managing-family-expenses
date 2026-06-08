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
        Schema::create('transactions', function (Blueprint $table) {
            $table->id(); // الـ P.K للعملية
            $table->decimal('amount', 15, 2); // مبلغ العملية
            $table->enum('type', ['income', 'expense']); // نوع العملية: إيراد أو مصروف
            $table->text('description')->nullable(); // وصف اختياري للعملية (مثلاً: شراء أغراض للمنزل)
            $table->date('date'); // تاريخ العملية الفعلي
            
            // ربط العملية بالمفاتيح الأجنبية (F.K) بناءً على المخطط:
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('account_id')->constrained('accounts')->onDelete('cascade');
            $table->foreignId('category_id')->constrained('categories')->onDelete('cascade');
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
