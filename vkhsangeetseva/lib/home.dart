import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  String _username = "";

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    // perform async operations here

    await _lock.synchronized(() async {
      // fetch form values

      // refresh all child widgets

      // perform sync operations here
    });

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createWelcome() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        // image
        Container(
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/Logo/SangeetSeva.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // all text
        SizedBox(
          height: 10,
        ),
        Text(
          'Welcome',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          _username.isEmpty ? 'Guest' : _username,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(
          height: 8,
        ),
        Text(
          'ISKCON Vaikuntha Hill',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'Govinda Sangeet Seva',
          style: GoogleFonts.pacifico(
            textStyle: Theme.of(context).textTheme.headlineLarge,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    children: [
                      // leave some space at top
                      SizedBox(height: 10),

                      Widgets().createResponsiveContainer(context, [
                        // your widgets here
                        Widgets().createTopLevelCard(context, _createWelcome())
                      ]),

                      // leave some space at bottom
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // circular progress indicator
        if (_isLoading)
          LoadingOverlay(
            image: "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
