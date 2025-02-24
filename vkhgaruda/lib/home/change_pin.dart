import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vkhgaruda/home/home.dart';
import 'package:vkhpackages/vkhpackages.dart';

class ChangePin extends StatefulWidget {
  final String title;

  const ChangePin({super.key, required this.title});

  @override
  _ChangePinState createState() => _ChangePinState();
}

class _ChangePinState extends State<ChangePin> {
  bool _isLoading = true;

  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Stack(
        children: [
          Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
              ),
              body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      maxLength: 4,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      controller: _oldPinController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Old pin',
                        counterText: '',
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      maxLength: 4,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      controller: _newPinController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'New pin',
                        counterText: '',
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      maxLength: 4,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      controller: _confirmPinController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Confirm pin',
                        counterText: '',
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        // check if all the pins have 4 digits
                        if (_oldPinController.text.length != 4 ||
                            _newPinController.text.length != 4 ||
                            _confirmPinController.text.length != 4) {
                          Toaster().error('All pins must have 4 digits');
                          return;
                        }

                        // check if new pin only contains numbers
                        if (!RegExp(r'^[0-9]+$')
                            .hasMatch(_newPinController.text)) {
                          Toaster().error('New pin must contain only numbers');
                          return;
                        }

                        // check if new and confirm pin match
                        if (_newPinController.text !=
                            _confirmPinController.text) {
                          Toaster().error('New and confirm pin do not match');
                          return;
                        }

                        // check if new pin is same as old pin
                        if (_newPinController.text == _oldPinController.text) {
                          Toaster().error('New pin cannot be same as old pin');
                          return;
                        }

                        // check if old pin is valid
                        var bytes = utf8.encode(_oldPinController.text);
                        var digest = sha256.convert(bytes);
                        DatabaseReference dbref = FirebaseDatabase.instance
                            .ref("${Const().dbrootGaruda}/Config");
                        DataSnapshot snapshot =
                            await dbref.child("PinHash").get();
                        if (snapshot.value != digest.toString()) {
                          Toaster().error('Invalid old pin');
                          return;
                        }

                        // save new pin
                        bytes = utf8.encode(_newPinController.text);
                        digest = sha256.convert(bytes);
                        dbref.child("PinHash").set(digest.toString());
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setString('pincache', digest.toString());
                        Toaster().info('Pin changed successfully');

                        // goto home page
                        Navigator.pushReplacement(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(
                              title: "Hare Krishna",
                            ),
                          ),
                        );
                      },
                      child: Text('Save'),
                    ),
                  ],
                ),
              )),

          // circular progress indicator
          if (_isLoading)
            LoadingOverlay(
                image: 'assets/images/Logo/KrishnaLilaPark_square.png')
        ],
      ),
    );
  }
}
