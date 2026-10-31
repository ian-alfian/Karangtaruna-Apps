import 'package:flutter/material.dart';

import 'action_dialogs.dart';
import 'demo_data.dart';
import 'inventory_forms.dart';
import 'inventory_photo.dart';
import 'inventory_store.dart';
import 'ui.dart';

class InventoryScreen extends StatefulWidget {
  /// Membuat halaman daftar inventaris.
  const InventoryScreen({
    super.key,
    required this.role,
    required this.store,
    required this.onNotifications,
  });
  final AppRole role;
  final InventoryStore store;
  final VoidCallback onNotifications;

  /// Membuat state interaktif untuk halaman daftar inventaris.
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String category = 'Semua';
  String query = '';

  /// Menyusun tampilan halaman daftar inventaris.
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => _buildContent(context),
  );

  /// Menyusun daftar dan ringkasan inventaris berdasarkan filter.
  Widget _buildContent(BuildContext context) {
    final sourceItems = widget.store.items
        .where((item) => widget.role == AppRole.admin || !item.hidden)
        .toList();
    final items = sourceItems
        .where(
          (item) =>
              (category == 'Semua' || item.category == category) &&
              item.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    final available = sourceItems.fold<int>(
      0,
      (sum, item) => sum + item.available,
    );
    final borrowed = sourceItems.fold<int>(
      0,
      (sum, item) => sum + item.borrowed,
    );
    return PageFrame(
      children: [
        RoleHeader(
          role: widget.role,
          title: 'Inventaris',
          onNotifications: widget.onNotifications,
        ),
        if (!widget.store.isRemote) const DemoBanner(),
        if (widget.role == AppRole.admin) ...[
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ItemFormPage(store: widget.store),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Barang'),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Cari barang',
          ),
        ),
        const SizedBox(height: 13),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in [
                'Semua',
                'Elektronik',
                'Peralatan',
                'Kegiatan',
                'Lainnya',
              ]) ...[
                ChoiceChip(
                  label: Text(option),
                  selected: category == option,
                  onSelected: (_) => setState(() => category = option),
                  selectedColor: AppColors.blue,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: category == option ? Colors.white : AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  side: BorderSide.none,
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            StatTile(
              value:
                '${sourceItems.fold<int>(0, (sum, item) => sum + item.total)}',
              label: 'Total unit',
            ),
            const SizedBox(width: 8),
            StatTile(value: '$available', label: 'Tersedia', highlight: true),
            const SizedBox(width: 8),
            StatTile(value: '$borrowed', label: 'Dipinjam'),
          ],
        ),
        const SizedBox(height: 27),
        SectionHeading(title: 'Daftar Barang', action: '${items.length} jenis'),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: AppColors.muted,
                ),
                SizedBox(height: 8),
                Text(
                  'Barang tidak ditemukan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          )
        else
          for (final item in items) ...[
            _InventoryCard(
              item: item,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InventoryDetailPage(
                    item: item,
                    role: widget.role,
                    store: widget.store,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  BorrowingHistoryPage(role: widget.role, store: widget.store),
            ),
          ),
          child: const Text('Riwayat Peminjaman'),
        ),
        if (widget.role == AppRole.admin) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HiddenItemsPage(store: widget.store),
              ),
            ),
            child: const Text('Barang Disembunyikan'),
          ),
        ],
      ],
    );
  }
}

/// Memilih ikon berdasarkan kategori barang.
IconData _iconFor(InventoryItem item) => switch (item.category) {
  'Elektronik' => Icons.speaker_rounded,
  'Peralatan' => Icons.chair_alt_rounded,
  'Kegiatan' => Icons.celebration_rounded,
  _ => Icons.inventory_2_rounded,
};

class _InventoryCard extends StatelessWidget {
  /// Membuat kartu satu barang inventaris.
  const _InventoryCard({required this.item, required this.onTap});
  final InventoryItem item;
  final VoidCallback onTap;

