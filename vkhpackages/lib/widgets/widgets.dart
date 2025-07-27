import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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

  Widget createContextMenu({
    required List<String> items,
    required Function(String) onPressed,
    Color? color,
  }) {
    return Builder(
      builder: (context) {
        final GlobalKey iconKey = GlobalKey();
        return SizedBox(
          width: 24, // Smaller width for just the icon
          height: 24, // Smaller height for just the icon
          child: GestureDetector(
            key: iconKey,
            onTap: () async {
              final RenderBox renderBox =
                  iconKey.currentContext!.findRenderObject() as RenderBox;
              final Offset position = renderBox.localToGlobal(
                renderBox.size.bottomCenter(Offset.zero),
              );

              final selectedValue = await showMenu<String>(
                context: context,
                position: RelativeRect.fromLTRB(
                  position.dx,
                  position.dy,
                  MediaQuery.of(context).size.width - position.dx,
                  MediaQuery.of(context).size.height - position.dy,
                ),
                items: List.generate(
                  items.length,
                  (index) => PopupMenuItem<String>(
                    value: items[index],
                    child: Text(
                      items[index],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              );

              if (selectedValue != null) {
                onPressed(selectedValue);
              }
            },
            child: Icon(
              Icons.more_vert,
              size: 24,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
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
      spacing: 2,
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
    Color? color,
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
                    color: color ?? Theme.of(context).primaryColor,
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

  Widget showColorpicker({
    required BuildContext context,
    required void Function(String) onColorSelected,
    String? initialColorHex,
  }) {
    Color tempColor = Utils().getRandomDarkColor();

    if (initialColorHex != null) {
      tempColor = Color(int.parse("0xff$initialColorHex"));
    }

    return GestureDetector(
      onTap: () async {
        Color? pickedColor = await showDialog<Color>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Pick a color"),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: tempColor,
                  onColorChanged: (color) {
                    tempColor = color;
                  },
                  showLabel: true,
                  pickerAreaHeightPercent: 0.8,
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text("Select"),
                  onPressed: () {
                    onColorSelected(
                      tempColor.value.toRadixString(16).substring(2),
                    );
                    Navigator.of(context).pop(tempColor);
                  },
                ),
              ],
            );
          },
        );
        if (pickedColor != null) {
          // Handle the picked color, e.g. setState or assign to a variable
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tempColor, // Replace with selected color variable
          border: Border.all(color: Colors.black26),
        ),
      ),
    );
  }

  Future<dynamic> showConfirmDialog(
    BuildContext context,
    String msg,
    String? actionType,
    void Function()? action,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm $actionType'),
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
            TextButton(
              onPressed: () {
                if (action != null) {
                  action();
                }
                Navigator.of(context).pop(actionType);
              },
              child: Text(actionType ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> showResponsiveDialog({
    required BuildContext context,
    String? title,
    required Widget child,
    required List<Widget> actions,
  }) async {
    final double screenHeight = MediaQuery.of(context).size.height;

    // add cancel button to actions
    actions.insert(
      0,
      TextButton(
        onPressed: () {
          // close dialog without saving
          Navigator.of(context).pop();
        },
        child: const Text("Cancel"),
      ),
    );

    if (screenHeight > maxScreenHeight) {
      // show dialog for desktop
      return await showDialog(
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
      // insert some padding between actions
      List<Widget> paddedActions = [];
      if (actions.isNotEmpty) {
        for (var action in actions) {
          paddedActions.add(action);
          paddedActions.add(SizedBox(width: 10));
        }
      }

      // show top modal for mobile
      return await showGeneralDialog(
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
                    if (!kIsWeb) SizedBox(height: 50),
                    createTopLevelCard(
                      context: context,
                      title: title,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            child,
                            SizedBox(height: 10),
                            if (paddedActions.isNotEmpty)
                              createResponsiveRow(context, paddedActions),
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
}
