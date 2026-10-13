---
title: "Product Requirements Document — Karang Taruna Digital"
subtitle: "Revisi berdasarkan hasil desain UI/UX"
author: "Dokumen produk dan implementasi"
date: "11 Oktober 2026"
lang: id-ID
---

# Informasi Dokumen

| Atribut | Nilai |
|---|---|
| Nama produk | Karang Taruna Digital — Manajemen Inventaris & Keuangan |
| Versi | **2.0** (menggantikan PRD 1.0, 30 September 2026) |
| Status | Baseline revisi untuk validasi dan implementasi |
| Platform | Aplikasi Android/iOS dengan Flutter |
| Layanan | Firebase Authentication, Cloud Firestore, Storage; Cloud Functions untuk operasi istimewa/kritis |
| Bahasa | Bahasa Indonesia; Rupiah (IDR) |
| Peran | Anggota, Bendahara, Admin |

> **Catatan dokumen:** Revisi ini berdasarkan keputusan sepanjang proses perancangan UI/UX dan tampilan Figma yang dibahas. Kehadiran rancangan layar tidak otomatis berarti fitur sudah diimplementasikan atau diuji. Dokumen UI/UX `.md` versi sebelumnya harus diselaraskan dengan PRD 2.0 ini; jika berbeda, keputusan produk terbaru di dokumen ini berlaku sampai disahkan kembali.

# 1. Ringkasan Eksekutif

Karang Taruna Digital membantu organisasi mengelola kas, barang, peminjaman/pengembalian, pengguna, dan laporan dari satu aplikasi mobile. Pengalaman dibedakan berdasarkan role: **Anggota melihat informasi**, **Bendahara mencatat pemasukan dan pengeluaran serta mengelola koneksi bendahara**, sedangkan **Admin mengelola sistem, pengguna, inventaris, peminjaman, dan laporan**.

Aplikasi mempertahankan transparansi keuangan melalui pencatatan transaksi yang bisa ditelusuri. **Saldo tidak pernah diedit manual**; saldo berasal dari transaksi valid. Fitur **Transfer antarbendahara dihapus dari scope**. Sebagai penggantinya dari sisi agregasi informasi (bukan perpindahan uang), ditambahkan **Koneksi Bendahara** berbasis permintaan dan persetujuan, dengan pencarian akun seperti sistem pencarian pemain dalam game namun menggunakan istilah “Hubungkan”.

# 2. Keputusan Perubahan dari PRD 1.0

| Area | PRD 1.0 | Keputusan v2.0 | Dampak |
|---|---|---|---|
| Jenis transaksi | Pemasukan, pengeluaran, transfer | **Pemasukan dan pengeluaran saja** | Hapus menu, filter, flow, API dan tipe `transfer` baru |
| Hubungan bendahara | Transfer antar pemegang dana | **Koneksi Bendahara** melalui permintaan/terima/tolak/putus | Tambah model koneksi, notifikasi dan agregasi saldo |
| Total Kas | Agregasi saldo organisasi | **Agregasi saldo unik sesuai cakupan kas organisasi/koneksi yang disepakati** | Cegah double count dan selisih definisi total |
| Akun pengguna | Login dan role | Admin membuat akun, mengubah role, aktif/nonaktif, membantu reset akses | Perlu operasi server istimewa; tidak hanya UI |
| Inventaris | CRUD dasar | CRUD penuh dengan update stok terpisah, arsip, riwayat perubahan | Audit dan validasi stok |
| Peminjaman | Catat pinjam dan kembali | Form, review, sukses, detail, histori, pengembalian parsial/kondisi | Konsistensi stok dan jejak kondisi |
| Laporan | Ringkasan dan ekspor fase lanjut | Laporan keuangan, inventaris, peminjaman; state ekspor | Ekspor hanya aktif bila implementasinya tersedia |
| UX | Acuan awal mobile | Visual mengikuti Splash/Login/Register dan component library Figma | Poppins, navy/biru, kartu membulat, input pill, low-text |

