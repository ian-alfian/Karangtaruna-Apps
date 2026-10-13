import 'package:flutter/material.dart';

import 'demo_data.dart';
import 'finance.dart';
import 'inventory.dart';
import 'inventory_store.dart';
import 'profile.dart';
import 'ui.dart';

class KarangTarunaApp extends StatelessWidget {
  const KarangTarunaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Karang Taruna Digital',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    builder: (context, child) => ColoredBox(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
    home: const AppRoot(),
  );
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppRole? role;
  final DemoStore store = DemoStore();
  final InventoryStore inventoryStore = InventoryStore();
  bool ready = false;
  bool localLoadFailed = false;

  @override
  void initState() {
    super.initState();
    Future.wait([store.load(), inventoryStore.load()])
        .then((_) {
          if (mounted) setState(() => ready = true);
        })
        .catchError((Object error) {
          if (mounted) {
            setState(() {
              ready = true;
              localLoadFailed = true;
            });
          }
        });
  }

  @override
  void dispose() {
    store.dispose();
    inventoryStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !ready
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : role == null
      ? PreviewLoginScreen(
          onEnter: (value) => setState(() => role = value),
          localLoadFailed: localLoadFailed,
        )
      : AppShell(
          role: role!,
          store: store,
          inventoryStore: inventoryStore,
          onLogout: () => setState(() => role = null),
        );
}

class PreviewLoginScreen extends StatefulWidget {
  const PreviewLoginScreen({
    super.key,
    required this.onEnter,
    this.localLoadFailed = false,
  });
  final ValueChanged<AppRole> onEnter;
  final bool localLoadFailed;
  @override
  State<PreviewLoginScreen> createState() => _PreviewLoginScreenState();
}

