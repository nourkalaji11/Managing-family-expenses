<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Controllers\Concerns\ScopesToFamily;
use App\Models\Account;
use App\Models\Transaction;
use App\Services\NotificationService;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
    {
    use ScopesToFamily;

    public function index(Request $request)
    {
        // 1. بناء الاستعلام وجلب العمليات مع فئات الصرف والحساب البنكي وترتيبها من الأحدث للأقدم
        // 'user' محمَّلة كي تعرف الشاشة **من** صرف، لا المبلغ وحده. ولي الأمر
        // يرى عمليات العائلة كلها، فبلا اسم صاحب العملية تصير القائمة أرقاماً
        // لا تُنسب إلى أحد — وهو بالضبط ما يفتحها من أجله.
        $query = \App\Models\Transaction::with(['account', 'category', 'user'])->latest();

        // 1أ. قصر النتيجة على ما يحق للمستخدم رؤيته: ولي الأمر يرى الجميع
        //     والابن يرى عملياته وحده. كان الاستعلام بلا أي قيد، فيقرأ أي
        //     مستخدم مسجَّل عمليات كل العائلات — انظر ScopesToFamily.
        $query = $this->scopeToViewer($query, $request->user());

        // 2. فلترة حسب مستخدم معين (ابن محدد) إذا تم إرسال user_id بالـ Postman.
        //    تُطبَّق **بعد** القيد أعلاه، فهي تضييق إضافي لا تجاوز له: ابن يرسل
        //    user_id لأخيه يبقى محصوراً بعملياته هو.
        if ($request->has('user_id') && $request->user_id != null) {
            $query->where('user_id', $request->user_id);
        }
    
        // 3. فلترة حسب فئة معينة (طعام، مواصلات...) إذا تم إرسال category_id
        if ($request->has('category_id') && $request->category_id != null) {
            $query->where('category_id', $request->category_id);
        }
    
        // 4. فلترة حسب تاريخ محدد (من تاريخ إلى تاريخ) إذا أرسل الأب نطاقاً زمنياً
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('date', [$request->start_date, $request->end_date]);
        }
    
        // 5. تنفيذ الاستعلام النهائي.
        //
        //    التقسيم إلى صفحات **اختياري**: بلا per_page تعود المجموعة كاملة كما
        //    كانت. هذا مقصود ولا يصح جعله افتراضياً، لأن تطبيق الموبايل يحسب
        //    ملخص لوحة التحكم (الدخل، المصاريف، توزيع الفئات) من العمليات كلها
        //    على الجهاز — فصفحة واحدة تعطيه أرقاماً خاطئة بصمت.
        //
        //    TODO(backend): الحل الصحيح نقطة نهاية ملخّص محسوبة في SQL، وعندها
        //    يصير التقسيم افتراضياً هنا.
        if ($request->filled('per_page')) {
            $perPage = max(1, min((int) $request->input('per_page'), 100));
            $paginated = $query->paginate($perPage);

            return response()->json([
                'message' => 'تم جلب العمليات المفلترة بنجاح',
                'data'    => $paginated->items(),
                'meta'    => [
                    'current_page' => $paginated->currentPage(),
                    'last_page'    => $paginated->lastPage(),
                    'per_page'     => $paginated->perPage(),
                    'total'        => $paginated->total(),
                ],
            ], 200);
        }

        return response()->json([
            'message' => 'تم جلب العمليات المفلترة بنجاح',
            'data'    => $query->get()
        ], 200);
    }

     public function store(Request $request)
    {
        // 1. التحقق من صحة البيانات
        $validated = $request->validate([
            'account_id'  => 'required|exists:accounts,id',
            'category_id' => 'required|exists:categories,id',
            'amount'      => 'required|numeric|min:0.01',
            'type'        => 'required|in:income,expense',
            'description' => 'nullable|string|max:255',
            'date'        => 'required|date',
        ]);

        $user = auth()->user();
        $notifier = new NotificationService();

        // 2. التحقق من حد السحب عند إضافة مصروف.
        //    كان الشرط `role === 'member'` حرفياً، فأي دور آخر غير 'member'
        //    و'admin' كان يفلت من السقف تماماً. isParent يقلب الفحص: من ليس
        //    ولي أمر فهو مقيَّد — انظر User::isParent.
        // مُهيَّأ خارج الشرط: يُقرأ مرة أخرى بعد الحفظ لتحذير "قارب على
        // النهاية"، وربط قراءته بتنفيذ كتلة شرطية يجعل أي تعديل على أحد
        // الشرطين يكسر الآخر بصمت.
        $totalSpent = 0.0;

        // null تعني "لم يُحدَّد سقف" لا "سقف صفر": المقارنة مع null كانت تعامله
        // كصفر فتمنع كل مصروف على ابن لم يضع له أحد سقفاً بعد. من أراد تجميد
        // الصرف يضع 0 صراحةً، وهو ما يفحصه الشرط أدناه كأي رقم آخر.
        if (! $user->isParent()
            && $validated['type'] === 'expense'
            && $user->spending_limit !== null) {
            // التحويلات مستثناة: نقل المال بين حسابَي العائلة ليس إنفاقاً،
            // وعدّه ضمن السقف كان سيستهلكه دون أن يخرج ريال واحد.
            $totalSpent = (float) Transaction::where('user_id', $user->id)
                ->where('type', 'expense')
                ->whereNull('transfer_group_id')
                ->sum('amount');

            if (($totalSpent + $validated['amount']) > $user->spending_limit) {
                $notifier->limitBlocked(
                    $user,
                    (float) $validated['amount'],
                    (float) $totalSpent,
                    (float) $user->spending_limit
                );

                return response()->json([
                    'message'        => 'عذراً، هذا المبلغ يتجاوز حد السحب المسموح لك به من قبل الأب.',
                    'spending_limit' => (float)$user->spending_limit,
                    'current_spent'  => (float)$totalSpent,
                    'remaining'      => (float)max(0, $user->spending_limit - $totalSpent)
                ], 403);
            }
        }

        // يُقرأ قبل الحفظ: checkBudget تحتاج الحالة السابقة لتعرف إن كان الحد
        // قد عُبِر الآن، بدل أن تُشعِر عند كل مصروف تالٍ على ميزانية متجاوَزة.
        $spentBefore = $notifier->spentBefore(
            (int) $validated['category_id'],
            (string) $validated['date']
        );

        // 3. حفظ العملية وتحديث الرصيد داخل DB::transaction
        $response = DB::transaction(function () use ($validated) {
            $account = Account::findOrFail($validated['account_id']);

            if ($validated['type'] === 'expense') {
                $account->balance -= $validated['amount'];
            } else {
                $account->balance += $validated['amount'];
            }
            $account->save();

            $validated['user_id'] = auth()->id();
            $transaction = Transaction::create($validated);

            // تحميل الفئة والحساب مع العملية، لأن تطبيق الموبايل يعرض اسميهما
            // مباشرةً بعد الحفظ دون إعادة جلب القائمة كاملة.
            $transaction->load(['account', 'category']);

            return $transaction;
        });

        // الإشعارات تُولَّد **بعد** إغلاق DB::transaction لا داخلها: كتابة إشعار
        // ليست جزءاً من الحركة المحاسبية، ولا يجوز أن يتسبب فشلها في التراجع عن
        // عملية مالية سليمة.
        $notifier->memberSpent($user, $response);
        $notifier->checkBudget($response, $spentBefore);

        // تحذير "قارب المصروف على النهاية". يُحسب من $totalSpent المقروء قبل
        // الحفظ في فحص السقف أعلاه — لا من استعلام جديد، وإلا لصار الرقم
        // المقارَن به شاملاً للعملية نفسها ولتعذّر معرفة أن العتبة عُبرت الآن.
        if (! $user->isParent()
            && $validated['type'] === 'expense'
            && $user->spending_limit !== null) {
            $notifier->limitApproaching(
                $user,
                (float) $totalSpent,
                (float) $totalSpent + (float) $validated['amount'],
                (float) $user->spending_limit
            );
        }

        return response()->json([
            'message' => 'تم تسجيل العملية وتحديث الرصيد بنجاح',
            'data'    => $response
        ], 201);
    }
    /**
     * عملية واحدة بتفاصيلها.
     *
     * كانت دالة فارغة ترد 200 بجسم فارغ — أسوأ من 404، لأن العميل يقرأها نجاحاً
     * ثم يفشل عند أول قراءة حقل. ولم يكن لها مسار مسجَّل أصلاً؛ أُضيف الآن.
     */
    public function show(Request $request, string $id)
    {
        $transaction = Transaction::with(['account', 'category'])->find($id);

        if (!$transaction) {
            return response()->json(['message' => 'العملية غير موجودة!'], 404);
        }

        // 404 لا 403 عند محاولة قراءة عملية مستخدم آخر: الرد بـ403 يؤكد أن الصف
        // موجود، وهو ما لا يحق للسائل معرفته أصلاً.
        if (! $this->viewerOwns($request->user(), $transaction->user_id)) {
            return response()->json(['message' => 'العملية غير موجودة!'], 404);
        }

        return response()->json([
            'message' => 'تم جلب العملية بنجاح',
            'data'    => $transaction
        ], 200);
    }

    /**
     * تعديل عملية مالية موجودة، مع إعادة ضبط رصيد الحساب.
     *
     * الأثر القديم للعملية يُلغى أولاً ثم يُطبَّق الأثر الجديد، وذلك داخل
     * DB::transaction، لأن التعديل قد يغيّر المبلغ أو النوع أو حتى الحساب نفسه.
     * بدون الإلغاء يبقى أثر المبلغ القديم في الرصيد إلى الأبد.
     */
    public function update(Request $request, string $id)
    {
        $transaction = Transaction::find($id);

        if (!$transaction) {
            return response()->json([
                'message' => 'العملية غير موجودة!'
            ], 404);
        }

        // نفس قواعد التحقق المستخدمة في store، حتى لا يقبل التعديل ما يرفضه الإنشاء.
        $validated = $request->validate([
            'account_id'  => 'required|exists:accounts,id',
            'category_id' => 'required|exists:categories,id',
            'amount'      => 'required|numeric|min:0.01',
            'type'        => 'required|in:income,expense',
            'description' => 'nullable|string|max:255',
            'date'        => 'required|date',
        ]);

        $user = auth()->user();
        $notifier = new NotificationService();

        // قصر index وحده يمنع التصفح لا الوصول: يكفي تخمين رقم في المسار لتعديل
        // عملية مستخدم آخر. 404 لا 403، لنفس سبب show.
        if (! $this->viewerOwns($user, $transaction->user_id)) {
            return response()->json([
                'message' => 'العملية غير موجودة!'
            ], 404);
        }

        // طرف تحويل لا يُعدَّل من هنا: تغيير مبلغه أو حسابه يترك الطرف الآخر
        // على قيمته القديمة، فيصبح التحويل غير متوازن ورصيد أحد الحسابين خاطئاً.
        // التعديل الصحيح هو حذف التحويل عبر DELETE /transfers/{group} وإعادته.
        if ($transaction->transfer_group_id !== null) {
            return response()->json([
                'message' => 'لا يمكن تعديل طرف تحويل. احذف التحويل وأعد إنشاءه.'
            ], 422);
        }

        // حد السحب يُفحص هنا أيضاً، وإلا صار بإمكان الابن تجاوزه بتعديل عملية
        // قديمة بدل إنشاء عملية جديدة. المبلغ القديم لنفس العملية يُستثنى من
        // المجموع، لأنه سيُستبدل وليس يُضاف إليه.
        if (! $user->isParent()
            && $validated['type'] === 'expense'
            && $user->spending_limit !== null) {
            $totalSpent = (float) Transaction::where('user_id', $user->id)
                ->where('type', 'expense')
                ->whereNull('transfer_group_id')
                ->where('id', '!=', $transaction->id)
                ->sum('amount');

            if (($totalSpent + $validated['amount']) > $user->spending_limit) {
                $notifier->limitBlocked(
                    $user,
                    (float) $validated['amount'],
                    (float) $totalSpent,
                    (float) $user->spending_limit
                );

                return response()->json([
                    'message'        => 'عذراً، هذا المبلغ يتجاوز حد السحب المسموح لك به من قبل الأب.',
                    'spending_limit' => (float)$user->spending_limit,
                    'current_spent'  => (float)$totalSpent,
                    'remaining'      => (float)max(0, $user->spending_limit - $totalSpent)
                ], 403);
            }
        }

        return DB::transaction(function () use ($validated, $transaction) {
            // الأثر الموقَّع لكل عملية على الرصيد: المصروف ينقص والإيراد يزيد.
            $oldEffect = $transaction->type === 'expense'
                ? -(float)$transaction->amount
                : (float)$transaction->amount;

            $newEffect = $validated['type'] === 'expense'
                ? -(float)$validated['amount']
                : (float)$validated['amount'];

            if ((int)$transaction->account_id === (int)$validated['account_id']) {
                // نفس الحساب: نسخة واحدة من الموديل، وإلا كتبت النسخة الثانية
                // فوق حفظ الأولى وضاع أحد التعديلين.
                $account = Account::findOrFail($validated['account_id']);
                $account->balance = $account->balance - $oldEffect + $newEffect;
                $account->save();
            } else {
                // تغيّر الحساب: نلغي الأثر من الحساب القديم ونطبّقه على الجديد.
                $oldAccount = Account::find($transaction->account_id);
                if ($oldAccount) {
                    $oldAccount->balance = $oldAccount->balance - $oldEffect;
                    $oldAccount->save();
                }

                $newAccount = Account::findOrFail($validated['account_id']);
                $newAccount->balance = $newAccount->balance + $newEffect;
                $newAccount->save();
            }

            // user_id غير موجود ضمن $validated، فيبقى المالك الأصلي كما هو.
            $transaction->update($validated);
            $transaction->load(['account', 'category']);

            return response()->json([
                'message' => 'تم تعديل العملية وتحديث الرصيد بنجاح',
                'data'    => $transaction
            ], 200);
        });
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Request $request, string $id)
{
    // البحث عن العملية بواسطة الـ ID
    $transaction = Transaction::find($id);

    // إذا لم نجد العملية، نرسل رسالة خطأ للموبايل
    if (!$transaction) {
        return response()->json([
            'message' => 'العملية غير موجودة!'
        ], 404); // 404 تعني Not Found
    }

    // نفس فحص الملكية المطبَّق في show وupdate.
    if (! $this->viewerOwns($request->user(), $transaction->user_id)) {
        return response()->json([
            'message' => 'العملية غير موجودة!'
        ], 404);
    }

    // حذف طرف تحويل منفرداً يترك الطرف الآخر يتيماً ورصيد أحد الحسابين خاطئاً.
    // التراجع الصحيح عبر DELETE /transfers/{group}.
    if ($transaction->transfer_group_id !== null) {
        return response()->json([
            'message' => 'لا يمكن حذف طرف تحويل. استخدم التراجع عن التحويل كاملاً.'
        ], 422);
    }

    // إلغاء أثر العملية على رصيد حسابها قبل حذفها. بدون هذا يبقى الرصيد
    // منقوصاً بمبلغ مصروف لم يعد له وجود — نفس القاعدة المطبقة في store وupdate.
    return DB::transaction(function () use ($transaction) {
        $account = Account::find($transaction->account_id);

        if ($account) {
            if ($transaction->type === 'expense') {
                $account->balance += $transaction->amount;
            } else {
                $account->balance -= $transaction->amount;
            }
            $account->save();
        }

        $transaction->delete();

        return response()->json([
            'message' => 'تم حذف العملية وإرجاع الرصيد بنجاح'
        ], 200);
    });
}
    }