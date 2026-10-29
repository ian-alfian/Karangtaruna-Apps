import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'action_dialogs.dart';
import 'demo_data.dart';
import 'firebase_login.dart';
import 'ui.dart';

class CloudConnectionPage extends StatefulWidget {
  /// Membuat kelola koneksi bendahara di Firebase.
  const CloudConnectionPage({super.key, required this.store});
  final DemoStore store;

  /// Membuat state interaktif untuk kelola koneksi bendahara di Firebase.
  @override
  State<CloudConnectionPage> createState() => _CloudConnectionPageState();
}

class _CloudConnectionPageState extends State<CloudConnectionPage> {
  final db = FirebaseFirestore.instance;
  final search = TextEditingController();
  Map<String, dynamic>? overview;
  String? error;
  bool busy = false;
  int tab = 0;

  /// Menyiapkan state dan pendengar awal saat widget dibuat.
  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  /// Memuat ulang data dan status terbaru.
  Future<void> refresh() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('Sesi Bendahara berakhir.');
      final profile = await db.collection('users').doc(uid).get();
      final actor = profile.data();
      if (actor == null ||
          actor['role'] != 'bendahara' ||
          actor['isActive'] != true) {
        throw StateError('Akun Bendahara tidak aktif.');
      }
      final organizationId = actor['organizationId'] as String;
      final snapshots = await Future.wait([
        db
            .collection('users')
            .where('organizationId', isEqualTo: organizationId)
            .get(),
        db
            .collection('treasurerConnectionRequests')
            .where('organizationId', isEqualTo: organizationId)
            .get(),
      ]);
      final people = snapshots[0].docs
          .where(
            (doc) =>
                doc.id != uid &&
                doc.data()['role'] == 'bendahara' &&
                doc.data()['isActive'] == true,
          )
          .map(
            (doc) => {
              'uid': doc.id,
              'name': doc.data()['name'],
              'email': doc.data()['email'],
            },
          )
          .toList();
      final requests = snapshots[1].docs
          .where(
            (doc) =>
                doc.data()['requesterId'] == uid ||
                doc.data()['recipientId'] == uid,
          )
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      if (mounted) {
        setState(() => overview = {'treasurers': people, 'requests': requests});
      }
    } catch (exception) {
      if (mounted) {
        setState(() => error = _connectionError(exception));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Menjalankan tindakan permintaan atau pemutusan koneksi.
  Future<void> act(String action, String targetUid) async {
    if (busy) return;
    if (action == 'disconnect') {
      final confirmed = await confirmAction(
        context,
        title: 'Putuskan koneksi?',
        message: 'Saldo dan transaksi masing-masing Bendahara tidak berubah.',
        confirmLabel: 'Putuskan',
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid == targetUid) {
        throw StateError('Bendahara tujuan tidak valid.');
      }
      final actorDoc = await db.collection('users').doc(uid).get();
      final actor = actorDoc.data();
      final targetDoc = await db.collection('users').doc(targetUid).get();
      final target = targetDoc.data();
      if (actor == null ||
          actor['role'] != 'bendahara' ||
          actor['isActive'] != true ||
          target == null ||
          target['role'] != 'bendahara' ||
          target['isActive'] != true ||
          actor['organizationId'] != target['organizationId']) {
        throw StateError('Bendahara tujuan tidak ditemukan.');
      }
      final organizationId = actor['organizationId'] as String;
      final pair = [uid, targetUid]..sort();
      final pairId = '${organizationId}__${pair[0]}__${pair[1]}';
      final requestRef = db
          .collection('treasurerConnectionRequests')
          .doc(pairId);
      final connectionRef = db.collection('treasurerConnections').doc(pairId);
      final notificationRef = db.collection('notifications').doc();
      await db.runTransaction((transaction) async {
        final request = (await transaction.get(requestRef)).data();
        final connection = (await transaction.get(connectionRef)).data();
        if (action == 'request') {
          if (request?['status'] == 'pending' ||
              connection?['active'] == true) {
            throw StateError('Permintaan atau koneksi sudah ada.');
          }
          transaction.set(requestRef, {
            'organizationId': organizationId,
            'requesterId': uid,
            'recipientId': targetUid,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'respondedAt': null,
          });
        } else if (action == 'accept' || action == 'reject') {
          if (request?['status'] != 'pending' ||
              request?['recipientId'] != uid ||
              request?['requesterId'] != targetUid) {
            throw StateError('Permintaan masuk tidak ditemukan.');
          }
          transaction.update(requestRef, {
            'status': action == 'accept' ? 'accepted' : 'rejected',
            'respondedAt': FieldValue.serverTimestamp(),
          });
          if (action == 'accept') {
            transaction.set(connectionRef, {
              'organizationId': organizationId,
              'holderIds': pair,
              'active': true,
              'joinedAt': FieldValue.serverTimestamp(),
            });
          }
        } else if (action == 'cancel') {
          if (request?['status'] != 'pending' ||
              request?['requesterId'] != uid ||
              request?['recipientId'] != targetUid) {
            throw StateError('Permintaan terkirim tidak ditemukan.');
          }
          transaction.update(requestRef, {
            'status': 'cancelled',
            'respondedAt': FieldValue.serverTimestamp(),
          });
        } else if (action == 'disconnect') {
          if (request?['status'] != 'accepted' ||
              connection?['active'] != true ||
              !pair.contains(uid)) {
            throw StateError('Koneksi aktif tidak ditemukan.');
          }
          transaction.update(requestRef, {
            'status': 'disconnected',
            'respondedAt': FieldValue.serverTimestamp(),
          });
          transaction.update(connectionRef, {
            'active': false,
            'disconnectedAt': FieldValue.serverTimestamp(),
          });
        } else {
          throw ArgumentError('Tindakan koneksi tidak valid.');
        }
        final title = switch (action) {
          'request' => 'Permintaan Koneksi Bendahara',
          'accept' => 'Koneksi diterima',
          'reject' => 'Koneksi ditolak',
          'cancel' => 'Permintaan dibatalkan',
          _ => 'Koneksi diputuskan',
        };
        transaction.set(notificationRef, {
          'organizationId': organizationId,
          'recipientId': targetUid,
          'sourceUid': uid,
          'category': 'connection',
          'title': title,
          'body':
              '${actor['name'] ?? 'Bendahara'} memperbarui koneksi Bendahara.',
          'referenceId': pairId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) {
        setState(() => busy = false);
        await refresh();
        if (mounted) {
          await showActionNotice(
            context,
            title: 'Berhasil',
            message: switch (action) {
              'request' => 'Permintaan koneksi telah dikirim.',
              'accept' => 'Koneksi Bendahara diterima.',
              'reject' => 'Permintaan koneksi ditolak.',
              'cancel' => 'Permintaan koneksi dibatalkan.',
              _ => 'Koneksi Bendahara diputuskan.',
            },
          );
        }
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = _connectionError(exception);
          busy = false;
        });
        await showActionNotice(
          context,
          title: 'Tindakan gagal',
          message: error!,
          error: true,
        );
      }
    }
  }

  /// Menerjemahkan kesalahan koneksi bendahara menjadi pesan.
  String _connectionError(Object error) {
    if (error is StateError || error is ArgumentError) {
      return error.toString().replaceFirst(
        RegExp(r'^(Bad state|Invalid argument): '),
        '',
      );
    }
    return firebaseLoginError(error);
  }

  /// Mengambil daftar orang yang tersedia untuk koneksi.
  List<Map<String, dynamic>> get people =>
      (overview?['treasurers'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
  /// Mengambil daftar permintaan koneksi.
  List<Map<String, dynamic>> get requests =>
      (overview?['requests'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
  /// Menyusun tampilan kelola koneksi bendahara di Firebase.
  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final personById = {for (final person in people) person['uid']: person};
    final connected = requests
        .where((item) => item['status'] == 'accepted')
        .toList();
    final pending = requests
        .where((item) => item['status'] == 'pending')
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koneksi Bendahara'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            onPressed: busy ? null : refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: PageFrame(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          if (overview == null && busy)
            const Center(child: CircularProgressIndicator()),
          if (overview != null) ...[
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Koneksi')),
                ButtonSegment(value: 1, label: Text('Cari')),
                ButtonSegment(value: 2, label: Text('Permintaan')),
              ],
              selected: {tab},
              onSelectionChanged: (value) => setState(() => tab = value.first),
            ),
            const SizedBox(height: 20),
            if (tab == 0) ...[
              AnimatedBuilder(
                animation: widget.store,
                builder: (context, _) => MoneyCard(
                  label: 'Total Kas Terkoneksi',
                  amount: widget.store.connectedCash,
                  subtitle: 'Saldo Anda dan Bendahara terhubung',
                ),
              ),
              const SizedBox(height: 20),
              if (connected.isEmpty)
                const Text('Belum ada Bendahara yang terhubung.'),
              for (final connection in connected)
                Builder(
                  builder: (context) {
                    final uid =
                        (connection['requesterId'] == currentUid
                                ? connection['recipientId']
                                : connection['requesterId'])
                            as String;
                    final other = personById[uid];
                    return _ConnectionTile(
                      title: other?['name'] as String? ?? 'Bendahara',
                      subtitle: rupiah(widget.store.balanceFor(uid)),
                      actionLabel: 'Putuskan',
                      onAction: busy ? null : () => act('disconnect', uid),
                    );
                  },
                ),
            ] else if (tab == 1) ...[
              TextField(
                controller: search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari nama atau email Bendahara',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              for (final person in people.where((person) {
                final query = search.text.trim().toLowerCase();
                return query.isEmpty ||
                    '${person['name']} ${person['email']}'
                        .toLowerCase()
                        .contains(query);
              }))
                _ConnectionTile(
                  title: person['name'] as String? ?? 'Bendahara',
                  subtitle: person['email'] as String? ?? '',
                  actionLabel: 'Hubungkan',
                  onAction: busy
                      ? null
                      : () => act('request', person['uid'] as String),
                ),
              if (people.isEmpty)
                const Text('Belum ada Bendahara lain dalam organisasi.'),
            ] else ...[
              if (pending.isEmpty) const Text('Tidak ada permintaan menunggu.'),
              for (final item in pending)
                Builder(
                  builder: (context) {
                    final isIncoming = item['recipientId'] == currentUid;
                    final otherUid =
                        (isIncoming ? item['requesterId'] : item['recipientId'])
                            as String;
                    final other = personById[otherUid];
                    return _ConnectionTile(
                      title: other?['name'] as String? ?? 'Bendahara',
                      subtitle: isIncoming
                          ? 'Permintaan masuk'
                          : 'Menunggu persetujuan',
                      actionLabel: isIncoming ? 'Terima' : 'Batalkan',
                      onAction: busy
                          ? null
                          : () =>
                                act(isIncoming ? 'accept' : 'cancel', otherUid),
                      secondaryLabel: isIncoming ? 'Tolak' : null,
                      onSecondary: isIncoming && !busy
                          ? () => act('reject', otherUid)
                          : null,
                    );
                  },
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  /// Membuat satu entri koneksi.
  const _ConnectionTile({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Menyusun tampilan satu entri koneksi.
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person_outline)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
          if (secondaryLabel != null)
            TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}
