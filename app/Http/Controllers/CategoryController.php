<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Category;

class CategoryController extends Controller
{
    /**
     * عرض جميع فئات المصاريف المتاحة بالتطبيق
     */
    public function index()
    {
        // جلب الفئات مرتبة أبجدياً حسب الاسم
        $categories = Category::orderBy('name', 'asc')->get();

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
}