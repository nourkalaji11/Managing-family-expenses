<?php

namespace App\Http\Controllers\Concerns;

use App\Models\User;
use Illuminate\Database\Eloquent\Builder;

/**
 * قصر الاستعلامات على ما يحق للمستخدم رؤيته.
 *
 * ---------------------------------------------------------------------------
 * قبل هذا الـtrait كانت كل دوال index تُرجع كل صفوف الجدول لأي مستخدم مسجَّل
 * دخوله: `Transaction::with(...)->latest()->get()` بلا أي where. مع عائلة واحدة
 * على السيرفر لا يظهر الأثر، لكن مع عائلتين يقرأ كل منهما بيانات الأخرى
 * المالية كاملة.
 *
 * النموذج المطبَّق:
 *
 *   العمليات والميزانيات  → ولي الأمر يرى الجميع، والابن يرى ما يخصه فقط.
 *                            هذا ما تفترضه DashboardController أصلاً حين تُظهر
 *                            لولي الأمر إجمالي العائلة وللابن مسحوباته وحده.
 *
 *   الحسابات المالية      → ولي الأمر يرى الجميع، والابن يرى حساباته وحدها.
 *
 *                            كانت مشتركة يراها الجميع، والحجة أن قصرها على
 *                            صاحبها يترك الابن بلا حساب يسجّل عليه مصروفه.
 *                            الحجة كانت صحيحة والحل كان خاطئاً: النتيجة أن
 *                            الابن يقرأ رصيد أبيه. الحل الصحيح أن يكون لكل ابن
 *                            حسابه — يُنشأ مع حسابه في createMember، وللأبناء
 *                            الموجودين تُنشئه هجرة — فيبقى عنده ما يسجّل عليه
 *                            دون أن يرى مال غيره.
 *
 *   الفئات                → عامة بحكم المخطط: جدول categories بلا user_id.
 *
 * TODO(backend): "العائلة" هنا تعني عملياً كل مستخدمي قاعدة البيانات، إذ لا
 * يوجد جدول families ولا عمود family_id. صحيح لنشر عائلة واحدة؛ تعدد العائلات
 * يحتاج عمود ربط أولاً، وعندها يصبح شرط ولي الأمر
 * `where('family_id', $user->family_id)` بدل غياب الشرط.
 * ---------------------------------------------------------------------------
 */
trait ScopesToFamily
{
    /**
     * يقيّد [$query] بصفوف المستخدم إن لم يكن ولي أمر.
     *
     * ولي الأمر لا يُقيَّد: رؤيته لنشاط العائلة كاملاً هي وظيفته في التطبيق.
     */
    protected function scopeToViewer(Builder $query, ?User $user): Builder
    {
        if ($user === null) {
            // لا يُفترض حدوثه خلف auth:sanctum، لكن الفشل إلى "لا شيء" أسلم من
            // الفشل إلى "كل شيء".
            return $query->whereRaw('1 = 0');
        }

        if ($user->isParent()) {
            return $query;
        }

        return $query->where('user_id', $user->id);
    }

    /**
     * هل يحق لهذا المستخدم قراءة صف يملكه [$ownerId] أو تعديله؟
     *
     * تُستعمل في دوال update/destroy: القصر على index وحده يمنع التصفح لا
     * الوصول المباشر — يكفي تخمين رقم في المسار.
     */
    protected function viewerOwns(?User $user, $ownerId): bool
    {
        if ($user === null) {
            return false;
        }

        return $user->isParent() || (int) $ownerId === (int) $user->id;
    }

    /**
     * هل يحق لهذا المستخدم تسجيل عملية على الحساب [$accountId]؟
     *
     * `exists:accounts,id` تتحقق من وجود الحساب لا من حق الوصول إليه. بدون هذا
     * الفحص يستطيع الابن أن يسجّل مصروفه على حساب أبيه بإرسال رقمه، فينقص رصيد
     * حساب لا يراه أصلاً.
     */
    protected function viewerCanUseAccount(?User $user, $accountId): bool
    {
        if ($user === null || $accountId === null) {
            return false;
        }

        $ownerId = \App\Models\Account::whereKey($accountId)->value('user_id');

        return $ownerId !== null && $this->viewerOwns($user, $ownerId);
    }
}
