import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vkhgaruda/home/home.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:vkhgaruda/widgets/welcome.dart';
import 'package:vkhpackages/vkhpackages.dart';

class PinPage extends StatefulWidget {
  final String title;

  const PinPage({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _PinPageState createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers
    _focusNode.dispose();

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
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //welcome message
                      Welcome(),

                      // input pin
                      SizedBox(height: 16),
                      TextField(
                        maxLength: 4,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Enter pin',
                        ),
                        controller: _controller,
                      ),

                      // submit button
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          var bytes = utf8.encode(_controller.text);
                          var digest = sha256.convert(bytes);

                          DatabaseReference dbref = FirebaseDatabase.instance
                              .ref("${Const().dbrootGaruda}/Settings");
                          DataSnapshot snapshot =
                              await dbref.child("PinHash").get();

                          if (snapshot.value == digest.toString()) {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            prefs.setString('pincache', digest.toString());

                            Navigator.pushReplacement(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(
                                  title: "Hare Krishna",
                                ),
                              ),
                            );
                          } else {
                            Toaster().error('Invalid pin');
                          }
                        },
                        child: Text("Submit"),
                      ),
                    ],
                  ),
                ),
              )),

          // circular progress indicator
          if (_isLoading) LoadingOverlay()
        ],
      ),
    );
  }
}
