<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// 1. استيراد المتحكمات الأربعة الخاصة بمشروع الميزانية
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\AccountController;
use App\Http\Controllers\BudgetController;
use App\Http\Controllers\CategoryController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// مسارات العمليات والنفقات (التي جهزنا دوالها بالكامل)
Route::apiResource('transactions', TransactionController::class);

// مسارات باقي الجداول (حسابات، ميزانيات، فئات)
Route::apiResource('accounts', AccountController::class);
Route::apiResource('budgets', BudgetController::class);
Route::apiResource('categories', CategoryController::class);
