import 'package:flutter/material.dart';

// top icon, bottom text
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

// title, icon, text
class LauncherTile2 extends StatelessWidget {
  final String title;
  final String image;
  final String text;
  final LauncherTileCallback? callback;

  const LauncherTile2(
      {super.key,
      required this.image,
      required this.title,
      required this.text,
      this.callback});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        leading: CircleAvatar(
          backgroundImage: AssetImage(image),
        ),
        subtitle: Text(text),
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
