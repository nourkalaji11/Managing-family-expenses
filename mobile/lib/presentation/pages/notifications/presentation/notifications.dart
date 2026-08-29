import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/presentation/pages/notifications/bloc/notifications_bloc.dart';
import 'package:family_expense_management/presentation/pages/notifications/presentation/widgets/notification_card.dart';
import 'package:family_expense_management/presentation/widgets/status_views.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The notifications list, pushed from the bell in every main tab's app bar.
///
/// The only paginated screen in the app: it loads page 1 on open and appends
/// the next page when the list is scrolled near its end.
///
/// It deliberately does **not** mark everything read on open. The previous
/// version did, which meant a user who opened the screen to glance at it lost
/// the ability to tell which alerts were new — the "mark all read" action is in
/// the app bar instead, so it stays the user's decision.
class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  static const double _pagePadding = 20;

  /// How close to the bottom, in pixels, triggers the next page.
  static const double _loadMoreThreshold = 300;

  late final NotificationsBloc _bloc;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _bloc = NotificationsBloc()..add(const OnLoadNotifications());
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final double remaining =
        _controller.position.maxScrollExtent - _controller.position.pixels;
    if (remaining > _loadMoreThreshold) return;

    // The bloc drops this when a page is already in flight or the last page has
    // been reached, so firing it on every frame near the bottom is safe.
    _bloc.add(const OnLoadMoreNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = _pagePadding.w;

    return Scaffold(
      backgroundColor: ColorsApp.dashboardBackground,
      appBar: AppBar(
        backgroundColor: ColorsApp.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'notifications'.tr(),
          style: TextStyleApp.dashboardAppBarTitle,
        ),
        iconTheme: const IconThemeData(color: ColorsApp.onSurface),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            bloc: _bloc,
            builder: (context, state) {
              // Offered only when it would actually do something.
              if (state is! NotificationsLoaded || state.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                key: const Key('notifications_mark_all'),
                onPressed: () =>
                    _bloc.add(const OnMarkAllNotificationsRead()),
                child: Text(
                  'notifications_page.mark_all_read'.tr(),
                  style: TextStyleApp.dashboardSectionAction,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: ColorsApp.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          bloc: _bloc,
          builder: (context, state) {
            return switch (state) {
              NotificationsInitial() ||
              NotificationsLoading() => const AppLoadingView(),
              NotificationsFailure(:final error) => AppFailureView(
                failure: error,
                retryKey: const Key('notifications_retry'),
                onRetry: () => _bloc.add(const OnLoadNotifications()),
              ),
              NotificationsLoaded() => _LoadedView(
                state: state,
                controller: _controller,
                horizontal: horizontal,
                onRefresh: () async =>
                    _bloc.add(const OnRefreshNotifications()),
                onTap: (id) => _bloc.add(OnMarkNotificationRead(id)),
                onDismissed: (id) => _bloc.add(OnDeleteNotification(id)),
              ),
            };
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final NotificationsLoaded state;
  final ScrollController controller;
  final double horizontal;
  final Future<void> Function() onRefresh;
  final void Function(int) onTap;
  final void Function(int) onDismissed;

  const _LoadedView({
    required this.state,
    required this.controller,
    required this.horizontal,
    required this.onRefresh,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: ColorsApp.primaryGreenPressed,
        // Scrollable even when empty, so pull-to-refresh still works.
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: 120.h), const _EmptyState()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: ColorsApp.primaryGreenPressed,
      child: ListView.separated(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontal, 20.h, horizontal, 32.h),
        // One extra row for the footer spinner while the next page loads.
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(
                child: CircularProgressIndicator(
                  color: ColorsApp.primaryGreenPressed,
                  strokeWidth: 3,
                ),
              ),
            );
          }

          final notification = state.items[index];
          return NotificationCard(
            notification: notification,
            onTap: () {
              final int? id = notification.id;
              if (id != null) onTap(id);
            },
            onDismissed: () {
              final int? id = notification.id;
              if (id != null) onDismissed(id);
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 40.r,
            color: ColorsApp.onSurfaceVariant,
          ),
          SizedBox(height: 12.h),
          Text(
            'notifications_page.empty_title'.tr(),
            style: TextStyleApp.transactionsEmptyTitle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Text(
            'notifications_page.empty_body'.tr(),
            style: TextStyleApp.dashboardStatLabel,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
