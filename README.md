# Karang Taruna Digital

**Karang Taruna Digital** adalah aplikasi mobile berbasis **Flutter dan Firebase** yang dirancang untuk membantu organisasi Karang Taruna mengelola keuangan, inventaris, peminjaman barang, dan data anggota secara digital, terstruktur, serta transparan.

Aplikasi ini dikembangkan untuk menggantikan proses administrasi manual yang sering kali menggunakan buku catatan atau spreadsheet terpisah. Dengan sistem terpusat dan pembagian hak akses berdasarkan peran pengguna, pengelolaan organisasi menjadi lebih praktis, efisien, dan mudah dipantau.

## 📱 Kompatibilitas Perangkat

> [!IMPORTANT]
> **Kompatibilitas Android:** aplikasi ini ditujukan **hanya untuk Android versi 7 hingga Android 17**. Perangkat di luar rentang versi tersebut tidak termasuk dukungan yang dinyatakan. Rentang ini adalah ketentuan dukungan proyek; pengujian perangkat nyata/emulator pada setiap versi tetap perlu dilakukan untuk memastikan kompatibilitas.

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

- Unggah bukti transaksi belum tersedia (direncanakan untuk pengembangan).

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

- Perhitungan **Total Kas Terkoneksi** secara otomatis menggunakan UID unik.

- Pemutusan koneksi.

**Koneksi Bendahara tidak memindahkan dana antar akun.** Setiap Bendahara tetap mengelola saldo dan transaksi masing-masing.

### 📦 Manajemen Inventaris

Admin dapat mengelola inventaris organisasi melalui fitur:

- Menambahkan barang baru.

- Memilih foto barang; aplikasi memperkecil dan menyimpannya di Firestore untuk ditampilkan pada detail inventaris.

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

- Menghapus akses/profil pengguna dari Firestore (identitas Firebase Authentication masih memerlukan penghapusan terpisah).

### 📊 Laporan dan Monitoring

Halaman **Laporan** menyediakan ringkasan untuk pemantauan organisasi. Grafik arus kas tersedia di halaman **Keuangan**, sedangkan ekspor laporan belum tersedia. Ringkasan mencakup:

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

| **Firebase Storage** | Belum dipakai pada paket Spark. Foto inventaris ukuran kecil disimpan pada koleksi `inventoryPhotos` di Firestore; bukti transaksi masih direncanakan. |

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

## 🧩 Diagram Sistem (Implementasi Saat Ini)

Diagram berikut menggambarkan **alur yang sudah diimplementasikan** sesuai pemeriksaan pengembang pada **29 Oktober 2026**. Diagram harus ditinjau ulang apabila kode aplikasi berubah. Format Mermaid dapat ditampilkan langsung oleh GitHub.

Bagian rancangan pengembangan dipisahkan pada akhir dokumentasi diagram agar tidak disalahartikan sebagai fitur yang sudah berjalan.

# Diagram Sistem — Karang Taruna Digital

Dokumentasi diagram **implementasi saat ini** aplikasi **Karang Taruna Digital** (Flutter + Firebase), berdasarkan pemeriksaan kode proyek yang dilaporkan pengembang pada **29 Oktober 2026**. Diagram ini merupakan potret kondisi kode saat pemeriksaan, bukan jaminan bahwa semua fitur PRD telah diimplementasikan.

> **Dasar verifikasi:** hasil pencocokan kode proyek oleh pengembang (antara lain `finance.dart`, `cloud_stores.dart`, `firebase_admin.dart`, `connection_scope.dart`, `login_bloc.dart`, `user_management.dart`, `firebase_login.dart`, `inventory.dart`, dan `firestore.rules`). **Tanggal pemeriksaan: 29 Oktober 2026.** Dokumentasi harus diperiksa ulang terhadap versi/commit aplikasi terbaru jika kode berubah. Penyusunan dokumen ini menggunakan hasil pemeriksaan tersebut dan tidak mengklaim audit kode independen.

**Implementasi saat ini:** Flutter mengakses Firebase Auth dan Cloud Firestore secara langsung, dengan kontrol Firestore Security Rules. Foto inventaris disimpan dalam bentuk Base64 di `inventoryPhotos`; unggah bukti transaksi belum tersedia. Cloud Functions/Admin SDK belum menjadi jalur operasional aplikasi.

**Rancangan pengembangan:** migrasi foto/bukti ke Storage, layanan backend tepercaya untuk operasi sensitif, pengaitan peminjam ke UID, dan ekspor laporan. Bagian ini dipisahkan di akhir dokumen.

**Aktor:** Admin, Bendahara, Anggota. **Aturan utama:** transaksi keuangan hanya **pemasukan** dan **pengeluaran**; fitur **transfer antar-Bendahara tidak tersedia**. Koneksi Bendahara membutuhkan persetujuan dan **tidak memindahkan dana**. Saldo dihitung dari transaksi dan tidak diubah manual.

> **Catatan notasi:** GitHub merender diagram menggunakan Mermaid. Bagian *Use Case* menggunakan bentuk flowchart dengan node oval sebagai representasi praktis use case, bukan notasi UML use case formal. Untuk diagram UML formal, ekspor ulang melalui PlantUML atau alat UML khusus.

