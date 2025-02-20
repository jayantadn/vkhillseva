import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vkhsangeetseva/common/const.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'dart:io';

class FS {
  static final FS _instance = FS._internal();

  factory FS() {
    return _instance;
  }

  FS._internal() {
    // init
  }

  // returns url
  Future<String> uploadFile(
      {required String dstPath, required String srcPath}) async {
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
  Future<String> uploadBytes(
      {required String dstPath, required Uint8List bytes}) async {
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
}
