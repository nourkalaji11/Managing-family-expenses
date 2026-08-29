<?php

namespace App\Http\Controllers;

use App\Models\AppNotification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * إشعارات المستخدم الحالي، الأحدث أولاً.
     *
     * مقسَّمة على صفحات — بخلاف بقية فهارس هذا المشروع. الإشعارات هي المجموعة
     * الوحيدة التي تنمو بلا سقف مع الاستعمال: كل مصروف يسجّله ابن يضيف صفاً،
     * فتحميلها كاملة يكبر بلا حد. الحسابات والفئات محدودة بطبيعتها.
     */
    public function index(Request $request)
    {
        $perPage = (int) $request->input('per_page', 20);
        $perPage = max(1, min($perPage, 50));

        $notifications = AppNotification::where('user_id', $request->user()->id)
            ->latest()
            ->paginate($perPage);

        return response()->json([
            'message' => 'تم جلب الإشعارات بنجاح',
            'data'    => $notifications->items(),
            // عدّاد غير المقروء يُحسب على كامل المجموعة لا على الصفحة الحالية،
            // لأن الشارة في شريط التطبيق تعني "غير مقروء لديك"، لا "في هذه الصفحة".
            'meta'    => [
                'current_page' => $notifications->currentPage(),
                'last_page'    => $notifications->lastPage(),
                'per_page'     => $notifications->perPage(),
                'total'        => $notifications->total(),
                'unread_count' => AppNotification::where('user_id', $request->user()->id)
                    ->where('seen', false)
                    ->count(),
            ],
        ], 200);
    }

    /**
     * تعليم إشعار واحد كمقروء.
     *
     * البحث مقيَّد بـ user_id وليس بالمعرّف وحده: بدونه يستطيع أي مستخدم تعليم
     * إشعارات غيره بتخمين الأرقام.
     */
    public function markAsRead(Request $request, string $id)
    {
        $notification = AppNotification::where('user_id', $request->user()->id)
            ->find($id);

        if (!$notification) {
            return response()->json(['message' => 'الإشعار غير موجود!'], 404);
        }

        $notification->update(['seen' => true]);

        return response()->json([
            'message' => 'تم تعليم الإشعار كمقروء',
            'data'    => $notification
        ], 200);
    }

    /**
     * تعليم كل إشعارات المستخدم كمقروءة.
     */
    public function markAllAsRead(Request $request)
    {
        $updated = AppNotification::where('user_id', $request->user()->id)
            ->where('seen', false)
            ->update(['seen' => true]);

        return response()->json([
            'message' => 'تم تعليم جميع الإشعارات كمقروءة',
            'data'    => ['updated' => $updated],
        ], 200);
    }

    /**
     * حذف إشعار.
     */
    public function destroy(Request $request, string $id)
    {
        $notification = AppNotification::where('user_id', $request->user()->id)
            ->find($id);

        if (!$notification) {
            return response()->json(['message' => 'الإشعار غير موجود!'], 404);
        }

        $notification->delete();

        return response()->json(['message' => 'تم حذف الإشعار'], 200);
    }
}
