// Smoke test for the shared authentication widgets.
//
// The previous contents of this file were the unmodified Flutter counter
// template, which asserted on a counter UI this app never had and so always
// failed. The feature-level tests live in `test/auth/`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/auth_primary_button.dart';

import 'auth/auth_test_harness.dart';

void main() {
  setUp(resetLocator);

  testWidgets('AuthPrimaryButton ignores taps while loading', (tester) async {
    int taps = 0;

    await tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: AuthPrimaryButton(
            text: 'submit',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(AuthPrimaryButton));
    await tester.pump();

    expect(taps, 0);
  });

  testWidgets('AuthPrimaryButton forwards taps when idle', (tester) async {
    int taps = 0;

    await tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: AuthPrimaryButton(text: 'submit', onPressed: () => taps++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AuthPrimaryButton));
    await tester.pump();

    expect(taps, 1);
  });
}