**Pembersihan desain dan data:** keluarkan tombol/label/filter *Transfer* dari seluruh tampilan termasuk histori dan dummy data baru. Riwayat transfer historis, **jika memang telah ada pada sistem terpasang**, tidak boleh dihapus tanpa keputusan migrasi tersendiri.

# 3. Tujuan, Pengguna, dan Batasan

## 3.1 Tujuan produk

- Membuat saldo masing-masing Bendahara dan total kas mudah dipahami dalam beberapa detik.
- Memudahkan pencatatan pemasukan/pengeluaran dengan bukti dan validasi yang jelas.
- Menggabungkan informasi kas bendahara yang terhubung tanpa mencampurkan kepemilikan kas atau menduplikasi nominal.
- Menyediakan inventaris dan peminjaman yang dapat diaudit.
- Memberi Admin kontrol operasional dengan prinsip hak akses minimum.
- Menampilkan transparansi yang sesuai kebijakan organisasi bagi Anggota.

## 3.2 Matriks hak akses

| Aktivitas | Anggota | Bendahara | Admin |
|---|:---:|:---:|:---:|
| Lihat dashboard, inventaris, transaksi yang diizinkan | Ya | Ya | Ya |
| Catat pemasukan/pengeluaran atas kas sendiri | Tidak | Ya | Tidak secara default |
| Transfer antarbendahara | Tidak | Tidak | Tidak |
| Cari/kirim/terima/putus koneksi bendahara miliknya | Tidak | Ya | Pengawasan sesuai kebijakan |
| Kelola barang, stok, arsip, histori inventaris | Tidak | Tidak | Ya |
| Catat peminjaman dan pengembalian | Tidak* | Tidak* | Ya |
| Lihat status/riwayat peminjaman | Ya, sesuai izin | Ya, sesuai izin | Ya |
| Buat akun pengguna / ubah role / aktif-nonaktif | Tidak | Tidak | Ya |
| Laporan organisasi | Ringkasan diizinkan | Keuangan terkait | Ya |
| Ubah profil sendiri dan password | Ya | Ya | Ya |

\* Fitur pengajuan pinjam mandiri oleh Anggota/Bendahara **belum ditetapkan**. Jangan munculkan CTA pengajuan tanpa keputusan produk dan alur persetujuan lengkap.

# 4. Ketentuan Inti Keuangan

## 4.1 Ledger dan saldo

- Jenis transaksi bisnis baru hanya `income` dan `expense`.
- Setiap transaksi terkait **satu bendahara pemegang kas** (`holderId`), nominal positif, tanggal, kategori, pencatat, dan bukti opsional.
- **Saldo Bendahara** = total `income` valid bendahara − total `expense` valid bendahara, termasuk dampak koreksi/reversal yang sah jika diterapkan.
- **Saldo Saya** = saldo bendahara yang login.
- **Total Kas** = jumlah **saldo unik** bendahara pada cakupan organisasi/kas yang berhak dilihat. Koneksi tidak menciptakan pemasukan ataupun memindahkan uang.
- Tidak tersedia field saldo atau total kas yang bisa diubah manual melalui aplikasi.
- Pengeluaran harus ditolak apabila melebihi saldo tersedia; nilai transaksi wajib > 0.
- Transaksi yang sudah tercatat tidak dihapus permanen untuk menutupi jejak. Koreksi dilakukan dengan catatan audit/void/reversal menurut kebijakan yang nanti disahkan.

**Contoh:** Sukardi memegang Rp7.450.000 dan Rina Rp5.000.000. Jika keduanya berada dalam cakupan kas yang sama dan status koneksinya disetujui, Total Kas = **Rp12.450.000**. Saldo Saya milik Sukardi tetap Rp7.450.000. Mengirim permintaan koneksi saja tidak langsung mengubah agregasi.

## 4.2 Keamanan dan arti “Koneksi Bendahara”

