import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/dashboard.dart';
import 'package:vkhgaruda/harinaam/datatypes.dart';
import 'package:vkhgaruda/harinaam/hmi_chanters.dart';
import 'package:vkhgaruda/harinaam/hmi_sales.dart';
import 'package:vkhgaruda/harinaam/inventory.dart';
import 'package:vkhgaruda/harinaam/summary.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'dart:typed_data';

// Add these imports for web-specific functionality
// ignore: avoid_web_libraries_in_flutter
// Conditional import for PDF sharing
import 'pdf_share_io.dart' if (dart.library.html) 'pdf_share_web.dart';

class Harinaam extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Harinaam({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _HarinaamState createState() => _HarinaamState();
}

class _HarinaamState extends State<Harinaam> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  final GlobalKey<HmiChantersState> _keyHmiChanters =
      GlobalKey<HmiChantersState>();
  final GlobalKey<HmiSalesState> _keyHmiSales = GlobalKey<HmiSalesState>();
  final GlobalKey<DashboardState> _keyDashboard = GlobalKey<DashboardState>();
  DateTime _lastCallbackInvokedChanters = DateTime.now();
  DateTime _lastCallbackInvokedSales = DateTime.now();
  late String _session;

  // lists
  final List<ChantersEntry> _chantersEntries = [];
  final List<SalesEntry> _salesEntries = [];

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listenersChanters = [];
  List<StreamSubscription<DatabaseEvent>> _listenersSales = [];

  @override
  initState() {
    super.initState();

    // set session
    if (DateTime.now().hour >= Const().morningCutoff) {
      _session = "Evening";
    } else {
      _session = "Morning";
    }

    // listen to database events for chanters
    String dbdate = DateFormat("yyyy-MM-dd").format(_selectedDate);
    String dbpathChanters =
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/ServiceEntries/$dbdate/$_session/Chanters";
    FB().listenForChange(
        dbpathChanters,
        FBCallbacks(
          // add
          add: (data) {
            if (_lastCallbackInvokedChanters.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvokedChanters = DateTime.now();
            }

            // process the received data
            ChantersEntry entry =
                Utils().convertRawToDatatype(data, ChantersEntry.fromJson);
            if (!_chantersEntries.contains(entry)) {
              _addChanters(entry);
            }
          },

          // edit
          edit: () {
            if (_lastCallbackInvokedChanters.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvokedChanters = DateTime.now();

              refresh();
            }
          },

          // delete
          delete: (data) async {
            if (_lastCallbackInvokedChanters.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvokedChanters = DateTime.now();

              // process the received data
              ChantersEntry entry =
                  Utils().convertRawToDatatype(data, ChantersEntry.fromJson);
              int index = _chantersEntries.indexOf(entry);
              if (index != -1) {
                _deleteChanters(index, skipConfirm: true);
              }
            }
          },

          // get listeners
          getListeners: (listeners) {
            _listenersChanters = listeners;
          },
        ));

    // listen to database events for sales
    String dbpathSales =
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/ServiceEntries/$dbdate/$_session/Sales";
    FB().listenForChange(
        dbpathSales,
        FBCallbacks(
          // add
          add: (data) {
            if (_lastCallbackInvokedSales.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvokedSales = DateTime.now();
            }

            // process the received data
            SalesEntry entry =
                Utils().convertRawToDatatype(data, SalesEntry.fromJson);
            if (!_salesEntries.contains(entry)) {
              _addSales(entry);
            }
          },

          // edit
          edit: () {
            if (_lastCallbackInvokedSales.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvokedSales = DateTime.now();

              refresh();
            }
          },

          // delete
          delete: (data) async {
            if (_lastCallbackInvokedSales.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvokedSales = DateTime.now();

              // process the received data
              SalesEntry entry =
                  Utils().convertRawToDatatype(data, SalesEntry.fromJson);
              int index = _salesEntries.indexOf(entry);
              if (index != -1) {
                _deleteSales(index, skipConfirm: true);
              }
            }
          },

          // get listeners
          getListeners: (listeners) {
            _listenersSales = listeners;
          },
        ));

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps
    _chantersEntries.clear();
    _salesEntries.clear();

    // clear all controllers and focus nodes
    for (var element in _listenersChanters) {
      element.cancel();
    }
    for (var element in _listenersSales) {
      element.cancel();
    }
    _listenersChanters.clear();
    _listenersSales.clear();

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control
    bool allowed = await Utils().checkPermission("Harinaam Mantapa");
    if (!allowed && mounted) {
      Toaster().error("You are not allowed to access Harinaam");
      Navigator.of(context).pop();
    }

    await _lock.synchronized(() async {
      // lock session if not live
      if (_isSessionLive()) {
        _keyHmiSales.currentState!.setLockState(false);
        _keyHmiChanters.currentState!.setLockState(false);
      } else {
        _keyHmiSales.currentState!.setLockState(true);
        _keyHmiChanters.currentState!.setLockState(true);
      }

      // add chanters records from database
      _chantersEntries.clear();
      String dbdate = DateFormat("yyyy-MM-dd").format(_selectedDate);
      String dbpath =
          "${Const().dbrootGaruda}/Harinaam/ServiceEntries/ServiceEntries/$dbdate/$_session/Chanters";
      Map<String, dynamic> chantersJson =
          await FB().getJson(path: dbpath, silent: true);
      int countChanters = 0;
      for (String key in chantersJson.keys) {
        ChantersEntry entry = Utils()
            .convertRawToDatatype(chantersJson[key], ChantersEntry.fromJson);
        countChanters += entry.count;
        _chantersEntries.add(entry);
      }
      _chantersEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _keyDashboard.currentState!.setChanters(countChanters);

      // add sales records from database
      _salesEntries.clear();
      dbdate = DateFormat("yyyy-MM-dd").format(_selectedDate);
      dbpath =
          "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/$_session/Sales";
      Map<String, dynamic> salesJson =
          await FB().getJson(path: dbpath, silent: true);
      int countSales = 0;
      for (String key in salesJson.keys) {
        SalesEntry entry =
            Utils().convertRawToDatatype(salesJson[key], SalesEntry.fromJson);
        countSales += entry.count;
        _salesEntries.add(entry);
      }
      _salesEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _keyDashboard.currentState!.setSales(countSales);
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addChanters(ChantersEntry entry) async {
    // forbid changes for another day
    bool isToday = DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;
    if (!isToday) {
      Toaster().error(
        "You cannot change data for another day.",
      );
      return;
    }

    // forbid changes for wrong session
    if (_session == "Morning" && DateTime.now().hour >= Const().morningCutoff) {
      Toaster().error(
        "You cannot add entries to the Morning session after the cutoff time.",
      );
      return;
    }
    if (_session == "Evening" && DateTime.now().hour < Const().morningCutoff) {
      Toaster().error(
        "You cannot add entries to the Evening session before the cutoff time.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // update counter
    _keyDashboard.currentState!.addChanters(entry.count);

    // add to the list
    setState(() {
      _chantersEntries.insert(0, entry);
    });

    // update database asynchronously
    _lastCallbackInvokedChanters = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbtime = DateFormat("HH-mm-ss-ms").format(entry.timestamp);
    String dbpath =
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/$_session/Chanters/$dbtime";
    FB().setJson(path: dbpath, json: entry.toJson());

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addSales(SalesEntry entry) async {
    // forbid changes for another day
    bool isToday = DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;
    if (!isToday) {
      Toaster().error(
        "You cannot change data for another day.",
      );
      return;
    }

    // forbid changes for wrong session
    if (_session == "Morning" && DateTime.now().hour >= Const().morningCutoff) {
      Toaster().error(
        "You cannot add entries to the Morning session after the cutoff time.",
      );
      return;
    }
    if (_session == "Evening" && DateTime.now().hour < Const().morningCutoff) {
      Toaster().error(
        "You cannot add entries to the Evening session before the cutoff time.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // update counter
    _keyDashboard.currentState!.addSales(entry.count);

    // add to the list
    setState(() {
      _salesEntries.insert(0, entry);
    });

    // update database asynchronously
    _lastCallbackInvokedSales = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbtime = DateFormat("HH-mm-ss-ms").format(entry.timestamp);
    String dbpath =
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/$_session/Sales/$dbtime";
    FB().setJson(path: dbpath, json: entry.toJson());

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createChantersTile(int index) {
    ChantersEntry entry = _chantersEntries[index];
    final borderRadius = BorderRadius.circular(12.0);
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 180, // fixed width
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.brown),
            borderRadius: borderRadius,
            color: Theme.of(context).cardColor,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: ListTileCompact(
              title: Text(
                DateFormat("HH:mm:ss").format(entry.timestamp),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),

              // count
              leading: Padding(
                padding: const EdgeInsets.all(4.0),
                child: CircleAvatar(
                  backgroundColor: Colors.brown,
                  child: Text(
                    entry.count.toString(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),

              subtitle: Text(
                entry.username,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),

              // context menu
              trailing: _isSessionLive()
                  ? Widgets().createContextMenu(
                      color: Colors.brown,
                      items: ["Edit", "Delete"],
                      onPressed: (action) {
                        if (action == "Edit") {
                          _editChanters(index);
                        } else if (action == "Delete") {
                          _deleteChanters(index);
                        }
                      },
                    )
                  : null,

              borderRadius: borderRadius,
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _createPdf() async {
    setState(() {
      _isLoading = true;
    });

    // reset table data
    List<String> sevakartasMorning = [];
    List<String> sevakartasEvening = [];
    int chantMalasOpeningBalanceMorning = 0;
    int chantMalasOpeningBalanceEvening = 0;
    int chantMalasDiscardedMorning = 0;
    int chantMalasDiscardedEvening = 0;
    int chantMalasNewAdditionsMorning = 0;
    int chantMalasNewAdditionsEvening = 0;
    int chantMalasClosingBalanceMorning = 0;
    int chantMalasClosingBalanceEvening = 0;

    // morning chanters
    String dbdate = DateFormat("yyyy-MM-dd").format(_selectedDate);
    SummaryData summaryData = await _getSummaryData(
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/Morning/Chanters");
    sevakartasMorning = summaryData.sevakartas;

    // evening chanters
    summaryData = await _getSummaryData(
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/Evening/Chanters");
    sevakartasEvening = summaryData.sevakartas;

    // morning sales
    summaryData = await _getSummaryData(
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/Morning/Sales");
    sevakartasMorning = [
      ...{...sevakartasMorning, ...summaryData.sevakartas}
    ];

    // evening sales
    summaryData = await _getSummaryData(
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/Evening/Sales");
    sevakartasEvening = [
      ...{...sevakartasEvening, ...summaryData.sevakartas}
    ];

    // create pdf
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        // orientation: pw.PageOrientation.landscape,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // page title
            pw.Center(
              child: pw.Text(
                "Harinaam Mantapa \nHare Krishna Mahamantra Chanters' Club",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            // date
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                "${DateFormat('EEEE').format(_selectedDate)}, ${DateFormat('dd-MM-yyyy').format(_selectedDate)}",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.normal,
                ),
                textAlign: pw.TextAlign.left,
              ),
            ),

            // header for morning entry
            pw.SizedBox(height: 10),
            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1E3A8A),
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFF1E3A8A),
                  width: 2,
                ),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Center(
                child: pw.Text(
                  "Morning",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFFFFFFFF),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),

            // list of sevakartas
            pw.SizedBox(height: 10),
            pw.Text("Sevakartas: ${sevakartasMorning.join(", ")}"),

            // Morning table
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // chant malas
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: pw.Table.fromTextArray(
                  headers: ["Chant malas", "Count"],
                  data: [
                    ['Opening balance', '150'],
                    ['Discarded', '3'],
                    ['New addition', '7'],
                    ['Closing balance', '17']
                  ],
                  columnWidths: {
                    1: const pw.FixedColumnWidth(50),
                  },
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(
                        0xFF90CAF9), // lighter shade of Morning header (0xFF1E3A8A)
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF000000),
                    fontWeight: pw.FontWeight.bold,
                  ),
                )),

                // sale malas
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: pw.Table.fromTextArray(
                  headers: ["Sale malas", "Count"],
                  data: [
                    ['Opening balance', '150'],
                    ['Discarded', '3'],
                    ['New addition', '7'],
                    ['Total sales', '7'],
                    ['Closing balance', '17']
                  ],
                  columnWidths: {
                    1: const pw.FixedColumnWidth(50),
                  },
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF90CAF9),
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF000000),
                    fontWeight: pw.FontWeight.bold,
                  ),
                )),

                // payment modes
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: pw.Table.fromTextArray(
                  headers: ["Payment modes", "Count"],
                  data: [
                    ['UPI', '150'],
                    ['Cash', '3'],
                    ['Card', '7'],
                    ['Gift', '7'],
                  ],
                  columnWidths: {
                    1: const pw.FixedColumnWidth(50),
                  },
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF90CAF9),
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF000000),
                    fontWeight: pw.FontWeight.bold,
                  ),
                )),
              ],
            ),

            // Summary
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                "Mala sales: 6",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1E3A8A),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Center(
              child: pw.Text(
                "Chanters count: 88",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1E3A8A),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            pw.Divider(color: PdfColor.fromInt(0xFF1E3A8A)),

            // evening data
            // header for evening entry
            pw.SizedBox(height: 10),
            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFd65302),
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFFd65302),
                  width: 2,
                ),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Center(
                child: pw.Text(
                  "Evening",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFFFFFFFF),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),

            // list of sevakartas
            pw.SizedBox(height: 10),
            pw.Text("Sevakartas: ${sevakartasEvening.join(", ")}"),

            // Morning table
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // chant malas
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: pw.Table.fromTextArray(
                  headers: ["Chant malas", "Count"],
                  data: [
                    ['Opening balance', '150'],
                    ['Discarded', '3'],
                    ['New addition', '7'],
                    ['Closing balance', '17']
                  ],
                  columnWidths: {
                    1: const pw.FixedColumnWidth(50),
                  },
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFffb587),
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF000000),
                    fontWeight: pw.FontWeight.bold,
                  ),
                )),

                // sale malas
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: pw.Table.fromTextArray(
                  headers: ["Sale malas", "Count"],
                  data: [
                    ['Opening balance', '150'],
                    ['Discarded', '3'],
                    ['New addition', '7'],
                    ['Total sales', '7'],
                    ['Closing balance', '17']
                  ],
                  columnWidths: {
                    1: const pw.FixedColumnWidth(50),
                  },
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFffb587),
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF000000),
                    fontWeight: pw.FontWeight.bold,
                  ),
                )),

                // payment modes
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: pw.Table.fromTextArray(
                  headers: ["Payment modes", "Count"],
                  data: [
                    ['UPI', '150'],
                    ['Cash', '3'],
                    ['Card', '7'],
                    ['Gift', '7'],
                  ],
                  columnWidths: {
                    1: const pw.FixedColumnWidth(50),
                  },
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFffb587),
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF000000),
                    fontWeight: pw.FontWeight.bold,
                  ),
                )),
              ],
            ),

            // Summary
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                "Mala sales: 6",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFFd65302),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Center(
              child: pw.Text(
                "Chanters count: 88",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFFd65302),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            pw.Divider(color: PdfColor.fromInt(0xFFd65302)),
          ],
        ),
      ),
    );

    setState(() {
      _isLoading = false;
    });

    return doc.save();
  }

  Widget _createSalesTile(int index) {
    SalesEntry entry = _salesEntries[index];
    String time = DateFormat("HH:mm:ss").format(entry.timestamp);

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 200,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(12.0),
            color: Theme.of(context).cardColor,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ListTileCompact(
              borderRadius: BorderRadius.circular(12.0),
              // sale count and amount
              leading: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: _createSalePair(entry),
                  ),
                  Text(
                    entry.paymentMode,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: (Const().paymentModes[entry.paymentMode]
                                  ?['color'] as Color?) ??
                              Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),

              // timestamp
              title: Text(
                time,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),

              // username
              subtitle: Text(
                entry.username,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),

              // context menu
              trailing: _isSessionLive()
                  ? Widgets().createContextMenu(
                      items: ["Edit", "Delete"],
                      onPressed: (String action) {
                        if (action == "Edit") {
                          _editSales(index);
                        } else if (action == "Delete") {
                          _deleteSales(index);
                        }
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _createSalePair(SalesEntry entry) {
    return IntrinsicWidth(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade100,
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left partition
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Color(int.parse("0xff${entry.japamala.colorHex}")),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: Center(
                  child: Text(
                    entry.count.toString(),
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
              // Right partition
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Center(
                  child: Text(
                    "₹${entry.japamala.saleValue * entry.count}",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteChanters(int index, {bool skipConfirm = false}) async {
    // forbid changes for another day
    bool isToday = DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;
    if (!isToday) {
      Toaster().error(
        "You cannot change data for another day.",
      );
      return;
    }

    ChantersEntry entry = _chantersEntries[index];

    setState(() {
      _isLoading = true;
    });

    // confirm delete
    bool confirmed = true;
    if (!skipConfirm) {
      dynamic ret = await Widgets()
          .showConfirmDialog(context, "Are you sure?", "Delete", null);
      confirmed = ret == null ? false : true;
    }

    if (!confirmed) return;

    // update dashboard counter
    int count = _keyDashboard.currentState!.getChanters();
    count -= entry.count;
    _keyDashboard.currentState!.setChanters(count);

    // update database
    _lastCallbackInvokedChanters = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbtime = DateFormat("HH-mm-ss-ms").format(entry.timestamp);
    String dbpath =
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/$_session/Chanters/$dbtime";
    FB().deleteValue(path: dbpath);

    // remove from the list
    setState(() {
      _chantersEntries.removeAt(index);
      _isLoading = false;
    });
  }

  Future<void> _deleteSales(int index, {bool skipConfirm = false}) async {
    // forbid changes for another day
    bool isToday = DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;
    if (!isToday) {
      Toaster().error(
        "You cannot change data for another day.",
      );
      return;
    }

    SalesEntry entry = _salesEntries[index];

    setState(() {
      _isLoading = true;
    });

    // confirm delete
    bool confirmed = true;
    if (!skipConfirm) {
      dynamic ret = await Widgets()
          .showConfirmDialog(context, "Are you sure?", "Delete", null);
      confirmed = ret == null ? false : true;
    }

    if (!confirmed) return;

    // update dashboard counter
    int count = _keyDashboard.currentState!.getSales();
    count -= entry.count;
    _keyDashboard.currentState!.setSales(count);

    // update database
    _lastCallbackInvokedSales = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbtime = DateFormat("HH-mm-ss-ms").format(entry.timestamp);
    String dbpath =
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/$_session/Sales/$dbtime";
    FB().deleteValue(path: dbpath);

    // remove from the list
    setState(() {
      _salesEntries.removeAt(index);
      _isLoading = false;
    });
  }

  Future<void> _editChanters(int index) async {
    // forbid changes for another day
    bool isToday = DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;
    if (!isToday) {
      Toaster().error(
        "You cannot change data for another day.",
      );
      return;
    }

    // get the entry to edit
    ChantersEntry entry = _chantersEntries[index];

    // Show the edit dialog
    ChantersEntry? editedEntry = await _showDialogEditChanters(entry);

    // If user saved changes, update the entry
    if (editedEntry != null) {
      // Update the list
      setState(() {
        _isLoading = true;
        _chantersEntries[index] = editedEntry;
      });

      // Update database (since timestamp doesn't change, we can update in place)
      _lastCallbackInvokedChanters = DateTime.now();
      String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
      String dbtime = DateFormat("HH-mm-ss-ms").format(entry.timestamp);
      String dbpath =
          "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/$_session/Chanters/$dbtime";
      FB().setJson(path: dbpath, json: editedEntry.toJson());

      // Update dashboard counter
      int totalCount = 0;
      for (ChantersEntry chanterEntry in _chantersEntries) {
        totalCount += chanterEntry.count;
      }
      _keyDashboard.currentState!.setChanters(totalCount);

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editSales(int index) async {
    // forbid changes for another day
    bool isToday = DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;
    if (!isToday) {
      Toaster().error(
        "You cannot change data for another day.",
      );
      return;
    }

    // get the entry to edit
    SalesEntry entry = _salesEntries[index];

    // Show the edit dialog
    SalesEntry? editedEntry = await _showDialogEditSales(entry);

    // If user saved changes, update the entry
    if (editedEntry != null) {
      // Update the list
      setState(() {
        _isLoading = true;
        _salesEntries[index] = editedEntry;
      });

      // Update database (since timestamp doesn't change, we can update in place)
      _lastCallbackInvokedSales = DateTime.now();
      String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
      String dbtime = DateFormat("HH-mm-ss-ms").format(entry.timestamp);
      String dbpath =
          "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/$_session/Sales/$dbtime";
      FB().setJson(path: dbpath, json: editedEntry.toJson());

      // Update dashboard counter
      int totalCount = 0;
      for (SalesEntry salesEntry in _salesEntries) {
        totalCount += salesEntry.count;
      }
      _keyDashboard.currentState!.setSales(totalCount);

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<SummaryData> _getSummaryData(String dbpath) async {
    List<String> sevakartas = [];

    Map<String, dynamic> json = await FB().getJson(path: dbpath, silent: true);
    for (var entry in json.entries) {
      ChantersEntry chantersEntry =
          Utils().convertRawToDatatype(entry.value, ChantersEntry.fromJson);

      // sevakarta
      if (!sevakartas.contains(chantersEntry.username)) {
        sevakartas.add(chantersEntry.username);
      }
    }

    return SummaryData(
      sevakartas: sevakartas,
    );
  }

  bool _isSessionLive() {
    // check if today
    bool isToday = DateTime.now().year == _selectedDate.year &&
        DateTime.now().month == _selectedDate.month &&
        DateTime.now().day == _selectedDate.day;

    String sessionTime =
        DateTime.now().hour < Const().morningCutoff ? "Morning" : "Evening";

    if (isToday && _session == sessionTime) {
      return true;
    } else {
      return false;
    }
  }

  /// Share the PDF using platform-specific implementation
  Future<void> _sharePdf(Uint8List pdfBytes) async {
    await sharePdf(pdfBytes, filename: 'report.pdf');
  }

  Future<ChantersEntry?> _showDialogEditChanters(ChantersEntry entry) async {
    final TextEditingController controller =
        TextEditingController(text: entry.count.toString());
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return await Widgets().showResponsiveDialog(
        context: context,
        title: "Edit Chanters Entry",
        child: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Count",
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Count cannot be empty';
                }

                final number = int.tryParse(value.trim());
                if (number == null) {
                  return 'Please enter a valid number';
                }

                if (number <= 0) {
                  return 'Count must be greater than 0';
                }

                if (number > 10000) {
                  return 'Count cannot exceed 10,000';
                }

                return null;
              },
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Validate form before saving
              if (formKey.currentState!.validate()) {
                // save changes - read from controller
                int count = int.parse(controller.text.trim());
                ChantersEntry editedEntry = ChantersEntry(
                  count: count,
                  timestamp: entry.timestamp,
                  username: Utils().getUsername(),
                );
                Navigator.of(context).pop(editedEntry);
              }
            },
            child: const Text("Save"),
          ),
        ]);
  }

  Future<SalesEntry?> _showDialogEditSales(SalesEntry entry) async {
    final TextEditingController controller =
        TextEditingController(text: entry.count.toString());
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final Map<String, dynamic> paymentModes = Const().paymentModes;
    final List<String> paymentModeKeys = paymentModes.keys.toList();
    String selectedPaymentMode = entry.paymentMode;

    return await Widgets().showResponsiveDialog(
        context: context,
        title: "Edit Sales Entry",
        child: Form(
          key: formKey,
          child: Column(
            children: [
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPaymentMode,
                decoration: const InputDecoration(
                  labelText: "Payment Mode",
                  border: OutlineInputBorder(),
                ),
                items: paymentModeKeys
                    .map((mode) => DropdownMenuItem<String>(
                          value: mode,
                          child: Text(mode),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedPaymentMode = value;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a payment mode';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Count",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Count cannot be empty';
                  }

                  final number = int.tryParse(value.trim());
                  if (number == null) {
                    return 'Please enter a valid number';
                  }

                  if (number <= 0) {
                    return 'Count must be greater than 0';
                  }

                  if (number > 10000) {
                    return 'Count cannot exceed 10,000';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Validate form before saving
              if (formKey.currentState!.validate()) {
                // save changes - read from controller
                int count = int.parse(controller.text.trim());
                Japamala japamala = entry.japamala;
                SalesEntry editedEntry = SalesEntry(
                  paymentMode: selectedPaymentMode,
                  japamala: japamala,
                  count: count,
                  timestamp: entry.timestamp,
                  username: Utils().getUsername(),
                );
                Navigator.of(context).pop(editedEntry);
              }
            },
            child: const Text("Save"),
          ),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveScaffold(
          title: widget.title,
          toolbarActions: [
            // inventory management
            ResponsiveToolbarAction(
              icon: const Icon(Icons.playlist_add),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Inventory(
                            title: "Inventory",
                            splashImage: widget.splashImage)));
              },
            ),

            // summary
            ResponsiveToolbarAction(
              icon: const Icon(Icons.article),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Summary(
                            title: "Summary",
                            splashImage: widget.splashImage)));
              },
            ),

            // share
            ResponsiveToolbarAction(
              icon: const Icon(Icons.share),
              onPressed: () async {
                final pdfBytes = await _createPdf();
                _sharePdf(pdfBytes);
              },
            ),
          ],
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

                      // date header
                      DateHeader(
                          callbacks: DateHeaderCallbacks(onChange: (date) {
                        // update selected date
                        _selectedDate = date;

                        // refresh the data
                        refresh();
                      })),

                      // session
                      RadioRow(
                          items: ["Morning", "Evening"],
                          selectedIndex: _session == "Morning" ? 0 : 1,
                          onChanged: (String session) {
                            _session = session;
                            refresh();
                          }),

                      // counter display
                      SizedBox(height: 4),
                      Widgets().createTopLevelCard(
                        context: context,
                        child: Dashboard(key: _keyDashboard),
                      ),

                      // Chanters' club
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Chanters' club",
                        color: Colors.brown,
                        child: Column(
                          children: [
                            // HmiChanters widget
                            HmiChanters(
                                key: _keyHmiChanters,
                                onSubmit: (count) {
                                  // create a new entry
                                  ChantersEntry entry = ChantersEntry(
                                    count: count,
                                    timestamp: DateTime.now(),
                                    username: Utils().getUsername(),
                                  );
                                  _addChanters(entry);
                                }),

                            // chanters entries list
                            if (_chantersEntries.isNotEmpty)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(
                                    _chantersEntries.length,
                                    (index) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4.0),
                                      child: _createChantersTile(index),
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),

                      // Japamala sales
                      SizedBox(height: 10),
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Japamala sales",
                        child: Column(
                          children: [
                            // HMI
                            HmiSales(
                                key: _keyHmiSales,
                                onSubmit: (sales) {
                                  _addSales(sales);
                                }),

                            // sales entries list
                            SizedBox(height: 10),
                            if (_salesEntries.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(
                                      _salesEntries.length,
                                      (index) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4.0),
                                        child: _createSalesTile(index),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),

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

class SummaryData {
  final List<String> sevakartas;

  SummaryData({
    required this.sevakartas,
  });
}
