# UI/UX Requirement — Sistem Inventori & Manajemen Keuangan Karang Taruna

**Versi:** 1.0  
**Platform:** Mobile App (Flutter)  
**Backend:** Firebase  
**Target utama:** Android smartphone 360–430 dp  
**Dokumen ini dioptimalkan untuk digunakan sebagai design context di Google Stitch.**

---

## 1. Tujuan Dokumen

Dokumen ini menjadi acuan utama untuk mendesain UI/UX aplikasi **Sistem Inventori & Manajemen Keuangan Karang Taruna**.

Desain harus:

- modern, ringan, dan mudah dipahami;
- mobile-first;
- tidak terlihat seperti koran, laporan, spreadsheet, atau dashboard enterprise yang padat;
- mengutamakan kartu, ikon, angka, status, whitespace, dan progressive disclosure;
- membedakan pengalaman berdasarkan role tanpa membuat aplikasi yang berbeda;
- menjaga transparansi keuangan organisasi;
- memastikan saldo tidak pernah diinput atau diedit manual.

### Prinsip keuangan utama

> **Saldo selalu dihitung dari transaksi yang valid. Saldo bukan field yang dapat diedit oleh pengguna.**

Rumus dasar:

```text
Saldo Bendahara = Total Pemasukan - Total Pengeluaran + Transfer Masuk - Transfer Keluar

Total Kas Organisasi = Total saldo seluruh bendahara
```

Transfer antarbendahara **tidak mengubah Total Kas Organisasi**.

---

# 2. Design Direction

## 2.1 Karakter visual

Gunakan gaya:

- clean;
- modern;
- minimal;
- youthful;
- friendly;
- trustworthy;
- community-oriented;
- professional tetapi tidak kaku.

Aplikasi harus terasa seperti aplikasi mobile modern, bukan sistem administrasi desktop yang dipindahkan ke layar kecil.

## 2.2 Aturan penting untuk Google Stitch

**DO:**

- gunakan visual hierarchy yang kuat;
- tampilkan angka penting dengan ukuran besar;
- gunakan card-based layout;
- gunakan icon yang mudah dipahami;
- gunakan status chip/badge;
- sisakan whitespace yang cukup;
- gunakan maksimal 4–5 section utama dalam satu layar;
- prioritaskan informasi yang bisa dipahami dalam 3–5 detik;
- gunakan progressive disclosure: detail muncul setelah pengguna membuka item/card;
- gunakan bottom sheet untuk pilihan sederhana;
- gunakan full screen form untuk input yang panjang.

**DON'T:**

- jangan membuat desain seperti koran;
- jangan membuat halaman penuh paragraf;
- jangan menampilkan banyak teks penjelasan dalam satu layar;
- jangan menggunakan tabel padat untuk mobile kecuali benar-benar diperlukan;
- jangan menampilkan seluruh data organisasi sekaligus;
- jangan membuat semua informasi memiliki bobot visual yang sama;
- jangan menggunakan lebih dari satu primary CTA dalam satu area utama;
- jangan menggunakan warna sebagai satu-satunya pembeda status.

### Target keterbacaan

Pengguna harus bisa mengetahui informasi utama layar dalam **3–5 detik**.

Urutan hierarchy yang diharapkan:

1. informasi atau angka utama;
2. primary action;
3. supporting information;
4. detail sekunder;
5. detail lengkap setelah pengguna melakukan tap.

---

# 3. Color System

## 3.1 Brand colors

| Token | Hex | Penggunaan |
|---|---|---|
| Primary | `#D0E7E6` | Soft surface, card highlight, selected background, section highlight |
| Accent | `#112E81` | Primary CTA, active icon, link, important number, focus state |
| Background | `#F7F9FC` | Main page background |
| Surface | `#FFFFFF` | Card, modal, bottom sheet, input surface |
| Text Primary | `#1B2430` | Main heading and body |
| Text Secondary | `#667085` | Helper text, metadata, secondary label |
| Border | `#D7DEE8` | Divider, outline input, card border |
| Success | `#2E7D32` | Income, available, success state |
| Warning | `#B7791F` | Pending, low stock, attention state |
| Danger | `#C62828` | Expense, error, destructive action |

