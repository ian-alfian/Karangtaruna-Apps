import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'action_dialogs.dart';
import 'demo_data.dart';
import 'cloud_connections.dart';
import 'firebase_login.dart';
import 'inventory_store.dart';
import 'ui.dart';
import 'user_management.dart';
import 'account_pages.dart';
import 'super_admin.dart';

class ProfileScreen extends StatelessWidget {
  /// Membuat halaman profil dan menu akun.
  const ProfileScreen({
    super.key,
    required this.role,
    this.authenticatedProfile,
    required this.store,
    required this.inventoryStore,
    required this.onLogout,
    required this.onNotifications,
    this.hasPendingConnectionRequest = false,
  });
  final AppRole role;
  final FirebaseUserProfile? authenticatedProfile;
  final DemoStore store;
  final InventoryStore inventoryStore;
  final VoidCallback onLogout;
  final VoidCallback onNotifications;
  final bool hasPendingConnectionRequest;

  /// Menyusun tampilan halaman profil dan menu akun.
  @override
  Widget build(BuildContext context) => PageFrame(
    children: [
      RoleHeader(role: role, title: 'Profil', onNotifications: onNotifications),
      if (!store.isRemote) const DemoBanner(),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.paleBlue,
              child: Text(
                (authenticatedProfile?.name ?? role.displayName)
                    .substring(0, 2)
                    .toUpperCase(),
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authenticatedProfile?.name ?? role.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    authenticatedProfile?.email ?? role.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.paleBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                authenticatedProfile?.role.label ?? role.label,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              _ProfileMenu(
                icon: Icons.person_outline_rounded,
                title: 'Data Profil',
                onTap: () {
                  final profile = authenticatedProfile;
                  if (profile == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileDetailsPage(profile: profile),
                    ),
                  );
                },
              ),
              if (role == AppRole.bendahara &&
                  (!store.isRemote ||
                      authenticatedProfile?.role == AppRole.bendahara))
                _ProfileMenu(
                  icon: Icons.people_outline_rounded,
                  title: 'Koneksi Bendahara',
                  showBadge: hasPendingConnectionRequest,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => store.isRemote
                          ? CloudConnectionPage(store: store)
                          : ConnectionPage(store: store),
                    ),
                  ),
                ),
              if (role == AppRole.admin ||
                  authenticatedProfile?.role == AppRole.admin) ...[
                if (authenticatedProfile?.isSuperAdmin == true)
                  _ProfileMenu(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Panel Super Admin',
                    onTap: () {
                      final profile = authenticatedProfile;
                      if (profile == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SuperAdminPage(profile: profile),
                        ),
                      );
                    },
                  ),
                if (authenticatedProfile?.isSuperAdmin != true)
                  _ProfileMenu(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Kelola Pengguna',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => UserManagementPage(
                          adminProfile: authenticatedProfile,
                        ),
                      ),
                    ),
                  ),
                if (authenticatedProfile?.isSuperAdmin != true)
                  _ProfileMenu(
                    icon: Icons.bar_chart_rounded,
                    title: 'Laporan',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReportsPage(
                          store: store,
                          inventoryStore: inventoryStore,
                        ),
                      ),
                    ),
                  ),
              ],
              _ProfileMenu(
                icon: Icons.lock_outline_rounded,
                title: 'Ubah Password',
                onTap: () {
                  final profile = authenticatedProfile;
                  if (profile == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChangePasswordPage(email: profile.email),
                    ),
                  );
                },
              ),
              _ProfileMenu(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Karang Taruna Digital',
                  applicationVersion: store.isRemote
                      ? 'Firebase'
                      : 'Pratinjau UI',
                  children: [
                    const Text(
                      'Aplikasi inventaris dan keuangan Karang Taruna.',
                    ),
                  ],
                ),
              ),
              _ProfileMenu(
                icon: Icons.logout_rounded,
                title: store.isRemote
                    ? 'Keluar dari Akun'
                    : 'Keluar dari Pratinjau',
                isLast: true,
                onTap: () async {
                  final confirmed = await confirmAction(
                    context,
                    title: store.isRemote
                        ? 'Keluar dari akun?'
                        : 'Keluar dari pratinjau?',
                    message: store.isRemote
                        ? 'Anda perlu masuk kembali untuk melihat data organisasi.'
                        : 'Data demo tersimpan di perangkat ini.',
                    confirmLabel: 'Keluar',
                  );
                  if (confirmed) onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ProfileMenu extends StatelessWidget {
  /// Membuat satu menu profil.
  const _ProfileMenu({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLast = false,
    this.showBadge = false,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLast;
  final bool showBadge;

  /// Menyusun tampilan satu menu profil.
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.navy),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.navy, fontSize: 13),
        ),
        trailing: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            if (showBadge)
              const Positioned(
                top: -3,
                right: -4,
                child: BlueStatusDot(size: 8),
              ),
          ],
        ),
        onTap: onTap,
      ),
      if (!isLast) const Divider(height: 1, color: AppColors.border),
    ],
  );
}

class ConnectionPage extends StatefulWidget {
  /// Membuat pratinjau koneksi bendahara.
  const ConnectionPage({super.key, required this.store});
  final DemoStore store;

  /// Membuat state interaktif untuk pratinjau koneksi bendahara.
  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  int tab = 0;

