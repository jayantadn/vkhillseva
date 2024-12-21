import 'package:flutter/material.dart';
import 'package:vkhillseva/common/config.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';

class FestivalSettingsPage extends StatefulWidget {
  final String title;

  const FestivalSettingsPage({super.key, required this.title});

  @override
  _FestivalSettingsPageState createState() => _FestivalSettingsPageState();
}

class _FestivalSettingsPageState extends State<FestivalSettingsPage> {
  bool _isLoading = true;

  List<FestivalSettings> _sevaList = [];

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _sevaList.clear();

    // clear all controllers

    super.dispose();
  }

  Future<void> refresh() async {
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
                icon:
                    Icon(Icons.edit, color: Theme.of(context).iconTheme.color),
                onPressed: callback.onEdit as void Function()?,
              ),
              IconButton(
                icon: Icon(Icons.delete,
                    color: Theme.of(context).iconTheme.color),
                onPressed: callback.onDelete as void Function()?,
              ),
            ],
          ),
        ),
      ),
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
                  for (FestivalSettings seva in _sevaList)
                    _createSettingsCard(
                        title: seva.name,
                        icon: seva.icon,
                        callback: FestivalSettingsCallback(
                          onEdit: () {},
                          onDelete: () {},
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
  final Function() onEdit;
  final Function onDelete;

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