## 3.2 Color rules

- `#D0E7E6` adalah **primary surface color**, bukan warna teks utama.
- `#112E81` adalah **accent/interactivity color** dan harus dominan pada primary button dan active state.
- Tombol dengan background `#112E81` menggunakan teks putih.
- Informasi pemasukan dan pengeluaran tidak boleh dibedakan hanya dengan hijau/merah.
- Gunakan kombinasi **warna + ikon + simbol + / - + label**.
- Hindari penggunaan warna terlalu banyak dalam satu screen.

---

# 4. Typography

Gunakan font sans-serif modern seperti:

- Inter;
- Roboto;
- atau native Android system font.

| Style | Size | Weight | Penggunaan |
|---|---:|---:|---|
| Display | 28–32 sp | 700 | Total Kas, nominal utama |
| H1 | 24 sp | 700 | Judul halaman |
| H2 | 20 sp | 600–700 | Section heading |
| H3 | 16 sp | 600 | Card/item title |
| Body | 14–16 sp | 400 | Main content |
| Label | 12–14 sp | 500–600 | Field, chip, button label |
| Caption | 12 sp | 400 | Timestamp, metadata, helper |

### Typography rules

- Financial numbers harus mudah dipindai.
- Gunakan tabular figures jika tersedia.
- Hindari heading yang terlalu panjang.
- Hindari body paragraph lebih dari 2–3 baris di screen utama.
- Gunakan nominal konsisten, contoh: `Rp 1.250.000`.

---

# 5. Layout, Spacing, Radius

| Token | Nilai |
|---|---:|
| Base spacing | 4 dp |
| Page horizontal padding | 16 dp |
| Section gap | 24 dp |
| Default card padding | 16 dp |
| Compact card padding | 12 dp |
| Minimum touch target | 44 × 44 dp |
| Card radius | 16 dp |
| Input radius | 12 dp |
| Button radius | 12 dp |
| Elevation | 0–2 |

### Layout rules

- Gunakan 16 dp horizontal padding sebagai default.
- Prioritaskan border/surface daripada shadow besar.
- Jangan membuat card terlalu banyak di layar.
- Kelompokkan informasi yang berhubungan ke dalam satu card.
- Pada smartphone kecil, gunakan single-column layout.

---

# 6. Navigation Architecture

Gunakan **Bottom Navigation 4 item** untuk semua role.

```text
Home / Beranda
Inventaris
Keuangan
Profil
```

Perbedaan role terjadi melalui isi screen dan CTA yang tersedia, bukan dengan membuat navigation structure berbeda.

### Bottom navigation behavior

- Icon + short label.
- Active item menggunakan accent `#112E81`.
- Inactive item menggunakan neutral gray.
- Jangan menambah tab kelima kecuali benar-benar diperlukan.

Admin dapat mengakses **Manajemen Pengguna** melalui:

- quick action di Beranda; atau
- menu di Profil.

---

# 7. User Roles

## 7.1 Admin

Admin dapat:

- melihat dashboard;
- melihat dan mengelola inventaris;
- melihat seluruh informasi keuangan;
- membuat pemasukan/pengeluaran jika diizinkan sistem;
- melakukan transfer dana;
- mengelola pengguna dan role;
- melakukan koreksi transaksi dengan audit trail.

## 7.2 Bendahara

Bendahara dapat:

- melihat dashboard;
- melihat inventaris;
- melihat seluruh informasi keuangan;
- melihat saldo yang dia pegang;
- membuat pemasukan;
- membuat pengeluaran;
- melakukan transfer antarbendahara;
- melihat riwayat transaksi;
- membuka detail transaksi;
- melakukan koreksi terbatas sesuai permission.

## 7.3 Anggota / Pengguna biasa

Anggota dapat:

- melihat dashboard;
- melihat inventaris;
- melihat Total Kas;
- melihat pemasukan dan pengeluaran;
- melihat dana per bendahara;
- melihat riwayat transaksi dan detail transaksi;
- melihat bukti transaksi bila diperbolehkan.

Anggota **tidak boleh** melihat CTA:

- Tambah Pemasukan;
- Tambah Pengeluaran;
- Transfer Dana;
- Edit transaksi;
- Hapus transaksi.

