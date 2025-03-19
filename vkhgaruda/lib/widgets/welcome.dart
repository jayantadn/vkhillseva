import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

// ignore: library_private_types_in_public_api
GlobalKey<_WelcomeState> summaryKey = GlobalKey<_WelcomeState>();

class _WelcomeState extends State<Welcome> {
  final Lock _lock = Lock();
  String _username = '';
  String _version = "";

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

  void refresh() async {
    // perform async work here

    // get version
    // _version = await Utils().checkForUpdates("vkhillgaruda");

    if (Utils().getUsername().isEmpty) {
      await Utils().fetchUserBasics();
    }

    // perform sync work here
    await _lock.synchronized(() async {
      setState(() {
        _username = Utils().getUsername();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
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
              'assets/images/VKHillDieties/Garuda.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      Text(
        'Welcome',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      Text(
        _username.isEmpty ? 'Guest' : _username,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      SizedBox(
        height: 8,
      ),
      Text(
        'ISKCON Vaikuntha Hill',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      if (_version.isNotEmpty)
        Text('Garuda v$_version',
            style: Theme.of(context).textTheme.headlineSmall),
    ]);
  }
}
