<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Account;
use App\Models\Transaction;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
    {
    public function index(Request $request)
    {
        // 1. بناء الاستعلام وجلب العمليات مع فئات الصرف والحساب البنكي وترتيبها من الأحدث للأقدم
        $query = \App\Models\Transaction::with(['account', 'category'])->latest();
    
        // 2. فلترة حسب مستخدم معين (ابن محدد) إذا تم إرسال user_id بالـ Postman
        if ($request->has('user_id') && $request->user_id != null) {
            $query->where('user_id', $request->user_id);
        }
    
        // 3. فلترة حسب فئة معينة (طعام، مواصلات...) إذا تم إرسال category_id
        if ($request->has('category_id') && $request->category_id != null) {
            $query->where('category_id', $request->category_id);
        }
    
        // 4. فلترة حسب تاريخ محدد (من تاريخ إلى تاريخ) إذا أرسل الأب نطاقاً زمنياً
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('date', [$request->start_date, $request->end_date]);
        }
    
        // 5. تنفيذ الاستعلام النهائي وجلب البيانات المفلترة
        $transactions = $query->get();
    
        return response()->json([
            'message' => 'تم جلب العمليات المفلترة بنجاح',
            'data'    => $transactions
        ], 200);
    }

     public function store(Request $request)
    {
        // 1. التحقق من صحة البيانات
        $validated = $request->validate([
            'account_id'  => 'required|exists:accounts,id',
            'category_id' => 'required|exists:categories,id',
            'amount'      => 'required|numeric|min:0.01',
            'type'        => 'required|in:income,expense',
            'description' => 'nullable|string|max:255',
            'date'        => 'required|date',
        ]);

        $user = auth()->user();

        // 2. التحقق من حد السحب الخاص بالابن عند إضافة مصروف
        if ($user->role === 'member' && $validated['type'] === 'expense') {
            $totalSpent = Transaction::where('user_id', $user->id)
                ->where('type', 'expense')
                ->sum('amount');

            if (($totalSpent + $validated['amount']) > $user->spending_limit) {
                return response()->json([
                    'message'        => 'عذراً، هذا المبلغ يتجاوز حد السحب المسموح لك به من قبل الأب.',
                    'spending_limit' => (float)$user->spending_limit,
                    'current_spent'  => (float)$totalSpent,
                    'remaining'      => (float)max(0, $user->spending_limit - $totalSpent)
                ], 403);
            }
        }

        // 3. حفظ العملية وتحديث الرصيد داخل DB::transaction
        return \DB::transaction(function () use ($validated) {
            $account = Account::findOrFail($validated['account_id']);

            if ($validated['type'] === 'expense') {
                $account->balance -= $validated['amount'];
            } else {
                $account->balance += $validated['amount'];
            }
            $account->save();

            $validated['user_id'] = auth()->id();
            $transaction = Transaction::create($validated);

            return response()->json([
                'message' => 'تم تسجيل العملية وتحديث الرصيد بنجاح',
                'data'    => $transaction
            ], 201);
        });
    }
    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    
        
{
    // البحث عن العملية بواسطة الـ ID
    $transaction = \App\Models\Transaction::find($id);

    // إذا لم نجد العملية، نرسل رسالة خطأ للموبايل
    if (!$transaction) {
        return response()->json([
            'message' => 'العملية غير موجودة!'
        ], 404); // 404 تعني Not Found
    }

    // حذف العملية من قاعدة البيانات
    $transaction->delete();

    return response()->json([
        'message' => 'تم حذف العملية بنجاح'
    ], 200);
}
    }