---

# 8. Global Component Library

## 8.1 Primary Button

```text
Background: #112E81
Text: white
Height: 48–52 dp
Radius: 12 dp
```

States:

- default;
- pressed;
- disabled;
- loading.

## 8.2 Secondary Button

- white atau soft primary surface;
- border `#112E81`;
- text `#112E81`.

## 8.3 Information Card

- surface putih atau `#D0E7E6`;
- radius 16 dp;
- padding 16 dp;
- minimal shadow.

## 8.4 Financial Summary Card

Harus berisi:

- label singkat;
- nominal besar;
- maksimal 2–3 secondary metrics;
- CTA kecil bila perlu.

Jangan menaruh paragraf di dalam financial card.

## 8.5 Transaction Tile

Structure:

```text
[Icon] Title                       + Rp500.000
       Bendahara • timestamp
```

atau:

```text
[Icon] Konsumsi Rapat              - Rp250.000
       Dimas • 29 Sep 2026
```

Gunakan:

- plus untuk income;
- minus untuk expense;
- transfer icon untuk transfer.

## 8.6 Status Chip

Contoh:

- Tersedia;
- Dipinjam;
- Rusak;
- Selesai;
- Menunggu.

Chip harus memiliki label teks dan tidak hanya warna.

## 8.7 Text Field

- persistent label;
- helper/error text bila dibutuhkan;
- radius 12 dp;
- clear focus state dengan `#112E81`.

## 8.8 Empty State

Gunakan:

- icon atau ilustrasi sederhana;
- short headline;
- satu kalimat pendek;
- CTA hanya jika role berhak melakukan aksi.

---

# 9. Authentication Screens

## 9.1 Login

### Required components

- logo / identity Karang Taruna;
- title `Selamat Datang`;
- short subtitle maksimal 1–2 baris;
- email/username field;
- password field;
- show/hide password;
- primary button `Masuk`;
- forgot password action.

### UX rules

- jangan membuat hero copy panjang;
- form berada di bagian yang mudah dijangkau;
- tampilkan inline validation;
- disable submit saat input belum valid;
- tampilkan loading ketika autentikasi berlangsung.

---

# 10. Beranda — Anggota

## Goal

Pengguna biasa dapat memahami kondisi umum organisasi tanpa masuk ke detail yang rumit.

### Screen hierarchy

1. Greeting + avatar.
2. Total Kas.
3. Ringkasan pemasukan/pengeluaran periode aktif.
4. Ringkasan inventaris.
5. Aktivitas terbaru.

### Main financial card

Tampilkan:

- `Total Kas` sebagai angka terbesar;
- pemasukan bulan ini;
- pengeluaran bulan ini;
- CTA kecil `Lihat Detail`.

Gunakan primary surface `#D0E7E6` dengan accent `#112E81`.

### Inventory summary

Gunakan 3 compact stat cards:

- Total Barang;
- Dipinjam;
- Rusak.

### Recent activity

- maksimal 3–5 item;
- gunakan transaction/activity tile;
- sediakan `Lihat Semua`.

### Restrictions

Jangan tampilkan tombol:

- Tambah Pemasukan;
- Tambah Pengeluaran;
- Transfer Dana.

---

# 11. Beranda — Bendahara

## Goal

Bendahara dapat memantau kondisi organisasi sekaligus mengakses aksi keuangan utama dengan cepat.

### Top area

- greeting;
- avatar;
- role badge `Bendahara`.

### Financial overview

Tampilkan:

- Total Kas organisasi;
- pemasukan bulan ini;
- pengeluaran bulan ini.

### Personal treasury card

Tampilkan secara jelas:

```text
Saldo yang Saya Pegang
Rp x.xxx.xxx
```

Saldo ini **read-only**.

### Quick actions

Gunakan tiga action yang visual dan mudah ditemukan:

- `+ Pemasukan`;
- `− Pengeluaran`;
- `Transfer Dana`.

Jangan menyembunyikan action utama di overflow menu.

### Recent transactions

- maksimal 4–5 item pada dashboard;
- full history tersedia setelah tap `Lihat Semua`.

---

