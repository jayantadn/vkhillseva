import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vkhsangeetseva/common/local_storage.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:synchronized/synchronized.dart';

// ignore: must_be_immutable
class AuthDialog extends StatefulWidget {
  void Function()? callback;
  AuthDialog({super.key, this.callback});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

// ignore: library_private_types_in_public_api
GlobalKey<_AuthDialogState> authdialogKey = GlobalKey<_AuthDialogState>();

class _AuthDialogState extends State<AuthDialog> {
  // locals
  final Lock _lock = Lock();
  bool _tc = false;
  bool _verified = false;
  bool _isLoading = false;
  String _verificationId = '';
  ConfirmationResult? _confirmationResult;

  // controllers and focus nodes
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // dispose all controllers and focus nodes
    _mobileNumberController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();

    super.dispose();
  }

  void refresh() async {
    // perform async work here

    // perform sync work here
    await _lock.synchronized(() async {
      setState(() {});
    });
  }

  Future<void> _otpConfirmed(UserCredential userCredential) async {
    if (userCredential.user != null) {
      UserBasics userbasics = UserBasics(
        name: _nameController.text.trim(),
        mobile: _mobileNumberController.text,
        uid: userCredential.user!.uid,
      );
      await LS().write("userbasics", jsonEncode(userbasics));

      if (widget.callback != null) widget.callback!();

      Toaster().info('Authentication successful');
    } else {
      Toaster().error('Authentication failed');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _submitOtpAndroid(BuildContext context) async {
    PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: _otpController.text,
    );

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(phoneAuthCredential);
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();

      _otpConfirmed(userCredential);
    } catch (e) {
      Toaster().error('Error: $e');
    }
  }

  Future<void> _submitOtpWeb(BuildContext context) async {
    if (_confirmationResult == null) {
      Toaster().error('Confirmation result is null');
      return;
    }

    try {
      UserCredential userCredential =
          await _confirmationResult!.confirm(_otpController.text);
      _otpConfirmed(userCredential);

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    } catch (e) {
      Toaster().error('Error: $e');
    }
  }

  Future<void> _triggerVerificationWeb(context) async {
    FirebaseAuth auth = FirebaseAuth.instance;

    _confirmationResult =
        await auth.signInWithPhoneNumber("+91${_mobileNumberController.text}");

    _otpController.clear();
    _otpFocusNode.requestFocus();
    Toaster().info('OTP sent');

    setState(() {
      _verified = true;
      _isLoading = false;
    });
  }

  Future<void> _triggerVerificationAndroid(BuildContext context) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91${_mobileNumberController.text}",
      verificationCompleted: (PhoneAuthCredential credential) {
        FirebaseAuth.instance
            .signInWithCredential(credential)
            .then((onValue) {});

        Navigator.of(context).pop();
      },
      verificationFailed: (FirebaseAuthException e) {
        Toaster().error('Verification failed: ${e.message}');
        Navigator.of(context).pop();
      },
      codeSent: (String verificationId, int? resendToken) {
        Toaster().info("OTP sent");

        _otpController.clear();
        _otpFocusNode.requestFocus();
        _verificationId = verificationId;

        setState(() {
          _verified = true;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _verify() async {
    if (!_tc) {
      Toaster().error('Please accept the terms and conditions');
      return;
    }

    if (_mobileNumberController.text.length != 10) {
      Toaster().error('Mobile number is invalid');
      return;
    }

    if (_nameController.text.isEmpty) {
      Toaster().error('Please enter your name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb) {
        _triggerVerificationWeb(context);
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            _triggerVerificationAndroid(context);
            break;
          default:
            Toaster().error(
              'Authentication not supported for platform - $defaultTargetPlatform',
            );
        }
      }
    } catch (e) {
      Toaster().error('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Registration'),
      content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Stack(children: [
            // dialog contents
            Column(
              children: [
                // name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                  ),
                ),

                // mobile number field
                SizedBox(height: 8),
                if (!_verified)
                  TextFormField(
                    controller: _mobileNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixText: '+91 ',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),

                // OTP field
                SizedBox(height: 8),
                if (_verified)
                  TextFormField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'OTP',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),

                // terms and conditions
                Row(
                  children: [
                    Checkbox(
                      value: _tc,
                      onChanged: (bool? value) {
                        setState(() {
                          _tc = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TermsAndConditions(
                                    title: "Terms & Conditions")),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Accept the ',
                                style: TextStyle(color: Colors.black),
                              ),
                              TextSpan(
                                text: 'terms and conditions',
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // circular progress indicator
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ])),
      actions: <Widget>[
        // cancel button
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        // verify button
        if (!_verified && !_isLoading)
          TextButton(
            onPressed: _verify,
            child: Text('Verify'),
          ),

        // submit OTP button
        if (_verified && !_isLoading)
          TextButton(
            child: Text('Submit OTP'),
            onPressed: () {
              if (_otpController.text.length != 6) {
                Toaster().error('OTP is invalid');
                return;
              }

              if (kIsWeb) {
                _submitOtpWeb(context);
              } else {
                switch (defaultTargetPlatform) {
                  case TargetPlatform.android:
                    _submitOtpAndroid(context);
                    break;
                  default:
                    Toaster().error(
                      'Authentication not supported for platform - $defaultTargetPlatform',
                    );
                }
              }

              setState(() {
                _isLoading = true;
              });
            },
          ),
      ],
    );
  }
}

class TermsAndConditions extends StatelessWidget {
  final String title;

  TermsAndConditions({super.key, required this.title});

  final List<String> _terms = [
    "You might receive an SMS message for verification and standard rates may apply.",
    "Phone numbers that you provide for authentication will be sent and stored by Google to improve spam and abuse prevention across Google services, including but not limited to Firebase.",
    "User details will be stored in temple database. This information may be used by temple authorities to contact you later."
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: _terms.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  "${index + 1}. ${_terms[index]}",
                ),
              );
            },
          )),
    );
  }
}

class UserBasics {
  final String uid;
  final String name;
  final String mobile;

  UserBasics({
    required this.uid,
    required this.name,
    required this.mobile,
  });

  factory UserBasics.fromJson(Map<String, dynamic> json) {
    return UserBasics(
      uid: json['uid'],
      name: json['name'],
      mobile: json['mobile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'mobile': mobile,
    };
  }
}

Future<void> smsAuth(BuildContext context, void Function()? callback) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AuthDialog(callback: callback);
    },
  );
}
