import 'package:flutter/material.dart';

import 'action_dialogs.dart';
import 'demo_data.dart';
import 'email_policy.dart';
import 'firebase_admin.dart';
import 'firebase_login.dart';
import 'ui.dart';

class UserManagementPage extends StatefulWidget {
  /// Membuat halaman kelola pengguna.
  const UserManagementPage({super.key, this.adminProfile});
  final FirebaseUserProfile? adminProfile;

  /// Membuat state interaktif untuk halaman kelola pengguna.
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  FirebaseAdminService? service;
  String query = '';

  /// Menyiapkan state dan pendengar awal saat widget dibuat.
  @override
  void initState() {
    super.initState();
    final profile = widget.adminProfile;
    if (profile != null && profile.role == AppRole.admin) {
      service = FirebaseAdminService(profile: profile);
    }
  }

  /// Membuka formulir pembuatan akun baru.
  Future<void> openCreateUser() async {
    final created = await Navigator.of(context).push<CreatedManagedUser>(
      MaterialPageRoute(builder: (_) => CreateUserPage(service: service!)),
    );
    if (!mounted || created == null) return;
    await showActionNotice(
      context,
      title: 'Akun berhasil dibuat',
      message: '${created.email} sekarang dapat masuk dengan password awal.',
      buttonLabel: 'Kembali ke Pengguna',
    );
  }

