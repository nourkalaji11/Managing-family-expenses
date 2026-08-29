<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Account;
use App\Models\Transaction;

class AccountController extends Controller
{
    /**
     * عرض جميع الحسابات المالية للعائلة
     */
    public function index()
    {
        // withCount يضيف transactions_count بجملة فرعية واحدة.
        //
        // بدونه كان تطبيق الموبايل يجلب /transactions كاملة لمجرد عدّ عمليات كل
        // حساب وعرض الرقم تحت اسمه — أي تنزيل كل عملية في تاريخ العائلة من أجل
        // سطر فرعي. والعدّ هنا يشمل كل الصفوف، لا ما صادف أن حمّله العميل.
        //
        // أطراف التحويل محسوبة عمداً: التحويل يمسّ الحسابين فعلاً، بخلاف فئته
        // التي هي حشو — انظر CategoryController::index.
        $accounts = Account::withCount('transactions')->latest()->get();

        return response()->json([
            'message' => 'تم جلب الحسابات المالية بنجاح',
            'data'    => $accounts
        ], 200);
    }

    /**
     * إنشاء حساب مالي جديد (كاش، بطاقة ائتمان...)
     */
    public function store(Request $request)
    {
        // 1. فحص صحة البيانات القادمة من تطبيق الموبايل
        $validated = $request->validate([
            'name'    => 'required|string|max:100',
            'balance' => 'required|numeric',
        ]);
        $validated['user_id'] = auth()->id();

        // 2. حفظ الحساب الجديد في قاعدة البيانات
        $account = Account::create($validated);

        return response()->json([
            'message' => 'تم إنشاء الحساب المالي بنجاح!',
            'data'    => $account
        ], 201);
    }

    /**
     * تعديل حساب مالي موجود.
     *
     * الدالة كانت غائبة رغم أن المسار PUT /accounts/{id} مسجَّل في
     * routes/api.php، أي أن استدعاءه كان يرمي 500 لا 404.
     *
     * ملاحظة: تعديل balance هنا يكتب الرصيد مباشرةً ولا يمرّ على منطق العمليات.
     * هذا مقصود: الشاشة تسميه "الرصيد الافتتاحي"، وهو تصحيح يدوي للرصيد وليس
     * عملية مالية. التعديلات الناتجة عن العمليات يتكفل بها TransactionController.
     */
    public function update(Request $request, string $id)
    {
        $account = Account::find($id);

        if (!$account) {
            return response()->json([
                'message' => 'الحساب غير موجود!'
            ], 404);
        }

        $validated = $request->validate([
            'name'    => 'required|string|max:100',
            'balance' => 'required|numeric',
        ]);

        // user_id غير موجود ضمن $validated، فيبقى المالك الأصلي كما هو.
        $account->update($validated);

        return response()->json([
            'message' => 'تم تعديل الحساب المالي بنجاح!',
            'data'    => $account
        ], 200);
    }

    /**
     * حذف حساب مالي.
     *
     * الحذف مرفوض إذا كان الحساب يحمل عمليات: المفتاح الأجنبي في
     * create_transactions_table معرَّف بـ onDelete('cascade')، أي أن حذف الحساب
     * يمسح كل عملياته صامتاً. رفض الحذف وإبلاغ المستخدم بالعدد أصدق من محو
     * سجلّ مالي كامل خلف ظهره.
     */
    public function destroy(string $id)
    {
        $account = Account::find($id);

        if (!$account) {
            return response()->json([
                'message' => 'الحساب غير موجود!'
            ], 404);
        }

        $transactionsCount = Transaction::where('account_id', $account->id)->count();

        if ($transactionsCount > 0) {
            return response()->json([
                'message' => "لا يمكن حذف هذا الحساب لأنه مرتبط بـ {$transactionsCount} عملية. احذف العمليات أولاً أو انقلها إلى حساب آخر.",
            ], 409);
        }

        $account->delete();

        return response()->json([
            'message' => 'تم حذف الحساب المالي بنجاح'
        ], 200);
    }
}