<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * إشعارات داخل التطبيق.
     *
     * الاسم `app_notifications` وليس `notifications` عمداً: الاسم الثاني محجوز
     * لجدول Laravel's database notification channel، واستعماله هنا يمنع تفعيل
     * تلك الميزة لاحقاً دون ترحيل مؤلم.
     */
    public function up(): void
    {
        Schema::create('app_notifications', function (Blueprint $table) {
            $table->id();

            // صاحب الإشعار — من يراه في قائمته.
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');

            // مفتاح نوع ثابت (budget_exceeded, limit_reached, ...) تقرأه الواجهة
            // لاختيار الأيقونة واللون، بدل أن تحلّل نص العنوان.
            $table->string('type', 40);

            $table->string('title');
            $table->text('message');

            /**
             * حمولة إضافية يقرر النوع شكلها — مثلاً معرّف الميزانية المتجاوَزة.
             * JSON وليس أعمدة منفصلة لأن كل نوع يحمل حقولاً مختلفة، وإضافة
             * نوع جديد لا يجوز أن تتطلب ترحيلاً.
             */
            $table->json('data')->nullable();

            // false = غير مقروء. مفهرس مع user_id لأن كل قراءة هي
            // "كم إشعاراً غير مقروء لهذا المستخدم".
            $table->boolean('seen')->default(false);

            $table->timestamps();

            $table->index(['user_id', 'seen']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_notifications');
    }
};
