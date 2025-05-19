import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/profile_details.dart';
import 'package:vkhpackages/vkhpackages.dart';

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
  String _tab = "Performers";

  // lists
  final List<PerformerProfile> _performers = [];
  final List<Performer> _supporters = [];

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
    _supporters.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    await _lock.synchronized(() async {
      // perform async operations here

      // performers
      _performers.clear();
      List<dynamic> usersRawList = await FB().getList(
        path: "${Const().dbrootSangeetSeva}/Users",
      );
      for (var userRaw in usersRawList) {
        Map<String, dynamic> userJson = Map<String, dynamic>.from(userRaw);
        PerformerProfile user = PerformerProfile.fromJson(userJson);
        _performers.add(user);
      }

      // supporters
      _supporters.clear();
      for (PerformerProfile user in _performers) {
        _supporters.addAll(user.referrals);
      }
    });

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createPerformerCard(int index) {
    var member = _performers[index];
    return ListTile(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProfileDetails(
                      title: "Profile details",
                      userdetails: _performers[index],
                    )));
      },
      leading: CircleAvatar(
        backgroundImage: NetworkImage(member.profilePicUrl),
      ),
      title: Text("${member.salutation} ${member.name}"),
      subtitle: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(member.mobile),
              ],
            ),
            SizedBox(width: 10),
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(member.credentials),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _createSupporterCard(int indexSupporter, int indexPerformer) {
    var member = _supporters[indexSupporter];
    return ListTile(
      title: Text("${member.salutation} ${member.name}"),
      subtitle: Row(
        children: [
          Icon(Icons.workspace_premium, size: 16),
          SizedBox(width: 5),
          Text(member.specialization),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeGaruda,
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

                          // radio performers vs supporters
                          RadioRow(
                            items: ["Performers", "Supporters"],
                            onChanged: (value) {
                              setState(() {
                                _tab = value;
                              });
                            },
                          ),

                          // performers list
                          if (_tab == "Performers")
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _performers.length,
                              itemBuilder: (context, index) {
                                return Card(child: _createPerformerCard(index));
                              },
                            ),

                          // supporters list
                          if (_tab == "Supporters")
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _supporters.length,
                              itemBuilder: (context, index) {
                                return Card(child: _createSupporterCard(index));
                              },
                            ),

                          // empty message
                          if ((_tab == "Performers" && _performers.isEmpty) ||
                              (_tab == "Supporters" && _supporters.isEmpty))
                            Center(
                              child: Text("No profiles found"),
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
