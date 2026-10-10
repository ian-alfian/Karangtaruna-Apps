# Karangtaruna Apps

Proyek Flutter untuk aplikasi manajemen inventori dan keuangan Karang Taruna. Dokumen kebutuhan ada di folder utama:

- `PRD_Sistem_Manajemen_Inventori_dan_Keuangan_Karang_Taruna.pdf`
- `UI_UX_Requirement_Sistem_Karang_Taruna.pdf`

## Menjalankan proyek

Pastikan Flutter SDK tersedia di `PATH`, lalu jalankan dari folder ini:

```sh
flutter pub get
flutter devices
flutter run
```

Untuk menjalankan di browser, gunakan `flutter run -d chrome`. Kode aplikasi dimulai dari `lib/main.dart`.

Di komputer ini, pengembangan web sudah siap. Untuk membangun aplikasi Android, jalankan `flutter doctor --android-licenses` dan setujui lisensi SDK yang ditampilkan. Untuk membangun aplikasi Windows, pasang Visual Studio dengan workload **Desktop development with C++**.

## Pemeriksaan dasar

```sh
flutter analyze
flutter test
```

Proyek ini baru berupa kerangka awal Flutter. Layar dan fitur dari dokumen kebutuhan belum diimplementasikan.
