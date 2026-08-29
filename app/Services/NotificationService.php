<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Budget;
use App\Models\Transaction;
use App\Models\User;

/**
 * المكان الوحيد الذي تُولَّد فيه الإشعارات.
 *
 * الكنترولرات تنادي هذه الدوال ولا تنشئ AppNotification مباشرةً: صياغة الرسالة
 * وقرار "من يُبلَّغ" قواعد عمل، ولو تكررت في store وupdate لاختلفت الصياغتان
 * بأول تعديل.
 *
 * كل دالة هنا **لا ترمي استثناءً**: فشل كتابة إشعار يجب ألا يُفشل العملية
 * المالية التي سبّبته. الإشعار خدمة مساعدة، لا جزء من الحركة المحاسبية.
 */
class NotificationService
{
    /**
     * أولياء الأمور الذين يُبلَّغون بنشاط الأبناء.
     *
     * TODO(backend): لا يوجد عمود family_id، فهذا يعني "كل أولياء الأمور في
     * قاعدة البيانات". صحيح لنشر عائلة واحدة فقط — انظر AuthController::familyMembers.
     */
    protected function parents()
    {
        return User::whereIn('role', User::PARENT_ROLES)->get();
    }

    /**
     * إنشاء إشعار واحد، مع ابتلاع أي خطأ.
     */
    protected function push(int $userId, string $type, string $title, string $message, array $data = []): void
    {
        try {
            AppNotification::create([
                'user_id' => $userId,
                'type'    => $type,
                'title'   => $title,
                'message' => $message,
                'data'    => $data ?: null,
                'seen'    => false,
            ]);
        } catch (\Throwable $e) {
            // متعمَّد: تسجيل الإشعار ليس جزءاً من الحركة المالية.
            report($e);
        }
    }

    /**
     * ابن سجّل مصروفاً. يُبلَّغ أولياء الأمور فقط — لا معنى لإشعار المستخدم
     * بفعل قام به هو للتو.
     */
    /**
     * النسبة التي يبدأ عندها التحذير من قرب انتهاء المصروف.
     *
     * 0.8 وليس 0.9: التحذير الذي يصل ولم يبقَ إلا عُشر المبلغ يصل متأخراً —
     * لا يكفي ولي الأمر ليقرر ويتصرف قبل أن تُرفض عملية الابن.
     */
    public const APPROACHING_RATIO = 0.8;

    /**
     * اقترب الابن من نهاية مصروفه.
     *
     * يُبلَّغ **الطرفان**، بخلاف memberSpent: الابن ليعرف أن ما تبقّى له قليل
     * قبل أن يُفاجأ برفض، وولي الأمر ليقرر رفع السقف أو السؤال عن وجه الصرف.
     * هذا هو الغرض الأساسي من الميزة — أن يصل التنبيه قبل المنع لا بعده.
     *
     * $spentBefore و$spentAfter يُمرَّران معاً لأن الشرط هو **العبور**: تنبيه
     * عند كل مصروف تالٍ بعد تجاوز 80% يتحول إلى ضجيج يُتجاهَل، فيضيع التنبيه
     * الوحيد الذي كان مهماً.
     */
    public function limitApproaching(User $member, float $spentBefore, float $spentAfter, float $limit): void
    {
        if ($member->isParent() || $limit <= 0) {
            return;
        }

        $threshold = $limit * self::APPROACHING_RATIO;

        // عبور العتبة الآن فقط. ولو تجاوز المبلغ السقف كاملاً فالعملية مرفوضة
        // أصلاً ولن تصل إلى هنا، فلا تعارض مع limitBlocked.
        if ($spentBefore >= $threshold || $spentAfter < $threshold) {
            return;
        }

        $remaining = max(0, $limit - $spentAfter);
        $remainingText = number_format($remaining, 2);
        $limitText = number_format($limit, 2);
        $percent = (int) round(($spentAfter / $limit) * 100);

        $data = [
            'member_id'   => $member->id,
            'member_name' => $member->name,
            'spent'       => $spentAfter,
            'remaining'   => $remaining,
            'limit'       => $limit,
            'percent'     => $percent,
        ];

        $this->push(
            $member->id,
            AppNotification::TYPE_LIMIT_APPROACHING,
            'اقتربت من نهاية مصروفك',
            "صرفت {$percent}% من مصروفك. المتبقي لك {$remainingText} من أصل {$limitText}.",
            $data
        );

        foreach ($this->parents() as $parent) {
            $this->push(
                $parent->id,
                AppNotification::TYPE_LIMIT_APPROACHING,
                'اقترب مصروف الابن من نهايته',
                "صرف {$member->name} {$percent}% من مصروفه. المتبقي له {$remainingText} من أصل {$limitText}.",
                $data
            );
        }
    }

    public function memberSpent(User $member, Transaction $transaction): void
    {
        if ($member->isParent()) {
            return;
        }

        $amount = number_format((float) $transaction->amount, 2);

        foreach ($this->parents() as $parent) {
            $this->push(
                $parent->id,
                AppNotification::TYPE_MEMBER_SPENT,
                'مصروف جديد',
                "سجّل {$member->name} مصروفاً بقيمة {$amount}.",
                [
                    'transaction_id' => $transaction->id,
                    'member_id'      => $member->id,
                    'member_name'    => $member->name,
                    'amount'         => (float) $transaction->amount,
                ]
            );
        }
    }