Koneksi menggunakan pola *friend request*, tetapi terminologi produk adalah **Hubungkan**, **Permintaan Koneksi**, **Menunggu**, **Terhubung**, **Terima**, **Tolak**, dan **Putuskan Koneksi**. Pencarian dapat memakai nama, email, atau ID pengguna yang memang diperbolehkan tampil.

Alur: Profil → Koneksi Bendahara → Hubungkan Bendahara → Cari → Hubungkan → Menunggu → notifikasi penerima → Terima/Tolak → Terhubung. Permintaan dapat dibatalkan sebelum disetujui. Pengguna dapat memutus koneksi melalui konfirmasi.

Aturan:

1. Hanya akun dengan role Bendahara yang aktif dan berada dalam **organisasi yang sama** dapat saling terhubung.
2. Penerima harus menyetujui. Koneksi ganda dan permintaan ke diri sendiri ditolak.
3. Koneksi adalah **relasi informasi/keanggotaan agregasi**, bukan otorisasi mengedit transaksi bendahara lain.
4. `pending` tidak dihitung sebagai koneksi aktif; `accepted` dihitung sesuai definisi cakupan yang disahkan.
5. Pemutusan koneksi tidak menghapus transaksi, tidak memindahkan uang, dan tidak mengubah saldo pribadi; nilai *total yang terlihat* dapat berubah jika cakupannya berubah.
6. Harus ada sumber tunggal untuk perhitungan agar hubungan A-B dan B-C tidak menyebabkan penghitungan saldo berulang. **Rekomendasi implementasi:** satu `cashGroupId`/kelompok kas terotorisasi per organisasi, dan seluruh saldo anggota dihitung satu kali berdasarkan `holderId` unik; permintaan koneksi menjadi proses masuk/bergabung ke kelompok, bukan penjumlahan daftar teman individual.
7. Jika belum ada koneksi lain, layar Koneksi menampilkan state kosong dan **Total Kas pada lingkup pribadi = Saldo Saya**. Ini **bukan jaminan** bahwa total seluruh kas organisasi sama dengan Saldo Saya; nama label harus membedakan *Total Kas Terkoneksi* dari *Total Kas Organisasi* bila cakupannya tidak sama.
8. Hak melihat nama dan saldo bendahara lain dikontrol di server; tidak otomatis terbuka hanya karena pencarian akun.

**Keputusan wajib sebelum implementasi:** apakah “Total Kas” adalah jumlah **seluruh bendahara aktif satu organisasi** (transparansi organisasi global), atau hanya **kelompok bendahara yang terhubung** (cakupan koneksi). Desain saat ini mengarah ke agregasi berdasarkan koneksi, tetapi penamaan *Total Kas Organisasi* pada layar bisa menyesatkan jika ada bendahara organisasi yang belum terhubung. Sampai diputuskan, gunakan label **“Total Kas Terkoneksi”** untuk angka yang dibatasi koneksi dan tampilkan “Total Kas Organisasi” hanya jika cakupannya memang lengkap.

# 5. Modul dan Kebutuhan Fungsional

## 5.1 Autentikasi dan akun (AUTH)

| ID | Kebutuhan | Prioritas | Kriteria penerimaan |
|---|---|---|---|
| AUTH-01 | Splash, login email/password, sesi, logout | P0 | Autentikasi sesuai role; pesan kesalahan dapat dipahami |
| AUTH-02 | Register jika kebijakan mengizinkan | P1 | Tidak memperoleh role istimewa dari pilihan pengguna sendiri |
| AUTH-03 | Admin membuat pengguna baru dan memilih role | P0 | Akun tercipta di Auth + profil Firestore; tidak menukar sesi Admin |
| AUTH-04 | Admin mengubah role, aktif/nonaktif akun | P0 | Memerlukan konfirmasi, ditolak jika bukan Admin, tercatat audit |
| AUTH-05 | Reset akses/password pengguna | P0 | Alur aman; tidak menampilkan password lama; disarankan tautan reset via email |
| AUTH-06 | Edit profil sendiri, ubah password | P1 | Role read-only; validasi dan umpan balik status |

