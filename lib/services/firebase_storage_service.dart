import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(
      String filePath,
      String folder,
      ) async {
    final file = File(filePath);

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final ref = _storage.ref().child('$folder/$fileName');

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }

  Future<void> deleteImage(String imageUrl) async {
    await _storage.refFromURL(imageUrl).delete();
  }

  Future<String?> getImageUrl(String path) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}