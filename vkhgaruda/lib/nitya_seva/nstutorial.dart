import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/nitya_seva/nitya_seva.dart';
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
  bool _lastPage = false;
  final List<String> _images = [
    "assets/images/Tutorials/NityaSevaBasics/01.png",
    "assets/images/Tutorials/NityaSevaBasics/02.png",
    "assets/images/Tutorials/NityaSevaBasics/03.png",
    "assets/images/Tutorials/NityaSevaBasics/04.png",
    "assets/images/Tutorials/NityaSevaBasics/05.png",
    "assets/images/Tutorials/NityaSevaBasics/06.png",
    "assets/images/Tutorials/NityaSevaBasics/07.png",
  ];

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
    return Stack(children: [
      PageView.builder(
        itemCount: _images.length,
        onPageChanged: (index) async {
          print(index);
          if (index == _images.length - 1) {
            await LS().write("lastTutorial", Const().version);
            Widgets().showConfirmDialog(
                context,
                "This is the end of the tutorial. Click OK to close and go to Nitya Seva.",
                "OK", () {
              Navigator.pop(context);
            });
          }
        },
        itemBuilder: (context, index) {
          return Image.asset(_images[index]);
        },
      ),
    ]);
  }
}
