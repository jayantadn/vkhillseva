import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/common/const.dart';
import 'package:vkhpackages/common/datatypes.dart';
import 'package:vkhpackages/common/fb.dart';
import 'package:vkhpackages/common/utils.dart';
import 'package:vkhpackages/vkhpackages.dart';

class NextAvlSlot extends StatefulWidget {
  const NextAvlSlot({super.key});

  @override
  State<NextAvlSlot> createState() => NextAvlSlotState();
}

class NextAvlSlotState extends State<NextAvlSlot> {
  final Lock _lock = Lock();
  bool _isLoading = false;
  DateTime? _nextAvailableDate;
  Slot? _nextAvailableSlot;

  // getter methods
  DateTime? get nextAvailableDate => _nextAvailableDate;
  Slot? get nextAvailableSlot => _nextAvailableSlot;

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // dispose all controllers

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async work here
    await _fetchNextAvailableSlot();

    await _lock.synchronized(() async {
      // perform sync work here
      setState(() {});
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _isSlotAvailable(DateTime date, Slot slot) async {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    String dbpath = "${Const().dbrootSangeetSeva}/Slots/$dateStr";

    bool exists = await FB().pathExists(dbpath);
    if (exists) {
      var slotsRaw = await FB().getValue(path: dbpath);
      Map<String, dynamic> slots = Map<String, dynamic>.from(slotsRaw);

      for (var slotRaw in slots.entries) {
        Slot slotObj =
            Utils().convertRawToDatatype(slotRaw.value, Slot.fromJson);
        if (slotObj.from == slot.from && slotObj.to == slot.to) {
          return slotObj.avl;
        }
      }
      // slot not found, means it is available
      return true;
    } else {
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        return true;
      }
    }

    return false;
  }

  Future<void> _fetchNextAvailableSlot() async {
    // set the starting search date and the next weekend date
    if (_nextAvailableDate == null) {
      DateTime today = DateTime.now();
      today = DateTime(today.year, today.month, today.day);
      _nextAvailableDate = today.add(Duration(days: 1));
      _nextAvailableSlot = null;
    } else {
      List<Slot> slots = [];

      // check if any more slots available for the current date
      // if yes, retain the date
      String dbdate = DateFormat('yyyy-MM-dd').format(_nextAvailableDate!);
      var slotsRaw = await FB()
          .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dbdate");
      if (slotsRaw != null) {
        Map<String, dynamic> slotsRawMap = Map<String, dynamic>.from(slotsRaw);
        for (var entry in slotsRawMap.entries) {
          Slot slot = Utils().convertRawToDatatype(entry.value, Slot.fromJson);
          slots.add(slot);
        }
      }

      // is the available date a weekend date?
      // if yes, check if any slots available after this
      if (_nextAvailableDate!.weekday == DateTime.saturday ||
          _nextAvailableDate!.weekday == DateTime.sunday) {
        for (var slotw in SSConst().weekendSangeetSevaSlots) {
          bool found = false;
          for (var slot in slots) {
            if (slotw.from == slot.from && slotw.to == slot.to) {
              found = true;
              break;
            }
          }

          if (!found) {
            slots.add(slotw);
          }
        }
      }

      // filter for available slots
      slots = slots.where((slot) => slot.avl == true).toList();

      // sort the slots by time
      slots.sort((a, b) {
        DateTime timeA = Utils().convertStringToTime(
            _nextAvailableDate!, a.from); // Convert to DateTime
        DateTime timeB = Utils().convertStringToTime(
            _nextAvailableDate!, b.from); // Convert to DateTime
        return timeA.compareTo(timeB); // Compare the times
      });

      // set the starting search date
      if (_nextAvailableSlot == null) {
        if (slots.isEmpty) {
          _nextAvailableDate = _nextAvailableDate!.add(Duration(days: 1));
          _nextAvailableSlot = null;
        } else {
          _nextAvailableSlot = slots[0];
          return;
        }
      } else {
        if (slots.isEmpty) {
          _nextAvailableDate = _nextAvailableDate!.add(Duration(days: 1));
          _nextAvailableSlot = null;
        } else {
          for (Slot slot in slots) {
            DateTime currentSlot = Utils().convertStringToTime(
                _nextAvailableDate!, _nextAvailableSlot!.from);
            DateTime newSlot =
                Utils().convertStringToTime(_nextAvailableDate!, slot.from);

            if (newSlot.isAfter(currentSlot)) {
              _nextAvailableSlot = slot;
              return;
            }
          }

          // no available slots found, so move to the next date
          _nextAvailableDate = _nextAvailableDate!.add(Duration(days: 1));
          _nextAvailableSlot = null;
        }
      }
    }

    // weekend date after the next available date
    DateTime nextWeekendDate = DateTime(
      _nextAvailableDate!.year,
      _nextAvailableDate!.month,
      _nextAvailableDate!.day,
    );
    while (nextWeekendDate.weekday != DateTime.saturday &&
        nextWeekendDate.weekday != DateTime.sunday) {
      nextWeekendDate = nextWeekendDate.add(Duration(days: 1));
    }

    // fetch all the created slots
    Map<String, dynamic> kvs = await FB().getValuesByDateRange(
        path: "${Const().dbrootSangeetSeva}/Slots",
        startDate: _nextAvailableDate!);
    List<String> slotDates = kvs.keys.toList();

    // find the next available slots from the created slots
    bool found = false;
    for (String dateStr in slotDates) {
      DateTime date = DateFormat('yyyy-MM-dd').parse(dateStr);
      if (date.isAfter(_nextAvailableDate!)) {
        var slotsRaw = await FB()
            .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dateStr");
        Map<String, dynamic> slots = Map<String, dynamic>.from(slotsRaw);

        for (var entry in slots.entries) {
          Slot slot = Utils().convertRawToDatatype(entry.value, Slot.fromJson);

          if (_nextAvailableSlot == null && slot.avl == true) {
            _nextAvailableDate = date;
            _nextAvailableSlot = slot;
            found = true;
            break;
          } else if (_nextAvailableSlot != null) {
            if (slot.avl == true) {
              if (Utils().convertStringToTime(date, slot.from).isAfter(Utils()
                  .convertStringToTime(
                      _nextAvailableDate!, _nextAvailableSlot!.from))) {
                _nextAvailableDate = date;
                _nextAvailableSlot = slot;
                found = true;
                break;
              }
            }
          }
        }
      } else {
        // date is same as the current date
        var slotsRaw = await FB()
            .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dateStr");
        Map<String, dynamic> slots = Map<String, dynamic>.from(slotsRaw);
        for (var entry in slots.entries) {
          Slot slot = Utils().convertRawToDatatype(entry.value, Slot.fromJson);
          if (_nextAvailableSlot == null && slot.avl == true) {
            _nextAvailableDate = date;
            _nextAvailableSlot = slot;
            found = true;
            break;
          } else if (_nextAvailableSlot != null) {
            if (slot.avl == true) {
              if (Utils().convertStringToTime(date, slot.from).isAfter(Utils()
                  .convertStringToTime(
                      _nextAvailableDate!, _nextAvailableSlot!.from))) {
                _nextAvailableDate = date;
                _nextAvailableSlot = slot;
                found = true;
                break;
              }
            }
          }
        }
      }
      if (found) {
        break;
      }
    }

    // arbitrate against the weekend slots
    bool foundWeekend = false;
    for (int i = 0; i < 10; i++) {
      List<Slot> weekendSlots = SSConst().weekendSangeetSevaSlots;
      weekendSlots.sort((a, b) {
        DateTime timeA =
            Utils().convertStringToTime(_nextAvailableDate!, a.from);
        DateTime timeB =
            Utils().convertStringToTime(_nextAvailableDate!, b.from);
        return timeA.compareTo(timeB); // forward sort
      });
      for (var slotw in weekendSlots) {
        bool avl = await _isSlotAvailable(nextWeekendDate, slotw);
        if (avl) {
          if (_nextAvailableSlot == null) {
            _nextAvailableDate = nextWeekendDate;
            _nextAvailableSlot = slotw;
            foundWeekend = true;
            break;
          } else if (_nextAvailableDate!.isAfter(nextWeekendDate)) {
            _nextAvailableDate = nextWeekendDate;
            _nextAvailableSlot = slotw;
            foundWeekend = true;
            break;
          } else {
            DateTime nextslot = Utils().convertStringToTime(
                _nextAvailableDate!, _nextAvailableSlot!.from);
            DateTime nextweekendslot =
                Utils().convertStringToTime(nextWeekendDate, slotw.from);
            if (nextslot.isAfter(nextweekendslot)) {
              _nextAvailableDate = nextWeekendDate;
              _nextAvailableSlot = slotw;
              foundWeekend = true;
              break;
            }
          }
        }
      }

      if (foundWeekend) {
        break;
      }
      // go to next weekend
      do {
        nextWeekendDate = nextWeekendDate.add(Duration(days: 1));
      } while (nextWeekendDate.weekday != DateTime.saturday &&
          nextWeekendDate.weekday != DateTime.sunday);
    }

    // if no slot is found, set the next available date to null
    if (_nextAvailableSlot == null) {
      _nextAvailableDate = null;
      _nextAvailableSlot = null;
    }
  }

  Future<void> _fetchPreviousAvailableSlot() async {
    if (_nextAvailableDate == null) {
      DateTime today = DateTime.now();
      today = DateTime(today.year, today.month, today.day);
      _nextAvailableDate = today.subtract(Duration(days: 1));
      _nextAvailableSlot = null;
    } else {
      List<Slot> slots = [];

      // check if any created slots are available for the current date
      String dbdate = DateFormat('yyyy-MM-dd').format(_nextAvailableDate!);
      var slotsRaw = await FB()
          .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dbdate");
      if (slotsRaw != null) {
        Map<String, dynamic> slotsRawMap = Map<String, dynamic>.from(slotsRaw);
        for (var entry in slotsRawMap.entries) {
          Slot slot = Utils().convertRawToDatatype(entry.value, Slot.fromJson);
          slots.add(slot);
        }
      }

      // is the available date a weekend date?
      if (_nextAvailableDate!.weekday == DateTime.saturday ||
          _nextAvailableDate!.weekday == DateTime.sunday) {
        for (var slotw in SSConst().weekendSangeetSevaSlots) {
          bool found = false;
          for (var slot in slots) {
            if (slotw.from == slot.from && slotw.to == slot.to) {
              found = true;
              break;
            }
          }
          if (!found) {
            slots.add(slotw);
          }
        }
      }

      // filter for available slots
      slots = slots.where((slot) => slot.avl == true).toList();

      // sort the slots by time in descending order
      slots.sort((a, b) {
        DateTime timeA = Utils().convertStringToTime(
            _nextAvailableDate!, a.from); // Convert to DateTime
        DateTime timeB = Utils().convertStringToTime(
            _nextAvailableDate!, b.from); // Convert to DateTime
        return timeB.compareTo(timeA); // Compare the times
      });

      // set the starting search date
      if (_nextAvailableSlot == null) {
        if (slots.isEmpty) {
          _nextAvailableDate = _nextAvailableDate!.subtract(Duration(days: 1));
          _nextAvailableSlot = null;
        } else {
          _nextAvailableSlot = slots[0];
          return;
        }
      } else {
        if (slots.isEmpty) {
          _nextAvailableDate = _nextAvailableDate!.subtract(Duration(days: 1));
          _nextAvailableSlot = null;
        } else {
          for (Slot slot in slots) {
            DateTime currentSlot = Utils().convertStringToTime(
                _nextAvailableDate!, _nextAvailableSlot!.from);
            DateTime newSlot =
                Utils().convertStringToTime(_nextAvailableDate!, slot.from);

            if (newSlot.isBefore(currentSlot)) {
              _nextAvailableSlot = slot;
              return;
            }
          }

          // no available slots found, so move to the previous date
          _nextAvailableDate = _nextAvailableDate!.subtract(Duration(days: 1));
          _nextAvailableSlot = null;
        }
      }
    }

    // if _nextAvailableDate is on or before today
    if (_nextAvailableDate!.isBefore(DateTime.now())) {
      _nextAvailableDate = null;
      _nextAvailableSlot = null;
      return;
    }

    // fetch all the created slots in reverse order
    Map<String, dynamic> kvs = await FB().getValuesByDateRange(
      path: "${Const().dbrootSangeetSeva}/Slots",
      startDate: _nextAvailableDate!,
    );
    List<String> slotDates = kvs.keys.toList();
    slotDates.sort((a, b) {
      DateTime dateA = DateFormat('yyyy-MM-dd').parse(a);
      DateTime dateB = DateFormat('yyyy-MM-dd').parse(b);
      return dateB.compareTo(dateA); // Reverse sort
    });

    // find the previous available slots from the created slots
    bool found = false;
    for (String dateStr in slotDates) {
      DateTime date = DateFormat('yyyy-MM-dd').parse(dateStr);
      if (date.isBefore(_nextAvailableDate!)) {
        var slotsRaw = await FB()
            .getValue(path: "${Const().dbrootSangeetSeva}/Slots/$dateStr");
        Map<String, dynamic> slots = Map<String, dynamic>.from(slotsRaw);

        for (var entry in slots.entries) {
          Slot slot = Utils().convertRawToDatatype(entry.value, Slot.fromJson);

          if (_nextAvailableSlot == null && slot.avl == true) {
            _nextAvailableDate = date;
            _nextAvailableSlot = slot;
            found = true;
            break;
          } else if (_nextAvailableSlot != null) {
            if (slot.avl == true) {
              if (Utils().convertStringToTime(date, slot.from).isBefore(Utils()
                  .convertStringToTime(
                      _nextAvailableDate!, _nextAvailableSlot!.from))) {
                _nextAvailableDate = date;
                _nextAvailableSlot = slot;
                found = true;
                break;
              }
            }
          }
        }
      }
      if (found) {
        break;
      }
    }

    // arbitrate against the weekend slots
    bool foundWeekend = false;
    for (int i = 0; i < 10; i++) {
      List<Slot> weekendSlots = SSConst().weekendSangeetSevaSlots;
      weekendSlots.sort((a, b) {
        DateTime timeA =
            Utils().convertStringToTime(_nextAvailableDate!, a.from);
        DateTime timeB =
            Utils().convertStringToTime(_nextAvailableDate!, b.from);
        return timeB.compareTo(timeA); // Reverse sort
      });
      for (var slot in SSConst().weekendSangeetSevaSlots) {
        bool avl = await _isSlotAvailable(_nextAvailableDate!, slot);
        if (avl) {
          if (_nextAvailableSlot == null) {
            _nextAvailableDate = _nextAvailableDate;
            _nextAvailableSlot = slot;
            foundWeekend = true;
            break;
          } else if (_nextAvailableDate!.isBefore(_nextAvailableDate!)) {
            _nextAvailableDate = _nextAvailableDate;
            _nextAvailableSlot = slot;
            foundWeekend = true;
            break;
          } else {
            DateTime nextslot = Utils().convertStringToTime(
                _nextAvailableDate!, _nextAvailableSlot!.from);
            DateTime nextweekendslot =
                Utils().convertStringToTime(_nextAvailableDate!, slot.from);
            if (nextslot.isBefore(nextweekendslot)) {
              _nextAvailableDate = _nextAvailableDate;
              _nextAvailableSlot = slot;
              foundWeekend = true;
              break;
            }
          }
        }
      }

      if (foundWeekend) {
        break;
      }
      // go to previous weekend
      do {
        _nextAvailableDate = _nextAvailableDate!.subtract(Duration(days: 1));
        if (!_nextAvailableDate!.isAfter(DateTime.now())) {
          // if we have reached today, break the loop
          _nextAvailableDate = null;
          _nextAvailableSlot = null;
          return;
        }
      } while (_nextAvailableDate!.weekday != DateTime.saturday &&
          _nextAvailableDate!.weekday != DateTime.sunday);
    }

    // if no slot is found, set the next available date to null
    if (_nextAvailableSlot == null) {
      _nextAvailableDate = null;
      _nextAvailableSlot = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // previous available slot
        IconButton(
          icon: Transform.rotate(
            angle: 3.14, // Rotate 180 degrees to point left
            child: Icon(
              Icons.play_arrow,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _fetchPreviousAvailableSlot();
                  setState(() {
                    _isLoading = false;
                  });
                },
        ),

        // slot details
        if (!_isLoading)
          Column(
            children: [
              Text(
                _nextAvailableDate != null
                    ? DateFormat('dd MMM yyyy').format(_nextAvailableDate!)
                    : "No slots...",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_nextAvailableSlot != null
                  ? "${_nextAvailableSlot!.from} - ${_nextAvailableSlot!.to}"
                  : "00:00 AM - 00:00 PM"),
            ],
          ),

        // loading screen
        if (_isLoading)
          Column(
            children: [
              Text(
                'Loading....',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("00:00 AM - 00:00 PM"),
            ],
          ),

        // next available slot
        IconButton(
          icon: Transform.rotate(
            angle: 0, // Rotate 0 degrees to point right
            child: Icon(
              Icons.play_arrow,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _fetchNextAvailableSlot();
                  setState(() {
                    _isLoading = false;
                  });
                },
        ),
      ],
    );
  }
}
