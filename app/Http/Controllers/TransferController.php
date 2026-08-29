<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\ScopesToFamily;
use App\Models\Account;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * نقل مبلغ بين حسابين للعائلة.
 *
 * التحويل يُسجَّل كعمليتين تحملان نفس transfer_group_id: مصروف من الحساب
 * المصدر وإيراد للحساب الهدف. هكذا يظهر في سجل المعاملات، ويستفيد من نفس
 * منطق الرصيد بدل تكراره.
 *
 * الطرفان مستثنيان من مجاميع الدخل/المصاريف في التطبيق: نقل المال بين جيبين
 * لنفس العائلة ليس دخلاً ولا إنفاقاً، وعدّه كذلك يضخّم الرقمين معاً.
 */
class TransferController extends Controller
{
    use ScopesToFamily;

    /**
     * قائمة التحويلات، مجمَّعة — كل تحويل صفّان.
     */
    public function index(Request $request)
    {
        // كان الشرط `where('user_id', $request->user()->id)` ثابتاً، فولي الأمر
        // لا يرى تحويلات أبنائه — بخلاف بقية الموارد كلها. scopeToViewer يوحّد
        // القاعدة: ولي الأمر يرى العائلة، والابن يرى ما يخصه.
        $rows = $this->scopeToViewer(
            Transaction::with(['account', 'category'])
                ->whereNotNull('transfer_group_id')
                ->latest(),
            $request->user()
        )->get();

        // التجميع في PHP لا في SQL: المجموعة صفّان فقط، وكتابتها كاستعلام
        // ذاتي الربط تعقيد بلا مقابل.
        $transfers = $rows->groupBy('transfer_group_id')->map(function ($pair) {
            $from = $pair->firstWhere('type', 'expense');
            $to   = $pair->firstWhere('type', 'income');

            return [
                'transfer_group_id' => $pair->first()->transfer_group_id,
                'amount'            => (float) $pair->first()->amount,
                'description'       => $pair->first()->description,
                'date'              => $pair->first()->date,
                'from_account'      => $from?->account,
                'to_account'        => $to?->account,
                'created_at'        => $pair->first()->created_at,
            ];
        })->values();

        return response()->json([
            'message' => 'تم جلب التحويلات بنجاح',
            'data'    => $transfers,
        ], 200);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'from_account_id' => 'required|exists:accounts,id|different:to_account_id',
            'to_account_id'   => 'required|exists:accounts,id',
            'amount'          => 'required|numeric|min:0.01',
            // الفئة مطلوبة لأن transactions.category_id غير قابل للإفراغ.
            // TODO(backend): فئة مخصّصة للتحويلات (أو جعل العمود nullable) أنظف
            // من إجبار المستخدم على تصنيف نقلٍ داخلي.
            'category_id'     => 'required|exists:categories,id',
            'description'     => 'nullable|string|max:255',
            'date'            => 'required|date',
        ]);

        // سقف سحب الابن لا يُطبَّق هنا عمداً: التحويل لا يُخرج مالاً من العائلة،
        // والسقف يقيّد الإنفاق. تطبيقه كان سيمنع ابناً من ترتيب حساباته.
        return DB::transaction(function () use ($validated, $request) {
            $from = Account::findOrFail($validated['from_account_id']);
            $to   = Account::findOrFail($validated['to_account_id']);

            $amount  = (float) $validated['amount'];
            $groupId = (string) Str::uuid();
            $userId  = $request->user()->id;

            $from->balance -= $amount;
            $from->save();

            $to->balance += $amount;
            $to->save();

            $shared = [
                'amount'            => $amount,
                'description'       => $validated['description'] ?? null,
                'date'              => $validated['date'],
                'user_id'           => $userId,
                'category_id'       => $validated['category_id'],
                'transfer_group_id' => $groupId,
            ];

            $out = Transaction::create($shared + [
                'type'       => 'expense',
                'account_id' => $from->id,
            ]);
            $in = Transaction::create($shared + [
                'type'       => 'income',
                'account_id' => $to->id,
            ]);

            $out->load(['account', 'category']);
            $in->load(['account', 'category']);

            return response()->json([
                'message' => 'تم تنفيذ التحويل بنجاح',
                'data'    => [
                    'transfer_group_id' => $groupId,
                    'amount'            => $amount,
                    'from'              => $out,
                    'to'                => $in,
                ],
            ], 201);
        });
    }

    /**
     * التراجع عن تحويل: يحذف الصفّين معاً ويعيد الرصيدين.
     *
     * حذف طرف واحد عبر DELETE /transactions/{id} يترك النصف الآخر يتيماً ورصيداً
     * غير متوازن، ولهذا يوجد هذا المسار.
     */
    public function destroy(Request $request, string $groupId)
    {
        $rows = Transaction::where('transfer_group_id', $groupId)->get();

        if ($rows->isEmpty()) {
            return response()->json(['message' => 'التحويل غير موجود!'], 404);
        }

        // نفس فحص الملكية المطبَّق في بقية الموارد: ولي الأمر يتراجع عن تحويلات
        // العائلة، والابن عن تحويلاته وحده. 404 لا 403، حتى لا يؤكد الرد وجود
        // تحويل لمستخدم آخر. طرفا التحويل يحملان نفس المالك، فيكفي فحص أحدهما.
        if (! $this->viewerOwns($request->user(), $rows->first()->user_id)) {
            return response()->json(['message' => 'التحويل غير موجود!'], 404);
        }

        return DB::transaction(function () use ($rows) {
            foreach ($rows as $row) {
                $account = Account::find($row->account_id);
                if ($account) {
                    // عكس الأثر، تماماً كما يفعل TransactionController::destroy.
                    if ($row->type === 'expense') {
                        $account->balance += $row->amount;
                    } else {
                        $account->balance -= $row->amount;
                    }
                    $account->save();
                }
                $row->delete();
            }

            return response()->json(['message' => 'تم التراجع عن التحويل'], 200);
        });
    }
}
