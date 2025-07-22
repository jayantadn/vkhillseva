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
  String _mobile = "";

  // lists
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _userProfiles = {};
  final List<UserBasics> _userBasics = [];

  // controllers, listeners and focus nodes
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
          trailing: Widgets().createContextMenu(
              items: ["Delete"],
              onPressed: (value) {
                if (value.isEmpty) {
                  return;
                }

                if (value == "Delete") {
                  _onDeleteUser(user.mobile);
                } else {
                  Toaster().error("Unknown action: $value");
                }
              })),
    );
  }

  String _getUsername(String mobile) {
    var profile = _userProfiles[mobile];
    return profile != null ? profile['name'] : "Unknown";
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

  Future<void> _onAddUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_userData[_dropdownValue].contains(_mobile)) {
      Toaster().error("User already exists");
      return;
    }

    // add user to the database
    String dbpath =
        "${Const().dbrootGaruda}/Settings/UserManagement/$_dropdownValue";
    await FB().addToList(listpath: dbpath, data: _mobile);

    // add to userbasics list
    UserBasics newUser = UserBasics(name: "Unknown", mobile: _mobile);
    setState(() {
      _userBasics.add(newUser);
    });

    Toaster().info("User added");
  }

  Future<void> _onDeleteUser(String mobile) async {
    String username = _getUsername(mobile);
    if (username == "Unknown") {
      username = "";
    }

    await Widgets().showConfirmDialog(
        context, "Are you sure to delete:\n$mobile\n$username", "Delete",
        () async {
      // remove user from the database
      String dbpath =
          "${Const().dbrootGaruda}/Settings/UserManagement/$_dropdownValue";
      await FB().deleteFromListByValue(listpath: dbpath, value: mobile);

      // remove from userbasics list
      setState(() {
        _userBasics.removeWhere((user) => user.mobile == mobile);
      });

      Toaster().info("User deleted");
    });
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
                          child: Form(
                            key: _formKey,
                            child: Column(children: [
                              // dropdown for category
                              SizedBox(
                                width: double.infinity,
                                child: Center(
                                  child: DropdownButtonFormField<String>(
                                    onChanged: (value) async {
                                      await refresh();
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
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select an option';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),

                              SizedBox(height: 10),
                              Row(
                                children: [
                                  // mobile number field
                                  Expanded(
                                    flex: 8,
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        hintText: 'Enter mobile number',
                                      ),
                                      keyboardType: TextInputType.phone,
                                      onChanged: (value) {
                                        _mobile = value;
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a mobile number';
                                        }

                                        if (value.startsWith('+') &&
                                            value.length != 13) {
                                          return 'Invalid mobile number';
                                        }

                                        if (value.startsWith('91') &&
                                            (value.length < 10 ||
                                                value.length > 12 ||
                                                value.length == 11)) {
                                          return 'Invalid mobile number';
                                        }

                                        if (value.length < 10) {
                                          return 'Mobile number must be 10 digits';
                                        }

                                        if (!RegExp(r'^[\d+]+$')
                                            .hasMatch(value)) {
                                          return 'Only numbers and + are allowed';
                                        }

                                        return null;
                                      },
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
                                                    .secondary),
                                            onPressed: () async {
                                              // Validate the form
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                await _onAddUser();
                                                // Clear the field
                                                setState(() {
                                                  _mobile = "";
                                                });
                                                // Unfocus and clear the text field
                                                FocusScope.of(context)
                                                    .unfocus();
                                                _formKey.currentState!.reset();
                                              }
                                            },
                                          )),
                                    ),
                                  ),
                                ],
                              )
                            ]),
                          ),
                        ),
                      ),

                      // list of users
                      if (_userBasics.isNotEmpty)
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
