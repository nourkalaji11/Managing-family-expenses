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
        Schema::create('accounts', function (Blueprint $table) {
            $table->id(); // الـ P.K للحساب
            $table->string('name'); // اسم الحساب (مثل: حساب بنكي، كاش، بطاقة ائتمان)
            $table->decimal('balance', 15, 2)->default(0.00); // رصيد الحساب الحالي (استخدمنا decimal لأنه الأفضل للمبالغ المادية)
            
            // ربط الحساب بالمستخدم (المفتاح الأجنبي F.K)
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade'); 
            
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('accounts');
    }
};
