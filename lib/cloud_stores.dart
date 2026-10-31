import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'demo_data.dart';
import 'connection_scope.dart';
import 'firebase_login.dart';
import 'inventory_store.dart';

/// Membaca tanggal dari nilai Firestore dengan nilai cadangan yang aman.
DateTime _date(Object? value) => switch (value) {
  Timestamp timestamp => timestamp.toDate(),
  String text => DateTime.parse(text),
  _ => DateTime.fromMillisecondsSinceEpoch(0),
};

/// Mengubah nilai Firestore menjadi bilangan bulat.
int _number(Object? value) => value is num ? value.toInt() : 0;

/// Menyusun pesan kesalahan dari operasi Firestore.
String _message(Object error) {
  if (error is FirebaseException) {
    return 'Koneksi database gagal: ${error.message ?? error.code}';
  }
  return 'Data gagal disimpan. Coba lagi.';
}

class CloudFinanceStore extends DemoStore {
  /// Membuat data keuangan dari Firestore.
  CloudFinanceStore(this.profile, {FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;

  final FirebaseUserProfile profile;
  final FirebaseFirestore db;
  final List<CashTransaction> _remoteTransactions = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _connectionSubscription;
  Set<String> _visibleHolders = {};

  /// Menandai apakah store memakai Firestore atau data lokal.
  @override
  bool get isRemote => true;
  /// Mengambil ID pemilik kas saat ini.
  @override
  String get currentHolderId => profile.uid;
  /// Mengambil nama pemilik kas saat ini.
  @override
  String get currentHolderName => profile.name;
  /// Mengambil daftar bendahara yang dapat ditampilkan.
  @override
  Map<String, String> get holders => {
    if (_visibleHolders.contains(profile.uid)) profile.uid: profile.name,
    for (final transaction in _remoteTransactions.where(
      (item) => _visibleHolders.contains(item.holderId),
    ))
      transaction.holderId: transaction.holderName,
  };

  /// Mengambil daftar transaksi yang dapat ditampilkan.
  @override
  List<CashTransaction> get transactions => List.unmodifiable(
    _remoteTransactions.reversed.where(
      (item) => _visibleHolders.contains(item.holderId),
    ),
  );

  /// Menghitung saldo milik bendahara tertentu.
  @override
  int balanceFor(String holderId) => _remoteTransactions
      .where((transaction) => transaction.holderId == holderId)
      .fold(
        0,
        (total, transaction) =>
            total +
            (transaction.type == TransactionType.income
                ? transaction.amount
                : -transaction.amount),
      );

  /// Menjumlahkan kas dari bendahara yang terhubung.
  @override
  int get connectedCash => _remoteTransactions
      .where((item) => _visibleHolders.contains(item.holderId))
      .fold(
        0,
        (total, transaction) =>
            total +
            (transaction.type == TransactionType.income
                ? transaction.amount
                : -transaction.amount),
      );

  /// Menjumlahkan transaksi menurut jenis dan rentang tanggal.
  @override
  int totalFor(TransactionType type, DateTime start, DateTime end) =>
      _remoteTransactions
          .where(
            (transaction) =>
                transaction.type == type &&
                _visibleHolders.contains(transaction.holderId) &&
                !transaction.date.isBefore(start) &&
                transaction.date.isBefore(end),
          )
          .fold(0, (total, transaction) => total + transaction.amount);

  /// Memuat data tersimpan dan menyiapkan pendengar perubahan.
  @override
  Future<void> load() async {
    final query = db
        .collection('financialTransactions')
        .where('organizationId', isEqualTo: profile.organizationId);
    final initial = await query.get();
    _accept(initial);
    _subscription = query.snapshots().listen(_accept);
    final connections = db
        .collection('treasurerConnections')
        .where('organizationId', isEqualTo: profile.organizationId);
    final initialConnections = await connections.get();
    _acceptConnections(initialConnections);
    _connectionSubscription = connections.snapshots().listen(
      _acceptConnections,
    );
  }

  /// Memperbarui koneksi bendahara dari snapshot Firestore.
  void _acceptConnections(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final pairs = snapshot.docs
        .where((doc) => doc.data()['active'] == true)
        .map(
          (doc) => List<String>.from(doc.data()['holderIds'] as List? ?? []),
        );
    _visibleHolders = connectedHolderIds(
      role: profile.role,
      currentUid: profile.uid,
      activePairs: pairs,
    );
    notifyListeners();
  }

  /// Memperbarui daftar transaksi dari snapshot Firestore.
  void _accept(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _remoteTransactions
      ..clear()
      ..addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          return CashTransaction(
            id: doc.id,
            title: data['title'] as String? ?? '',
            category: data['category'] as String? ?? 'Lainnya',
            holderId: data['holderUid'] as String? ?? '',
            holderName: data['holderName'] as String? ?? '',
            type: data['type'] == 'expense'
                ? TransactionType.expense
                : TransactionType.income,
            amount: _number(data['amount']),
            date: _date(data['transactionDate']),
            note: data['note'] as String? ?? '',
          );
        }),
      );
    _remoteTransactions.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  /// Memvalidasi lalu menyimpan transaksi pemasukan atau pengeluaran.
  @override
  Future<void> addTransaction({
    required TransactionType type,
    required String title,
    required String category,
    required int amount,
    required DateTime date,
    String note = '',
  }) async {
    if (profile.role != AppRole.bendahara) {
      throw StateError('Hanya Bendahara yang dapat mencatat transaksi.');
    }
    if (amount <= 0 || title.trim().isEmpty || category.trim().isEmpty) {
      throw ArgumentError('Lengkapi transaksi dengan nominal yang valid.');
    }
    final accountRef = db.collection('cashAccounts').doc(profile.uid);
    final ledgerRef = db.collection('financialTransactions').doc();
    try {
      await db.runTransaction((transaction) async {
        final account = await transaction.get(accountRef);
        final oldBalance = (account.data()?['balance'] as num?)?.toInt() ?? 0;
        final nextBalance =
            oldBalance + (type == TransactionType.income ? amount : -amount);
        if (nextBalance < 0) throw StateError('Saldo tidak mencukupi.');
        transaction.set(accountRef, {
          'organizationId': profile.organizationId,
          'holderUid': profile.uid,
          'holderName': profile.name,
          'balance': nextBalance,
          'lastTransactionId': ledgerRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(ledgerRef, {
          'organizationId': profile.organizationId,
          'holderUid': profile.uid,
          'holderName': profile.name,
          'type': type.name,
          'title': title.trim(),
          'category': category.trim(),
          'amount': amount,
          'note': note.trim(),
          'transactionDate': Timestamp.fromDate(date),
          'createdBy': profile.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      if (error is StateError) rethrow;
      throw StateError(_message(error));
    }
  }

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    _subscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

class CloudInventoryStore extends InventoryStore {
  /// Membuat data inventaris dari Firestore.
  CloudInventoryStore(this.profile, {FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;

  final FirebaseUserProfile profile;
  final FirebaseFirestore db;
  final List<InventoryItem> _remoteItems = [];
  final List<Borrowing> _remoteBorrowings = [];
  final List<InventoryMovement> _remoteMovements = [];
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _subscriptions = [];

  /// Menandai apakah store memakai Firestore atau data lokal.
  @override
  bool get isRemote => true;
  /// Mengambil daftar barang aktif.
  @override
  List<InventoryItem> get items =>
      List.unmodifiable(
        _remoteItems.where(
          (item) =>
              !item.archived &&
              (profile.role == AppRole.admin || !item.hidden),
        ),
      );
  /// Mengambil data legacy yang masih bertanda arsip.
  @override
  List<InventoryItem> get archivedItems =>
      List.unmodifiable(_remoteItems.where((item) => item.archived));
  /// Mengambil barang yang di-hide untuk dikelola Admin.
  @override
  List<InventoryItem> get hiddenItems => List.unmodifiable(
    _remoteItems.where((item) => !item.archived && item.hidden),
  );
  /// Mengambil daftar peminjaman.
  @override
  List<Borrowing> get borrowings =>
      List.unmodifiable(_remoteBorrowings.reversed);
  /// Mengambil riwayat perubahan stok untuk satu barang.
  @override
  List<InventoryMovement> movementsFor(String code) => List.unmodifiable(
    _remoteMovements.where((item) => item.itemCode == code).toList().reversed,
  );
  /// Mencari barang berdasarkan kode inventaris.
  @override
  InventoryItem itemFor(String code) =>
      _remoteItems.firstWhere((item) => item.code == code);

  /// Mengambil foto yang tersimpan untuk kode barang.
  @override
  Future<String?> photoFor(String code) async {
    final snapshot = await db
        .collection('inventoryPhotos')
        .doc('${profile.organizationId}__${code.trim().toUpperCase()}')
        .get();
    return snapshot.data()?['imageBase64'] as String?;
  }

  /// Memuat data tersimpan dan menyiapkan pendengar perubahan.
  @override
  Future<void> load() async {
    final itemsCollection = db.collection('inventoryItems').where(
      'organizationId',
      isEqualTo: profile.organizationId,
    );
    final itemsQuery = profile.role == AppRole.admin
        ? itemsCollection
        : itemsCollection.where('hidden', isEqualTo: false);
    final borrowingQuery = db
        .collection('borrowings')
        .where('organizationId', isEqualTo: profile.organizationId);
    final movementQuery = db
        .collection('inventoryMovements')
        .where('organizationId', isEqualTo: profile.organizationId);
    final snapshots = await Future.wait([
      itemsQuery.get(),
      borrowingQuery.get(),
      movementQuery.get(),
    ]);
    _acceptItems(snapshots[0]);
    _acceptBorrowings(snapshots[1]);
    _acceptMovements(snapshots[2]);
    _subscriptions.addAll([
      itemsQuery.snapshots().listen(_acceptItems),
      borrowingQuery.snapshots().listen(_acceptBorrowings),
      movementQuery.snapshots().listen(_acceptMovements),
    ]);
  }

  /// Memperbarui daftar barang dari snapshot Firestore.
  void _acceptItems(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _remoteItems
      ..clear()
      ..addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          return InventoryItem(
            code: data['code'] as String? ?? doc.id,
            name: data['name'] as String? ?? '',
            category: data['category'] as String? ?? 'Lainnya',
            location: data['location'] as String? ?? '',
            total: _number(data['total']),
            available: _number(data['available']),
            damaged: _number(data['damaged']),
            lost: _number(data['lost']),
            archived: data['archived'] == true,
            hidden: data['hidden'] == true,
          );
        }),
      );
    _remoteItems.sort((a, b) => a.code.compareTo(b.code));
    notifyListeners();
  }

  /// Memperbarui peminjaman dari snapshot Firestore.
  void _acceptBorrowings(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _remoteBorrowings
      ..clear()
      ..addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          return Borrowing(
            id: doc.id,
            itemCode: data['itemCode'] as String? ?? '',
            borrower: data['borrower'] as String? ?? '',
            quantity: _number(data['quantity']),
            returned: _number(data['returned']),
            borrowedAt: _date(data['borrowedAt']),
            dueAt: _date(data['dueAt']),
            note: data['note'] as String? ?? '',
          );
        }),
      );
    _remoteBorrowings.sort((a, b) => a.borrowedAt.compareTo(b.borrowedAt));
    notifyListeners();
  }

  /// Memperbarui riwayat perubahan stok dari snapshot Firestore.
  void _acceptMovements(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _remoteMovements
      ..clear()
      ..addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          return InventoryMovement(
            id: doc.id,
            itemCode: data['itemCode'] as String? ?? '',
            action: data['action'] as String? ?? '',
            reason: data['reason'] as String? ?? '',
            beforeAvailable: _number(data['beforeAvailable']),
            afterAvailable: _number(data['afterAvailable']),
            at: _date(data['at']),
          );
        }),
      );
    _remoteMovements.sort((a, b) => a.at.compareTo(b.at));
    notifyListeners();
  }

