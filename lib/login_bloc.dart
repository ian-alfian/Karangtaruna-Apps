import 'package:flutter_bloc/flutter_bloc.dart';

import 'demo_data.dart';
import 'firebase_login.dart';

/// Perintah yang dapat dikirim oleh halaman masuk ke [LoginBloc].
sealed class LoginEvent {
  const LoginEvent();
}

/// Meminta login dengan kredensial dan peran yang dipilih pengguna.
final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({
    required this.email,
    required this.password,
    required this.rememberMe,
    required this.selectedRole,
  });

  final String email;
  final String password;
  final bool rememberMe;
  final AppRole selectedRole;
}

/// Meminta tautan pengaturan ulang password melalui email.
final class PasswordResetRequested extends LoginEvent {
  const PasswordResetRequested(this.email);

  final String email;
}

/// Menampilkan kegagalan pemulihan sesi pada halaman login.
final class LoginErrorReported extends LoginEvent {
  const LoginErrorReported(this.message);

  final String message;
}

/// Mengosongkan pesan login setelah pengguna keluar.
final class LoginCleared extends LoginEvent {
  const LoginCleared();
}

/// Kondisi yang dapat ditampilkan oleh halaman login.
sealed class LoginState {
  const LoginState();
}

/// Belum ada proses login yang sedang berjalan.
final class LoginInitial extends LoginState {
  const LoginInitial();
}

/// Login atau reset password sedang menunggu jawaban Firebase.
final class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Login berhasil dan profil sudah siap dipakai aplikasi.
final class LoginSuccess extends LoginState {
  const LoginSuccess(this.profile, this.viewRole);

  final FirebaseUserProfile profile;
  final AppRole? viewRole;
}

/// Tindakan login gagal dengan pesan yang bisa ditampilkan kepada pengguna.
final class LoginFailure extends LoginState {
  const LoginFailure(this.message);

  final String message;
}

/// Email reset password telah diminta melalui Firebase.
final class PasswordResetSent extends LoginState {
  const PasswordResetSent(this.message);

  final String message;
}

/// Mengubah event login menjadi state tanpa menyimpan password di state UI.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  /// Menghubungkan layanan Firebase dan persiapan data ke alur login.
  LoginBloc(this._gateway, this._activateProfile)
    : super(const LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<LoginErrorReported>((event, emit) => emit(LoginFailure(event.message)));
    on<LoginCleared>((event, emit) => emit(const LoginInitial()));
  }

  final LoginGateway _gateway;
  final Future<void> Function(FirebaseUserProfile) _activateProfile;

  /// Memvalidasi peran, masuk ke Firebase, lalu menyiapkan data organisasi.
  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state is LoginLoading) return;
    emit(const LoginLoading());
    try {
      final profile = await _gateway.signIn(
        event.email,
        event.password,
        rememberMe: event.rememberMe,
      );
      if (profile.role != AppRole.admin && profile.role != event.selectedRole) {
        throw FirebaseProfileException(
          'Akun ini terdaftar sebagai ${profile.role.label}. Pilih peran yang sesuai.',
        );
      }
      await _activateProfile(profile);
      emit(
        LoginSuccess(
          profile,
          profile.role == AppRole.admin ? event.selectedRole : null,
        ),
      );
    } catch (error) {
      try {
        await _gateway.signOut();
      } catch (_) {
        // Pesan utama tetap berasal dari kegagalan login.
      }
      emit(LoginFailure(firebaseLoginError(error)));
    }
  }

  /// Mengirim permintaan reset password dan menampilkan hasilnya.
  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (state is LoginLoading) return;
    emit(const LoginLoading());
    try {
      await _gateway.sendPasswordReset(event.email);
      emit(
        const PasswordResetSent(
          'Jika email terdaftar, tautan pengaturan password telah dikirim.',
        ),
      );
    } catch (error) {
      emit(LoginFailure(firebaseLoginError(error)));
    }
  }
}
