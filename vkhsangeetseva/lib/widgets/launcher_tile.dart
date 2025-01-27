import 'package:flutter/material.dart';

// top icon, bottom text
class LauncherTile extends StatelessWidget {
  final String image;
  final String title;
  final double scale;
  final LauncherTileCallback? callback;

  const LauncherTile(
      {super.key,
      required this.image,
      required this.title,
      this.scale = 1.0,
      this.callback});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150 * scale,
      height: 220 * scale,
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
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        scale == 1 ? title : title.replaceAll(" ", "\n"),
                        style: scale == 1
                            ? Theme.of(context).textTheme.headlineMedium
                            : Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
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

// title, icon, text
class LauncherTile2 extends StatelessWidget {
  final String title;
  final String imageLeading;
  final String imageTrailing;
  final String text;
  final LauncherTileCallback? callback;

  const LauncherTile2(
      {super.key,
      required this.imageLeading,
      required this.imageTrailing,
      required this.title,
      required this.text,
      this.callback});

  @override
  Widget build(BuildContext context) {
    double imageSize = 50;

    return Card(
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CircleAvatar(
          backgroundImage: AssetImage(imageLeading),
          radius: imageSize / 2,
        ),
        subtitle: Text(text),
        trailing: CircleAvatar(
          backgroundImage: AssetImage(imageTrailing),
          radius: imageSize / 2,
        ),
        onTap: () {
          if (callback != null) {
            callback!.onClick();
          }
        },
      ),
    );
  }
}

class LauncherTileCallback {
  final Function() onClick;

  LauncherTileCallback({required this.onClick});
}
