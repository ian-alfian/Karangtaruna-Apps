import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karangtaruna_apps/demo_data.dart';
import 'package:karangtaruna_apps/email_policy.dart';
import 'package:karangtaruna_apps/firebase_login.dart';
import 'package:karangtaruna_apps/login_screen.dart';

void main() {
  test('profil aktif menentukan peran dari Firestore', () {
    final profile = FirebaseUserProfile.fromData(
      uid: 'user-1',
      email: 'bendahara@gmail.com',
      data: {
        'name': 'Sari',
        'organizationId': 'org-1',
        'role': 'bendahara',
        'isActive': true,
      },
    );

    expect(profile.name, 'Sari');
    expect(profile.role, AppRole.bendahara);
    expect(profile.organizationId, 'org-1');
  });

  test('profil tanpa akses organisasi atau peran yang sah ditolak', () {
    final base = <String, dynamic>{
      'name': 'Sari',
      'organizationId': 'org-1',
      'role': 'anggota',
      'isActive': true,
    };

    for (final changes in [
      {'isActive': false},
      {'organizationId': ''},
      {'role': 'superadmin'},
    ]) {
      expect(
        () => FirebaseUserProfile.fromData(
          uid: 'user-1',
          email: 'sari@gmail.com',
          data: {...base, ...changes},
        ),
        throwsA(isA<FirebaseProfileException>()),
      );
    }
  });

  test('akun biasa wajib Gmail dan hanya Admin pertama dikecualikan', () {
    expect(isGmailEmail(' User+Alias@GMAIL.COM '), isTrue);
    expect(isGmailEmail('user@sub.gmail.com'), isFalse);
    expect(isGmailEmail('user@gmail.com.evil'), isFalse);
    expect(isAllowedLoginEmail(superAdminEmail), isTrue);
    expect(isAllowedLoginEmail('admin@kampus.ac.id'), isFalse);
    expect(
      () => FirebaseUserProfile.fromData(
        uid: 'user-2',
        email: 'anggota@kampus.ac.id',
        data: {
          'name': 'Anggota',
          'organizationId': 'org-1',
          'role': 'anggota',
          'isActive': true,
        },
      ),
      throwsA(isA<FirebaseProfileException>()),
    );
    expect(
      () => FirebaseUserProfile.fromData(
        uid: 'user-3',
        email: superAdminEmail,
        data: {
          'name': 'Bukan Admin',
          'organizationId': 'org-1',
          'role': 'anggota',
          'isActive': true,
        },
      ),
      throwsA(isA<FirebaseProfileException>()),
    );
  });

  testWidgets('form login memvalidasi email dan mengirim kredensial', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? submittedEmail;
    String? submittedPassword;
    bool? submittedRememberMe;
    AppRole? submittedRole;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onSignIn: (email, password, rememberMe, role) async {
            submittedEmail = email;
            submittedPassword = password;
            submittedRememberMe = rememberMe;
            submittedRole = role;
          },
          onResetPassword: (_) async {},
        ),
      ),
    );

    expect(find.text('Buka Pratinjau'), findsNothing);
    expect(find.text('Masuk dengan Firebase'), findsNothing);
    expect(find.textContaining('Mode lokal'), findsNothing);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Anggota'), findsOneWidget);
    expect(find.text('Bendahara'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
    expect(submittedEmail, isNull);

    await tester.enterText(
      find.byType(TextFormField).first,
      'sari@kampus.ac.id',
    );
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text(gmailOnlyMessage), findsOneWidget);
    expect(submittedEmail, isNull);

    await tester.enterText(
      find.byType(TextFormField).first,
      ' sari@gmail.com ',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password-rahasia');
    await tester.tap(find.text('Ingat Saya'));
    await tester.tap(find.byKey(const ValueKey('login-role-bendahara')));
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(submittedEmail, 'sari@gmail.com');
    expect(submittedPassword, 'password-rahasia');
    expect(submittedRememberMe, true);
    expect(submittedRole, AppRole.bendahara);
  });

  testWidgets('atur password hanya memerlukan email', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? resetEmail;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onSignIn: (_, _, _, _) async {},
          onResetPassword: (email) async => resetEmail = email,
        ),
      ),
    );

    await tester.tap(find.text('Atur / lupa password'));
    await tester.pump();
    expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
    expect(find.text('Masukkan password.'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, superAdminEmail);
    await tester.tap(find.text('Atur / lupa password'));
    await tester.pump();
    expect(resetEmail, superAdminEmail);
    expect(find.text('Masukkan password.'), findsNothing);
  });
}
