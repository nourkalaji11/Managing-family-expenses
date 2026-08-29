import 'package:flutter/material.dart';

class ColorsApp {
  static const Color offwhite = Color(0xffFDF8F1);
  static const Color red = Color(0xffD13208);
  static const Color lightYellow = Color(0xffFCF3DA);
  static const Color yellow = Color(0xffF2C10D);
  static const Color grey = Color(0xff797878);
  static const Color grey200 = Color(0xffD4D4D4);
  static const Color black = Color(0xff222222);
  static const Color white = Color(0xffFFFFFF);
  static const Color green = Color(0xff3DCA2B);

  // ---------------------------------------------------------------------------
  // Family Expenses design system.
  // Source of truth: docs/stitch_family_finance_tracker (login/register/splash).
  // ---------------------------------------------------------------------------
  static const Color primaryGreen = Color(0xff00805E);
  static const Color primaryGreenPressed = Color(0xff006C49);
  static const Color navy = Color(0xff071A33);
  static const Color navy70 = Color(0xB3071A33);
  static const Color navy50 = Color(0x80071A33);
  static const Color authBackground = Color(0xffF7F9FF);
  static const Color inputBackground = Color(0xffF6F7FC);
  static const Color greyText = Color(0xff8F96A3);
  static const Color lightBorder = Color(0xffE1E5ED);
  static const Color progressTrack = Color(0xffE5EEFF);
  static const Color googleBlue = Color(0xff4285F4);
  static const Color facebookBlue = Color(0xff1877F2);

  // ---------------------------------------------------------------------------
  // Dashboard. APPEND-ONLY: nothing above this line was renamed or changed,
  // because other features already depend on those tokens.
  //
  // Source of truth: docs/stitch_family_finance_tracker/
  //   dashboard_screen_minimal_redesign (code.html tailwind.config + dashboard.png).
  //
  // Two existing tokens are reused rather than duplicated:
  //   * `primaryGreenPressed` (#006C49) == the design's `secondary`
  //   * `progressTrack`       (#E5EEFF) == the design's `surface-container`
  // ---------------------------------------------------------------------------

  /// `background` — the cool page background behind the cards.
  static const Color dashboardBackground = Color(0xffF8F9FF);

  /// `primary` — the blue used by the "remaining" stat and the housing arc.
  static const Color dashboardBlue = Color(0xff0058BE);

  /// `tertiary-fixed-dim` — the amber transport arc.
  static const Color dashboardAmber = Color(0xffFFB95F);

  /// `on-surface` — primary text on cards.
  static const Color onSurface = Color(0xff0B1C30);

  /// `on-surface-variant` — secondary text, inactive nav items.
  static const Color onSurfaceVariant = Color(0xff424754);

  /// `outline-variant` — card borders (rendered at 30–50% opacity).
  static const Color outlineVariant = Color(0xffC2C6D6);

  /// `surface-container-low` — tinted icon tiles and the donut track.
  static const Color surfaceContainerLow = Color(0xffEFF4FF);

  /// `error` — expense amounts and the outgoing-arrow tile.
  static const Color errorRed = Color(0xffBA1A1A);

  // ---------------------------------------------------------------------------
  // Transactions. APPEND-ONLY, and deliberately only ONE new token.
  //
  // Source of truth: docs/stitch_family_finance_tracker/
  //   transactions_list_screen_minimal_redesign and
  //   add_edit_transaction_screen_minimal_redesign.
  //
  // Everything else the two transaction screens need already exists above and is
  // reused rather than duplicated:
  //   * `primaryGreenPressed` (#006C49) == both designs' `secondary`
  //   * `errorRed`            (#BA1A1A) == `error`
  //   * `dashboardBackground` (#F8F9FF) == `background`
  //   * `onSurface`           (#0B1C30) == `on-surface`
  //   * `onSurfaceVariant`    (#424754) == `on-surface-variant`
  //   * `outlineVariant`      (#C2C6D6) == `outline-variant`
  //   * `progressTrack`       (#E5EEFF) == the list design's `surface-container`
  //                                        and the `m3-card` border
  //   * `surfaceContainerLow` (#EFF4FF) stands in for the add/edit design's
  //     `surface-container` (#F1F4F9). The two differ by about one step of
  //     lightness, well below a perceptible difference on the tinted icon tiles
  //     and the type toggle where it is used, so a near-duplicate token is not
  //     worth carrying.
  // ---------------------------------------------------------------------------

  /// `outline` — the muted label ink on the add/edit form ("الحساب", "الفئة",
  /// "التاريخ", "الوصف") and the search placeholder.
  ///
  /// Genuinely new: [outlineVariant] (#C2C6D6) is a *border* colour and fails
  /// contrast as text, while [greyText] (#8F96A3) belongs to the auth design and
  /// is a different hue. Both designs specify #727785 for this role.
  static const Color outline = Color(0xff727785);

  // ---------------------------------------------------------------------------
  // Budgets. APPEND-ONLY, and deliberately only ONE new token.
  //
  // Source of truth: docs/stitch_family_finance_tracker/
  //   budgets_list_screen_minimal_redesign and
  //   add_edit_budget_screen_minimal_redesign.
  //
  // Everything else the two budget screens need already exists above and is
  // reused rather than duplicated:
  //   * `primaryGreenPressed` (#006C49) == the list design's `primary` and the
  //                                        form design's `secondary`
  //   * `errorRed`            (#BA1A1A) == `error` (the over-budget state)
  //   * `dashboardBackground` (#F8F9FF) == the form design's `background`
  //   * `onSurface`           (#0B1C30) == `on-surface`
  //   * `onSurfaceVariant`    (#424754) == `on-surface-variant`
  //   * `outlineVariant`      (#C2C6D6) == `outline-variant`
  //   * `outline`             (#727785) == the muted field-label ink
  //   * `surfaceContainerLow` (#EFF4FF) stands in for both the month header's
  //     tint (#F7F9FC) and the preview card's `primary-container` (#E5EEFF) —
  //     the latter is already carried as `progressTrack`, which is what the
  //     progress bars use for their unfilled track.
  // ---------------------------------------------------------------------------

  /// `tertiary` — the amber "اقتربت من الحد" status ink and its progress fill.
  ///
  /// Genuinely new: [dashboardAmber] (#FFB95F) is the design's
  /// `tertiary-fixed-dim`, a *fill* tone that fails contrast as text on white.
  /// The budgets design specifies #825100 for this role.
  static const Color budgetWarning = Color(0xff825100);
}
