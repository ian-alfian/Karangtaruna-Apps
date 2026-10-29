import 'package:flutter_test/flutter_test.dart';
import 'package:karangtaruna_apps/demo_data.dart';
import 'package:karangtaruna_apps/firebase_login.dart';
import 'package:karangtaruna_apps/login_bloc.dart';

class _FakeLoginGateway implements LoginGateway {
  _FakeLoginGateway(this.profile);

  final FirebaseUserProfile profile;
  Object? signInError;
  Object? resetError;
  String? emailUsed;
  bool? rememberMeUsed;
  int signOutCount = 0;

  @override
  Future<FirebaseUserProfile> signIn(
    String email,
    String password, {
    required bool rememberMe,
  }) async {
    emailUsed = email;
    rememberMeUsed = rememberMe;
    if (signInError != null) throw signInError!;
    return profile;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    emailUsed = email;
    if (resetError != null) throw resetError!;
  }

  @override
  Future<void> signOut() async => signOutCount++;
}

void main() {
  const admin = FirebaseUserProfile(
    uid: 'admin-1',
    name: 'Admin',
    email: 'admin@example.com',
    organizationId: 'org-1',
    role: AppRole.admin,
  );

  test('Admin masuk ke tampilan peran yang dipilih', () async {
    final gateway = _FakeLoginGateway(admin);
    FirebaseUserProfile? activated;
    final bloc = LoginBloc(gateway, (profile) async => activated = profile);
    addTearDown(bloc.close);

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<LoginLoading>(),
        isA<LoginSuccess>().having(
          (state) => state.viewRole,
          'viewRole',
          AppRole.bendahara,
        ),
      ]),
    );
    bloc.add(
      const LoginSubmitted(
        email: 'admin@example.com',
        password: 'password-rahasia',
        rememberMe: true,
        selectedRole: AppRole.bendahara,
      ),
    );
    await states;

    expect(activated, admin);
    expect(gateway.emailUsed, 'admin@example.com');
    expect(gateway.rememberMeUsed, true);
  });

  test('peran akun yang tidak cocok ditolak dan sesi dibersihkan', () async {
    final gateway = _FakeLoginGateway(
      const FirebaseUserProfile(
        uid: 'member-1',
        name: 'Anggota',
        email: 'anggota@example.com',
        organizationId: 'org-1',
        role: AppRole.anggota,
      ),
    );
    var activated = false;
    final bloc = LoginBloc(gateway, (_) async => activated = true);
    addTearDown(bloc.close);

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<LoginLoading>(),
        isA<LoginFailure>().having(
          (state) => state.message,
          'message',
          contains('Pilih peran yang sesuai'),
        ),
      ]),
    );
    bloc.add(
      const LoginSubmitted(
        email: 'anggota@example.com',
        password: 'password-rahasia',
        rememberMe: false,
        selectedRole: AppRole.bendahara,
      ),
    );
    await states;

    expect(activated, false);
    expect(gateway.signOutCount, 1);
  });

  test('reset password mengirim email tanpa mengeluarkan sesi', () async {
    final gateway = _FakeLoginGateway(admin);
    final bloc = LoginBloc(gateway, (_) async {});
    addTearDown(bloc.close);

    final states = expectLater(
      bloc.stream,
      emitsInOrder([isA<LoginLoading>(), isA<PasswordResetSent>()]),
    );
    bloc.add(const PasswordResetRequested('admin@example.com'));
    await states;

    expect(gateway.emailUsed, 'admin@example.com');
    expect(gateway.signOutCount, 0);
  });
}
