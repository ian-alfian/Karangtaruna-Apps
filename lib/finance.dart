import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_data.dart';
import 'ui.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({
    super.key,
    required this.role,
    required this.store,
    required this.onNotifications,
  });
  final AppRole role;
  final DemoStore store;
  final VoidCallback onNotifications;

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  TransactionType? filter;
  bool obscured = false;

  void openForm(TransactionType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionForm(store: widget.store, type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTreasurer = widget.role == AppRole.bendahara;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final transactions = widget.store.transactions
            .where((t) => filter == null || t.type == filter)
            .take(4)
            .toList();
        return PageFrame(
          children: [
            RoleHeader(
              role: widget.role,
              title: 'Keuangan',
              onNotifications: widget.onNotifications,
            ),
            const DemoBanner(),
            MoneyCard(
              label: isTreasurer ? 'Saldo Saya' : 'Total Kas Terkoneksi',
              subtitle: isTreasurer
                  ? 'Kas yang saya pegang'
                  : 'Kas bendahara pada contoh ini',
              amount: isTreasurer
                  ? widget.store.balanceFor('sukardi')
                  : widget.store.connectedCash,
              footerLabel: isTreasurer ? 'Total Kas Terkoneksi' : '2 Bendahara',
              footerValue: isTreasurer
                  ? rupiah(widget.store.connectedCash)
                  : null,
              obscured: obscured,
              onToggle: () => setState(() => obscured = !obscured),
            ),
            if (isTreasurer) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  QuickAction(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Pemasukan',
                    onTap: () => openForm(TransactionType.income),
                  ),
                  QuickAction(
                    icon: Icons.remove_circle_outline_rounded,
                    label: 'Pengeluaran',
                    onTap: () => openForm(TransactionType.expense),
                  ),
                  QuickAction(
                    icon: Icons.history_rounded,
                    label: 'Riwayat',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TransactionHistoryPage(store: widget.store),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            CashFlowCard(
              monthStart: monthStart,
              transactions: widget.store.transactions,
              income: widget.store.totalFor(
                TransactionType.income,
                monthStart,
                monthEnd,
              ),
              expense: widget.store.totalFor(
                TransactionType.expense,
                monthStart,
                monthEnd,
              ),
            ),
            const SizedBox(height: 28),
            const SectionHeading(title: 'Kas Bendahara'),
            Row(
              children: [
                _TreasurerCard(
                  name: 'Sukardi',
                  amount: widget.store.balanceFor('sukardi'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TreasurerDetailPage(
                        store: widget.store,
                        holderId: 'sukardi',
                        name: 'Sukardi',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                _TreasurerCard(
                  name: 'Rina',
                  amount: widget.store.balanceFor('rina'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TreasurerDetailPage(
                        store: widget.store,
                        holderId: 'rina',
                        name: 'Rina',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeading(
              title: 'Transaksi Terbaru',
              action: 'Lihat Semua',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransactionHistoryPage(store: widget.store),
                ),
              ),
            ),
            Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: filter == null,
                  onTap: () => setState(() => filter = null),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Pemasukan',
                  selected: filter == TransactionType.income,
                  onTap: () => setState(() => filter = TransactionType.income),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Pengeluaran',
                  selected: filter == TransactionType.expense,
                  onTap: () => setState(() => filter = TransactionType.expense),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TransactionPanel(
              transactions: transactions,
              onSelect: (t) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransactionDetailPage(transaction: t),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TreasurerCard extends StatelessWidget {
  const _TreasurerCard({
    required this.name,
    required this.amount,
    required this.onTap,
  });
  final String name;
  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rupiah(amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(23),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            fontSize: 11,
            color: selected ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key, required this.store});
  final DemoStore store;
  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  TransactionType? filter;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Riwayat Transaksi'),
      backgroundColor: AppColors.background,
    ),
    body: AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final transactions = widget.store.transactions
            .where((t) => filter == null || t.type == filter)
            .toList();
        return PageFrame(
          children: [
            const DemoBanner(),
            Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: filter == null,
                  onTap: () => setState(() => filter = null),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Pemasukan',
                  selected: filter == TransactionType.income,
                  onTap: () => setState(() => filter = TransactionType.income),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Pengeluaran',
                  selected: filter == TransactionType.expense,
                  onTap: () => setState(() => filter = TransactionType.expense),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TransactionPanel(
              transactions: transactions,
              onSelect: (t) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransactionDetailPage(transaction: t),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key, required this.transaction});
  final CashTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final income = transaction.type == TransactionType.income;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: AppColors.background,
      ),
      body: PageFrame(
        children: [
          const DemoBanner(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income ? 'Pemasukan' : 'Pengeluaran',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 7),
                Text(
                  '${income ? '+' : '−'}${rupiah(transaction.amount)}',
                  style: TextStyle(
                    color: income ? AppColors.green : AppColors.navy,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Divider(height: 32),
                _DetailRow(label: 'Judul', value: transaction.title),
                _DetailRow(label: 'Kategori', value: transaction.category),
                _DetailRow(label: 'Bendahara', value: transaction.holderName),
                _DetailRow(
                  label: 'Tanggal',
                  value: shortDate(transaction.date),
                ),
                if (transaction.note.isNotEmpty)
                  _DetailRow(label: 'Catatan', value: transaction.note),
                const _DetailRow(
                  label: 'Bukti',
                  value: 'Tidak ada bukti pada data contoh',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class TreasurerDetailPage extends StatelessWidget {
  const TreasurerDetailPage({
    super.key,
    required this.store,
    required this.holderId,
    required this.name,
  });
  final DemoStore store;
  final String holderId;
  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(name), backgroundColor: AppColors.background),
    body: AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final transactions = store.transactions
            .where((t) => t.holderId == holderId)
            .toList();
        return PageFrame(
          children: [
            const DemoBanner(),
            MoneyCard(
              label: 'Saldo Dipegang',
              amount: store.balanceFor(holderId),
              subtitle: name,
            ),
            const SizedBox(height: 26),
            const SectionHeading(title: 'Riwayat Transaksi'),
            TransactionPanel(
              transactions: transactions,
              onSelect: (t) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransactionDetailPage(transaction: t),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key, required this.store, required this.type});
  final DemoStore store;
  final TransactionType type;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final titleController = TextEditingController();
  final noteController = TextEditingController();
  DateTime date = DateTime.now();
  String category = 'Lainnya';
  bool saving = false;

  bool get income => widget.type == TransactionType.income;
  int get amount =>
      int.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
      0;

  @override
  void dispose() {
    amountController.dispose();
    titleController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate() || saving) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Konfirmasi ${income ? 'Pemasukan' : 'Pengeluaran'}'),
        content: Text(
          '${rupiah(amount)} · ${titleController.text.trim()}\n\nData ini hanya tersimpan selama pratinjau aplikasi terbuka.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Periksa Lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan Demo'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => saving = true);
    try {
      await widget.store.addTransaction(
        type: widget.type,
        title: titleController.text.trim(),
        category: category,
        amount: amount,
        date: date,
        note: noteController.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaksi demo berhasil ditambahkan.')),
      );
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data lokal gagal disimpan. Coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(income ? 'Tambah Pemasukan' : 'Tambah Pengeluaran'),
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
              const _FieldLabel('Nominal'),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  prefixText: 'Rp  ',
                  hintText: '0',
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                validator: (value) {
                  if (amount <= 0) return 'Nominal harus lebih dari nol.';
                  if (!income && amount > widget.store.balanceFor('sukardi')) {
                    return 'Saldo tidak mencukupi.';
                  }
                  return null;
                },
              ),
              if (!income) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rupiah(widget.store.balanceFor('sukardi')),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Saldo tersedia · Sukardi',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _FieldLabel(income ? 'Sumber Dana' : 'Keperluan'),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: income
                      ? 'Contoh: Iuran anggota'
                      : 'Contoh: Perlengkapan acara',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Field ini wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Kategori'),
              DropdownButtonFormField<String>(
                initialValue: category,
                items:
                    (income
                            ? [
                                'Lainnya',
                                'Iuran',
                                'Donasi',
                                'Sponsor',
                                'Saldo awal',
                              ]
                            : [
                                'Lainnya',
                                'Konsumsi',
                                'Perlengkapan',
                                'Transportasi',
                                'Kegiatan',
                              ])
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                onChanged: (value) =>
                    setState(() => category = value ?? 'Lainnya'),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Tanggal'),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => date = picked);
                },
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(shortDate(date)),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Catatan (opsional)'),
              TextFormField(
                controller: noteController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tambahkan catatan singkat',
                ),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Bukti (opsional)'),
              OutlinedButton.icon(
                onPressed: () => showPreviewOnly(context),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Unggah bukti saat Firebase tersedia'),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: saving ? null : submit,
                child: Text(
                  saving
                      ? 'Menyimpan...'
                      : 'Simpan ${income ? 'Pemasukan' : 'Pengeluaran'} Demo',
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Periksa data sebelum disimpan',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
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
