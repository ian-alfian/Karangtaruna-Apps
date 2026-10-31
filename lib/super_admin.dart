import 'package:flutter/material.dart';

import 'action_dialogs.dart';
import 'firebase_admin.dart';
import 'firebase_login.dart';
import 'ui.dart';
import 'user_management.dart';

/// Panel khusus Super Admin untuk membuat organisasi dan Admin pertamanya.
class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key, required this.profile});

  final FirebaseUserProfile profile;

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  final _organizationId = TextEditingController();
  final _organizationName = TextEditingController();
  final _region = TextEditingController();
  final _adminName = TextEditingController();
  final _adminEmail = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  late final FirebaseAdminService _service;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = FirebaseAdminService(profile: widget.profile);
    _registerExistingOrganization();
  }

  Future<void> _registerExistingOrganization() async {
    try {
      await _service.ensureCurrentOrganizationRegistered();
    } catch (_) {
      // Daftar organisasi tetap dapat dipakai; kegagalan hanya ditampilkan
      // ketika StreamBuilder memuat data dari Firestore.
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _organizationId,
      _organizationName,
      _region,
      _adminName,
      _adminEmail,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _createOrganization() async {
    if (_password.text != _confirmPassword.text) {
      await showActionNotice(
        context,
        title: 'Password tidak sama',
        message: 'Konfirmasi password Admin pertama harus sama.',
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final organization = await _service.createOrganizationWithAdmin(
        organizationId: _organizationId.text,
        name: _organizationName.text,
        region: _region.text,
        adminName: _adminName.text,
        adminEmail: _adminEmail.text,
        password: _password.text,
      );
      if (!mounted) return;
      for (final controller in [
        _organizationId,
        _organizationName,
        _region,
        _adminName,
        _adminEmail,
        _password,
        _confirmPassword,
      ]) {
        controller.clear();
      }
      await showActionNotice(
        context,
        title: 'Organisasi berhasil dibuat',
        message:
            '${organization.name} (${organization.id}) siap digunakan. Admin pertama dapat login dengan email yang didaftarkan.',
      );
    } catch (error) {
      if (!mounted) return;
      await showActionNotice(
        context,
        title: 'Organisasi belum dibuat',
        message: adminActionError(error),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Panel Super Admin'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paleBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.admin_panel_settings_outlined, color: AppColors.blue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Panel ini hanya untuk Super Admin. Setiap organisasi memiliki data terpisah; Admin biasa hanya dapat mengelola organisasinya sendiri.',
                  style: TextStyle(color: AppColors.navy, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeading(title: 'Buat organisasi baru'),
        _field(
          _organizationId,
          'Kode organisasi',
          'contoh: karangtaruna-banyumas',
        ),
        _field(_organizationName, 'Nama organisasi', 'Karang Taruna ...'),
        _field(_region, 'Wilayah', 'Desa / Kecamatan / Kabupaten'),
        const SizedBox(height: 8),
        const SectionHeading(title: 'Admin pertama'),
        _field(_adminName, 'Nama Admin', 'Nama lengkap'),
        _field(
          _adminEmail,
          'Email Admin',
          'contoh@gmail.com',
          keyboard: TextInputType.emailAddress,
        ),
        _field(_password, 'Password awal', 'Minimal 8 karakter', obscure: true),
        _field(
          _confirmPassword,
          'Konfirmasi password',
          'Ulangi password awal',
          obscure: true,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _busy ? null : _createOrganization,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_business_outlined),
          label: Text(_busy ? 'Menyimpan...' : 'Buat Organisasi & Admin'),
        ),
        const SizedBox(height: 26),
        const SectionHeading(title: 'Organisasi terdaftar'),
        StreamBuilder<List<ManagedOrganization>>(
          stream: _service.organizations(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                'Daftar organisasi belum dapat dimuat.',
                style: TextStyle(color: AppColors.muted),
              );
            }
            final organizations =
                snapshot.data ?? const <ManagedOrganization>[];
            if (organizations.isEmpty) {
              return const Text(
                'Belum ada organisasi selain organisasi akun Anda.',
                style: TextStyle(color: AppColors.muted),
              );
            }
            return Column(
              children: [
                for (final organization in organizations)
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => UserManagementPage(
                          adminProfile: widget.profile,
                          organizationId: organization.id,
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.paleBlue,
                          child: Icon(
                            Icons.apartment_outlined,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                organization.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                              Text(
                                '${organization.id} · ${organization.region}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                          Icon(
                            organization.isActive
                                ? Icons.chevron_right_rounded
                                : Icons.pause_circle_outline,
                            color: organization.isActive
                                ? AppColors.blue
                                : AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    bool obscure = false,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
}
