<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ScopesToFamily;
use App\Models\Account;
use App\Models\Budget;
use App\Models\Transaction;
use Illuminate\Http\Request;

/**
 * كل ما ترسمه الشاشة الرئيسية، في طلب واحد.
 *
 * ---------------------------------------------------------------------------
 * النسخة السابقة كانت ترد بأربعة أرقام لا تكفي لرسم الشاشة: لا دخل، ولا توزيع
 * فئات، ولا آخر العمليات، ولا حساب لسطر "رقم الحساب العائلي". فكان التطبيق
 * يتجاهل هذا المسار كلياً ويجلب /accounts و/transactions ثم يجمّع كل شيء على
 * الجهاز — أي أنه ينزّل كل عملية في تاريخ العائلة ليحسب ثلاثة أرقام.
 *
 * الآن يُحسب هنا. ثلاث نتائج مباشرة:
 *   - طلب واحد بدل اثنين.
 *   - الأرقام تشمل كل الصفوف لا ما صادف أن حمّله العميل.
 *   - ‏/transactions يصبح قابلاً للتقسيم إلى صفحات افتراضياً، وهو ما كان
 *     ممنوعاً ما دام العميل يجمّع من المجموعة كاملة.
 *
 * التحويلات مستثناة من الدخل والمصاريف والتوزيع: نقل المال بين حسابَي العائلة
 * يكتب صف مصروف وصف إيراد حقيقيين — وهذا ما يبقي الرصيدين صحيحين — لكن عدّهما
 * ينفخ الرقمين معاً دون أن يدخل أو يخرج ريال واحد. نفس الاستثناء مطبَّق في
 * NotificationService وBudgetController وفي DashboardSummary بتطبيق الموبايل،
 * فلا يمكن للأربعة أن تتناقض.
 * ---------------------------------------------------------------------------
 */
class DashboardController extends Controller
{
    use ScopesToFamily;

    /** عدد شرائح التوزيع قبل تجميع الباقي في "أخرى". يطابق تصميم الشاشة. */
    public const TOP_CATEGORIES = 3;

    /** عدد صفوف "آخر المعاملات". */
    public const RECENT_LIMIT = 3;

    public function index(Request $request)
    {
        $user = $request->user();

        // العمليات مقيَّدة بالدور، والحسابات مشتركة — انظر ScopesToFamily.
        // الرصيد الإجمالي يظهر للطرفين: الحسابات مرئية للجميع أصلاً، فإخفاء
        // مجموعها عن الابن مسرحية يستطيع تجاوزها بجمع القائمة بنفسه.
        $scoped = fn () => $this->scopeToViewer(Transaction::query(), $user);

        $totals = $this->totals($scoped);
        $breakdown = $this->breakdown($scoped, $totals['expenses']);

        $recent = $this->scopeToViewer(
            Transaction::with(['account', 'category', 'user'])->latest(),
            $user
        )->limit(self::RECENT_LIMIT)->get();

        $data = [
            'role' => $user->role,
            'total_balance' => (float) Account::sum('balance'),
            'income' => $totals['income'],
            'expenses' => $totals['expenses'],
            // قد يكون سالباً حين تتجاوز المصاريف الدخل، وهو الرقم الصادق —
            // الواجهة تقرر كيف تلوّنه.
            'remaining' => round($totals['income'] - $totals['expenses'], 2),
            'breakdown' => $breakdown,
            'recent_transactions' => $recent,

            // TODO(backend): "الحساب العائلي" لا وجود له في المخطط — لا عمود
            // is_primary ولا رقم حساب. هذا أحدث حساب أُنشئ، وهو نائب للعرض لا
            // أكثر. تحديده فعلياً يحتاج تغييراً في المخطط لا نقطة نهاية جديدة.
            'primary_account' => Account::latest()->first(),
        ];

        if ($user->isParent()) {
            $data['alerts'] = $this->alerts();
        } else {
            // null يبقى null حتى الواجهة: الشاشة ترسم "لا يوجد سقف" بدل
            // شريط ممتلئ عند 0، وهما رسالتان متعاكستان.
            $limit = $user->spending_limit === null
                ? null
                : (float) $user->spending_limit;
            // ما يُحتسب على السقف: مصاريف هذا المستخدم، دون التحويلات — نفس
            // القاعدة التي يطبّقها TransactionController::store عند الفحص، وإلا
            // اختلف الرقم المعروض عن الرقم الذي يمنع العملية.
            $spent = (float) Transaction::where('user_id', $user->id)
                ->where('type', 'expense')
                ->whereNull('transfer_group_id')
                ->sum('amount');

            $data['spending_limit'] = $limit;
            $data['spent_of_limit'] = round($spent, 2);
            $data['remaining_limit'] = $limit === null
                ? null
                : round(max(0, $limit - $spent), 2);
        }

        return response()->json([
            'message' => 'تم جلب بيانات لوحة التحكم بنجاح',
            'data' => $data,
        ], 200);
    }

