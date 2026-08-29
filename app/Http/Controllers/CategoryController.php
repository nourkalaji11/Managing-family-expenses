<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Budget;
use App\Models\Category;
use App\Models\Transaction;

class CategoryController extends Controller
{
    /**
     * عرض جميع فئات المصاريف المتاحة بالتطبيق
     */
    public function index()
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
        $categories = Category::query()
            ->withCount([
                'transactions as transactions_count' => fn ($query) =>
                    $query->whereNull('transfer_group_id'),
                'budgets as budgets_count',
            ])
            ->orderBy('name', 'asc')
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
        // فحص أمان الاسم ومنع التكرار
        $validated = $request->validate([
            'name' => 'required|string|max:50|unique:categories,name',
        ]);

        $category = Category::create($validated);

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

        // قاعدة unique تستثني الفئة نفسها، وإلا فشل حفظ الفئة دون تغيير اسمها.
        $validated = $request->validate([
            'name' => 'required|string|max:50|unique:categories,name,' . $category->id,
        ]);

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