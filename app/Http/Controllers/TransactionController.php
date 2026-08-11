<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class TransactionController extends Controller
{
    /**
     * Display a listing of the resource.
     */

    public function index()
{
    // جلب كل العمليات من قاعدة البيانات مرتبة من الأحدث إلى الأقدم
    // مع جلب بيانات الحساب والفئة التابعة لها لتسهيل العرض في الموبايل
    $transactions = \App\Models\Transaction::with(['account', 'category'])->latest()->get();

    // إرجاع البيانات بصيغة JSON
    return response()->json([
        'message' => 'تم جلب جميع العمليات بنجاح',
        'data'    => $transactions
    ], 200); // 200 تعني OK
}
    

    /**
     * Store a newly created resource in storage.
     */
     public function store(Request $request)
{
    // 1. التحقق من صحة البيانات القادمة من تطبيق الموبايل
    $validated = $request->validate([
        'account_id'   => 'required|exists:accounts,id',
        'category_id'  => 'required|exists:categories,id',
        'amount'       => 'required|numeric|min:0.01',
        'type'         => 'required|in:income,expense', // إما إيراد أو مصروف
        'description'  => 'nullable|string|max:255',
        'date'         => 'required|date',
    ]);

    // 2. تسجيل العملية مباشرة في قاعدة البيانات
    $validated['user_id'] = auth()->id();
    $transaction = \App\Models\Transaction::create($validated);

    // 3. إرجاع رد نجاح للتطبيق بصيغة JSON
    return response()->json([
        'message' => 'تم تسجيل العملية بنجاح!',
        'data'    => $transaction
    ], 201);
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
    

