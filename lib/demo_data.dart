import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppRole { anggota, bendahara, admin }

extension AppRoleLabel on AppRole {
  /// Mengambil label peran untuk tampilan.
  String get label => switch (this) {
    AppRole.anggota => 'Anggota',
    AppRole.bendahara => 'Bendahara',
    AppRole.admin => 'Admin',
  };

  /// Mengambil nama contoh sesuai peran.
  String get displayName => switch (this) {
    AppRole.anggota => 'Rizky',
    AppRole.bendahara => 'Sukardi',
    AppRole.admin => 'Admin',
  };

  /// Mengambil email contoh sesuai peran.
  String get email => switch (this) {
    AppRole.anggota => 'rizky@gmail.com',
    AppRole.bendahara => 'sukardi@gmail.com',
    AppRole.admin => 'admin@gmail.com',
  };
}

enum TransactionType { income, expense }

class CashTransaction {
  /// Membuat satu transaksi kas.
  const CashTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.holderId,
    required this.holderName,
    required this.type,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final String id;
  final String title;
  final String category;
  final String holderId;
  final String holderName;
  final TransactionType type;
  final int amount;
  final DateTime date;
  final String note;

  /// Mengubah model menjadi peta data untuk penyimpanan.
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'holderId': holderId,
    'holderName': holderName,
    'type': type.name,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };

  /// Membangun model dari peta data tersimpan.
  factory CashTransaction.fromJson(Map<String, dynamic> json) =>
      CashTransaction(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        holderId: json['holderId'] as String,
        holderName: json['holderName'] as String,
        type: TransactionType.values.byName(json['type'] as String),
        amount: json['amount'] as int,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String? ?? '',
      );
}

class InventoryItem {
  /// Membuat satu barang inventaris.
  const InventoryItem({
    required this.code,
    required this.name,
    required this.category,
    required this.total,
    required this.available,
    required this.location,
    this.damaged = 0,
    this.lost = 0,
    this.archived = false,
  });

  final String code;
  final String name;
  final String category;
  final int total;
  final int available;
  final String location;
  final int damaged;
  final int lost;
  final bool archived;

  /// Menghitung jumlah stok yang sedang dipinjam.
  int get borrowed => total - available - damaged - lost;

  /// Membuat salinan model dengan nilai tertentu yang diperbarui.
  InventoryItem copyWith({
    String? name,
    String? category,
    String? location,
    int? total,
    int? available,
    int? damaged,
    int? lost,
    bool? archived,
  }) => InventoryItem(
    code: code,
    name: name ?? this.name,
    category: category ?? this.category,
    location: location ?? this.location,
    total: total ?? this.total,
    available: available ?? this.available,
    damaged: damaged ?? this.damaged,
    lost: lost ?? this.lost,
    archived: archived ?? this.archived,
  );

  /// Mengubah model menjadi peta data untuk penyimpanan.
  Map<String, Object?> toJson() => {
    'code': code,
    'name': name,
    'category': category,
    'location': location,
    'total': total,
    'available': available,
    'damaged': damaged,
    'lost': lost,
    'archived': archived,
  };

  /// Membangun model dari peta data tersimpan.
  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    code: json['code'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    location: json['location'] as String,
    total: json['total'] as int,
    available: json['available'] as int,
    damaged: json['damaged'] as int? ?? 0,
    lost: json['lost'] as int? ?? 0,
    archived: json['archived'] as bool? ?? false,
  );
}

class DemoStore extends ChangeNotifier {
  /// Membuat data keuangan lokal untuk pratinjau.
  DemoStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync(),
      _transactions = [
        CashTransaction(
          id: 't1',
          title: 'Saldo awal',
          category: 'Saldo awal',
          holderId: 'sukardi',
          holderName: 'Sukardi',
          type: TransactionType.income,
          amount: 6000000,
          date: DateTime(2026, 9, 1),
        ),
        CashTransaction(
          id: 't2',
          title: 'Saldo awal',
          category: 'Saldo awal',
          holderId: 'rina',
          holderName: 'Rina',
          type: TransactionType.income,
          amount: 5500000,
          date: DateTime(2026, 9, 1),
        ),
        CashTransaction(
          id: 't3',
          title: 'Kegiatan warga',
          category: 'Kegiatan',
          holderId: 'sukardi',
          holderName: 'Sukardi',
          type: TransactionType.expense,
          amount: 1000000,
          date: DateTime(2026, 9, 25),
        ),
        CashTransaction(
          id: 't4',
          title: 'Perlengkapan',
          category: 'Perlengkapan',
          holderId: 'rina',
          holderName: 'Rina',
          type: TransactionType.expense,
          amount: 500000,
          date: DateTime(2026, 9, 30),
        ),
        CashTransaction(
          id: 't5',
          title: 'Sponsor kegiatan',
          category: 'Sponsor',
          holderId: 'sukardi',
          holderName: 'Sukardi',
          type: TransactionType.income,
          amount: 1025000,
          date: DateTime(2026, 9, 20),
        ),
        CashTransaction(
          id: 't6',
          title: 'Donasi warga',
          category: 'Donasi',
          holderId: 'sukardi',
          holderName: 'Sukardi',
          type: TransactionType.income,
          amount: 1000000,
          date: DateTime(2026, 10, 2),
        ),
        CashTransaction(
          id: 't7',
          title: 'Perlengkapan',
          category: 'Perlengkapan',
          holderId: 'sukardi',
          holderName: 'Sukardi',
          type: TransactionType.expense,
          amount: 325000,
          date: DateTime(2026, 10, 4),
        ),
        CashTransaction(
          id: 't8',
          title: 'Iuran anggota',
          category: 'Iuran',
          holderId: 'sukardi',
          holderName: 'Sukardi',
          type: TransactionType.income,
          amount: 750000,
          date: DateTime(2026, 10, 5),
        ),
      ];

