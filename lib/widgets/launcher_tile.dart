import 'package:flutter/material.dart';

class LauncherTile extends StatelessWidget {
  final String image;
  final String title;
  final LauncherTileCallback? callback;

  const LauncherTile(
      {super.key, required this.image, required this.title, this.callback});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 200,
      child: GestureDetector(
        onTap: () {
          if (callback != null) {
            callback!.onClick();
          }
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
                child: Image.asset(image),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LauncherTileCallback {
  final Function() onClick;

  LauncherTileCallback({required this.onClick});
}