# 12. Beranda — Admin

## Goal

Memberikan operational overview tanpa mengubah dashboard menjadi halaman statistik padat.

### Statistic cards

Tampilkan maksimal 4 metric utama:

- Total Kas;
- Total Inventaris;
- Total Anggota;
- Barang Dipinjam.

### Quick actions

- Tambah Barang;
- Kelola Pengguna;
- Lihat Keuangan;
- Laporan.

### Recent activity

Maksimal 3–4 activity tiles.

Gunakan progressive disclosure untuk data lanjutan.

---

# 13. Keuangan — Anggota

## Goal

Transparansi keuangan organisasi dalam format yang ringkas dan mudah dipahami.

### Main section

Tampilkan:

- Total Kas;
- Pemasukan periode aktif;
- Pengeluaran periode aktif;
- optional net cash flow.

### Period filter

Gunakan compact filter seperti:

- Bulan Ini;
- 3 Bulan;
- Tahun Ini;
- custom date melalui filter.

Jangan membuat filter date menjadi section besar.

### Dana per Bendahara

Gunakan card, bukan tabel.

Contoh:

```text
Rina
Saldo Dipegang
Rp 2.000.000

Pemasukan Rp 5.000.000
Pengeluaran Rp 3.000.000
```

Tap card membuka Detail Bendahara.

### Recent transactions

Filter chips:

- Semua;
- Masuk;
- Keluar;
- Transfer.

Item menampilkan:

- icon;
- title;
- bendahara;
- date;
- amount.

### Restriction

Tidak ada input/edit/delete CTA untuk Anggota.

---

# 14. Keuangan — Bendahara/Admin

Screen menggunakan struktur yang sama dengan user biasa tetapi menambahkan management actions.

### Required actions

- Tambah Pemasukan;
- Tambah Pengeluaran;
- Transfer Dana.

Gunakan:

- quick action card;
- segmented action row;
- atau floating action yang membuka action menu sederhana.

Jangan membuat 3 FAB terpisah yang memenuhi layar.

---

# 15. Detail Bendahara

### Header

- back button;
- nama Bendahara;
- role badge kecil.

### Main card

```text
Saldo Dipegang
Rp x.xxx.xxx
```

### Secondary metrics

Gunakan dua compact cards:

- Total Pemasukan;
- Total Pengeluaran.

### Transaction history

Tampilkan riwayat transaksi milik bendahara tersebut.

Optional: chart sederhana untuk perbandingan income/expense.

**Chart tidak boleh lebih dominan daripada angka utama.**

---

# 16. Input Pemasukan

## Access

Hanya Bendahara/Admin yang berwenang.

### Fields

- Nominal;
- Sumber Dana;
- Kategori;
- Tanggal;
- Catatan opsional;
- Upload bukti opsional.

### UI behavior

Nominal menjadi input paling prominent.

Gunakan:

```text
Rp | 500.000
```

- numeric keyboard;
- Rupiah formatting saat mengetik;
- category via chips/bottom sheet;
- date picker;
- receipt upload card.

### CTA

`Simpan Pemasukan`

Sebelum final submit, tampilkan review/confirmation.

---

# 17. Input Pengeluaran

### Fields

- Nominal;
- Kategori Pengeluaran;
- Keperluan;
- Tanggal;
- Catatan opsional;
- Bukti transaksi.

### Category examples

Gunakan icon + short label:

- Konsumsi;
- Perlengkapan;
- Transportasi;
- Kegiatan;
- Lainnya.

### Current balance info

Tampilkan compact info card:

```text
Saldo Anda
Rp x.xxx.xxx
```

### Validation

Pengeluaran tidak boleh melebihi saldo bendahara.

Gunakan compact warning jika saldo tidak cukup.

### CTA

`Simpan Pengeluaran`

---

# 18. Transfer Dana Antar Bendahara

## Important business rule

> Transfer memindahkan uang dari satu bendahara ke bendahara lain dan tidak mengubah Total Kas organisasi.

### Flow

1. Pilih bendahara sumber.
2. Pilih bendahara tujuan.
3. Input nominal.
4. Input keterangan.
5. Review transfer.
6. Confirmation.
7. Success receipt.

