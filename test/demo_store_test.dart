import 'package:flutter_test/flutter_test.dart';
import 'package:karangtaruna_apps/demo_data.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());
  test(
    'saldo contoh berasal dari transaksi dan tidak menghitung bendahara ganda',
    () {
      final store = DemoStore();
      expect(store.balanceFor('sukardi'), 7450000);
      expect(store.balanceFor('rina'), 5000000);
      expect(store.connectedCash, 12450000);
    },
  );

  test('pengeluaran demo menolak nominal di atas saldo', () async {
    final store = DemoStore();
    await expectLater(
      store.addTransaction(
        type: TransactionType.expense,
        title: 'Terlalu besar',
        category: 'Lainnya',
        amount: 8000000,
        date: DateTime(2026, 10, 12),
      ),
      throwsStateError,
    );
    expect(store.balanceFor('sukardi'), 7450000);
  });

  test('transaksi demo tersimpan lokal dan saldo dihitung ulang', () async {
    final store = DemoStore();
    await store.addTransaction(
      type: TransactionType.income,
      title: 'Iuran',
      category: 'Iuran',
      amount: 100000,
      date: DateTime(2026, 10, 12),
    );
    final restored = DemoStore();
    await restored.load();
    expect(restored.transactions.length, 9);
    expect(restored.balanceFor('sukardi'), 7550000);
    expect(restored.connectedCash, 12550000);
  });
}
