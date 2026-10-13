import 'package:flutter/material.dart';

import 'demo_data.dart';
import 'inventory_forms.dart';
import 'inventory_store.dart';
import 'ui.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    required this.role,
    required this.store,
    required this.onNotifications,
  });
  final AppRole role;
  final InventoryStore store;
  final VoidCallback onNotifications;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String category = 'Semua';
  String query = '';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final items = widget.store.items
        .where(
          (item) =>
              (category == 'Semua' || item.category == category) &&
              item.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    final available = widget.store.items.fold<int>(
      0,
      (sum, item) => sum + item.available,
    );
    final borrowed = widget.store.items.fold<int>(
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
        const DemoBanner(),
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
                  '${widget.store.items.fold<int>(0, (sum, item) => sum + item.total)}',
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
                builder: (_) => ArchivedItemsPage(store: widget.store),
              ),
            ),
            child: const Text('Barang Diarsipkan'),
          ),
        ],
      ],
    );
  }
}

IconData _iconFor(InventoryItem item) => switch (item.category) {
  'Elektronik' => Icons.speaker_rounded,
  'Peralatan' => Icons.chair_alt_rounded,
  'Kegiatan' => Icons.celebration_rounded,
  _ => Icons.inventory_2_rounded,
};

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onTap});
  final InventoryItem item;
  final VoidCallback onTap;

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
  const _StockMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool highlight;

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

class InventoryDetailPage extends StatelessWidget {
  const InventoryDetailPage({
    super.key,
    required this.item,
    required this.role,
    required this.store,
  });
  final InventoryItem item;
  final AppRole role;
  final InventoryStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => _buildDetail(context, store.itemFor(item.code)),
  );

  Widget _buildDetail(BuildContext context, InventoryItem item) => Scaffold(
    appBar: AppBar(
      title: const Text('Detail Inventaris'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        const DemoBanner(),
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: AppColors.paleBlue,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(_iconFor(item), size: 84, color: AppColors.blue),
        ),
        const SizedBox(height: 20),
        Text(item.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          '${item.code} · ${item.category}',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            StatTile(value: '${item.total}', label: 'Total unit'),
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
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              _InfoRow(label: 'Rusak', value: '${item.damaged} unit'),
              const Divider(color: AppColors.border),
              _InfoRow(label: 'Hilang', value: '${item.lost} unit'),
              const Divider(color: AppColors.border),
              _InfoRow(label: 'Lokasi', value: item.location),
              const Divider(color: AppColors.border),
              _InfoRow(
                label: 'Status',
                value: item.available > 0 ? 'Tersedia' : 'Tidak tersedia',
              ),
            ],
          ),
        ),
        if (role == AppRole.admin) ...[
          const SizedBox(height: 25),
          if (!item.archived)
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StockAdjustPage(store: store, item: item),
                ),
              ),
              child: const Text('Update Stok'),
            ),
          const SizedBox(height: 8),
          if (!item.archived)
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ItemFormPage(store: store, existing: item),
                ),
              ),
              child: const Text('Edit Barang'),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => InventoryHistoryPage(store: store, item: item),
              ),
            ),
            child: const Text('Riwayat Perubahan'),
          ),
          if (!item.archived) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Arsip barang?'),
                    content: const Text(
                      'Barang yang diarsipkan tetap ada dalam riwayat dan tidak muncul di daftar aktif.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Batal'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Arsipkan'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                try {
                  await store.archiveItem(item.code);
                  if (context.mounted) Navigator.pop(context);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error.toString().replaceFirst('Bad state: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Arsip Barang'),
            ),
          ],
        ],
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
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
  const BorrowingHistoryPage({
    super.key,
    required this.role,
    required this.store,
  });
  final AppRole role;
  final InventoryStore store;

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
          const DemoBanner(),
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
