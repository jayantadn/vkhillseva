import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Support extends StatefulWidget {
  final String title;

  const Support({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _SupportState createState() => _SupportState();
}

class _SupportState extends State<Support> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeDefault,
      child: Stack(
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

                        // FAQ
                        Text(
                          "FAQ",
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height / 2,
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (var faq in faqs)
                                ListTile(
                                  title: Text(faq["Q"] ?? ""),
                                  subtitle: Text(faq["A"] ?? ""),
                                ),
                            ],
                          ),
                        ),

                        // Contact us
                        SizedBox(height: 20),
                        Text(
                          "Contact support",
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 400),
                            child: Card(
                              child: ListTile(
                                leading: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    'assets/images/Common/WhatsApp.png',
                                  ),
                                ),

                                title: Text(
                                  "WhatsApp message",
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),

                                subtitle: Text("+91 9900995060"),

                                onTap: () {
                                  Utils().sendWhatsAppMessage(
                                    "+919900995060",
                                    "Hello, I need help with ...",
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

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
            LoadingOverlay(image: "assets/images/Logo/SangeetSeva.png"),
        ],
      ),
    );
  }
}

// [
// {
//   "Q": "a question",
//   "A": "an answer",
// }
// ]
final List<Map<String, String>> faqs = [
  {
    "Q": "Did not receive OTP?",
    "A":
        "Check spam folder in messages app. If not received, try again at later point.",
  },
];
