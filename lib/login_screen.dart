import 'package:flutter/material.dart';

import 'demo_data.dart';
import 'email_policy.dart';
import 'ui.dart';

class LoginScreen extends StatefulWidget {
  /// Membuat halaman masuk.
  const LoginScreen({
    super.key,
    required this.onSignIn,
    required this.onResetPassword,
    this.busy = false,
    this.error,
    this.notice,
  });

  final Future<void> Function(
    String email,
    String password,
    bool rememberMe,
    AppRole selectedRole,
  )
  onSignIn;
  final Future<void> Function(String email) onResetPassword;
  final bool busy;
  final String? error;
  final String? notice;

  /// Membuat state interaktif untuk halaman masuk.
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailFieldKey = GlobalKey<FormFieldState<String>>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool showPassword = false;
  bool rememberMe = false;
  AppRole selectedRole = AppRole.anggota;

  /// Melepas controller atau langganan saat widget ditutup.
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Memeriksa apakah email pada formulir memiliki format dasar yang valid.
  bool get emailValid {
    final email = emailController.text.trim();
    return email.contains('@') && email.contains('.');
  }

  /// Memberi pesan saat email tidak valid atau domainnya tidak diizinkan.
  String? get emailError {
    if (!emailValid) return 'Masukkan alamat email yang valid.';
    return isAllowedLoginEmail(emailController.text) ? null : gmailOnlyMessage;
  }

  /// Meminta email pengaturan ulang password untuk akun yang diisi.
  Future<void> resetPassword() async {
    if (emailError != null) {
      emailFieldKey.currentState?.validate();
      return;
    }
    await widget.onResetPassword(emailController.text.trim());
  }

  /// Memvalidasi isian lalu mengirim permintaan login.
  void submit() {
    if (widget.busy) return;
    if (formKey.currentState!.validate()) {
      widget.onSignIn(
        emailController.text.trim(),
        passwordController.text,
        rememberMe,
        selectedRole,
      );
    }
  }

  /// Menyusun tampilan halaman masuk.
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = constraints.maxHeight >= 760
              ? (124.0 - MediaQuery.paddingOf(context).top).clamp(40.0, 124.0)
              : (constraints.maxHeight * 0.075).clamp(30.0, 65.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  SizedBox(height: topPadding),
                  const _DesignLogo(),
                  const SizedBox(height: 24),
                  const Text(
                    'Masuk ke aplikasi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      height: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: 272,
                    height: 33,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.navy, width: 1.4),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Row(
                          children: [
                            for (final role in AppRole.values)
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(100),
                                  key: ValueKey('login-role-${role.name}'),
                                  onTap: widget.busy
                                      ? null
                                      : () =>
                                            setState(() => selectedRole = role),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 170),
                                    decoration: BoxDecoration(
                                      color: selectedRole == role
                                          ? Colors.black
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Center(
                                      child: Text(
                                        role.label,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: selectedRole == role
                                              ? AppColors.background
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 43),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 352),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: emailFieldKey,
                            controller: emailController,
                            enabled: !widget.busy,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            decoration: _fieldDecoration(
                              label: 'Email',
                              hint: 'Sukardi@gmail.com',
                            ),
                            validator: (_) => emailError,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: passwordController,
                            enabled: !widget.busy,
                            obscureText: !showPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => submit(),
                            autofillHints: const [AutofillHints.password],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            decoration:
                                _fieldDecoration(
                                  label: 'Password',
                                  hint: 'Minimal 8 karakter',
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: showPassword
                                        ? 'Sembunyikan password'
                                        : 'Tampilkan password',
                                    onPressed: () => setState(
                                      () => showPassword = !showPassword,
                                    ),
                                    icon: Icon(
                                      showPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 22,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                            validator: (value) => (value?.isEmpty ?? true)
                                ? 'Masukkan password.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: widget.busy
                                    ? null
                                    : (value) => setState(
                                        () => rememberMe = value ?? false,
                                      ),
                                activeColor: AppColors.navy,
                                side: const BorderSide(
                                  color: Color(0xFF1E1E20),
                                ),
                                shape: const RoundedRectangleBorder(),
                                visualDensity: const VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: widget.busy
                                    ? null
                                    : () => setState(
                                        () => rememberMe = !rememberMe,
                                      ),
                                child: const Text(
                                  'Ingat Saya',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              widget.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (widget.notice != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              widget.notice!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 31),
                          Center(
                            child: SizedBox(
                              width: 276,
                              height: 46,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.navy, AppColors.blue],
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: TextButton(
                                  onPressed: widget.busy ? null : submit,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white70,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  child: Text(
                                    widget.busy ? 'Memproses...' : 'Masuk',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: TextButton(
                              onPressed: widget.busy ? null : resetPassword,
                              child: const Text(
                                'Atur / lupa password',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Menyusun garis tepi dan label kolom login.
InputDecoration _fieldDecoration({
  required String label,
  required String hint,
}) {
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(100),
    borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      color: Colors.black,
    ),
    floatingLabelStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      color: Colors.black,
    ),
    hintStyle: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      color: Colors.black.withValues(alpha: 0.35),
    ),
    filled: false,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    border: outline,
    enabledBorder: outline,
    focusedBorder: outline.copyWith(
      borderSide: const BorderSide(color: AppColors.blue, width: 1.8),
    ),
    errorBorder: outline.copyWith(
      borderSide: const BorderSide(color: Colors.red, width: 1.4),
    ),
    focusedErrorBorder: outline.copyWith(
      borderSide: const BorderSide(color: Colors.red, width: 1.8),
    ),
    errorStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11),
  );
}

class _DesignLogo extends StatelessWidget {
  /// Membuat logo aplikasi di halaman masuk.
  const _DesignLogo();

  /// Menyusun tampilan logo aplikasi di halaman masuk.
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Logo Karangtaruna Apps',
    child: SizedBox(
      width: 134,
      height: 134,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: -133,
              top: -124,
              child: Image.asset(
                'assets/login_reference.png',
                width: 412,
                height: 917,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
