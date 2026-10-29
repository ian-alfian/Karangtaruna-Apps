import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_stores.dart';
import 'demo_data.dart';
import 'firebase_admin.dart';
import 'firebase_login.dart';
import 'finance.dart';
import 'inventory.dart';
import 'inventory_store.dart';
import 'login_screen.dart';
import 'login_bloc.dart';
import 'onboarding_screen.dart';
import 'profile.dart';
import 'ui.dart';
import 'user_management.dart';

class KarangTarunaApp extends StatelessWidget {
  /// Membuat aplikasi dan tema utamanya.
  const KarangTarunaApp({super.key});

  /// Menyusun tampilan aplikasi dan tema utamanya.
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
  /// Membuat alur awal, sesi login, dan onboarding.
  const AppRoot({super.key});

  /// Membuat state interaktif untuk alur awal, sesi login, dan onboarding.
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  FirebaseUserProfile? signedInProfile;
  AppRole? selectedLoginRole;
  DemoStore? store;
  InventoryStore? inventoryStore;
  late final FirebaseLoginService loginService;
  late final LoginBloc loginBloc;
  bool ready = false;
  bool onboardingComplete = false;
  bool signOutBusy = false;

  /// Menyiapkan state dan pendengar awal saat widget dibuat.
  @override
  void initState() {
    super.initState();
    loginService = FirebaseLoginService();
    loginBloc = LoginBloc(loginService, _activateProfile);
    _initialize();
  }

  /// Memuat preferensi awal dan mencoba memulihkan sesi login.
  Future<void> _initialize() async {
    try {
      onboardingComplete =
          await SharedPreferencesAsync().getBool('onboarding_complete_v1') ??
          false;
    } catch (_) {
      onboardingComplete = false;
    }
    try {
      final profile = await loginService.restoreSession();
      if (profile != null) {
        await _activateProfile(profile);
        signedInProfile = profile;
      }
    } catch (error) {
      await loginService.signOut();
      loginBloc.add(LoginErrorReported(firebaseLoginError(error)));
    }
    if (mounted) setState(() => ready = true);
  }

  /// Menyiapkan store keuangan dan inventaris sesuai profil pengguna.
  Future<void> _activateProfile(FirebaseUserProfile profile) async {
    final finance = CloudFinanceStore(profile);
    final inventory = CloudInventoryStore(profile);
    try {
      await finance.load();
      await inventory.load();
    } catch (_) {
      finance.dispose();
      inventory.dispose();
      rethrow;
    }
    store?.dispose();
    inventoryStore?.dispose();
    store = finance;
    inventoryStore = inventory;
  }

  /// Menyimpan bahwa pengenalan aplikasi sudah selesai.
  Future<void> _completeOnboarding() async {
    try {
      await SharedPreferencesAsync().setBool('onboarding_complete_v1', true);
    } catch (_) {}
    if (mounted) setState(() => onboardingComplete = true);
  }

  /// Menghapus sesi serta state akun yang sedang aktif.
  Future<void> _signOut() async {
    if (signOutBusy) return;
    setState(() => signOutBusy = true);
    try {
      await loginService.signOut();
      if (mounted) {
        loginBloc.add(const LoginCleared());
        setState(() {
          store?.dispose();
          inventoryStore?.dispose();
          store = null;
          inventoryStore = null;
          signedInProfile = null;
          selectedLoginRole = null;
        });
      }
    } catch (error) {
      loginBloc.add(LoginErrorReported(firebaseLoginError(error)));
    } finally {
      if (mounted) setState(() => signOutBusy = false);
    }
  }

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    store?.dispose();
    inventoryStore?.dispose();
    unawaited(loginBloc.close());
    super.dispose();
  }

  /// Menyusun tampilan alur awal, sesi login, dan onboarding.
  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: loginBloc,
    child: BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          setState(() {
            signedInProfile = state.profile;
            selectedLoginRole = state.viewRole;
          });
        }
      },
      builder: (context, state) => !ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : signedInProfile != null
          ? AppShell(
              role: signedInProfile!.role,
              initialViewRole: selectedLoginRole,
              authenticatedProfile: signedInProfile!,
              store: store!,
              inventoryStore: inventoryStore!,
              onLogout: _signOut,
            )
          : !onboardingComplete
          ? OnboardingScreen(onFinished: _completeOnboarding)
          : LoginScreen(
              onSignIn: (email, password, rememberMe, selectedRole) async {
                loginBloc.add(
                  LoginSubmitted(
                    email: email,
                    password: password,
                    rememberMe: rememberMe,
                    selectedRole: selectedRole,
                  ),
                );
              },
              onResetPassword: (email) async {
                loginBloc.add(PasswordResetRequested(email));
              },
              busy: state is LoginLoading,
              error: state is LoginFailure ? state.message : null,
              notice: state is PasswordResetSent ? state.message : null,
            ),
    ),
  );
}

class AppShell extends StatefulWidget {
  /// Membuat navigasi utama sesuai peran.
  const AppShell({
    super.key,
    required this.role,
    required this.store,
    required this.inventoryStore,
    required this.onLogout,
    this.authenticatedProfile,
    this.initialViewRole,
  });
  final AppRole role;
  final DemoStore store;
  final InventoryStore inventoryStore;
  final VoidCallback onLogout;
  final FirebaseUserProfile? authenticatedProfile;
  final AppRole? initialViewRole;

