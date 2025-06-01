import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Tutorial extends StatefulWidget {
  final String title;
  final List<String> images;

  const Tutorial({super.key, required this.title, required this.images});

  @override
  // ignore: library_private_types_in_public_api
  _TutorialState createState() => _TutorialState();
}

class _TutorialState extends State<Tutorial> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  bool _lastPage = false;

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
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (index) async {
            if (index == widget.images.length - 1) {
              await LS().write("lastTutorial", Const().version);
              Widgets().showConfirmDialog(
                context,
                "This is the end of the tutorial. Click OK to close and go to Nitya Seva.",
                "OK",
                () {
                  Navigator.pop(context);
                },
              );
            }
          },
          itemBuilder: (context, index) {
            return Image.asset(widget.images[index]);
          },
        ),
      ],
    );
  }
}
