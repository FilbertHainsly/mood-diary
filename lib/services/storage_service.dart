import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Maks size dalam byte untuk hasil kompresi (~ 800 KB)
  static const int _targetMaxBytes = 800 * 1024;

  // =====================================================
  // PICK IMAGE FROM GALLERY
  // =====================================================

  Future<File?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // =====================================================
  // COMPRESS IMAGE
  // =====================================================

  Future<File> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (result == null) return file;

      final compressed = File(result.path);
      // Kalau masih kebesaran, kompres lagi sekali dengan quality lebih rendah
      if (await compressed.length() > _targetMaxBytes) {
        final secondPath =
            '${tempDir.path}/compressed2_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final second = await FlutterImageCompress.compressAndGetFile(
          compressed.absolute.path,
          secondPath,
          quality: 55,
          minWidth: 900,
          minHeight: 900,
          format: CompressFormat.jpeg,
        );
        if (second != null) return File(second.path);
      }
      return compressed;
    } catch (_) {
      return file;
    }
  }

  // =====================================================
  // UPLOAD IMAGE
  // =====================================================

  Future<String> uploadDiaryImage({
    required String userId,
    required File file,
  }) async {
    try {
      final compressed = await _compressImage(file);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = _storage.ref().child(
        'diary_images/$userId/$fileName',
      );

      final snapshot = await ref.putFile(
        compressed,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Gagal upload foto: $e';
    }
  }

  // =====================================================
  // DELETE IMAGE BY URL
  // =====================================================

  Future<void> deleteImageByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Foto sudah tidak ada / URL invalid — diabaikan biar tidak block flow.
    }
  }
}
