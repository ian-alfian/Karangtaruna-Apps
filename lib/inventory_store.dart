import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_data.dart';

class Borrowing {
  /// Membuat satu catatan peminjaman.
  const Borrowing({
    required this.id,
    required this.itemCode,
    required this.borrower,
    required this.quantity,
    required this.returned,
    required this.borrowedAt,
    required this.dueAt,
    this.note = '',
  });
  final String id;
  final String itemCode;
  final String borrower;
  final int quantity;
  final int returned;
  final DateTime borrowedAt;
  final DateTime dueAt;
  final String note;

  /// Menghitung jumlah barang pinjaman yang belum kembali.
  int get remaining => quantity - returned;
  /// Menentukan status pengembalian peminjaman.
  String get status => remaining == 0
      ? 'Selesai'
      : dueAt.isBefore(DateTime.now())
      ? 'Terlambat'
      : 'Aktif';

  /// Membuat salinan model dengan nilai tertentu yang diperbarui.
  Borrowing copyWith({int? returned}) => Borrowing(
    id: id,
    itemCode: itemCode,
    borrower: borrower,
    quantity: quantity,
    returned: returned ?? this.returned,
    borrowedAt: borrowedAt,
    dueAt: dueAt,
    note: note,
  );
  /// Mengubah model menjadi peta data untuk penyimpanan.
  Map<String, Object?> toJson() => {
    'id': id,
    'itemCode': itemCode,
    'borrower': borrower,
    'quantity': quantity,
    'returned': returned,
    'borrowedAt': borrowedAt.toIso8601String(),
    'dueAt': dueAt.toIso8601String(),
    'note': note,
  };
  /// Membangun model dari peta data tersimpan.
  factory Borrowing.fromJson(Map<String, dynamic> json) => Borrowing(
    id: json['id'] as String,
    itemCode: json['itemCode'] as String,
    borrower: json['borrower'] as String,
    quantity: json['quantity'] as int,
    returned: json['returned'] as int,
    borrowedAt: DateTime.parse(json['borrowedAt'] as String),
    dueAt: DateTime.parse(json['dueAt'] as String),
    note: json['note'] as String? ?? '',
  );
}

class InventoryMovement {
  /// Membuat satu perubahan stok.
  const InventoryMovement({
    required this.id,
    required this.itemCode,
    required this.action,
    required this.reason,
    required this.beforeAvailable,
    required this.afterAvailable,
    required this.at,
  });
  final String id;
  final String itemCode;
  final String action;
  final String reason;
  final int beforeAvailable;
  final int afterAvailable;
  final DateTime at;

  /// Mengubah model menjadi peta data untuk penyimpanan.
  Map<String, Object?> toJson() => {
    'id': id,
    'itemCode': itemCode,
    'action': action,
    'reason': reason,
    'beforeAvailable': beforeAvailable,
    'afterAvailable': afterAvailable,
    'at': at.toIso8601String(),
  };
  /// Membangun model dari peta data tersimpan.
  factory InventoryMovement.fromJson(Map<String, dynamic> json) =>
      InventoryMovement(
        id: json['id'] as String,
        itemCode: json['itemCode'] as String,
        action: json['action'] as String,
        reason: json['reason'] as String,
        beforeAvailable: json['beforeAvailable'] as int,
        afterAvailable: json['afterAvailable'] as int,
        at: DateTime.parse(json['at'] as String),
      );
}

class InventoryStore extends ChangeNotifier {
  /// Membuat data inventaris lokal.
  InventoryStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'karang_taruna_demo_inventory_v1';
  final SharedPreferencesAsync _preferences;
  /// Menandai apakah store memakai Firestore atau data lokal.
  bool get isRemote => false;
  List<InventoryItem> _items = List.of(DemoStore.inventory);
  List<Borrowing> _borrowings = [
    Borrowing(
      id: 'b1',
      itemCode: 'INV-001',
      borrower: 'Rizky',
      quantity: 1,
      returned: 0,
      borrowedAt: DateTime(2026, 10, 5),
      dueAt: DateTime(2026, 10, 15),
    ),
    Borrowing(
      id: 'b2',
      itemCode: 'INV-002',
      borrower: 'Dina',
      quantity: 10,
      returned: 0,
      borrowedAt: DateTime(2026, 10, 4),
      dueAt: DateTime(2026, 10, 20),
    ),
    Borrowing(
      id: 'b3',
      itemCode: 'INV-003',
      borrower: 'Ayu',
      quantity: 2,
      returned: 0,
      borrowedAt: DateTime(2026, 10, 3),
      dueAt: DateTime(2026, 10, 22),
    ),
  ];
  List<InventoryMovement> _movements = [];
  Map<String, String> _photos = {};