### UI requirement

Tampilkan sender dan receiver secara visual:

```text
[Rina]
  ↓
Rp 1.000.000
  ↓
[Dimas]
```

atau horizontal jika ruang memungkinkan.

### Validation

- tujuan tidak boleh sama dengan sumber;
- nominal > 0;
- nominal tidak boleh melebihi saldo sumber.

### Review screen/card

Tampilkan:

```text
Dari: Rina
Ke: Dimas
Nominal: Rp 1.000.000

Saldo Rina
Rp 3.000.000 → Rp 2.000.000

Saldo Dimas
Rp 1.500.000 → Rp 2.500.000

Total Kas Organisasi
Rp 4.500.000 → Rp 4.500.000
```

### CTA

`Konfirmasi Transfer`

Setelah sukses, tampilkan receipt ringkas dan link ke detail transaksi.

---

# 19. Riwayat Transaksi

### Header

`Riwayat Transaksi`

### Filter

Gunakan chips:

- Semua;
- Masuk;
- Keluar;
- Transfer.

Tambahkan date filter icon jika dibutuhkan.

### Grouping

Boleh dikelompokkan berdasarkan:

- Hari Ini;
- Kemarin;
- tanggal.

### Transaction tile

```text
[icon] Iuran Anggota              + Rp500.000
       Rina • 30 Sep 2026
```

```text
[icon] Konsumsi Rapat             - Rp250.000
       Dimas • 29 Sep 2026
```

Jangan menampilkan deskripsi panjang pada list.

---

# 20. Detail Transaksi

Gunakan modern receipt-like layout.

### Primary information

- transaction type icon;
- transaction type;
- large amount;
- status.

### Detail information

Gunakan icon + label + value:

- Judul;
- Kategori;
- Tanggal;
- Bendahara;
- Dibuat oleh;
- Catatan;
- Bukti transaksi;
- Created timestamp jika diperlukan.

### Receipt

Gunakan thumbnail card yang dapat dibuka full screen.

### Permissions

- Anggota: read-only.
- Bendahara: edit/koreksi hanya jika permitted.
- Admin: koreksi dengan audit trail.

---

# 21. Inventaris — List

### Top

- title `Inventaris`;
- search bar;
- filter icon.

### Filter chips

Contoh:

- Semua;
- Elektronik;
- Peralatan;
- Kegiatan;
- Lainnya.

### Item cards

Tampilkan:

- thumbnail / icon;
- nama barang;
- jumlah;
- condition chip;
- availability status.

Contoh:

```text
Kursi Plastik
50 unit
Baik • Tersedia
```

Gunakan list atau 2-column card grid jika readability tetap baik.

Jangan gunakan spreadsheet table.

---

# 22. Detail Inventaris

### Required content

- large item image;
- nama;
- kode barang;
- kategori;
- lokasi;
- kondisi;
- total stok;
- stok tersedia;
- jumlah dipinjam;
- riwayat singkat.

Gunakan icon-based information blocks.

### Role behavior

Anggota:

- view-only.

Admin:

- edit action di top-right.

---

# 23. Inventaris — Admin Management

### Main screen

- search;
- filter;
- inventory list;
- `+ Tambah Barang` FAB.

### Overflow actions per item

Gunakan overflow menu untuk:

- Edit;
- Update stok;
- Hapus.

Jangan menampilkan semua management action langsung pada card.

---

# 24. Peminjaman Barang

### Fields

- Barang;
- Jumlah;
- Peminjam;
- Tanggal Pinjam;
- Rencana Kembali;
- Catatan.

### UX

- jumlah tidak boleh melebihi stock available;
- tampilkan availability secara visual;
- confirmation sebelum submit bila dibutuhkan.

---

# 25. Pengembalian Barang

### Required inputs

- Barang;
- jumlah yang kembali;
- kondisi barang;
- tanggal kembali;
- catatan kerusakan jika kondisi rusak.

Jika status `Rusak`, tampilkan field catatan tambahan secara conditional.

---

# 26. Profile

### Header

- avatar;
- nama;
- role badge;
- email.

### Menu

- Data Profil;
- Ubah Password;
- Tentang Aplikasi;
- Keluar.

