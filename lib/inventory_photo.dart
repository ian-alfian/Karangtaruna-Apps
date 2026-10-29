import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';

import 'ui.dart';

const maxInventoryPhotoBytes = 150000;

/// Memilih dan mengecilkan foto agar muat di dokumen Firestore pada paket Spark.
Future<String?> pickInventoryPhoto() async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked == null) return null;
  if (await picked.length() > 12 * 1024 * 1024) {
    throw ArgumentError('Ukuran foto asal maksimal 12 MB.');
  }
  return compute(compressInventoryPhotoBytes, await picked.readAsBytes());
}

/// Mengubah foto menjadi JPEG kecil lalu mengodekannya sebagai Base64.
String compressInventoryPhotoBytes(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) {
    throw ArgumentError('Format gambar tidak didukung. Gunakan JPG atau PNG.');
  }
  final oriented = image.bakeOrientation(decoded);
  for (final maxSide in [900, 720, 600, 480]) {
    final longest = oriented.width > oriented.height
        ? oriented.width
        : oriented.height;
    final resized = longest > maxSide
        ? image.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? maxSide : null,
            height: oriented.height > oriented.width ? maxSide : null,
            interpolation: image.Interpolation.average,
          )
        : oriented;
    for (final quality in [78, 65, 50, 38]) {
      final jpeg = image.encodeJpg(resized, quality: quality);
      if (jpeg.length <= maxInventoryPhotoBytes) return base64Encode(jpeg);
    }
  }
  throw ArgumentError(
    'Foto terlalu besar setelah diperkecil. Pilih foto lain.',
  );
}

class InventoryPhotoView extends StatelessWidget {
  /// Membuat pratinjau foto barang.
  const InventoryPhotoView({
    super.key,
    required this.base64,
    this.height = 205,
  });

  final String? base64;
  final double height;

  /// Menyusun tampilan pratinjau foto barang.
  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      if (base64 != null && base64!.isNotEmpty) bytes = base64Decode(base64!);
    } on FormatException {
      bytes = null;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        height: height,
        color: AppColors.paleBlue,
        child: bytes == null
            ? const Center(
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.blue,
                  size: 54,
                ),
              )
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 52),
                ),
              ),
      ),
    );
  }
}