**Catatan keamanan:** Membuat akun pengguna lain, mengelola role, menonaktifkan identitas, dan reset akses **harus menggunakan Cloud Functions/Admin SDK atau layanan server istimewa**. Jangan membuat akun dengan `createUserWithEmailAndPassword` pada sesi Admin lalu mengubah sesi login Admin; jangan simpan atau tampilkan password sementara dalam dokumen/riwayat. Untuk UI “Password Awal” yang sudah digambar, putuskan apakah diganti menjadi **undangan/set password via email**; opsi ini direkomendasikan. Registrasi publik, bila digunakan, harus menghasilkan role Anggota atau akun pending secara aman.

## 5.2 Bendahara dan keuangan (FIN)

| ID | Kebutuhan | Prioritas | Kriteria penerimaan |
|---|---|---|---|
| FIN-01 | Beranda dan Keuangan: Saldo Saya, total relevan, arus kas | P0 | Angka konsisten dan tidak bisa diedit manual |
| FIN-02 | Catat pemasukan | P0 | Form → konfirmasi → sukses; nominal > 0; bukti opsional |
| FIN-03 | Catat pengeluaran | P0 | Saldo cukup dan > 0; form → konfirmasi → sukses |
| FIN-04 | Riwayat dan detail transaksi | P0 | Filter Semua/Pemasukan/Pengeluaran; periode; bukti dapat dilihat sesuai izin |
| FIN-05 | Detail bendahara dan distribusi saldo | P0 | Saldo per bendahara sesuai hak baca dan cakupan kas |
| FIN-06 | Grafik line pemasukan/pengeluaran per periode | P1 | Dua seri diberi label; agregasi selaras dengan periode terpilih |
| FIN-07 | Upload bukti dengan progres dan retry | P1 | Gagal upload tidak menghapus isian form |
| FIN-08 | Koreksi transaksi terlacak | P1 | Transaksi asli dan alasan koreksi dapat diaudit |
| FIN-09 | **Tidak ada transfer** | P0 | Tidak ada CTA, route, filter atau pencatatan transfer baru |

## 5.3 Koneksi Bendahara (CON)

| ID | Kebutuhan | Prioritas | Kriteria penerimaan |
|---|---|---|---|
| CON-01 | Menu Profil → Koneksi Bendahara | P0 | Terdapat ringkasan koneksi dan daftar saldo yang diizinkan |
| CON-02 | Cari bendahara aktif via nama/email/ID | P0 | Hanya pengguna satu organisasi yang eligible muncul; tidak bocor data sensitif |
| CON-03 | Kirim dan batalkan permintaan | P0 | Status pending; cegah duplikat dan self-connect |
| CON-04 | Terima/tolak permintaan masuk | P0 | Hanya penerima dapat memutuskan; notifikasi diperbarui |
| CON-05 | Detail koneksi dan putuskan koneksi | P0 | Konfirmasi; transaksi dan saldo pribadi tidak dihapus |
| CON-06 | Hitung agregasi saldo koneksi | P0 | Satu bendahara dihitung satu kali; tidak menghitung pending |
| CON-07 | Notifikasi koneksi dan empty state | P1 | Status menunggu/diterima/ditolak/putus dan tanpa koneksi jelas |

## 5.4 Inventaris Admin (INV)

| ID | Kebutuhan | Prioritas | Kriteria penerimaan |
|---|---|---|---|
| INV-01 | List, pencarian, filter, detail barang | P0 | Foto, kode, kategori, stok, kondisi, lokasi, status |
| INV-02 | Tambah barang | P0 | Field wajib tervalidasi; foto opsional/sesuai kebijakan |
| INV-03 | Edit metadata barang | P0 | **Stok tidak diedit langsung** di form edit |
| INV-04 | Update stok | P0 | Tambah/kurangi, jumlah, alasan wajib, review sebelum simpan |
| INV-05 | Arsip barang, konfirmasi, histori | P0 | Barang tak lagi di daftar aktif; riwayat tetap ada |
| INV-06 | Riwayat perubahan inventaris | P1 | Jenis perubahan, jumlah sebelum/sesudah, pelaku, waktu, alasan |
| INV-07 | Pulihkan barang arsip | P2 | Opsional setelah aturan penamaan/status jelas |

