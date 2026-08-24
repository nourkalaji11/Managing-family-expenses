<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Account;
use App\Models\Transaction;
use App\Models\Budget;

class DashboardController extends Controller
{
    public function index()
    {
        // 1. حساب إجمالي الرصيد المتوفر في حسابات العائلة
        $totalBalance = Account::sum('balance');

        // 2. حساب إجمالي ما تم صرفه من كل العائلة (العمليات من نوع expense)
        $totalSpent = Transaction::where('type', 'expense')->sum('amount');

        // 3. جلب تنبيهات الميزانيات (الميزانيات التي شارف الأبناء على تجاوزها أو تجاوزوها فعلاً)
        $budgetsAlerts = Budget::with('user', 'category')
            ->whereColumn('current_spending', '>=', 'limit_amount')
            ->get()
            ->map(function($budget) {
                return [
                    'user_name' => $budget->user->name,
                    'category' => $budget->category->name,
                    'limit' => $budget->limit_amount,
                    'spent' => $budget->current_spending,
                    'message' => "تنبيه: الابن {$budget->user->name} تجاوز ميزانية الـ {$budget->category->name}!"
                ];
            ]);

        // إرجاع كل هذه الإحصائيات لتطبيق الموبايل بطلب واحد
        return response()->json([
            'message' => 'تم جلب بيانات لوحة تحكم الأب بنجاح',
            'data' => [
                'total_family_balance' => $totalBalance,
                'total_family_spent'   => $totalSpent,
                'alerts'               => $budgetsAlerts
            ]
        ], 200);
    }
}