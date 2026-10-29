import 'package:flutter/material.dart';

import 'demo_data.dart';

abstract final class AppColors {
  static const background = Color(0xFFF0F2FF);
  static const navy = Color(0xFF0D1C42);
  static const deepNavy = Color(0xFF101E49);
  static const blue = Color(0xFF2373F4);
  static const muted = Color(0xFF6B7898);
  static const paleBlue = Color(0xFFE7EEFF);
  static const border = Color(0xFFCFD9F1);
  static const green = Color(0xFF0B8C61);
  static const amber = Color(0xFFB86A14);
}

/// Menyusun warna, tipografi, dan tema Material aplikasi.
ThemeData appTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    primary: AppColors.blue,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
      headlineMedium: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.navy),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    ),
  );
}

class PageFrame extends StatelessWidget {
  /// Membuat kerangka halaman yang dapat digulir.
  const PageFrame({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 22, 24, 28),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  /// Menyusun tampilan kerangka halaman yang dapat digulir.
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(padding: padding, children: children),
  );
}

class RoleHeader extends StatelessWidget {
  /// Membuat header peran dan akun.
  const RoleHeader({
    super.key,
    required this.role,
    required this.title,
    this.onNotifications,
  });

  final AppRole role;
  final String title;
  final VoidCallback? onNotifications;

  /// Menyusun tampilan header peran dan akun.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      children: [
        if (title.startsWith('Halo')) ...[
          CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.navy,
            child: Text(
              role.displayName.substring(0, 2).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 2),
              Text(
                role.label,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onNotifications,
          tooltip: 'Notifikasi',
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.navy,
          ),
        ),
      ],
    ),
  );
}

class DemoBanner extends StatelessWidget {
  /// Membuat penanda mode data lokal.
  const DemoBanner({super.key});

  /// Menyusun tampilan penanda mode data lokal.
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4DE),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      children: [
        Icon(Icons.visibility_outlined, size: 18, color: AppColors.amber),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Mode lokal • data contoh tersimpan di perangkat ini',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.amber,
            ),
          ),
        ),
      ],
    ),
  );
}

class MoneyCard extends StatelessWidget {
  /// Membuat kartu ringkasan saldo.
  const MoneyCard({
    super.key,
    required this.label,
    required this.amount,
    this.subtitle,
    this.footerLabel,
    this.footerValue,
    this.obscured = false,
    this.onToggle,
  });

  final String label;
  final int amount;
  final String? subtitle;
  final String? footerLabel;
  final String? footerValue;
  final bool obscured;
  final VoidCallback? onToggle;