  /// Menyusun tampilan pratinjau koneksi bendahara.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Koneksi Bendahara'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        const DemoBanner(),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: ChoiceChip(
                  label: Text(['Koneksi', 'Cari', 'Permintaan'][i]),
                  selected: tab == i,
                  onSelected: (_) => setState(() => tab = i),
                  selectedColor: AppColors.blue,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: tab == i ? Colors.white : AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  side: BorderSide.none,
                ),
              ),
              if (i < 2) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 20),
        if (tab == 0) ...[
          MoneyCard(
            label: 'Total Kas Terkoneksi',
            subtitle: 'Saldo unik dua bendahara',
            amount: widget.store.connectedCash,
            footerLabel: '2 Bendahara Terkoneksi',
          ),
          const SizedBox(height: 26),
          const SectionHeading(title: 'Bendahara Terhubung'),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _ConnectionRow(
                  name: 'Sukardi · Anda',
                  amount: widget.store.balanceFor('sukardi'),
                ),
                const Divider(color: AppColors.border),
                _ConnectionRow(
                  name: 'Rina',
                  amount: widget.store.balanceFor('rina'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => setState(() => tab = 1),
            child: const Text('Hubungkan Bendahara'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Koneksi hanya menggabungkan tampilan kas; tidak memindahkan dana.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ] else if (tab == 1) ...[
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari nama bendahara',
            ),
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: AppColors.muted,
                ),
                SizedBox(height: 8),
                Text(
                  'Pencarian belum tersedia',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Akun bendahara hanya dapat dicari setelah Firebase dan aturan organisasi terhubung.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 42,
                  color: AppColors.blue,
                ),
                SizedBox(height: 8),
                Text(
                  'Belum ada permintaan',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Permintaan koneksi akan muncul di sini.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _ConnectionRow extends StatelessWidget {
  /// Membuat satu baris saldo bendahara.
  const _ConnectionRow({required this.name, required this.amount});
  final String name;
  final int amount;

  /// Menyusun tampilan satu baris saldo bendahara.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: AppColors.paleBlue,
          child: Icon(Icons.person, color: AppColors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  fontSize: 12,
                ),
              ),
              Text(
                rupiah(amount),
                style: const TextStyle(color: AppColors.navy, fontSize: 11),
              ),
            ],
          ),
        ),
        const Text(
          'Terhubung',
          style: TextStyle(
            color: AppColors.blue,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class ReportsPage extends StatelessWidget {
  /// Membuat halaman laporan.
  const ReportsPage({
    super.key,
    required this.store,
    required this.inventoryStore,
  });
  final DemoStore store;
  final InventoryStore inventoryStore;

  /// Menyusun tampilan halaman laporan.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Laporan'),
      backgroundColor: AppColors.background,
    ),
    body: AnimatedBuilder(
      animation: Listenable.merge([store, inventoryStore]),
      builder: (context, _) => PageFrame(
        children: [
          if (!store.isRemote) const DemoBanner(),
          MoneyCard(
            label: 'Total Kas Terkoneksi',
            amount: store.connectedCash,
            footerLabel: store.isRemote ? 'Data organisasi' : 'Data contoh',
          ),
          const SizedBox(height: 22),
          const SectionHeading(title: 'Ringkasan'),
          _ReportCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Keuangan',
            detail:
                '${store.transactions.length} transaksi${store.isRemote ? '' : ' contoh'}',
          ),
          _ReportCard(
            icon: Icons.inventory_2_outlined,
            title: 'Inventaris',
            detail:
                '${inventoryStore.items.length} jenis barang${store.isRemote ? '' : ' contoh'}',
          ),
          _ReportCard(
            icon: Icons.assignment_outlined,
            title: 'Peminjaman',
            detail:
                '${inventoryStore.borrowings.where((item) => item.remaining > 0).length} peminjaman aktif',
          ),
          const SizedBox(height: 10),
          const Text(
            'Ekspor laporan belum tersedia.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _ReportCard extends StatelessWidget {
  /// Membuat kartu ringkasan laporan.
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  /// Menyusun tampilan kartu ringkasan laporan.
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class NotificationsPage extends StatelessWidget {
  /// Membuat halaman notifikasi.
  const NotificationsPage({super.key, this.profile, this.store});
  final FirebaseUserProfile? profile;
  final DemoStore? store;

  /// Menyusun tampilan halaman notifikasi.
  @override
  Widget build(BuildContext context) {
    final user = profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.background,
      ),
      body: user == null
          ? const PageFrame(children: [_NotificationEmpty()])
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipientId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const PageFrame(
                    children: [
                      Text('Notifikasi belum dapat dimuat. Coba lagi nanti.'),
                    ],
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final aDate = a.data()['createdAt'] as Timestamp?;
                    final bDate = b.data()['createdAt'] as Timestamp?;
                    return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
                      aDate?.millisecondsSinceEpoch ?? 0,
                    );
                  });
                return PageFrame(
                  children: [
                    if (docs.isEmpty) const _NotificationEmpty(),
                    for (final doc in docs)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            doc.data()['read'] == true
                                ? Icons.notifications_none
                                : Icons.notifications_active_outlined,
                            color: AppColors.blue,
                          ),
                          title: Text(
                            doc.data()['title'] as String? ?? 'Notifikasi',
                          ),
                          subtitle: Text(doc.data()['body'] as String? ?? ''),
                          onTap: () async {
                            if (doc.data()['read'] != true) {
                              await doc.reference.update({'read': true});
                            }
                            if (context.mounted &&
                                store != null &&
                                doc.data()['category'] == 'connection' &&
                                user.role == AppRole.bendahara) {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CloudConnectionPage(store: store!),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _NotificationEmpty extends StatelessWidget {
  /// Membuat pesan saat notifikasi kosong.
  const _NotificationEmpty();

  /// Menyusun tampilan pesan saat notifikasi kosong.
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Column(
      children: [
        Icon(Icons.notifications_none_rounded, size: 46, color: AppColors.blue),
        SizedBox(height: 10),
        Text(
          'Belum ada notifikasi',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 5),
        Text(
          'Pembaruan organisasi akan muncul di sini.',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}
