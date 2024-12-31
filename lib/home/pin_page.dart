import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vkhillseva/home/change_pin.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/home/home.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:vkhillseva/common/toaster.dart';

class PinPage extends StatefulWidget {
  final String title;

  const PinPage({super.key, required this.title});

  @override
  _PinPageState createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  bool _isLoading = true;

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
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // app logo
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/Logo/KrishnaLilaPark_circle.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        // welcome message
                        Text(
                          'ISKCON Vaikuntha Hill',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text('Seva App v${Const().version}',
                            style: Theme.of(context).textTheme.headlineSmall),

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
                            counterText: '',
                          ),
                          onChanged: (value) async {
                            if (value.length == 4) {
                              var bytes = utf8.encode(value);
                              var digest = sha256.convert(bytes);

                              DatabaseReference dbref = FirebaseDatabase
                                  .instance
                                  .ref("${Const().dbroot}/Settings");
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
                            }
                          },
                        ),

                        // change pin
                        SizedBox(height: 16),
                        TextButton(
                            child: Text('Change pin'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ChangePin(
                                          title: 'Change pin',
                                        )),
                              );
                            }),
                      ],
                    ),
                  ),
                ),
              )),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: 'assets/images/tas.png')
        ],
      ),
    );
  }
}