  /// Mengambil daftar barang aktif.
  List<InventoryItem> get items =>
      List.unmodifiable(_items.where((item) => !item.archived));
  /// Mengambil daftar barang yang diarsipkan.
  List<InventoryItem> get archivedItems =>
      List.unmodifiable(_items.where((item) => item.archived));
  /// Mengambil daftar peminjaman.
  List<Borrowing> get borrowings => List.unmodifiable(_borrowings.reversed);
  /// Mengambil riwayat perubahan stok untuk satu barang.
  List<InventoryMovement> movementsFor(String code) => List.unmodifiable(
    _movements.where((movement) => movement.itemCode == code).toList().reversed,
  );
  /// Mencari barang berdasarkan kode inventaris.
  InventoryItem itemFor(String code) =>
      _items.firstWhere((item) => item.code == code);
  /// Mengambil foto yang tersimpan untuk kode barang.
  Future<String?> photoFor(String code) async => _photos[code.toUpperCase()];

  /// Memuat data tersimpan dan menyiapkan pendengar perubahan.
  Future<void> load() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((value) => InventoryItem.fromJson(value as Map<String, dynamic>))
        .toList();
    final borrowings = (data['borrowings'] as List<dynamic>)
        .map((value) => Borrowing.fromJson(value as Map<String, dynamic>))
        .toList();
    final movements = (data['movements'] as List<dynamic>)
        .map(
          (value) => InventoryMovement.fromJson(value as Map<String, dynamic>),
        )
        .toList();
    final photos = (data['photos'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, value as String),
    );
    _verify(items, borrowings);
    _items = items;
    _borrowings = borrowings;
    _movements = movements;
    _photos = photos;
    notifyListeners();
  }

  /// Memeriksa konsistensi jumlah stok dan peminjaman.
  void _verify(List<InventoryItem> items, List<Borrowing> borrowings) {
    for (final item in items) {
      final activeBorrowed = borrowings
          .where((borrowing) => borrowing.itemCode == item.code)
          .fold<int>(0, (sum, borrowing) => sum + borrowing.remaining);
      if (item.total < 0 ||
          item.available < 0 ||
          item.damaged < 0 ||
          item.lost < 0 ||
          item.borrowed != activeBorrowed) {
        throw StateError('Stok ${item.name} tidak konsisten.');
      }
    }
  }

  /// Menyimpan perubahan inventaris lokal dan memberi tahu pendengar.
  Future<void> _commit(
    List<InventoryItem> items,
    List<Borrowing> borrowings,
    List<InventoryMovement> movements, {
    Map<String, String>? photos,
  }) async {
    _verify(items, borrowings);
    final data = jsonEncode({
      'items': items.map((item) => item.toJson()).toList(),
      'borrowings': borrowings.map((borrowing) => borrowing.toJson()).toList(),
      'movements': movements.map((movement) => movement.toJson()).toList(),
      'photos': photos ?? _photos,
    });
    await _preferences.setString(_storageKey, data);
    _items = items;
    _borrowings = borrowings;
    _movements = movements;
    _photos = photos ?? _photos;
    notifyListeners();
  }

  /// Membuat catatan perubahan stok dengan informasi waktu dan alasan.
  InventoryMovement _movement(
    InventoryItem item,
    String action,
    String reason,
    int afterAvailable,
  ) => InventoryMovement(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    itemCode: item.code,
    action: action,
    reason: reason,
    beforeAvailable: item.available,
    afterAvailable: afterAvailable,
    at: DateTime.now(),
  );

  /// Memvalidasi dan menyimpan barang baru beserta stok serta fotonya.
  Future<void> addItem({
    required String code,
    required String name,
    required String category,
    required String location,
    required int quantity,
    String? photoBase64,
  }) async {
    if (code.trim().isEmpty ||
        name.trim().isEmpty ||
        location.trim().isEmpty ||
        quantity <= 0) {
      throw ArgumentError('Lengkapi data barang dan stok awal.');
    }
    if (_items.any(
      (item) => item.code.toLowerCase() == code.trim().toLowerCase(),
    )) {
      throw StateError('Kode barang sudah digunakan.');
    }
    final item = InventoryItem(
      code: code.trim().toUpperCase(),
      name: name.trim(),
      category: category,
      location: location.trim(),
      total: quantity,
      available: quantity,
    );
    await _commit(
      [..._items, item],
      _borrowings,
      [
        ..._movements,
        InventoryMovement(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          itemCode: item.code,
          action: 'Tambah barang',
          reason: 'Stok awal',
          beforeAvailable: 0,
          afterAvailable: quantity,
          at: DateTime.now(),
        ),
      ],
      photos: photoBase64 == null ? null : {..._photos, item.code: photoBase64},
    );
  }

  /// Memperbarui informasi dan foto barang yang sudah ada.
  Future<void> editItem(
    String code, {
    required String name,
    required String category,
    required String location,
    String? photoBase64,
  }) async {
    if (name.trim().isEmpty || location.trim().isEmpty) {
      throw ArgumentError('Nama dan lokasi wajib diisi.');
    }
    final original = itemFor(code);
    if (original.archived) {
      throw StateError('Barang arsip tidak dapat diubah.');
    }
    final next = _items
        .map(
          (item) => item.code == code
              ? item.copyWith(
                  name: name.trim(),
                  category: category,
                  location: location.trim(),
                )
              : item,
        )
        .toList();
    await _commit(
      next,
      _borrowings,
      [
        ..._movements,
        _movement(
          original,
          'Edit barang',
          'Metadata diperbarui',
          original.available,
        ),
      ],
      photos: photoBase64 == null
          ? null
          : {..._photos, original.code: photoBase64},
    );
  }

  /// Menambah atau mengurangi stok dan mencatat alasannya.
  Future<void> adjustStock(String code, int delta, String reason) async {
    if (delta == 0 || reason.trim().isEmpty) {
      throw ArgumentError('Jumlah dan alasan perubahan wajib diisi.');
    }
    final original = itemFor(code);
    if (original.archived) throw StateError('Barang arsip tidak dapat diubah.');
    if (original.available + delta < 0) {
      throw StateError('Stok tersedia tidak mencukupi.');
    }
    final next = _items
        .map(
          (item) => item.code == code
              ? item.copyWith(
                  total: item.total + delta,
                  available: item.available + delta,
                )
              : item,
        )
        .toList();
    await _commit(next, _borrowings, [
      ..._movements,
      _movement(
        original,
        'Update stok',
        reason.trim(),
        original.available + delta,
      ),
    ]);
  }

  /// Mengarsipkan barang setelah memastikan tidak ada peminjaman aktif.
  Future<void> archiveItem(String code) async {
    final original = itemFor(code);
    if (original.borrowed > 0) {
      throw StateError('Selesaikan peminjaman aktif sebelum arsip.');
    }
    final next = _items
        .map((item) => item.code == code ? item.copyWith(archived: true) : item)
        .toList();
    await _commit(next, _borrowings, [
      ..._movements,
      _movement(
        original,
        'Arsip barang',
        'Diarsipkan oleh Admin demo',
        original.available,
      ),
    ]);
  }

  /// Mencatat peminjaman dan mengurangi stok tersedia.
  Future<void> borrowItem({
    required String code,
    required String borrower,
    required int quantity,
    required DateTime dueAt,
    String note = '',
  }) async {
    final original = itemFor(code);
    if (original.archived || borrower.trim().isEmpty || quantity <= 0) {
      throw ArgumentError('Isi peminjam dan jumlah yang valid.');
    }
    if (quantity > original.available) {
      throw StateError('Stok tersedia tidak mencukupi.');
    }
    if (dueAt.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      throw ArgumentError('Tanggal kembali tidak valid.');
    }
    final borrowing = Borrowing(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      itemCode: code,
      borrower: borrower.trim(),
      quantity: quantity,
      returned: 0,
      borrowedAt: DateTime.now(),
      dueAt: dueAt,
      note: note.trim(),
    );
    final next = _items
        .map(
          (item) => item.code == code
              ? item.copyWith(available: item.available - quantity)
              : item,
        )
        .toList();
    await _commit(
      next,
      [..._borrowings, borrowing],
      [
        ..._movements,
        _movement(
          original,
          'Peminjaman',
          'Dipinjam oleh ${borrowing.borrower}',
          original.available - quantity,
        ),
      ],
    );
  }

  /// Mencatat pengembalian serta memperbarui stok, kerusakan, atau kehilangan.
  Future<void> returnItem(
    String borrowingId, {
    required int good,
    required int damaged,
    required int lost,
    required String note,
  }) async {
    final borrowing = _borrowings.firstWhere(
      (value) => value.id == borrowingId,
    );
    final count = good + damaged + lost;
    if (good < 0 ||
        damaged < 0 ||
        lost < 0 ||
        count <= 0 ||
        count > borrowing.remaining) {
      throw ArgumentError('Jumlah kembali tidak valid.');
    }
    if ((damaged > 0 || lost > 0) && note.trim().isEmpty) {
      throw ArgumentError('Catatan wajib untuk barang rusak atau hilang.');
    }
    final original = itemFor(borrowing.itemCode);
    final nextItems = _items
        .map(
          (item) => item.code == original.code
              ? item.copyWith(
                  available: item.available + good,
                  damaged: item.damaged + damaged,
                  lost: item.lost + lost,
                )
              : item,
        )
        .toList();
    final nextBorrowings = _borrowings
        .map(
          (value) => value.id == borrowingId
              ? value.copyWith(returned: value.returned + count)
              : value,
        )
        .toList();
    await _commit(nextItems, nextBorrowings, [
      ..._movements,
      _movement(
        original,
        'Pengembalian',
        'Baik $good, rusak $damaged, hilang $lost. ${note.trim()}',
        original.available + good,
      ),
    ]);
  }
}
