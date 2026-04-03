import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

// ignore: library_private_types_in_public_api
GlobalKey<_WelcomeState> welcomeKey = GlobalKey<_WelcomeState>();

class _WelcomeState extends State<Welcome> {
  final Lock _lock = Lock();
  String _username = '';
  String? _mobile;
  String _version = '';

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
    final packageInfo = await PackageInfo.fromPlatform();

    if (Utils().getUsername().isEmpty) {
      await Utils().fetchUserBasics();
    }

    // perform sync work here
    await _lock.synchronized(() async {
      setState(() {
        _version = packageInfo.version;
        UserBasics? basics = Utils().getUserBasics();

        if (basics != null) {
          _username = basics.name;
          _mobile = basics.mobile;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Widgets().createTopLevelCard(
      context: context,
      child: Column(children: [
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
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          _username.isEmpty ? 'Guest' : _username,
          style: Theme.of(context).textTheme.headlineMedium,
        ),

        // mobile number
        if (_mobile != null && _mobile!.isNotEmpty)
          Text(
            _mobile ?? "",
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.grey,
                ),
          ),
        SizedBox(
          height: 8,
        ),
        Text(
          'ISKCON Vaikuntha Hill',
          style: TextStyle(
            fontFamily: 'Macondo',
            fontSize: 24.0,
            letterSpacing: 2.0,
            color: Theme.of(context).colorScheme.primary,
          ),
          // GoogleFonts.macondo(
          //   textStyle: Theme.of(context).textTheme.headlineLarge,
          //   color: Theme.of(context).colorScheme.primary,
          // ),
        ),

        // version
        if (_version.isNotEmpty)
          Text('Garuda v$_version',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
      ]),
    );
  }
}
