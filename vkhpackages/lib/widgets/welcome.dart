import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Welcome extends StatefulWidget {
  final Function onAuthComplete;

  const Welcome({super.key, required this.onAuthComplete});

  @override
  State<Welcome> createState() => WelcomeState();
}

// hint: put the global key as a member of the calling class
// instantiate the class with a global key
// final GlobalKey<WelcomeState> _welcomeKey = GlobalKey<WelcomeState>();

class WelcomeState extends State<Welcome> {
  final Lock _lock = Lock();
  String _username = "";

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // dispose all controllers

    super.dispose();
  }

  Future<void> refresh() async {
    // perform async work here

    // get username from local storage
    await Utils().fetchUserBasics();

    await _lock.synchronized(() async {
      // perform sync work here
      setState(() {
        _username = Utils().getUsername();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // image
          Container(
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
                'assets/images/Logo/SangeetSeva.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // all text
          SizedBox(height: 10),
          Text('Welcome', style: Theme.of(context).textTheme.headlineSmall),
          Text(
            _username.isEmpty ? 'Guest' : _username,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            'ISKCON Vaikuntha Hill',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            'Govinda Sangeet Seva',
            style: GoogleFonts.pacifico(
              textStyle: Theme.of(context).textTheme.headlineLarge,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          // signup button
          SizedBox(height: 10),
          if (_username.isEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.deepOrange, // Change the background color here
              ),
              onPressed: () {
                smsAuth(context, () async {
                  // auth complete.
                  widget.onAuthComplete();
                });
              },
              child: Text('Signup / Login'),
            ),
        ],
      ),
    );
  }
}
