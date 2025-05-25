import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class UserManagement extends StatefulWidget {
  final String title;
  final String? splashImage;

  const UserManagement({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _UserManagementState createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  String? _dropdownValue;

  // lists
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _userProfiles = {};
  List<UserBasics> _userBasics = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _userData.clear();
    _userProfiles.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      String dbpathUM = "${Const().dbrootGaruda}/Settings/UserManagement";
      String dbpathUP = "${Const().dbrootGaruda}/Settings/UserProfileSettings";
      _userData = await FB().getJson(path: dbpathUM);
      _userProfiles = await FB().getJson(path: dbpathUP);
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createUserCard(int index) {
    UserBasics user = _userBasics[index];

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: ListTile(
          title: Text(user.mobile),
          subtitle: Text(user.name),
          trailing:
              Widgets().createContextMenu(["Edit", "Delete"], (value) {})),
    );
  }

  Future<void> _setUserBasics() async {
    if (_dropdownValue == null || _userData.isEmpty || _userProfiles.isEmpty) {
      return;
    }

    _userBasics.clear();
    for (String mobile in _userData[_dropdownValue]) {
      UserBasics basics = UserBasics(name: "Unknown", mobile: mobile);

      var profile = _userProfiles[mobile];
      if (profile != null) {
        basics.name = profile['name'];
      }
      _userBasics.add(basics);
    }
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

                      // input fields
                      Widgets().createTopLevelCard(
                        context: context,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(children: [
                            // dropdown for category
                            SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: DropdownButton<String>(
                                  onChanged: (value) {
                                    setState(() {
                                      _dropdownValue = value;
                                      _setUserBasics();
                                    });
                                  },
                                  value: _dropdownValue,
                                  hint: const Text('Select an option',
                                      textAlign: TextAlign.center),
                                  isExpanded: true,
                                  alignment: Alignment.center,
                                  items: _userData.keys
                                      .toList()
                                      .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Center(
                                          child: Text(
                                        value,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: value == "Admin"
                                                ? Colors.red
                                                : Colors.black),
                                      )),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),

                            Row(
                              children: [
                                // mobile number field
                                Expanded(
                                  flex: 8,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'Enter mobile number',
                                    ),
                                    keyboardType: TextInputType.phone,
                                    onChanged: (value) {},
                                  ),
                                ),

                                // circular add button
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Material(
                                      color: _dropdownValue == "Admin"
                                          ? Colors.red
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary, // dark background
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        icon: Icon(Icons.add,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary), // white icon
                                        onPressed: () {
                                          // add user logic
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ]),
                        ),
                      ),

                      // list of users
                      Widgets().createTopLevelCard(
                        context: context,
                        child: Column(
                            children: List.generate(_userBasics.length,
                                (index) => _createUserCard(index))),
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
          LoadingOverlay(
            image: widget.splashImage ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
