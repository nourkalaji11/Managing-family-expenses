<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Budget;

class BudgetController extends Controller
{
    /**
     * عرض جميع الميزانيات المحددة
     */
    public function index()
    {
        // جلب الميزانيات مع الفئة التابعة لها لتظهر بوضوح في شاشة الموبايل
        $budgets = Budget::with('category')->latest()->get();

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
        // 1. فحص الأمان للبيانات القادمة من تطبيق الموبايل
        $validated = $request->validate([
            'category_id'  => 'required|exists:categories,id',
            'limit_amount' => 'required|numeric|min:0.01',
            'start_date'  =>  'required|date',
            'end_date'    =>  'required|date|after_or_equal:start_date',
            'user_id'     =>  'required|exists:users,id',
        ]);

        // 2. حفظ الميزانية أو تحديثها بشكل ذكي في قاعدة البيانات
        $budget = Budget::updateOrCreate(
            ['category_id' => $validated['category_id']],
            $validated
        );

        return response()->json([
            'message' => 'تم حفظ الميزانية بنجاح!',
            'data'    => $budget
        ], 201);
    }
}