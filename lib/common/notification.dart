import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MyNotification {
  static final MyNotification _instance = MyNotification._internal();

  factory MyNotification() {
    return _instance;
  }

  MyNotification._internal() {
    // init
  }

  Future<void> send(String token, String title, String body) async {
    const String functionUrl =
        "https://sendnotification-eqsv4pot7q-uc.a.run.app"; // Replace with your Firebase function URL

    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
        }),
      );

      if (response.statusCode == 200) {
        print("Notification sent: ${response.body}");
      } else {
        print("Failed to send notification: ${response.body}");
      }
    } catch (error) {
      print("Error sending notification: $error");
    }
  }
}
