import 'package:flutter_test/flutter_test.dart';
import 'package:karangtaruna_apps/inventory_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('peminjaman dan pengembalian menjaga stok sesuai kondisi', () async {
    final store = InventoryStore();
    await store.addItem(
      code: 'INV-004',
      name: 'Meja lipat',
      category: 'Peralatan',
      location: 'Gudang',
      quantity: 5,
    );

    await store.borrowItem(
      code: 'INV-004',
      borrower: 'Ayu',
      quantity: 3,
      dueAt: DateTime.now().add(const Duration(days: 7)),
    );
    expect(store.itemFor('INV-004').available, 2);
    expect(store.itemFor('INV-004').borrowed, 3);
    await expectLater(store.archiveItem('INV-004'), throwsStateError);

    final borrowing = store.borrowings.first;
    await store.returnItem(
      borrowing.id,
      good: 1,
      damaged: 1,
      lost: 1,
      note: 'Satu rusak, satu hilang',
    );
    final item = store.itemFor('INV-004');
    expect(item.available, 3);
    expect(item.borrowed, 0);
    expect(item.damaged, 1);
    expect(item.lost, 1);
    expect(store.borrowings.first.status, 'Selesai');
    await store.archiveItem('INV-004');
    expect(store.items.any((item) => item.code == 'INV-004'), isFalse);
    expect(store.archivedItems.any((item) => item.code == 'INV-004'), isTrue);
  });

  test(
    'stok dan pinjaman lokal dimuat kembali, perubahan invalid ditolak',
    () async {
      final store = InventoryStore();
      await expectLater(
        store.adjustStock('INV-001', -2, 'Audit'),
        throwsStateError,
      );
      await expectLater(
        store.returnItem('b1', good: 0, damaged: 1, lost: 0, note: ''),
        throwsArgumentError,
      );
      await store.adjustStock('INV-001', 2, 'Pembelian');
      await store.borrowItem(
        code: 'INV-001',
        borrower: 'Dina',
        quantity: 1,
        dueAt: DateTime.now().add(const Duration(days: 2)),
      );

      final restored = InventoryStore();
      await restored.load();
      expect(restored.itemFor('INV-001').total, 4);
      expect(restored.itemFor('INV-001').available, 2);
      expect(restored.itemFor('INV-001').borrowed, 2);
      expect(restored.borrowings.length, 4);
      expect(restored.movementsFor('INV-001').length, 2);
    },
  );

  test('foto inventaris tersimpan dan dapat diganti', () async {
    final store = InventoryStore();
    await store.addItem(
      code: 'INV-004',
      name: 'Meja lipat',
      category: 'Peralatan',
      location: 'Gudang',
      quantity: 1,
      photoBase64: 'foto-pertama',
    );
    final restored = InventoryStore();
    await restored.load();
    expect(await restored.photoFor('INV-004'), 'foto-pertama');
    await restored.editItem(
      'INV-004',
      name: 'Meja lipat',
      category: 'Peralatan',
      location: 'Gudang',
      photoBase64: 'foto-baru',
    );
    expect(await restored.photoFor('INV-004'), 'foto-baru');
  });
}
