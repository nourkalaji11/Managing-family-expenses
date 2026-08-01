<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\AccountController;
use App\Http\Controllers\BudgetController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\AuthController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// 🟢 مسارات عامة بدون توكن (تسجيل جديد ودخول)
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// 🔒 مسارات محمية بتوكن (Sanctum Middleware)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // مسارات العمليات والفئات والحسابات والميزانيات
    Route::apiResource('transactions', TransactionController::class);
    Route::apiResource('accounts', AccountController::class);
    Route::apiResource('budgets', BudgetController::class);
    Route::apiResource('categories', CategoryController::class);
});