Admin juga melihat:

- Kelola Pengguna.

Gunakan icon + label list card yang sederhana.

---

# 27. User Management — Admin

### Required sections

- search user;
- filter berdasarkan role;
- user list;
- user detail;
- edit role;
- activate/deactivate jika fitur tersedia.

### User tile

Tampilkan hanya:

- avatar;
- nama;
- email/identifier singkat;
- role chip;
- status.

Jangan membuat user list menjadi tabel kompleks.

---

# 28. State Requirements

Setiap screen utama harus memiliki desain untuk state berikut.

## Loading

- skeleton untuk card/list;
- spinner hanya untuk action singkat;
- jangan tampilkan `Rp 0` sebagai placeholder saat saldo belum dimuat.

## Empty

- simple icon;
- concise message;
- CTA hanya untuk role yang berwenang.

## Error

- human-readable message;
- `Coba Lagi` action;
- jangan kehilangan input form saat network error.

## Offline

Tampilkan compact offline indicator.

Jika data berasal dari cache dan berpotensi lama, tampilkan informasi sederhana seperti:

`Data mungkin belum terbaru`.

## Success

- snackbar atau success confirmation;
- update data hanya setelah backend mengonfirmasi transaksi.

## Permission Denied

- jangan tampilkan kontrol sensitif;
- bila user membuka deep-link/action yang tidak diizinkan, tampilkan explanatory screen yang singkat.

---

# 29. Form & Validation Rules

- Error ditempatkan dekat field terkait.
- Nominal harus lebih besar dari 0.
- Pengeluaran tidak boleh membuat saldo bendahara negatif.
- Transfer tidak boleh membuat saldo bendahara sumber negatif.
- Bendahara tujuan tidak boleh sama dengan sumber.
- Future date untuk financial transaction diblokir kecuali product rule berubah.
- Disable submit saat request berjalan.
- Hindari duplicate transaction akibat double tap.
- Receipt upload harus memiliki preview, progress, retry, dan remove.

### Important

Aksi koreksi transaksi harus mempertahankan audit trail.

Hindari silent edit yang menghapus histori perubahan.

---

# 30. Accessibility

- Touch target minimum 44 × 44 dp.
- Gunakan kontras teks yang jelas.
- `#D0E7E6` tidak digunakan sebagai warna teks utama.
- Icon yang tidak obvious harus memiliki semantic label.
- Support text scaling tanpa clipping.
- Informasi penting tidak boleh hanya tersedia melalui chart atau warna.
- Nominal harus memiliki format dan alignment yang konsisten.

---

# 31. Responsive Behavior

## Smartphone

Target utama: portrait 360–430 dp.

- gunakan single-column;
- financial metrics boleh stack vertical;
- jangan mengecilkan nominal utama secara berlebihan.

## Tablet

Boleh menggunakan:

- two-column dashboard;
- list-detail layout.

Functional behavior dan hierarchy tetap sama.

---

# 32. Copywriting Rules

Gunakan terminology berikut secara konsisten.

| Gunakan | Hindari sebagai istilah utama |
|---|---|
| Pemasukan | Uang Masuk |
| Pengeluaran | Uang Keluar |
| Transfer Dana | Pindah Saldo |
| Total Kas | Saldo Utama |
| Dana per Bendahara | Dompet Bendahara |
| Riwayat Transaksi | Log Uang |
| Bukti Transaksi | Foto Struk |

Gunakan bahasa Indonesia yang:

- sederhana;
- ringkas;
- natural;
- tidak terlalu administratif.

---

# 33. Important Security UX

UI bukan satu-satunya security layer.

Walaupun CTA disembunyikan berdasarkan role, Firebase authorization/security rules tetap harus menentukan permission sebenarnya.

Desain UI harus mencerminkan permission yang benar:

- Anggota = read-only finance.
- Bendahara = financial management.
- Admin = user/inventory/system management.

---

# 34. Critical Financial UX Rules

Google Stitch harus mempertahankan aturan berikut di semua desain keuangan:

