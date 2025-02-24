import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vkhpackages/vkhpackages.dart';

class ProfileDetails extends StatefulWidget {
  final String title;
  final String? icon;
  final UserDetails userdetails;

  const ProfileDetails(
      {super.key, required this.title, this.icon, required this.userdetails});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileDetailsState createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  // scalars

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // leave some space at top
                        SizedBox(height: 10),

                        // Name
                        Center(
                          child: Text(
                              "${widget.userdetails.salutation} ${widget.userdetails.name}",
                              style: Theme.of(context).textTheme.headlineLarge),
                        ),

                        // type
                        Center(
                          child: Text(widget.userdetails.fieldOfExpertise,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                        ),

                        // credentials
                        Center(
                          child: Text(widget.userdetails.credentials,
                              style: Theme.of(context).textTheme.headlineSmall),
                        ),

                        // sangeet sadhana
                        Center(
                          child: Text(
                              "Sangeet sadhana: ${widget.userdetails.experience}",
                              style: Theme.of(context).textTheme.headlineSmall),
                        ),

                        // mobile
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              launchUrl(Uri.parse(
                                  "tel:${widget.userdetails.mobile}"));
                            },
                            child: Text("Mobile: ${widget.userdetails.mobile}",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline)),
                          ),
                        ),

                        // photo
                        SizedBox(height: 20),
                        Center(
                          child: SizedBox(
                              width: 150,
                              child: Image.network(
                                  widget.userdetails.profilePicUrl)),
                        ),

                        // Specialization
                        SizedBox(height: 10),
                        Text("Specialization:",
                            style: Theme.of(context).textTheme.headlineSmall),
                        SizedBox(width: 10),
                        Text(
                          widget.userdetails.skills.join(', '),
                        ),

                        // youtube links
                        SizedBox(height: 10),
                        Text("Youtube links:",
                            style: Theme.of(context).textTheme.headlineSmall),
                        SizedBox(width: 10),
                        ...widget.userdetails.youtubeUrls.map((link) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5.0),
                              child: GestureDetector(
                                onTap: () {
                                  launchUrl(Uri.parse(link));
                                },
                                child: Text(link,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline)),
                              ),
                            )),

                        // Audio clips
                        SizedBox(height: 10),
                        Text("Audio clips:",
                            style: Theme.of(context).textTheme.headlineSmall),
                        SizedBox(width: 10),
                        ...widget.userdetails.audioClipUrls
                            .map((link) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      launchUrl(Uri.parse(link));
                                    },
                                    child: Text(
                                        Uri.parse(link)
                                            .pathSegments
                                            .last
                                            .split('/')
                                            .last,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                                color: Colors.blue,
                                                decoration:
                                                    TextDecoration.underline)),
                                  ),
                                )),

                        // leave some space at bottom
                        SizedBox(height: 100),
                      ]))),
        ),
      ],
    );
  }
}
