import 'package:firebase_core/firebase_core.dart';

/// Konfigurasi publik Firebase untuk aplikasi web terdaftar.
class DefaultFirebaseOptions {
  /// Menjaga agar konfigurasi Firebase hanya diakses melalui properti statis.
  const DefaultFirebaseOptions._();

  /// Menyediakan konfigurasi Firebase untuk aplikasi web.
  static FirebaseOptions get web => FirebaseOptions(
    apiKey: "AIzaSyD6PwnFRtuhklz0FONPvWuBYey3WzCZ0F8",
    appId: "1:318796675217:web:cd67159da291c684bce730",
    messagingSenderId: "318796675217",
    projectId: "karangtaruna-apps",
    authDomain: "karangtaruna-apps.firebaseapp.com",
    storageBucket: "karangtaruna-apps.firebasestorage.app",
    measurementId: "G-1V0EB9B4LC",
  );
}
