import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:vkhsangeetseva/common/const.dart';
import 'package:vkhsangeetseva/common/toaster.dart';
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
      {required String srcPath, required String dstPath}) async {
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
}
