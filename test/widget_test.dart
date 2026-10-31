import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karangtaruna_apps/app.dart';
import 'package:karangtaruna_apps/demo_data.dart';
import 'package:karangtaruna_apps/firebase_login.dart';
import 'package:karangtaruna_apps/inventory_store.dart';
import 'package:karangtaruna_apps/ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  Future<void> pumpShell(
    WidgetTester tester,
    AppRole role, {
    FirebaseUserProfile? profile,
    AppRole? initialViewRole,
  }) async {
    final store = DemoStore();
    final inventoryStore = InventoryStore();
    await Future.wait([store.load(), inventoryStore.load()]);
    addTearDown(() {
      store.dispose();
      inventoryStore.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          role: role,
          authenticatedProfile: profile,
          initialViewRole: initialViewRole,
          store: store,
          inventoryStore: inventoryStore,
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('profil Admin tidak menampilkan ganti tampilan peran', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpShell(
      tester,
      AppRole.admin,
      profile: const FirebaseUserProfile(
        uid: 'admin-1',
        name: 'Admin Karang Taruna',
        email: 'admin@example.com',
        organizationId: 'karangtaruna-main',
        role: AppRole.admin,
      ),
    );

    expect(find.textContaining('Tampilan Admin'), findsNothing);
    expect(
      tester.widget<StatTile>(find.widgetWithText(StatTile, 'Pengguna')).value,
      '0',
    );
    expect(find.byTooltip('Ganti tampilan peran'), findsNothing);
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('Kelola Pengguna'), findsOneWidget);
    expect(find.text('Ganti Tampilan Peran'), findsNothing);
  });

  testWidgets('peran pilihan login menjadi tampilan awal Admin', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpShell(
      tester,
      AppRole.admin,
      initialViewRole: AppRole.bendahara,
      profile: const FirebaseUserProfile(
        uid: 'admin-1',
        name: 'Admin Karang Taruna',
        email: 'admin@example.com',
        organizationId: 'karangtaruna-main',
        role: AppRole.admin,
      ),
    );
    expect(find.text('Tampilan Bendahara • data contoh'), findsNothing);
    expect(find.text('Halo, Sukardi'), findsOneWidget);
  });

  testWidgets('anggota dapat membuka navigasi utama', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpShell(tester, AppRole.anggota);
    expect(find.textContaining('Halo, Rizky'), findsOneWidget);
    expect(find.text('Total Kas Terkoneksi'), findsWidgets);

    await tester.tap(find.text('Inventaris').last);
    await tester.pumpAndSettle();
    expect(find.text('Daftar Barang'), findsOneWidget);
    expect(find.text('Speaker aktif 12 inch'), findsOneWidget);
  });

  testWidgets('form tambah barang menyediakan foto untuk detail inventaris', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpShell(tester, AppRole.admin);
    await tester.tap(find.text('Inventaris').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Barang'));
    await tester.pumpAndSettle();
    expect(find.text('Foto Barang'), findsOneWidget);
    expect(find.text('Pilih Foto Barang'), findsOneWidget);
  });

  testWidgets('aksi keuangan tampil pada bendahara', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpShell(tester, AppRole.bendahara);
    expect(find.text('Pemasukan'), findsWidgets);
    expect(find.text('Pengeluaran'), findsWidgets);
    await tester.tap(find.text('Pemasukan').first);
    await tester.pumpAndSettle();
    expect(find.text('Tambah Pemasukan'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));

    await tester.enterText(find.byType(TextFormField).first, '1500000');
    await tester.pump();
    expect(find.text('1.500.000'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'Iuran anggota');
    await tester.ensureVisible(find.text('Simpan Pemasukan Demo'));
    await tester.tap(find.text('Simpan Pemasukan Demo'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Pemasukan'), findsOneWidget);
    final noButton = find.text('Batal');
    final yesButton = find.text('Simpan');
    expect(noButton, findsOneWidget);
    expect(yesButton, findsOneWidget);
    expect(
      tester.getCenter(noButton).dx,
      closeTo(tester.getCenter(yesButton).dx, 1),
    );
    expect(
      tester.getCenter(noButton).dy,
      greaterThan(tester.getCenter(yesButton).dy),
    );
    expect(find.textContaining('Rp 1.500.000'), findsOneWidget);
  });

  testWidgets('pengeluaran memperingatkan saldo saat nominal diketik', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpShell(tester, AppRole.bendahara);
    await tester.tap(find.text('Pengeluaran').first);
    await tester.pumpAndSettle();

    expect(find.text('Tambah Pengeluaran'), findsOneWidget);
    final amountField = find.byType(TextFormField).first;
    await tester.enterText(amountField, '90000000');
    await tester.pump();
    expect(find.text('90.000.000'), findsOneWidget);
    expect(find.text('Saldo tidak mencukupi.'), findsOneWidget);
    expect(find.text('Konfirmasi Pengeluaran'), findsNothing);

    await tester.enterText(amountField, '1000');
    await tester.pump();
    expect(find.text('Saldo tidak mencukupi.'), findsNothing);
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Perlengkapan acara',
    );
    await tester.ensureVisible(find.text('Simpan Pengeluaran Demo'));
    await tester.tap(find.text('Simpan Pengeluaran Demo'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Pengeluaran'), findsOneWidget);
    final noButton = find.text('Batal');
    final yesButton = find.text('Simpan');
    expect(noButton, findsOneWidget);
    expect(yesButton, findsOneWidget);
    expect(
      tester.getCenter(noButton).dx,
      closeTo(tester.getCenter(yesButton).dx, 1),
    );
    expect(
      tester.getCenter(noButton).dy,
      greaterThan(tester.getCenter(yesButton).dy),
    );
    await tester.tap(noButton);
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Pengeluaran'), findsNothing);
  });
}
