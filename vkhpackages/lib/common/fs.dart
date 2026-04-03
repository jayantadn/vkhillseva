import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'toaster.dart';

class FS {
  static final FS _instance = FS._internal();

  factory FS() {
    return _instance;
  }

  FS._internal() {
    // init
  }

  // returns url
  Future<String> uploadFile({
    required String dstPath,
    required String srcPath,
  }) async {
    String downloadUrl = '';

    final storageRef = FirebaseStorage.instance.ref();
    final fileRef = storageRef.child(dstPath);

    try {
      await fileRef.putFile(File(srcPath));
      downloadUrl = await fileRef.getDownloadURL();
    } catch (e) {
      Toaster().error('Error uploading file: $e');
    }

    return downloadUrl;
  }

  // upload bytestream
  Future<String> uploadBytes({
    required String dstPath,
    required Uint8List bytes,
  }) async {
    String downloadUrl = '';

    final storageRef = FirebaseStorage.instance.ref();
    final fileRef = storageRef.child(dstPath);

    try {
      await fileRef.putData(bytes);
      downloadUrl = await fileRef.getDownloadURL();
    } catch (e) {
      Toaster().error('Error uploading bytes: $e');
    }

    return downloadUrl;
  }

  // extract storage path from download URL
  String getPathFromUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      // Extract the path from /o/ segment and decode it
      String encodedPath = uri.pathSegments[uri.pathSegments.indexOf('o') + 1];
      return Uri.decodeComponent(encodedPath);
    } catch (e) {
      // If parsing fails, assume it's already a path
      return url;
    }
  }

  // get download URL from storage path
  Future<String> getUrlFromPath(String path) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final fileRef = storageRef.child(path);
      return await fileRef.getDownloadURL();
    } catch (e) {
      Toaster().error('Error getting URL from path: $e');
      return '';
    }
  }

  // delete file
  Future<bool> deleteFile({required String filePath}) async {
    final storageRef = FirebaseStorage.instance.ref();
    final fileRef = storageRef.child(filePath);

    try {
      await fileRef.delete();
      return true;
    } catch (e) {
      Toaster().error('Error deleting file: $e');
      return false;
    }
  }
}
