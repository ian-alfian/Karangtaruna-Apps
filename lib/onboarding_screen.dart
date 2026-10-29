import 'package:flutter/material.dart';

import 'ui.dart';

class OnboardingScreen extends StatefulWidget {
  /// Membuat pengenalan aplikasi.
  const OnboardingScreen({super.key, required this.onFinished});

  final Future<void> Function() onFinished;

  /// Membuat state interaktif untuk pengenalan aplikasi.
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  bool finishing = false;

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Menyimpan penyelesaian pengenalan aplikasi.
  Future<void> finish() async {
    if (finishing) return;
    setState(() => finishing = true);
    try {
      await widget.onFinished();
    } finally {
      if (mounted) setState(() => finishing = false);
    }
  }

  /// Berpindah ke langkah pengenalan berikutnya atau menyelesaikannya.
  void next() {
    if (page == 2) {
      finish();
      return;
    }
    controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Menyusun tampilan pengenalan aplikasi.
  @override
  Widget build(BuildContext context) {
    final first = page == 0;
    final foreground = first ? Colors.white : AppColors.navy;
    return Scaffold(
      backgroundColor: first ? AppColors.blue : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 14, 30, 34),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: finishing ? null : finish,
                  child: Text(
                    'Lewati',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: controller,
                  onPageChanged: (value) => setState(() => page = value),
                  children: const [
                    _IntroPage(
                      title: 'Selamat datang di Karangtaruna Apps',
                      description: 'Kegiatan, kas, dan inventaris organisasi dalam satu tempat.',
                      first: true,
                    ),
                    _IntroPage(
                      title: 'Kas lebih transparan',
                      description: 'Pemasukan dan pengeluaran tercatat. Saldo dihitung otomatis dari transaksi.',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    _IntroPage(
                      title: 'Barang selalu terpantau',
                      description: 'Kelola stok, peminjaman, dan pengembalian dengan riwayat yang jelas.',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < 3; index++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      width: page == index ? 26 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: page == index
                            ? foreground
                            : foreground.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 276,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: first ? Colors.white : null,
                    gradient: first
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.navy, AppColors.blue],
                          ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: TextButton(
                    onPressed: finishing ? null : next,
                    style: TextButton.styleFrom(
                      foregroundColor: first ? AppColors.blue : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Text(
                      finishing
                          ? 'Memproses...'
                          : page == 2
                          ? 'Mulai'
                          : 'Selanjutnya',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  /// Membuat satu halaman pengenalan.
  const _IntroPage({
    required this.title,
    required this.description,
    this.first = false,
    this.icon,
  });

  final String title;
  final String description;
  final bool first;
  final IconData? icon;

  /// Menyusun tampilan satu halaman pengenalan.
  @override
  Widget build(BuildContext context) {
    final foreground = first ? Colors.white : AppColors.navy;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (first)
            SizedBox(
              width: 280,
              height: 240,
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned(
                      left: -66,
                      top: -340,
                      child: Image.asset(
                        'assets/splash_reference.png',
                        width: 412,
                        height: 917,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: 176,
              height: 176,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.navy, AppColors.blue],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 86),
            ),
          const SizedBox(height: 34),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.6,
              color: foreground.withValues(alpha: first ? 0.9 : 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
