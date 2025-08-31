import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/harinaam/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

// Add these imports for web-specific functionality
// ignore: avoid_web_libraries_in_flutter
// Conditional import for PDF sharing
import 'pdf_share_io.dart' if (dart.library.html) 'pdf_share_web.dart';

class Inventory extends StatefulWidget {
  final String title;
  final String? splashImage;

  const Inventory({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _InventoryState createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  late bool _isToday;
  final String _selectedYear = DateTime.now().year.toString();
  DateTime _lastDataModification = DateTime.now();
  late String _session;
  late InventorySummary _morningInventoryChanters;
  late InventorySummary _eveningInventoryChanters;
  late InventorySummary _morningInventorySales;
  late InventorySummary _eveningInventorySales;
  late SaleData _morningSales;
  late SaleData _eveningSales;

  // lists
  final List<InventoryEntry> _inventoryEntries = [];

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    _isToday = DateUtils.isSameDay(DateTime.now(), _selectedDate);

    // set session
    if (DateTime.now().hour >= Const().morningCutoff) {
      _session = "Evening";
    } else {
      _session = "Morning";
    }

    // set default inventory data
    _eveningInventoryChanters = _morningInventoryChanters =
        _eveningInventorySales = _morningInventorySales = InventorySummary(
      openingBalance: 0,
      discarded: 0,
      newAdditions: 0,
      closingBalance: 0,
    );

    // set default payment mode counts
    _morningSales = SaleData(count: 0, paymentModes: {});
    _eveningSales = SaleData(count: 0, paymentModes: {});

    FB().listenForChange(
      "${Const().dbrootGaruda}/Harinaam/Inventory",
      FBCallbacks(
        // add
        add: (data) {
          if (_lastDataModification.isBefore(
            DateTime.now().subtract(Duration(seconds: Const().fbListenerDelay)),
          )) {
            _lastDataModification = DateTime.now();
          }

          // process the received data
          refresh();
        },

        // edit
        edit: () {
          if (_lastDataModification.isBefore(
            DateTime.now().subtract(Duration(seconds: Const().fbListenerDelay)),
          )) {
            _lastDataModification = DateTime.now();

            refresh();
          }
        },

        // delete
        delete: (data) async {
          if (_lastDataModification.isBefore(
            DateTime.now().subtract(Duration(seconds: Const().fbListenerDelay)),
          )) {
            _lastDataModification = DateTime.now();

            // process the received data
            refresh(); // directly refreshing because the deleted data is deeply nested
          }
        },

        // get listeners
        getListeners: (listeners) {
          _listeners = listeners;
        },
      ),
    );

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps
    _inventoryEntries.clear();

    // dispose all controllers and focus nodes
    _inventoryEntries.clear();

    // listeners
    for (var element in _listeners) {
      element.cancel();
    }

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

      return;
    }

    await _lock.synchronized(() async {
      _isToday = DateUtils.isSameDay(DateTime.now(), _selectedDate);

      // set session
      if (DateTime.now().hour >= Const().morningCutoff) {
        _session = "Evening";
      } else {
        _session = "Morning";
      }

      _morningInventoryChanters =
          await _getInventorySummary(_selectedDate, "Morning", "Chanters");
      _morningInventorySales =
          await _getInventorySummary(_selectedDate, "Morning", "Sales");
      _eveningInventoryChanters =
          await _getInventorySummary(_selectedDate, "Evening", "Chanters");
      _eveningInventorySales =
          await _getInventorySummary(_selectedDate, "Evening", "Sales");

      // refill inventory entries
      _inventoryEntries.clear();
      String dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory";
      List rawTopList =
          await FB().getListByYear(path: dbpath, year: _selectedYear);
      if (rawTopList.isNotEmpty) {
        for (var rawList in rawTopList) {
          for (var rawItem in rawList) {
            Map rawMap = rawItem as Map;
            InventoryEntry entry =
                Utils().convertRawToDatatype(rawMap, InventoryEntry.fromJson);
            _inventoryEntries.insert(0, entry);
          }
        }
      }
      _inventoryEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // sales count
      _morningSales = await _getSales("Morning");
      _eveningSales = await _getSales("Evening");
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addInventoryEntry(InventoryEntry entry) async {
    setState(() {
      _isLoading = true;
    });

    _inventoryEntries.insert(0, entry);

    // update inventory summary
    if (entry.malaType == "Chanters") {
      if (entry.addOrRemove == "Add") {
        if (_session == "Morning") {
          _morningInventoryChanters.newAdditions += entry.count;
          _morningInventoryChanters.closingBalance += entry.count;
        } else {
          _eveningInventoryChanters.newAdditions += entry.count;
          _eveningInventoryChanters.closingBalance += entry.count;
        }
      } else {
        if (_session == "Morning") {
          _morningInventoryChanters.discarded += entry.count;
          _morningInventoryChanters.closingBalance -= entry.count;
        } else {
          _eveningInventoryChanters.discarded += entry.count;
          _eveningInventoryChanters.closingBalance -= entry.count;
        }
      }
    } else {
      if (entry.addOrRemove == "Add") {
        if (_session == "Morning") {
          _morningInventorySales.newAdditions += entry.count;
          _morningInventorySales.closingBalance += entry.count;
        } else {
          _eveningInventorySales.newAdditions += entry.count;
          _eveningInventorySales.closingBalance += entry.count;
        }
      } else {
        if (_session == "Morning") {
          _morningInventorySales.discarded += entry.count;
          _morningInventorySales.closingBalance -= entry.count;
        } else {
          _eveningInventorySales.discarded += entry.count;
          _eveningInventorySales.closingBalance -= entry.count;
        }
      }
    }

    // store to database
    _lastDataModification = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory/$dbdate";
    await FB().addToList(listpath: dbpath, data: entry.toJson());

    // update summary database
    dbpath =
        "${Const().dbrootGaruda}/Harinaam/InventorySummary/$dbdate/$_session/${entry.malaType}";
    Map<String, dynamic> data = await FB().getJson(path: dbpath);
    if (entry.addOrRemove == "Add") {
      data["newAdditions"] += entry.count;
      data["closingBalance"] += entry.count;
    } else {
      data["discarded"] += entry.count;
      data["closingBalance"] -= entry.count;
    }
    await FB().setJson(path: dbpath, json: data);

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createDashboardTables() {
    return Column(
      children: [
        // chanters table
        Table(
          border: TableBorder(
            top: BorderSide(color: Colors.brown),
            bottom: BorderSide(color: Colors.brown),
            left: BorderSide(color: Colors.brown),
            right: BorderSide(color: Colors.brown),
          ),
          columnWidths: {
            0: FlexColumnWidth(1.5), // wider
            1: FlexColumnWidth(1), // narrower
            2: FlexColumnWidth(1), // narrower
          },
          children: [
            // headline
            TableRow(
                decoration: BoxDecoration(
                  color: Colors.brown,
                ),
                children: [
                  Text("Chanters",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center),
                  Text("Morning",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center),
                  Text("Evening",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center)
                ]),

            // opening balance
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Opening balance", textAlign: TextAlign.left),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_morningInventoryChanters.openingBalance.toString(),
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_eveningInventoryChanters.openingBalance.toString(),
                    textAlign: TextAlign.center),
              ),
            ]),

            // New additions
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("New additions", textAlign: TextAlign.left),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_morningInventoryChanters.newAdditions.toString(),
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_eveningInventoryChanters.newAdditions.toString(),
                    textAlign: TextAlign.center),
              ),
            ]),

            // discarded
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Discarded", textAlign: TextAlign.left),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_morningInventoryChanters.discarded.toString(),
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_eveningInventoryChanters.discarded.toString(),
                    textAlign: TextAlign.center),
              ),
            ]),

            // closing balance
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Closing balance", textAlign: TextAlign.left),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_morningInventoryChanters.closingBalance.toString(),
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_eveningInventoryChanters.closingBalance.toString(),
                    textAlign: TextAlign.center),
              ),
            ]),
          ],
        ),

        // sales table
        SizedBox(
          height: 10,
        ),
        Table(
          border: TableBorder(
            top: BorderSide(color: Theme.of(context).colorScheme.primary),
            bottom: BorderSide(color: Theme.of(context).colorScheme.primary),
            left: BorderSide(color: Theme.of(context).colorScheme.primary),
            right: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          columnWidths: {
            0: FlexColumnWidth(1.5), // wider
            1: FlexColumnWidth(1), // narrower
            2: FlexColumnWidth(1), // narrower
          },
          children: [
            // headline
            TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                children: [
                  Text("Sales",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center),
                  Text("Morning",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center),
                  Text("Evening",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(color: Colors.white),
                      textAlign: TextAlign.center)
                ]),

            // opening balance
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Opening balance", textAlign: TextAlign.left),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_morningInventorySales.openingBalance.toString(),
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_eveningInventorySales.openingBalance.toString(),
                    textAlign: TextAlign.center),
              ),
            ]),

            // New additions
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("New additions", textAlign: TextAlign.left),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_morningInventorySales.newAdditions.toString(),
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_eveningInventorySales.newAdditions.toString(),
                    textAlign: TextAlign.center),
              ),
            ]),

            // discarded
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Discarded", textAlign: TextAlign.left),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_morningInventorySales.discarded.toString(),
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_eveningInventorySales.discarded.toString(),
                    textAlign: TextAlign.center),
              ),
            ]),

            // Sales
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Total sales", textAlign: TextAlign.left),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_morningSales.count.toString(),
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_eveningSales.count.toString(),
                    textAlign: TextAlign.center),
              ),
            ]),

            // closing balance
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Closing balance", textAlign: TextAlign.left),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    (_morningInventorySales.closingBalance -
                            _morningSales.count)
                        .toString(),
                    textAlign: TextAlign.center),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    (_eveningInventorySales.closingBalance -
                            _eveningSales.count)
                        .toString(),
                    textAlign: TextAlign.center),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  Widget _createInventoryTile(int index) {
    InventoryEntry entry = _inventoryEntries[index];
    bool isTodaysEntry = DateUtils.isSameDay(entry.timestamp, DateTime.now());

    return Column(
      children: [
        ListTileCompact(
          // count
          leading: Container(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Icon(
                  entry.addOrRemove == "Add"
                      ? Icons.add_circle
                      : Icons.remove_circle,
                  color: entry.malaType == "Chanters"
                      ? Colors.brown
                      : Theme.of(context).colorScheme.primary,
                ),
                Text(entry.count.toString(),
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: entry.malaType == "Chanters"
                            ? Colors.brown
                            : Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),

          // mala type and timestamp
          title: Widgets().createResponsiveRow(
            context,
            [
              Text(
                "[${entry.malaType} mala]",
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: entry.malaType == "Chanters"
                          ? Colors.brown
                          : Theme.of(context).colorScheme.primary,
                    ),
              ),
              Text(DateFormat("dd MMM, yyyy").format(entry.timestamp),
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: entry.malaType == "Chanters"
                            ? Colors.brown
                            : Theme.of(context).colorScheme.primary,
                      )),
            ],
          ),

          // username
          subtitle: Text(
            entry.username,
          ),

          // note
          infotext: entry.note.isNotEmpty ? Text("Note: ${entry.note}") : null,

          // context menu
          trailing: isTodaysEntry
              ? Widgets().createContextMenu(
                  items: ["Edit", "Delete"],
                  onPressed: (String action) {
                    if (action == "Edit") {
                      _showInventoryDialog(entry.addOrRemove, oldEntry: entry);
                    } else if (action == "Delete") {
                      Widgets().showConfirmDialog(
                          context, "Delete this inventory item?", "Delete", () {
                        _deleteInventoryEntry(entry);
                      });
                    }
                  })
              : null,
        ),

        // divider
        if (_inventoryEntries.length > 1) SizedBox(height: 8),
        if (_inventoryEntries.length > 1 &&
            index < _inventoryEntries.length - 1)
          Divider(
            color: Colors.grey.shade300,
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
        if (_inventoryEntries.length > 1) SizedBox(height: 8),
      ],
    );
  }

  Future<Uint8List> _createPdf() async {
    setState(() {
      _isLoading = true;
    });

    // reset table data
    List<String> sevakartasMorning = [];
    List<String> sevakartasEvening = [];

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

    // transform the payment modes
    List<List<String>> morningPaymentModes = [];
    List<List<String>> eveningPaymentModes = [];
    _morningSales.paymentModes.forEach((key, value) {
      morningPaymentModes.add([key, value.toString()]);
    });
    _eveningSales.paymentModes.forEach((key, value) {
      eveningPaymentModes.add([key, value.toString()]);
    });

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
                    [
                      'Opening balance',
                      _morningInventoryChanters.openingBalance
                    ],
                    ['New addition', _morningInventoryChanters.newAdditions],
                    ['Discarded', _morningInventoryChanters.discarded],
                    [
                      'Closing balance',
                      _morningInventoryChanters.closingBalance
                    ]
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
                    ['Opening balance', _morningInventorySales.openingBalance],
                    ['New addition', _morningInventorySales.newAdditions],
                    ['Discarded', _morningInventorySales.discarded],
                    ['Total sales', _morningSales.count],
                    ['Closing balance', _morningInventorySales.closingBalance]
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
                  data: morningPaymentModes,
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
                "Mala sales: $_morningSales",
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
                    [
                      'Opening balance',
                      _eveningInventoryChanters.openingBalance
                    ],
                    ['New addition', _eveningInventoryChanters.newAdditions],
                    ['Discarded', _eveningInventoryChanters.discarded],
                    [
                      'Closing balance',
                      _eveningInventoryChanters.closingBalance
                    ]
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
                    ['Opening balance', _eveningInventorySales.openingBalance],
                    ['New addition', _eveningInventorySales.newAdditions],
                    ['Discarded', _eveningInventorySales.discarded],
                    ['Total sales', _eveningSales.count],
                    ['Closing balance', _eveningInventorySales.closingBalance]
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
                  data: eveningPaymentModes,
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
                "Mala sales: $_eveningSales",
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

  Future<void> _deleteInventoryEntry(InventoryEntry entry) async {
    setState(() {
      _isLoading = true;
    });

    _inventoryEntries.remove(entry);

    // delete from database
    _lastDataModification = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(entry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory/$dbdate";
    List inventoryEntriesRaw = await FB().getList(path: dbpath);
    List<InventoryEntry> inventoryEntries = inventoryEntriesRaw
        .map((e) => Utils().convertRawToDatatype(e, InventoryEntry.fromJson))
        .toList();
    if (inventoryEntries.isEmpty) {
      Toaster().error("No inventory entries found for the date");
    } else {
      inventoryEntries.remove(entry);
      inventoryEntriesRaw = inventoryEntries
          .map((e) => e.toJson())
          .toList(); // convert back to raw format
      await FB().setValue(path: dbpath, value: inventoryEntriesRaw);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _editInventoryEntry(
      InventoryEntry oldEntry, InventoryEntry newEntry) async {
    setState(() {
      _isLoading = true;
    });

    // update the entry in the list
    int index = _inventoryEntries.indexOf(oldEntry);
    if (index != -1) {
      _inventoryEntries[index] = newEntry;

      // update inventory summary
      int delta = newEntry.count - oldEntry.count;
      if (oldEntry.malaType == newEntry.malaType) {
        if (newEntry.malaType == "Chanters") {
          if (newEntry.addOrRemove == "Add") {
            if (_session == "Morning") {
              _morningInventoryChanters.newAdditions += delta;
              _morningInventoryChanters.closingBalance += delta;
            } else {
              _eveningInventoryChanters.newAdditions += delta;
              _eveningInventoryChanters.closingBalance += delta;
            }
          } else {
            if (_session == "Morning") {
              _morningInventoryChanters.discarded += delta;
              _morningInventoryChanters.closingBalance -= delta;
            } else {
              _eveningInventoryChanters.discarded += delta;
              _eveningInventoryChanters.closingBalance -= delta;
            }
          }
        } else {
          if (newEntry.addOrRemove == "Add") {
            if (_session == "Morning") {
              _morningInventorySales.newAdditions += delta;
              _morningInventorySales.closingBalance += delta;
            } else {
              _eveningInventorySales.newAdditions += delta;
              _eveningInventorySales.closingBalance += delta;
            }
          } else {
            if (_session == "Morning") {
              _morningInventorySales.discarded += delta;
              _morningInventorySales.closingBalance -= delta;
            } else {
              _eveningInventorySales.discarded += delta;
              _eveningInventorySales.closingBalance -= delta;
            }
          }
        }
      } else {
        if (newEntry.malaType == "Chanters") {
          if (newEntry.addOrRemove == "Add") {
            if (_session == "Morning") {
              _morningInventorySales.newAdditions -= oldEntry.count;
              _morningInventorySales.closingBalance -= oldEntry.count;

              _morningInventoryChanters.newAdditions += newEntry.count;
              _morningInventoryChanters.closingBalance += newEntry.count;
            } else {
              _eveningInventorySales.newAdditions -= oldEntry.count;
              _eveningInventorySales.closingBalance -= oldEntry.count;

              _eveningInventoryChanters.newAdditions += newEntry.count;
              _eveningInventoryChanters.closingBalance += newEntry.count;
            }
          } else {
            if (_session == "Morning") {
              _morningInventorySales.discarded -= oldEntry.count;
              _morningInventorySales.closingBalance += oldEntry.count;

              _morningInventoryChanters.discarded += newEntry.count;
              _morningInventoryChanters.closingBalance -= newEntry.count;
            } else {
              _eveningInventorySales.discarded -= oldEntry.count;
              _eveningInventorySales.closingBalance += oldEntry.count;

              _eveningInventoryChanters.discarded += newEntry.count;
              _eveningInventoryChanters.closingBalance -= newEntry.count;
            }
          }
        } else {
          if (newEntry.addOrRemove == "Add") {
            if (_session == "Morning") {
              _morningInventoryChanters.newAdditions -= oldEntry.count;
              _morningInventoryChanters.closingBalance -= oldEntry.count;

              _morningInventorySales.newAdditions += newEntry.count;
              _morningInventorySales.closingBalance += newEntry.count;
            } else {
              _eveningInventoryChanters.newAdditions -= oldEntry.count;
              _eveningInventoryChanters.closingBalance -= oldEntry.count;

              _eveningInventorySales.newAdditions += newEntry.count;
              _eveningInventorySales.closingBalance += newEntry.count;
            }
          } else {
            if (_session == "Morning") {
              _morningInventoryChanters.discarded -= oldEntry.count;
              _morningInventoryChanters.closingBalance += oldEntry.count;

              _morningInventorySales.discarded += newEntry.count;
              _morningInventorySales.closingBalance -= newEntry.count;
            } else {
              _eveningInventoryChanters.discarded -= oldEntry.count;
              _eveningInventoryChanters.closingBalance += oldEntry.count;

              _eveningInventorySales.discarded += newEntry.count;
              _eveningInventorySales.closingBalance -= newEntry.count;
            }
          }
        }
      }
    }

    // update in the database
    _lastDataModification = DateTime.now();
    String dbdate = DateFormat("yyyy-MM-dd").format(newEntry.timestamp);
    String dbpath = "${Const().dbrootGaruda}/Harinaam/Inventory/$dbdate";
    List<dynamic> inventoryListRaw = await FB().getList(path: dbpath);
    if (inventoryListRaw.isEmpty) {
      Toaster().error("No inventory entries found for the date");
      return;
    } else {
      List newInventoryListRaw = [];
      for (var inventoryItem in inventoryListRaw) {
        InventoryEntry entry = Utils()
            .convertRawToDatatype(inventoryItem, InventoryEntry.fromJson);
        if (entry.timestamp == oldEntry.timestamp &&
            entry.malaType == oldEntry.malaType &&
            entry.addOrRemove == oldEntry.addOrRemove) {
          // found the entry to update
          newInventoryListRaw.add(newEntry.toJson());
        } else {
          // keep the old entry
          newInventoryListRaw.add(inventoryItem);
        }
      }
      _lastDataModification = DateTime.now();
      await FB().setValue(path: dbpath, value: newInventoryListRaw);
    }

    // update summary database
    if (oldEntry.malaType == newEntry.malaType) {
      // no changes in mala type
      if (_session == "Morning") {
        if (newEntry.malaType == "Chanters") {
          dbpath =
              "${Const().dbrootGaruda}/Harinaam/InventorySummary/$dbdate/Morning/Chanters";
          Map<String, dynamic> data = await FB().getJson(path: dbpath);
          data['newAdditions'] = _morningInventoryChanters.newAdditions;
          data['discarded'] = _morningInventoryChanters.discarded;
          data['closingBalance'] = _morningInventoryChanters.closingBalance;
          await FB().setJson(path: dbpath, json: data);
        } else {
          // Sales mala
          dbpath =
              "${Const().dbrootGaruda}/Harinaam/InventorySummary/$dbdate/Morning/Sales";
          Map<String, dynamic> data = await FB().getJson(path: dbpath);
          data['newAdditions'] = _morningInventorySales.newAdditions;
          data['discarded'] = _morningInventorySales.discarded;
          data['closingBalance'] = _morningInventorySales.closingBalance;
          await FB().setJson(path: dbpath, json: data);
        }
      } else {
        // evening
        if (newEntry.malaType == "Chanters") {
          dbpath =
              "${Const().dbrootGaruda}/Harinaam/InventorySummary/$dbdate/Evening/Chanters";
          Map<String, dynamic> data = await FB().getJson(path: dbpath);
          data['newAdditions'] = _eveningInventoryChanters.newAdditions;
          data['discarded'] = _eveningInventoryChanters.discarded;
          data['closingBalance'] = _eveningInventoryChanters.closingBalance;
          await FB().setJson(path: dbpath, json: data);
        } else {
          // Sales mala
          dbpath =
              "${Const().dbrootGaruda}/Harinaam/InventorySummary/$dbdate/Evening/Sales";
          Map<String, dynamic> data = await FB().getJson(path: dbpath);
          data['newAdditions'] = _eveningInventorySales.newAdditions;
          data['discarded'] = _eveningInventorySales.discarded;
          data['closingBalance'] = _eveningInventorySales.closingBalance;
          await FB().setJson(path: dbpath, json: data);
        }
      }
    } else {
      // mala type changed
      if (_session == "Morning") {
      } else {
        // evening
        if (newEntry.malaType == "Chanters") {
        } else {
          // Sales mala
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<InventorySummary> _getInventorySummary(
      DateTime date, String session, String type) async {
    int openingBalance = 0;
    int discarded = 0;
    int newAdditions = 0;
    int closingBalance = 0;

    String dbdate = DateFormat("yyyy-MM-dd").format(date);
    String dbpath =
        "${Const().dbrootGaruda}/Harinaam/InventorySummary/$dbdate/$session/$type";
    Map<String, dynamic> summaryDataJson =
        await FB().getJson(path: dbpath, silent: true);

    if (summaryDataJson.isEmpty &&
        _session == session &&
        _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year) {
      // if session is evening, check for morning session
      if (session == "Evening") {
        String dbpathTemp =
            "${Const().dbrootGaruda}/Harinaam/InventorySummary/$dbdate/Morning/$type";
        summaryDataJson = await FB().getJson(path: dbpathTemp, silent: true);
        if (summaryDataJson.isEmpty) {
          // ask for current balance
          openingBalance =
              closingBalance = await _showGetCurrentBalanceDialog(type);
        } else {
          // fill the current session
          openingBalance =
              closingBalance = summaryDataJson['closingBalance'] ?? 0;
        }
      }

      // if session is morning, check for previous day's evening session
      if (session == "Morning") {
        String prevDbdate =
            DateFormat("yyyy-MM-dd").format(date.subtract(Duration(days: 1)));
        String dbpathTemp =
            "${Const().dbrootGaruda}/Harinaam/InventorySummary/$prevDbdate/Evening/$type";
        summaryDataJson = await FB().getJson(path: dbpathTemp, silent: true);
        if (summaryDataJson.isEmpty) {
          // ask for current balance
          openingBalance =
              closingBalance = await _showGetCurrentBalanceDialog(type);
        } else {
          // fill the current session
          openingBalance =
              closingBalance = summaryDataJson['closingBalance'] ?? 0;
        }
      }

      // write back to db
      await FB().setValue(path: dbpath, value: {
        'openingBalance': openingBalance,
        'discarded': discarded,
        'newAdditions': newAdditions,
        'closingBalance': closingBalance,
      });
    } else {
      // fill the current session
      openingBalance = summaryDataJson['openingBalance'] ?? 0;
      discarded = summaryDataJson['discarded'] ?? 0;
      newAdditions = summaryDataJson['newAdditions'] ?? 0;
      closingBalance = summaryDataJson['closingBalance'] ?? 0;
    }

    return InventorySummary(
      openingBalance: openingBalance,
      discarded: discarded,
      newAdditions: newAdditions,
      closingBalance: closingBalance,
    );
  }

  Future<SaleData> _getSales(String session) async {
    int sales = 0;
    Map<String, int> paymentModes = {};
    Const().paymentModes.forEach((key, value) {
      paymentModes[key] = 0;
    });
    String dbdate = DateFormat("yyyy-MM-dd").format(_selectedDate);
    String dbpathService =
        "${Const().dbrootGaruda}/Harinaam/ServiceEntries/$dbdate/$session/Sales";
    Map<String, dynamic> salesDataJson =
        await FB().getJson(path: dbpathService, silent: true);
    for (var value in salesDataJson.values) {
      SalesEntry entry =
          Utils().convertRawToDatatype(value, SalesEntry.fromJson);
      sales += entry.count;
      paymentModes[entry.paymentMode] =
          (paymentModes[entry.paymentMode] ?? 0) + entry.count;
    }

    return SaleData(
      count: sales,
      paymentModes: paymentModes,
    );
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

  /// Share the PDF using platform-specific implementation
  Future<void> _sharePdf(Uint8List pdfBytes) async {
    await sharePdf(pdfBytes, filename: 'report.pdf');
  }

  Future<int> _showGetCurrentBalanceDialog(String type) async {
    int currentBalance = 0;
    TextEditingController balanceController =
        TextEditingController(text: currentBalance.toString());
    final formKey = GlobalKey<FormState>();

    await Widgets().showResponsiveDialog(
        context: context,
        title: "Enter $type mala balance",
        child: Form(
          key: formKey,
          child: Column(
            children: [
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Current Balance",
                  border: OutlineInputBorder(),
                ),
                controller: balanceController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a count';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) < 0) {
                    return 'Count cannot be negative';
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
                if (formKey.currentState?.validate() ?? false) {
                  currentBalance = int.parse(balanceController.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Submit")),
        ]);

    return currentBalance;
  }

  Future<void> _showInventoryDialog(String addOrRemove,
      {InventoryEntry? oldEntry}) async {
    final formKey = GlobalKey<FormState>();

    TextEditingController noteController =
        TextEditingController(text: oldEntry?.note ?? "");
    TextEditingController countController =
        TextEditingController(text: oldEntry?.count.toString() ?? "");
    String malaType = oldEntry?.malaType ?? "Chanters";

    Widgets().showResponsiveDialog(
        context: context,
        title: "${oldEntry == null ? addOrRemove : 'Edit'} Inventory",
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // select chanter or sale
              RadioRow(
                  items: ["Chanters", "Sales"],
                  selectedIndex: malaType == "Chanters" ? 0 : 1,
                  onChanged: (String value) {
                    setState(() {
                      malaType = value;
                    });
                  }),

              // count
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Count",
                  border: OutlineInputBorder(),
                ),
                controller: countController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a count';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Count must be greater than 0';
                  }
                  return null;
                },
              ),

              // note
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: "Note",
                  border: OutlineInputBorder(),
                ),
                controller: noteController,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop();

                  UserBasics? userBasics = await Utils().fetchOrGetUserBasics();

                  // create the inventory entry
                  InventoryEntry entry = InventoryEntry(
                    count: int.parse(countController.text),
                    timestamp: DateTime.now(),
                    note: noteController.text,
                    username: userBasics?.name ?? "Unknown",
                    malaType: malaType,
                    addOrRemove: addOrRemove,
                  );

                  if (oldEntry == null) {
                    await _addInventoryEntry(entry);
                  } else {
                    await _editInventoryEntry(oldEntry, entry);
                  }
                }
              },
              child:
                  Text("$addOrRemove${oldEntry == null ? '' : ' (Update)'}")),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ResponsiveScaffold(
          // title
          title: widget.title,

          toolbarActions: [
            // Only show add/discard buttons if today
            if (_isToday) ...[
              // add
              ResponsiveToolbarAction(
                icon: Icon(Icons.add_circle_outline),
                onPressed: () async {
                  await _showInventoryDialog("Add");
                },
              ),

              // discard
              ResponsiveToolbarAction(
                icon: Icon(Icons.remove_circle_outline),
                onPressed: () async {
                  await _showInventoryDialog("Discard");
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
                      // inventory dashboard
                      Widgets().createTopLevelCard(
                          context: context,
                          title: "Dashboard",
                          child: Column(
                            children: [
                              DateHeader(
                                callbacks: DateHeaderCallbacks(
                                    onChange: (DateTime date) {
                                  _selectedDate = date;
                                  refresh();
                                }),
                              ),
                              SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _createDashboardTables(),
                              )
                            ],
                          )),

                      // inventory entries
                      Widgets().createTopLevelCard(
                          context: context,
                          title: "Inventory entries",
                          child: Column(
                            children: [
                              ...List.generate(_inventoryEntries.length,
                                  (index) => _createInventoryTile(index)),
                              if (_inventoryEntries.isEmpty)
                                Text("No inventory entries found.")
                            ],
                          )),

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

class SaleData {
  int count;
  Map<String, int> paymentModes;

  SaleData({
    required this.count,
    required this.paymentModes,
  });
}
