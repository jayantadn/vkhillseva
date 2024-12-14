import 'package:flutter/material.dart';
import 'package:vkhillseva/common/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';

class SettingsFestivals extends StatefulWidget {
  final String title;

  const SettingsFestivals({super.key, required this.title});

  @override
  _SettingsFestivalsState createState() => _SettingsFestivalsState();
}

class _SettingsFestivalsState extends State<SettingsFestivals> {
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
                  const Placeholder(),
                ],
              ),
            ),

            // circular progress indicator
            if (_isLoading)
              LoadingOverlay(image: 'assets/images/LauncherIcons/NityaSeva.png')
          ],
        ),
      ),
    );
  }
}
