import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'action_dialogs.dart';
import 'firebase_login.dart';
import 'ui.dart';

class ProfileDetailsPage extends StatelessWidget {
  /// Membuat detail profil akun.
  const ProfileDetailsPage({super.key, required this.profile});

  final FirebaseUserProfile profile;

  /// Menyusun tampilan detail profil akun.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Data Profil'),
      backgroundColor: AppColors.background,
    ),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(profile.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const PageFrame(
            children: [
              Text('Data profil belum dapat dimuat. Periksa koneksi internet.'),
            ],
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data();
        if (data == null) {
          return const PageFrame(
            children: [Text('Profil akun tidak ditemukan. Hubungi Admin.')],
          );
        }
        return PageFrame(
          children: [
            _ProfileValue(label: 'Nama', value: data['name'] as String? ?? '-'),
            _ProfileValue(
              label: 'Email',
              value: data['email'] as String? ?? profile.email,
            ),
            _ProfileValue(
              label: 'Peran',
              value: switch (data['role']) {
                'admin' => 'Admin',
                'bendahara' => 'Bendahara',
                _ => 'Anggota',
              },
            ),
            _ProfileValue(
              label: 'Status',
              value: data['isActive'] == true ? 'Aktif' : 'Nonaktif',
            ),
            _ProfileValue(
              label: 'Organisasi',
              value: data['organizationId'] as String? ?? '-',
            ),
          ],
        );
      },
    ),
  );
}

class _ProfileValue extends StatelessWidget {
  /// Membuat satu baris data profil.
  const _ProfileValue({required this.label, required this.value});

  final String label;
  final String value;

  /// Menyusun tampilan satu baris data profil.
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class ChangePasswordPage extends StatefulWidget {
  /// Membuat formulir perubahan password.
  const ChangePasswordPage({super.key, required this.email});

  final String email;

  /// Membuat state interaktif untuk formulir perubahan password.
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final formKey = GlobalKey<FormState>();
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false;
  String? error;

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  /// Memvalidasi password saat ini dan menyimpan password baru melalui Firebase Auth.
  Future<void> save() async {
    if (busy || !formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Sesi berakhir. Masuk kembali.');
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: widget.email,
          password: current.text,
        ),
      );
      await user.updatePassword(next.text);
      if (mounted) {
        await showActionNotice(
          context,
          title: 'Berhasil',
          message: 'Password akun berhasil diubah.',
          buttonLabel: 'Kembali ke Profil',
        );
        if (mounted) Navigator.of(context).pop();
      }
    } catch (exception) {
      if (mounted) {
        setState(
          () => error = switch (exception) {
            FirebaseAuthException(:final code)
                when code == 'wrong-password' || code == 'invalid-credential' =>
              'Password saat ini salah.',
            FirebaseAuthException(:final code) when code == 'weak-password' =>
              'Password baru terlalu lemah.',
            FirebaseAuthException(:final code)
                when code == 'network-request-failed' =>
              'Koneksi internet bermasalah. Coba lagi.',
            StateError() => exception.message,
            _ => 'Password belum berhasil diubah. Coba lagi.',
          },
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Menyusun tampilan formulir perubahan password.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ubah Password'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        const Text(
          'Gunakan password saat ini untuk mengamankan perubahan akun.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: current,
                obscureText: true,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Password saat ini',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Masukkan password saat ini.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: next,
                obscureText: true,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'Password baru'),
                validator: (value) => (value?.length ?? 0) < 8
                    ? 'Gunakan minimal 8 karakter.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirm,
                obscureText: true,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Ulangi password baru',
                ),
                validator: (value) =>
                    value != next.text ? 'Password baru belum sama.' : null,
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy ? null : save,
            child: Text(busy ? 'Menyimpan...' : 'Simpan Password'),
          ),
        ),
      ],
    ),
  );
}