  /// Menyusun tampilan kartu ringkasan saldo.
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.deepNavy, AppColors.blue],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFCDD8F1),
                      fontSize: 13,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFFCDD8F1),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onToggle,
              tooltip: obscured ? 'Tampilkan saldo' : 'Sembunyikan saldo',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),
              icon: Icon(
                obscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          obscured ? 'Rp •••••••' : rupiah(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (footerLabel != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  footerLabel!,
                  style: const TextStyle(
                    color: Color(0xFFCDD8F1),
                    fontSize: 12,
                  ),
                ),
              ),
              if (footerValue != null)
                Text(
                  obscured ? '•••••••' : footerValue!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class SectionHeading extends StatelessWidget {
  /// Membuat judul bagian halaman.
  const SectionHeading({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;

  /// Menyusun tampilan judul bagian halaman.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class StatTile extends StatelessWidget {
  /// Membuat kartu angka statistik.
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.highlight = false,
  });
  final String value;
  final String label;
  final bool highlight;

  /// Menyusun tampilan kartu angka statistik.
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.blue : AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class QuickAction extends StatelessWidget {
  /// Membuat tombol pintas fitur.
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Menyusun tampilan tombol pintas fitur.
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: AppColors.blue),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class TransactionTile extends StatelessWidget {
  /// Membuat satu baris transaksi.
  const TransactionTile({super.key, required this.transaction, this.onTap});
  final CashTransaction transaction;
  final VoidCallback? onTap;

  /// Menyusun tampilan satu baris transaksi.
  @override
  Widget build(BuildContext context) {
    final income = transaction.type == TransactionType.income;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.paleBlue,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                income ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: AppColors.blue,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.holderName} · ${shortDate(transaction.date)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${income ? '+' : '−'}${rupiah(transaction.amount)}',
              style: TextStyle(
                color: income ? AppColors.green : AppColors.navy,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionPanel extends StatelessWidget {
  /// Membuat daftar transaksi.
  const TransactionPanel({
    super.key,
    required this.transactions,
    this.onSelect,
  });
  final List<CashTransaction> transactions;
  final ValueChanged<CashTransaction>? onSelect;

  /// Menyusun tampilan daftar transaksi.
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: transactions.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Belum ada transaksi pada periode ini.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        : Column(
            children: [
              for (var i = 0; i < transactions.length; i++) ...[
                TransactionTile(
                  transaction: transactions[i],
                  onTap: onSelect == null
                      ? null
                      : () => onSelect!(transactions[i]),
                ),
                if (i < transactions.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
  );
}

class CashFlowCard extends StatelessWidget {
  /// Membuat grafik arus kas.
  const CashFlowCard({
    super.key,
    required this.income,
    required this.expense,
    required this.monthStart,
    required this.transactions,
  });
  final int income;
  final int expense;
  final DateTime monthStart;
  final List<CashTransaction> transactions;

  /// Menyusun tampilan grafik arus kas.
  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final maximum = income > expense ? income : expense;
    /// Menghitung titik grafik bulanan untuk pemasukan atau pengeluaran.
    List<Offset> series(TransactionType type) => List.generate(5, (index) {
      final x = index / 4.0;
      final day = (1 + x * (daysInMonth - 1)).round();
      final total = transactions
          .where(
            (transaction) =>
                transaction.type == type &&
                transaction.date.year == monthStart.year &&
                transaction.date.month == monthStart.month &&
                transaction.date.day <= day,
          )
          .fold<int>(0, (sum, transaction) => sum + transaction.amount);
      return Offset(x, maximum == 0 ? .5 : .9 - .8 * total / maximum);
    });
    final monthLabel = shortDate(monthStart).split(' ')[1];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Arus Kas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Bulan Ini',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _FlowMetric(
                  label: 'Pemasukan',
                  amount: income,
                  color: AppColors.blue,
                ),
              ),
              Expanded(
                child: _FlowMetric(
                  label: 'Pengeluaran',
                  amount: expense,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 70,
            width: double.infinity,
            child: maximum == 0
                ? const Center(
                    child: Text(
                      'Belum ada transaksi bulan ini',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  )
                : CustomPaint(
                    painter: _FlowChartPainter(
                      incomePoints: series(TransactionType.income),
                      expensePoints: series(TransactionType.expense),
                    ),
                  ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 $monthLabel',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              Text(
                '${(daysInMonth * .25).round()}',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              Text(
                '${(daysInMonth * .5).round()}',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              Text(
                '${(daysInMonth * .75).round()}',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              Text(
                '$daysInMonth $monthLabel',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowMetric extends StatelessWidget {
  /// Membuat angka ringkasan arus kas.
  const _FlowMetric({
    required this.label,
    required this.amount,
    required this.color,
  });
  final String label;
  final int amount;
  final Color color;

  /// Menyusun tampilan angka ringkasan arus kas.
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      const SizedBox(height: 4),
      Text(
        rupiah(amount),
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _FlowChartPainter extends CustomPainter {
  /// Membuat gambar grafik arus kas.
  const _FlowChartPainter({
    required this.incomePoints,
    required this.expensePoints,
  });
  final List<Offset> incomePoints;
  final List<Offset> expensePoints;

  /// Menggambar grafik pada kanvas.
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    /// Menghubungkan titik grafik dengan garis penuh atau putus-putus.
    void line(List<Offset> points, Color color, bool dashed) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      if (dashed) {
        for (final metric in path.computeMetrics()) {
          for (var offset = 0.0; offset < metric.length; offset += 9) {
            canvas.drawPath(metric.extractPath(offset, offset + 5), paint);
          }
        }
      } else {
        canvas.drawPath(path, paint);
      }
    }

    line(incomePoints, AppColors.blue, false);
    line(expensePoints, AppColors.navy, true);
  }

  /// Menentukan apakah grafik perlu digambar ulang.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
