import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/core/locals_app.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/text_style.dart';

/// The circular user avatar shown in the dashboard and transactions app bars.
///
/// Extracted from `DashboardAppBar`, where it used to be a private widget, once
/// a second screen needed the identical thing. Behaviour and appearance are
/// unchanged — only [size] is new, because the transactions design draws it at
/// 32px where the dashboard draws it at 40px.
///
/// TODO(backend): `users` has no avatar/photo column, so there is no image to
/// load. Until one exists this renders the user's first initial on the design's
/// `surface-container-high` tint, which degrades gracefully and needs no asset.
class ProfileAvatar extends StatelessWidget {
  /// Diameter in logical pixels, before `.r` scaling.
  final double size;

  const ProfileAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final String? name = LocalsApp.user?.name?.trim();
    final String initial = (name != null && name.isNotEmpty)
        ? name.characters.first
        : '?';

    return Container(
      width: size.r,
      height: size.r,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xffDCE9FF),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyleApp.dashboardSectionTitle.copyWith(
          color: ColorsApp.dashboardBlue,
        ),
      ),
    );
  }
}