  /// Menyusun tampilan kartu satu barang inventaris.
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(item), color: AppColors.blue, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} · Baik',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.hidden)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1D6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Hide',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
          const Divider(height: 25, color: AppColors.border),
          Row(
            children: [
              _StockMetric(label: 'Total', value: '${item.total} unit'),
              _StockMetric(
                label: 'Tersedia',
                value: '${item.available} unit',
                highlight: true,
              ),
              _StockMetric(label: 'Dipinjam', value: '${item.borrowed} unit'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StockMetric extends StatelessWidget {
  /// Membuat angka ringkasan stok.
  const _StockMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool highlight;

  /// Menyusun tampilan angka ringkasan stok.
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.blue : AppColors.navy,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class InventoryDetailPage extends StatefulWidget {
  /// Membuat detail barang inventaris.
  const InventoryDetailPage({
    super.key,
    required this.item,
    required this.role,
    required this.store,
  });
  final InventoryItem item;
  final AppRole role;
  final InventoryStore store;

  /// Membuat state interaktif untuk detail barang inventaris.
  @override
  State<InventoryDetailPage> createState() => _InventoryDetailPageState();
}

class _InventoryDetailPageState extends State<InventoryDetailPage> {
  late Future<String?> photo;

  /// Menyiapkan state dan pendengar awal saat widget dibuat.
  @override
  void initState() {
    super.initState();
    photo = widget.store.photoFor(widget.item.code);
  }

  /// Memperbarui informasi dan foto barang yang sudah ada.
  Future<void> editItem() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ItemFormPage(
          store: widget.store,
          existing: widget.store.itemFor(widget.item.code),
        ),
      ),
    );
    if (mounted) {
      setState(() => photo = widget.store.photoFor(widget.item.code));
    }
  }

  /// Menyusun tampilan detail barang inventaris.
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) =>
        _buildDetail(context, widget.store.itemFor(widget.item.code)),
  );

  /// Menyusun detail barang, foto, stok, dan tombol tindakan.
  Widget _buildDetail(BuildContext context, InventoryItem item) => Scaffold(
    appBar: AppBar(
      title: const Text('Detail Inventaris'),
      backgroundColor: AppColors.background,
      actions: [
        if (widget.role == AppRole.admin && !item.archived)
          TextButton(onPressed: editItem, child: const Text('Edit')),
      ],
    ),
    body: PageFrame(
      children: [
        if (!widget.store.isRemote) const DemoBanner(),
        FutureBuilder<String?>(
          future: photo,
          builder: (context, snapshot) =>
              snapshot.connectionState == ConnectionState.waiting
              ? Container(
                  height: 205,
                  decoration: BoxDecoration(
                    color: AppColors.paleBlue,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : InventoryPhotoView(base64: snapshot.data),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: item.available > 0
                    ? const Color(0xFFE4F8EE)
                    : const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.available > 0 ? '• Tersedia' : '• Tidak tersedia',
                style: TextStyle(
                  color: item.available > 0
                      ? AppColors.green
                      : const Color(0xFFC62828),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(item.code, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              _InfoRow(label: 'Kategori', value: item.category),
              const Divider(color: AppColors.border),
              _InfoRow(label: 'Lokasi', value: item.location),
              const Divider(color: AppColors.border),
              _InfoRow(
                label: 'Kondisi',
                value: item.damaged == 0 && item.lost == 0
                    ? 'Baik'
                    : '${item.damaged} rusak · ${item.lost} hilang',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            StatTile(value: '${item.total}', label: 'Total Stok'),
            const SizedBox(width: 8),
            StatTile(
              value: '${item.available}',
              label: 'Tersedia',
              highlight: true,
            ),
            const SizedBox(width: 8),
            StatTile(value: '${item.borrowed}', label: 'Dipinjam'),
          ],
        ),
        if (widget.role == AppRole.admin) ...[
          const SizedBox(height: 18),
          if (!item.archived)
            ActionPillButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      StockAdjustPage(store: widget.store, item: item),
                ),
              ),
              label: 'Update Stok',
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    InventoryHistoryPage(store: widget.store, item: item),
              ),
            ),
            child: const Text('Riwayat Perubahan'),
          ),
          if (!item.archived) ...[
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
              onPressed: () async {
                final hiding = !item.hidden;
                final confirmed = await confirmAction(
                  context,
                  title: hiding ? 'Sembunyikan barang?' : 'Tampilkan barang?',
                  message: hiding
                      ? 'Barang tidak akan terlihat oleh Bendahara dan Anggota, tetapi tetap tersimpan untuk Admin.'
                      : 'Barang akan muncul kembali di daftar inventaris Bendahara dan Anggota.',
                  confirmLabel: hiding ? 'Sembunyikan' : 'Tampilkan',
                );
                if (!confirmed || !context.mounted) return;
                try {
                  if (hiding) {
                    await widget.store.hideItem(item.code);
                  } else {
                    await widget.store.showItem(item.code);
                  }
                  if (context.mounted) {
                    await showActionNotice(
                      context,
                      title: 'Berhasil',
                      message: hiding
                          ? '${item.name} telah disembunyikan.'
                          : '${item.name} telah ditampilkan kembali.',
                      buttonLabel: 'Kembali ke Inventaris',
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                } catch (error) {
                  if (context.mounted) {
                    await showActionNotice(
                      context,
                      title: hiding ? 'Hide gagal' : 'Tampilkan gagal',
                      message: error.toString().replaceFirst('Bad state: ', ''),
                      error: true,
                    );
                  }
                }
              },
              child: Text(item.hidden ? 'Tampilkan Barang' : 'Hide Barang'),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              side: const BorderSide(color: Color(0xFFC62828)),
            ),
            onPressed: () async {
              final confirmed = await confirmAction(
                context,
                title: 'Hapus barang secara permanen?',
                message:
                    'Data barang dan fotonya akan dihapus. Riwayat perubahan tetap disimpan.',
                confirmLabel: 'Hapus Barang',
                destructive: true,
              );
              if (!confirmed || !context.mounted) return;
              try {
                await widget.store.deleteItem(item.code);
                if (context.mounted) {
                  await showActionNotice(
                    context,
                    title: 'Barang dihapus',
                    message: '${item.name} telah dihapus dari inventaris.',
                    buttonLabel: 'Kembali ke Inventaris',
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              } catch (error) {
                if (context.mounted) {
                  await showActionNotice(
                    context,
                    title: 'Hapus gagal',
                    message: error.toString().replaceFirst('Bad state: ', ''),
                    error: true,
                  );
                }
              }
            },
            child: const Text('Hapus Barang'),
          ),
        ],
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  /// Membuat satu baris informasi barang.
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  /// Menyusun tampilan satu baris informasi barang.
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class BorrowingHistoryPage extends StatelessWidget {
  /// Membuat riwayat peminjaman.
  const BorrowingHistoryPage({
    super.key,
    required this.role,
    required this.store,
  });
  final AppRole role;
  final InventoryStore store;

  /// Menyusun tampilan riwayat peminjaman.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Riwayat Peminjaman'),
      backgroundColor: AppColors.background,
    ),
    body: AnimatedBuilder(
      animation: store,
      builder: (context, _) => PageFrame(
        children: [
          if (!store.isRemote) const DemoBanner(),
          if (role == AppRole.admin) ...[
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BorrowFormPage(store: store),
                ),
              ),
              child: const Text('Catat Peminjaman'),
            ),
            const SizedBox(height: 20),
          ],
          SectionHeading(
            title: 'Daftar Peminjaman',
            action: '${store.borrowings.length} catatan',
          ),
          if (store.borrowings.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                'Belum ada peminjaman.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          for (final borrowing in store.borrowings) ...[
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.itemFor(borrowing.itemCode).name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${borrowing.borrower} · ${borrowing.quantity} unit · ${borrowing.status}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Sisa ${borrowing.remaining} · Tenggat ${shortDate(borrowing.dueAt)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  if (role == AppRole.admin && borrowing.remaining > 0) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReturnFormPage(
                            store: store,
                            borrowing: borrowing,
                          ),
                        ),
                      ),
                      child: const Text('Catat Pengembalian'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );
}