## 1. Use Case Diagram

### 1.1 Gambaran hak akses seluruh role

```mermaid
flowchart LR
    AD["Admin"]
    BE["Bendahara"]
    AN["Anggota"]

    subgraph SYS["Karang Taruna Digital"]
      LOGIN(["Onboarding, Login, Lihat Profil, Ubah Password"])
      VIEWFIN(["Lihat Total Kas Terkoneksi dan Transaksi"])
      INCOME(["Catat Pemasukan / Pengeluaran"])
      CONNECT(["Kelola Koneksi Bendahara"])
      VIEWINV(["Lihat Inventaris"])
      MANINV(["CRUD Inventaris dan Penyesuaian Stok"])
      BORROW(["Kelola Peminjaman dan Pengembalian"])
      VIEWBOR(["Lihat Riwayat Peminjaman yang Diizinkan"])
      USERS(["Kelola Akun, Role, Status, dan Hapus Akses"])
      REPORTS(["Monitoring dan Ringkasan Laporan"])
    end

    AD --- LOGIN & VIEWFIN & VIEWINV & MANINV & BORROW & VIEWBOR & USERS & REPORTS
    BE --- LOGIN & VIEWFIN & INCOME & CONNECT & VIEWINV & VIEWBOR
    AN --- LOGIN & VIEWFIN & VIEWINV & VIEWBOR
```

### 1.2 Use case Koneksi Bendahara

```mermaid
flowchart LR
    B["Bendahara"]
    subgraph K["Koneksi Bendahara"]
      FIND(["Cari Bendahara"])
      SEND(["Kirim Permintaan Hubungkan"])
      INCOMING(["Lihat Permintaan Masuk"])
      APPROVE(["Terima / Tolak Permintaan"])
      CANCEL(["Batalkan Permintaan"])
      LIST(["Lihat Koneksi Aktif"])
      DISCONNECT(["Putuskan Koneksi"])
      TOTAL(["Lihat Total Kas Terkoneksi"])
    end
    B --- FIND & SEND & INCOMING & APPROVE & CANCEL & LIST & DISCONNECT & TOTAL
```

### 1.3 Use case Inventaris dan Pengguna Admin

```mermaid
flowchart LR
    A["Admin"]
    subgraph S["Administrasi Organisasi"]
      ADD(["Tambah Barang"])
      READ(["Lihat / Cari Barang"])
      EDIT(["Edit Informasi Barang"])
      STOCK(["Update Stok dengan Alasan"])
      ARCHIVE(["Arsipkan Barang"])
      HISTORY(["Lihat Audit Inventaris"])
      CREATEUSER(["Buat Akun Pengguna"])
      ROLE(["Ubah Role"])
      STATUS(["Aktifkan / Nonaktifkan Akun"])
      DELUSER(["Hapus Profil Firestore / Akses Aplikasi (Auth masih ada)"])
    end
    A --- ADD & READ & EDIT & STOCK & ARCHIVE & HISTORY & CREATEUSER & ROLE & STATUS & DELUSER
```

## 2. Activity Diagram

### 2.1 Onboarding, login, dan pengalihan berdasarkan role

```mermaid
flowchart TD
    START(["Mulai"]) --> FIRST{"Pertama membuka aplikasi?"}
    FIRST -- "Ya" --> INTRO["Tampilkan onboarding"] --> FORM
    FIRST -- "Tidak" --> FORM["Pilih tampilan role; isi email dan password"]
    FORM --> VALID{"Input valid?"}
    VALID -- "Tidak" --> ERROR["Tampilkan pesan validasi"] --> FORM
    VALID -- "Ya" --> AUTH["Firebase Authentication memverifikasi kredensial"]
    AUTH --> PASS{"Autentikasi berhasil?"}
    PASS -- "Tidak" --> FAIL["Tampilkan kesalahan login"] --> FORM
    PASS -- "Ya" --> PROFILE["Muat status dan role dari Firestore"]
    PROFILE --> ACTIVE{"Akun aktif?"}
    ACTIVE -- "Tidak" --> BLOCK["Tolak akses dan akhiri sesi"] --> END(["Selesai"])
    ACTIVE -- "Ya" --> ROLE{"Role"}
    ROLE -- "Admin" --> ADMINVIEW{"Pilihan tampilan Admin?"}
    ADMINVIEW -- "Admin" --> A["Beranda Admin"] --> END
    ADMINVIEW -- "Role lain" --> PREVIEW["Tampilkan perspektif role terpilih; hak aksi tetap Admin sesuai aturan"] --> END
    ROLE -- "Bendahara" --> B["Beranda Bendahara"] --> END
    ROLE -- "Anggota" --> C["Beranda Anggota"] --> END
```

### 2.2 Pencatatan keuangan Bendahara