1. **Saldo tidak memiliki tombol Edit.**
2. **Saldo tidak pernah berupa input field.**
3. Saldo hanya ditampilkan sebagai read-only financial metric.
4. Perubahan saldo terjadi melalui transaksi.
5. Setiap transaksi dapat ditelusuri ke bendahara terkait.
6. Transfer tidak dihitung sebagai pemasukan/pengeluaran organisasi.
7. Transfer hanya mengubah distribusi kas antar bendahara.
8. Total Kas organisasi harus tetap sama sebelum dan sesudah transfer.
9. Regular member tidak melihat financial management CTA.
10. Semua aksi finansial berisiko memiliki review/confirmation sebelum submit.

---

# 35. Visual Density Rules

Ini merupakan aturan penting agar desain tidak terlihat seperti koran.

## Maximum density

Per screen utama:

- maksimal 1 hero information area;
- maksimal 3–4 metric cards;
- maksimal 5 activity/list items sebelum `Lihat Semua`;
- maksimal 4–5 major sections;
- maksimal 1–2 baris supporting copy per section.

## Prefer

- icon + label;
- number + short caption;
- compact cards;
- chips;
- badges;
- progress indicators;
- thumbnails;
- charts sederhana jika benar-benar membantu.

## Avoid

- paragraph blocks;
- multi-column mobile tables;
- 8–10 cards dalam satu viewport;
- long descriptions on transaction lists;
- dashboard dengan semua data organisasi sekaligus;
- large banner yang hanya berisi teks.

---

# 36. Screen Priority for Design Generation

Jika Google Stitch membuat desain secara bertahap, gunakan urutan berikut agar visual system konsisten.

## Phase 1 — Base visual language

1. Login
2. Beranda Anggota
3. Keuangan Anggota
4. Detail Bendahara
5. Riwayat Transaksi
6. Detail Transaksi

## Phase 2 — Bendahara

7. Beranda Bendahara
8. Tambah Pemasukan
9. Tambah Pengeluaran
10. Transfer Dana
11. Transfer Review/Confirmation
12. Transfer Success

## Phase 3 — Inventaris

13. Inventaris List
14. Detail Inventaris
15. Tambah/Edit Barang
16. Peminjaman
17. Pengembalian

## Phase 4 — Admin

18. Beranda Admin
19. User Management
20. User Detail / Role Management

## Phase 5 — Supporting screens

21. Profile
22. Forgot Password
23. Empty states
24. Error states
25. Offline states

---

# 37. Acceptance Criteria UI/UX

Desain dianggap sesuai requirement jika:

- primary `#D0E7E6` digunakan konsisten sebagai soft surface/highlight;
- accent `#112E81` digunakan untuk primary CTA dan active state;
- desain mobile tidak terlihat seperti koran/report/spreadsheet;
- pengguna dapat memahami informasi utama dalam 3–5 detik;
- Total Kas menjadi financial metric utama;
- saldo tidak dapat diedit secara manual;
- Anggota tidak memiliki financial input controls;
- Bendahara memiliki action untuk pemasukan, pengeluaran, dan transfer;
- transfer memperlihatkan bahwa Total Kas tidak berubah;
- informasi keuangan dapat ditelusuri berdasarkan Bendahara;
- semua list menggunakan progressive disclosure;
- main dashboard tidak menampilkan lebih dari 5 major sections;
- input form memiliki validation/error/loading states;
- seluruh major screens memiliki loading, empty, error, dan success state;
- touch target memenuhi minimum 44 × 44 dp;
- text scaling tidak menyebabkan clipping/overflow;
- desain konsisten di semua role.

---

# 38. Final Instruction for Google Stitch

Use this document as the **primary UI/UX design specification** for the Karang Taruna Management mobile application.

Do not reinterpret the product as a financial report dashboard or text-heavy administrative system.

The desired product experience is:

**simple + visual + transparent + modern + role-aware + mobile-first**.

For every screen:

- show only the information necessary for the user's current task;
- prioritize key numbers and primary actions;
- keep text concise;
- use cards, icons, chips, badges, and whitespace;
- move secondary information into detail screens;
- preserve consistent design tokens and component behavior;
- preserve all role-based permissions and financial business rules defined in this document.

**Most important:** the UI must feel like a modern mobile app, not a newspaper, accounting sheet, or desktop admin panel.
