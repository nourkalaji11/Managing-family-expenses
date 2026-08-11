import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:family_expense_management/style/colors.dart';

/// One arc of [DonutChart].
class DonutSlice {
  final double fraction;
  final Color color;

  const DonutSlice({required this.fraction, required this.color});
}

/// The "توزيع المصاريف" ring.
///
/// Drawn with a [CustomPainter] rather than a charting package — the plan
/// explicitly rules out new dependencies, and this is a single stroked arc set.
///
/// The design's SVG uses `r="15.9"` with `stroke-width="3"` in a 36-unit
/// viewBox, which is reproduced here as [strokeWidthRatio].
class DonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final double size;

  /// Content rendered in the middle of the ring.
  final Widget? center;

  /// Stroke width as a fraction of [size]: 3/36 in the design's SVG.
  static const double strokeWidthRatio = 3 / 36;

  const DonutChart({
    super.key,
    required this.slices,
    required this.size,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    // In RTL the ring sweeps counter-clockwise so the first (largest) slice
    // still reads as "the start" for a right-to-left reader.
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          slices: slices,
          strokeWidth: size * strokeWidthRatio,
          clockwise: !isRtl,
        ),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final double strokeWidth;
  final bool clockwise;

  /// 12 o'clock.
  static const double _startAngle = -math.pi / 2;

  const _DonutPainter({
    required this.slices,
    required this.strokeWidth,
    required this.clockwise,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = ColorsApp.surfaceContainerLow;

    // The track is always drawn: it shows through if the slices do not sum to
    // 1, and it is the entire visual when there is no data.
    canvas.drawCircle(center, radius, track);

    double sweptSoFar = 0;
    for (final slice in slices) {
      final fraction = slice.fraction.clamp(0.0, 1.0);
      if (fraction <= 0) continue;

      final sweep = 2 * math.pi * fraction;
      final direction = clockwise ? 1 : -1;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = slice.color;

      canvas.drawArc(
        rect,
        _startAngle + direction * sweptSoFar,
        direction * sweep,
        false,
        paint,
      );

      sweptSoFar += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    if (oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.clockwise != clockwise ||
        oldDelegate.slices.length != slices.length) {
      return true;
    }
    for (int i = 0; i < slices.length; i++) {
      if (oldDelegate.slices[i].fraction != slices[i].fraction ||
          oldDelegate.slices[i].color != slices[i].color) {
        return true;
      }
    }
    return false;
  }
}