    /**
     * مجموع الدخل والمصاريف، بمرورين على قاعدة البيانات لا بتحميل الصفوف.
     *
     * الفترة: كل العمليات. الشاشة لا تعرض أي منتقي فترة، والتطبيق كان يجمع
     * المجموعة كاملة، فتقييدها بشهر هنا كان سيغيّر كل رقم على الشاشة دون أن
     * يطلب أحد ذلك.
     */
    private function totals(callable $scoped): array
    {
        $sum = fn (string $type) => (float) $scoped()
            ->where('type', $type)
            ->whereNull('transfer_group_id')
            ->sum('amount');

        return [
            'income' => round($sum('income'), 2),
            'expenses' => round($sum('expense'), 2),
        ];
    }

    /**
     * شرائح المصاريف: أعلى فئات إنفاقاً، والباقي مجمَّعاً في "أخرى".
     *
     * التجميع في SQL؛ ما يعود هو صف واحد لكل فئة لا كل العمليات.
     */
    private function breakdown(callable $scoped, float $expenses): array
    {
        if ($expenses <= 0) {
            return [];
        }

        $rows = $scoped()
            ->selectRaw('category_id, SUM(amount) as total')
            ->where('type', 'expense')
            ->whereNull('transfer_group_id')
            ->groupBy('category_id')
            ->orderByDesc('total')
            ->with('category')
            ->get();

        $slices = [];
        $otherTotal = 0.0;

        foreach ($rows as $index => $row) {
            $total = (float) $row->total;

            if ($index < self::TOP_CATEGORIES) {
                $slices[] = [
                    'category_id' => $row->category_id,
                    'category' => $row->category->name ?? null,
                    'total' => round($total, 2),
                    'fraction' => round($total / $expenses, 4),
                    'is_other' => false,
                ];
                continue;
            }

            $otherTotal += $total;
        }

        if ($otherTotal > 0) {
            // شريحة مركّبة لا صف في جدول الفئات، ولهذا category_id فيها null —
            // وهو ما يميّزها للعميل.
            $slices[] = [
                'category_id' => null,
                'category' => null,
                'total' => round($otherTotal, 2),
                'fraction' => round($otherTotal / $expenses, 4),
                'is_other' => true,
            ];
        }

        return $slices;
    }

    /**
     * الميزانيات المتجاوَزة، لولي الأمر.
     *
     * كان الفلتر `whereColumn('current_spending', '>=', 'limit_amount')`، وهو
     * لا يطابق شيئاً أبداً: العمود لا يكتبه أي كود في المشروع فيبقى عند 0.00 —
     * أي أن التنبيهات كانت مصفوفة فارغة دائماً منذ كُتبت. المصروف يُجمع هنا من
     * جدول العمليات، كما تفعل BudgetController::index.
     */
    private function alerts(): array
    {
        $alerts = [];

        foreach (Budget::with(['user', 'category'])->get() as $budget) {
            $spent = (float) Transaction::where('category_id', $budget->category_id)
                ->where('user_id', $budget->user_id)
                ->where('type', 'expense')
                ->whereNull('transfer_group_id')
                ->whereBetween('date', [$budget->start_date, $budget->end_date])
                ->sum('amount');

            $limit = (float) $budget->limit_amount;
            if ($spent < $limit) {
                continue;
            }

            $owner = $budget->user->name ?? 'أحد أفراد العائلة';
            $category = $budget->category->name ?? 'غير مصنّف';

            $alerts[] = [
                'budget_id' => $budget->id,
                'user_id' => $budget->user_id,
                'user_name' => $owner,
                'category' => $category,
                'limit' => round($limit, 2),
                'spent' => round($spent, 2),
                'over_by' => round($spent - $limit, 2),
                'message' => "تجاوز {$owner} ميزانية {$category}",
            ];
        }

        return $alerts;
    }
}
