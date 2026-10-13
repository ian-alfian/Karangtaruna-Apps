import 'package:flutter/material.dart';

import 'demo_data.dart';
import 'inventory_store.dart';
import 'ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.role,
    required this.store,
    required this.inventoryStore,
    required this.onLogout,
    required this.onNotifications,
  });
  final AppRole role;
  final DemoStore store;
  final InventoryStore inventoryStore;
  final VoidCallback onLogout;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) => PageFrame(
    children: [
      RoleHeader(role: role, title: 'Profil', onNotifications: onNotifications),
      const DemoBanner(),
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
                role.displayName.substring(0, 2).toUpperCase(),
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
                    role.displayName,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    role.email,
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
                role.label,
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
                onTap: () => showPreviewOnly(context),
              ),
              if (role == AppRole.bendahara)
                _ProfileMenu(
                  icon: Icons.people_outline_rounded,
                  title: 'Koneksi Bendahara',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ConnectionPage(store: store),
                    ),
                  ),
                ),
              if (role == AppRole.admin) ...[
                _ProfileMenu(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Kelola Pengguna',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UserManagementPage(),
                    ),
                  ),
                ),
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
                onTap: () => showPreviewOnly(context),
              ),
              _ProfileMenu(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Karang Taruna Digital',
                  applicationVersion: 'Pratinjau UI',
                  children: [
                    const Text(
                      'Aplikasi inventaris dan keuangan Karang Taruna.',
                    ),
                  ],
                ),
              ),
              _ProfileMenu(
                icon: Icons.logout_rounded,
                title: 'Keluar dari Pratinjau',
                isLast: true,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Keluar dari pratinjau?'),
                      content: const Text(
                        'Perubahan data demo akan hilang saat aplikasi ditutup.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) onLogout();
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
  const _ProfileMenu({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLast = false,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

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
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.muted,
        ),
        onTap: onTap,
      ),
      if (!isLast) const Divider(height: 1, color: AppColors.border),
    ],
  );
}

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key, required this.store});
  final DemoStore store;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  int tab = 0;

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
  const _ConnectionRow({required this.name, required this.amount});
  final String name;
  final int amount;

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

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Kelola Pengguna'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        const DemoBanner(),
        FilledButton.icon(
          onPressed: () => showPreviewOnly(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Pengguna'),
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Cari nama atau email',
          ),
          onChanged: (_) {},
        ),
        const SizedBox(height: 20),
        const SectionHeading(title: 'Daftar Pengguna'),
        for (final user in const [
          ('Rizky Pratama', 'rizky@example.com', 'Anggota'),
          ('Dina Putri', 'dina@example.com', 'Admin'),
          ('Ayu Setyaningrum', 'ayu@example.com', 'Bendahara'),
          ('Sukardi', 'sukardi@example.com', 'Bendahara'),
        ]) ...[
          Container(
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
                    user.$1.substring(0, 2).toUpperCase(),
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
                        user.$1,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        user.$2,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.$3,
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Aktif',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    ),
  );
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({
    super.key,
    required this.store,
    required this.inventoryStore,
  });
  final DemoStore store;
  final InventoryStore inventoryStore;

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
          const DemoBanner(),
          MoneyCard(
            label: 'Total Kas Terkoneksi',
            amount: store.connectedCash,
            footerLabel: 'Data contoh',
          ),
          const SizedBox(height: 22),
          const SectionHeading(title: 'Ringkasan'),
          _ReportCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Keuangan',
            detail: '${store.transactions.length} transaksi contoh',
          ),
          _ReportCard(
            icon: Icons.inventory_2_outlined,
            title: 'Inventaris',
            detail: '${inventoryStore.items.length} jenis barang contoh',
          ),
          _ReportCard(
            icon: Icons.assignment_outlined,
            title: 'Peminjaman',
            detail:
                '${inventoryStore.borrowings.where((item) => item.remaining > 0).length} peminjaman aktif',
          ),
          const SizedBox(height: 10),
          const Text(
            'Ekspor laporan akan tersedia setelah layanan data nyata terhubung.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

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
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifikasi'),
      backgroundColor: AppColors.background,
    ),
    body: const PageFrame(children: [DemoBanner(), _NotificationEmpty()]),
  );
}

class _NotificationEmpty extends StatelessWidget {
  const _NotificationEmpty();

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
