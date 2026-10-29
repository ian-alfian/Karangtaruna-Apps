/// Email Admin pertama yang tetap diizinkan meskipun bukan alamat Gmail.
const superAdminEmail = 'ian.23eo10039@students.unugha.id';

/// Memeriksa domain Gmail secara tepat, tanpa menerima subdomain atau akhiran lain.
bool isGmailEmail(String email) =>
    RegExp(r'^[^@\s]+@gmail\.com$').hasMatch(email.trim().toLowerCase());

/// Mengizinkan Gmail atau akun Admin pertama untuk masuk dan reset password.
bool isAllowedLoginEmail(String email) =>
    isGmailEmail(email) || email.trim().toLowerCase() == superAdminEmail;

/// Pesan yang dipakai bersama oleh form dan layanan Firebase.
const gmailOnlyMessage = 'Gunakan alamat @gmail.com.';