```mermaid
flowchart TD
    START(["Mulai"]) --> TYPE{"Pilih jenis transaksi"}
    TYPE -- "Pemasukan" --> IN["Isi nominal, sumber, kategori, tanggal"]
    TYPE -- "Pengeluaran" --> OUT["Isi nominal, keperluan, kategori, tanggal"]
    IN --> RECEIPT["Catatan opsional; unggah bukti belum tersedia"]
    OUT --> RECEIPT
    RECEIPT --> VALID{"Form valid dan nominal > 0?"}
    VALID -- "Tidak" --> FIX["Perbaiki input"] --> TYPE
    VALID -- "Ya" --> REVIEW["Tampilkan ringkasan konfirmasi"]
    REVIEW --> CONF{"Konfirmasi simpan?"}
    CONF -- "Tidak" --> TYPE
    CONF -- "Ya" --> SERVER["Flutter menjalankan Firestore runTransaction"]
    SERVER --> CHECK["Callback Flutter membaca cashAccounts/{uid}, memvalidasi saldo; Rules memeriksa izin"]
    CHECK --> ALLOW{"Transaksi diizinkan?"}
    ALLOW -- "Tidak" --> DECLINE["Batalkan transaksi atomik; tampilkan kesalahan / saldo tidak cukup"] --> TYPE
    ALLOW -- "Ya" --> SAVE["Dalam satu transaksi atomik: tulis financialTransactions dan update cashAccounts/{uid}"]
    SAVE --> BALANCE["Baca transaksi terbaru dan hitung saldo tampilan"] --> SUCCESS["Tampilkan berhasil"] --> END(["Selesai"])
```

### 2.3 Koneksi antar-Bendahara

```mermaid
flowchart TD
    START(["Mulai"]) --> SEARCH["Cari Bendahara berdasarkan nama/email/ID"]
    SEARCH --> SELECT["Pilih Bendahara dan tekan Hubungkan"]
    SELECT --> DUP{"Sudah terhubung / ada request aktif?"}
    DUP -- "Ya" --> CURRENT["Tampilkan status saat ini"] --> END(["Selesai"])
    DUP -- "Tidak" --> SEND["Simpan permintaan pending dan notifikasi"]
    SEND --> WAIT["Menunggu tanggapan penerima"]
    WAIT --> DECISION{"Tanggapan"}
    DECISION -- "Terima" --> APPROVE["Aktifkan koneksi dua pihak"]
    APPROVE --> SUM["Hitung Total Kas Terkoneksi dari UID unik"] --> END
    DECISION -- "Tolak" --> REJECT["Tandai ditolak"] --> END
    DECISION -- "Batalkan" --> CANCEL["Tandai dibatalkan"] --> END
    DECISION -- "Belum ada" --> WAIT
```

### 2.4 Pengelolaan inventaris Admin

```mermaid
flowchart TD
    START(["Mulai"]) --> LIST["Buka Inventaris"] --> ACTION{"Pilih tindakan"}
    ACTION -- "Tambah" --> ADD["Isi detail barang dan stok awal"] --> CHECK{"Valid?"}
    ACTION -- "Edit" --> EDIT["Ubah metadata barang, bukan stok"] --> CHECK
    CHECK -- "Tidak" --> RETRY["Perbaiki data"] --> LIST
    CHECK -- "Ya" --> STORE["Simpan barang dan log audit"] --> DONE["Tampilkan hasil"] --> END(["Selesai"])
    ACTION -- "Update Stok" --> STOCK["Pilih tambah/kurangi, jumlah, alasan"] --> PREVIEW["Preview stok lama dan baru"]
    PREVIEW --> STOCKCHECK{"Stok tetap valid?"}
    STOCKCHECK -- "Tidak" --> STOCK
    STOCKCHECK -- "Ya" --> COMMIT["Simpan perubahan atomik dan audit"] --> DONE
    ACTION -- "Arsipkan" --> ACTIVE{"Masih dipinjam?"}
    ACTIVE -- "Ya" --> DENY["Tolak arsip hingga peminjaman selesai"] --> LIST
    ACTIVE -- "Tidak" --> ASK{"Konfirmasi arsip?"}
    ASK -- "Tidak" --> LIST
    ASK -- "Ya" --> ARCHIVE["Ubah status menjadi archived dan catat audit"] --> DONE
    ACTION -- "Lihat" --> DETAIL["Tampilkan detail dan riwayat"] --> END
```

### 2.5 Peminjaman dan pengembalian

```mermaid
flowchart TD
    START(["Mulai"]) --> CHOICE{"Proses"}
    CHOICE -- "Pinjam" --> BORROW["Admin pilih barang, ketik nama peminjam, jumlah, dan tanggal"]
    BORROW --> STOCK{"Stok tersedia mencukupi?"}
    STOCK -- "Tidak" --> CORRECT["Perbaiki jumlah"] --> BORROW
    STOCK -- "Ya" --> BCONF["Review dan konfirmasi"] --> BSAVE["Catat peminjaman dan stok secara atomik"] --> SUCCESS["Tampilkan berhasil"] --> END(["Selesai"])
    CHOICE -- "Kembali" --> RETURN["Admin pilih pinjaman aktif dan jumlah kembali"]
    RETURN --> QTY{"Jumlah kembali valid?"}
    QTY -- "Tidak" --> RETURN
    QTY -- "Ya" --> CONDITION{"Kondisi"}
    CONDITION -- "Baik" --> GOOD["Kembalikan unit ke stok tersedia"]
    CONDITION -- "Rusak" --> BAD["Catat kerusakan; unit tidak tersedia"]
    CONDITION -- "Hilang" --> LOST["Catat kehilangan; unit tidak tersedia"]
    GOOD --> RSAVE["Simpan pengembalian dan audit secara atomik"]
    BAD --> RSAVE
    LOST --> RSAVE
    RSAVE --> DONE{"Semua jumlah selesai?"}
    DONE -- "Ya" --> FINISH["Status selesai"] --> SUCCESS
    DONE -- "Tidak" --> PARTIAL["Status aktif / sisa pinjaman"] --> SUCCESS
```