**Definisi CRUD:** Create (Tambah), Read (List/Detail), Update (Edit/Update Stok), Delete secara operasional = **soft delete/arsip**. Hapus permanen bukan default. Barang dengan peminjaman aktif tidak dapat diarsipkan tanpa penyelesaian atau kebijakan khusus.

## 5.5 Peminjaman dan pengembalian (BOR)

| ID | Kebutuhan | Prioritas | Kriteria penerimaan |
|---|---|---|---|
| BOR-01 | Admin catat peminjaman | P0 | Barang, jumlah, peminjam, tanggal, tenggat, catatan; stok mencukupi |
| BOR-02 | Review, sukses, detail, riwayat | P0 | Status Aktif/Selesai/Terlambat konsisten |
| BOR-03 | Pengembalian penuh atau parsial | P0 | Jumlah kembali tidak melebihi sisa pinjaman |
| BOR-04 | Kondisi kembali: Baik/Rusak/Hilang | P0 | Rusak: alasan dan foto opsional; Hilang: penjelasan wajib |
| BOR-05 | Dampak stok berdasarkan kondisi | P0 | Barang Baik menambah tersedia; Rusak/Hilang tidak otomatis menjadi stok siap pinjam |
| BOR-06 | Riwayat pinjam lihat-saja bagi Anggota/Bendahara | P1 | Hanya data yang diizinkan oleh organisasi |

**Perhatian:** Contoh UI untuk pengembalian **Rusak** yang menambah stok siap pinjam harus diperbaiki. Unit rusak masuk status rusak/maintenance, bukan `available`. Kuantitas total, tersedia, dipinjam, rusak/hilang harus tetap konsisten menurut definisi inventaris.

## 5.6 Admin, laporan, dan notifikasi (ADM/REP/NOT)

| ID | Kebutuhan | Prioritas | Kriteria penerimaan |
|---|---|---|---|
| ADM-01 | Beranda Admin dan item perlu perhatian | P0 | Kas, inventaris, anggota, pinjam, ringkasan aktivitas |
| ADM-02 | Kelola pengguna, role, status dan profil | P0 | Konfirmasi perubahan dan audit |
| ADM-03 | Monitoring Keuangan Admin (view-only) | P1 | Total, arus kas, kas bendahara, riwayat dan detail transaksi |
| REP-01 | Laporan keuangan, inventaris, peminjaman | P1 | Periode konsisten, data masuk akal, tampilan mobile |
| REP-02 | Ekspor PDF/CSV dan status progres | P2 | Hanya ditampilkan aktif jika layanan ekspor tersedia |
| NOT-01 | Notifikasi per kategori dan dibaca/belum | P1 | Pesan singkat, waktu, navigasi ke konteks relevan |
| NOT-02 | Notifikasi permintaan koneksi | P0 | Permintaan masuk dapat ditanggapi lewat notifikasi atau halaman koneksi |

# 6. Daftar Layar dan Alur

## Shared (semua role)

Splash, Login, Register (jika diaktifkan), Profil, Data Profil, Ubah Password, Tentang Aplikasi, Konfirmasi Keluar; komponen Notifikasi, loading, empty, error, offline, izin ditolak, validasi, submit, upload dan success.

## Bendahara

Beranda; Keuangan; Detail Bendahara; Riwayat/Detail Transaksi; Tambah/Konfirmasi/Sukses Pemasukan; Tambah/Konfirmasi/Sukses Pengeluaran; Inventaris/Detail (view-only); Notifikasi; Profil dan pengaturan; Koneksi Bendahara; Cari Bendahara; Permintaan Terkirim; Permintaan Masuk; Detail Koneksi; Konfirmasi Putus Koneksi; state tanpa koneksi.

