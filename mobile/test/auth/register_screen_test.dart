import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/register_screen.dart';
import 'package:family_expense_management/presentation/pages/auth/presentation/widgets/account_type_selector.dart';

import 'auth_test_harness.dart';

void main() {
  setUp(resetLocator);

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('auth_name_field')),
      'أبو محمد',
    );
    await tester.enterText(
      find.byKey(const Key('auth_email_field')),
      'parent@family.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth_password_field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('auth_confirm_password_field')),
      'password123',
    );
  }

  testWidgets('register: an empty form reports every required field', (
    tester,
  ) async {
    await tester.pumpWidget(wrapForTest(const RegisterScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('auth_register_button')));
    await tester.pump();

    expect(find.text('auth.error_name_required'), findsOneWidget);
    expect(find.text('auth.error_email_required'), findsOneWidget);
    expect(find.text('auth.error_password_required'), findsOneWidget);
    expect(find.text('auth.error_password_confirm_required'), findsOneWidget);
    expect(find.text('auth.error_terms_required'), findsOneWidget);
  });

  testWidgets('register: mismatched passwords are rejected', (tester) async {
    await tester.pumpWidget(wrapForTest(const RegisterScreen()));
    await tester.pumpAndSettle();

    await fillValidForm(tester);
    await tester.enterText(
      find.byKey(const Key('auth_confirm_password_field')),
      'different123',
    );
    await tester.tap(find.byKey(const Key('auth_register_button')));
    await tester.pump();

    expect(find.text('auth.error_passwords_not_match'), findsOneWidget);
  });

  testWidgets('register: a valid form is still blocked until the terms '
      'checkbox is ticked', (tester) async {
    await tester.pumpWidget(wrapForTest(const RegisterScreen()));
    await tester.pumpAndSettle();

    await fillValidForm(tester);
    await tester.tap(find.byKey(const Key('auth_register_button')));
    await tester.pump();

    expect(find.text('auth.error_terms_required'), findsOneWidget);

    // Ticking the box clears the error.
    await tester.tap(find.byKey(const Key('auth_terms_checkbox')));
    await tester.pump();
    expect(find.text('auth.error_terms_required'), findsNothing);
  });

  testWidgets('register: the role selector defaults to parent and switches to '
      'member', (tester) async {
    await tester.pumpWidget(wrapForTest(const RegisterScreen()));
    await tester.pumpAndSettle();

    AccountTypeSelector selector() =>
        tester.widget<AccountTypeSelector>(find.byType(AccountTypeSelector));

    expect(selector().value, AccountRole.parent);

    await tester.tap(find.byKey(const Key('auth_role_member')));
    await tester.pump();

    expect(selector().value, AccountRole.member);
  });

  testWidgets('register: password fields toggle independently', (tester) async {
    await tester.pumpWidget(wrapForTest(const RegisterScreen()));
    await tester.pumpAndSettle();

    bool obscured(Key key) => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(TextField),
          ),
        )
        .obscureText;

    expect(obscured(const Key('auth_password_field')), isTrue);
    expect(obscured(const Key('auth_confirm_password_field')), isTrue);

    await tester.tap(find.byKey(const Key('auth_password_toggle')));
    await tester.pump();

    expect(obscured(const Key('auth_password_field')), isFalse);
    // The confirm field owns a separate PasswordCubit, so it stays hidden.
    expect(obscured(const Key('auth_confirm_password_field')), isTrue);
  });

  testWidgets('register: renders without overflowing a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 480 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrapForTest(const RegisterScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