## 3. Sequence Diagram

> **Status:** diagram sequence di bawah menggambarkan **jalur implementasi saat pemeriksaan kode (29 Oktober 2026)**: Flutter ↔ Firebase Authentication / Cloud Firestore, dengan kontrol `firestore.rules`. Cloud Functions/Admin SDK tidak menjadi jalur operasional. Pemakaian `runTransaction` pada keuangan dan penambahan inventaris sudah diidentifikasi dalam pemeriksaan kode; pengujian izin serta kasus bersamaan tetap diperlukan.

### 3.1 Login dan pemuatan role

```mermaid
sequenceDiagram
    autonumber
    actor U as Pengguna
    participant F as Flutter
    participant A as Firebase Authentication
    participant D as Cloud Firestore
    U->>F: Selesaikan onboarding bila pertama kali
    U->>F: Pilih tampilan role, masukkan email/password
    F->>A: Login email/password
    alt Kredensial salah
        A-->>F: Login gagal
        F-->>U: Pesan kesalahan
    else Login berhasil
        A-->>F: Session dan UID
        F->>D: Ambil users/{uid} atau profil keanggotaan
        D-->>F: Role dan status
        alt Akun nonaktif
            F->>A: Sign out
            F-->>U: Akses dinonaktifkan
        else Akun aktif
            F-->>U: Dashboard atau tampilan role yang diizinkan
            Note over U,F: Admin dapat memilih perspektif role lain, otorisasi tidak mengikuti pilihan UI.
        end
    end
```

### 3.2 Pemasukan dan pengeluaran — implementasi saat pemeriksaan

```mermaid
sequenceDiagram
    autonumber
    actor B as Bendahara
    participant F as Flutter
    participant D as Cloud Firestore
    participant R as firestore.rules
    B->>F: Isi pemasukan atau pengeluaran
    Note over B,F: Upload bukti transaksi belum tersedia
    F->>F: Validasi form dan nominal
    F-->>B: Review transaksi
    B->>F: Konfirmasi simpan
    F->>D: Mulai runTransaction(callback Flutter)
    D-->>F: Konteks transaksi
    F->>D: Callback membaca cashAccounts/{uid}
    D-->>F: Data kas terkini
    F->>F: Callback validasi nominal dan saldo tersedia
    alt Pengeluaran melebihi saldo atau data tidak valid
        F-->>B: Batalkan, tampilkan saldo tidak cukup / input tidak valid
    else Data valid
        F->>D: Callback menulis financialTransactions dan cashAccounts/{uid}
        D->>R: Evaluasi izin penulisan melalui firestore.rules
        alt Izin ditolak
            R-->>D: Deny
            D-->>F: Gagal, tidak ada commit parsial
            F-->>B: Tampilkan kesalahan akses
        else Izin diterima
            R-->>D: Allow
            D->>D: Commit kedua perubahan secara atomik
            D-->>F: Transaksi berhasil
            F->>D: Ambil daftar transaksi terbaru
            D-->>F: Transaksi terkini
            F->>F: Hitung saldo tampilan dari daftar transaksi
            F-->>B: Tampilkan sukses dan saldo terbaru
        end
    end
```

> Callback `runTransaction` di **Flutter** membaca `cashAccounts/{uid}` dan memutuskan apakah saldo mencukupi (berdasarkan pemeriksaan `cloud_stores.dart` sekitar baris 169–183). Firestore memastikan penulisan `financialTransactions` dan pembaruan `cashAccounts/{uid}` di-commit **secara atomik**, sedangkan `firestore.rules` memeriksa izin. Saldo pada UI dihitung dari daftar transaksi. Tidak ada Firebase Storage atau Cloud Functions pada alur ini.

### 3.3 Hubungkan Bendahara — implementasi saat ini

```mermaid
sequenceDiagram
    autonumber
    actor A as Bendahara Pengirim
    actor B as Bendahara Penerima
    participant F as Flutter
    participant D as Cloud Firestore
    participant R as firestore.rules
    A->>F: Cari Bendahara dan tekan Hubungkan
    F->>D: Baca pengguna Bendahara / status koneksi
    D-->>F: Hasil dan status
    F->>D: Tulis permintaan pending
    D->>R: Periksa izin request
    R-->>D: Allow / deny
    D-->>F: Status request
    F-->>A: Menunggu Konfirmasi
    B->>F: Buka permintaan masuk
    F->>D: Baca request pending
    D-->>F: Permintaan masuk
    alt Terima
        B->>F: Terima permintaan
        F->>D: Perbarui status koneksi
        D->>R: Periksa otorisasi
        R-->>D: Allow / deny
        D-->>F: Status terkini
        F->>F: Tentukan cakupan koneksi, UID unik
        F-->>B: Tampilkan Total Kas Terkoneksi
    else Tolak
        B->>F: Tolak permintaan
        F->>D: Perbarui status rejected
        D-->>F: Status terbaru
    end
    Note over A,D: Koneksi tidak memindahkan dana. Total Kas Terkoneksi menggunakan UID unik dalam kelompok koneksi.
```

