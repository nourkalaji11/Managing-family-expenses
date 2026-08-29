import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/login_screen.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/register_screen.dart';

import 'auth_test_harness.dart';

void main() {
  setUp(resetLocator);

  testWidgets('login: submitting an empty form shows validation errors and '
      'stays on the screen', (tester) async {
    await tester.pumpWidget(wrapForTest(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('auth_login_button')));
    await tester.pump();

    expect(find.text('auth.error_email_required'), findsOneWidget);
    expect(find.text('auth.error_password_required'), findsOneWidget);
    // This asserts UI behaviour only: the form did not advance. Whether an API
    // request was dispatched is not observable from a widget test — that is
    // guaranteed by the early `return` in `_submit()` when validation fails.
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('login: a malformed email is rejected', (tester) async {
    await tester.pumpWidget(wrapForTest(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth_email_field')),
      'not-an-email',
    );
    await tester.enterText(
      find.byKey(const Key('auth_password_field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('auth_login_button')));
    await tester.pump();

    expect(find.text('auth.error_email_invalid'), findsOneWidget);
    expect(find.text('auth.error_password_required'), findsNothing);
  });

  testWidgets('login: a short password is rejected', (tester) async {
    await tester.pumpWidget(wrapForTest(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('auth_email_field')),
      'parent@family.com',
    );
    await tester.enterText(find.byKey(const Key('auth_password_field')), '123');
    await tester.tap(find.byKey(const Key('auth_login_button')));
    await tester.pump();

    expect(find.text('auth.error_password_short'), findsOneWidget);
  });

  testWidgets('login: the eye icon toggles password visibility', (
    tester,
  ) async {
    await tester.pumpWidget(wrapForTest(const LoginScreen()));
    await tester.pumpAndSettle();

    final fieldFinder = find.byKey(const Key('auth_password_field'));
    TextField innerField() => tester.widget<TextField>(
      find.descendant(of: fieldFinder, matching: find.byType(TextField)),
    );

    expect(innerField().obscureText, isTrue);

    await tester.tap(find.byKey(const Key('auth_password_toggle')));
    await tester.pump();
    expect(innerField().obscureText, isFalse);

    await tester.tap(find.byKey(const Key('auth_password_toggle')));
    await tester.pump();
    expect(innerField().obscureText, isTrue);
  });

  testWidgets('login: the register link navigates to RegisterScreen', (
    tester,
  ) async {
    await tester.pumpWidget(wrapForTest(const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('auth_register_link')));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('login: renders without overflowing a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 480 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrapForTest(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