  static const _storageKey = 'karang_taruna_demo_finance_v1';
  final SharedPreferencesAsync _preferences;
  final List<CashTransaction> _transactions;

  /// Menandai apakah store memakai Firestore atau data lokal.
  bool get isRemote => false;

  /// Mengambil ID pemilik kas saat ini.
  String get currentHolderId => 'sukardi';

  /// Mengambil nama pemilik kas saat ini.
  String get currentHolderName => 'Sukardi';

  /// Mengambil daftar bendahara yang dapat ditampilkan.
  Map<String, String> get holders => const {
    'sukardi': 'Sukardi',
    'rina': 'Rina',
  };

  /// Memuat data tersimpan dan menyiapkan pendengar perubahan.
  Future<void> load() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null) return;
    final data = jsonDecode(raw) as List<dynamic>;
    final restored = data
        .map((item) => CashTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
    _transactions
      ..clear()
      ..addAll(restored);
    notifyListeners();
  }

  static const inventory = [
    InventoryItem(
      code: 'INV-001',
      name: 'Speaker aktif 12 inch',
      category: 'Elektronik',
      total: 2,
      available: 1,
      location: 'Gudang utama',
    ),
    InventoryItem(
      code: 'INV-002',
      name: 'Kursi plastik',
      category: 'Peralatan',
      total: 30,
      available: 20,
      location: 'Balai warga',
    ),
    InventoryItem(
      code: 'INV-003',
      name: 'Tenda kegiatan',
      category: 'Kegiatan',
      total: 10,
      available: 8,
      location: 'Gudang utama',
    ),
  ];

  /// Mengambil daftar transaksi yang dapat ditampilkan.
  List<CashTransaction> get transactions =>
      List.unmodifiable(_transactions.reversed);

  /// Menghitung saldo milik bendahara tertentu.
  int balanceFor(String holderId) => _transactions
      .where((transaction) => transaction.holderId == holderId)
      .fold(
        0,
        (sum, transaction) =>
            sum +
            (transaction.type == TransactionType.income
                ? transaction.amount
                : -transaction.amount),
      );

  /// Menjumlahkan kas dari bendahara yang terhubung.
  int get connectedCash =>
      {'sukardi', 'rina'}.fold(0, (sum, id) => sum + balanceFor(id));

  /// Menjumlahkan transaksi menurut jenis dan rentang tanggal.
  int totalFor(TransactionType type, DateTime start, DateTime end) =>
      _transactions
          .where(
            (transaction) =>
                transaction.type == type &&
                !transaction.date.isBefore(start) &&
                transaction.date.isBefore(end),
          )
          .fold(0, (sum, transaction) => sum + transaction.amount);

  /// Memvalidasi lalu menyimpan transaksi pemasukan atau pengeluaran.
  Future<void> addTransaction({
    required TransactionType type,
    required String title,
    required String category,
    required int amount,
    required DateTime date,
    String note = '',
  }) async {
    if (amount <= 0) throw ArgumentError('Nominal harus lebih dari nol.');
    if (type == TransactionType.expense && amount > balanceFor('sukardi')) {
      throw StateError('Saldo tidak mencukupi.');
    }
    final transaction = CashTransaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      category: category,
      holderId: 'sukardi',
      holderName: 'Sukardi',
      type: type,
      amount: amount,
      date: date,
      note: note,
    );
    final next = [..._transactions, transaction];
    await _preferences.setString(
      _storageKey,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
    _transactions.add(transaction);
    notifyListeners();
  }
}

/// Memformat nominal angka menjadi mata uang rupiah.
String rupiah(int amount) {
  final digits = amount.abs().toString();
  final chunks = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    chunks.insert(0, digits.substring(start, end));
  }
  return 'Rp ${amount < 0 ? '-' : ''}${chunks.join('.')}';
}

/// Memformat tanggal singkat untuk tampilan.
String shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
