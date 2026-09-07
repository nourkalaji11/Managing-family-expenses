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

  /// Icons by the name the server sends in `categories.icon`.
  ///
  /// Keyed by name rather than by id because ids are not stable across a fresh
  /// seed, and because the server chose the name deliberately — mapping it here
  /// is the client's half of that contract.
  static const Map<String, IconData> _iconsByName = {
    // Income
    'salary': Icons.payments_outlined,
    'bonus': Icons.emoji_events_outlined,
    'gift': Icons.card_giftcard_outlined,
    'sale': Icons.sell_outlined,
    'extra': Icons.add_circle_outline,
    'top_up': Icons.account_balance_wallet_outlined,
    // Movement
    'cash_out': Icons.money_off_outlined,
    'transfer': Icons.swap_horiz,
    'credit_payment': Icons.credit_card_outlined,
    'atm': Icons.local_atm_outlined,
    // Food
    'food': Icons.restaurant_menu_outlined,
    'cafe': Icons.local_cafe_outlined,
    'restaurant': Icons.restaurant,
    'home_cooking': Icons.soup_kitchen_outlined,
    'fast_food': Icons.lunch_dining_outlined,
    'groceries': Icons.local_grocery_store_outlined,
    // Shopping
    'shopping': Icons.shopping_cart_outlined,
    'accessories': Icons.watch_outlined,
    'clothes': Icons.checkroom_outlined,
    'electronics': Icons.devices_outlined,
    'shoes': Icons.ice_skating_outlined,
    'cosmetics': Icons.brush_outlined,
    // Transport
    'transport': Icons.directions_car_outlined,
    'fuel': Icons.local_gas_station_outlined,
    'car_service': Icons.build_outlined,
    'parking': Icons.local_parking_outlined,
    'taxi': Icons.local_taxi_outlined,
    'company_taxi': Icons.airport_shuttle_outlined,
    'public_transport': Icons.directions_bus_outlined,
    // Bills
    'bills': Icons.receipt_long_outlined,
    'electricity': Icons.bolt_outlined,
    'gas': Icons.propane_tank_outlined,
    'internet': Icons.wifi_outlined,
    'phone': Icons.phone_outlined,
    'rent': Icons.home_outlined,
    'water': Icons.water_drop_outlined,
    // Household and people
    'family': Icons.family_restroom_outlined,
    'children': Icons.child_care_outlined,
    'home_repair': Icons.handyman_outlined,
    'services': Icons.cleaning_services_outlined,
    'pets': Icons.pets_outlined,
    // Work, study, money
    'work': Icons.work_outline,
    'education': Icons.school_outlined,
    'books': Icons.menu_book_outlined,
    'courses': Icons.cast_for_education_outlined,
    'investment': Icons.trending_up_outlined,
    'insurance': Icons.shield_outlined,
    'subscriptions': Icons.subscriptions_outlined,
    // Leisure, giving, health
    'entertainment': Icons.tv_outlined,
    'games': Icons.sports_esports_outlined,
    'movies': Icons.movie_outlined,
    'donations': Icons.volunteer_activism_outlined,
    'charity': Icons.favorite_border,
    'zakat': Icons.spa_outlined,
    'health': Icons.favorite_outline,
    'doctor': Icons.medical_services_outlined,
    'medicine': Icons.medication_outlined,
    'personal_care': Icons.self_improvement_outlined,
    'sports': Icons.fitness_center_outlined,
    'travel': Icons.flight_takeoff_outlined,
    // Debt and leftovers
    'debt': Icons.request_quote_outlined,
    'borrow': Icons.south_west_outlined,
    'repay': Icons.north_east_outlined,
    'lent': Icons.call_made_outlined,
    'owed': Icons.call_received_outlined,
    'other': Icons.category_outlined,
    'misc': Icons.more_horiz,
  };

  /// Icon for a transaction row. `receipt_long` is the generic fallback.
  ///
  /// [name] is `categories.icon`. The id map behind it only still exists for
  /// rows created before that column, which carry no name.
  static IconData iconFor(int? categoryId, {String? name}) {
    if (name != null) {
      final byName = _iconsByName[name];
      if (byName != null) return byName;
    }
    if (categoryId == null) return Icons.receipt_long_outlined;
    return _icons[categoryId] ?? Icons.receipt_long_outlined;
  }
}