## Anggota

Beranda; Keuangan (view-only); Detail Bendahara (view-only); Riwayat/Detail Transaksi (view-only); Inventaris/Detail (view-only); Riwayat/Detail Peminjaman (view-only); Notifikasi; Profil, Data Profil, Password, Tentang Aplikasi, Logout.

## Admin

Beranda; Keuangan Monitoring/Detail Transaksi (view-only); Inventaris/Detail; Tambah/Edit Barang; Update Stok (review/sukses); Arsip (konfirmasi/sukses); Riwayat Inventaris; Kelola/Tambah/Detail Pengguna; Ubah Role (konfirmasi/sukses); Aktif/Nonaktif; Reset Akses; Peminjaman (form/review/sukses/detail/riwayat); Pengembalian (form/review/sukses/detail); Laporan Overview/Keuangan/Inventaris/Peminjaman; ekspor; Notifikasi; Profil dan pengaturan.

**Navigasi utama:** Beranda, Inventaris, Keuangan, Profil. Fitur Admin tambahan melalui pintasan/konteks, bukan menambah banyak tab.

# 7. Model Data Konseptual Firebase

Berikut struktur rekomendasi, bukan skema final. Semua entitas organisasi harus mempunyai `organizationId` dan diakses hanya dalam batas organisasinya.

| Koleksi / entitas | Field penting |
|---|---|
| `users` | `uid`, `organizationId`, `name`, `email`, `phone?`, `role`, `isActive`, `createdAt`, `updatedAt` |
| `financialTransactions` | `id`, `organizationId`, `type: income|expense`, `holderId`, `amount`, `categoryId`, `title`, `description?`, `transactionDate`, `receiptPath?`, `status`, `createdBy`, timestamps, `reversalOf?` |
| `cashGroups` (direkomendasikan) | `id`, `organizationId`, `name`, `status`, `createdAt`, anggota terotorisasi (subcollection bila diperlukan) |
| `treasurerConnectionRequests` | `id`, `organizationId`, `requesterId`, `recipientId`, `cashGroupId?`, `status: pending|accepted|rejected|cancelled`, `createdAt`, `respondedAt?` |
| `treasurerConnections` / membership | `organizationId`, `cashGroupId`, `holderId`, `joinedAt`, `active`; kunci unik logis untuk mencegah duplikasi |
| `inventoryItems` | `id`, `organizationId`, `code`, `name`, `categoryId`, `location`, `condition`, `totalQty`, `availableQty`, `borrowedQty`, `damagedQty`, `lostQty`, `archivedAt?`, `imagePath?`, timestamps |
| `inventoryMovements` | `itemId`, `organizationId`, `type`, `delta`, `before`, `after`, `reason`, `actorId`, `createdAt`, `borrowingId?` |
| `borrowings` | `id`, `organizationId`, `itemId`, `borrowerId`, `quantity`, `returnedQuantity`, `borrowDate`, `dueDate`, `status`, `createdBy` |
| `borrowingReturns` | `borrowingId`, `quantity`, `condition`, `damageNote?`, `lossNote?`, `photoPath?`, `returnedAt`, `createdBy` |
| `notifications` | `organizationId`, `recipientId`, `type`, `title`, `message`, `targetRef?`, `readAt?`, `createdAt` |
| `auditLogs` | `organizationId`, `actorId`, `action`, `entityType`, `entityId`, `before?`, `after?`, `createdAt` |

Jangan menyimpan saldo sebagai angka yang bisa diubah manual. Apabila digunakan agregat/cache demi performa, nilai tersebut hanya boleh diproses server secara konsisten dari ledger dan dapat direkonsiliasi ulang.

# 8. Keamanan, Integritas, dan Privasi

