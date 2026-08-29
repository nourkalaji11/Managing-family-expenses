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
/// Matches `docs/stitch_family_finance_tracker/dashboard_screen_minimal_redesign`:
/// the ring draws only the named categories and the remainder shows the
/// background track, exactly as the design's SVG does (40 + 30 + 20 = 90%, with
/// `#eff4ff` visible for the last 10%). The "أخرى" bucket is therefore not
/// drawn as its own arc and not listed in the legend.
class CategoryChartCard extends StatelessWidget {
  final DashboardSummary summary;

  /// Below this width the donut and legend stack instead of sitting side by
  /// side, which keeps very small screens from squeezing the legend to nothing.
  ///
  /// The design is `flex items-center justify-between` — always side by side.
  /// On a 1080px phone this card measures ~339dp, so a 340 threshold tipped it
  /// into the stacked branch and never matched the design. 300 keeps the
  /// safety net for genuinely narrow screens without catching normal phones.
  static const double stackBreakpoint = 300;

  const CategoryChartCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    // Only the named categories are drawn and listed. The index is carried
    // along so the colour assignment stays tied to the slice's position in the
    // full breakdown rather than its position after filtering.
    final slices = <({CategoryBreakdown slice, int index})>[
      for (int i = 0; i < summary.breakdown.length; i++)
        if (!summary.breakdown[i].isOther)
          (slice: summary.breakdown[i], index: i),
    ];

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
                final chart = _Chart(
                  summary: summary,
                  slices: slices,
                  maxWidth: constraints.maxWidth,
                );
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
  final List<({CategoryBreakdown slice, int index})> slices;
  final double maxWidth;

  const _Chart({
    required this.summary,
    required this.slices,
    required this.maxWidth,
  });

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
        for (final entry in slices)
          DonutSlice(
            fraction: entry.slice.fraction,
            color: CategoryVisuals.colorFor(
              entry.slice.categoryId,
              index: entry.index,
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
  final List<({CategoryBreakdown slice, int index})> slices;

  const _Legend({required this.slices});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < slices.length; i++) ...[
          if (i > 0) SizedBox(height: 12.h),
          _LegendRow(slice: slices[i].slice, index: slices[i].index),
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
    // `isOther` rows are filtered out before reaching the legend, so this only
    // ever renders a named category.
    final color = CategoryVisuals.colorFor(slice.categoryId, index: index);

    // Unnamed categories fall back to the localised "أخرى" rather than showing
    // a blank row.
    final name = slice.categoryName ?? 'dashboard.other'.tr();

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
