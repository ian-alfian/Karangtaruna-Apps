import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'action_dialogs.dart';
import 'demo_data.dart';
import 'inventory_store.dart';
import 'inventory_photo.dart';
import 'ui.dart';

/// Menampilkan pesan kesalahan pada formulir inventaris.
Future<void> _showError(BuildContext context, Object error) async {
  final message = error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Invalid argument(s): ', '');
  /// Menampilkan dialog hasil tindakan atau pesan kesalahan.
  await showActionNotice(
    context,
    title: 'Tindakan gagal',
    message: message,
    error: true,
  );
}

class ItemFormPage extends StatefulWidget {
  /// Membuat formulir tambah atau ubah barang.
  const ItemFormPage({super.key, required this.store, this.existing});
  final InventoryStore store;
  final InventoryItem? existing;
  /// Membuat state interaktif untuk formulir tambah atau ubah barang.
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
  bool pickingPhoto = false;
  bool photoChanged = false;
  String? photoBase64;

  /// Menyiapkan state dan pendengar awal saat widget dibuat.
  @override
  void initState() {
    super.initState();
    if (widget.existing != null) _loadPhoto();
  }

  /// Memuat foto barang saat membuka formulir ubah.
  Future<void> _loadPhoto() async {
    try {
      final photo = await widget.store.photoFor(widget.existing!.code);
      if (mounted && !photoChanged) setState(() => photoBase64 = photo);
    } catch (error) {
      if (mounted) await _showError(context, error);
    }
  }

  /// Memilih foto baru dan memperbarui pratinjau.
  Future<void> _choosePhoto() async {
    if (pickingPhoto || saving) return;
    setState(() => pickingPhoto = true);
    try {
      final selected = await pickInventoryPhoto();
      if (selected != null && mounted) {
        setState(() {
          photoBase64 = selected;
          photoChanged = true;
        });
      }
    } catch (error) {
      if (mounted) await _showError(context, error);
    } finally {
      if (mounted) setState(() => pickingPhoto = false);
    }
  }

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    code.dispose();
    name.dispose();
    location.dispose();
    quantity.dispose();
    super.dispose();
  }

  /// Memvalidasi data lalu menambah atau memperbarui barang beserta fotonya.
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
          photoBase64: photoBase64,
        );
      } else {
        await widget.store.editItem(
          widget.existing!.code,
          name: name.text,
          category: category,
          location: location.text,
          photoBase64: photoChanged ? photoBase64 : null,
        );
      }
      if (!mounted) return;
      final message = widget.existing == null
          ? widget.store.isRemote
                ? 'Barang tersimpan di database.'
                : 'Barang tersimpan di perangkat.'
          : 'Data barang diperbarui.';
      await showActionNotice(
        context,
        title: 'Berhasil',
        message: message,
        buttonLabel: 'Kembali ke Inventaris',
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (mounted) await _showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  /// Menyusun tampilan formulir tambah atau ubah barang.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.existing == null ? 'Tambah Barang' : 'Edit Barang'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        if (!widget.store.isRemote) const DemoBanner(),
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
              const SizedBox(height: 18),
              const _FormLabel('Foto Barang'),
              const SizedBox(height: 8),
              InventoryPhotoView(base64: photoBase64, height: 190),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: saving || pickingPhoto ? null : _choosePhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  pickingPhoto
                      ? 'Memproses foto...'
                      : photoBase64 == null
                      ? 'Pilih Foto Barang'
                      : 'Ganti Foto Barang',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'JPG atau PNG. Foto diperkecil otomatis sebelum disimpan.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: saving || pickingPhoto ? null : save,
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
  /// Membuat formulir penyesuaian stok.
  const StockAdjustPage({super.key, required this.store, required this.item});
  final InventoryStore store;
  final InventoryItem item;
  /// Membuat state interaktif untuk formulir penyesuaian stok.
  @override
  State<StockAdjustPage> createState() => _StockAdjustPageState();
}

