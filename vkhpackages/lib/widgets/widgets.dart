import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class Widgets {
  static final Widgets _instance = Widgets._internal();
  static final double maxCardWidth = 400;
  static final double maxScreenHeight = 1000;

  factory Widgets() {
    return _instance;
  }

  Widgets._internal() {
    // init
  }

  Widget createContextMenu(List<String> items, Function(String) onPressed) {
    return Builder(
      builder: (context) {
        final GlobalKey iconButtonKey = GlobalKey();
        return IconButton(
          key: iconButtonKey,
          icon: Icon(Icons.more_vert),
          onPressed: () async {
            final RenderBox renderBox =
                iconButtonKey.currentContext!.findRenderObject() as RenderBox;
            final Offset position = renderBox.localToGlobal(
              renderBox.size.bottomCenter(Offset.zero),
            );

            final selectedValue = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                position.dx,
                position.dy,
                position.dx + 1,
                position.dy + 1,
              ),
              items: List.generate(
                items.length,
                (index) => PopupMenuItem<String>(
                  value: items[index],
                  child: Text(items[index]),
                ),
              ),
            );

            onPressed(selectedValue ?? "");
          },
        );
      },
    );
  }

  Widget createImageButton({
    required BuildContext context,
    required String image,
    required String text,
    required void Function() onPressed,
    bool? imageOnRight,
    double? fixedWidth, // Optional parameter to set a specific width
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        constraints:
            fixedWidth != null
                ? BoxConstraints(
                  minHeight: 50,
                  maxHeight: 50,
                  maxWidth: fixedWidth,
                  minWidth: fixedWidth,
                )
                : BoxConstraints(minHeight: 50, maxHeight: 50),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Row(
          mainAxisSize:
              fixedWidth != null ? MainAxisSize.max : MainAxisSize.min,
          children:
              imageOnRight == true
                  ? [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Center(
                          child: Text(
                            text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      child: Image.asset(
                        image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ]
                  : [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      child: Image.asset(
                        image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Center(
                          child: Text(
                            text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall!.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
        ),
      ),
    );
  }

  Widget createResponsiveRow(BuildContext context, List<Widget> children) {
    double maxWidth = MediaQuery.of(context).size.width;

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 0,
      runSpacing: 0,
      children: [
        for (var child in children)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
      ],
    );
  }

  Widget createTopLevelResponsiveContainer(
    BuildContext context,
    List<Widget> children,
  ) {
    double maxWidth = maxCardWidth;
    final double screenWidth = MediaQuery.of(context).size.width;

    maxWidth = screenWidth < maxWidth * 2 ? screenWidth : maxWidth;

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var child in children)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, minWidth: maxWidth),
            child: child,
          ),
      ],
    );
  }

  Widget createTopLevelCard({
    required BuildContext context,
    required Widget child,
    String? title,
  }) {
    double maxWidth = maxCardWidth;
    final double screenWidth = MediaQuery.of(context).size.width;
    maxWidth =
        (screenWidth > maxWidth && screenWidth < maxWidth * 2)
            ? screenWidth
            : maxWidth;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, minWidth: maxWidth),
        child: Card(
          child: Column(
            children: [
              // title
              if (title != null)
                Container(
                  width: double.infinity, // Stretch to full width
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),

              // child widget
              Padding(padding: const EdgeInsets.all(4.0), child: child),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showResponsiveDialog({
    required BuildContext context,
    String? title,
    required Widget child,
    required List<Widget> actions,
  }) async {
    final double screenHeight = MediaQuery.of(context).size.height;

    if (screenHeight > maxScreenHeight) {
      // show dialog for desktop
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title ?? ''),
            content: SingleChildScrollView(child: child),
            actions: actions,
          );
        },
      );
    } else {
      // show top modal for mobile
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black45,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (
          BuildContext buildContext,
          Animation animation,
          Animation secondaryAnimation,
        ) {
          return Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0),
              ),
              child: IntrinsicHeight(
                // Ensures the height is based on the child
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    createTopLevelCard(
                      context: context,
                      title: title,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            child,
                            SizedBox(height: 10),
                            if (actions.isNotEmpty)
                              createResponsiveRow(context, actions),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, -1),
              end: Offset(0, 0),
            ).animate(animation),
            child: child,
          );
        },
      );
    }
  }

  Future<void> showMessage(BuildContext context, String msg) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Attention!'),
          content: Text(msg),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showConfirmDialog(
    BuildContext context,
    String msg,
    String? actionType,
    void Function()? action,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(msg),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(onPressed: action, child: Text(actionType ?? 'OK')),
          ],
        );
      },
    );
  }
}
