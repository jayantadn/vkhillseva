import 'package:flutter/material.dart';
import 'package:vkhillseva/common/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';
import 'package:vkhillseva/widgets/date_header.dart';

class NityaSeva extends StatefulWidget {
  final String title;

  const NityaSeva({super.key, required this.title});

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
                  DateHeader(
                      callbacks:
                          DateHeaderCallbacks(onChange: (DateTime date) {})),
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
