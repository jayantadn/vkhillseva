import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';

class Summary extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Summary({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _SummaryState createState() => _SummaryState();
}

class _SummaryState extends State<Summary> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  String _period = "daily";
  String _periodDetails = DateFormat("dd MMM, yyyy").format(DateTime.now());

  // variables for chanters summary
  int _totalChanters = 0;
  int _newChanterMalasProcured = 0;
  int _discardedChanterMalas = 0;

  // variables for sales summary
  int _totalMalasSold = 0;
  int _totalAmountCollected = 0;
  int _newSaleMalasProcured = 0;
  int _discardedSaleMalas = 0;

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control
    bool allowed = await Utils().checkPermission("Harinaam Mantapa");
    if (!allowed) {
      Toaster().error("Access denied");
      if (mounted) {
        Navigator.of(context).pop();
      }
    }

    await _lock.synchronized(() async {
      // your code here
      switch (_period) {
        case "daily":
          DateTime date = DateFormat("dd MMM, yyyy").parse(_periodDetails);
          String dbdate = DateFormat("yyyy-MM-dd").format(date);

          // collect morning chaters data
          _totalChanters = 0;
          String dbpath =
              "${Const().dbrootGaruda}/Harinaam/$dbdate/Morning/Chanters";
          Map<String, dynamic> data =
              await FB().getJson(path: dbpath, silent: true);
          for (var entry in data.entries) {
            ChantersEntry chanter = Utils()
                .convertRawToDatatype(entry.value, ChantersEntry.fromJson);
            _totalChanters += chanter.count;
          }

          // collect evening chaters data
          dbpath = "${Const().dbrootGaruda}/Harinaam/$dbdate/Evening/Chanters";
          data = await FB().getJson(path: dbpath, silent: true);
          for (var entry in data.entries) {
            ChantersEntry chanter = Utils()
                .convertRawToDatatype(entry.value, ChantersEntry.fromJson);
            _totalChanters += chanter.count;
          }

          // chanters inventory data
          _newChanterMalasProcured = 0;
          _discardedChanterMalas = 0;
          _newSaleMalasProcured = 0;
          _discardedSaleMalas = 0;
          dbpath = "${Const().dbrootGaruda}/HarinaamInventory/$dbdate";
          List listRaw = await FB().getList(path: dbpath);
          for (var item in listRaw) {
            InventoryEntry entry =
                Utils().convertRawToDatatype(item, InventoryEntry.fromJson);
            if (entry.malaType == "Chanters") {
              if (entry.addOrRemove == "Add") {
                _newChanterMalasProcured += entry.count;
              } else if (entry.addOrRemove == "Discard") {
                _discardedChanterMalas += entry.count;
              }
            } else if (entry.malaType == "Sales") {
              if (entry.addOrRemove == "Add") {
                _newSaleMalasProcured += entry.count;
              } else if (entry.addOrRemove == "Discard") {
                _discardedSaleMalas += entry.count;
              }
            }
          }

          // number of malas sold
          _totalMalasSold = 0;
          _totalAmountCollected = 0;
          dbpath = "${Const().dbrootGaruda}/Harinaam/$dbdate/Morning/Sales";
          data = await FB().getJson(path: dbpath, silent: true);
          for (var entry in data.entries) {
            SalesEntry sale =
                Utils().convertRawToDatatype(entry.value, SalesEntry.fromJson);
            _totalMalasSold += sale.count;
            _totalAmountCollected += (sale.japamala.saleValue * sale.count);
          }
          dbpath = "${Const().dbrootGaruda}/Harinaam/$dbdate/Evening/Sales";
          data = await FB().getJson(path: dbpath, silent: true);
          for (var entry in data.entries) {
            SalesEntry sale =
                Utils().convertRawToDatatype(entry.value, SalesEntry.fromJson);
            _totalMalasSold += sale.count;
            _totalAmountCollected += (sale.japamala.saleValue * sale.count);
          }
          break;

        case "weekly":
          DateTime startDate = DateFormat("dd MMM, yyyy")
              .parse(_periodDetails.split('-')[0].trim());
          DateTime endDate = DateFormat("dd MMM, yyyy")
              .parse(_periodDetails.split('-')[1].trim());

          // number of chanters and sales
          String dbpath = "${Const().dbrootGaruda}/Harinaam";
          var dataRaw = await FB().getValuesByDateRange(
              path: dbpath, startDate: startDate, endDate: endDate);
          CountTuple countData = _getChantersAndSalesCount(dataRaw);
          _totalChanters = countData.chantersCount;
          _totalMalasSold = countData.salesCount;
          _totalAmountCollected = countData.salesAmount;

          // chanters inventory data
          _newChanterMalasProcured = 0;
          _discardedChanterMalas = 0;
          dbpath = "${Const().dbrootGaruda}/HarinaamInventory";
          dataRaw = await FB().getValuesByDateRange(
              path: dbpath, startDate: startDate, endDate: endDate);
          InventoryTuple inventoryData =
              _getChantersAndSalesInventory(dataRaw as Map);
          _newChanterMalasProcured = inventoryData.addedChantersMalas;
          _discardedChanterMalas = inventoryData.discardedChantersMalas;
          _newSaleMalasProcured = inventoryData.addedSalesMalas;
          _discardedSaleMalas = inventoryData.discardedSalesMalas;

          break;

        case "monthly":
          DateTime month = DateFormat("MMM yyyy").parse(_periodDetails);
          DateTime startDate = DateTime(month.year, month.month, 1);
          DateTime endDate = DateTime(month.year, month.month + 1, 0);

          // number of chanters and sales
          String dbpath = "${Const().dbrootGaruda}/Harinaam";
          var dataRaw = await FB().getValuesByDateRange(
              path: dbpath, startDate: startDate, endDate: endDate);
          CountTuple countData = _getChantersAndSalesCount(dataRaw);
          _totalChanters = countData.chantersCount;
          _totalMalasSold = countData.salesCount;
          _totalAmountCollected = countData.salesAmount;

          // chanters inventory data
          dbpath = "${Const().dbrootGaruda}/HarinaamInventory";
          dataRaw = await FB().getValuesByDateRange(
              path: dbpath, startDate: startDate, endDate: endDate);
          InventoryTuple inventoryData =
              _getChantersAndSalesInventory(dataRaw as Map);
          _newChanterMalasProcured = inventoryData.addedChantersMalas;
          _discardedChanterMalas = inventoryData.discardedChantersMalas;
          _newSaleMalasProcured = inventoryData.addedSalesMalas;
          _discardedSaleMalas = inventoryData.discardedSalesMalas;

          break;

        case "yearly":
          DateTime year = DateFormat("yyyy").parse(_periodDetails);
          DateTime startDate = DateTime(year.year, 1, 1);
          DateTime endDate = DateTime(year.year, 12, 31);

          // number of chanters and sales
          String dbpath = "${Const().dbrootGaruda}/Harinaam";
          var dataRaw = await FB().getValuesByDateRange(
              path: dbpath, startDate: startDate, endDate: endDate);
          CountTuple countData = _getChantersAndSalesCount(dataRaw);
          _totalChanters = countData.chantersCount;
          _totalMalasSold = countData.salesCount;
          _totalAmountCollected = countData.salesAmount;

          // chanters inventory data
          dbpath = "${Const().dbrootGaruda}/HarinaamInventory";
          dataRaw = await FB().getValuesByDateRange(
              path: dbpath, startDate: startDate, endDate: endDate);
          InventoryTuple inventoryData =
              _getChantersAndSalesInventory(dataRaw as Map);
          _newChanterMalasProcured = inventoryData.addedChantersMalas;
          _discardedChanterMalas = inventoryData.discardedChantersMalas;
          _newSaleMalasProcured = inventoryData.addedSalesMalas;
          _discardedSaleMalas = inventoryData.discardedSalesMalas;

          break;
      }
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createChantersSummary() {
    return Widgets().createTopLevelCard(
        context: context,
        title: "Chanters' Summary",
        color: Colors.brown,
        child: Column(
          children: [
            _createTableEntry("Total Chanters", "$_totalChanters"),
            _createTableEntry(
                "New malas procured", "$_newChanterMalasProcured"),
            _createTableEntry("Discarded malas", "$_discardedChanterMalas",
                divider: false),
          ],
        ));
  }

  Widget _createSalesSummary() {
    return Widgets().createTopLevelCard(
        context: context,
        title: "Japamala Sales",
        child: Column(
          children: [
            _createTableEntry("Total malas sold", "$_totalMalasSold"),
            _createTableEntry(
                "Total amount collected", "₹$_totalAmountCollected"),
            _createTableEntry("New malas procured", "$_newSaleMalasProcured"),
            _createTableEntry("Discarded malas", "$_discardedSaleMalas",
                divider: false),
          ],
        ));
  }

  Widget _createHMI() {
    return Widgets().createTopLevelCard(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(12.0), // Reduced from 16
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Period selector row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button with animation (more compact)
                Container(
                  width: 40, // Fixed width
                  height: 40, // Fixed height
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withOpacity(0.9), // Dark background
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero, // Remove default padding
                    icon: AnimatedRotation(
                      turns: 0.5,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white, // White icon
                        size: 18, // Slightly smaller
                      ),
                    ),
                    onPressed: _prev,
                  ),
                ),

                // Dropdown with enhanced styling (more compact)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 0), // Minimal vertical padding
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: DropdownButton<String>(
                    value: _period,
                    underline: Container(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).primaryColor,
                      size: 20, // Slightly smaller
                    ),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14, // Reduced font size
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "daily",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today, size: 16), // Smaller icons
                            SizedBox(width: 6), // Reduced spacing
                            Text("Daily"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "weekly",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_week, size: 16),
                            SizedBox(width: 6),
                            Text("Weekly"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "monthly",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month, size: 16),
                            SizedBox(width: 6),
                            Text("Monthly"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "yearly",
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 16),
                            SizedBox(width: 6),
                            Text("Yearly"),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      _period = newValue ?? _period;

                      // Update period details based on selection
                      switch (_period) {
                        case "daily":
                          _periodDetails =
                              DateFormat("dd MMM, yyyy").format(DateTime.now());
                          break;
                        case "weekly":
                          DateTime now = DateTime.now();
                          DateTime startOfWeek =
                              now.subtract(Duration(days: now.weekday - 1));
                          DateTime endOfWeek =
                              startOfWeek.add(Duration(days: 6));
                          _periodDetails =
                              "${DateFormat("dd MMM, yyyy").format(startOfWeek)} - ${DateFormat("dd MMM, yyyy").format(endOfWeek)}";
                          break;
                        case "monthly":
                          DateTime now = DateTime.now();
                          _periodDetails = DateFormat("MMM yyyy").format(now);
                          break;
                        case "yearly":
                          DateTime now = DateTime.now();
                          _periodDetails = DateFormat("yyyy").format(now);
                          break;
                      }

                      refresh();
                    },
                  ),
                ),

                // Next button with animation (more compact)
                Container(
                  width: 40, // Fixed width
                  height: 40, // Fixed height
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .primaryColor
                        .withOpacity(0.9), // Dark background
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero, // Remove default padding
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white, // White icon
                      size: 18, // Slightly smaller
                    ),
                    onPressed: _next,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8), // Reduced from 16

            // Period details with enhanced styling (more compact)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_periodDetails),
                width: double.infinity, // Full width
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6), // Reduced vertical padding
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .primaryColor
                      .withOpacity(0.9), // Dark background
                  borderRadius: BorderRadius.circular(4), // Sharp edges
                ),
                child: Text(
                  _periodDetails,
                  textAlign: TextAlign.center, // Center the text
                  style: TextStyle(
                    color: Colors.white, // White text
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Reduced font size
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _createTableEntry(String label, String value, {bool divider = true}) {
    return Column(children: [
      Table(
        columnWidths: const {
          0: FlexColumnWidth(3), // Label
          1: FlexColumnWidth(1), // Number
        },
        children: [
          TableRow(
            children: [
              Text(label),
              Text(value),
            ],
          ),
        ],
      ),
      if (divider)
        Divider(height: 1, thickness: 0.5, color: Colors.grey.withOpacity(0.3))
    ]);
  }

  CountTuple _getChantersAndSalesCount(Map dataRaw) {
    int chantersCount = 0;
    int salesCount = 0;
    int salesAmount = 0;

    for (var entry in dataRaw.entries) {
      // morning chanters
      if (entry.value.containsKey('Morning') &&
          entry.value['Morning'].containsKey('Chanters')) {
        Map morningData = entry.value['Morning']['Chanters'];
        for (var morningEntry in morningData.entries) {
          ChantersEntry chanter = Utils()
              .convertRawToDatatype(morningEntry.value, ChantersEntry.fromJson);
          chantersCount += chanter.count;
        }
      }

      // morning sales
      if (entry.value.containsKey('Morning') &&
          entry.value['Morning'].containsKey('Sales')) {
        Map morningSalesData = entry.value['Morning']['Sales'];
        for (var morningEntry in morningSalesData.entries) {
          SalesEntry sale = Utils()
              .convertRawToDatatype(morningEntry.value, SalesEntry.fromJson);
          salesCount += sale.count;
          salesAmount += (sale.japamala.saleValue * sale.count);
        }
      }

      // evening chanters
      if (entry.value.containsKey('Evening') &&
          entry.value['Evening'].containsKey('Chanters')) {
        Map eveningData = entry.value['Evening']['Chanters'];
        for (var eveningEntry in eveningData.entries) {
          ChantersEntry chanter = Utils()
              .convertRawToDatatype(eveningEntry.value, ChantersEntry.fromJson);
          chantersCount += chanter.count;
        }
      }

      // evening sales
      if (entry.value.containsKey('Evening') &&
          entry.value['Evening'].containsKey('Sales')) {
        Map eveningSalesData = entry.value['Evening']['Sales'];
        for (var eveningEntry in eveningSalesData.entries) {
          SalesEntry sale = Utils()
              .convertRawToDatatype(eveningEntry.value, SalesEntry.fromJson);
          salesCount += sale.count;
          salesAmount += (sale.japamala.saleValue * sale.count);
        }
      }
    }

    return CountTuple(
        chantersCount: chantersCount,
        salesCount: salesCount,
        salesAmount: salesAmount);
  }

  InventoryTuple _getChantersAndSalesInventory(var dataMap) {
    int addedChantersMalas = 0;
    int discardedChantersMalas = 0;
    int addedSalesMalas = 0;
    int discardedSalesMalas = 0;

    for (var entry in dataMap.entries) {
      List listRaw = entry.value;
      for (var item in listRaw) {
        InventoryEntry entry =
            Utils().convertRawToDatatype(item, InventoryEntry.fromJson);
        if (entry.malaType == "Chanters") {
          if (entry.addOrRemove == "Add") {
            addedChantersMalas += entry.count;
          } else if (entry.addOrRemove == "Discard") {
            discardedChantersMalas += entry.count;
          }
        } else if (entry.malaType == "Sales") {
          if (entry.addOrRemove == "Add") {
            addedSalesMalas += entry.count;
          } else if (entry.addOrRemove == "Discard") {
            discardedSalesMalas += entry.count;
          }
        }
      }
    }

    return InventoryTuple(
        addedChantersMalas: addedChantersMalas,
        discardedChantersMalas: discardedChantersMalas,
        addedSalesMalas: addedSalesMalas,
        discardedSalesMalas: discardedSalesMalas);
  }

  Future<void> _prev() async {
    switch (_period) {
      case "daily":
        DateTime currentDate = DateFormat("dd MMM, yyyy").parse(_periodDetails);
        DateTime previousDate = currentDate.subtract(Duration(days: 1));

        _periodDetails = DateFormat("dd MMM, yyyy").format(previousDate);
        break;

      case "weekly":
        String startOfWeek = _periodDetails.split('-')[0].trim();
        DateTime currentStartDate =
            DateFormat("dd MMM, yyyy").parse(startOfWeek);
        DateTime previousStartDate =
            currentStartDate.subtract(Duration(days: 7));
        DateTime previousEndDate = previousStartDate.add(Duration(days: 6));

        _periodDetails =
            "${DateFormat("dd MMM, yyyy").format(previousStartDate)} - ${DateFormat("dd MMM, yyyy").format(previousEndDate)}";
        break;

      case "monthly":
        DateTime currentDate = DateFormat("MMM yyyy").parse(_periodDetails);
        DateTime previousMonth =
            DateTime(currentDate.year, currentDate.month - 1, 1);

        _periodDetails = DateFormat("MMM yyyy").format(previousMonth);
        break;

      case "yearly":
        DateTime currentDate = DateFormat("yyyy").parse(_periodDetails);
        DateTime previousYear = DateTime(currentDate.year - 1, 1, 1);

        _periodDetails = DateFormat("yyyy").format(previousYear);
        break;
    }

    refresh();
  }

  Future<void> _next() async {
    DateTime today = DateTime.now();

    switch (_period) {
      case "daily":
        DateTime currentDate = DateFormat("dd MMM, yyyy").parse(_periodDetails);

        if (currentDate.year == today.year &&
            currentDate.month == today.month &&
            currentDate.day == today.day) {
          return;
        }

        DateTime nextDate = currentDate.add(Duration(days: 1));

        _periodDetails = DateFormat("dd MMM, yyyy").format(nextDate);
        break;

      case "weekly":
        String startOfWeek = _periodDetails.split('-')[0].trim();
        DateTime currentStartDate =
            DateFormat("dd MMM, yyyy").parse(startOfWeek);
        DateTime nextStartDate = currentStartDate.add(Duration(days: 7));

        // Don't go beyond current week
        if (nextStartDate
            .isAfter(today.subtract(Duration(days: today.weekday - 1)))) {
          return;
        }

        DateTime nextEndDate = nextStartDate.add(Duration(days: 6));

        _periodDetails =
            "${DateFormat("dd MMM, yyyy").format(nextStartDate)} - ${DateFormat("dd MMM, yyyy").format(nextEndDate)}";
        break;

      case "monthly":
        DateTime currentDate = DateFormat("MMM yyyy").parse(_periodDetails);

        // Don't go beyond current month
        if (currentDate.year == today.year &&
            currentDate.month == today.month) {
          return;
        }

        DateTime nextMonth =
            DateTime(currentDate.year, currentDate.month + 1, 1);

        _periodDetails = DateFormat("MMM yyyy").format(nextMonth);
        break;

      case "yearly":
        DateTime currentDate = DateFormat("yyyy").parse(_periodDetails);

        // Don't go beyond current year
        if (currentDate.year == today.year) {
          return;
        }

        DateTime nextYear = DateTime(currentDate.year + 1, 1, 1);

        _periodDetails = DateFormat("yyyy").format(nextYear);
        break;
    }

    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveScaffold(
          // title
          title: widget.title,

          // toolbar icons
          toolbarActions: [
            // ResponsiveToolbarAction(
            //   icon: Icon(Icons.refresh),
            // ),
          ],

          // body
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

                      // your widgets here
                      _createHMI(),

                      SizedBox(height: 10),
                      _createChantersSummary(),

                      SizedBox(height: 10),
                      _createSalesSummary(),

                      // leave some space at bottom
                      SizedBox(height: 500),
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
            image: widget.splashImage,
          ),
      ],
    );
  }
}

class InventoryTuple {
  final int addedChantersMalas;
  final int discardedChantersMalas;
  final int addedSalesMalas;
  final int discardedSalesMalas;

  InventoryTuple(
      {required this.addedChantersMalas,
      required this.discardedChantersMalas,
      required this.addedSalesMalas,
      required this.discardedSalesMalas});
}

class CountTuple {
  final int chantersCount;
  final int salesCount;
  final int salesAmount;

  CountTuple(
      {required this.chantersCount,
      required this.salesCount,
      required this.salesAmount});
}
