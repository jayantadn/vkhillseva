import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/common/const.dart';
import 'package:vkhgaruda/common/fb.dart';
import 'package:vkhgaruda/sangeet_seva/profile_details.dart';
import 'package:vkhgaruda/sangeet_seva/user.dart';
import 'package:vkhgaruda/widgets/loading_overlay.dart';
import 'package:vkhgaruda/common/theme.dart';

class Profiles extends StatefulWidget {
  final String title;
  final String? icon;

  const Profiles({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilesState createState() => _ProfilesState();
}

class _ProfilesState extends State<Profiles> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists
  final List<UserDetails> _performers = [];

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
                              UserDetails userdetails = _performers[index];
                              return Card(
                                color:
                                    userdetails.fieldOfExpertise == "Vocalist"
                                        ? Colors.blue[50]
                                        : Colors.orange[50],
                                child: ListTile(
                                  title: Text(
                                    "${userdetails.salutation} ${userdetails.name} (${userdetails.credentials})",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          text: 'Specialization: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black),
                                          children: <TextSpan>[
                                            TextSpan(
                                              text:
                                                  userdetails.skills.join(', '),
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.normal),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(userdetails.profilePicUrl),
                                  ),
                                  trailing: Icon(
                                      userdetails.fieldOfExpertise == "Vocalist"
                                          ? Icons.mic
                                          : Icons.music_note),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ProfileDetails(
                                                  title: "Profile details",
                                                  userdetails: userdetails,
                                                )));
                                  },
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