### 3.4 CRUD inventaris dan foto Base64 — implementasi saat pemeriksaan

```mermaid
sequenceDiagram
    autonumber
    actor A as Admin
    participant F as Flutter
    participant D as Cloud Firestore
    participant R as firestore.rules
    A->>F: Buka Inventaris
    F->>D: Baca daftar barang
    D-->>F: Data inventaris
    alt Tambah Barang
        A->>F: Isi data barang, stok awal, dan foto opsional
        opt Ada foto
            F->>F: Konversi foto menjadi Base64
        end
        F->>D: runTransaction() untuk tambah barang
        D->>R: Periksa izin penulisan terkait
        alt Ditolak
            R-->>D: Deny
            D-->>F: Seluruh transaksi gagal
        else Diizinkan
            R-->>D: Allow
            Note over F,D: Dalam SATU transaksi Firestore
            D->>D: Tulis inventoryItems
            opt Foto tersedia
                D->>D: Tulis inventoryPhotos (Base64)
            end
            D->>D: Tulis inventoryMovements (audit)
            D-->>F: Commit atomik berhasil
        end
    else Edit Barang
        A->>F: Ubah metadata tanpa edit stok langsung
        F->>D: Ajukan update metadata
        D->>R: Periksa izin
        R-->>D: Allow / deny
        D-->>F: Hasil operasi
    else Update Stok
        A->>F: Isi jumlah dan alasan
        F->>D: Ajukan penyesuaian stok dan audit
        D->>R: Periksa izin
        R-->>D: Allow / deny
        D-->>F: Hasil operasi
    else Arsipkan Barang
        A->>F: Konfirmasi arsip
        F->>D: Ajukan perubahan status arsip
        D->>R: Periksa izin
        R-->>D: Allow / deny
        D-->>F: Hasil operasi
    end
    F-->>A: Tampilkan sukses atau error
```

> Saat **menambah barang**, dokumen `inventoryItems`, `inventoryPhotos` (bila ada), dan `inventoryMovements` disimpan dalam **satu transaksi Firestore** menurut `cloud_stores.dart` sekitar baris 422. Foto tetap disimpan sebagai Base64 di Firestore, **bukan Firebase Storage**. Alur Edit/Stok/Arsip ditampilkan ringkas dan tidak otomatis diasumsikan memakai transaksi yang sama.

### 3.5 Peminjaman dan pengembalian — implementasi saat ini

```mermaid
sequenceDiagram
    autonumber
    actor A as Admin
    participant F as Flutter
    participant D as Cloud Firestore
    participant R as firestore.rules
    alt Peminjaman
        A->>F: Ketik nama peminjam, pilih barang, jumlah dan tanggal
        Note over A,F: Peminjam berupa teks, belum dipetakan ke UID akun Anggota
        F-->>A: Review peminjaman
        A->>F: Konfirmasi
        F->>D: runTransaction: catat peminjaman dan ubah stok
        D->>R: Periksa izin melalui firestore.rules
        R-->>D: Allow / deny
        D-->>F: Commit atomik berhasil atau gagal tanpa commit parsial
    else Pengembalian
        A->>F: Pilih peminjaman dan isi jumlah/kondisi
        opt Rusak atau hilang
            F-->>A: Minta keterangan kondisi
        end
        F-->>A: Review pengembalian
        A->>F: Konfirmasi
        F->>D: runTransaction: catat pengembalian dan ubah stok
        D->>R: Periksa izin melalui firestore.rules
        R-->>D: Allow / deny
        D-->>F: Commit atomik berhasil atau gagal tanpa commit parsial
    end
    F-->>A: Tampilkan status
```

> Peminjaman dan pengembalian menggunakan `runTransaction` untuk menyimpan catatan sekaligus perubahan stok **secara atomik** (berdasarkan pemeriksaan `cloud_stores.dart` sekitar baris 609). Peminjam masih berupa nama teks, **belum terhubung otomatis** dengan UID Anggota yang login.

### 3.6 Admin membuat dan mengelola akun — implementasi saat ini

