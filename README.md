# Karang Taruna Digital

**Karang Taruna Digital** adalah aplikasi mobile berbasis **Flutter dan Firebase** yang dirancang untuk membantu organisasi Karang Taruna mengelola keuangan, inventaris, peminjaman barang, dan data anggota secara digital, terstruktur, serta transparan.

Aplikasi ini dikembangkan untuk menggantikan proses administrasi manual yang sering kali menggunakan buku catatan atau spreadsheet terpisah. Dengan sistem terpusat dan pembagian hak akses berdasarkan peran pengguna, pengelolaan organisasi menjadi lebih praktis, efisien, dan mudah dipantau.

## 🎯 Tujuan Aplikasi

Karang Taruna Digital bertujuan untuk:

- Mempermudah pencatatan pemasukan dan pengeluaran kas organisasi.
- Meningkatkan transparansi keuangan kepada seluruh anggota.
- Menggabungkan informasi saldo dari beberapa Bendahara yang saling terhubung.
- Membantu pengelolaan data inventaris dan ketersediaan barang.
- Mencatat aktivitas peminjaman dan pengembalian inventaris.
- Mempermudah pengelolaan akun serta hak akses pengguna.
- Menyediakan informasi dan laporan organisasi secara terpusat.

## ✨ Fitur Utama

### 💰 Manajemen Keuangan

Aplikasi menyediakan sistem pencatatan keuangan yang memungkinkan Bendahara mengelola pemasukan dan pengeluaran secara terstruktur.

Fitur yang tersedia meliputi:

- Pencatatan pemasukan dan pengeluaran.
- Pengelompokan transaksi berdasarkan kategori.
- Penyimpanan bukti transaksi.
- Riwayat dan detail transaksi.
- Grafik pemasukan dan pengeluaran.
- Pemantauan saldo kas secara otomatis.

Saldo kas dihitung berdasarkan transaksi yang tercatat, bukan melalui perubahan nominal secara manual.

### 🔗 Koneksi Antar Bendahara

Karang Taruna Digital mendukung pengelolaan kas oleh lebih dari satu Bendahara.

Setiap Bendahara dapat mencari akun Bendahara lain dan mengirimkan permintaan koneksi. Setelah permintaan diterima, sistem dapat menampilkan akumulasi saldo dari Bendahara yang terhubung.

Fitur ini meliputi:

- Pencarian akun Bendahara.
- Pengiriman dan penerimaan permintaan koneksi.
- Persetujuan atau penolakan koneksi.
- Daftar Bendahara yang terhubung.
- Informasi saldo masing-masing Bendahara.
- Perhitungan total kas gabungan secara otomatis.
- Pemutusan koneksi.

**Koneksi Bendahara tidak memindahkan dana antar akun.** Setiap Bendahara tetap mengelola saldo dan transaksi masing-masing.

### 📦 Manajemen Inventaris

Admin dapat mengelola inventaris organisasi melalui fitur:

- Menambahkan barang baru.
- Melihat daftar dan detail inventaris.
- Memperbarui informasi barang.
- Menambah atau mengurangi stok dengan alasan perubahan.
- Mengarsipkan barang.
- Melihat riwayat perubahan inventaris.
- Memantau kondisi serta ketersediaan barang.

### 🔄 Peminjaman dan Pengembalian Barang

Sistem menyediakan pencatatan peminjaman dan pengembalian inventaris agar penggunaan aset organisasi dapat dipantau.

Fitur ini mencakup:

- Pencatatan peminjaman barang.
- Informasi peminjam dan jumlah barang.
- Tanggal peminjaman dan rencana pengembalian.
- Status peminjaman aktif, selesai, atau terlambat.
- Pencatatan pengembalian barang.
- Pemeriksaan kondisi barang saat dikembalikan.
- Pencatatan barang rusak atau hilang.

### 👥 Manajemen Pengguna

Admin memiliki akses untuk:

- Membuat akun pengguna baru.
- Melihat dan mencari data pengguna.
- Mengatur peran pengguna.
- Mengaktifkan atau menonaktifkan akun.
- Mengelola proses pemulihan akses pengguna.

### 📊 Laporan dan Monitoring

Aplikasi menyediakan ringkasan dan laporan untuk membantu pemantauan kegiatan organisasi, meliputi:

- Laporan keuangan.
- Laporan inventaris.
- Laporan peminjaman barang.
- Ringkasan aktivitas dan informasi yang memerlukan perhatian.

## 🔐 Hak Akses Pengguna

Aplikasi menerapkan **Role-Based Access Control (RBAC)** dengan tiga peran utama:

| Role | Hak Akses |
|---|---|
| **Admin** | Mengelola inventaris, pengguna, peminjaman, pengembalian, laporan, serta memantau keuangan. |
| **Bendahara** | Mengelola pemasukan dan pengeluaran, melihat saldo, menghubungkan akun Bendahara, serta memantau inventaris. |
| **Anggota** | Melihat informasi keuangan, inventaris, riwayat transaksi, dan informasi peminjaman tanpa mengubah data pengelolaan. |

Pembagian hak akses ini bertujuan menjaga keamanan data serta memastikan setiap pengguna hanya dapat menjalankan fitur sesuai tanggung jawabnya.

## 🛠️ Teknologi

Aplikasi dirancang menggunakan teknologi berikut:

| Teknologi | Kegunaan |
|---|---|
| **Flutter** | Pengembangan aplikasi mobile lintas platform. |
| **Dart** | Bahasa pemrograman utama. |
| **Firebase Authentication** | Autentikasi dan pengelolaan akses pengguna. |
| **Cloud Firestore** | Penyimpanan data pengguna, keuangan, inventaris, dan aktivitas organisasi. |
| **Firebase Storage** | Penyimpanan gambar inventaris dan bukti transaksi. |
| **Figma** | Perancangan antarmuka dan pengalaman pengguna (UI/UX). |

## 🎨 Konsep UI/UX

Karang Taruna Digital menggunakan pendekatan **mobile-first** dengan gaya visual modern yang terinspirasi dari kemudahan penggunaan aplikasi mobile banking.

Desain mengutamakan:

- Tampilan bersih dan sederhana.
- Navigasi yang mudah dipahami.
- Informasi penting yang mudah ditemukan.
- Penyajian data menggunakan kartu, ikon, dan grafik.
- Konsistensi warna, tipografi, serta komponen.
- Pengurangan teks yang tidak diperlukan.
- Kemudahan penggunaan bagi seluruh anggota organisasi.

Identitas visual aplikasi menggunakan kombinasi warna biru dan navy dengan tipografi **Poppins**.

## 🚀 Status Pengembangan

**Dalam pengembangan (Work in Progress).**

Proyek dikembangkan secara bertahap, dimulai dari analisis kebutuhan, penyusunan Product Requirements Document (PRD), perancangan UI/UX, hingga implementasi aplikasi menggunakan Flutter dan Firebase.

Fitur yang didokumentasikan merupakan ruang lingkup produk yang direncanakan dan tidak selalu menunjukkan bahwa seluruh fungsi telah selesai diimplementasikan.

## 📌 Penutup

Karang Taruna Digital diharapkan dapat menjadi solusi pengelolaan organisasi kepemudaan yang lebih modern, transparan, dan terorganisasi.

Dengan mengintegrasikan manajemen keuangan, inventaris, pengguna, serta peminjaman barang dalam satu aplikasi, pengurus dan anggota Karang Taruna dapat mengakses informasi organisasi dengan lebih mudah dan efisien.