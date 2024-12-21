import 'package:flutter/material.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';
import 'package:vkhillseva/home/settings_festivals.dart';

class Settings extends StatefulWidget {
  final String title;

  const Settings({super.key, required this.title});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _isLoading = true;

  @override
  initState() {
    super.initState();

    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = false;
    });
  }

  Widget _createSettingsCard(
      {required String title,
      required String icon,
      required SettingsCallback callback}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: InkWell(
          onTap: () {
            callback.onClick();
          },
          child: ListTile(
            title:
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
            leading: ClipRRect(
              borderRadius:
                  BorderRadius.circular(8.0), // Adjust the radius as needed
              child: Image.asset(
                icon,
              ),
            ),
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
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                children: [
                  // Nitya Seva Festival settings
                  _createSettingsCard(
                    title: 'Festival List',
                    icon: "assets/images/LauncherIcons/NityaSeva.png",
                    callback: SettingsCallback(onClick: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FestivalSettingsPage(
                                title: "Festival List")),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading)
            LoadingOverlay(
                image: 'assets/images/Logo/KrishnaLilaPark_square.png')
        ],
      ),
    );
  }
}

class SettingsCallback {
  final Function onClick;

  SettingsCallback({required this.onClick});
}
