import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class NSTutorial extends StatefulWidget {
  final String title;
  final String? splashImage;

  const NSTutorial({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _NSTutorialState createState() => _NSTutorialState();
}

class _NSTutorialState extends State<NSTutorial> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();
  }

  @override
  dispose() {
    // clear all lists and maps

    // clear all controllers and focus nodes

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Placeholder();
  }
}
