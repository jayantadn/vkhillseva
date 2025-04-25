import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/registration.dart';
import 'package:vkhsangeetseva/registration_page2.dart';
import 'package:vkhsangeetseva/widgets/next_avl_slot.dart';

class SlotSelection extends StatefulWidget {
  final String title;

  const SlotSelection({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _SlotSelectionState createState() => _SlotSelectionState();
}

class _SlotSelectionState extends State<SlotSelection> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  final GlobalKey<NextAvlSlotState> _nextavlslotKey =
      GlobalKey<NextAvlSlotState>();

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    // perform async operations here

    await _lock.synchronized(() async {
      // fetch form values

      // refresh all child widgets

      // perform sync operations here
    });

    setState(() {
      _isLoading = false;
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

                      Widgets().createResponsiveTopLevelContainer(context, [
                        // your widgets here
                        Widgets().createTopLevelCard(
                            context,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Next available slot:"),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    NextAvlSlot(key: _nextavlslotKey),
                                    const SizedBox(width: 10),
                                    IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  Registration(
                                                title: "Event Registration",
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.calendar_month))
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                      onPressed: () async {
                                        DateTime? date = _nextavlslotKey
                                            .currentState!.nextAvailableDate;
                                        Slot? slot = _nextavlslotKey
                                            .currentState!.nextAvailableSlot;

                                        if (date == null || slot == null) {
                                          Toaster().error("invalid slot");
                                          return;
                                        }

                                        // check if the slot is already booked
                                        List requestsRaw = await FB().getList(
                                            path:
                                                "${Const().dbrootSangeetSeva}/PendingRequests");
                                        for (var requestRaw in requestsRaw) {
                                          Map<String, dynamic> requestMap =
                                              Map<String, dynamic>.from(
                                                  requestRaw);
                                          String mobile = requestMap['path']
                                              .split('/')
                                              .last;
                                          UserBasics? basics =
                                              Utils().getUserBasics();
                                          if (basics != null &&
                                              mobile == basics.mobile) {
                                            String dbpath = requestMap['path'];
                                            List events = await FB()
                                                .getList(path: dbpath);
                                            int index = requestMap['index'];
                                            EventRecord event = Utils()
                                                .convertRawToDatatype(
                                                    events[index],
                                                    EventRecord.fromJson);
                                            if (event.date == date &&
                                                event.slot.from == slot.from &&
                                                event.slot.to == slot.to) {
                                              Toaster().error(
                                                  "You already requested this slot");
                                              return;
                                            }
                                          }
                                        }

                                        // check if slot is in the past
                                        DateTime now = DateTime.now();
                                        List<int> hrMin = Utils()
                                            .convertTimeToHrMin(slot.from);
                                        DateTime slotDateTime = DateTime(
                                          date.year,
                                          date.month,
                                          date.day,
                                          hrMin[0],
                                          hrMin[1],
                                        );
                                        if (slotDateTime.isBefore(now)) {
                                          Toaster().error(
                                              "Cannot book slot in the past");
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RegistrationPage2(
                                              title: widget.title,
                                              selectedDate: date,
                                              slot: slot,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text("Select slot")),
                                ),
                              ],
                            )),
                      ]),

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
            image: "assets/images/Logo/SangeetSeva.png",
          ),
      ],
    );
  }
}
