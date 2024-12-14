import 'package:flutter/material.dart';
import 'package:vkhillseva/common/config.dart';
import 'package:vkhillseva/common/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';

class FestivalSettingsPage extends StatefulWidget {
  final String title;

  const FestivalSettingsPage({super.key, required this.title});

  @override
  _FestivalSettingsPageState createState() => _FestivalSettingsPageState();
}

class _FestivalSettingsPageState extends State<FestivalSettingsPage> {
  bool _isLoading = true;

  // Map<name, icon>
  Map<String, String> _sevaList = {};

  @override
  initState() {
    super.initState();

    // synchronous init
    _sevaList = Config().getFestivalIcons();

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
