<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Account;

class AccountController extends Controller
{
    /**
     * عرض جميع الحسابات المالية للعائلة
     */
    public function index()
    {
        // جلب الحسابات مرتبة من الأحدث للأقدم
        $accounts = Account::latest()->get();

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
            'user_id' => 'required|exists:users,id',
            'name'    => 'required|string|max:100',
            'balance' => 'required|numeric',
        ]);

        // 2. حفظ الحساب الجديد في قاعدة البيانات
        $account = Account::create($validated);

        return response()->json([
            'message' => 'تم إنشاء الحساب المالي بنجاح!',
            'data'    => $account
        ], 201);
    }
}