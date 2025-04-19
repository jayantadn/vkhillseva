import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vkhpackages/widgets/radio_row.dart';
import 'package:file_picker/file_picker.dart';

class Profile extends StatefulWidget {
  final String title;
  final String? icon;
  final bool? self;
  final Function(UserDetails user)? onProfileSaved;
  final String? friendMobile;
  final UserDetails? oldUserDetails;

  const Profile(
      {super.key,
      required this.title,
      this.icon,
      this.self,
      this.onProfileSaved,
      this.friendMobile,
      this.oldUserDetails});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  String _profilePicUrl = '';
  late String _salutation;
  UserDetails? _userDetailsOld;

  // lists
  final List<String> _salutations = [
    'Shri',
    'Smt',
    'Kumar',
    'Kumari',
    'Vidwan',
    'Vidushi',
    'Chiranjeevi',
    'Others'
  ];

  final List<String> _vocalSkills = [
    'Hindustani',
    'Carnatic',
    'Western',
    'Bhajan Mandali',
    'Semi classical',
    'Sugam Sangeet',
    'Others'
  ];

  final List<String> _instrumentSkills = [
    'Veena',
    'Flute',
    'Tabla',
    'Mridangam',
    'Harmonium',
    'Kartaal',
    'Violin',
    'Keyboard',
    'Others'
  ];

  List<SangeetExp> _exp = [];

  List<String> _youtubeLinks = ["", "", ""];
  List<String> _audioClips = [
    "",
    "",
    ""
  ]; // this is local file path before upload. after upload it becomes firestore url.

