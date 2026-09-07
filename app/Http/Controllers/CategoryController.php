<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Budget;
use App\Models\Category;
use App\Models\Transaction;

class CategoryController extends Controller
{
    use \App\Http\Controllers\Concerns\ScopesToFamily;

    /**
     * عرض جميع فئات المصاريف المتاحة بالتطبيق
     */
    public function index(Request $request)
    {
        // عدّادان يغنيان العميل عن جلب /transactions و/budgets كاملين:
        //   transactions_count → الرقم تحت اسم الفئة في الشبكة.
        //   budgets_count      → حارس الحذف؛ destroy يرد 409 إن أشار إليها أي
        //                        منهما، والواجهة تخبر المستخدم قبل أن يضغط.
        //
        // أطراف التحويل مستثناة من عدّ العمليات: فئة التحويل يختارها النموذج
        // اضطراراً لأن transactions.category_id غير قابل للإفراغ، فعدّها ينفخ
        // فئة لا علاقة لها بالأمر. عدّ الحسابات يشملها، لأن التحويل يمسّ
        // الحسابين فعلاً.
        // العدّاد مقيَّد بالدور مثل القائمة نفسها: كان يعدّ عمليات العائلة كلها،
        // فيقرأ الابن تحت "المطاعم" رقماً يشمل مصاريف أبيه — أي أنه يستدلّ على
        // نشاط لا يُسمح له برؤيته من عدّاد بريء الشكل.
        //
        // budgets_count يبقى بلا قيد: وظيفته حارس الحذف، وفئة تستعملها ميزانية
        // شخص آخر يجب أن تظل ممنوعة الحذف بصرف النظر عمّن يسأل.
        $viewer = $request->user();

        $categories = Category::query()
            ->withCount([
                'transactions as transactions_count' => fn ($query) =>
                    $this->scopeToViewer(
                        $query->whereNull('transfer_group_id'),
                        $viewer
                    ),
                'budgets as budgets_count',
            ])
            // مرتَّبة بترتيب الإنشاء لا بالاسم: الشجرة تُعرض كما زرعها
            // CategorySeeder — المجموعة ثم فروعها — والترتيب الأبجدي يبعثر
            // الفرع عن مجموعته ويقلب ترتيباً مقصوداً في التطبيق المرجعي.
            ->when(
                $request->filled('type'),
                fn ($query) => $query->where('type', $request->string('type')),
            )
            ->orderBy('id', 'asc')
            ->get();

        return response()->json([
            'message' => 'تم جلب فئات المصاريف بنجاح',
            'data'    => $categories
        ], 200);
    }

    /**
     * إنشاء فئة مصاريف جديدة (مثلاً: مواصلات، تسوق...)
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            // التكرار ممنوع داخل المجموعة الواحدة لا في الجدول كله: "الهدايا"
            // فئة دخل وفرع تحت التبرعات معاً، و"دين" مجموعة رئيسية وفرع تحت
            // "أخرى" — وقاعدة unique على الاسم وحده كانت تمنع نصف الشجرة.
            'name'      => 'required|string|max:50',
            'type'      => 'nullable|string|in:' . implode(',', Category::TYPES),
            'parent_id' => 'nullable|exists:categories,id',
            'icon'      => 'nullable|string|max:60',
        ]);

        $type = $validated['type'] ?? Category::TYPE_EXPENSE;
        $parentId = $validated['parent_id'] ?? null;

        $taken = Category::where('name', $validated['name'])
            ->where('type', $type)
            ->where('parent_id', $parentId)
            ->exists();

        if ($taken) {
            return response()->json([
                'message' => 'يوجد فئة بهذا الاسم في المكان نفسه.'
            ], 422);
        }

        $category = Category::create([
            'name'      => $validated['name'],
            'type'      => $type,
            'parent_id' => $parentId,
            'icon'      => $validated['icon'] ?? null,
        ]);

        return response()->json([
            'message' => 'تم إنشاء الفئة بنجاح!',
            'data'    => $category
        ], 201);
    }

    /**
     * تعديل اسم فئة موجودة.
     *
     * الدالة كانت غائبة رغم أن المسار PUT /categories/{id} مسجَّل في
     * routes/api.php، أي أن استدعاءه كان يرمي 500 لا 404.
     */
    public function update(Request $request, string $id)
    {
        $category = Category::find($id);

        if (!$category) {
            return response()->json([
                'message' => 'الفئة غير موجودة!'
            ], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:50',
            'icon' => 'nullable|string|max:60',
        ]);

        // التفرّد داخل المجموعة، كما في store — و`unique:categories,name` هنا
        // كانت سترفض تسمية فرع باسم يحمله فرع في مجموعة أخرى، وهو مسموح.
        $taken = Category::where('name', $validated['name'])
            ->where('type', $category->type)
            ->where('parent_id', $category->parent_id)
            ->whereKeyNot($category->id)
            ->exists();

        if ($taken) {
            return response()->json([
                'message' => 'يوجد فئة بهذا الاسم في المكان نفسه.'
            ], 422);
        }

        // النوع والأب لا يُعدَّلان من هنا: نقل فئة بين التبويبات يترك عمليات
        // مصنَّفة تحت نوع لا تنتمي إليه.
        $category->update($validated);

        return response()->json([
            'message' => 'تم تعديل الفئة بنجاح!',
            'data'    => $category
        ], 200);
    }

    /**
     * حذف فئة.
     *
     * مرفوض إذا كانت الفئة مستخدمة في عمليات أو ميزانيات: المفتاحان الأجنبيان
     * في كلا الجدولين معرَّفان بـ onDelete('cascade')، فحذف الفئة يمحو معها كل
     * عملية وكل ميزانية تتبع لها صامتاً.
     */
    public function destroy(string $id)
    {
        $category = Category::find($id);

        if (!$category) {
            return response()->json([
                'message' => 'الفئة غير موجودة!'
            ], 404);
        }

        $transactionsCount = Transaction::where('category_id', $category->id)->count();
        $budgetsCount      = Budget::where('category_id', $category->id)->count();

        if ($transactionsCount > 0 || $budgetsCount > 0) {
            return response()->json([
                'message' => "لا يمكن حذف هذه الفئة لأنها مستخدمة في {$transactionsCount} عملية و {$budgetsCount} ميزانية.",
            ], 409);
        }

        $category->delete();

        return response()->json([
            'message' => 'تم حذف الفئة بنجاح'
        ], 200);
    }
}