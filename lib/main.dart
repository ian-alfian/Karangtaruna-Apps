import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Menyiapkan Firebase lalu menjalankan aplikasi Flutter.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Aplikasi Firebase tersedia di Android dan web.'),
          ),
        ),
      ),
    );
    return;
  }
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.web : null,
  );
  runApp(const KarangTarunaApp());
}
