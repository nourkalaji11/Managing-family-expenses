import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/style/colors.dart';

/// The thin consumed/remaining bar under a budget's heading.
///
/// Shared by the list card and the form's preview, so the two can never render
/// the same fraction at different heights or radii.
///
/// A plain `Container` rather than `LinearProgressIndicator`: the design's bar
/// is fully rounded at both ends including the fill, which the Material widget
/// does not do without a clip wrapper of exactly this shape anyway.
class BudgetProgressBar extends StatelessWidget {
  /// Already clamped to 0..1 by `BudgetModel.progress`.
  final double value;

  final Color color;

  /// The design uses 1.5 units on the card and 2 on the preview.
  final double height;

  const BudgetProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(999.r);
    final double fraction = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height.h,
        color: ColorsApp.progressTrack,
        // `FractionallySizedBox` resolves against the parent's width without a
        // LayoutBuilder, and honours the ambient text direction, so the bar
        // fills from the right in Arabic.
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: fraction,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}
