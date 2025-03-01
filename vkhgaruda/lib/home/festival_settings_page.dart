import 'package:flutter/material.dart';
import 'package:vkhgaruda/widgets/image_selector.dart';
import 'package:vkhpackages/vkhpackages.dart';

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

    // fetch festival list from db
    var data = await FB()
        .getValue(path: "${Const().dbrootGaruda}/Settings/NityaSevaList");
    if (data != null) {
      List<dynamic> values = data as List;
      _festivals.clear();
      for (var element in values) {
        if (element != null) {
          _festivals.add(
              FestivalSettings.fromJson(Map<String, dynamic>.from(element)));
        }
      }
    }

    // write ids for each festival
    for (int i = 0; i < _festivals.length; i++) {
      _festivals[i] =
          FestivalSettings(name: _festivals[i].name, icon: _festivals[i].icon);
    }
    FB().setValue(
        path: "${Const().dbrootGaruda}/Settings/NityaSevaList",
        value: _festivals.map((e) => e.toJson()).toList());

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
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    callback.onEdit(FestivalSettings(name: title, icon: icon));
                  }),
              IconButton(
                  icon: Icon(Icons.delete),
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

  void _onAddEdit(FestivalSettings? old) async {
    final TextEditingController festivalNameController =
        TextEditingController(text: old == null ? "" : old.name);
    String selectedIcon = old == null ? "" : old.icon;

    // move the selected icon to front
    if (old != null) {
      Const().icons.remove(selectedIcon);
      Const().icons.insert(0, selectedIcon);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: old == null
              ? Text("Add new festival")
              : Text("Edit Festival: ${old.name}"),
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
                ImageSelector(
                    selectedImage: old == null ? "" : old.icon,
                    callback:
                        ImageSelectorCallback(onImageSelected: (String icon) {
                      selectedIcon = icon;
                    })),
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
                setState(() {
                  if (old == null) {
                    // add new festival
                    _festivals.add(FestivalSettings(
                        name: festivalNameController.text, icon: selectedIcon));
                    _festivals.sort((a, b) => a.name.compareTo(b.name));
                  } else {
                    // edit the festival
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
                  }
                });
                _festivals.sort((a, b) => a.name.compareTo(b.name));
                FB().setValue(
                    path: "${Const().dbrootGaruda}/Settings/NityaSevaList",
                    value: _festivals.map((e) => e.toJson()).toList());

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onDelete(FestivalSettings festival) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Festival"),
          content: Text("Are you sure you want to delete:\n${festival.name}?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                setState(() {
                  int index = _festivals.indexWhere((element) =>
                      element.name == festival.name &&
                      element.icon == festival.icon);
                  if (index >= 0) {
                    _festivals.removeAt(index);
                  }
                });
                await FB().setValue(
                    path: "${Const().dbrootGaruda}/Settings/NityaSevaList",
                    value: _festivals.map((e) => e.toJson()).toList());

                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: Text(widget.title), actions: [
              IconButton(
                icon: Icon(Icons.add, size: 32),
                onPressed: () {
                  _onAddEdit(null);
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
                          onEdit: _onAddEdit,
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
