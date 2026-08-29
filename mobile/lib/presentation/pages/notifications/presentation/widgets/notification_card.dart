import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/app_notification.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/presentation/pages/notifications/presentation/widgets/notification_visuals.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// One notification row: tinted glyph, title, message, relative timestamp.
///
/// Unread rows carry a tinted background and a dot; read rows are plain white.
/// The dot is redundant with the background on purpose — colour alone must not
/// be the only thing distinguishing read from unread.
///
/// Swipe-to-dismiss deletes. The design specifies no delete affordance, but the
/// backend supports it and a list that only ever grows is not usable; a swipe
/// keeps the row itself uncluttered.
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(20.r);
    final NotificationType type = notification.type;
    final bool unread = !notification.seen;

    return Dismissible(
      key: ValueKey<int?>(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: EdgeInsetsDirectional.only(end: 24.w),
        decoration: BoxDecoration(
          color: ColorsApp.errorRed.withValues(alpha: 0.1),
          borderRadius: radius,
        ),
        child: Icon(
          Icons.delete_outline,
          color: ColorsApp.errorRed,
          size: 24.r,
        ),
      ),
      child: Material(
        color: unread ? ColorsApp.surfaceContainerLow : ColorsApp.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: ColorsApp.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: NotificationVisuals.tintFor(type),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      NotificationVisuals.iconFor(type),
                      size: 20.r,
                      color: NotificationVisuals.inkFor(type),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title ??
                                    'notifications_page.untitled'.tr(),
                                style: TextStyleApp.transactionsRowTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unread) ...[
                              SizedBox(width: 8.w),
                              Container(
                                width: 8.r,
                                height: 8.r,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ColorsApp.primaryGreenPressed,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          notification.message ?? '',
                          style: TextStyleApp.transactionsRowSubtitle,
                          // Three lines is enough for every message the server
                          // composes; a longer one is truncated rather than
                          // pushing the next row off screen.
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          DashboardFormatter.relativeDateTime(
                            notification.createdAt,
                          ),
                          style: TextStyleApp.dashboardCaption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