  // controllers, listeners and focus nodes
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _credController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  initState() {
    super.initState();

    _salutation = _salutations[0];

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _salutations.clear();
    _instrumentSkills.clear();
    _vocalSkills.clear();
    _youtubeLinks.clear();
    _audioClips.clear();

    // clear all controllers and focus nodes
    _nameController.dispose();
    _mobileController.dispose();
    _formKey.currentState?.dispose();

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here

    // fetch form values
    if (widget.self != null && widget.self == true) {
      await Utils().fetchUserBasics();
      UserBasics? basics = Utils().getUserBasics();
      if (basics != null) {
        String mobile = basics.mobile;
        bool exists =
            await FB().pathExists("${Const().dbrootSangeetSeva}/Users/$mobile");
        if (exists) {
          Map<String, dynamic> userdetailsJson = await FB()
              .getJson(path: "${Const().dbrootSangeetSeva}/Users/$mobile");
          _userDetailsOld = UserDetails.fromJson(userdetailsJson);
        }
      }
    } else if (widget.oldUserDetails != null) {
      _userDetailsOld = widget.oldUserDetails;
    }

    await _lock.synchronized(() async {
      // perform sync operations here
      if (widget.self != null && widget.self == true) {
        UserBasics? basics = Utils().getUserBasics();
        if (basics != null) {
          _nameController.text = basics.name;
          _mobileController.text = basics.mobile;
        }
      }

      if (_userDetailsOld != null) {
        _salutation = _userDetailsOld!.salutation;
        _nameController.text = _userDetailsOld!.name;
        _mobileController.text = _userDetailsOld!.mobile;
        _profilePicUrl = _userDetailsOld!.profilePicUrl;
        _credController.text = _userDetailsOld!.credentials;
        _exp = _userDetailsOld!.exps;
        _youtubeLinks = _userDetailsOld!.youtubeUrls;
        _audioClips = _userDetailsOld!.audioClipUrls;

        while (_youtubeLinks.length < 3) {
          _youtubeLinks.add("");
        }
        while (_audioClips.length < 3) {
          _audioClips.add("");
        }
      }

      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _handleExistingUser(BuildContext context) async {
    // fetch existing user details
    String dbpath =
        "${Const().dbrootSangeetSeva}/Users/${_mobileController.text}";
    Map<String, dynamic> userdetailsJson = await FB().getJson(path: dbpath);
    UserDetails? userDetails = UserDetails.fromJson(userdetailsJson);

    // check if current user is friend
    bool isFriend = false;
    UserBasics? currentUser = Utils().getUserBasics();
    if (currentUser != null) {
      if (userDetails.friendMobile != null &&
          userDetails.friendMobile!.contains(currentUser.mobile)) {
        isFriend = true;
      }
    }

    // show dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User already exists'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mobile: ${_mobileController.text}'),
                Text('Name: ${userDetails.salutation} ${userDetails.name}'),
                Text('Credentials: ${userDetails.credentials}'),
                SizedBox(height: 4),
                if (!isFriend)
                  Text('You do not have permission to edit this profile.',
                      style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Use existing'),
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                widget.onProfileSaved!(userDetails);
              },
            ),
            if (isFriend)
              TextButton(
                child: Text('Overwrite'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _save();
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);

    String downloadUrl = '';
    if (image != null) {
      // compress the image
      final rawImage = await image.readAsBytes();
      final ByteData? byteData =
          await resizeImage(Uint8List.view(rawImage.buffer), height: 250);
      if (byteData == null) {
        Toaster().error('Error compressing image');
        return;
      }
      final bytes = byteData.buffer.asUint8List();

      setState(() {
        _isLoading = true;
      });

      // upload to firestore
      String path =
          "${Const().dbrootSangeetSeva}/Users/${_mobileController.text}/profile.png";
      final storageRef = FirebaseStorage.instance.ref();
      final fileRef = storageRef.child(path);

      try {
        await fileRef.putData(bytes);
        downloadUrl = await fileRef.getDownloadURL();
      } catch (e) {
        Toaster().error('Error uploading file: $e');
      }

      Toaster().info('Image uploaded');
      setState(() {
        _isLoading = false;
      });
    } else {
      Toaster().error('No image selected');
    }

    setState(() {
      _profilePicUrl = downloadUrl;
    });
  }

  Future<void> _save() async {
    // validation of form
    if (!_formKey.currentState!.validate()) {
      Toaster().error('There are errors in the form');
      return;
    }

    // validation for profile photo
    if (_profilePicUrl.isEmpty) {
      Toaster().error('Please upload your profile picture');
      return;
    }

    // validation of performance links
    if (widget.self != null && widget.self == true) {
      if (_youtubeLinks[0].isEmpty && _audioClips[0].isEmpty) {
        Toaster().error(
            'Please enter at least one youtube link or upload one audio clip');
        return;
      }
    }

    // validation for sangeet experience
    if (_exp.isEmpty) {
      Toaster().error('Please enter your sangeet sadhana details');
      return;
    }

    // no abrupt returns after this point
    setState(() {
      _isLoading = true;
    });

    // Convert name to title case
    String name = _nameController.text;
    setState(() {
      _nameController.text = name.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');

      _nameController.text = _nameController.text.trim();
    });

    // create user details object
    UserDetails? details;
    details = UserDetails(
        salutation: _salutation,
        name: _nameController.text,
        mobile: _mobileController.text,
        profilePicUrl: _profilePicUrl,
        exps: _exp,
        credentials: _credController.text,
        youtubeUrls: _youtubeLinks.where((link) => link.isNotEmpty).toList(),
        audioClipUrls: _audioClips.where((link) => link.isNotEmpty).toList(),
        friendMobile: widget.friendMobile);

    // set the FCM token
    String? fcmToken = await Notifications().setupFirebaseMessaging();
    if (fcmToken == null) {
      Toaster().error("FCM token not available");
    } else {
      details.fcmToken = fcmToken;
    }

    // write to database
    await Utils().setUserDetails(details);

    // update old details
    _userDetailsOld = details;

    // Write to local storage
    if (widget.self != null && widget.self == true) {
      UserBasics basics = UserBasics(
        name: details.name,
        mobile: details.mobile,
        uid: Utils().getUserBasics()!.uid,
      );
      await LS().write("userbasics", jsonEncode(basics));
    }

    // invoke the callback
    if (widget.onProfileSaved != null) {
      widget.onProfileSaved!(details);
    }

    Toaster().info('Profile saved');
    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).pop();
  }

  Future<void> _showDialogSangeetExp(BuildContext context) async {
    String selectedExpertiseType = "Vocal";
    String selectedSkill = _vocalSkills[0];
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController othersController = TextEditingController();
    final TextEditingController yearsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // title for dialog
          title: Text('Sangeet sadhana details',
              style: Theme.of(context).textTheme.headlineMedium),
          content: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // stateful widgets
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Column(
                        children: [
                          // radio for vocal/instrumental
                          RadioRow(
                            items: ["Vocal", "Instrumental"],
                            onChanged: (String value) {
                              setState(() {
                                selectedExpertiseType = value;
                                selectedSkill = value == "Vocal"
                                    ? _vocalSkills[0]
                                    : _instrumentSkills[0];
                              });
                            },
                          ),

                          // dropdown for skills
                          SizedBox(height: 10),
                          DropdownButton<String>(
                            isExpanded: true,
                            value: selectedExpertiseType == "Vocal"
                                ? _vocalSkills[0]
                                : _instrumentSkills[0],
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedSkill = newValue!;
                              });
                            },
                            items: selectedExpertiseType == "Vocal"
                                ? _vocalSkills.map<DropdownMenuItem<String>>(
                                    (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList()
                                : _instrumentSkills
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                          ),

                          // hidden box for others
                          SizedBox(height: 10),
                          if (selectedSkill == "Others")
                            TextFormField(
                                controller: othersController,
                                decoration: InputDecoration(
                                  labelText: 'Please specify',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Provide valid input';
                                  }
                                  return null;
                                }),
                        ],
                      );
                    },
                  ),

                  // Stateless widgets
                  // exp in years
                  SizedBox(height: 10),
                  TextFormField(
                    controller: yearsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Years of sadhana"),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.parse(value) < 0) {
                        return 'Provide valid input';
                      }
                      return null;
                    },
                  )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                // clear all local lists

                // clear all local controllers and focus nodes

                // close the dialog
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                // validate
                if (!formKey.currentState!.validate()) {
                  return;
                }

                // Handle the add logic here
                SangeetExp exp = SangeetExp(
                  category: selectedExpertiseType,
                  subcategory: selectedSkill == "Others"
                      ? othersController.text
                      : selectedSkill,
                  yrs: int.parse(yearsController.text),
                );
                setState(() {
                  _exp.add(exp);
                });

                // clear all local lists

                // clear all local controllers and focus nodes

                // close the dialog
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getFileNameFromUrl(String url) {
    if (url.isEmpty) return "No files selected";

    if (url.substring(0, 8) == "https://") {
      Uri uri = Uri.parse(url);
      return uri.pathSegments.last.split('/').last;
    } else {
      return "Local: ${url.split('/').last}";
    }
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
              actions: [
                IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () async {
                    // validation if user already exists
                    String dbpath =
                        "${Const().dbrootSangeetSeva}/Users/${_mobileController.text}";
                    bool exists = await FB().pathExists(dbpath);
                    if (exists) {
                      await _handleExistingUser(context);
                    } else {
                      await _save();
                    }
                  },
                )
              ],
            ),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Form(
                    key: _formKey,
                    child: Column(children: [
                      // leave some space at top
                      SizedBox(height: 10),

                      Utils().responsiveBuilder(context, [
                        // salutation
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Salutation',
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12.0),
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _salutation,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _salutation = newValue!;
                                });
                              },
                              items: _salutations.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Name cannot be empty';
                            }
                            if (value.length < 3) {
                              return 'Please enter full name';
                            }
                            return null;
                          },
                        ),

                        // mobile
                        TextFormField(
                          controller: _mobileController,
                          decoration: const InputDecoration(
                            labelText: 'Mobile',
                          ),
                          readOnly: widget.self ?? false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mobile number cannot be empty';
                            }
                            if (value.length != 10) {
                              return 'Please enter 10 digit mobile number';
                            }
                            return null;
                          },
                        ),

                        // Sangeet credentials
                        TextFormField(
                          controller: _credController,
                          decoration: const InputDecoration(
                              labelText: 'Sangeet academic details',
                              hintText: "e.g. MA in music"),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Field cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ]),

                      // picture
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                          ),
                          child: _profilePicUrl.isEmpty
                              ? TextButton(
                                  onPressed: _pickAndUploadImage,
                                  child: Text("Upload"))
                              : ClipRRect(
                                  child: Image.network(
                                    _profilePicUrl,
                                    fit: BoxFit.cover,
                                    width: 150,
                                    height: 150,
                                  ),
                                ),
                        ),
                      ),
                      if (_profilePicUrl.isEmpty)
                        Center(child: Text("Upload your profile picture")),

                      // sangeet exp details
                      SizedBox(height: 20),
                      if (_exp.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Sangeet sadhana details",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              ...List.generate(_exp.length, (index) {
                                return Text(
                                    "${index + 1}. ${_exp[index].category} - ${_exp[index].subcategory} - ${_exp[index].yrs} years");
                              }),
                            ],
                          ),
                        ),

                      // button for sangeet exp
                      SizedBox(height: 20),
                      TextButton(
                          onPressed: () async {
                            await _showDialogSangeetExp(context);
                          },
                          child: Text("Add sangeet sadhana details")),

                      // youtube links
                      SizedBox(height: 20),
                      if (widget.self != null && widget.self == true)
                        Column(
                          children:
                              List.generate(_youtubeLinks.length, (index) {
                            return Column(
                              children: [
                                if (index == 0 ||
                                    _youtubeLinks[index - 1].isNotEmpty)
                                  TextFormField(
                                    controller: TextEditingController()
                                      ..text = (_youtubeLinks[index].isNotEmpty)
                                          ? _youtubeLinks[index]
                                          : "",
                                    decoration: InputDecoration(
                                      labelText: index == 0
                                          ? 'Youtube link for your performance'
                                          : 'Another youtube link (optional)',
                                      hintText:
                                          "e.g. https://www.youtube.com/watch?v=123",
                                    ),
                                    onChanged: (value) {
                                      _youtubeLinks[index] = value;
                                    },
                                  ),
                                if (index < _youtubeLinks.length - 1)
                                  SizedBox(height: 10),
                              ],
                            );
                          }),
                        ),

                      // upload audio clip
                      SizedBox(height: 10),
                      if (widget.self != null && widget.self == true)
                        Text("Upload audio clip of your performance",
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(color: primaryColor)),
                      if (widget.self != null && widget.self == true)
                        Column(
                          children: List.generate(_audioClips.length, (index) {
                            return Column(
                              children: [
                                if (index == 0 ||
                                    _audioClips[index - 1].isNotEmpty)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _getFileNameFromUrl(
                                              _audioClips[index]),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          softWrap: false,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      ElevatedButton(
                                        child: Text("Browse"),
                                        onPressed: () async {
                                          FilePickerResult? result =
                                              await FilePicker.platform
                                                  .pickFiles(
                                            type: FileType.audio,
                                          );

                                          if (result == null) return;
                                          PlatformFile file =
                                              result.files.first;

                                          // upload to firestore
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          UserBasics? basics =
                                              Utils().getUserBasics();
                                          if (basics == null) {
                                            Toaster().error('User not found');
                                            return;
                                          }
                                          String ext =
                                              file.name.split('.').last;
                                          String dstPath =
                                              "${Const().dbrootSangeetSeva}/Users/${basics.mobile}/audio$index.$ext";
                                          String url = await FS().uploadBytes(
                                              dstPath: dstPath,
                                              bytes: file.bytes!);

                                          setState(() {
                                            _audioClips[index] = url;
                                            _isLoading = false;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                if (index < _audioClips.length - 1)
                                  SizedBox(height: 10),
                              ],
                            );
                          }),
                        ),

                      // leave some space at bottom
                      SizedBox(height: 100),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: widget.icon)
        ],
      ),
    );
  }
}
