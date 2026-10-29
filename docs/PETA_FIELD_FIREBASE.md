# Peta field Firebase — Karangtaruna Apps

Dokumen ini mengikuti kode aplikasi saat ini. Database yang dipakai ialah **Cloud Firestore**, bukan Realtime Database. Akun login ada di **Firebase Authentication**.

## Membuka data di Firebase Console

1. Buka proyek `karangtaruna-apps` di [Firebase Console](https://console.firebase.google.com/project/karangtaruna-apps/overview).
2. Di menu kiri, pilih **Databases & Storage → Firestore Database → Data**. Pilih database **`(default)`**. Buka nama koleksi, lalu ID dokumen, untuk melihat field dan nilainya.
3. Untuk melihat akun email dan UID, buka **Authentication → Users**. Cocokkan UID di sana dengan ID dokumen `users/{uid}` di Firestore.
4. Koleksi baru terlihat setelah aplikasi berhasil menyimpan minimal satu dokumen di koleksi itu. Segarkan halaman konsol setelah membuat data.

Tampilan **Realtime Database → Create Database** pada tangkapan layar tidak perlu dipakai. Membuat Realtime Database tidak akan menampilkan data aplikasi ini.

## Formulir → koleksi dan field

| Tindakan di aplikasi | Lokasi di Firestore | Field yang tersimpan / berubah |
| --- | --- | --- |
| Admin membuat pengguna | `users/{uid}` | `name`, `email`, `role` (`admin`/`bendahara`/`anggota`), `organizationId`, `isActive`, `createdBy`, `createdAt`, `updatedAt`. UID adalah ID dokumen yang sama dengan UID akun di Authentication. |
| Admin mengubah peran atau status | `users/{uid}` | `role`, `isActive`, `updatedBy`, `updatedAt` diperbarui. |
| Admin menghapus pengguna dari aplikasi | `users/{uid}` | Dokumen profil dihapus. Riwayat transaksi tetap ada. Identitas email di Authentication masih ada dan harus dihapus secara terpisah lewat konsol bila ingin menghapusnya sepenuhnya atau memakai ulang email. |
| Bendahara menambah pemasukan | `financialTransactions/{id otomatis}` | `organizationId`, `holderUid`, `holderName`, `type: income`, `title` (Sumber Dana), `category`, `amount`, `note`, `transactionDate`, `createdBy`, `createdAt`. `cashAccounts/{uid}` berisi saldo baru. |
| Bendahara menambah pengeluaran | `financialTransactions/{id otomatis}` | Field sama, dengan `type: expense` dan `title` dari Keperluan. `cashAccounts/{uid}.balance` berkurang. |
| Saldo Bendahara | `cashAccounts/{uid}` | `organizationId`, `holderUid`, `holderName`, `balance`, `lastTransactionId`, `updatedAt`. Dokumen muncul sesudah transaksi pertama. |
| Admin menambah barang | `inventoryItems/{organizationId}__{kode}` | `organizationId`, `code`, `name`, `category`, `location`, `total`, `available`, `damaged`, `lost`, `archived`, `createdBy`, `createdAt`, `updatedAt`. Ada catatan awal di `inventoryMovements`. |
| Admin memilih atau mengganti foto barang | `inventoryPhotos/{organizationId}__{kode}` | `organizationId`, `itemCode`, `format: jpeg`, `imageBase64` (foto diperkecil), `updatedBy`, `updatedAt`. Dokumen ini dibuat hanya bila foto dipilih; halaman Detail Inventaris memuatnya saat dibuka. |
| Admin mengubah barang, stok, atau mengarsipkan | `inventoryItems/{...}` dan `inventoryMovements/{id otomatis}` | Data barang yang relevan berubah; pergerakan mencatat `organizationId`, `itemCode`, `action`, `reason`, `beforeAvailable`, `afterAvailable`, `actorUid`, `at`. Arsip mengatur `archived: true`, bukan menghapus barang. |
| Admin mencatat peminjaman | `borrowings/{id otomatis}` | `organizationId`, `itemCode`, `borrower`, `quantity`, `returned`, `dueAt`, `note`, `borrowedAt`, `createdBy`. `inventoryItems.available` berkurang dan `inventoryMovements` bertambah. |
| Admin mencatat pengembalian | `borrowingReturns/{id otomatis}` | `organizationId`, `borrowingId`, `itemCode`, `good`, `damaged`, `lost`, `note`, `returnedAt`, `returnedBy`. `borrowings.returned` dan `updatedAt` berubah; jumlah baik/rusak/hilang di `inventoryItems` diperbarui dan `inventoryMovements` bertambah. |
| Bendahara meminta/menjawab koneksi | `treasurerConnectionRequests/{id pasangan}` | `organizationId`, `requesterId`, `recipientId`, `status`, `createdAt`, `respondedAt`. Status dapat menjadi `pending`, `accepted`, `rejected`, `cancelled`, atau `disconnected`. |
| Bendahara menerima/memutus koneksi | `treasurerConnections/{id pasangan}` | `organizationId`, `holderIds`, `active`, `joinedAt`, lalu `disconnectedAt` saat diputus. |
| Aktivitas koneksi Bendahara | `notifications/{id otomatis}` | `organizationId`, `recipientId`, `sourceUid`, `category`, `title`, `body`, `referenceId`, `read`, `createdAt`. |

**Password awal**, konfirmasi password, dan password baru tidak disimpan di Firestore. Firebase Authentication mengelola kredensial secara aman; konsol menampilkan akun dan UID, **bukan nilai password**. Angka `amount`/`balance` disimpan sebagai bilangan rupiah (misalnya `1500000`), sedangkan titik pemisah ribuan hanya tampilan. Tanggal dan waktu disimpan sebagai timestamp. `organizationId` dipakai untuk memisahkan data organisasi.

**Laporan dan grafik** menghitung data dari koleksi transaksi dan saldo; tidak membuat koleksi laporan tersendiri. Status onboarding/"Ingat Saya" disimpan lokal di perangkat. Foto inventaris tersedia dalam ukuran kecil di Firestore, bukan berupa URL Cloud Storage. Unggah bukti transaksi belum aktif.

## Urutan demo singkat

1. Masuk sebagai Admin, buat satu pengguna uji. Tunjukkan email/UID di **Authentication → Users**, lalu `users/{UID}` di **Firestore Database → Data**. Jangan tampilkan password di depan audiens.
2. Masuk sebagai Bendahara, catat pemasukan. Buka dokumen terbaru di `financialTransactions`, lalu `cashAccounts/{UID}` untuk menunjukkan saldo berubah. Coba pengeluaran dengan cara yang sama.
3. Masuk sebagai Admin, tambah barang. Buka `inventoryItems` dan `inventoryMovements`; lalu buat peminjaman dan pengembalian untuk menunjukkan `borrowings`, `borrowingReturns`, dan perubahan stok.
4. Bila ingin menunjukkan koneksi Bendahara, buat permintaan dari satu Bendahara ke Bendahara lain. Buka `treasurerConnectionRequests`, `treasurerConnections` setelah disetujui, dan `notifications`.

Jangan menghapus dokumen langsung dari Firebase Console saat demo karena itu melewati alur aplikasi dan dapat membuat data terkait tidak konsisten.
