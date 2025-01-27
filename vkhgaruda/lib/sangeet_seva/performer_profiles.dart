import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/common/const.dart';
import 'package:vkhgaruda/common/fb.dart';
import 'package:vkhgaruda/sangeet_seva/user.dart';
import 'package:vkhgaruda/widgets/loading_overlay.dart';
import 'package:vkhgaruda/common/theme.dart';

class PerformerProfiles extends StatefulWidget {
  final String title;
  final String? icon;

  const PerformerProfiles({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _PerformerProfilesState createState() => _PerformerProfilesState();
}

class _PerformerProfilesState extends State<PerformerProfiles> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists
  List<UserDetails> _performers = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _performers.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here
    _performers.clear();
    List<dynamic> usersRawList =
        await FB().getList(path: "Users", dbroot: Const().dbrootSangeetSeva);
    for (var userRaw in usersRawList) {
      Map<String, dynamic> userJson = Map<String, dynamic>.from(userRaw);
      UserDetails user = UserDetails.fromJson(userJson);
      _performers.add(user);
    }

    // refresh all child widgets

    // perform sync operations here
    await _lock.synchronized(() async {});

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
                child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(children: [
                          // leave some space at top
                          SizedBox(height: 10),

                          // your widgets here
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _performers.length,
                            itemBuilder: (context, index) {
                              UserDetails performer = _performers[index];
                              return Card(
                                color: performer.fieldOfExpertise == "Vocalist"
                                    ? Colors.blue[50]
                                    : Colors.orange[50],
                                child: ListTile(
                                  title: Text(
                                    performer.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(performer.mobile),
                                    ],
                                  ),
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(performer.profilePicUrl),
                                  ),
                                  trailing: Icon(
                                      performer.fieldOfExpertise == "Vocalist"
                                          ? Icons.mic
                                          : Icons.music_note),
                                ),
                              );
                            },
                          ),

                          // leave some space at bottom
                          SizedBox(height: 100),
                        ])))),
          ),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: widget.icon)
        ],
      ),
    );
  }
}
