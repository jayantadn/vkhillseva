import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhsangeetseva/common/const.dart';

// ignore: must_be_immutable
class ImageSelector extends StatefulWidget {
  String? selectedImage;
  final ImageSelectorCallback callback;

  ImageSelector({super.key, this.selectedImage, required this.callback});

  @override
  State<ImageSelector> createState() => _ImageSelectorState();
}

// ignore: library_private_types_in_public_api
GlobalKey<_ImageSelectorState> summaryKey = GlobalKey<_ImageSelectorState>();

class _ImageSelectorState extends State<ImageSelector> {
  final Lock _lock = Lock();

  String _selectedImage = "";

  @override
  void initState() {
    super.initState();

    _selectedImage =
        widget.selectedImage ?? "assets/images/Logo/KrishnaLilaPark_square.png";

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers

    super.dispose();
  }

  void refresh() async {
    await _lock.synchronized(() async {
      // all you need to do
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (String icon in Const().icons)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImage = icon;
                });
                widget.callback.onImageSelected(icon);
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedImage == icon
                          ? Colors.blue
                          : Colors.transparent,
                      width: 4.0,
                    ),
                  ),
                  child: Image.asset(
                    icon,
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class ImageSelectorCallback {
  void Function(String image) onImageSelected;

  ImageSelectorCallback({required this.onImageSelected});
}
