import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/nitya_seva/laddu/fbl.dart';
import 'package:vkhillseva/nitya_seva/laddu/serve.dart';
import 'package:vkhillseva/nitya_seva/session.dart';

class ServiceSelect extends StatefulWidget {
  const ServiceSelect({super.key});

  @override
  _ServiceSelectDialogState createState() => _ServiceSelectDialogState();
}

class _ServiceSelectDialogState extends State<ServiceSelect> {
  List<Session> slots = [];
  List<String> services = [];
  String status = "loading";

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() async {
    slots = await FBL().readPushpanjaliSlotsByDate(DateTime.now());
    List<Session> slotsYest = await FBL()
        .readPushpanjaliSlotsByDate(DateTime.now().subtract(Duration(days: 1)));
    slots.addAll(slotsYest);

    setState(() {
      services = slots.map((e) {
        String day = DateFormat("EEE").format(e.timestamp);
        String sessionTiming =
            e.timestamp.hour < Const().morningCutoff ? "MNG" : "EVE";
        String type = e.type == "Pushpanjali" ? "PP" : "KK";
        return "$day - $type $sessionTiming ${e.name}";
      }).toList();
      status = services.isEmpty ? "empty" : "loaded";
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Service"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (status == "loading")
              CircularProgressIndicator()
            else if (status == "empty")
              Text(
                "No services found",
                style: TextStyle(
                  fontSize: 20.0, // Increase the font size
                  fontWeight: FontWeight.bold, // Make the text bold
                  color: Colors.red, // Color the text red
                ),
              )
            else
              Column(
                children: services.map((service) {
                  int index = services.indexOf(service);
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Serve(slot: slots[index])),
                      );
                    },
                    child: Text(service),
                  );
                }).toList(),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