class _PreviewLoginScreenState extends State<PreviewLoginScreen> {
  AppRole selected = AppRole.anggota;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 38),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height - 120,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.deepNavy, AppColors.blue],
                  ),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 43,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Karangtaruna Apps',
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 45),
              Text(
                'Masuk ke aplikasi',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pratinjau desain untuk tiga peran',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 28),
              SegmentedButton<AppRole>(
                segments: const [
                  ButtonSegment(value: AppRole.anggota, label: Text('Anggota')),
                  ButtonSegment(
                    value: AppRole.bendahara,
                    label: Text('Bendahara'),
                  ),
                  ButtonSegment(value: AppRole.admin, label: Text('Admin')),
                ],
                selected: {selected},
                showSelectedIcon: false,
                onSelectionChanged: (roles) =>
                    setState(() => selected = roles.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Login Firebase belum tersedia',
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const TextField(
                enabled: false,
                obscureText: true,
                decoration: InputDecoration(hintText: '••••••••'),
              ),
              const SizedBox(height: 22),
              const DemoBanner(),
              if (widget.localLoadFailed)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Data lokal gagal dimuat. Periksa penyimpanan perangkat sebelum menambah data.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              FilledButton(
                onPressed: () => widget.onEnter(selected),
                child: const Text('Buka Pratinjau'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Jangan masukkan email atau password asli pada versi pratinjau.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.role,
    required this.store,
    required this.inventoryStore,
    required this.onLogout,
  });
  final AppRole role;
  final DemoStore store;
  final InventoryStore inventoryStore;
  final VoidCallback onLogout;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedTab = 0;
  void openNotifications() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const NotificationsPage()));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: selectedTab,
      children: [
        HomeScreen(
          role: widget.role,
          store: widget.store,
          inventoryStore: widget.inventoryStore,
          onTab: (index) => setState(() => selectedTab = index),
          onNotifications: openNotifications,
        ),
        InventoryScreen(
          role: widget.role,
          store: widget.inventoryStore,
          onNotifications: openNotifications,
        ),
        FinanceScreen(
          role: widget.role,
          store: widget.store,
          onNotifications: openNotifications,
        ),
        ProfileScreen(
          role: widget.role,
          store: widget.store,
          inventoryStore: widget.inventoryStore,
          onLogout: widget.onLogout,
          onNotifications: openNotifications,
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 15),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
              active: selectedTab == 0,
              onTap: () => setState(() => selectedTab = 0),
            ),
            _NavItem(
              icon: Icons.inventory_2_outlined,
              activeIcon: Icons.inventory_2_rounded,
              label: 'Inventaris',
              active: selectedTab == 1,
              onTap: () => setState(() => selectedTab = 1),
            ),
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet_rounded,
              label: 'Keuangan',
              active: selectedTab == 2,
              onTap: () => setState(() => selectedTab = 2),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profil',
              active: selectedTab == 3,
              onTap: () => setState(() => selectedTab = 3),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? AppColors.blue : AppColors.muted,
              size: 23,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.blue : AppColors.muted,
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.role,
    required this.store,
    required this.inventoryStore,
    required this.onTab,
    required this.onNotifications,
  });
  final AppRole role;
  final DemoStore store;
  final InventoryStore inventoryStore;
  final ValueChanged<int> onTab;
  final VoidCallback onNotifications;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool obscured = false;

  @override
  Widget build(BuildContext context) {
    final isTreasurer = widget.role == AppRole.bendahara;
    final isAdmin = widget.role == AppRole.admin;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    return AnimatedBuilder(
      animation: Listenable.merge([widget.store, widget.inventoryStore]),
      builder: (context, _) => PageFrame(
        children: [
          RoleHeader(
            role: widget.role,
            title: 'Halo, ${widget.role.displayName}',
            onNotifications: widget.onNotifications,
          ),
          const DemoBanner(),
          MoneyCard(
            label: isTreasurer ? 'Saldo Saya' : 'Total Kas Terkoneksi',
            subtitle: isTreasurer
                ? 'Kas yang saya pegang'
                : 'Kas bendahara pada contoh ini',
            amount: isTreasurer
                ? widget.store.balanceFor('sukardi')
                : widget.store.connectedCash,
            footerLabel: isTreasurer ? 'Total Kas Terkoneksi' : '2 Bendahara',
            footerValue: isTreasurer
                ? rupiah(widget.store.connectedCash)
                : null,
            obscured: obscured,
            onToggle: () => setState(() => obscured = !obscured),
          ),
          if (isTreasurer) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                QuickAction(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Pemasukan',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TransactionForm(
                        store: widget.store,
                        type: TransactionType.income,
                      ),
                    ),
                  ),
                ),
                QuickAction(
                  icon: Icons.remove_circle_outline_rounded,
                  label: 'Pengeluaran',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TransactionForm(
                        store: widget.store,
                        type: TransactionType.expense,
                      ),
                    ),
                  ),
                ),
                QuickAction(
                  icon: Icons.history_rounded,
                  label: 'Riwayat',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TransactionHistoryPage(store: widget.store),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                StatTile(
                  value: '${widget.inventoryStore.items.length}',
                  label: 'Jenis barang',
                ),
                const SizedBox(width: 8),
                const StatTile(value: '4', label: 'Pengguna'),
                const SizedBox(width: 8),
                StatTile(
                  value:
                      '${widget.inventoryStore.items.fold<int>(0, (sum, item) => sum + item.borrowed)}',
                  label: 'Dipinjam',
                  highlight: true,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                QuickAction(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventaris',
                  onTap: () => widget.onTab(1),
                ),
                QuickAction(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Pengguna',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const UserManagementPage(),
                    ),
                  ),
                ),
                QuickAction(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Keuangan',
                  onTap: () => widget.onTab(2),
                ),
                QuickAction(
                  icon: Icons.bar_chart_outlined,
                  label: 'Laporan',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReportsPage(
                        store: widget.store,
                        inventoryStore: widget.inventoryStore,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isAdmin) ...[
            const SizedBox(height: 23),
            CashFlowCard(
              monthStart: monthStart,
              transactions: widget.store.transactions,
              income: widget.store.totalFor(
                TransactionType.income,
                monthStart,
                monthEnd,
              ),
              expense: widget.store.totalFor(
                TransactionType.expense,
                monthStart,
                monthEnd,
              ),
            ),
          ],
          if (!isTreasurer) ...[
            const SizedBox(height: 28),
            SectionHeading(
              title: 'Inventaris',
              action: 'Lihat Semua',
              onAction: () => widget.onTab(1),
            ),
            Row(
              children: [
                StatTile(
                  value:
                      '${widget.inventoryStore.items.fold<int>(0, (sum, item) => sum + item.total)}',
                  label: 'Total unit',
                ),
                const SizedBox(width: 8),
                StatTile(
                  value:
                      '${widget.inventoryStore.items.fold<int>(0, (sum, item) => sum + item.available)}',
                  label: 'Tersedia',
                  highlight: true,
                ),
                const SizedBox(width: 8),
                StatTile(
                  value:
                      '${widget.inventoryStore.items.fold<int>(0, (sum, item) => sum + item.borrowed)}',
                  label: 'Dipinjam',
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          SectionHeading(
            title: 'Transaksi Terbaru',
            action: 'Lihat Semua',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TransactionHistoryPage(store: widget.store),
              ),
            ),
          ),
          TransactionPanel(
            transactions: widget.store.transactions.take(3).toList(),
            onSelect: (transaction) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TransactionDetailPage(transaction: transaction),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
