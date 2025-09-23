import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload file
  Future<String> uploadFile({
    required File file,
    required String uploadPath,
    String? customFileName,
  }) async {
    try {
      final fileName = customFileName ?? DateTime.now().millisecondsSinceEpoch.toString() + path.basename(file.path);
      final ref = _storage.ref().child('$uploadPath/$fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }
  
  // Upload bytes
  Future<String> uploadBytes({
    required List<int> bytes,
    required String path,
    required String fileName,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child('$path/$fileName');
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'uploaded': DateTime.now().toString()},
      );
      final uploadTask = await ref.putData(Uint8List.fromList(bytes), metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading bytes: $e');
      rethrow;
    }
  }
  
  // Delete file
  Future<void> deleteFile(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }
  
  // Get download URL
  Future<String> getDownloadURL(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } catch (e) {
      print('Error getting download URL: $e');
      rethrow;
    }
  }
  
  // List files in directory
  Future<List<Reference>> listFiles(String directory) async {
    try {
      final ListResult result = await _storage.ref(directory).listAll();
      return result.items;
    } catch (e) {
      print('Error listing files: $e');
      rethrow;
    }
  }
}
