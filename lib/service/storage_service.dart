// lib/services/storage_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a file and return download URL
  Future<String> uploadFile({
    required File file,
    required String storagePath,
    Function(double)? onProgress,
  }) async {
    try {
      final String fileName = path.basename(file.path);
      final Reference ref = _storage.ref().child('$storagePath/$fileName');

      final UploadTask uploadTask = ref.putFile(file);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final double progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Upload raw data (bytes) and return download URL
  Future<String> uploadData({
    required Uint8List data,
    required String storagePath,
    required String fileName,
    String? contentType,
    Function(double)? onProgress,
  }) async {
    try {
      final Reference ref = _storage.ref().child('$storagePath/$fileName');

      final SettableMetadata metadata = contentType != null
          ? SettableMetadata(contentType: contentType)
          : SettableMetadata();

      final UploadTask uploadTask = ref.putData(data, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final double progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload data: $e');
    }
  }

  // Get download URL of a file by reference path
  Future<String> getDownloadURL({required String storagePath}) async {
    try {
      return await _storage.ref().child(storagePath).getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  // Delete a file by reference path
  Future<void> deleteFile({required String storagePath}) async {
    try {
      await _storage.ref().child(storagePath).delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // List all files in a directory
  Future<List<String>> listFiles({required String storagePath}) async {
    try {
      final ListResult result =
          await _storage.ref().child(storagePath).listAll();
      return result.items.map((Reference ref) => ref.fullPath).toList();
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  // Get metadata of a file
  Future<Map<String, dynamic>> getMetadata(
      {required String storagePath}) async {
    try {
      final FullMetadata metadata =
          await _storage.ref().child(storagePath).getMetadata();

      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'creationTime': metadata.timeCreated,
        'updatedTime': metadata.updated,
      };
    } catch (e) {
      throw Exception('Failed to get metadata: $e');
    }
  }

  // Update metadata of a file
  Future<void> updateMetadata({
    required String storagePath,
    required Map<String, String> customMetadata,
    String? contentType,
    String? cacheControl,
  }) async {
    try {
      final SettableMetadata metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: customMetadata,
        cacheControl: cacheControl,
      );

      await _storage.ref().child(storagePath).updateMetadata(metadata);
    } catch (e) {
      throw Exception('Failed to update metadata: $e');
    }
  }

  // Download file to a local path
  Future<File> downloadFile({
    required String storagePath,
    required String localPath,
    Function(double)? onProgress,
  }) async {
    try {
      final File file = File(localPath);
      final Reference ref = _storage.ref().child(storagePath);

      final DownloadTask downloadTask = ref.writeToFile(file);

      if (onProgress != null) {
        downloadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final double progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      await downloadTask;
      return file;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }
}
