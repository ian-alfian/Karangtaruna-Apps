import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_data.dart';
import 'email_policy.dart';

class FirebaseUserProfile {
  /// Membuat profil pengguna hasil autentikasi Firebase.
  const FirebaseUserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.organizationId,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final String organizationId;
  final AppRole role;

  /// Membaca dan memvalidasi profil pengguna dari data Firestore.
  factory FirebaseUserProfile.fromData({
    required String uid,
    required String email,
    required Map<String, dynamic> data,
  }) {
    if (data['isActive'] != true) {
      throw const FirebaseProfileException('Akun tidak aktif. Hubungi Admin.');
    }
    final organizationValue = data['organizationId'];
    final organizationId = organizationValue is String
        ? organizationValue.trim()
        : '';
    if (organizationId.isEmpty) {
      throw const FirebaseProfileException(
        'Akun belum terhubung ke organisasi. Hubungi Admin.',
      );
    }
    final roleValue = data['role'];
    final roleName = roleValue is String
        ? roleValue.trim().toLowerCase()
        : null;
    final role = switch (roleName) {
      'anggota' => AppRole.anggota,
      'bendahara' => AppRole.bendahara,
      'admin' => AppRole.admin,
      _ => null,
    };
    if (role == null) {
      throw const FirebaseProfileException(
        'Peran akun belum valid. Hubungi Admin.',
      );
    }
    if (!isGmailEmail(email) &&
        !(role == AppRole.admin &&
            email.trim().toLowerCase() == superAdminEmail)) {
      throw const FirebaseProfileException(gmailOnlyMessage);
    }
    final nameValue = data['name'];
    final name = nameValue is String ? nameValue.trim() : '';
    return FirebaseUserProfile(
      uid: uid,
      name: name.isEmpty ? email : name,
      email: email,
      organizationId: organizationId,
      role: role,
    );
  }
}

class FirebaseProfileException implements Exception {
  /// Membuat kesalahan validasi profil Firebase.
  const FirebaseProfileException(this.message);
  final String message;
}

/// Kontrak autentikasi yang dipakai BLoC login dan dapat diganti saat pengujian.
abstract interface class LoginGateway {
  /// Memeriksa kredensial dan mengembalikan profil yang memiliki akses.
  Future<FirebaseUserProfile> signIn(
    String email,
    String password, {
    required bool rememberMe,
  });

  /// Mengakhiri sesi autentikasi yang sedang aktif.
  Future<void> signOut();

  /// Mengirim email untuk mengatur ulang password.
  Future<void> sendPasswordReset(String email);
}

class FirebaseLoginService implements LoginGateway {
  /// Membuat layanan login dan sesi Firebase.
  FirebaseLoginService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Memulihkan sesi login dan memvalidasi profil pengguna.
  Future<FirebaseUserProfile?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    if (!kIsWeb) {
      final remember =
          await SharedPreferencesAsync().getBool('remember_login') ?? true;
      if (!remember) {
        await _auth.signOut();
        return null;
      }
    }
    try {
      return await _profileFor(user);
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  /// Masuk dengan email dan password lalu mengambil profil pengguna.
  @override
  Future<FirebaseUserProfile> signIn(
    String email,
    String password, {
    required bool rememberMe,
  }) async {
    if (!isAllowedLoginEmail(email)) {
      throw const FirebaseProfileException(gmailOnlyMessage);
    }
    if (kIsWeb) {
      await _auth.setPersistence(
        rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    }
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const FirebaseProfileException('Gagal membuka sesi akun.');
    }
    try {
      final profile = await _profileFor(user);
      if (!kIsWeb) {
        await SharedPreferencesAsync().setBool('remember_login', rememberMe);
      }
      return profile;
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  /// Mengakhiri sesi pengguna di Firebase Auth.
  @override
  Future<void> signOut() => _auth.signOut();

  /// Mengirim email untuk mengatur ulang password.
  @override
  Future<void> sendPasswordReset(String email) {
    if (!isAllowedLoginEmail(email)) {
      throw const FirebaseProfileException(gmailOnlyMessage);
    }
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Membaca profil Firestore untuk pengguna Firebase Auth.
  Future<FirebaseUserProfile> _profileFor(User user) async {
    if (!isAllowedLoginEmail(user.email ?? '')) {
      throw const FirebaseProfileException(gmailOnlyMessage);
    }
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw const FirebaseProfileException(
        'Profil akun belum tersedia. Hubungi Admin.',
      );
    }
    return FirebaseUserProfile.fromData(
      uid: user.uid,
      email: user.email ?? '',
      data: data,
    );
  }
}

/// Mengubah kesalahan login Firebase menjadi pesan yang mudah dipahami.
String firebaseLoginError(Object error) {
  if (error is FirebaseProfileException) return error.message;
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Format email belum benar.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email atau password salah.',
      'user-disabled' => 'Akun tidak aktif. Hubungi Admin.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      'network-request-failed' => 'Koneksi internet bermasalah. Coba lagi.',
      'operation-not-allowed' =>
        'Login email/password belum diaktifkan di Firebase.',
      _ => 'Login gagal. Coba lagi atau hubungi Admin.',
    };
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Akses data organisasi ditolak. Periksa izin akun dan Firestore.';
  }
  if (error is FirebaseException) {
    return 'Database belum dapat dibuka: ${error.message ?? error.code}';
  }
  return 'Layanan login belum tersedia. Coba lagi nanti.';
}
