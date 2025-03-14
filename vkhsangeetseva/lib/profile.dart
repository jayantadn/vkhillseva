import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vkhsangeetseva/widgets/radio_row.dart';
import 'package:file_picker/file_picker.dart';

class Profile extends StatefulWidget {
  final String title;
  final String? icon;
  final bool? self;
  final Function(UserDetails user)? onProfileSaved;

  const Profile(
      {super.key,
      required this.title,
      this.icon,
      this.self,
      this.onProfileSaved});

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
  String _selectedExpertiseType = "Vocalist";
  UserDetails? _userDetailsOld;
  bool _backEnabled = false;

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
  List<String> _selectedVocalSkills = [];

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
  List<String> _selectedInstrumentalSkills = [];

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
    _selectedInstrumentalSkills.clear();
    _vocalSkills.clear();
    _selectedVocalSkills.clear();
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
      String mobile = Utils().getUserBasics()!.mobile;
      bool exists =
          await FB().pathExists("${Const().dbrootSangeetSeva}/Users/$mobile");
      if (exists) {
        Map<String, dynamic> userdetailsJson = await FB()
            .getJson(path: "${Const().dbrootSangeetSeva}/Users/$mobile");
        _userDetailsOld = UserDetails.fromJson(userdetailsJson);
      }
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
        _experienceController.text = _userDetailsOld!.experience;
        _selectedExpertiseType = _userDetailsOld!.fieldOfExpertise;
        _selectedVocalSkills = _userDetailsOld!.skills
            .where((skill) => _vocalSkills.contains(skill))
            .toList();
        _selectedInstrumentalSkills = _userDetailsOld!.skills
            .where((skill) => _instrumentSkills.contains(skill))
            .toList();
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

  Future<void> _save({UserDetails? userdetails}) async {
    // validation of form
    if (!_formKey.currentState!.validate()) {
      Toaster().error('There are errors in the form');
      return;
    }

    // validation of skill set
    if (_selectedExpertiseType == "Vocalist" && _selectedVocalSkills.isEmpty) {
      Toaster().error('Please select at least one vocal skill');
      return;
    }
    if (_selectedExpertiseType == "Instrumentalist" &&
        _selectedInstrumentalSkills.isEmpty) {
      Toaster().error('Please select at least one instrumental skill');
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

    // no abrupt returns before this point
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
    if (userdetails == null) {
      details = UserDetails(
        salutation: _salutation,
        name: _nameController.text,
        mobile: _mobileController.text,
        profilePicUrl: _profilePicUrl,
        credentials: _credController.text,
        experience: _experienceController.text,
        fieldOfExpertise: _selectedExpertiseType,
        skills: _selectedExpertiseType == "Vocalist"
            ? _selectedVocalSkills
            : _selectedInstrumentalSkills,
        youtubeUrls: _youtubeLinks.where((link) => link.isNotEmpty).toList(),
        audioClipUrls: _audioClips.where((link) => link.isNotEmpty).toList(),
      );
    } else {
      details = userdetails;
    }

    // set the FCM token
    String? fcmToken = await setupFirebaseMessaging();
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // FIXME: too many issues with intercepting back action
        // _onBack(context);
      },
      child: Theme(
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
                      await _save();
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
                                items: _salutations
                                    .map<DropdownMenuItem<String>>(
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

                        // Sangeet credentials
                        SizedBox(height: 20),
                        Utils().responsiveBuilder(context, [
                          TextFormField(
                            controller: _credController,
                            decoration: const InputDecoration(
                                labelText: 'Academic details for sangeet',
                                hintText: "e.g. MA in music"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Field cannot be empty';
                              }
                              return null;
                            },
                          ),

                          // years of sangeet sadhana
                          TextFormField(
                            controller: _experienceController,
                            decoration: const InputDecoration(
                                labelText: 'Years of sangeet sadhana',
                                hintText: "e.g. 10 years"),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Field cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ]),

                        // field of expertise toggle
                        SizedBox(height: 10),
                        RadioRow(
                            items: ["Vocalist", "Instrumentalist"],
                            onChanged: (String value) {
                              setState(() {
                                _selectedExpertiseType = value;
                              });
                            }),

                        // toggle vocal/instrumental skills
                        SizedBox(height: 20),
                        if (_selectedExpertiseType == "Vocalist")
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Sangeet skills',
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12.0),
                              border: OutlineInputBorder(),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 20.0, bottom: 10),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 5,
                                children: _vocalSkills
                                    .map((String expertise) => FilterChip(
                                          label: Text(expertise),
                                          selected: _selectedVocalSkills
                                              .contains(expertise),
                                          onSelected: (bool selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedVocalSkills
                                                    .add(expertise);
                                              } else {
                                                _selectedVocalSkills
                                                    .remove(expertise);
                                              }
                                            });
                                          },
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        if (_selectedExpertiseType == "Instrumentalist")
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Sangeet skills',
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12.0),
                              border: OutlineInputBorder(),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 20.0, bottom: 10),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 5,
                                children: _instrumentSkills
                                    .map((String expertise) => FilterChip(
                                          label: Text(expertise),
                                          selected: _selectedInstrumentalSkills
                                              .contains(expertise),
                                          onSelected: (bool selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedInstrumentalSkills
                                                    .add(expertise);
                                              } else {
                                                _selectedInstrumentalSkills
                                                    .remove(expertise);
                                              }
                                            });
                                          },
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),

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
                                        ..text =
                                            (_youtubeLinks[index].isNotEmpty)
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
                            children:
                                List.generate(_audioClips.length, (index) {
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
      ),
    );
  }
}
