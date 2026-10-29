import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karangtaruna_apps/onboarding_screen.dart';

void main() {
  testWidgets('pengenalan dapat dilewati dan diselesaikan', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 917));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onFinished: () async {
            finished++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang di Karangtaruna Apps'), findsOneWidget);
    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Kas lebih transparan'), findsOneWidget);
    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Barang selalu terpantau'), findsOneWidget);
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(finished, 1);
  });

  testWidgets('Lewati langsung menutup pengenalan', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onFinished: () async {
            finished = true;
          },
        ),
      ),
    );
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });
}