  /// Memastikan tindakan inventaris dijalankan oleh Admin.
  void _requireAdmin() {
    if (profile.role != AppRole.admin) {
      throw StateError('Hanya Admin yang dapat mengubah inventaris.');
    }
  }

  /// Membuat referensi dokumen Firestore untuk satu barang.
  DocumentReference<Map<String, dynamic>> _itemRef(String code) {
    final normalized = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9_-]{1,50}$').hasMatch(normalized)) {
      throw ArgumentError('Kode barang hanya boleh huruf, angka, - dan _.');
    }
    return db
        .collection('inventoryItems')
        .doc('${profile.organizationId}__$normalized');
  }

  /// Membuat catatan perubahan stok dengan informasi waktu dan alasan.
  Map<String, Object?> _movement({
    required String code,
    required String action,
    required String reason,
    required int before,
    required int after,
  }) => {
    'organizationId': profile.organizationId,
    'itemCode': code,
    'action': action,
    'reason': reason,
    'beforeAvailable': before,
    'afterAvailable': after,
    'actorUid': profile.uid,
    'at': FieldValue.serverTimestamp(),
  };

  /// Menjalankan operasi Firestore lalu meneruskan kesalahan yang relevan.
  Future<void> _perform(Future<void> Function() operation) async {
    _requireAdmin();
    try {
      await operation();
    } catch (error) {
      if (error is StateError || error is ArgumentError) rethrow;
      throw StateError(_message(error));
    }
  }

  /// Memvalidasi dan menyimpan barang baru beserta stok serta fotonya.
  @override
  Future<void> addItem({
    required String code,
    required String name,
    required String category,
    required String location,
    required int quantity,
    String? photoBase64,
  }) => _perform(() async {
    if (quantity <= 0 ||
        name.trim().isEmpty ||
        category.trim().isEmpty ||
        location.trim().isEmpty) {
      throw ArgumentError('Lengkapi data barang dan stok awal.');
    }
    final ref = _itemRef(code);
    final normalized = code.trim().toUpperCase();
    final movementRef = db.collection('inventoryMovements').doc();
    final photoRef = db.collection('inventoryPhotos').doc(ref.id);
    await db.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) {
        throw StateError('Kode barang sudah digunakan.');
      }
      transaction.set(ref, {
        'organizationId': profile.organizationId,
        'code': normalized,
        'name': name.trim(),
        'category': category.trim(),
        'location': location.trim(),
        'total': quantity,
        'available': quantity,
        'damaged': 0,
        'lost': 0,
        'archived': false,
        'hidden': false,
        'createdBy': profile.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (photoBase64 != null) {
        transaction.set(photoRef, {
          'organizationId': profile.organizationId,
          'itemCode': normalized,
          'format': 'jpeg',
          'imageBase64': photoBase64,
          'updatedBy': profile.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.set(
        movementRef,
        _movement(
          code: normalized,
          action: 'Tambah barang',
          reason: 'Stok awal',
          before: 0,
          after: quantity,
        ),
      );
    });
  });

  /// Memperbarui informasi dan foto barang yang sudah ada.
  @override
  Future<void> editItem(
    String code, {
    required String name,
    required String category,
    required String location,
    String? photoBase64,
  }) => _perform(() async {
    if (name.trim().isEmpty ||
        category.trim().isEmpty ||
        location.trim().isEmpty) {
      throw ArgumentError('Nama, kategori, dan lokasi wajib diisi.');
    }
    final ref = _itemRef(code);
    final movementRef = db.collection('inventoryMovements').doc();
    final photoRef = db.collection('inventoryPhotos').doc(ref.id);
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final item = snapshot.data();
      if (item == null || item['archived'] == true) {
        throw StateError('Barang tidak ditemukan atau sudah dihapus.');
      }
      transaction.update(ref, {
        'name': name.trim(),
        'category': category.trim(),
        'location': location.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (photoBase64 != null) {
        transaction.set(photoRef, {
          'organizationId': profile.organizationId,
          'itemCode': code.trim().toUpperCase(),
          'format': 'jpeg',
          'imageBase64': photoBase64,
          'updatedBy': profile.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      final available = _number(item['available']);
      transaction.set(
        movementRef,
        _movement(
          code: code.trim().toUpperCase(),
          action: 'Edit barang',
          reason: 'Metadata diperbarui',
          before: available,
          after: available,
        ),
      );
    });
  });

  /// Menambah atau mengurangi stok dan mencatat alasannya.
  @override
  Future<void> adjustStock(String code, int delta, String reason) =>
      _perform(() async {
        if (delta == 0 || reason.trim().isEmpty) {
          throw ArgumentError('Jumlah dan alasan perubahan wajib diisi.');
        }
        final ref = _itemRef(code);
        final movementRef = db.collection('inventoryMovements').doc();
        await db.runTransaction((transaction) async {
          final item = (await transaction.get(ref)).data();
          if (item == null || item['archived'] == true) {
            throw StateError('Barang tidak ditemukan atau sudah dihapus.');
          }
          final before = _number(item['available']);
          if (before + delta < 0) {
            throw StateError('Stok tersedia tidak mencukupi.');
          }
          transaction.update(ref, {
            'total': _number(item['total']) + delta,
            'available': before + delta,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          transaction.set(
            movementRef,
            _movement(
              code: code.trim().toUpperCase(),
              action: 'Update stok',
              reason: reason.trim(),
              before: before,
              after: before + delta,
            ),
          );
        });
      });

  /// Menyembunyikan barang dari Bendahara dan Anggota tanpa menghapus data.
  @override
  Future<void> hideItem(String code) => _perform(() async {
    final ref = _itemRef(code);
    final movementRef = db.collection('inventoryMovements').doc();
    await db.runTransaction((transaction) async {
      final item = (await transaction.get(ref)).data();
      if (item == null || item['archived'] == true || item['hidden'] == true) {
        throw StateError('Barang tidak ditemukan atau sudah disembunyikan.');
      }
      transaction.update(ref, {
        'hidden': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final before = _number(item['available']);
      transaction.set(
        movementRef,
        _movement(
          code: code.trim().toUpperCase(),
          action: 'Hide barang',
          reason: 'Disembunyikan oleh Admin',
          before: before,
          after: before,
        ),
      );
    });
  });

  /// Menampilkan kembali barang yang sebelumnya di-hide.
  @override
  Future<void> showItem(String code) => _perform(() async {
    final ref = _itemRef(code);
    final movementRef = db.collection('inventoryMovements').doc();
    await db.runTransaction((transaction) async {
      final item = (await transaction.get(ref)).data();
      if (item == null || item['archived'] == true || item['hidden'] != true) {
        throw StateError('Barang tidak ditemukan atau sudah ditampilkan.');
      }
      transaction.update(ref, {
        'hidden': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final before = _number(item['available']);
      transaction.set(
        movementRef,
        _movement(
          code: code.trim().toUpperCase(),
          action: 'Tampilkan barang',
          reason: 'Ditampilkan oleh Admin',
          before: before,
          after: before,
        ),
      );
    });
  });

  /// Menghapus barang dan foto secara permanen setelah memastikan tidak dipinjam.
  @override
  Future<void> deleteItem(String code) => _perform(() async {
    final ref = _itemRef(code);
    final photoRef = db.collection('inventoryPhotos').doc(ref.id);
    await db.runTransaction((transaction) async {
      final item = (await transaction.get(ref)).data();
      final photo = await transaction.get(photoRef);
      if (item == null) throw StateError('Barang tidak ditemukan.');
      final borrowed =
          _number(item['total']) -
          _number(item['available']) -
          _number(item['damaged']) -
          _number(item['lost']);
      if (borrowed > 0) {
        throw StateError('Selesaikan peminjaman aktif sebelum menghapus barang.');
      }
      transaction.delete(ref);
      if (photo.exists) transaction.delete(photoRef);
    });
  });

  /// Kompatibilitas data lama: arsip lama diperlakukan sebagai hide.
  @Deprecated('Gunakan hideItem.')
  @override
  Future<void> archiveItem(String code) => hideItem(code);

  /// Mencatat peminjaman dan mengurangi stok tersedia.
  @override
  Future<void> borrowItem({
    required String code,
    required String borrower,
    required int quantity,
    required DateTime dueAt,
    String note = '',
  }) => _perform(() async {
    if (borrower.trim().isEmpty ||
        quantity <= 0 ||
        dueAt.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      throw ArgumentError('Peminjam, jumlah, atau tanggal tidak valid.');
    }
    final ref = _itemRef(code);
    final borrowingRef = db.collection('borrowings').doc();
    final movementRef = db.collection('inventoryMovements').doc();
    await db.runTransaction((transaction) async {
      final item = (await transaction.get(ref)).data();
      if (item == null || item['archived'] == true) {
        throw StateError('Barang tidak ditemukan atau sudah dihapus.');
      }
      final before = _number(item['available']);
      if (before < quantity) throw StateError('Stok tersedia tidak mencukupi.');
      transaction.update(ref, {
        'available': before - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(borrowingRef, {
        'organizationId': profile.organizationId,
        'itemCode': code.trim().toUpperCase(),
        'borrower': borrower.trim(),
        'quantity': quantity,
        'returned': 0,
        'dueAt': Timestamp.fromDate(dueAt),
        'note': note.trim(),
        'borrowedAt': FieldValue.serverTimestamp(),
        'createdBy': profile.uid,
      });
      transaction.set(
        movementRef,
        _movement(
          code: code.trim().toUpperCase(),
          action: 'Peminjaman',
          reason: 'Dipinjam oleh ${borrower.trim()}',
          before: before,
          after: before - quantity,
        ),
      );
    });
  });

  /// Mencatat pengembalian serta memperbarui stok, kerusakan, atau kehilangan.
  @override
  Future<void> returnItem(
    String borrowingId, {
    required int good,
    required int damaged,
    required int lost,
    required String note,
  }) => _perform(() async {
    final count = good + damaged + lost;
    if (good < 0 || damaged < 0 || lost < 0 || count <= 0) {
      throw ArgumentError('Jumlah kembali tidak valid.');
    }
    if ((damaged > 0 || lost > 0) && note.trim().isEmpty) {
      throw ArgumentError('Catatan wajib untuk barang rusak atau hilang.');
    }
    final borrowingRef = db.collection('borrowings').doc(borrowingId);
    final returnRef = db.collection('borrowingReturns').doc();
    final movementRef = db.collection('inventoryMovements').doc();
    await db.runTransaction((transaction) async {
      final borrowing = (await transaction.get(borrowingRef)).data();
      if (borrowing == null ||
          borrowing['organizationId'] != profile.organizationId) {
        throw StateError('Peminjaman tidak ditemukan.');
      }
      final code = borrowing['itemCode'] as String;
      final itemRef = _itemRef(code);
      final item = (await transaction.get(itemRef)).data();
      if (item == null || item['archived'] == true) {
        throw StateError('Barang tidak ditemukan atau sudah dihapus.');
      }
      final remaining =
          _number(borrowing['quantity']) - _number(borrowing['returned']);
      if (count > remaining) {
        throw StateError('Jumlah kembali melebihi pinjaman.');
      }
      final before = _number(item['available']);
      transaction.update(itemRef, {
        'available': before + good,
        'damaged': _number(item['damaged']) + damaged,
        'lost': _number(item['lost']) + lost,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(borrowingRef, {
        'returned': _number(borrowing['returned']) + count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(returnRef, {
        'organizationId': profile.organizationId,
        'borrowingId': borrowingId,
        'itemCode': code,
        'good': good,
        'damaged': damaged,
        'lost': lost,
        'note': note.trim(),
        'returnedAt': FieldValue.serverTimestamp(),
        'returnedBy': profile.uid,
      });
      transaction.set(
        movementRef,
        _movement(
          code: code,
          action: 'Pengembalian',
          reason: 'Baik $good, rusak $damaged, hilang $lost. ${note.trim()}',
          before: before,
          after: before + good,
        ),
      );
    });
  });

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
