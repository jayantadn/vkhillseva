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
    "assets/images/Tutorials/01.png",
    "assets/images/Tutorials/02.png",
    "assets/images/Tutorials/03.png",
    "assets/images/Tutorials/04.png",
    "assets/images/Tutorials/05.png",
    "assets/images/Tutorials/06.png",
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
        onPageChanged: (index) {
          if (index == _images.length - 1) {
            setState(() {
              _lastPage = true;
            });
          }
        },
        itemBuilder: (context, index) {
          return Image.asset(_images[index]);
        },
      ),
      if (_lastPage)
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.black, size: 60),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) {
                  return NityaSeva(
                    title: "Nitya Seva",
                  );
                }));
              },
            ),
          ),
        )
    ]);
  }
}
