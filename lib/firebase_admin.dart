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
  const CreatedManagedUser({required this.uid, required this.email});
  final String uid;
  final String email;
}

/// Representasi organisasi yang dapat dikelola Super Admin.
class ManagedOrganization {
  const ManagedOrganization({
    required this.id,
    required this.name,
    required this.region,
    required this.ownerUid,
    required this.isActive,
  });

  final String id;
  final String name;
  final String region;
  final String ownerUid;
  final bool isActive;

  /// Membaca organisasi dari dokumen Firestore.
  factory ManagedOrganization.fromDocument(
    String id,
    Map<String, dynamic> data,
  ) => ManagedOrganization(
    id: id,
    name: data['name'] as String? ?? id,
    region: data['region'] as String? ?? '',
    ownerUid: data['ownerUid'] as String? ?? '',
    isActive: data['isActive'] == true,
  );
}

class FirebaseAdminService {
  /// Membuat layanan pengelolaan akun di Firebase.
  FirebaseAdminService({required this.profile, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseUserProfile profile;
  final FirebaseFirestore _firestore;

  /// Mendengarkan daftar pengguna yang dikelola Admin.
  Stream<List<ManagedUser>> users() => usersForOrganization(profile.organizationId);

  /// Mendengarkan akun pada organisasi tertentu.
  Stream<List<ManagedUser>> usersForOrganization(String organizationId) => _firestore
      .collection('users')
      .where('organizationId', isEqualTo: organizationId)
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

  /// Mendengarkan seluruh akun lintas organisasi untuk dashboard Super Admin.
  Stream<List<ManagedUser>> allUsers() {
    if (!profile.isSuperAdmin) return Stream.value(const <ManagedUser>[]);
    return _firestore.collection('users').snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (document) =>
                ManagedUser.fromDocument(document.id, document.data()),
          )
          .toList(),
    );
  }

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

  /// Mendengarkan daftar organisasi untuk Super Admin.
  Stream<List<ManagedOrganization>> organizations() {
    if (!profile.isSuperAdmin) return const Stream.empty();
    return _firestore
        .collection('organizations')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        ManagedOrganization.fromDocument(doc.id, doc.data()),
                  )
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  /// Mendaftarkan organisasi lama satu kali agar terlihat di direktori Super Admin.
  Future<void> ensureCurrentOrganizationRegistered() async {
    if (!profile.isSuperAdmin) return;
    final ref = _firestore
        .collection('organizations')
        .doc(profile.organizationId);
    // Jangan menulis ulang dokumen yang sudah ada agar createdAt/createdBy tetap
    // immutable dan aturan Firestore update tetap ketat.
    if ((await ref.get()).exists) return;
    final defaultName = profile.organizationId == 'karangtaruna-main'
        ? 'Karang Taruna Utama'
        : profile.organizationId;
    await ref.set({
      'name': defaultName,
      'region': 'Wilayah utama',
      'ownerUid': profile.uid,
      'createdBy': profile.uid,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Membuat akun Firebase Auth dan profil pengguna Firestore.
  Future<CreatedManagedUser> createUser({
    required String name,
    required String email,
    required AppRole role,
    required String password,
    String? organizationId,
  }) async {
    if (profile.role != AppRole.admin) {
      throw StateError('Hanya Admin yang dapat membuat akun.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    final targetOrganizationId = (organizationId ?? profile.organizationId)
        .trim();
    if (targetOrganizationId.isEmpty) {
      throw ArgumentError('Organisasi tujuan wajib dipilih.');
    }
    if (targetOrganizationId != profile.organizationId &&
        !profile.isSuperAdmin) {
      throw StateError('Admin hanya dapat membuat akun di organisasinya.');
    }
    if (targetOrganizationId != profile.organizationId &&
        role != AppRole.admin) {
      throw StateError(
        'Akun lintas organisasi hanya dapat dibuat sebagai Admin pertama.',
      );
    }
    final organizationSnapshot = await _firestore
        .collection('organizations')
        .doc(targetOrganizationId)
        .get();
    if (!organizationSnapshot.exists ||
        organizationSnapshot.data()?['isActive'] != true) {
      throw StateError('Organisasi tujuan belum terdaftar atau tidak aktif.');
    }
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
          'organizationId': targetOrganizationId,
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
    return CreatedManagedUser(
      uid: createdUser.uid,
      email: normalizedEmail,
    );
  }

  /// Membuat organisasi baru dan Admin pertama untuk organisasi tersebut.
  Future<ManagedOrganization> createOrganizationWithAdmin({
    required String organizationId,
    required String name,
    required String region,
    required String adminName,
    required String adminEmail,
    required String password,
  }) async {
    if (!profile.isSuperAdmin) {
      throw StateError('Hanya Super Admin yang dapat membuat organisasi.');
    }
    final id = organizationId.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,48}$').hasMatch(id)) {
      throw ArgumentError(
        'Kode organisasi 3–49 karakter: huruf kecil, angka, dan tanda -.',
      );
    }
    if (name.trim().length < 2 || region.trim().isEmpty) {
      throw ArgumentError('Nama dan wilayah organisasi wajib diisi.');
    }
    final organizationRef = _firestore.collection('organizations').doc(id);
    if ((await organizationRef.get()).exists) {
      throw StateError('Kode organisasi sudah digunakan.');
    }
    await organizationRef.set({
      'name': name.trim(),
      'region': region.trim(),
      'ownerUid': profile.uid,
      'createdBy': profile.uid,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    String ownerUid = profile.uid;
    try {
      final created = await createUser(
        name: adminName,
        email: adminEmail,
        role: AppRole.admin,
        password: password,
        organizationId: id,
      );
      ownerUid = created.uid;
      await organizationRef.update({
        'ownerUid': created.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await organizationRef.delete();
      rethrow;
    }
    return ManagedOrganization(
      id: id,
      name: name.trim(),
      region: region.trim(),
      ownerUid: ownerUid,
      isActive: true,
    );
  }

  /// Memperbarui peran atau status aktif pengguna di Firestore.
  Future<void> updateUser({
    required String uid,
    required AppRole role,
    required bool isActive,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final snapshot = await userRef.get();
    final organizationId = snapshot.data()?['organizationId'] as String?;
    if (!snapshot.exists || organizationId == null) {
      throw StateError('Pengguna tidak ditemukan.');
    }
    if (!profile.isSuperAdmin && organizationId != profile.organizationId) {
      throw StateError('Admin hanya dapat mengubah akun organisasinya.');
    }
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
        (!profile.isSuperAdmin &&
            user.data()?['organizationId'] != profile.organizationId)) {
      throw StateError('Pengguna tidak ditemukan di organisasi ini.');
    }
    final targetOrganizationId = user.data()?['organizationId'] as String;
    if (user.data()?['role'] == AppRole.bendahara.name) {
      final connections = await _firestore
          .collection('treasurerConnections')
          .where('organizationId', isEqualTo: targetOrganizationId)
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
          .where('organizationId', isEqualTo: targetOrganizationId)
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
