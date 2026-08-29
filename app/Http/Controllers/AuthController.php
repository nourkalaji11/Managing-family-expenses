<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // 1. إنشاء حساب جديد (Register)
    public function register(Request $request)
    {
        // 'role' مقيَّد بقيمتين بدل 'nullable|string' المفتوح: القاعدة القديمة
        // كانت تقبل أي نص، فكان بإمكان أي عميل أن يسجّل نفسه بأي دور يكتبه —
        // بما فيه 'admin' — عبر تعديل حقل واحد في الطلب.
        //
        // ملاحظة أمنية متبقية: التسجيل العام ما زال يسمح باختيار 'parent'،
        // وهذا مقصود لأن شاشة إنشاء الحساب في التطبيق تعرض هذا الخيار (أول
        // مستخدم في العائلة هو ولي أمرها). إن أردنا منعه لاحقاً فالحل أن
        // يُثبَّت الدور على 'member' هنا وتُضاف ترقية يقوم بها ولي أمر موجود.
        $validatedData = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'role'     => 'nullable|string|in:parent,member',
        ]);

        $user = User::create([
            'name'     => $validatedData['name'],
            'email'    => $validatedData['email'],
            'password' => Hash::make($validatedData['password']),
            'role'     => $validatedData['role']?? 'member',
        ]);

        // إنشاء Token للمستخدم الجديد
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message'      => 'User registered successfully',
            'access_token' => $token,
            'token_type'   => 'Bearer',
            'user'         => $user
        ], 201);
    }

    // 2. تسجيل الدخول (Login)
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Invalid login credentials'
            ], 401);
        }

        // إبطال أي توكنات قديمة وإنشاء توكن جديد
        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message'      => 'Login successful',
            'access_token' => $token,
            'token_type'   => 'Bearer',
            'user'         => $user
        ], 200);
    }

    // 3. تسجيل الخروج (Logout)
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully'
        ], 200);
    }

    // 4. جلب بيانات المستخدم الحالي (Profile)
    public function me(Request $request)
    {
        return response()->json([
            'user' => $request->user()
        ], 200);
    }

    /**
     * 5. تعديل بيانات المستخدم الحالي.
     *
     * الاسم والبريد اختياريان، وكلمة المرور تُغيَّر فقط إذا أُرسلت — ومعها
     * كلمة المرور الحالية. بدون هذا الشرط يصبح توكن مسروق كافياً للاستيلاء
     * على الحساب نهائياً بتغيير كلمة المرور.
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name'     => 'sometimes|required|string|max:255',
            // قاعدة unique تستثني المستخدم نفسه، وإلا فشل الحفظ دون تغيير البريد.
            'email'    => 'sometimes|required|string|email|max:255|unique:users,email,' . $user->id,
            'password' => 'sometimes|required|string|min:8|confirmed',
            'current_password' => 'required_with:password|string',
        ]);

        if (isset($validated['password'])) {
            if (! Hash::check($validated['current_password'], $user->password)) {
                return response()->json([
                    'message' => 'كلمة المرور الحالية غير صحيحة.'
                ], 422);
            }
            $user->password = Hash::make($validated['password']);
        }

        if (isset($validated['name']))  $user->name = $validated['name'];
        if (isset($validated['email'])) $user->email = $validated['email'];

        // الدور غير قابل للتعديل من هنا عمداً: ترقية المستخدم لنفسه إلى ولي أمر
        // تجاوز صلاحيات، لا تحرير ملف شخصي.
        $user->save();

        return response()->json([
            'message' => 'تم تحديث البيانات بنجاح.',
            'user'    => $user
        ], 200);
    }

    /**
     * 6. أفراد العائلة.
     *
     * ولي الأمر يرى الجميع؛ الابن يرى نفسه فقط. الابن الذي يستطيع تعداد بقية
     * أفراد العائلة بأسمائهم وبريدهم وسقوف سحبهم يحصل على معلومات ليست له.
     *
     * TODO(backend): لا يوجد جدول families ولا عمود family_id، فـ"العائلة" هنا
     * تعني عملياً كل مستخدمي قاعدة البيانات. هذا صحيح لنشر عائلة واحدة فقط؛
     * تعدد العائلات يحتاج عمود ربط أولاً.
     */
    public function familyMembers(Request $request)
    {
        $user = $request->user();

        $members = $user->isParent()
            ? User::orderBy('name')->get()
            : User::where('id', $user->id)->get();

        // ما صرفه كل فرد فعلياً، لا سقفه فقط. السقف وحده يقول ما هو مسموح؛
        // ولي الأمر يحتاج أن يرى ما صُرف منه — وهو سبب وجود الشاشة.
        //
        // نفس قاعدة TransactionController::store: مصاريف فقط، دون التحويلات،
        // وعلى كامل التاريخ. أي اختلاف هنا يعني رقماً معروضاً لا يطابق الرقم
        // الذي يمنع العملية التالية.
        $spentByUser = Transaction::where('type', 'expense')
            ->whereNull('transfer_group_id')
            ->whereIn('user_id', $members->pluck('id'))
            ->selectRaw('user_id, SUM(amount) as total')
            ->groupBy('user_id')
            ->pluck('total', 'user_id');

        $members->each(function (User $member) use ($spentByUser) {
            $spent = (float) ($spentByUser[$member->id] ?? 0);
            $limit = $member->spending_limit === null
                ? null
                : (float) $member->spending_limit;

            $member->spent = round($spent, 2);
            // null لا صفر حين لا سقف: "بلا حد" و"لم يبقَ شيء" حالتان متعاكستان،
            // وتمثيلهما برقم واحد يقلب معنى الشاشة.
            $member->remaining = $limit === null ? null : round(max(0, $limit - $spent), 2);
        });

        return response()->json([
            'message' => 'تم جلب أفراد العائلة بنجاح',
            'data'    => $members
        ], 200);
    }

    /**
     * ولي الأمر ينشئ حساب ابن.
     *
     * ---------------------------------------------------------------------
     * التسجيل الذاتي عبر /register يبقى قائماً لولي الأمر الأول، لكنه لا يصلح
     * لإضافة الأبناء: كان على الابن أن يسجّل بنفسه ثم ينتظر أن يجده والده في
     * القائمة ويحدّد له سقفاً. هذه النقطة تجعلها خطوة واحدة يقوم بها من يملك
     * القرار أصلاً.
     *
     * الدور مثبَّت على 'member' ولا يُقرأ من الطلب: نقطة تسمح لولي أمر بإنشاء
     * ولي أمر آخر هي تصعيد صلاحيات بخطوة واحدة.
     * ---------------------------------------------------------------------
     */
    public function createMember(Request $request)
    {
        if (! $request->user()->isParent()) {
            return response()->json(['message' => 'غير مصرح لك بإضافة أفراد.'], 403);
        }

        $validated = $request->validate([
            'name'           => 'required|string|max:255',
            'email'          => 'required|string|email|max:255|unique:users,email',
            'password'       => 'required|string|min:8',
            'spending_limit' => 'nullable|numeric|min:0',
        ]);

        $member = User::create([
            'name'           => $validated['name'],
            'email'          => $validated['email'],
            'password'       => Hash::make($validated['password']),
            'role'           => 'member',
            'spending_limit' => $validated['spending_limit'] ?? null,
        ]);

        // إشعار بالسقف عند تحديده مع الإنشاء، تماماً كما لو حُدِّد لاحقاً عبر
        // setSpendingLimit — وإلا لاختفى السجل لمجرد أن التوقيت اختلف.
        if (isset($validated['spending_limit'])) {
            (new NotificationService())->limitUpdated($member, (float) $validated['spending_limit']);
        }

        return response()->json([
            'message' => 'تم إنشاء الحساب بنجاح',
            'data'    => $member
        ], 201);
    }

    // 7. تحديد حد السحب المالي للابن (خاص بولي الأمر)
    public function setSpendingLimit(Request $request, $id)
    {
        // كان الفحص `role !== 'admin'` حرفياً، فحساب ولي أمر أُنشئ من التطبيق
        // (الذي يرسل 'parent') كان يُرفض. isParent يقبل الاثنين — انظر User.
        if (! $request->user()->isParent()) {
            return response()->json(['message' => 'غير مصرح لك بتحديد الحدود المالية.'], 403);
        }

        $request->validate([
            'spending_limit' => 'required|numeric|min:0',
        ]);

        $user = User::findOrFail($id);

        // سقف السحب لا معنى له لولي أمر: store لا يفحصه إلا للأدوار غير الأبوية،
        // فتعيينه يمنح المستخدم رقماً لا يقيّد شيئاً ويقرأ كأنه يقيّده.
        if ($user->isParent()) {
            return response()->json([
                'message' => 'سقف السحب يُحدَّد للأبناء فقط.'
            ], 422);
        }

        $user->spending_limit = $request->spending_limit;
        $user->save();

        // الابن يُبلَّغ بسقفه الجديد: بدون إشعار يكتشفه فقط عند رفض عملية.
        (new NotificationService())->limitUpdated($user, (float) $user->spending_limit);

        return response()->json([
            'message' => 'تم تحديث سقف السحب بنجاح.',
            'data'    => $user
        ], 200);
    }
};