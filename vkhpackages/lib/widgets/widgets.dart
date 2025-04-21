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

  Widget createResponsiveContainer(
    BuildContext context,
    List<Widget> children,
  ) {
    double maxWidth = 350;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Ensure maxWidth is adjusted to fit within the screen width
    maxWidth =
        screenWidth < maxWidth * 2
            ? (screenWidth - 20) /
                2 // Adjust for spacing and padding
            : maxWidth;

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

  Widget createTopLevelCard(BuildContext context, Widget child) {
    double maxWidth = 350;
    final double screenWidth = MediaQuery.of(context).size.width;
    maxWidth =
        (screenWidth > maxWidth && screenWidth < maxWidth * 2)
            ? screenWidth
            : maxWidth;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Card(child: child),
      ),
    );
  }

  Future<void> showMessage(BuildContext context, String msg) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