    /**
     * محاولة صرف تجاوزت سقف السحب ورُفضت.
     *
     * يُبلَّغ الطرفان: الابن ليعرف لماذا رُفضت عمليته بعد أن يغلق رسالة الخطأ،
     * وولي الأمر لأن تكرار المحاولات إشارة إلى أن السقف صار ضيقاً.
     */
    public function limitBlocked(User $member, float $attempted, float $spent, float $limit): void
    {
        $attemptedText = number_format($attempted, 2);
        $limitText     = number_format($limit, 2);
        $remaining     = max(0, $limit - $spent);
        $remainingText = number_format($remaining, 2);

        $payload = [
            'member_id'   => $member->id,
            'member_name' => $member->name,
            'attempted'   => $attempted,
            'limit'       => $limit,
            'remaining'   => $remaining,
        ];

        $this->push(
            $member->id,
            AppNotification::TYPE_LIMIT_BLOCKED,
            'تم رفض العملية',
            "مبلغ {$attemptedText} يتجاوز سقف سحبك. المتبقي لك {$remainingText} من أصل {$limitText}.",
            $payload
        );

        foreach ($this->parents() as $parent) {
            $this->push(
                $parent->id,
                AppNotification::TYPE_LIMIT_BLOCKED,
                'محاولة تجاوز سقف السحب',
                "حاول {$member->name} صرف {$attemptedText} وتجاوز بذلك سقف سحبه البالغ {$limitText}.",
                $payload
            );
        }
    }

    /**
     * ولي الأمر عدّل سقف سحب ابن. يُبلَّغ الابن وحده.
     */
    public function limitUpdated(User $member, float $limit): void
    {
        $limitText = number_format($limit, 2);

        $this->push(
            $member->id,
            AppNotification::TYPE_LIMIT_UPDATED,
            'تم تحديث سقف السحب',
            "أصبح سقف سحبك {$limitText}.",
            ['limit' => $limit]
        );
    }

    /**
     * فحص ما إذا كانت عملية جديدة قد جعلت ميزانية فئتها متجاوَزة، وإشعار
     * أولياء الأمور إن حدث.
     *
     * المصروف يُجمَع من جدول transactions ولا يُقرأ من budgets.current_spending:
     * ذلك العمود لا يكتبه أي كود في هذا المشروع ويبقى عند 0.00 دائماً — نفس
     * السبب الذي يجعل تطبيق الموبايل يشتق القيمة بنفسه (انظر BudgetsRepo).
     *
     * يُطلق فقط عند **عبور** الحد، لا في كل مرة تكون الميزانية متجاوَزة، وإلا
     * تحوّل كل مصروف لاحق إلى إشعار مكرر.
     */
    public function checkBudget(Transaction $transaction, float $spentBefore): void
    {
        if ($transaction->type !== 'expense') {
            return;
        }

        $budgets = Budget::with('category')
            ->where('category_id', $transaction->category_id)
            ->whereDate('start_date', '<=', $transaction->date)
            ->whereDate('end_date', '>=', $transaction->date)
            ->get();

        foreach ($budgets as $budget) {
            $limit = (float) $budget->limit_amount;
            $spentAfter = $spentBefore + (float) $transaction->amount;

            // عبور الحد الآن فقط. إن كانت متجاوَزة أصلاً فقد أُرسل الإشعار سابقاً.
            if ($spentBefore > $limit || $spentAfter <= $limit) {
                continue;
            }

            $categoryName = $budget->category->name ?? 'غير مصنّف';
            $over = number_format($spentAfter - $limit, 2);

            foreach ($this->parents() as $parent) {
                $this->push(
                    $parent->id,
                    AppNotification::TYPE_BUDGET_EXCEEDED,
                    'تجاوز ميزانية',
                    "تجاوزت ميزانية \"{$categoryName}\" بمقدار {$over}.",
                    [
                        'budget_id'   => $budget->id,
                        'category_id' => $budget->category_id,
                        'category'    => $categoryName,
                        'limit'       => $limit,
                        'spent'       => $spentAfter,
                    ]
                );
            }
        }
    }

    /**
     * مجموع المصروف على فئة داخل فترة ميزانية، قبل إضافة العملية الحالية.
     *
     * تُستدعى قبل الحفظ لأن checkBudget تحتاج معرفة الحالة السابقة لتقرر إن كان
     * الحد قد عُبِر الآن. التحويلات مستثناة: نقل المال بين حسابَي العائلة ليس
     * إنفاقاً.
     */
    public function spentBefore(int $categoryId, string $date): float
    {
        return (float) Transaction::where('category_id', $categoryId)
            ->where('type', 'expense')
            ->whereNull('transfer_group_id')
            ->whereDate('date', '<=', $date)
            ->sum('amount');
    }
}
