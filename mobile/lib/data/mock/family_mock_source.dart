import 'package:family_expense_management/data/models/app_notification.dart';
import 'package:family_expense_management/data/models/user.dart';

/// SEED DATA ONLY — the family behind the fake dataset, and its notifications.
///
/// Same contract as [DashboardMockSource]: immutable starting state, read
/// exactly once by `MockStore`, which owns every mutation from then on. Nothing
/// else may read this file.
///
/// It exists because five features — auth, profile, family members, spending
/// limits and notifications — all need *people*, and the original seed had
/// none: it derived a single owner id from the `user_id` on a transaction row.
/// That was enough while only the dashboard, transactions and budgets were
/// mocked. It cannot answer "who is signed in", "who else is in the family" or
/// "what is this member's ceiling", so the users are now the source of truth and
/// the transactions' owner is derived from them, not the other way round.
class FamilyMockSource {
  const FamilyMockSource._();

  /// The account the mock signs in as. A **parent**, deliberately: the parent
  /// role is the superset — it can see the family list, set ceilings and read
  /// the alerts panel. Signing in as a member would leave those screens
  /// unreachable and untestable in a mock build.
  ///
  /// The id is 1 because every seeded transaction, account and budget already
  /// carries `user_id: 1`. Changing it here without changing those would scope
  /// the dashboard to a user the profile screen does not show.
  static const int signedInUserId = 1;

  /// No `token` is set on any of these.
  ///
  /// `LocalsApp.user.token` is what `DioClient` puts in the Authorization
  /// header, and a mock session must never end up holding something that looks
  /// like a credential. `AuthRepo` stamps a clearly-fake marker on the signed-in
  /// copy instead — see `AuthRepo.mockToken`.
  static List<User> users() => [
    User(
      id: signedInUserId,
      name: 'أحمد الكيالي',
      email: 'ahmad@example.com',
      role: 'parent',
    ),
    User(
      id: 2,
      name: 'نور الكيالي',
      email: 'nour@example.com',
      role: 'member',
      // The member screen is only worth looking at with a ceiling set: it draws
      // the limit, the spent-against-it bar and the "تعديل السقف" action.
      spendingLimit: 1500,
    ),
    User(
      id: 3,
      name: 'سعاد الكيالي',
      email: 'souad@example.com',
      role: 'member',
      // Deliberately null: the list has to render both states, and "لا يوجد
      // سقف" is the one a real family starts in.
    ),
  ];

  /// Seeded notifications, oldest first — `NotificationsRepo` sorts.
  ///
  /// One row per [NotificationType] that `NotificationService` on the server can
  /// actually produce, so the list screen's type icons and colours are all
  /// exercised without having to trigger each event by hand.
  ///
  /// Times are relative to now, like the seeded transactions, so the "منذ
  /// ساعتين" style subtitles stay truthful whenever the app runs.
  static List<AppNotification> notifications() {
    final now = DateTime.now();

    return [
      AppNotification(
        id: 1,
        rawType: NotificationType.limitUpdated.wire,
        title: 'تم تحديث سقف السحب',
        message: 'تم تعيين سقف سحب شهري بقيمة 1,500 ل.س لحساب نور.',
        seen: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      AppNotification(
        id: 2,
        rawType: NotificationType.memberSpent.wire,
        title: 'عملية صرف جديدة',
        message: 'صرفت نور 468 ل.س على المطاعم.',
        seen: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
      ),
      AppNotification(
        id: 3,
        rawType: NotificationType.limitBlocked.wire,
        title: 'تم رفض عملية صرف',
        message: 'حاولت نور صرف 900 ل.س وهو ما يتجاوز السقف المتبقي.',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      AppNotification(
        id: 4,
        rawType: NotificationType.budgetExceeded.wire,
        title: 'تجاوزت الميزانية',
        message: 'تجاوز الصرف على المطاعم ميزانية هذا الشهر.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }
}
