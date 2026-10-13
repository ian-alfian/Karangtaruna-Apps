import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karangtaruna_apps/app.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());
  testWidgets('pratinjau anggota dapat membuka navigasi utama', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const KarangTarunaApp());
    await tester.pumpAndSettle();
    expect(find.text('Buka Pratinjau'), findsOneWidget);

    await tester.tap(find.text('Buka Pratinjau'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Halo, Rizky'), findsOneWidget);
    expect(find.text('Total Kas Terkoneksi'), findsWidgets);

    await tester.tap(find.text('Inventaris').last);
    await tester.pumpAndSettle();
    expect(find.text('Daftar Barang'), findsOneWidget);
    expect(find.text('Speaker aktif 12 inch'), findsOneWidget);
  });

  testWidgets('aksi keuangan hanya tampil pada pratinjau bendahara', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const KarangTarunaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bendahara'));
    await tester.tap(find.text('Buka Pratinjau'));
    await tester.pumpAndSettle();
    expect(find.text('Pemasukan'), findsWidgets);
    expect(find.text('Pengeluaran'), findsWidgets);
    await tester.tap(find.text('Pemasukan').first);
    await tester.pumpAndSettle();
    expect(find.text('Tambah Pemasukan'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });
}
