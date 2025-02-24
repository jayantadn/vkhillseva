import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/home/pin_page.dart';
import 'package:vkhgaruda/widgets/welcome.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Landing extends StatefulWidget {
  final String title;
  final String? icon;

  const Landing({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _LandingState createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  String _username = "";

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here
    Utils().fetchUserBasics().then((value) {
      setState(() {
        _username = Utils().getUsername();
      });

      if (_username.isNotEmpty) {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => PinPage(
              title: "Hare Krishna",
            ),
          ),
        );
      }
    });

    // perform sync operations here
    await _lock.synchronized(() async {});

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
            body: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Center(
                  child: Column(
                children: [
                  // welcome header
                  Welcome(),

                  // sms authetication
                  SizedBox(
                    height: 8,
                  ),
                  if (_username.isEmpty)
                    ElevatedButton(
                      onPressed: () {
                        smsAuth(context, () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PinPage(
                                title: "Hare Krishna",
                              ),
                            ),
                          );
                        });
                      },
                      child: Text('Signup / Login'),
                    ),
                ],
              )),
            ),
          ),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: widget.icon)
        ],
      ),
    );
  }
}
