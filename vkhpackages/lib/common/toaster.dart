import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Toaster {
  static final Toaster _instance = Toaster._internal();

  factory Toaster() {
    return _instance;
  }

  Toaster._internal();

  void error(String str) {
    Fluttertoast.showToast(
      msg: str,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.red,
      webBgColor: "#FF0000",
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void info(String str) {
    Fluttertoast.showToast(
      msg: str,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void notify({required String header, required String body}) {
    String msg = '';
    if (kIsWeb) {
      msg = "<b>$header</b><br>$body";
    } else {
      msg = "[$header] $body";
    }

    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 5,
      backgroundColor: Colors.yellow,
      webBgColor: "#FFFF00",
      textColor: Colors.black,
      fontSize: 16.0,
    );
  }
}
