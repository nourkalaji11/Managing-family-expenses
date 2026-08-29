<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AccountController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\TransactionController;
use App\Http\Controllers\BudgetController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\TransferController;
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
    Route::put('/profile', [AuthController::class, 'updateProfile']);

    // أفراد العائلة وسقف السحب. ولي الأمر يرى الجميع، والابن يرى نفسه فقط.
    Route::get('/users', [AuthController::class, 'familyMembers']);
    Route::put('/users/{id}/limit', [AuthController::class, 'setSpendingLimit']);

    // الإشعارات داخل التطبيق
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);

    // التحويل بين حسابين. طرفاه عمليتان في transactions تحملان نفس
    // transfer_group_id — انظر TransferController.
    Route::get('/transfers', [TransferController::class, 'index']);
    Route::post('/transfers', [TransferController::class, 'store']);
    Route::delete('/transfers/{group}', [TransferController::class, 'destroy']);

    // الداشبورد الإحصائي
    Route::get('/dashboard', [DashboardController::class, 'index']);

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
    // show كانت مُنفَّذة كدالة فارغة بلا مسار أصلاً. أصبح لها الآن كلاهما.
    Route::get('/transactions/{id}', [TransactionController::class, 'show']);
    Route::post('/transactions', [TransactionController::class, 'store']);
    Route::put('/transactions/{id}', [TransactionController::class, 'update']);
    Route::delete('/transactions/{id}', [TransactionController::class, 'destroy']);

    // مسارات الميزانيات للأولاد (Budgets)
    Route::get('/budgets', [BudgetController::class, 'index']);
    Route::post('/budgets', [BudgetController::class, 'store']);
    Route::put('/budgets/{id}', [BudgetController::class, 'update']);
    Route::delete('/budgets/{id}', [BudgetController::class, 'destroy']);
});