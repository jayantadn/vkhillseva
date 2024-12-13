import 'package:flutter/material.dart';
import 'package:vkhillseva/common/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';

class NityaSeva extends StatefulWidget {
  const NityaSeva({super.key});

  @override
  _NityaSevaState createState() => _NityaSevaState();
}

class _NityaSevaState extends State<NityaSeva> {
  bool _isLoading = true;

  @override
  initState() {
    super.initState();

    refresh();
  }

  Future<void> refresh() async {
    await Future.delayed(const Duration(seconds: 2));
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
          title: const Text('Title'),
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
              LoadingOverlay(
                  image: 'assets/images/LauncherIcons/NityaSeva.png'),
          ],
        ),
      ),
    );
  }
}