- Firestore Security Rules dan Storage Rules memverifikasi identitas, organisasi, role, serta akses tiap record; menyembunyikan tombol di UI tidak cukup.
- Operasi kritis menggunakan transaksi Firestore/Cloud Functions: mencatat pengeluaran dengan pengecekan saldo, mengubah stok/peminjaman/pengembalian, menerima koneksi, serta administrasi akun.
- Hindari `list` akun bendahara lintas organisasi; hasil pencarian dibatasi dan dienumerasi secara aman (misalnya prefix pencarian dengan batas/indeks yang tepat).
- Koneksi tidak memberi izin untuk mengubah transaksi orang lain.
- Jangan mengirim password melalui chat, audit log, atau dokumen yang dapat dilihat pengguna lain.
- Tindakan admin (buat akun, ganti role, status akun, stok, arsip) menyimpan pelaku, waktu, target, dan nilai perubahan yang relevan.
- File bukti transaksi dan foto kerusakan dilindungi dengan aturan akses berbasis role/organisasi.
- Saat data offline, labeli kemungkinan stale; jangan tampilkan nominal `Rp0` sebagai pengganti loading.

# 9. Prinsip Desain UI/UX yang Disepakati

Visual acuan utama: **Splash, Login, Register, dan component library Figma yang sudah disetujui**. Dashboard lama bukan acuan visual.

- Font Poppins; latar `#F0F2FF`, biru `#2373F4`, navy `#0D1C42`, deep navy `#030A3A`; aksen gradient navy-biru.
- Mobile-first pada lebar acuan 412 px; input dan tombol pill; kartu putih atau gradient dengan sudut membulat.
- Dashboard bergaya mobile banking: angka utama dominan, pintasan ikon, grafik **line chart** pemasukan/pengeluaran, transaksi ringkas.
- Halaman Keuangan tidak boleh memuat terlalu banyak teks atau mengulang nominal di beberapa kartu. Gunakan progresif disclosure untuk detail.
- Keuangan Anggota dan Admin berupa monitoring/view-only; hanya Bendahara mendapat tombol Pemasukan/Pengeluaran.
- Filter transaksi **Semua / Pemasukan / Pengeluaran**; tidak ada Transfer.
- Semua UI menggunakan copy pendek berbahasa Indonesia, tanda status yang tidak bergantung pada warna saja, tap target nyaman, dan state yang jelas.
- Koneksi Bendahara memakai istilah keuangan, **bukan Friend/Add Friend**.

# 10. State dan Validasi Minimum

| Keadaan | Perilaku yang harus didesain/dibangun |
|---|---|
| Loading | Skeleton saldo, histori, inventaris, pengguna; jangan tampilkan Rp0 sementara |
| Empty | Belum Ada Transaksi, Inventaris Kosong, Tidak Ditemukan, Belum Ada Peminjaman, tidak ada koneksi |
| Error | “Data Gagal Dimuat” + “Coba Lagi”; hindari pesan teknis Firebase |
| Offline | Banner singkat; tampilkan data cache bila tersedia dan beri indikasi mungkin belum terbaru |
| Permission denied | “Akses Tidak Tersedia” + kembali |
| Submit | Indikator “Menyimpan…”, cegah double tap |
| Upload | Belum ada, progres, sukses/preview/remove, gagal/retry; input lain tetap terisi |
| Validasi finansial | Nominal > 0; saldo cukup; tanggal valid; field wajib |
| Validasi pengguna | Email format/unik, role sah, akses reset aman; akun dinonaktifkan ditolak login |
| Validasi barang | Stok perubahan tidak negatif, alasan wajib, stok dipinjam tidak bisa dianggap tersedia |
| Validasi peminjaman | Pinjam ≤ tersedia; kembali ≤ jumlah tersisa; kondisi Rusak/Hilang memerlukan penanganan |
| Koneksi | Self-connect/duplikat ditolak; permintaan pending; notifikasi; tanpa koneksi; gagal jaringan |

# 11. Prioritas Delivery

**P0 — MVP fungsional:** autentikasi berbasis role; dashboard; pencatatan pemasukan/pengeluaran; saldo otomatis; koneksi bendahara dan agregasi aman; histori/detail; inventaris Admin (termasuk update stok dan arsip); peminjaman/pengembalian; Admin membuat/mengelola akun; keamanan server; state utama.

