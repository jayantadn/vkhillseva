import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';

// Conditional import for screenshot sharing
import 'screenshot_share_io.dart'
    if (dart.library.html) 'screenshot_share_web.dart';

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
  late String _periodDetails;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // variables for chanters summary
  int _totalChanters = 0;
  int _openingBalanceChanters = 0;
  int _newChanterMalasProcured = 0;
  int _discardedChanterMalas = 0;
  int _closingBalanceChanters = 0;

  // variables for sales summary
  int _totalMalasSold = 0;
  int _openingBalanceSales = 0;
  int _totalAmountCollected = 0;
  int _newSaleMalasProcured = 0;
  int _discardedSaleMalas = 0;
  int _closingBalanceSales = 0;
  final Map<String, dynamic> _paymentModeSummary = {};

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    _initPeriodDetails();

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
      _paymentModeSummary.clear();
      switch (_period) {
        case "daily":
          DateTime date = DateFormat("dd MMM, yyyy").parse(_periodDetails);
          String dbdate = DateFormat("yyyy-MM-dd").format(date);

          // collect morning chaters data
          _totalChanters = 0;
          String dbpath =
              "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/Morning/Chanters";
          Map<String, dynamic> data =
              await FB().getJson(path: dbpath, silent: true);
          for (var entry in data.entries) {
            ChantersEntry chanter = Utils()
                .convertRawToDatatype(entry.value, ChantersEntry.fromJson);
            _totalChanters += chanter.count;
          }

          // collect evening chaters data
          dbpath =
              "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/Evening/Chanters";
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
          dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory/$dbdate";
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

          // number of malas sold morning
          _totalMalasSold = 0;
          _totalAmountCollected = 0;
          dbpath =
              "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/Morning/Sales";
          data = await FB().getJson(path: dbpath, silent: true);
          for (var entry in data.entries) {
            SalesEntry sale =
                Utils().convertRawToDatatype(entry.value, SalesEntry.fromJson);
            _totalMalasSold += sale.count;
            _totalAmountCollected += (sale.japamala.saleValue * sale.count);

            // payment modes
            if (_paymentModeSummary.containsKey(sale.paymentMode)) {
              Map<String, dynamic> data =
                  _paymentModeSummary[sale.paymentMode] as Map<String, dynamic>;
              data['count'] += sale.count;
              data['amount'] += (sale.japamala.saleValue * sale.count);
              _paymentModeSummary[sale.paymentMode] = data;
            } else {
              _paymentModeSummary[sale.paymentMode] = {
                'count': sale.count,
                'amount': (sale.japamala.saleValue * sale.count),
              };
            }
          }

          // number of malas sold evening
          dbpath =
              "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/Evening/Sales";
          data = await FB().getJson(path: dbpath, silent: true);
          for (var entry in data.entries) {
            SalesEntry sale =
                Utils().convertRawToDatatype(entry.value, SalesEntry.fromJson);
            _totalMalasSold += sale.count;
            _totalAmountCollected += (sale.japamala.saleValue * sale.count);

            // payment modes
            if (_paymentModeSummary.containsKey(sale.paymentMode)) {
              Map<String, dynamic> data =
                  _paymentModeSummary[sale.paymentMode] as Map<String, dynamic>;
              data['count'] += sale.count;
              data['amount'] += (sale.japamala.saleValue * sale.count);
              _paymentModeSummary[sale.paymentMode] = data;
            } else {
              _paymentModeSummary[sale.paymentMode] = {
                'count': sale.count,
                'amount': (sale.japamala.saleValue * sale.count),
              };
            }
          }
          break;

        case "weekly":
          DateTime startDate = DateFormat("dd MMM, yyyy")
              .parse(_periodDetails.split('-')[0].trim());
          DateTime endDate = DateFormat("dd MMM, yyyy")
              .parse(_periodDetails.split('-')[1].trim());

          // number of chanters and sales
          String dbpath = "${Const().dbrootGaruda}/Harinaam/ServiceEntries";
          var dataRaw = await FB().getValuesByDateRange(
              path: dbpath, startDate: startDate, endDate: endDate);
          CountTuple countData = _getChantersAndSalesCount(dataRaw);
          _totalChanters = countData.chantersCount;
          _totalMalasSold = countData.salesCount;
          _totalAmountCollected = countData.salesAmount;
          _paymentModeSummary.addAll(countData.paymentModeSummary);

          // chanters inventory data
          _newChanterMalasProcured = 0;
          _discardedChanterMalas = 0;
          dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory";
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
          String dbpath = "${Const().dbrootGaruda}/Harinaam//ServiceEntries";
          var dataRaw = await FB().getValuesByDateRange(
              path: dbpath, startDate: startDate, endDate: endDate);
          CountTuple countData = _getChantersAndSalesCount(dataRaw);
          _totalChanters = countData.chantersCount;
          _totalMalasSold = countData.salesCount;
          _totalAmountCollected = countData.salesAmount;
          _paymentModeSummary.addAll(countData.paymentModeSummary);

          // chanters inventory data
          dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory";
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
          String dbpath = "${Const().dbrootGaruda}/Harinaam//ServiceEntries";
          var dataRaw = await FB().getValuesByDateRange(
              path: dbpath, startDate: startDate, endDate: endDate);
          CountTuple countData = _getChantersAndSalesCount(dataRaw);
          _totalChanters = countData.chantersCount;
          _totalMalasSold = countData.salesCount;
          _totalAmountCollected = countData.salesAmount;
          _paymentModeSummary.addAll(countData.paymentModeSummary);

          // chanters inventory data
          dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory";
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

      // display the balances
      await _updateBalances();
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
            _createTableEntry("Opening balance", "$_openingBalanceChanters"),
            _createTableEntry(
                "New malas procured", "$_newChanterMalasProcured"),
            _createTableEntry("Discarded malas", "$_discardedChanterMalas",
                divider: false),
            _createTableEntry("Closing balance", "$_closingBalanceChanters")
          ],
        ));
  }

  Widget _createPaymentModeSummary() {
    return Widgets().createTopLevelCard(
        context: context,
        title: "Payment Modes",
        child: Column(
          children:
              _paymentModeSummary.entries.toList().asMap().entries.map((entry) {
            int idx = entry.key;
            String paymentMode = entry.value.key;
            Map<String, dynamic> data = entry.value.value;
            bool isLast = idx == _paymentModeSummary.entries.length - 1;
            return _createTableEntry(
              paymentMode,
              "${data['count']} (₹${data['amount']})",
              divider: !isLast,
            );
          }).toList(),
        ));
  }

  Widget _createSalesSummary() {
    return Widgets().createTopLevelCard(
        context: context,
        title: "Japamala Sales",
        child: Column(
          children: [
            _createTableEntry("Opening balance", "$_openingBalanceSales"),
            _createTableEntry("Total malas sold", "$_totalMalasSold"),
            _createTableEntry("New malas procured", "$_newSaleMalasProcured"),
            _createTableEntry(
              "Discarded malas",
              "$_discardedSaleMalas",
            ),
            _createTableEntry(
              "Closing balance",
              "$_closingBalanceSales",
            ),
            _createTableEntry(
                "Total amount collected", "₹$_totalAmountCollected",
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0), // Minimal vertical padding
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
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
                              _periodDetails = DateFormat("dd MMM, yyyy")
                                  .format(DateTime.now());
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
                              _periodDetails =
                                  DateFormat("MMM yyyy").format(now);
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

                    // today button
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        tooltip: "Jump to today",
                        icon: const Icon(Icons.event, size: 20),
                        color: Theme.of(context).primaryColor,
                        onPressed: () {
                          setState(() {
                            switch (_period) {
                              case "daily":
                                _periodDetails = DateFormat("dd MMM, yyyy")
                                    .format(DateTime.now());
                                break;
                              case "weekly":
                                DateTime now = DateTime.now();
                                DateTime startOfWeek = now
                                    .subtract(Duration(days: now.weekday - 1));
                                DateTime endOfWeek =
                                    startOfWeek.add(Duration(days: 6));
                                _periodDetails =
                                    "${DateFormat("dd MMM, yyyy").format(startOfWeek)} - ${DateFormat("dd MMM, yyyy").format(endOfWeek)}";
                                break;
                              case "monthly":
                                DateTime now = DateTime.now();
                                _periodDetails =
                                    DateFormat("MMM yyyy").format(now);
                                break;
                              case "yearly":
                                DateTime now = DateTime.now();
                                _periodDetails = DateFormat("yyyy").format(now);
                                break;
                            }
                          });

                          refresh();
                        },
                      ),
                    ),
                  ],
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
    Map<String, dynamic> paymentModeSummary = {};

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

          if (paymentModeSummary.containsKey(sale.paymentMode)) {
            Map<String, dynamic> data =
                paymentModeSummary[sale.paymentMode] as Map<String, dynamic>;
            data['count'] += sale.count;
            data['amount'] += (sale.japamala.saleValue * sale.count);
            paymentModeSummary[sale.paymentMode] = data;
          } else {
            paymentModeSummary[sale.paymentMode] = {
              'count': sale.count,
              'amount': (sale.japamala.saleValue * sale.count),
            };
          }
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

          if (paymentModeSummary.containsKey(sale.paymentMode)) {
            Map<String, dynamic> data =
                paymentModeSummary[sale.paymentMode] as Map<String, dynamic>;
            data['count'] += sale.count;
            data['amount'] += (sale.japamala.saleValue * sale.count);
            paymentModeSummary[sale.paymentMode] = data;
          } else {
            paymentModeSummary[sale.paymentMode] = {
              'count': sale.count,
              'amount': (sale.japamala.saleValue * sale.count),
            };
          }
        }
      }
    }

    return CountTuple(
        chantersCount: chantersCount,
        salesCount: salesCount,
        salesAmount: salesAmount,
        paymentModeSummary: paymentModeSummary);
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

  DateTime? _getStartAndEndDateOfPeriod(String neededDate) {
    DateTime? date;

    switch (_period) {
      case "daily":
        date = DateFormat("dd MMM, yyyy").parse(_periodDetails);
        break;
      case "weekly":
        if (neededDate == "startDate") {
          String strDate = _periodDetails.split('-')[0];
          strDate = strDate.trim();
          date = DateFormat("dd MMM, yyyy").parse(strDate);
        } else if (neededDate == "endDate") {
          String strDate = _periodDetails.split('-')[1];
          strDate = strDate.trim();
          date = DateFormat("dd MMM, yyyy").parse(strDate);
        }
        break;
      case "monthly":
        date = DateFormat("MMM yyyy").parse(_periodDetails);
        if (neededDate == "startDate") {
          date = DateTime(date.year, date.month, 1);
        } else if (neededDate == "endDate") {
          date = DateTime(date.year, date.month + 1, 0);
        }
        break;
      case "yearly":
        date = DateFormat("yyyy").parse(_periodDetails);
        if (neededDate == "startDate") {
          date = DateTime(date.year, 1, 1);
        } else if (neededDate == "endDate") {
          date = DateTime(date.year, 12, 31);
        }
        break;
    }

    return date;
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

  /// Share the screenshot using platform-specific implementation
  Future<void> _shareImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List? screenshotBytes = await _takeScreenshot();
      if (screenshotBytes != null) {
        await shareScreenshot(screenshotBytes,
            filename:
                'harinaam_summary_${DateTime.now().millisecondsSinceEpoch}.png');
      } else {
        Toaster().error("Failed to capture screenshot");
      }
    } catch (e) {
      Toaster().error("Failed to share screenshot: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Capture screenshot of the widget
  Future<Uint8List?> _takeScreenshot() async {
    try {
      // Find the RenderRepaintBoundary
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Capture the image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to bytes
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      Toaster().error("Failed to take screenshot: $e");
      return null;
    }
  }

  void _initPeriodDetails() {
    switch (_period) {
      case "daily":
        _periodDetails = DateFormat("dd MMM, yyyy").format(DateTime.now());
        break;
      case "weekly":
        DateTime now = DateTime.now();
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
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
  }

  Future<void> _updateBalances() async {
    DateTime? startDate = _getStartAndEndDateOfPeriod("startDate");
    DateTime? endDate = _getStartAndEndDateOfPeriod("endDate");
    if (startDate == null || endDate == null) {
      Toaster().error("Could not determine start or end date of the period");
      return;
    }

    // opening balance
    String dbpath = "${Const().dbrootGaruda}/Harinaam/MalaBalance";
    Map<String, dynamic> dataBalance = await FB().getJsonForFirstDateInRange(
        path: dbpath, startDate: startDate, endDate: endDate, silent: true);
    _openingBalanceChanters = dataBalance["ChantersOpeningBalance"] ?? 0;
    _openingBalanceSales = dataBalance["SalesOpeningBalance"] ?? 0;

    // closing balance
    dbpath = "${Const().dbrootGaruda}/Harinaam/MalaBalance";
    dataBalance = await FB().getJsonForLastDateInRange(
        path: dbpath, startDate: startDate, endDate: endDate, silent: true);
    _closingBalanceChanters = dataBalance["ChantersClosingBalance"] ?? 0;
    _closingBalanceSales = dataBalance["SalesClosingBalance"] ?? 0;
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
            // share button
            // ResponsiveToolbarAction(
            //   icon: Icon(Icons.share),
            //   onPressed: () {
            //     _shareImage();
            //   },
            // ),
          ],

          // body
          body: RepaintBoundary(
            key: _repaintBoundaryKey,
            child: RefreshIndicator(
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

                        SizedBox(height: 10),
                        _createPaymentModeSummary(),

                        // leave some space at bottom
                        SizedBox(height: 500),
                      ],
                    ),
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
  Map<String, dynamic> paymentModeSummary;

  CountTuple(
      {required this.chantersCount,
      required this.salesCount,
      required this.salesAmount,
      required this.paymentModeSummary});
}
