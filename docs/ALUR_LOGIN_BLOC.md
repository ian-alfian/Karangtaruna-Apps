# Alur login dengan BLoC

Saat ini BLoC dipakai untuk **masuk** dan **atur ulang password**. Pemulihan sesi awal, keluar akun, serta data keuangan dan inventaris masih memakai alur yang sudah ada.

## Peran file

| File | Tugas |
| --- | --- |
| `lib/login_screen.dart` | Menampilkan formulir, memvalidasi isian, dan mengirim tindakan pengguna. |
| `lib/login_bloc.dart` | Menerima event, memanggil layanan login, lalu menghasilkan state. |
| `lib/firebase_login.dart` | Berkomunikasi dengan Firebase Auth dan membaca profil pengguna di Firestore. `LoginGateway` membuat BLoC mudah diuji dengan layanan palsu. |
| `lib/app.dart` | Menyediakan BLoC, mendengarkan login berhasil, lalu membuka halaman utama. |

## Event dan state

**Event** adalah tindakan yang masuk ke BLoC:

- `LoginSubmitted`: pengguna menekan **Masuk**, membawa email, password, pilihan Ingat Saya, dan peran.
- `PasswordResetRequested`: pengguna meminta email pengaturan ulang password.
- `LoginErrorReported`: menampilkan kegagalan pemulihan sesi awal.
- `LoginCleared`: membersihkan pesan lama setelah keluar akun.

**State** adalah hasil yang dikirim BLoC ke tampilan:

- `LoginInitial`: belum ada proses.
- `LoginLoading`: permintaan sedang berjalan; tombol dinonaktifkan.
- `LoginSuccess`: profil dan tampilan peran sudah siap.
- `LoginFailure`: ada pesan kesalahan untuk ditampilkan.
- `PasswordResetSent`: ada pesan bahwa permintaan email reset selesai.

## Urutan ketika menekan Masuk

```text
LoginScreen
  -> LoginSubmitted
  -> LoginBloc mengirim LoginLoading
  -> FirebaseLoginService.signIn()
  -> validasi peran dari profil Firestore
  -> siapkan data organisasi
  -> LoginSuccess
  -> AppRoot membuka AppShell
```

Jika login, validasi peran, atau persiapan data gagal, BLoC mengakhiri sesi Firebase dan mengirim `LoginFailure`. Password hanya diteruskan ke Firebase Auth saat proses login; password tidak dimasukkan ke `LoginState`.

`BlocConsumer` dalam `app.dart` mempunyai dua tugas: `builder` menampilkan status memuat/pesan pada formulir, sedangkan `listener` menjalankan perpindahan ke halaman utama ketika menerima `LoginSuccess`.

`setState()` masih dipakai di `login_screen.dart` untuk hal lokal seperti memperlihatkan password, mencentang Ingat Saya, dan memilih peran. Aturan dan status proses login berada di BLoC.

## Kalimat singkat untuk presentasi

“Saya memakai BLoC pada alur login. Tombol Masuk mengirim event `LoginSubmitted`. BLoC mengubah state menjadi `LoginLoading`, meminta Firebase memeriksa email dan password, lalu memvalidasi peran akun dari Firestore. Jika berhasil, BLoC mengirim `LoginSuccess` dan aplikasi membuka dashboard. Jika gagal, BLoC mengirim `LoginFailure` sehingga pesan kesalahan muncul pada formulir. Dengan begitu, proses login terpisah dari kode tampilan.”
