import 'package:flutter/material.dart';
import 'package:vkhgaruda/nitya_seva/settings/festival_settings_page.dart';
import 'package:vkhgaruda/nitya_seva/settings/ticket_settings.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Settings extends StatefulWidget {
  final String title;

  const Settings({super.key, required this.title});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _isLoading = true;

  @override
  initState() {
    super.initState();

    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = false;
    });
  }

  Widget _createSettingsCard(
      {required String title,
      required IconData icon,
      required SettingsCallback callback}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: InkWell(
          onTap: () {
            callback.onClick();
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ListTile(
              title: Text(title,
                  style: Theme.of(context).textTheme.headlineMedium),
              leading: ClipRRect(
                borderRadius:
                    BorderRadius.circular(8.0), // Adjust the radius as needed
                child: Container(
                  color: Theme.of(context)
                      .primaryColor, // Background color for the icon
                  padding: const EdgeInsets.all(
                      8.0), // Optional: add padding for better appearance
                  child: Icon(
                    icon,
                    color: Colors.white, // Icon color as white
                  ),
                ),
              ),
            ),
          ),
        ),
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
              child: ListView(
                children: [
                  // Nitya Seva Festival settings
                  _createSettingsCard(
                    title: 'Festival settings',
                    icon: Icons.volunteer_activism,
                    callback: SettingsCallback(onClick: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FestivalSettingsPage(
                                title: "Festival settings")),
                      );
                    }),
                  ),

                  // Nitya Seva Ticket settings
                  _createSettingsCard(
                    title: 'Ticket settings',
                    icon:
                        Icons.confirmation_number, // Suggested icon for tickets
                    callback: SettingsCallback(onClick: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const TicketSettings(title: "Ticket settings")),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // circular progress indicator
          if (_isLoading)
            LoadingOverlay(
                image: 'assets/images/Logo/KrishnaLilaPark_square.png')
        ],
      ),
    );
  }
}

class SettingsCallback {
  final Function onClick;

  SettingsCallback({required this.onClick});
}
