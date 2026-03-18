import 'package:countpluse/screens/auth/auth_screen.dart';
import 'package:countpluse/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpAuthScreen(
  WidgetTester tester, {
  LoginAction? loginAction,
  RegisterAction? registerAction,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AuthScreen(
        loginAction:
            loginAction ??
            ({required email}) async => AuthUser(
              userId: 'user-1',
              name: 'Braj',
              email: email,
              phone: '',
            ),
        registerAction:
            registerAction ??
            ({required name, required email, required phone}) async => AuthUser(
              userId: 'user-1',
              name: name,
              email: email,
              phone: phone,
            ),
      ),
    ),
  );
}

void main() {
  testWidgets('login shows invalid email message for malformed email', (
    tester,
  ) async {
    await _pumpAuthScreen(tester);

    await tester.enterText(find.byKey(const Key('login_email_field')), 'wrong-email');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    expect(find.text('Please enter a valid email address'), findsOneWidget);
  });

  testWidgets('login strips exception prefix for invalid email backend error', (
    tester,
  ) async {
    await _pumpAuthScreen(
      tester,
      loginAction: ({required email}) async {
        throw Exception('Invalid email');
      },
    );

    await tester.enterText(find.byKey(const Key('login_email_field')), 'braj@gmail.com');
    await tester.tap(find.text('Send OTP'));
    await tester.pump();

    expect(find.text('Invalid email'), findsOneWidget);
    expect(find.textContaining('Exception:'), findsNothing);
  });

  testWidgets('login navigates to OTP screen for valid email', (tester) async {
    await _pumpAuthScreen(tester);

    await tester.enterText(find.byKey(const Key('login_email_field')), 'braj@gmail.com');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('OTP Verification'), findsOneWidget);
  });

  testWidgets('register validates empty name locally', (tester) async {
    await _pumpAuthScreen(tester);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name'), findsOneWidget);
  });

  testWidgets('register validates empty email locally', (tester) async {
    await _pumpAuthScreen(tester);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('register_name_field')), 'Braj');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
  });

  testWidgets('register validates empty phone locally', (tester) async {
    await _pumpAuthScreen(tester);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('register_name_field')), 'Braj');
    await tester.enterText(find.byKey(const Key('register_email_field')), 'braj@gmail.com');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your phone number'), findsOneWidget);
  });

  testWidgets('register validates malformed phone number locally', (
    tester,
  ) async {
    await _pumpAuthScreen(tester);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('register_name_field')), 'Braj');
    await tester.enterText(find.byKey(const Key('register_email_field')), 'braj@gmail.com');
    await tester.enterText(find.byKey(const Key('register_phone_field')), '12ab');
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(find.text('Please enter a valid phone number'), findsOneWidget);
  });

  testWidgets('register navigates to OTP screen for valid details', (
    tester,
  ) async {
    await _pumpAuthScreen(tester);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('register_name_field')), 'Braj');
    await tester.enterText(find.byKey(const Key('register_email_field')), 'braj@gmail.com');
    await tester.enterText(find.byKey(const Key('register_phone_field')), '9876543210');
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('OTP Verification'), findsOneWidget);
  });
}
