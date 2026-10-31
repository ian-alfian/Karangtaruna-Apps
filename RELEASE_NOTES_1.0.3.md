# Karangtaruna Apps — Rilis Stabil 1.0.3

**Status:** Rilis stabil (bukan beta)  
**Build Android:** 4  
**Platform:** Android dan Web/Chrome  
**Firebase:** Email/Password Authentication dan Cloud Firestore
iyaa tapi 
## Tentang aplikasi

Karangtaruna Apps adalah sistem digital untuk mengelola anggota, inventaris, peminjaman barang, serta pemasukan dan pengeluaran kas dalam satu organisasi Karang Taruna.

## Fitur utama

- Login email dan password dengan Firebase Authentication.
- Data organisasi tersimpan di Cloud Firestore secara realtime.
- Dashboard ringkasan kas, inventaris, pengguna, peminjaman, dan transaksi terbaru.
- Pengelolaan inventaris: tambah, edit, foto barang, update stok, riwayat perubahan, hide/tampilkan, dan hapus.
- Peminjaman serta pengembalian barang dengan pencatatan stok, kerusakan, dan kehilangan.
- Pengelolaan pemasukan dan pengeluaran kas dengan format nominal Rupiah serta validasi saldo.
- Koneksi antar-Bendahara untuk menampilkan saldo yang terhubung tanpa mencampur transaksi masing-masing.
- Permintaan koneksi dengan notifikasi dan indikator realtime.
- Laporan dan riwayat aktivitas organisasi.
- Perubahan password oleh pengguna secara mandiri.

## Role pengguna

### Admin

Mengelola akun pengguna, peran dan status akun, inventaris, stok, foto barang, peminjaman, pengembalian, hide/tampilkan barang, penghapusan barang, laporan, dan data organisasi.

### Bendahara

Mengelola pemasukan dan pengeluaran kas miliknya, melihat saldo, menghubungkan akun Bendahara lain, menerima atau menolak permintaan koneksi, serta melihat inventaris dan peminjaman.

### Anggota

Melihat dashboard organisasi, inventaris yang tersedia, detail barang, dan informasi peminjaman sesuai akses yang diberikan.

## Kompatibilitas Android

- **Minimum:** Android 7.0 Nougat (API level 24).
- **Maksimum:** Android versi terbaru yang mendukung API Android modern; aplikasi dibangun dengan target Android API 36 (Android 16).
- Perangkat Android 7.0 atau lebih baru dapat memasang APK selama layanan Google Play dan arsitektur perangkat mendukungnya.

## Catatan rilis

APK ini dibuat dalam mode **release** dan siap digunakan untuk demo atau distribusi langsung. Untuk publikasi ke Google Play Store, aplikasi masih perlu signing key produksi dan konfigurasi Play App Signing.
