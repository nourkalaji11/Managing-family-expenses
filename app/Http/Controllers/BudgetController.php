<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ScopesToFamily;
use App\Models\Budget;
use App\Models\Transaction;
use Illuminate\Http\Request;

class BudgetController extends Controller
{
    use ScopesToFamily;

    /**
     * عرض الميزانيات.
     *
     * ولي الأمر يرى ميزانيات العائلة كلها، والابن يرى ميزانياته وحده. كان
     * الاستعلام بلا أي قيد — انظر ScopesToFamily.
     */
    public function index(Request $request)
    {
        // جلب الميزانيات مع الفئة التابعة لها لتظهر بوضوح في شاشة الموبايل
        $budgets = $this->scopeToViewer(
            Budget::with('category')->latest(),
            $request->user()
        )->get();

        // current_spending يُحسب هنا ولا يُقرأ من العمود: العمود موجود لكن لا
        // يكتبه أي كود في المشروع فيبقى عند 0.00 أبداً. الحساب في السيرفر يعني
        // أن الرقم يشمل كل العمليات لا ما صادف أن حمّله العميل.
        //
        // التحويلات مستثناة: طرف التحويل الصادر مصروف مصنَّف تحت فئة اختارها
        // النموذج اضطراراً، فاحتسابه يستهلك ميزانية لم تُنفَق فعلاً. نفس
        // الاستثناء مطبَّق في NotificationService::spentBefore وفي BudgetsRepo
        // بتطبيق الموبايل، فلا يمكن للثلاثة أن تتناقض.
        foreach ($budgets as $budget) {
            $budget->current_spending = (float) Transaction::query()
                ->where('category_id', $budget->category_id)
                ->where('user_id', $budget->user_id)
                ->where('type', 'expense')
                ->whereNull('transfer_group_id')
                ->whereBetween('date', [$budget->start_date, $budget->end_date])
                ->sum('amount');
        }

        return response()->json([
            'message' => 'تم جلب الميزانيات بنجاح',
            'data'    => $budgets
        ], 200);
    }

    /**
     * إنشاء ميزانية جديدة أو تحديثها لفئة معينة
     */
    public function store(Request $request)
    {
        // 1. فحص الأمان للبيانات القادمة من تطبيق الموبايل.
        //    user_id لا يُقبل من الطلب: يؤخذ من التوكن، وإلا صار بإمكان أي
        //    مستخدم إنشاء ميزانية باسم مستخدم آخر بمجرد تغيير رقم في الطلب.
        $validated = $request->validate([
            'category_id'  => 'required|exists:categories,id',
            'limit_amount' => 'required|numeric|min:0.01',
            'start_date'  =>  'required|date',
            'end_date'    =>  'required|date|after_or_equal:start_date',
        ]);

        $validated['user_id'] = auth()->id();

        // 2. حفظ الميزانية أو تحديثها. مفتاح المطابقة يشمل user_id، وإلا كانت
        //    ميزانية عائلة تكتب فوق ميزانية عائلة أخرى لنفس الفئة.
        $budget = Budget::updateOrCreate(
            [
                'category_id' => $validated['category_id'],
                'user_id'     => $validated['user_id'],
            ],
            $validated
        );

        // اسم الفئة يُعرض على بطاقة الميزانية في الموبايل مباشرةً بعد الحفظ.
        $budget->load('category');

        return response()->json([
            'message' => 'تم حفظ الميزانية بنجاح!',
            'data'    => $budget
        ], 201);
    }

    /**
     * تعديل ميزانية موجودة.
     *
     * الدالة كانت غائبة كلياً رغم أن المسار PUT /budgets/{id} مسجَّل في
     * routes/api.php، أي أن استدعاءه كان يرمي خطأ 500 لا 404.
     */
    public function update(Request $request, string $id)
    {
        $budget = Budget::find($id);

        if (!$budget) {
            return response()->json([
                'message' => 'الميزانية غير موجودة!'
            ], 404);
        }

        // قصر index وحده يمنع التصفح لا الوصول. 404 لا 403، حتى لا يؤكد الرد
        // وجود صف لمستخدم آخر.
        if (! $this->viewerOwns($request->user(), $budget->user_id)) {
            return response()->json([
                'message' => 'الميزانية غير موجودة!'
            ], 404);
        }

        // نفس قواعد store، حتى لا يقبل التعديل ما يرفضه الإنشاء.
        $validated = $request->validate([
            'category_id'  => 'required|exists:categories,id',
            'limit_amount' => 'required|numeric|min:0.01',
            'start_date'  =>  'required|date',
            'end_date'    =>  'required|date|after_or_equal:start_date',
        ]);

        // user_id غير موجود ضمن $validated، فيبقى المالك الأصلي كما هو.
        $budget->update($validated);
        $budget->load('category');

        return response()->json([
            'message' => 'تم تعديل الميزانية بنجاح!',
            'data'    => $budget
        ], 200);
    }

    /**
     * حذف ميزانية.
     *
     * الدالة كانت غائبة تماماً رغم أن المسار DELETE /budgets/{id} مسجَّل، أي أن
     * استدعاءه كان يرمي 500 لا 404 — آخر ثغرة من نوعها في هذا المشروع.
     *
     * لا حارس استعمال هنا، بخلاف الحسابات والفئات: الميزانية سقف يخص فترة، ولا
     * يشير إليها أي صف آخر. حذفها لا يفقد بيانات، والعمليات التي كانت تُحتسب
     * ضمنها تبقى كما هي.
     */
    public function destroy(Request $request, string $id)
    {
        $budget = Budget::find($id);

        if (!$budget) {
            return response()->json([
                'message' => 'الميزانية غير موجودة!'
            ], 404);
        }

        if (! $this->viewerOwns($request->user(), $budget->user_id)) {
            return response()->json([
                'message' => 'الميزانية غير موجودة!'
            ], 404);
        }

        $budget->delete();

        return response()->json([
            'message' => 'تم حذف الميزانية بنجاح'
        ], 200);
    }
}