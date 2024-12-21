import 'package:flutter/material.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';
import 'package:firebase_database/firebase_database.dart';

class FestivalSettingsPage extends StatefulWidget {
  final String title;

  const FestivalSettingsPage({super.key, required this.title});

  @override
  _FestivalSettingsPageState createState() => _FestivalSettingsPageState();
}

class _FestivalSettingsPageState extends State<FestivalSettingsPage> {
  bool _isLoading = true;

  final List<FestivalSettings> _festivals = [];

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _festivals.clear();

    // clear all controllers

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // fetch seva list from db
    DatabaseReference dbref =
        FirebaseDatabase.instance.ref("${Const().dbroot}/Config/Festivals");
    DataSnapshot snapshot = await dbref.get();
    if (snapshot.value != null) {
      List<dynamic> values = snapshot.value as List;
      _festivals.clear();
      for (var element in values) {
        if (element != null) {
          _festivals.add(
              FestivalSettings.fromJson(Map<String, String>.from(element)));
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createSettingsCard(
      {required String title,
      required String icon,
      required FestivalSettingsCallback callback}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: ListTile(
          title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              icon,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  icon: Icon(Icons.edit,
                      color: Theme.of(context).iconTheme.color),
                  onPressed: () {
                    callback.onEdit(FestivalSettings(name: title, icon: icon));
                  }),
              IconButton(
                  icon: Icon(Icons.delete,
                      color: Theme.of(context).iconTheme.color),
                  onPressed: () {
                    callback
                        .onDelete(FestivalSettings(name: title, icon: icon));
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void _onEdit(FestivalSettings old) async {
    final TextEditingController festivalNameController =
        TextEditingController(text: old.name);
    String selectedIcon = old.icon;

    // move the selected icon to front
    Const().icons.remove(selectedIcon);
    Const().icons.insert(0, selectedIcon);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Festival: ${old.name}"),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                // festival name
                TextField(
                  controller: festivalNameController,
                  decoration: InputDecoration(labelText: "Name"),
                ),

                // icon
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (String icon in Const().icons)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedIcon == icon
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
                )
              ],
            ),
          ),

          // buttons
          actions: [
            // cancel button
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

            // ok button
            TextButton(
              child: Text("OK"),
              onPressed: () {
                // edit the festival
                setState(() {
                  int index = _festivals.indexWhere((element) =>
                      element.name == old.name && element.icon == old.icon);
                  if (index >= 0) {
                    _festivals.removeAt(index);
                    _festivals.insert(
                        index,
                        FestivalSettings(
                            name: festivalNameController.text,
                            icon: selectedIcon));
                  }
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onDelete(FestivalSettings festival) async {}

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: Text(widget.title), actions: [
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  // Add your onPressed code here!
                },
              ),
            ]),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                children: [
                  for (FestivalSettings seva in _festivals)
                    _createSettingsCard(
                        title: seva.name,
                        icon: seva.icon,
                        callback: FestivalSettingsCallback(
                          onEdit: _onEdit,
                          onDelete: _onDelete,
                        ))
                ],
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading)
            LoadingOverlay(image: 'assets/images/LauncherIcons/NityaSeva.png')
        ],
      ),
    );
  }
}

class FestivalSettingsCallback {
  final void Function(FestivalSettings old) onEdit;
  final void Function(FestivalSettings festival) onDelete;

  FestivalSettingsCallback({required this.onEdit, required this.onDelete});
}

class FestivalSettings {
  final String name;
  final String icon;

  FestivalSettings({required this.name, required this.icon});

  factory FestivalSettings.fromJson(Map<String, dynamic> json) {
    return FestivalSettings(
      name: json['name'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
    };
  }
}
