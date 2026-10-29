import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'demo_data.dart';
import 'email_policy.dart';
import 'firebase_login.dart';

class ManagedUser {
  /// Membuat profil pengguna yang dikelola Admin.
  const ManagedUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  final String uid;
  final String name;
  final String email;
  final AppRole role;
  final bool isActive;

  /// Membaca profil pengguna dari dokumen Firestore.
  factory ManagedUser.fromDocument(String uid, Map<String, dynamic> data) =>
      ManagedUser(
        uid: uid,
        name: (data['name'] as String?)?.trim() ?? '',
        email: (data['email'] as String?)?.trim() ?? '',
        role: AppRole.values.firstWhere(
          (role) => role.name == data['role'],
          orElse: () => AppRole.anggota,
        ),
        isActive: data['isActive'] == true,
      );
}

class CreatedManagedUser {
  /// Membuat hasil pembuatan akun pengguna.
  const CreatedManagedUser({required this.email});
  final String email;
}

class FirebaseAdminService {
  /// Membuat layanan pengelolaan akun di Firebase.
  FirebaseAdminService({required this.profile, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseUserProfile profile;
  final FirebaseFirestore _firestore;

  /// Mendengarkan daftar pengguna yang dikelola Admin.
  Stream<List<ManagedUser>> users() => _firestore
      .collection('users')
      .where('organizationId', isEqualTo: profile.organizationId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map(
                  (document) =>
                      ManagedUser.fromDocument(document.id, document.data()),
                )
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );

  /// Menghitung akun buatan Admin tanpa menghitung akun Admin pertama.
  Stream<int> managedUserCount() => _firestore
      .collection('users')
      .where('organizationId', isEqualTo: profile.organizationId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.where((document) {
          final creator = document.data()['createdBy'];
          return document.id != profile.uid &&
              creator is String &&
              creator.isNotEmpty;
        }).length,
      );

  /// Membuat akun Firebase Auth dan profil pengguna Firestore.
  Future<CreatedManagedUser> createUser({
    required String name,
    required String email,
    required AppRole role,
    required String password,
  }) async {
    if (profile.role != AppRole.admin) {
      throw StateError('Hanya Admin yang dapat membuat akun.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().length < 2 || !normalizedEmail.contains('@')) {
      throw ArgumentError('Periksa nama dan email pengguna.');
    }
    if (!isGmailEmail(normalizedEmail)) {
      throw ArgumentError(gmailOnlyMessage);
    }
    if (password.length < 8) {
      throw ArgumentError('Password awal harus minimal 8 karakter.');
    }
    // A secondary Auth instance keeps the Admin signed in while creating a user.
    final app = await Firebase.initializeApp(
      name: 'create-user-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    final secondaryAuth = FirebaseAuth.instanceFor(app: app);
    User? createdUser;
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      createdUser = credential.user;
      if (createdUser == null) throw StateError('Akun belum berhasil dibuat.');
      try {
        await _firestore.collection('users').doc(createdUser.uid).set({
          'name': name.trim(),
          'email': normalizedEmail,
          'role': role.name,
          'organizationId': profile.organizationId,
          'isActive': true,
          'createdBy': profile.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        await createdUser.delete();
        rethrow;
      }
    } finally {
      await secondaryAuth.signOut();
      await app.delete();
    }
    return CreatedManagedUser(email: normalizedEmail);
  }

  /// Memperbarui peran atau status aktif pengguna di Firestore.
  Future<void> updateUser({
    required String uid,
    required AppRole role,
    required bool isActive,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role.name,
      'isActive': isActive,
      'updatedBy': profile.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Menghapus profil dan akses aplikasi pengguna.
  /// Identitas Firebase Auth perlu dihapus terpisah melalui Admin SDK atau konsol.
  Future<void> deleteUserProfile(String uid) async {
    if (profile.role != AppRole.admin || uid == profile.uid) {
      throw StateError('Akun Admin yang sedang dipakai tidak dapat dihapus.');
    }
    final userRef = _firestore.collection('users').doc(uid);
    final user = await userRef.get();
    if (!user.exists ||
        user.data()?['organizationId'] != profile.organizationId) {
      throw StateError('Pengguna tidak ditemukan di organisasi ini.');
    }
    if (user.data()?['role'] == AppRole.bendahara.name) {
      final connections = await _firestore
          .collection('treasurerConnections')
          .where('organizationId', isEqualTo: profile.organizationId)
          .get();
      if (connections.docs.any(
        (doc) =>
            doc.data()['active'] == true &&
            (doc.data()['holderIds'] as List? ?? []).contains(uid),
      )) {
        throw StateError(
          'Putuskan koneksi Bendahara ini sebelum menghapus akun.',
        );
      }
      final requests = await _firestore
          .collection('treasurerConnectionRequests')
          .where('organizationId', isEqualTo: profile.organizationId)
          .get();
      if (requests.docs.any(
        (doc) =>
            doc.data()['status'] == 'pending' &&
            (doc.data()['requesterId'] == uid ||
                doc.data()['recipientId'] == uid),
      )) {
        throw StateError(
          'Selesaikan permintaan koneksi Bendahara ini sebelum menghapus akun.',
        );
      }
    }
    await userRef.delete();
  }
}

/// Mengubah kesalahan pengelolaan akun menjadi pesan untuk pengguna.
String adminActionError(Object error) {
  if (error is ArgumentError) {
    return error.message?.toString() ?? 'Periksa data pengguna.';
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'email-already-in-use' => 'Email sudah digunakan.',
      'invalid-email' => 'Format email belum benar.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      'weak-password' =>
        'Password awal terlalu lemah. Gunakan minimal 8 karakter.',
      _ => 'Akun belum berhasil dibuat: ${error.message ?? error.code}',
    };
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Tindakan pengguna ditolak. Periksa izin Admin dan organisasi.';
  }
  if (error is StateError) return error.message;
  return 'Layanan akun sedang bermasalah. Coba lagi.';
}