```mermaid
sequenceDiagram
    autonumber
    actor A as Admin
    participant F as Flutter (sesi Admin)
    participant S as Firebase Auth sekunder
    participant D as Cloud Firestore
    participant R as firestore.rules
    alt Buat akun
        A->>F: Isi nama, email, role, password awal, konfirmasi
        F->>F: Validasi form
        F->>S: Buat akun dengan instance Auth sekunder
        S-->>F: UID akun baru
        Note over F,S: Sesi login Admin utama tetap aktif
        F->>D: Simpan profil users/{uid} dan role
        D->>R: Periksa izin menulis profil
        R-->>D: Allow / deny
        D-->>F: Hasil simpan
        F-->>A: Akun dibuat / tampilkan error
    else Ubah role atau status
        A->>F: Pilih perubahan dan konfirmasi
        F->>D: Update users/{uid}
        D->>R: Evaluasi izin
        R-->>D: Allow / deny
        D-->>F: Hasil
    else Hapus akun dari aplikasi
        A->>F: Konfirmasi hapus akun
        F->>D: Hapus profil Firestore dan akses aplikasi
        D->>R: Periksa izin
        R-->>D: Allow / deny
        D-->>F: Status penghapusan profil
        F-->>A: Profil/akses aplikasi dihapus
        Note over A,D: Identitas Firebase Authentication belum terhapus otomatis.
    end
```

> **Batasan keamanan dan konsistensi:** penghapusan profil Firestore tidak sama dengan penghapusan user Firebase Authentication. Untuk produksi, penegakan role/status pada Rules dan operasi penghapusan perlu diuji; Admin SDK via backend tepercaya merupakan rancangan pengembangan.

### 3.7 Anggota melihat keuangan, inventaris, dan riwayat

```mermaid
sequenceDiagram
    autonumber
    actor A as Anggota
    participant F as Flutter
    participant D as Cloud Firestore
    A->>F: Login dan buka Beranda
    F->>D: Minta ringkasan sesuai izin
    D-->>F: Kas, arus kas, inventaris
    F-->>A: Beranda Anggota
    alt Keuangan
        A->>F: Lihat transaksi dan distribusi kas
        F->>D: Baca data keuangan view-only
        D-->>F: Riwayat dan ringkasan
    else Inventaris
        A->>F: Lihat daftar dan detail barang
        F->>D: Baca barang view-only
        D-->>F: Stok, kondisi, detail
    else Peminjaman
        A->>F: Lihat riwayat/status peminjaman
        F->>D: Baca catatan yang diizinkan
        D-->>F: Catatan dengan nama peminjam teks
        Note over A,D: Belum otomatis difilter berdasarkan UID Anggota yang login.
    end
    F-->>A: Tampilkan data tanpa aksi pengelolaan
```

## 4. Ringkasan

| Jenis diagram | Fokus | Jumlah |
|---|---|---:|
| Use Case | Hak akses, koneksi Bendahara, administrasi | 3 |
| Activity | Login, transaksi keuangan, koneksi, inventaris, peminjaman | 5 |
| Sequence | Integrasi Flutter–Firebase pada proses utama | 7 |
| **Total** | | **15** |

**Catatan keamanan dan konsistensi:** Aturan role harus ditegakkan pada Firestore Security Rules, bukan hanya dengan menyembunyikan tombol. Mutasi stok, peminjaman, serta pengeluaran harus diuji terhadap permintaan bersamaan.

## 5. Batasan Implementasi dan Rancangan Pengembangan

| Topik | Implementasi saat ini (berdasarkan catatan kode) | Rancangan pengembangan |
|---|---|---|
| Bukti transaksi | Unggah belum tersedia | Upload file dan penyimpanan aman |
| Foto inventaris | Base64 pada Firestore `inventoryPhotos` | Firebase Storage dengan metadata Firestore |
| Operasi data | Flutter langsung ke Firestore; penulisan keuangan dan tambah barang memakai `runTransaction`, diperiksa `firestore.rules` | Backend tepercaya untuk mutasi sensitif |
| Buat akun | Firebase Auth sekunder + `users/{uid}` | Alur server-side dengan Admin SDK / undangan |
| Hapus akun | Profil Firestore dan akses aplikasi dihapus; identitas Auth belum otomatis terhapus | Penghapusan Auth user yang terotorisasi dan konsisten |
| Total Kas | **Total Kas Terkoneksi** menurut kelompok koneksi UID unik | Optimalisasi agregasi, tanpa mengubah definisinya |
| Peminjam | Nama teks yang dimasukkan Admin | Relasi eksplisit dengan UID pengguna |
| Profil dan password | Melihat profil; ubah password setelah login; reset via email dari login | Perluasan edit profil jika dibutuhkan |
| Laporan | Ringkasan laporan; grafik arus kas ada di halaman Keuangan. Belum ada grafik atau ekspor pada halaman Laporan | Ekspor PDF/CSV bila diimplementasikan |

> **Khusus README:** jangan mempresentasikan kolom rancangan sebagai fitur yang sudah bisa didemokan. Admin **belum memiliki** use case reset password pengguna lain; pengguna dapat mengganti password sendiri setelah login atau meminta reset melalui email pada halaman login.
 **Total Kas Terkoneksi** dihitung dari UID unik dalam kelompok koneksi Bendahara; tidak sama dengan seluruh kas organisasi jika ada Bendahara di luar cakupan koneksi.

## 🚀 Status Pengembangan

**Dalam pengembangan (Work in Progress).**