  /// Membuka formulir untuk mengubah peran atau status pengguna.
  Future<void> editUser(ManagedUser user) async {
    var role = user.role;
    var isActive = user.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => ActionConfirmDialog(
          title: 'Ubah ${user.name}',
          message: 'Atur peran dan status akses pengguna.',
          confirmLabel: 'Simpan Perubahan',
          details: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<AppRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Peran'),
                items: [
                  for (final value in AppRole.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) => update(() => role = value ?? role),
              ),
              SwitchListTile(
                title: const Text('Akun aktif'),
                value: isActive,
                onChanged: (value) => update(() => isActive = value),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await service!.updateUser(uid: user.uid, role: role, isActive: isActive);
      if (mounted) {
        await showActionNotice(
          context,
          title: 'Berhasil',
          message: 'Data ${user.name} berhasil diperbarui.',
          buttonLabel: 'Kembali ke Pengguna',
        );
      }
    } catch (error) {
      if (mounted) {
        await showActionNotice(
          context,
          title: 'Perubahan gagal',
          message: adminActionError(error),
          error: true,
        );
      }
    }
  }

  /// Meminta konfirmasi lalu menghapus profil pengguna.
  Future<void> deleteUser(ManagedUser user) async {
    final confirmed = await confirmAction(
      context,
      title: 'Hapus akun ${user.name}?',
      message: 'Profil dan akses aplikasi akan dihapus. Riwayat transaksi tetap tersimpan. Identitas Firebase Authentication perlu dihapus terpisah melalui Firebase Console agar email dapat digunakan kembali.',
      confirmLabel: 'Hapus Akun',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await service!.deleteUserProfile(user.uid);
      if (mounted) {
        await showActionNotice(
          context,
          title: 'Akses akun dihapus',
          message:
              'Profil ${user.email} sudah dihapus dari aplikasi. Hapus identitas email ini di Firebase Console → Authentication → Users bila ingin menghapusnya sepenuhnya atau memakai ulang email.',
          buttonLabel: 'Kembali ke Pengguna',
        );
      }
    } catch (error) {
      if (mounted) {
        await showActionNotice(
          context,
          title: 'Akun belum terhapus',
          message: adminActionError(error),
          error: true,
        );
      }
    }
  }

  /// Menyusun tampilan halaman kelola pengguna.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Kelola Pengguna'),
      backgroundColor: AppColors.background,
    ),
    body: service == null
        ? const PageFrame(
            children: [Text('Masuk sebagai Admin untuk mengelola pengguna.')],
          )
        : PageFrame(
            children: [
              const Text(
                'Akun dalam organisasi Anda',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Password awal dibuat oleh Admin. Pengguna dapat mengubahnya sendiri setelah masuk.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: openCreateUser,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Tambah Pengguna'),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari nama atau email',
                ),
                onChanged: (value) =>
                    setState(() => query = value.toLowerCase()),
              ),
              const SizedBox(height: 22),
              const SectionHeading(title: 'Daftar Pengguna'),
              StreamBuilder<List<ManagedUser>>(
                stream: service!.users(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        adminActionError(snapshot.error!),
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final users = snapshot.data!
                      .where(
                        (user) =>
                            user.name.toLowerCase().contains(query) ||
                            user.email.toLowerCase().contains(query),
                      )
                      .toList();
                  if (users.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Belum ada pengguna yang cocok.'),
                    );
                  }
                  return Column(
                    children: [
                      for (final user in users)
                        _UserCard(
                          user: user,
                          onEdit: user.uid == widget.adminProfile?.uid
                              ? null
                              : () => editUser(user),
                          onDelete: user.uid == widget.adminProfile?.uid
                              ? null
                              : () => deleteUser(user),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
  );
}

class _UserCard extends StatelessWidget {
  /// Membuat kartu satu pengguna.
  const _UserCard({required this.user, this.onEdit, this.onDelete});
  final ManagedUser user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Menyusun tampilan kartu satu pengguna.
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.paleBlue,
          child: Text(
            user.name.isEmpty
                ? '?'
                : user.name
                      .substring(0, user.name.length >= 2 ? 2 : 1)
                      .toUpperCase(),
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              Text(
                user.role.label,
                style: const TextStyle(color: AppColors.blue, fontSize: 11),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Text(
              user.isActive ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                color: user.isActive ? AppColors.green : Colors.red,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Ubah ${user.name}',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.blue,
                    ),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Hapus ${user.name}',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFC62828),
                    ),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class CreateUserPage extends StatefulWidget {
  /// Membuat formulir pembuatan akun.
  const CreateUserPage({super.key, required this.service});
  final FirebaseAdminService service;

  /// Membuat state interaktif untuk formulir pembuatan akun.
  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  AppRole role = AppRole.anggota;
  bool busy = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  String? error;

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// Memvalidasi identitas, peran, dan password sebelum membuat akun.
  Future<void> submit() async {
    if (busy || !formKey.currentState!.validate()) return;
    if (role == AppRole.admin) {
      final confirmed = await confirmAction(
        context,
        title: 'Berikan akses Admin?',
        message: 'Akun ini dapat membuat akun lain dan mengakses semua tampilan peran.',
        confirmLabel: 'Ya, Buat Admin',
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final created = await widget.service.createUser(
        name: nameController.text,
        email: emailController.text,
        role: role,
        password: passwordController.text,
      );
      if (mounted) Navigator.pop(context, created);
    } catch (exception) {
      if (mounted) setState(() => error = adminActionError(exception));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Menyusun tampilan formulir pembuatan akun.
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      title: const Text('Tambah Pengguna'),
      backgroundColor: const Color(0xFFF7F9FC),
    ),
    body: PageFrame(
      children: [
        const Text(
          'Buat akun baru',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tentukan peran dan password awal. Pengguna dapat mengganti password sendiri setelah masuk.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama lengkap'),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Masukkan nama minimal 2 karakter.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Masukkan email yang valid.';
                  }
                  return isGmailEmail(email) ? null : gmailOnlyMessage;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AppRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Peran'),
                items: [
                  for (final value in AppRole.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: busy
                    ? null
                    : (value) =>
                          setState(() => role = value ?? AppRole.anggota),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: !showPassword,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: 'Password awal',
                  hintText: 'Minimal 8 karakter',
                  suffixIcon: IconButton(
                    tooltip: showPassword
                        ? 'Sembunyikan password'
                        : 'Lihat password',
                    icon: Icon(
                      showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => showPassword = !showPassword),
                  ),
                ),
                validator: (value) => (value?.length ?? 0) < 8
                    ? 'Password awal minimal 8 karakter.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi password',
                  suffixIcon: IconButton(
                    tooltip: showConfirmPassword
                        ? 'Sembunyikan konfirmasi password'
                        : 'Lihat konfirmasi password',
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(
                      () => showConfirmPassword = !showConfirmPassword,
                    ),
                  ),
                ),
                validator: (value) => value != passwordController.text
                    ? 'Konfirmasi password belum sama.'
                    : null,
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy ? null : submit,
            child: Text(busy ? 'Membuat akun...' : 'Buat Akun'),
          ),
        ),
      ],
    ),
  );
}
