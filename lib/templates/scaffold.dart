import 'package:flutter/material.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:vkhillseva/common/theme.dart';

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

  @override
  dispose() {
    // clear all lists

    // clear all controllers

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    setState(() {
      _isLoading = false;
    });
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
                  const Placeholder(),
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