  /// Membuat state interaktif untuk navigasi utama sesuai peran.
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedTab = 0;
  AppRole? selectedViewRole;

  /// Menyiapkan state dan pendengar awal saat widget dibuat.
  @override
  void initState() {
    super.initState();
    selectedViewRole = widget.initialViewRole;
  }

  /// Membuka halaman notifikasi.
  void openNotifications() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NotificationsPage(
        profile: widget.authenticatedProfile,
        store: widget.store,
      ),
    ),
  );

  /// Menyusun tampilan navigasi utama sesuai peran.
  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.authenticatedProfile?.role == AppRole.admin;
    final viewRole = isAdmin ? (selectedViewRole ?? widget.role) : widget.role;
    return Scaffold(
      body: IndexedStack(
        index: selectedTab,
        children: [
          HomeScreen(
            role: viewRole,
            authenticatedProfile: widget.authenticatedProfile,
            store: widget.store,
            inventoryStore: widget.inventoryStore,
            onTab: (index) => setState(() => selectedTab = index),
            onNotifications: openNotifications,
          ),
          InventoryScreen(
            role: viewRole,
            store: widget.inventoryStore,
            onNotifications: openNotifications,
          ),
          FinanceScreen(
            role: viewRole,
            store: widget.store,
            onNotifications: openNotifications,
            canEditFinance:
                !widget.store.isRemote ||
                widget.authenticatedProfile?.role == AppRole.bendahara,
          ),
          ProfileScreen(
            role: viewRole,
            authenticatedProfile: widget.authenticatedProfile,
            store: widget.store,
            inventoryStore: widget.inventoryStore,
            onLogout: widget.onLogout,
            onNotifications: openNotifications,
            onViewRoleChanged: isAdmin
                ? (role) => setState(() {
                    selectedViewRole = role;
                    selectedTab = 0;
                  })
                : null,
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
}

class _NavItem extends StatelessWidget {
  /// Membuat satu tombol navigasi bawah.
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

  /// Menyusun tampilan satu tombol navigasi bawah.
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
  /// Membuat beranda sesuai peran.
  const HomeScreen({
    super.key,
    required this.role,
    this.authenticatedProfile,
    required this.store,
    required this.inventoryStore,
    required this.onTab,
    required this.onNotifications,
  });
  final AppRole role;
  final FirebaseUserProfile? authenticatedProfile;
  final DemoStore store;
  final InventoryStore inventoryStore;
  final ValueChanged<int> onTab;
  final VoidCallback onNotifications;

  /// Membuat state interaktif untuk beranda sesuai peran.
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool obscured = false;
  Stream<int>? managedUserCount;

  /// Menyiapkan state dan pendengar awal saat widget dibuat.
  @override
  void initState() {
    super.initState();
    _setUserCountStream();
  }

  /// Memperbarui stream ketika data widget beranda berubah.
  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authenticatedProfile?.uid !=
        widget.authenticatedProfile?.uid) {
      _setUserCountStream();
    }
  }

  /// Menyiapkan stream jumlah pengguna untuk dashboard Admin.
  void _setUserCountStream() {
    final profile = widget.authenticatedProfile;
    managedUserCount = widget.store.isRemote && profile?.role == AppRole.admin
        ? FirebaseAdminService(profile: profile!).managedUserCount()
        : null;
  }

  /// Menyusun tampilan beranda sesuai peran.
  @override
  Widget build(BuildContext context) {
    final isTreasurer =
        widget.role == AppRole.bendahara &&
        (!widget.store.isRemote ||
            widget.authenticatedProfile?.role == AppRole.bendahara);
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
          if (!widget.store.isRemote) const DemoBanner(),
          MoneyCard(
            label: isTreasurer
                ? 'Saldo Saya'
                : widget.store.isRemote
                ? 'Total Kas Terkoneksi'
                : 'Total Kas Terkoneksi',
            subtitle: isTreasurer
                ? 'Kas yang saya pegang'
                : widget.store.isRemote
                ? 'Kas Bendahara terhubung'
                : 'Kas bendahara pada contoh ini',
            amount: isTreasurer
                ? widget.store.balanceFor(widget.store.currentHolderId)
                : widget.store.connectedCash,
            footerLabel: isTreasurer
                ? 'Total Kas Terkoneksi'
                : '${widget.store.holders.length} Bendahara',
            footerValue: isTreasurer
                ? rupiah(widget.store.connectedCash)
                : null,
            obscured: obscured,
            onToggle: () => setState(() => obscured = !obscured),
          ),
          if (isTreasurer &&
              (!widget.store.isRemote ||
                  widget.authenticatedProfile?.role == AppRole.bendahara)) ...[
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
                StreamBuilder<int>(
                  stream: managedUserCount,
                  builder: (context, snapshot) => StatTile(
                    value: widget.store.isRemote
                        ? snapshot.hasError
                              ? '—'
                              : '${snapshot.data ?? 0}'
                        : '0',
                    label: 'Pengguna',
                  ),
                ),
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
                      builder: (_) => UserManagementPage(
                        adminProfile: widget.authenticatedProfile,
                      ),
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
