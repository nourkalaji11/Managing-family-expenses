import 'package:flutter/material.dart';
import 'package:family_expense_management/style/colors.dart';

/// Colour and icon for a spending category.
///
/// ---------------------------------------------------------------------------
/// TODO(backend): this lookup exists only because the `categories` table has
/// just `(id, name)` — no `color` and no `icon` column. Adding those two columns
/// makes this file deletable and lets the palette be managed server-side, which
/// also fixes the fallback case below (a category the app has never seen gets a
/// generic tint instead of its own identity).
/// ---------------------------------------------------------------------------
///
/// Keyed by category **id** rather than name so that renaming a category in the
/// backend does not silently change its colour. Ids match
/// `DashboardMockSource`; once the real API is wired the ids come from the
/// server and this map is what needs replacing.
class CategoryVisuals {
  const CategoryVisuals._();

  /// The three named slice colours in the design, in the design's order.
  static const Color _restaurantsColor = ColorsApp.primaryGreenPressed;
  static const Color _housingColor = ColorsApp.dashboardBlue;
  static const Color _transportColor = ColorsApp.dashboardAmber;

  /// The synthetic "أخرى" slice, and the fallback for unknown categories.
  static const Color otherColor = ColorsApp.outlineVariant;

  static const Map<int, Color> _colors = {
    1: _restaurantsColor,
    2: _housingColor,
    3: _transportColor,
  };

  static const Map<int, IconData> _icons = {
    1: Icons.restaurant,
    2: Icons.home_outlined,
    3: Icons.directions_car_outlined,
    4: Icons.shopping_cart_outlined,
    5: Icons.payments_outlined,
  };

  /// Ordered palette used for any category beyond the mapped ones, so a real
  /// dataset still produces distinguishable arcs.
  static const List<Color> _fallbackPalette = [
    _restaurantsColor,
    _housingColor,
    _transportColor,
    ColorsApp.primaryGreen,
    ColorsApp.googleBlue,
  ];

  /// Colour for a slice. [index] is the slice's position, used only when
  /// [categoryId] is unknown.
  static Color colorFor(int? categoryId, {int index = 0}) {
    if (categoryId == null) return otherColor;
    final mapped = _colors[categoryId];
    if (mapped != null) return mapped;
    return _fallbackPalette[index % _fallbackPalette.length];
  }

  /// Icon for a transaction row. `receipt_long` is the generic fallback.
  static IconData iconFor(int? categoryId) {
    if (categoryId == null) return Icons.receipt_long_outlined;
    return _icons[categoryId] ?? Icons.receipt_long_outlined;
  }
}
