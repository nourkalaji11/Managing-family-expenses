import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:family_expense_management/blocs/local_user_cubit.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/presentation/pages/notifications/bloc/notifications_bloc.dart';
import 'package:family_expense_management/presentation/pages/notifications/presentation/widgets/notification_card.dart';
import 'package:family_expense_management/presentation/widgets/custom_app_bar.dart';
import 'package:family_expense_management/presentation/widgets/default_loader.dart';
import 'package:family_expense_management/presentation/widgets/error_message.dart';
import 'package:family_expense_management/presentation/widgets/no_items.dart';
import 'package:family_expense_management/presentation/widgets/refresh.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/utils/service_locator.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final bloc = getIt<NotificationsBloc>();
  final markAllAsReadbloc = getIt<NotificationsBloc>();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    bloc.add(const OnFetchNotifications());
    scrollController.addListener(_onScroll);
    super.initState();
  }

  void _onScroll() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      bloc.add(OnFetchMoreNotifications(bloc.currentPage + 1));
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "notifications".tr()),
      body: BlocProvider.value(
        value: bloc,
        child: BlocListener(
          bloc: bloc,
          listener: (context, state) {
            if (state is FetchNotificationsSuccess) {
              markAllAsReadbloc.add(OnMarkAllAsRead());
            }
          },
          child: BlocBuilder<NotificationsBloc, NotificationsState>(
            bloc: bloc,
            builder: (context, state) {
              if (state is NotificationsLoading) {
                return const DefaultLoader();
              } else if (state is NotificationsFailure) {
                return ErrorMessage(
                  failure: state.error,
                  reload: () {
                    bloc.add(OnFetchNotifications());
                  },
                );
              } else if (state is FetchNotificationsSuccess) {
                context.read<LocalUserCubit>().updateUser(null);

                context.read<LocalUserCubit>().updateUser(LocalsApp.user);
                return state.notifications.isEmpty
                    ? NoItems(
                        message: "no_notifications".tr(),
                        reload: () {
                          bloc.add(OnFetchNotifications());
                        },
                      )
                    : AppRefreshIndicator(
                        reload: () {
                          bloc.add(OnFetchNotifications());
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding: EdgeInsetsApp.symmetricV20H20,
                                physics: AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: state.notifications.length,
                                      padding: EdgeInsets.zero,
                                      separatorBuilder: (context, index) =>
                                          const Divider(
                                            color: ColorsApp.grey200,
                                          ),
                                      itemBuilder: (context, index) =>
                                          NotificationCard(
                                            notification:
                                                state.notifications[index],
                                          ),
                                    ),
                                    Spaces.height4,
                                    if (!state.hasReachedMax)
                                      const Center(child: DefaultLoader()),
                                    Spaces.height16,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}
