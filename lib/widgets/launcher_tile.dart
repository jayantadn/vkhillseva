import 'package:flutter/material.dart';
import 'package:vkhillseva/common/theme.dart';

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
                    child: Text(
                      title,
                      style: scale == 1
                          ? Theme.of(context).textTheme.headlineMedium
                          : Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: primaryColor, fontWeight: FontWeight.bold),
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
        title: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            imageLeading,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
          ),
        ),
        subtitle: Text(text),
        trailing: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            imageTrailing,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
          ),
        ),
        onTap: () {
          if (callback != null) {
            callback!.onClick();
          }
        },
      ),
    );

    // return SizedBox(
    //   width: 150,
    //   height: 210,
    //   child: GestureDetector(
    //     onTap: () {
    //       if (callback != null) {
    //         callback!.onClick();
    //       }
    //     },
    //     child: Card(
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: <Widget>[
    //           // title
    //           SizedBox(
    //             height: 55,
    //             width: double.infinity,
    //             child: Padding(
    //               padding: const EdgeInsets.all(8.0),
    //               child: Center(
    //                 child: Text(
    //                   title,
    //                   style: Theme.of(context).textTheme.headlineSmall,
    //                   textAlign: TextAlign.center,
    //                 ),
    //               ),
    //             ),
    //           ),

    //           Divider(),

    //           // image
    //           Center(
    //             child: CircleAvatar(
    //               radius: 35,
    //               backgroundImage: AssetImage(image),
    //             ),
    //           ),

    //           Divider(),

    //           // footer
    //           Padding(
    //             padding: const EdgeInsets.symmetric(horizontal: 4.0),
    //             child: Text(
    //               text,
    //               style: Theme.of(context).textTheme.bodySmall,
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}

class LauncherTileCallback {
  final Function() onClick;

  LauncherTileCallback({required this.onClick});
}
