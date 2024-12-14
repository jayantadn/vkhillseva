import 'package:flutter/material.dart';
import 'package:vkhillseva/common/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';

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
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        leading: ClipRRect(
          borderRadius:
              BorderRadius.circular(8.0), // Adjust the radius as needed
          child: Image.asset(
            icon,
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                children: [
                  // Nitya Seva Festival settings
                  _createSettingsCard(
                    title: 'Nitya Seva Festival',
                    icon: "assets/images/LauncherIcons/NityaSeva.png",
                    callback: SettingsCallback(callback: () {
                      // Navigator.pushNamed(context, '/nitya_seva_festival');
                    }),
                  ),
                ],
              ),
            ),

            // circular progress indicator
            if (_isLoading)
              LoadingOverlay(
                  image: 'assets/images/Logo/KrishnaLilaPark_square.png')
          ],
        ),
      ),
    );
  }
}

class SettingsCallback {
  final Function callback;

  SettingsCallback({required this.callback});
}
