import 'package:flutter/material.dart';

import 'ui.dart';

/// Menampilkan konfirmasi untuk tindakan yang memerlukan keputusan pengguna.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ActionConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          destructive: destructive,
        ),
      ) ??
      false;
}

/// Menampilkan dialog hasil tindakan atau pesan kesalahan.
Future<void> showActionNotice(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'Selesai',
  bool error = false,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => Dialog(
    backgroundColor: Colors.white,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 31,
              backgroundColor: error
                  ? const Color(0xFFFFE8E8)
                  : AppColors.paleBlue,
              child: Icon(
                error ? Icons.priority_high_rounded : Icons.check_rounded,
                color: error ? const Color(0xFFC62828) : AppColors.blue,
                size: 31,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          ActionPillButton(
            label: buttonLabel,
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    ),
  ),
);

class ActionConfirmDialog extends StatelessWidget {
  /// Membuat dialog konfirmasi tindakan.
  const ActionConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Batal',
    this.destructive = false,
    this.details,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final Widget? details;

  /// Menyusun tampilan dialog konfirmasi tindakan.
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 27),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          if (details != null) ...[const SizedBox(height: 20), details!],
          const SizedBox(height: 24),
          ActionPillButton(
            label: confirmLabel,
            destructive: destructive,
            onPressed: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 10),
          ActionPillButton(
            label: cancelLabel,
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    ),
  );
}

class ActionPillButton extends StatelessWidget {
  /// Membuat tombol aksi berbentuk pil.
  const ActionPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool secondary;
  final bool destructive;

  /// Menyusun tampilan tombol aksi berbentuk pil.
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(28),
    child: Ink(
      decoration: BoxDecoration(
        color: secondary
            ? AppColors.paleBlue
            : destructive
            ? const Color(0xFFC62828)
            : null,
        gradient: secondary || destructive
            ? null
            : const LinearGradient(colors: [AppColors.navy, AppColors.blue]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onPressed,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: secondary ? AppColors.blue : Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