**P1 — Penyempurnaan:** grafik keuangan, bukti upload dengan state lengkap, notifikasi, laporan rinci, audit navigabel, filter lanjutan, penyesuaian aksesibilitas, optimalisasi offline/empty/error.

**P2 — Opsional/pasca-MVP:** ekspor PDF/CSV, pemulihan arsip, pengajuan pinjam mandiri, laporan lebih lanjut dan notifikasi lanjutan setelah kebutuhan ditetapkan.

# 12. Risiko dan Keputusan Terbuka

1. **Definisi Total Kas:** organisasi global atau kas kelompok terhubung? Harus satu definisi, label dan formula konsisten lintas dashboard, Admin, Anggota, laporan.
2. **Hubungan koneksi:** pairwise atau keanggotaan kelompok kas? Untuk total gabungan yang konsisten, implementasi **kelompok kas** direkomendasikan. Tentukan apakah Admin mengatur kelompok, dan bagaimana jika satu organisasi memiliki lebih dari satu kelompok.
3. **Pencatatan kas awal:** aplikasi baru membutuhkan saldo awal; tanpa transfer/manual edit, tetapkan mekanisme **transaksi pemasukan saldo awal** yang diaudit (bukan edit saldo). Wajib mencegah duplikasi pencatatan.
4. **Registrasi publik vs akun buatan Admin:** desain Login/Register dan Tambah Pengguna sama-sama ada. Tetapkan alur resmi, default role, aktivasi, undangan email, dan penanganan akun duplikat.
5. **Reset password pengguna:** ganti rancangan password sementara yang berisiko dengan tautan aman, kecuali ada kebijakan identitas yang tervalidasi.
6. **Cakupan detail keuangan Anggota:** apakah bukti transaksi dan saldo tiap bendahara boleh dilihat semua anggota organisasi? Atur izin eksplisit.
7. **Pengembalian Rusak/Hilang:** kebijakan unit rusak untuk reparasi, stok tidak tersedia, dan pengadaan pengganti. Pastikan rumus stok selaras.
8. **Koreksi transaksi keuangan:** tetapkan siapa yang dapat void/reversal, periode koreksi, dan persetujuan audit.
9. **Ekspor laporan:** apakah benar dibutuhkan pada MVP, dan format mana yang diprioritaskan.

# 13. Kriteria Selesai (Definition of Done)

- Semua tiga role memiliki jalur navigasi sesuai haknya; percobaan akses ilegal ditolak server.
- Tidak ada aksi Transfer di produk v2.0; pemasukan/pengeluaran bekerja dan memutakhirkan saldo turunan yang benar.
- Koneksi bendahara dapat dicari, diajukan, disetujui, ditolak, dibatalkan, diputus; status dan notifikasinya konsisten.
- Tidak ada pemegang kas dihitung ganda; label total kas sesuai cakupan yang disetujui.
- Admin dapat membuat akun secara aman tanpa kehilangan sesinya; manajemen role/status terlindungi.
- CRUD inventaris bekerja dengan riwayat; stok, peminjaman, pengembalian rusak/hilang tidak menghasilkan stok tersedia keliru.
- Loading, empty, error, offline, upload, konfirmasi, dan validasi memiliki tampilan dan perilaku yang masuk akal.
- Laporan membaca agregasi periode yang sama dengan keuangan dan inventaris, bukan menggunakan angka dummy.
- Dokumen desain `.md`, komponen Figma, data model, Security Rules, dan pengujian integrasi diperbarui mengikuti PRD 2.0.

---

**Riwayat versi:** v1.0 (30 September 2026) — baseline inventaris, keuangan dan transfer; v2.0 (11 Oktober 2026) — tanpa transfer; koneksi bendahara; manajemen akun Admin; CRUD/audit inventaris; peminjaman lengkap; laporan dan UX hasil Figma.