Proyek dikembangkan secara bertahap, dimulai dari analisis kebutuhan, penyusunan Product Requirements Document (PRD), perancangan UI/UX, hingga implementasi aplikasi menggunakan Flutter dan Firebase.

Fitur yang didokumentasikan merupakan ruang lingkup produk yang direncanakan dan tidak selalu menunjukkan bahwa seluruh fungsi telah selesai diimplementasikan.

### Implementasi saat ini

- Satu formulir **Masuk** dengan Firebase Authentication dan pilihan tampilan Anggota, Bendahara, atau Admin di atas email. Peran dan izin akun tetap diverifikasi dari Firestore; pilihan tampilan tidak dapat menaikkan hak akses akun.

- Proses masuk dan atur ulang password memakai `flutter_bloc`: tindakan formulir menjadi event, hasil Firebase menjadi state, dan tampilan mengikuti state tersebut. Penjelasan kode tersedia di [Alur Login BLoC](docs/ALUR_LOGIN_BLOC.md).

- Bar **Tampilan Admin** di atas halaman utama dihapus. Admin dapat membuka tampilan peran lain melalui **Profil → Ganti Tampilan Peran**; pengelolaan akun tersedia di **Profil → Kelola Pengguna**.

- Pengenalan aplikasi tiga langkah pada pembukaan pertama dengan tombol **Selanjutnya**, **Lewati**, dan **Mulai**. Status selesai disimpan di perangkat.

- Admin dapat membuka tampilan Anggota, Bendahara, dan Admin dari menu ganti tampilan setelah masuk. Empat tab utama adalah Beranda, Inventaris, Keuangan, dan Profil.

- Setelah login Firebase, transaksi, inventaris, peminjaman, pergerakan stok, dan pengguna dibaca dari Firestore dengan filter `organizationId`. Aplikasi yang dijalankan tidak memuat data contoh lokal.

- Form pemasukan/pengeluaran Bendahara menyimpan ke Firestore lewat transaksi atomik. Aturan Firestore menolak saldo negatif dan mengharuskan pembaruan saldo dipasangkan dengan catatan transaksi.

- Admin dapat menambah dan mengubah barang, menyesuaikan stok dengan alasan, mengarsipkan barang, mencatat peminjaman, serta mengembalikan barang dengan kondisi baik/rusak/hilang. Stok siap pinjam hanya bertambah untuk barang yang kembali dalam kondisi baik.

- Admin menyimpan inventaris, foto barang yang diperkecil, peminjaman, dan pengembalian langsung lewat transaksi Firestore. Pada **Tambah Pengguna**, Admin memilih peran serta mengisi password awal dan konfirmasinya. Akun dibuat di Firebase Authentication melalui instance sekunder agar sesi Admin tidak terganti; profil, peran, dan status akun disimpan di Firestore. Password tidak disimpan di Firestore atau ditampilkan di daftar pengguna. Angka **Pengguna** di dashboard menghitung dokumen akun yang dibuat Admin pada organisasi ini, bukan angka contoh.

- Bendahara mengirim, menerima, menolak, membatalkan, dan memutus koneksi melalui Firestore; notifikasi koneksi tersimpan di koleksi `notifications`.

- Grafik arus kas mengikuti transaksi yang dibaca dari Firestore pada bulan berjalan.

- Menu **Data Profil** membaca dokumen akun langsung dari Firestore. Menu **Ubah Password** memverifikasi password saat ini dan memperbaruinya melalui Firebase Authentication.

- **Kelola Pengguna** menyediakan ubah status/peran dan **Hapus Akun**. Hapus Akun menghapus profil Firestore serta akses aplikasi; identitas email Firebase Authentication tetap perlu dihapus terpisah dari **Authentication → Users** jika ingin menghapusnya sepenuhnya atau memakai ulang email. Admin tidak dapat menghapus akun sendiri.

- Konfirmasi tindakan memakai dialog dengan tombol aksi penuh di atas dan **Batal** di bawah; hasil tindakan memakai dialog status yang seragam.

Peta lengkap lokasi koleksi dan field untuk demo tersedia di [docs/PETA_FIELD_FIREBASE.md](docs/PETA_FIELD_FIREBASE.md).

Firebase Core sudah diinisialisasi pada Android memakai `android/app/google-services.json` dan pada web memakai `lib/firebase_options.dart` untuk proyek `karangtaruna-apps`. Provider email/password telah diaktifkan di Firebase Authentication. Login membaca peran, status aktif, dan organisasi dari dokumen Firestore `users/{uid}`. Akun Admin pertama disiapkan oleh pengelola proyek; kredensial dan alamat email akun awal tidak dicantumkan dalam README publik.

Email pengguna baru wajib berakhiran tepat `@gmail.com`. Form tambah pengguna, layanan pembuatan akun, login, pemulihan sesi, dan aturan Firestore menerapkan kebijakan ini. Satu-satunya pengecualian adalah akun Admin pertama yang telah disiapkan, yang tetap harus memiliki peran `admin` pada profilnya. Akun lama dengan domain lain tidak dapat mengakses aplikasi setelah aturan ini diterapkan; Admin perlu membuat akun Gmail pengganti bila diperlukan. Pada paket Spark, aturan Firestore melindungi data aplikasi, tetapi tidak mencegah seseorang memanggil API Firebase Authentication secara langsung untuk membuat identitas tanpa profil aplikasi.

