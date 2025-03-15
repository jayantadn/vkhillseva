import 'dart:async';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/home/home.dart';
import 'package:vkhgaruda/widgets/welcome.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Landing extends StatefulWidget {
  final String title;

  const Landing({super.key, required this.title});

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
    await Utils().fetchUserBasics();
    _username = Utils().getUsername();

    // perform sync operations here
    await _lock.synchronized(() async {
      if (_username.isNotEmpty) {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              title: "Hare Krishna",
            ),
          ),
        );
      }
    });

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
            appBar: AppBar(title: Text(widget.title)),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Column(
                      children: [
                        // leave some space at top
                        SizedBox(height: 10),

                        // your widgets here
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
                                    builder: (context) => HomePage(
                                      title: "Hare Krishna",
                                    ),
                                  ),
                                );
                              });
                            },
                            child: Text('Signup / Login'),
                          ),

                        // leave some space at bottom
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading)
            LoadingOverlay(
              image: "assets/images/Logo/KrishnaLilaPark_circle.png",
            ),
        ],
      ),
    );
  }
}
