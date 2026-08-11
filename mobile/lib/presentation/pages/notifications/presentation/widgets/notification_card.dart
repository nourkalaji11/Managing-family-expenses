import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:family_expense_management/data/models/custom_notification.dart';
import 'package:family_expense_management/presentation/pages/notifications/bloc/notifications_bloc.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/radius.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';
import 'package:family_expense_management/utils/date_formatter.dart';
import 'package:family_expense_management/utils/service_locator.dart';

class NotificationCard extends StatelessWidget {
  final CustomNotification notification;
  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<NotificationsBloc>();

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      bloc: bloc,
      builder: (context, state) {
        return BlocListener<NotificationsBloc, NotificationsState>(
          bloc: bloc,
          listener: (context, s) {
            if (s is NotificationsLoading) {
              EasyLoading.show();
            } else if (s is NotificationsFailure) {
              EasyLoading.dismiss();
              EasyLoading.showError(s.error.message);
            } else if (s is MarkAsReadSuccess) {
              EasyLoading.dismiss();
              notification.seen = true;
              print("type ${notification.type}");
              print(
                "additionalData.category ${notification.additionalData?.category}",
              );
            }
          },
          child: InkWell(
            onTap: () {
              bloc.add(OnMarkAsRead(notification.id!));
            },
            borderRadius: BorderRadiusApp.radius12,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: ColorsApp.lightYellow,
                  radius: 26.r,
                  child: SvgPicture.asset("assets/icons/notification.svg"),
                ),
                Spaces.width10,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message ?? "",
                        style: TextStyleApp.black12500,
                      ),
                      Spaces.height4,
                      Text(
                        notification.createdAt!.isSameDay(DateTime.now())
                            ? notification.createdAt!.formatTime()
                            : notification.createdAt!.formatDate(),
                        style: TextStyleApp.grey12300,
                      ),
                    ],
                  ),
                ),
                if (notification.seen == false) ...[
                  Spaces.width6,
                  Container(
                    height: 8.r,
                    width: 8.r,
                    decoration: BoxDecoration(
                      color: ColorsApp.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