**Status backend:** aplikasi memakai Firebase Authentication dan Firestore pada paket Spark tanpa Cloud Functions. Halaman masuk menyediakan satu aksi **Masuk**; tidak ada pilihan mode lokal. Aturan Firestore memeriksa peran, organisasi, dan beberapa invariant transaksi. Data contoh hanya dipakai oleh tes otomatis. Cloud Storage untuk Firebase memerlukan paket Blaze, sehingga foto inventaris disimpan sebagai JPEG kecil (maksimal 150 KB sebelum Base64) di Firestore. Unggah bukti transaksi belum tersedia.

### Menyiapkan login Firebase

1\. Database Cloud Firestore `(default)` telah dibuat di Jakarta (`asia-southeast2`), provider Email/Password telah diaktifkan, dan aturan `firestore.rules` telah diterapkan pada proyek `karangtaruna-apps`.

2\. Admin pertama sudah dibuat. Masuk memakai kredensial yang telah disiapkan, atau gunakan **Atur / lupa password** untuk mengatur ulang password melalui email. Pengguna baru berikutnya dibuat dari **Kelola Pengguna**.

3\. Aturan Firestore membatasi akses baca dan tulis menurut peran dan organisasi. Terapkan perubahan aturan dengan `firebase deploy --only firestore:rules --project karangtaruna-apps`.

4\. Admin menentukan password awal saat membuat akun dan menyampaikannya kepada pengguna melalui saluran yang aman. Pengguna dapat mengganti password sendiri dari **Profil → Ubah Password** dengan memverifikasi password saat ini; persetujuan Admin tidak diperlukan. Alur **Atur / lupa password** pada halaman masuk tetap tersedia jika pengguna lupa password. Penonaktifan profil mencegah masuk ke aplikasi, tetapi tidak menonaktifkan identitas di Firebase Authentication.

Aturan akses dapat diuji tanpa data nyata dengan JDK 21 atau lebih baru: jalankan `npm ci --prefix firebase-tests`, lalu `npm test --prefix firebase-tests`. Pengujian memakai proyek emulator `demo-karangtaruna` dan mencakup transaksi kas, inventaris, akun, serta koneksi Bendahara.

Jika provider login, profil, atau izin baca belum disiapkan, aplikasi menampilkan pesan kesalahan dan tidak memberi akses. Jangan menaruh password pengguna di berkas proyek.

PRD v2.0 menjadi acuan jika gambar ZIP atau dokumen UI/UX lama berbeda. Aplikasi tidak menyediakan transfer antarbendahara. **Total Kas Terkoneksi** Bendahara menjumlahkan saldo dirinya dan seluruh Bendahara dalam satu komponen koneksi aktif, masing-masing sekali, termasuk rantai A–B–C. Admin dan Anggota melihat gabungan saldo unik semua Bendahara yang memiliki koneksi aktif dalam organisasi. Permintaan `pending` dan koneksi terputus tidak dihitung. Aturan akses detail transaksi antar-role masih perlu diputuskan secara produk sebelum produksi.

Jalankan pratinjau web di alamat tetap `http://127.0.0.1:5080/`: pilih konfigurasi **Flutter Web (localhost:5080)** saat menekan F5 di VS Code, atau jalankan tugas **Flutter Web: port 5080** melalui **Terminal → Run Task** / `run-web.bat`, lalu buka alamat tersebut di Chrome. Skrip memakai perangkat `web-server` agar tetap melayani halaman meski koneksi debugger Chrome terputus. Panel **Mobile Preview** pada workspace ini juga diarahkan ke alamat yang sama. Perintah biasa `flutter run -d chrome` tanpa opsi `--web-port=5080` akan memilih port otomatis. Hentikan sesi sebelumnya dengan Ctrl+C sebelum menjalankan sesi baru pada port yang sama. Untuk perangkat Android, gunakan perintah Flutter sesuai emulator yang tersedia. Periksa kode dengan `flutter analyze` dan `flutter test`. Firebase telah dikonfigurasi pada Android dan Web; iOS memerlukan pendaftaran aplikasi dan konfigurasi tersendiri. Sebelum pemakaian produksi, putuskan akses detail transaksi antarperan dan lakukan pengujian keamanan lanjutan.

Jika menjalankan Flutter langsung dari PowerShell dan `pub.dev` tidak dapat diakses, atur `$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"` pada terminal tersebut sebelum `flutter pub get` atau `flutter run`. Konfigurasi F5 dan `run-web.bat` sudah mengatur mirror ini untuk proses masing-masing.

## 📌 Penutup

Karang Taruna Digital diharapkan dapat menjadi solusi pengelolaan organisasi kepemudaan yang lebih modern, transparan, dan terorganisasi.

Dengan mengintegrasikan manajemen keuangan, inventaris, pengguna, serta peminjaman barang dalam satu aplikasi, pengurus dan anggota Karang Taruna dapat mengakses informasi organisasi dengan lebih mudah dan efisien.
