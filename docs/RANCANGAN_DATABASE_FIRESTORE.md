# Rancangan database Firestore — Karangtaruna Apps

**Status:** rancangan untuk dipelajari dan dibuat oleh pemilik proyek. Dokumen ini tidak membuat koleksi, dokumen, atau akun di Firebase.

**Acuan:** kode Flutter dan `firestore.rules` saat ini, dengan kebutuhan lanjutan dari `PRD_Karang_Taruna_Digital_v2_0.md`. Nama dan field pada bagian **Aktif dalam aplikasi** harus dipakai persis agar aplikasi dapat membaca datanya. Bagian **Rencana lanjutan** belum dihubungkan ke aplikasi.

## Cara membaca rancangan

- Proyek Firebase: `karangtaruna-apps`; database: Cloud Firestore `(default)` di Jakarta (`asia-southeast2`).
- Firestore memakai **koleksi → dokumen → field**. Koleksi adalah padanan terdekat dari tabel SQL, tetapi tidak memiliki skema kolom tetap.
- Semua koleksi aktif di bawah ini berada pada **root** database (Parent path `/`), bukan di dalam dokumen `users`.
- `{uid}` adalah UID dari Firebase Authentication. `{id otomatis}` berarti ID dokumen dibuat otomatis oleh Firestore. ID dokumen bukan field kecuali tabel di bawah secara eksplisit menyebut field tersebut.
- Pada pilihan **Type** di Firebase Console: gunakan `string` untuk teks/UID, `number` untuk bilangan bulat, `boolean` untuk benar/salah, `timestamp` untuk tanggal/waktu, `null` untuk nilai kosong yang memang diminta, dan `array` untuk daftar UID. Di dalam `array`, setiap UID bertipe `string`. Firestore menyimpan angka sebagai integer bila diisi tanpa pecahan; nominal rupiah ditulis `1500000`, bukan teks `"Rp 1.500.000"`.
- Lihat [daftar tipe data resmi Firestore](https://firebase.google.com/docs/firestore/manage-data/data-types) bila pilihan Type di Console berbeda bahasa atau tampilannya berubah.
- Semua field pada tabel wajib saat dokumen dibuat, kecuali diberi tanda **opsional** atau **sesudah perubahan**. `createdAt`, `updatedAt`, dan waktu aksi diisi dengan waktu server oleh aplikasi.
- **Asal `karangtaruna-main`:** ini adalah nilai `organizationId` yang terlihat pada dokumen akun di koleksi `users` pada tangkapan layar Firebase Anda. Untuk mengeceknya sendiri: **Authentication → Users → salin UID Admin → Firestore Database → Data → `users` → pilih dokumen dengan ID UID tersebut → lihat nilai `organizationId`**. Aplikasi membaca nilai itu dari profil Admin di `lib/firebase_login.dart`, lalu menyalinnya ke data baru; ini bukan nama database atau Project ID Firebase. Pakai nilai yang sama dengan profil Admin, jangan mengarang nilai baru untuk dokumen terkait.
- Jika kelak Anda ingin **mengganti** `organizationId`, perubahan satu dokumen saja tidak cukup: akun dan data keuangan/inventaris terkait harus tetap menunjuk organisasi yang sama. Aplikasi sekarang belum mempunyai menu untuk memigrasikan organisasi; jangan mengganti nilainya langsung pada profil Admin yang sudah dipakai.
- Semua contoh nilai di bawah adalah **ilustrasi bentuk data**, kecuali `karangtaruna-main` yang memang tampak pada profil organisasi Anda. Teks seperti `<UID_BENDAHARA>` harus diganti dengan UID nyata; jangan disimpan apa adanya.

### Dari mana nilai dinamis diambil?

| Nilai | Tempat mendapatkannya |
| --- | --- |
| `<UID_ADMIN>`, `<UID_BENDAHARA>`, `<UID_USER>` | Firebase Console → **Authentication → Users → kolom User UID**. ID dokumen akun yang sama terlihat di **Firestore → `users`**. Pilih UID sesuai peran akun yang dimaksud. |
| `organizationId` | Field `organizationId` pada dokumen **`users/{UID_ADMIN}`** yang sudah ada; untuk organisasi sekarang tampak `karangtaruna-main`. |
| `itemCode` dan ID barang | Field `code` dari form Tambah Barang; ID barang berbentuk `{organizationId}__{code}`. |
| `<ID_TRANSAKSI_TERBARU>` | ID dokumen yang dihasilkan setelah aplikasi membuat `financialTransactions`. |
| `<ID_DOKUMEN_BORROWINGS>` | ID dokumen yang dihasilkan setelah aplikasi membuat `borrowings`. |
| `<ID_PASANGAN_KONEKSI>` | ID dokumen `treasurerConnectionRequests` yang dibuat aplikasi dari organisasi dan dua UID Bendahara yang diurutkan. |
| Waktu `createdAt`, `updatedAt`, `at`, `borrowedAt`, `returnedAt` | Diisi otomatis dari waktu server saat aksi aplikasi berhasil. `transactionDate` dan `dueAt` berasal dari tanggal yang dipilih pada form. |
| `imageBase64` | Hasil olahan foto JPEG oleh aplikasi, bukan kalimat yang diketik atau alamat file laptop. |

## Peta 11 koleksi aktif, dikelompokkan per modul

Ketik nama pada kolom **Collection ID** persis seperti tabel berikut (huruf besar/kecil berpengaruh). Semua berada pada Parent path `/`.

| Modul | Collection ID / nama koleksi | ID dokumen | Kapan muncul |
| --- | --- | --- | --- |
| Akun | `users` | UID akun Authentication | Admin membuat akun |
| Keuangan | `financialTransactions` | ID otomatis | Bendahara mencatat pemasukan/pengeluaran |
| Keuangan | `cashAccounts` | UID Bendahara | Transaksi pertama Bendahara, bersama `financialTransactions` |
| Inventaris | `inventoryItems` | `{organizationId}__{KODE}` | Admin menambah barang |
| Inventaris | `inventoryPhotos` | Sama dengan ID `inventoryItems` | Barang diberi foto |
| Inventaris | `inventoryMovements` | ID otomatis | Tambah/edit/stok/arsip/pinjam/kembali barang |
| Peminjaman | `borrowings` | ID otomatis | Admin mencatat peminjaman |
| Peminjaman | `borrowingReturns` | ID otomatis | Admin mencatat pengembalian |
| Koneksi Bendahara | `treasurerConnectionRequests` | `{organizationId}__{uidA}__{uidB}` | Bendahara mengirim permintaan |
| Koneksi Bendahara | `treasurerConnections` | Sama dengan ID permintaan | Permintaan koneksi diterima |
| Koneksi Bendahara | `notifications` | ID otomatis | Aktivitas koneksi Bendahara |

**Urutan melihat hasil di Console:** buat akun melalui Admin → lihat `users`; catat pemasukan melalui Bendahara → lihat `financialTransactions` dan `cashAccounts`; tambah barang melalui Admin → lihat `inventoryItems` dan `inventoryMovements` (`inventoryPhotos` bila ada foto); catat peminjaman/pengembalian → lihat `borrowings` dan `borrowingReturns`; buat koneksi dua Bendahara → lihat tiga koleksi Koneksi Bendahara. Koleksi akan muncul setelah ada dokumen pertama yang valid.

**Status Firebase Console, 28 Oktober 2026:** delapan koleksi selain `users`, `financialTransactions`, dan `cashAccounts` telah dibuat di root `/` dengan satu dokumen penanda bernama `_schema`. Dokumen `_schema` pada tiap koleksi sekarang berisi **nama field dan tipe data sesuai tabel rancangan di bawah**; beberapa field yang pada dokumen nyata baru muncul sesudah perubahan (`updatedAt` peminjaman dan `disconnectedAt` koneksi) juga ditampilkan agar dapat dipelajari. Nilainya adalah contoh, **bukan data bisnis dan bukan skema yang diberlakukan Firestore**. Semua penanda memakai `organizationId: "__schema__"` (bukan `karangtaruna-main`), serta UID/kode contoh. Karena query aplikasi memfilter organisasi nyata atau penerima notifikasi, penanda tidak tampil sebagai barang, pinjaman, koneksi, atau notifikasi pengguna. Saat data asli disimpan lewat aplikasi, dokumen baru dengan ID dan field yang tepat akan berada dalam koleksi yang sama. Jangan menyalin `_schema` untuk membuat transaksi, barang, peminjaman, atau koneksi.

**Pemeriksaan tiga koleksi awal:** dokumen `cashAccounts` yang tampak di Console memakai ID otomatis yang tidak sama dengan field `holderUid`, sedangkan `lastTransactionId` masih kosong meskipun `balance` berisi angka. Kode aplikasi memakai UID Bendahara sebagai ID `cashAccounts` dan menulis saldo bersama `financialTransactions`; data awal itu perlu ditinjau sebelum dipakai sebagai saldo acuan. Belum ada perubahan pada dokumen awal tersebut.

### 1. `users/{uid}` — profil dan hak akses

UID dokumen harus sama dengan UID akun di **Firebase Authentication**. Password tidak disimpan di Firestore. Email akun baru wajib `@gmail.com`; akun Admin pertama dengan email kampus adalah pengecualian yang sudah ada.

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `name` | `string` | `Sukardi` | Nama lengkap pengguna. |
| `email` | `string` | `sukardi@gmail.com` | Email akun, huruf kecil. |
| `role` | `string` | `bendahara` | Tepat salah satu: `admin`, `bendahara`, `anggota`. |
| `organizationId` | `string` | `karangtaruna-main` | Ambil dari profil Admin pada `users/{UID_ADMIN}`. |
| `isActive` | `boolean` | `true` | Awalnya `true`; `false` menutup akses aplikasi. |
| `createdBy` | `string` | `<UID_ADMIN>` | UID Admin pembuat akun; Admin awal dapat tidak memiliki field ini. |
| `createdAt` | `timestamp` | Waktu saat akun dibuat | Diisi server saat proses pembuatan. |
| `updatedAt` | `timestamp` | Sama dengan `createdAt` saat awal | Waktu perubahan terakhir, diisi server. |
| `updatedBy` | `string`, sesudah perubahan | `<UID_ADMIN>` | Baru ada setelah Admin mengubah peran/status. |

Sumber kode: `lib/firebase_admin.dart`, `lib/firebase_login.dart`.

**Rencana kode pendek `001`:** tambahkan `memberCode` bertipe `string` pada dokumen `users/{uid}` (contoh `"001"`, `"002"`). Nilai ini hanya kode yang ditampilkan, **bukan pengganti UID Authentication atau ID dokumen `users`**. Field tersebut belum ditulis/dibaca oleh aplikasi dan belum diizinkan dalam `firestore.rules`. Agar nomor baru tidak ganda saat dua Admin membuat akun bersamaan, rancangan lanjutannya memakai `userCodeCounters/{organizationId}` pada tabel rencana di bawah. Jangan menambahkannya secara acak pada data nyata sebelum kode aplikasi, aturan akses, dan pengisian kode akun lama disiapkan. [Firebase menjelaskan UID khusus hanya saat pembuatan akun dengan Admin SDK](https://firebase.google.com/docs/auth/admin/manage-users).

### 2. `financialTransactions/{id otomatis}` — buku transaksi kas

Satu dokumen adalah satu pemasukan atau pengeluaran milik **satu Bendahara**. Dokumen tidak dihapus atau diubah melalui aplikasi saat ini.

**Contoh isi adalah nilai nyata/ilustrasi, bukan keterangan field.** Pada layar yang Anda tunjukkan, `organizationId` seharusnya berisi `karangtaruna-main`, bukan `ID organisasi.`; `holderUid` harus berisi UID Bendahara sungguhan, bukan `UID Bendahara pemegang kas.`

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `organizationId` | `string` | `karangtaruna-main` | Nilai sama dengan profil Bendahara. |
| `holderUid` | `string` | `<UID_BENDAHARA>` | UID Bendahara pemegang kas dari Authentication. |
| `holderName` | `string` | `Sukardi` | Nama Bendahara saat transaksi dicatat. |
| `type` | `string` | `income` | `income` untuk pemasukan atau `expense` untuk pengeluaran. |
| `title` | `string` | `Iuran anggota` | Sumber dana/keperluan sesuai form. |
| `category` | `string` | `Lainnya` | Nama kategori, bukan ID koleksi kategori. |
| `amount` | `number` (integer) | `1500000` | Nominal positif dalam rupiah. |
| `note` | `string` | `Iuran bulan Oktober` | Catatan; boleh string kosong `""`. |
| `transactionDate` | `timestamp` | `28 Okt 2026 09:00 WIB` | Tanggal transaksi yang dipilih pengguna. |
| `createdBy` | `string` | `<UID_BENDAHARA>` | UID Bendahara pencatat. |
| `createdAt` | `timestamp` | Waktu saat transaksi disimpan | Diisi server. |

Sumber kode: `lib/cloud_stores.dart` (`CloudFinanceStore.addTransaction`).

### 3. `cashAccounts/{uid}` — saldo Bendahara

ID dokumen adalah UID Bendahara. Saldo ini merupakan nilai ringkasan yang **harus berubah bersamaan** dengan penambahan `financialTransactions`; jangan dibuat atau diedit sebagai angka bebas di Console.

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `organizationId` | `string` | `karangtaruna-main` | Nilai sama dengan profil Bendahara. |
| `holderUid` | `string` | `<UID_BENDAHARA>` | Sama dengan ID dokumen akun kas. |
| `holderName` | `string` | `Sukardi` | Nama Bendahara. |
| `balance` | `number` (integer) | `1500000` | Hasil transaksi, bukan angka yang bebas diketik. |
| `lastTransactionId` | `string` | `<ID_TRANSAKSI_TERBARU>` | ID transaksi penyebab perubahan saldo. |
| `updatedAt` | `timestamp` | Waktu transaksi terbaru | Diisi server. |

Saldo yang benar mengikuti jumlah `income` dikurangi `expense` pada buku transaksi. Sumber kode: `lib/cloud_stores.dart` dan aturan pasangan transaksi/saldo di `firestore.rules`.

### 4. `inventoryItems/{organizationId}__{KODE}` — data barang

Contoh ID: `karangtaruna-main__INV-004`. `KODE` dinormalisasi menjadi huruf besar dan hanya boleh memuat huruf, angka, `-`, `_` (maksimum 50 karakter). Nama koleksinya **`inventoryItems`**, bukan `inventory`.

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `organizationId` | `string` | `karangtaruna-main` | Nilai sama dengan profil Admin. |
| `code` | `string` | `INV-004` | Kode unik barang. |
| `name` | `string` | `Speaker aktif 12 inch` | Nama barang. |
| `category` | `string` | `Elektronik` | Nama kategori barang. |
| `location` | `string` | `Aula sekretariat` | Lokasi penyimpanan. |
| `total` | `number` (integer) | `2` | Jumlah unit yang tercatat. |
| `available` | `number` (integer) | `2` | Unit siap dipinjam saat awal. |
| `damaged` | `number` (integer) | `0` | Unit rusak saat awal. |
| `lost` | `number` (integer) | `0` | Unit hilang saat awal. |
| `archived` | `boolean` | `false` | `true` menyembunyikan barang dari daftar aktif. |
| `createdBy` | `string` | `<UID_ADMIN>` | UID Admin pembuat barang. |
| `createdAt` | `timestamp` | Waktu saat barang dibuat | Diisi server. |
| `updatedAt` | `timestamp` | Sama dengan `createdAt` saat awal | Diisi server. |

Saat dibuat: `total = available = stok awal`, `damaged = lost = 0`. Jumlah yang sedang dipinjam dihitung oleh aplikasi sebagai `total - available - damaged - lost`; tidak ada field `borrowed`. Sumber kode: `lib/cloud_stores.dart` (`CloudInventoryStore`).

### 5. `inventoryPhotos/{organizationId}__{KODE}` — foto barang

Dokumen ini **opsional** dan memakai ID yang sama dengan barang terkait. Saat ini foto JPEG kecil disimpan sebagai teks Base64 di Firestore, bukan sebagai URL Cloud Storage.

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `organizationId` | `string` | `karangtaruna-main` | Nilai sama dengan barang. |
| `itemCode` | `string` | `INV-004` | Kode barang terkait. |
| `format` | `string` | `jpeg` | Format foto saat ini. |
| `imageBase64` | `string` | Teks Base64 JPEG hasil aplikasi | Bukan path file atau URL; jangan isi teks contoh. |
| `updatedBy` | `string` | `<UID_ADMIN>` | UID Admin yang memilih/mengganti foto. |
| `updatedAt` | `timestamp` | Waktu foto disimpan | Diisi server. |

Jika barang belum mempunyai foto, jangan membuat dokumen kosong. Sumber kode: `lib/cloud_stores.dart`, `lib/inventory_photo.dart`.

### 6. `inventoryMovements/{id otomatis}` — riwayat perubahan inventaris

Setiap perubahan barang menghasilkan satu catatan. Koleksi ini dipakai untuk menampilkan riwayat dan bukan tempat mengedit stok secara langsung.

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `organizationId` | `string` | `karangtaruna-main` | Nilai sama dengan barang. |
| `itemCode` | `string` | `INV-004` | Kode barang yang berubah. |
| `action` | `string` | `Tambah barang` | Nilai lain: `Edit barang`, `Update stok`, `Arsip barang`, `Peminjaman`, `Pengembalian`. |
| `reason` | `string` | `Stok awal` | Alasan atau ringkasan tindakan. |
| `beforeAvailable` | `number` (integer) | `0` | Stok tersedia sebelum tindakan. |
| `afterAvailable` | `number` (integer) | `2` | Stok tersedia sesudah tindakan. |
| `actorUid` | `string` | `<UID_ADMIN>` | UID Admin pelaku. |
| `at` | `timestamp` | Waktu tindakan | Diisi server. |

Sumber kode: `lib/cloud_stores.dart` (`_movement`).

### 7. `borrowings/{id otomatis}` — peminjaman barang

`borrower` saat ini adalah **nama yang diketik**, bukan UID akun `users`.

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `organizationId` | `string` | `karangtaruna-main` | Nilai sama dengan barang. |
| `itemCode` | `string` | `INV-004` | Kode barang yang dipinjam. |
| `borrower` | `string` | `Rizky Pratama` | Nama peminjam, bukan UID. |
| `quantity` | `number` (integer) | `1` | Jumlah dipinjam, lebih dari nol. |
| `returned` | `number` (integer) | `0` | Jumlah yang sudah kembali; awalnya nol. |
| `dueAt` | `timestamp` | `4 Nov 2026 09:00 WIB` | Tenggat pengembalian. |
| `note` | `string` | `Untuk acara warga` | Catatan; boleh string kosong `""`. |
| `borrowedAt` | `timestamp` | Waktu saat pinjaman dicatat | Diisi server. |
| `createdBy` | `string` | `<UID_ADMIN>` | UID Admin pencatat. |
| `updatedAt` | `timestamp`, sesudah pengembalian | Waktu pengembalian terakhir | Baru ada setelah `returned` bertambah. |

Status aktif/selesai/terlambat dihitung dari `quantity`, `returned`, dan `dueAt`; tidak ada field `status` pada implementasi saat ini. Sumber kode: `lib/cloud_stores.dart`.

### 8. `borrowingReturns/{id otomatis}` — setiap pengembalian

Satu peminjaman dapat mempunyai beberapa dokumen pengembalian bila kembali secara bertahap.

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `organizationId` | `string` | `karangtaruna-main` | Nilai sama dengan pinjaman. |
| `borrowingId` | `string` | `<ID_DOKUMEN_BORROWINGS>` | ID peminjaman asal. |
| `itemCode` | `string` | `INV-004` | Kode barang. |
| `good` | `number` (integer) | `1` | Unit kembali dalam kondisi baik. |
| `damaged` | `number` (integer) | `0` | Unit kembali rusak. |
| `lost` | `number` (integer) | `0` | Unit dilaporkan hilang. |
| `note` | `string` | `Dikembalikan lengkap` | Wajib berisi bila rusak/hilang; boleh kosong jika semua baik. |
| `returnedAt` | `timestamp` | Waktu pengembalian dicatat | Diisi server. |
| `returnedBy` | `string` | `<UID_ADMIN>` | UID Admin pencatat. |

`good + damaged + lost` harus lebih dari nol dan tidak boleh melebihi sisa pinjaman. Pengembalian baik menaikkan `inventoryItems.available`; rusak/hilang menaikkan field masing-masing. Sumber kode: `lib/cloud_stores.dart`.

### 9. `treasurerConnectionRequests/{id pasangan}` — permintaan koneksi

ID dokumen adalah `{organizationId}__{uidA}__{uidB}` dengan dua UID diurutkan. Satu pasangan memakai satu ID agar permintaan ganda dapat dicegah.

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `organizationId` | `string` | `karangtaruna-main` | Organisasi kedua Bendahara. |
| `requesterId` | `string` | `<UID_BENDAHARA_A>` | UID Bendahara pengirim. |
| `recipientId` | `string` | `<UID_BENDAHARA_B>` | UID Bendahara penerima. |
| `status` | `string` | `pending` | Nilai lain: `accepted`, `rejected`, `cancelled`, `disconnected`. |
| `createdAt` | `timestamp` | Waktu saat permintaan dikirim | Diisi server. |
| `respondedAt` | `null` saat awal; kemudian `timestamp` | `null` | Diisi waktu saat permintaan dijawab/dibatalkan/diputus. |

Sumber kode: `lib/cloud_connections.dart`.

### 10. `treasurerConnections/{id pasangan}` — koneksi yang diterima

ID dokumen sama dengan permintaan pasangannya. Dokumen baru muncul ketika penerima menyetujui; `pending` tidak dihitung sebagai koneksi aktif.

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `organizationId` | `string` | `karangtaruna-main` | Organisasi kedua Bendahara. |
| `holderIds` | `array`, elemen `string` | [`<UID_BENDAHARA_A>`, `<UID_BENDAHARA_B>`] | Tepat dua UID Bendahara, diurutkan. |
| `active` | `boolean` | `true` | `false` sesudah koneksi diputus. |
| `joinedAt` | `timestamp` | Waktu saat permintaan diterima | Diisi server. |
| `disconnectedAt` | `timestamp`, sesudah putus | Waktu saat koneksi diputus | Baru ada setelah koneksi diputus. |

Koneksi memengaruhi cakupan **Total Kas Terkoneksi**, tetapi tidak memindahkan uang. Sumber kode: `lib/cloud_connections.dart`, `lib/connection_scope.dart`.

### 11. `notifications/{id otomatis}` — pemberitahuan koneksi

Implementasi saat ini membuat notifikasi untuk aktivitas koneksi Bendahara.

| Field | Pilih Type | Contoh isi/nilai | Arti |
| --- | --- | --- | --- |
| `organizationId` | `string` | `karangtaruna-main` | Organisasi kedua Bendahara. |
| `recipientId` | `string` | `<UID_BENDAHARA_B>` | UID penerima notifikasi. |
| `sourceUid` | `string` | `<UID_BENDAHARA_A>` | UID pelaku tindakan. |
| `category` | `string` | `connection` | Nilai kategori yang dipakai sekarang. |
| `title` | `string` | `Permintaan Koneksi Bendahara` | Judul pemberitahuan. |
| `body` | `string` | `Sukardi memperbarui koneksi Bendahara.` | Ringkasan singkat. |
| `referenceId` | `string` | `<ID_PASANGAN_KONEKSI>` | ID permintaan/koneksi terkait. |
| `read` | `boolean` | `false` | Menjadi `true` setelah dibaca. |
| `createdAt` | `timestamp` | Waktu notifikasi dibuat | Diisi server. |

Sumber kode: `lib/cloud_connections.dart` dan `firestore.rules`.

## Hubungan antardata

| Sumber | Mengarah ke | Kunci penghubung |
| --- | --- | --- |
| Firebase Authentication | `users` | UID Auth = ID dokumen `users`. |
| `users` Bendahara | `cashAccounts`, `financialTransactions` | UID = ID akun kas = `holderUid`. |
| `inventoryItems` | `inventoryPhotos` | ID dokumen sama. |
| `inventoryItems` | `inventoryMovements`, `borrowings` | `code` = `itemCode` dalam organisasi yang sama. |
| `borrowings` | `borrowingReturns` | ID dokumen pinjaman = `borrowingId`. |
| `treasurerConnectionRequests` | `treasurerConnections`, `notifications` | ID pasangan = ID dokumen koneksi = `referenceId`. |
| Seluruh dokumen organisasi | `users` | `organizationId` sama dengan organisasi profil akun. |

Firestore tidak membuat *foreign key* SQL. Konsistensi hubungan ini dijaga oleh kode dan aturan akses.

## Rencana lanjutan dari PRD — belum aktif di aplikasi

Jangan membuat koleksi berikut hanya untuk membuatnya terlihat di Console; kode Flutter saat ini belum menggunakan isinya.

| Usulan | Field dan Type yang direncanakan | Contoh nilai ilustratif | Status/keputusan |
| --- | --- | --- | --- |
| `organizations/{organizationId}` | `name: string`, `isActive: boolean`, `createdAt: timestamp`, `updatedAt: timestamp` | ID dokumen `karangtaruna-main`; `name: Karang Taruna Utama`; `isActive: true`; waktu diisi server | Direktori organisasi bila kelak ada lebih dari satu organisasi; sekarang aplikasi hanya memakai `organizationId` pada setiap dokumen. Perlu kode dan rules baru. |
| `cashGroups/{id otomatis}` | `organizationId: string`, `name: string`, `status: string`, `holderIds: array` berisi `string`, `createdAt: timestamp`, `updatedAt: timestamp` | `organizationId: karangtaruna-main`; `name: Kas Bendahara`; `status: active`; `holderIds: [<UID_A>, <UID_B>]` | Rekomendasi PRD untuk kelompok kas; aplikasi sekarang menghitung cakupan dari pasangan `treasurerConnections`. Jangan menambahkannya sebelum aturan migrasi cakupan kas diputuskan. |
| `auditLogs/{id otomatis}` | `organizationId: string`, `actorUid: string`, `action: string`, `targetId: string`, `details: map`, `at: timestamp` | `action: update-stock`; `actorUid: <UID_ADMIN>`; `targetId: karangtaruna-main__INV-004`; `details: {before: 2, after: 3}` | Dicadangkan pada rules dan kode Cloud Functions, tetapi penulisan audit server tersebut belum dipakai oleh alur aplikasi Spark. |
| `userAudit/{id otomatis}` | `action: string`, `actorUid: string`, `targetUid: string`, `organizationId: string`, `role: string`, `createdAt: timestamp` | `action: create`; `actorUid: <UID_ADMIN>`; `targetUid: <UID_USER>`; `organizationId: karangtaruna-main`; `role: anggota` | Ada di rancangan Cloud Functions untuk pembuatan akun; belum dipakai oleh alur pembuatan akun Flutter sekarang. |
| `userCodeCounters/{organizationId}` | `lastIssued: number` (integer), `updatedAt: timestamp` | ID dokumen `karangtaruna-main`; `lastIssued: 5` berarti kode terakhir `"005"` | Rencana pendukung `users.memberCode`. Nilai harus dinaikkan lewat transaksi atomik oleh kode aplikasi/server; belum dibuat/dibaca oleh aplikasi atau diatur dalam rules. |
| Tambahan pada `financialTransactions` | `receiptPath: string` (opsional), `status: string`, `reversalOf: string` (opsional) | `receiptPath: receipts/.../bukti.jpg`; `status: valid`; `reversalOf: <ID_TRANSAKSI_ASAL>` hanya bila koreksi | Bukti transaksi dan koreksi terlacak menurut PRD; belum ada di kode/rules yang aktif. |
| Tambahan pada `inventoryItems`/`borrowingReturns` | `condition: string`, `archivedAt: timestamp`, `photoPath: string` sesuai keputusan penyimpanan media | `condition: baik`; `archivedAt` waktu arsip; `photoPath: damage/.../foto.jpg` | PRD mengusulkan kondisi/foto kerusakan; aplikasi saat ini menyimpan foto barang di `inventoryPhotos` dan belum menyimpan foto pengembalian. |

Tidak diperlukan koleksi `reports`, `dashboard`, `categories`, atau `transfers` pada implementasi sekarang: laporan/grafik dihitung dari transaksi, kategori disimpan sebagai teks, dan PRD 2.0 melarang transfer antarbendahara.

## Bila nanti Anda membuatnya di Firebase Console

1. Buka **Firestore Database → Data**, pilih `(default)`, dan pastikan **Parent path `/`** saat memilih **Start collection**. Ketik nama koleksi **persis** seperti pada peta 11 koleksi di atas.
2. Firestore meminta dokumen pertama beserta field dan tipe datanya. Koleksi kosong tidak akan tampil. ID otomatis hanya dipakai pada koleksi yang memang bertanda `{id otomatis}`; jangan gunakan Auto ID untuk `users`, `cashAccounts`, `inventoryItems`, `inventoryPhotos`, atau dua koleksi koneksi.
3. Cocokkan UID dengan Firebase Authentication. Membuat `users/{uid}` saja **tidak** membuat akun login atau password.
4. Untuk transaksi, saldo, stok, peminjaman, pengembalian, koneksi, dan notifikasi, **buat lewat aksi aplikasi** setelah nama/fieldnya dipahami. Beberapa dokumen harus ditulis bersama dalam satu transaksi; dokumen contoh yang dibuat sendiri di Console dapat menyebabkan saldo, stok, dan riwayat tidak konsisten.
5. Mengubah rancangan field baru tidak otomatis mengubah aplikasi. Kode pembaca/penulis, validasi, dan `firestore.rules` harus disesuaikan sebelum field tambahan dipakai.

Rancangan ini merinci struktur yang cocok dengan aplikasi saat ini. `docs/PETA_FIELD_FIREBASE.md` tetap menjadi panduan cepat untuk mendemonstrasikan lokasi data setelah formulir diisi.
