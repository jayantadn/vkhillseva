import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  String? _mobile;
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
    final packageInfo = await PackageInfo.fromPlatform();
    _version = packageInfo.version;

    if (Utils().getUsername().isEmpty) {
      await Utils().fetchUserBasics();
    }

    // perform sync work here
    await _lock.synchronized(() async {
      setState(() {
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
        style: Theme.of(context).textTheme.headlineMedium,
      ),

      // version
      Text('Garuda v${Const().version}',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.primary,
              )),
    ]);
  }
}
