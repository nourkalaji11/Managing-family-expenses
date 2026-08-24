<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AccountController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\BudgetController;

/*
|--------------------------------------------------------------------------
| Public Routes (المسارات العامة)
|--------------------------------------------------------------------------
*/
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

/*
|--------------------------------------------------------------------------
| Protected Routes (المسارات المحمية بـ التوكن)
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {

    // الروابط الأساسية البروفايل والخروج
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'me']);

    // الداشبورد الإحصائي
    Route::get('/dashboard', function() {
        return response()->json(['message' => 'مرحباً بك في لوحة تحكم إدارة العائلة']);
    });

    // مسارات الحسابات المادية (Accounts)
    Route::get('/accounts', [AccountController::class, 'index']);
    Route::post('/accounts', [AccountController::class, 'store']);
    Route::put('/accounts/{id}', [AccountController::class, 'update']);
    Route::delete('/accounts/{id}', [AccountController::class, 'destroy']);

    // مسارات فئات المصاريف (Categories)
    Route::get('/categories', [CategoryController::class, 'index']);
    Route::post('/categories', [CategoryController::class, 'store']);
    Route::put('/categories/{id}', [CategoryController::class, 'update']);
    Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);

    // مسارات العمليات والفلترة (Transactions)
    Route::get('/transactions', [TransactionController::class, 'index']); // 👈 هاد يلي عدلنا دالته ليفلتر بالبوست مان
    Route::post('/transactions', [TransactionController::class, 'store']);
    Route::put('/transactions/{id}', [TransactionController::class, 'update']);
    Route::delete('/transactions/{id}', [TransactionController::class, 'destroy']);

    // مسارات الميزانيات للأولاد (Budgets)
    Route::get('/budgets', [BudgetController::class, 'index']);
    Route::post('/budgets', [BudgetController::class, 'store']);
    Route::put('/budgets/{id}', [BudgetController::class, 'update']);
    Route::delete('/budgets/{id}', [BudgetController::class, 'destroy']);
});