class _StockAdjustPageState extends State<StockAdjustPage> {
  final formKey = GlobalKey<FormState>();
  final quantity = TextEditingController();
  final reason = TextEditingController();
  bool adding = true;
  bool saving = false;

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    quantity.dispose();
    reason.dispose();
    super.dispose();
  }

  /// Memvalidasi jumlah serta alasan, lalu menyesuaikan stok.
  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    final amount = int.parse(quantity.text) * (adding ? 1 : -1);
    final current = widget.store.itemFor(widget.item.code);
    if (current.available + amount < 0) {
      await _showError(context, StateError('Stok tersedia tidak mencukupi.'));
      return;
    }
    final approved = await confirmAction(
      context,
      title: 'Review Update Stok',
      message:
          '${current.name}\n${current.available} → ${current.available + amount} unit tersedia\nAlasan: ${reason.text.trim()}',
      confirmLabel: 'Simpan',
    );
    if (!approved || !mounted) return;
    setState(() => saving = true);
    try {
      await widget.store.adjustStock(widget.item.code, amount, reason.text);
      if (!mounted) return;
      await showActionNotice(
        context,
        title: 'Berhasil',
        message: 'Stok berhasil diperbarui.',
        buttonLabel: 'Kembali ke Inventaris',
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (mounted) await _showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  /// Menyusun tampilan formulir penyesuaian stok.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Update Stok'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        if (!widget.store.isRemote) const DemoBanner(),
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
  /// Membuat formulir peminjaman barang.
  const BorrowFormPage({super.key, required this.store});
  final InventoryStore store;
  /// Membuat state interaktif untuk formulir peminjaman barang.
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

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    borrower.dispose();
    quantity.dispose();
    note.dispose();
    super.dispose();
  }

  /// Memvalidasi peminjaman lalu menyimpan catatannya.
  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    final item = widget.store.itemFor(code!);
    final count = int.parse(quantity.text);
    if (count > item.available) {
      await _showError(context, StateError('Stok tersedia tidak mencukupi.'));
      return;
    }
    final approved = await confirmAction(
      context,
      title: 'Review Peminjaman',
      message:
          '${item.name}\n${borrower.text.trim()} · $count unit\nTenggat ${shortDate(due)}',
      confirmLabel: 'Simpan',
    );
    if (!approved || !mounted) return;
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
      await showActionNotice(
        context,
        title: 'Berhasil',
        message: 'Peminjaman berhasil dicatat.',
        buttonLabel: 'Kembali ke Inventaris',
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (mounted) await _showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  /// Menyusun tampilan formulir peminjaman barang.
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
          if (!widget.store.isRemote) const DemoBanner(),
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
  /// Membuat formulir pengembalian barang.
  const ReturnFormPage({
    super.key,
    required this.store,
    required this.borrowing,
  });
  final InventoryStore store;
  final Borrowing borrowing;
  /// Membuat state interaktif untuk formulir pengembalian barang.
  @override
  State<ReturnFormPage> createState() => _ReturnFormPageState();
}

class _ReturnFormPageState extends State<ReturnFormPage> {
  final good = TextEditingController(text: '0');
  final damaged = TextEditingController(text: '0');
  final lost = TextEditingController(text: '0');
  final note = TextEditingController();
  bool saving = false;
  /// Membaca jumlah barang dari kolom formulir.
  int count(TextEditingController controller) =>
      int.tryParse(controller.text) ?? 0;

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    good.dispose();
    damaged.dispose();
    lost.dispose();
    note.dispose();
    super.dispose();
  }

  /// Memvalidasi jumlah kembali, rusak, dan hilang sebelum menyimpan.
  Future<void> save() async {
    final total = count(good) + count(damaged) + count(lost);
    if (total <= 0 || total > widget.borrowing.remaining) {
      await _showError(
        context,
        ArgumentError(
          'Jumlah kembali harus 1–${widget.borrowing.remaining} unit.',
        ),
      );
      return;
    }
    if ((count(damaged) > 0 || count(lost) > 0) && note.text.trim().isEmpty) {
      await _showError(
        context,
        ArgumentError('Catatan wajib untuk barang rusak atau hilang.'),
      );
      return;
    }
    final approved = await confirmAction(
      context,
      title: 'Review Pengembalian',
      message:
          'Baik ${good.text} · Rusak ${damaged.text} · Hilang ${lost.text}\nHanya barang baik kembali ke stok tersedia.',
      confirmLabel: 'Simpan',
    );
    if (!approved || !mounted || saving) return;
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
      await showActionNotice(
        context,
        title: 'Berhasil',
        message: 'Pengembalian barang berhasil dicatat.',
        buttonLabel: 'Kembali ke Inventaris',
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (mounted) await _showError(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  /// Menyusun tampilan formulir pengembalian barang.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pengembalian Barang'),
      backgroundColor: AppColors.background,
    ),
    body: PageFrame(
      children: [
        if (!widget.store.isRemote) const DemoBanner(),
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
  /// Membuat kolom jumlah barang.
  const _QuantityField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;
  /// Menyusun tampilan kolom jumlah barang.
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
  /// Membuat riwayat perubahan stok.
  const InventoryHistoryPage({
    super.key,
    required this.store,
    required this.item,
  });
  final InventoryStore store;
  final InventoryItem item;
  /// Menyusun tampilan riwayat perubahan stok.
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
          if (!store.isRemote) const DemoBanner(),
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

class HiddenItemsPage extends StatelessWidget {
  /// Membuat daftar barang yang disembunyikan.
  const HiddenItemsPage({super.key, required this.store});
  final InventoryStore store;
  /// Menyusun tampilan daftar barang yang disembunyikan.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Barang Disembunyikan'),
      backgroundColor: AppColors.background,
    ),
    body: AnimatedBuilder(
      animation: store,
      builder: (context, _) => PageFrame(
        children: [
          if (!store.isRemote) const DemoBanner(),
          if (store.hiddenItems.isEmpty)
            const Text(
              'Belum ada barang yang disembunyikan.',
              style: TextStyle(color: AppColors.muted),
            ),
          for (final item in store.hiddenItems)
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
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
                  TextButton(
                    onPressed: () async {
                      try {
                        await store.showItem(item.code);
                        if (context.mounted) {
                          await showActionNotice(
                            context,
                            title: 'Barang ditampilkan',
                            message:
                                '${item.name} kembali terlihat oleh Bendahara dan Anggota.',
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          await showActionNotice(
                            context,
                            title: 'Tindakan gagal',
                            message: error.toString().replaceFirst(
                              'Bad state: ',
                              '',
                            ),
                            error: true,
                          );
                        }
                      }
                    },
                    child: const Text('Tampilkan'),
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
  /// Membuat label formulir inventaris.
  const _FormLabel(this.label);
  final String label;
  /// Menyusun tampilan label formulir inventaris.
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
