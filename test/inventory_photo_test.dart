import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:karangtaruna_apps/inventory_photo.dart';

void main() {
  test('foto dikompresi ke JPEG kecil untuk dokumen Firestore', () {
    final source = image.Image(width: 1400, height: 1000);
    image.fill(source, color: image.ColorRgb8(44, 108, 218));
    final encoded = compressInventoryPhotoBytes(
      Uint8List.fromList(image.encodePng(source)),
    );
    final bytes = base64Decode(encoded);
    final decoded = image.decodeJpg(bytes);
    expect(bytes.length, lessThanOrEqualTo(maxInventoryPhotoBytes));
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(900));
  });
}
