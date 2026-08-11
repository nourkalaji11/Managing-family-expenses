import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/models/dashboard_summary.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/category_visuals.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/dashboard_formatter.dart';
import 'package:family_expense_management/presentation/pages/dashboard/presentation/widgets/donut_chart.dart';
import 'package:family_expense_management/style/text_style.dart';

/// "توزيع المصاريف" — the donut plus its legend.
///
/// Per the approved strategy the ring shows the top three categories and folds
/// everything else into a single "أخرى" slice, so it always closes to 100%.
class CategoryChartCard extends StatelessWidget {
  final DashboardSummary summary;

  /// Below this width the donut and legend stack instead of sitting side by
  /// side, which keeps very small screens from squeezing the legend to nothing.
  static const double stackBreakpoint = 340;

  const CategoryChartCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final slices = summary.breakdown;

    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'dashboard.spending_distribution'.tr(),
            style: TextStyleApp.dashboardSectionTitle,
          ),
          SizedBox(height: 24.h),
          if (slices.isEmpty)
            _EmptyChartHint()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final chart = _Chart(summary: summary, maxWidth: constraints.maxWidth);
                final legend = _Legend(slices: slices);

                if (constraints.maxWidth < stackBreakpoint) {
                  return Column(
                    children: [
                      chart,
                      SizedBox(height: 20.h),
                      legend,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [chart, Flexible(child: legend)],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final DashboardSummary summary;
  final double maxWidth;

  const _Chart({required this.summary, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    // 160px in the design, but never more than ~42% of the available width so
    // the legend keeps room on small screens.
    final size = maxWidth < CategoryChartCard.stackBreakpoint
        ? 160.r
        : (160.r).clamp(0.0, maxWidth * 0.42);

    return DonutChart(
      size: size.toDouble(),
      slices: [
        for (int i = 0; i < summary.breakdown.length; i++)
          DonutSlice(
            fraction: summary.breakdown[i].fraction,
            color: summary.breakdown[i].isOther
                ? CategoryVisuals.otherColor
                : CategoryVisuals.colorFor(
                    summary.breakdown[i].categoryId,
                    index: i,
                  ),
          ),
      ],
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'dashboard.total'.tr(),
            style: TextStyleApp.dashboardChartCaption,
          ),
          SizedBox(height: 2.h),
          Text(
            DashboardFormatter.compactAmount(summary.expenses),
            style: TextStyleApp.dashboardStatValue,
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<CategoryBreakdown> slices;

  const _Legend({required this.slices});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < slices.length; i++) ...[
          if (i > 0) SizedBox(height: 12.h),
          _LegendRow(slice: slices[i], index: i),
        ],
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final CategoryBreakdown slice;
  final int index;

  const _LegendRow({required this.slice, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = slice.isOther
        ? CategoryVisuals.otherColor
        : CategoryVisuals.colorFor(slice.categoryId, index: index);

    // Unnamed categories fall back to the localised "أخرى" rather than showing
    // a blank row.
    final name = slice.isOther
        ? 'dashboard.other'.tr()
        : (slice.categoryName ?? 'dashboard.other'.tr());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.r,
          height: 10.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 12.w),
        Flexible(
          child: Text(
            name,
            style: TextStyleApp.dashboardLegend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyChartHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Text(
          'dashboard.no_expenses'.tr(),
          style: TextStyleApp.dashboardStatLabel,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
