import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_data.dart';
import 'inventory_store.dart';
import 'ui.dart';

void _showError(BuildContext context, Object error) {
  final message = error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Invalid argument(s): ', '');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class ItemFormPage extends StatefulWidget {
  const ItemFormPage({super.key, required this.store, this.existing});
  final InventoryStore store;
  final InventoryItem? existing;
  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController code = TextEditingController(
    text: widget.existing?.code ?? '',
  );
  late final TextEditingController name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController location = TextEditingController(
    text: widget.existing?.location ?? '',
  );
  final quantity = TextEditingController();
  late String category = widget.existing?.category ?? 'Peralatan';
  bool saving = false;

  @override
  void dispose() {
    code.dispose();
    name.dispose();
    location.dispose();
    quantity.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    setState(() => saving = true);
    try {
      if (widget.existing == null) {
        await widget.store.addItem(
          code: code.text,
          name: name.text,
          category: category,
          location: location.text,
          quantity: int.parse(quantity.text),
        );
      } else {
        await widget.store.editItem(
          widget.existing!.code,
          name: name.text,
          category: category,
          location: location.text,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null
                ? 'Barang tersimpan di perangkat.'
                : 'Data barang diperbarui.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.existing == null ? 'Tambah Barang' : 'Edit Barang'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        const DemoBanner(),
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FormLabel('Kode Barang'),
              TextFormField(
                controller: code,
                enabled: widget.existing == null,
                decoration: const InputDecoration(hintText: 'Contoh: INV-004'),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Kode wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 18),
              const _FormLabel('Nama Barang'),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(hintText: 'Nama barang'),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Nama wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 18),
              const _FormLabel('Kategori'),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: ['Elektronik', 'Peralatan', 'Kegiatan', 'Lainnya']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => category = value ?? category),
              ),
              const SizedBox(height: 18),
              const _FormLabel('Lokasi'),
              TextFormField(
                controller: location,
                decoration: const InputDecoration(
                  hintText: 'Lokasi penyimpanan',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Lokasi wajib diisi.'
                    : null,
              ),
              if (widget.existing == null) ...[
                const SizedBox(height: 18),
                const _FormLabel('Stok Awal'),
                TextFormField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: 'Jumlah unit'),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                      ? 'Stok awal harus lebih dari nol.'
                      : null,
                ),
              ] else ...[
                const SizedBox(height: 15),
                const Text(
                  'Stok diubah melalui menu Update Stok agar riwayatnya tercatat.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Menyimpan...' : 'Simpan Barang'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class StockAdjustPage extends StatefulWidget {
  const StockAdjustPage({super.key, required this.store, required this.item});
  final InventoryStore store;
  final InventoryItem item;
  @override
  State<StockAdjustPage> createState() => _StockAdjustPageState();
}

class _StockAdjustPageState extends State<StockAdjustPage> {
  final formKey = GlobalKey<FormState>();
  final quantity = TextEditingController();
  final reason = TextEditingController();
  bool adding = true;
  bool saving = false;

  @override
  void dispose() {
    quantity.dispose();
    reason.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    final amount = int.parse(quantity.text) * (adding ? 1 : -1);
    final current = widget.store.itemFor(widget.item.code);
    if (current.available + amount < 0) {
      _showError(context, StateError('Stok tersedia tidak mencukupi.'));
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review Update Stok'),
        content: Text(
          '${current.name}\n${current.available} → ${current.available + amount} unit tersedia\nAlasan: ${reason.text.trim()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => saving = true);
    try {
      await widget.store.adjustStock(widget.item.code, amount, reason.text);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Stok lokal berhasil diperbarui.')),
      );
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Update Stok'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        const DemoBanner(),
        Text(widget.item.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '${widget.store.itemFor(widget.item.code).available} unit tersedia',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Tambah')),
                  ButtonSegment(value: false, label: Text('Kurangi')),
                ],
                selected: {adding},
                onSelectionChanged: (value) =>
                    setState(() => adding = value.first),
              ),
              const SizedBox(height: 20),
              const _FormLabel('Jumlah'),
              TextFormField(
                controller: quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(hintText: 'Jumlah unit'),
                validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                    ? 'Jumlah harus lebih dari nol.'
                    : null,
              ),
              const SizedBox(height: 18),
              const _FormLabel('Alasan Perubahan'),
              TextFormField(
                controller: reason,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan alasan perubahan stok',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Alasan wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Menyimpan...' : 'Review Update Stok'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class BorrowFormPage extends StatefulWidget {
  const BorrowFormPage({super.key, required this.store});
  final InventoryStore store;
  @override
  State<BorrowFormPage> createState() => _BorrowFormPageState();
}

class _BorrowFormPageState extends State<BorrowFormPage> {
  final formKey = GlobalKey<FormState>();
  final borrower = TextEditingController();
  final quantity = TextEditingController();
  final note = TextEditingController();
  String? code;
  DateTime due = DateTime.now().add(const Duration(days: 7));
  bool saving = false;

  @override
  void dispose() {
    borrower.dispose();
    quantity.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    final item = widget.store.itemFor(code!);
    final count = int.parse(quantity.text);
    if (count > item.available) {
      _showError(context, StateError('Stok tersedia tidak mencukupi.'));
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review Peminjaman'),
        content: Text(
          '${item.name}\n${borrower.text.trim()} · $count unit\nTenggat ${shortDate(due)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => saving = true);
    try {
      await widget.store.borrowItem(
        code: code!,
        borrower: borrower.text,
        quantity: count,
        dueAt: due,
        note: note.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Peminjaman lokal tercatat.')),
      );
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableItems = widget.store.items
        .where((item) => item.available > 0)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Peminjaman'),
        backgroundColor: AppColors.background,
      ),
      body: PageFrame(
        children: [
          const DemoBanner(),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FormLabel('Barang'),
                DropdownButtonFormField<String>(
                  initialValue: code,
                  hint: const Text('Pilih barang'),
                  items: availableItems
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.code,
                          child: Text(
                            '${item.name} (${item.available} tersedia)',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => code = value),
                  validator: (value) => value == null ? 'Pilih barang.' : null,
                ),
                const SizedBox(height: 18),
                const _FormLabel('Peminjam'),
                TextFormField(
                  controller: borrower,
                  decoration: const InputDecoration(hintText: 'Nama peminjam'),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Nama peminjam wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 18),
                const _FormLabel('Jumlah'),
                TextFormField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: 'Jumlah unit'),
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                      ? 'Jumlah harus lebih dari nol.'
                      : null,
                ),
                const SizedBox(height: 18),
                const _FormLabel('Tenggat Pengembalian'),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: due,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => due = picked);
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(shortDate(due)),
                ),
                const SizedBox(height: 18),
                const _FormLabel('Catatan (opsional)'),
                TextFormField(
                  controller: note,
                  decoration: const InputDecoration(
                    hintText: 'Catatan peminjaman',
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: availableItems.isEmpty || saving ? null : save,
                  child: Text(saving ? 'Menyimpan...' : 'Review Peminjaman'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReturnFormPage extends StatefulWidget {
  const ReturnFormPage({
    super.key,
    required this.store,
    required this.borrowing,
  });
  final InventoryStore store;
  final Borrowing borrowing;
  @override
  State<ReturnFormPage> createState() => _ReturnFormPageState();
}

class _ReturnFormPageState extends State<ReturnFormPage> {
  final good = TextEditingController(text: '0');
  final damaged = TextEditingController(text: '0');
  final lost = TextEditingController(text: '0');
  final note = TextEditingController();
  bool saving = false;
  int count(TextEditingController controller) =>
      int.tryParse(controller.text) ?? 0;

  @override
  void dispose() {
    good.dispose();
    damaged.dispose();
    lost.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final total = count(good) + count(damaged) + count(lost);
    if (total <= 0 || total > widget.borrowing.remaining) {
      _showError(
        context,
        ArgumentError(
          'Jumlah kembali harus 1–${widget.borrowing.remaining} unit.',
        ),
      );
      return;
    }
    if ((count(damaged) > 0 || count(lost) > 0) && note.text.trim().isEmpty) {
      _showError(
        context,
        ArgumentError('Catatan wajib untuk barang rusak atau hilang.'),
      );
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review Pengembalian'),
        content: Text(
          'Baik ${good.text} · Rusak ${damaged.text} · Hilang ${lost.text}\nHanya barang baik kembali ke stok tersedia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted || saving) return;
    setState(() => saving = true);
    try {
      await widget.store.returnItem(
        widget.borrowing.id,
        good: count(good),
        damaged: count(damaged),
        lost: count(lost),
        note: note.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Pengembalian lokal tercatat.')),
      );
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pengembalian Barang'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        const DemoBanner(),
        Text(
          widget.store.itemFor(widget.borrowing.itemCode).name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        Text(
          '${widget.borrowing.borrower} · Sisa ${widget.borrowing.remaining} unit',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        _QuantityField(label: 'Kondisi Baik', controller: good),
        _QuantityField(label: 'Rusak', controller: damaged),
        _QuantityField(label: 'Hilang', controller: lost),
        const _FormLabel('Catatan kondisi'),
        TextField(
          controller: note,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Wajib jika rusak atau hilang',
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Menyimpan...' : 'Review Pengembalian'),
        ),
      ],
    ),
  );
}

class _QuantityField extends StatelessWidget {
  const _QuantityField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(label),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    ),
  );
}

class InventoryHistoryPage extends StatelessWidget {
  const InventoryHistoryPage({
    super.key,
    required this.store,
    required this.item,
  });
  final InventoryStore store;
  final InventoryItem item;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Riwayat Inventaris'),
      backgroundColor: AppColors.background,
    ),
    body: AnimatedBuilder(
      animation: store,
      builder: (context, _) => PageFrame(
        children: [
          const DemoBanner(),
          Text(item.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (store.movementsFor(item.code).isEmpty)
            const Text(
              'Belum ada perubahan stok lokal.',
              style: TextStyle(color: AppColors.muted),
            ),
          for (final movement in store.movementsFor(item.code))
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.action,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${movement.beforeAvailable} → ${movement.afterAvailable} unit tersedia · ${shortDate(movement.at)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    movement.reason,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class ArchivedItemsPage extends StatelessWidget {
  const ArchivedItemsPage({super.key, required this.store});
  final InventoryStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Barang Diarsipkan'),
      backgroundColor: AppColors.background,
    ),
    body: AnimatedBuilder(
      animation: store,
      builder: (context, _) => PageFrame(
        children: [
          const DemoBanner(),
          if (store.archivedItems.isEmpty)
            const Text(
              'Belum ada barang diarsipkan.',
              style: TextStyle(color: AppColors.muted),
            ),
          for (final item in store.archivedItems)
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${item.code} · ${item.total} unit',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.navy,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}
