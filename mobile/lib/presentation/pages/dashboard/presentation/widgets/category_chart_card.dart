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
/// The ring draws every slice, "أخرى" included, and the legend lists all of
/// them.
///
/// The design's SVG leaves the remainder as bare background track
/// (`docs/stitch_family_finance_tracker/dashboard_screen_minimal_redesign`:
/// 40 + 30 + 20 = 90%, with `#eff4ff` showing through for the last 10%), and
/// this card used to reproduce that by filtering the "other" slice out of both.
/// It read as a bug rather than as a choice: the ring visibly had a fourth
/// segment that the legend refused to name, so the only way to find out what
/// the pale arc was, was to add up the other three. It is now drawn in
/// [CategoryVisuals.otherColor], a neutral grey deliberately darker than the
/// empty track behind it: "spent on something small" and "nothing here" have to
/// look different.
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
    // Every slice, in breakdown order — "أخرى" is last, because `_buildBreakdown`
    // appends it after the named categories. The index is carried along because
    // it is what picks the colour for a category the palette does not map.
    final slices = <({CategoryBreakdown slice, int index})>[
      for (int i = 0; i < summary.breakdown.length; i++)
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
    // The "other" slice carries a null `categoryId`, which `colorFor` answers
    // with `otherColor` — so its dot matches its arc without this row having to
    // special-case it.
    final color = CategoryVisuals.colorFor(slice.categoryId, index: index);

    // "أخرى" for the synthetic slice, which is built with a null name, and for
    // any real category whose name did not arrive — better than a blank row.
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
