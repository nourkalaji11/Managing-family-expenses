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
        $user = auth()->user();

        // 1. إذا كان المستخدم هو الأب (admin) -> يشوف الإحصائيات الكاملة والتنبيهات والرصيد
        if (strtolower($user->role) === 'admin') {
            $totalBalance = Account::sum('balance');
            $totalSpent = Transaction::where('type', 'expense')->sum('amount');
            
            $budgetsAlerts = Budget::with('user', 'category')
                ->whereColumn('current_spending', '>=', 'limit_amount')
                ->get()
                ->map(function($budget) {
                    return [
                        'user_name' => $budget->user->name,
                        'category'  => $budget->category->name,
                        'limit'     => $budget->limit_amount,
                        'spent'     => $budget->current_spending,
                        'message'   => "تنبيه: الابن {$budget->user->name} تجاوز ميزانية {$budget->category->name}"
                    ];
                });

            return response()->json([
                'message' => 'تم جلب بيانات لوحة تحكم الأب بنجاح',
                'data' => [
                    'role'                 => $user->role,
                    'total_family_balance' => $totalBalance,
                    'total_family_spent'   => $totalSpent,
                    'alerts'               => $budgetsAlerts,
                ]
            ], 200);
        }

        // 2. إذا كان المستخدم ابن (member) -> يختفي الرصيد الإجمالي ويظهر حد سحبه ومسحوباته فقط
        $mySpent = Transaction::where('user_id', $user->id)
            ->where('type', 'expense')
            ->sum('amount');
            
        $limit = $user->spending_limit;

        return response()->json([
            'message' => 'تم جلب بيانات لوحة تحكم الابن بنجاح',
            'data' => [
                'role'               => 'member',
                'my_spending_limit'  => (float)$limit,
                'my_total_spent'     => (float)$mySpent,
                'my_remaining_limit' => (float)max(0, $limit - $mySpent),
            ]
        ], 200);
    }
}