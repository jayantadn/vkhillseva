import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:vkhillseva/common/const.dart';
import 'package:vkhillseva/widgets/date_header.dart';
import 'package:vkhillseva/common/fb.dart';
import 'package:vkhillseva/widgets/loading_overlay.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TAS extends StatefulWidget {
  const TAS({super.key, required this.title});

  final String title;

  @override
  State<TAS> createState() => _TASState();
}

class _TASState extends State<TAS> {
  bool _isLoading = true;

  int _editIndex = -1;

  List<String> _gotraList = [];
  List<String> _nakshatraList = [];

  // all controllers and focus nodes
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final TextEditingController _pujariSignatureController =
      TextEditingController();
  final TextEditingController _securitySignatureController =
      TextEditingController();

  TextField _tfGotra = TextField();
  TextField _tfNakshatra = TextField();

  final List<Map<String, String>> _sevakartas = [];
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _gotraList.clear();
    _nakshatraList.clear();

    // clear all controllers and focus nodes
    _nameController.dispose();
    _nameFocusNode.dispose();
    _pujariSignatureController.dispose();
    _securitySignatureController.dispose();

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // read config
    DatabaseReference dbref =
        FirebaseDatabase.instance.ref("${Const().dbroot}/Settings");
    DataSnapshot snapshot = await dbref.child("GotraList").get();
    if (snapshot.value != null) {
      _gotraList = List<String>.from(snapshot.value as List);
    }
    snapshot = await dbref.child("NakshatraList").get();
    if (snapshot.value != null) {
      _nakshatraList = List<String>.from(snapshot.value as List);
    }

    // read sevakartas for today
    _sevakartas.clear();
    dbref = FirebaseDatabase.instance.ref("${Const().dbroot}/TAS/DataEntries");
    String date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    snapshot = await dbref.child("$date/Sevakartas").get();
    if (snapshot.value != null) {
      List<dynamic> entries = snapshot.value as List;
      for (var entry in entries) {
        _sevakartas.add({
          "Name": entry["Name"],
          "Gotra": entry["Gotra"],
          "Nakshatra": entry["Nakshatra"]
        });
      }
    }

    // read signatures from database
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    var data = await FB()
        .getValue(path: "TAS/DataEntries/$formattedDate/pujariSignature");
    if (data != null) {
      _pujariSignatureController.text = data['Signature'];
    } else {
      _pujariSignatureController.text = "";
    }
    data = await FB()
        .getValue(path: "TAS/DataEntries/$formattedDate/securitySignature");
    if (data != null) {
      _securitySignatureController.text = data['Signature'];
    } else {
      _securitySignatureController.text = "";
    }

    setState(() {
      _isLoading = false;
    });
  }

  _createConfirmationDialog(context, index) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this sevakarta?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                setState(() {
                  _editIndex = -1;
                  _sevakartas.removeAt(index);
                });

                // clear form
                _nameController.clear();
                _tfGotra.controller!.clear();
                _tfNakshatra.controller!.clear();
                FocusScope.of(context).unfocus();

                _updateSevakartasFB();

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateGotraListFB() async {
    final dbref =
        FirebaseDatabase.instance.ref("${Const().dbroot}/Settings/GotraList");

    await dbref.set(_gotraList);
  }

  Future<void> _updateNakshatraListFB() async {
    final dbref = FirebaseDatabase.instance
        .ref("${Const().dbroot}/Settings/NakshatraList");

    await dbref.set(_nakshatraList);
  }

  Future<void> _updateSevakartasFB() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dbref = FirebaseDatabase.instance
        .ref("${Const().dbroot}/TAS/DataEntries/$formattedDate/Sevakartas");

    await dbref.set(_sevakartas);
  }

  Widget _createHMI(BuildContext context) {
    Widget nameField = TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      decoration: InputDecoration(labelText: 'Name'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );

    Widget gotraField = TypeAheadField<String>(
      hideOnEmpty: true,
      suggestionsCallback: (search) {
        if (search.isEmpty) {
          return [];
        }

        return _gotraList
            .where(
                (gotra) => gotra.toUpperCase().contains(search.toUpperCase()))
            // .take(5)
            .toList();
      },
      builder: (context, controller, focusNode) {
        _tfGotra = TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Gotra',
            ));

        return _tfGotra;
      },
      itemBuilder: (context, gotra) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(gotra),
        );
      },
      onSelected: (gotra) {
        _tfGotra.controller!.text = gotra;
      },
    );

    Widget nakshatraField = TypeAheadField<String>(
      hideOnEmpty: true,
      suggestionsCallback: (search) {
        if (search.isEmpty) {
          return [];
        }

        return _nakshatraList
            .where((nakshatra) =>
                nakshatra.toUpperCase().contains(search.toUpperCase()))
            // .take(5)
            .toList();
      },
      builder: (context, controller, focusNode) {
        _tfNakshatra = TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Nakshatra',
            ));

        return _tfNakshatra;
      },
      itemBuilder: (context, nakshatra) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(nakshatra),
        );
      },
      onSelected: (nakshatra) {
        _tfNakshatra.controller!.text = nakshatra;
      },
    );

    void submit() {
      String gotra = _tfGotra.controller!.text.toUpperCase();
      String nakshatra = _tfNakshatra.controller!.text.toUpperCase();

      if (_formKey.currentState!.validate()) {
        setState(() {
          if (_editIndex != -1) {
            _sevakartas[_editIndex] = {
              "Name": _nameController.text,
              "Gotra": gotra,
              "Nakshatra": nakshatra
            };
            _editIndex = -1;
          } else {
            _sevakartas.insert(0, {
              "Name": _nameController.text,
              "Gotra": gotra,
              "Nakshatra": nakshatra
            });
          }
        });

        if (!_gotraList.contains(gotra)) {
          _gotraList.add(gotra);
          _gotraList.sort();

          _updateGotraListFB();
        }

        if (!_nakshatraList.contains(nakshatra)) {
          _nakshatraList.add(nakshatra);
          _nakshatraList.sort();

          _updateNakshatraListFB();
        }

        _updateSevakartasFB();

        _nameController.clear();
        _tfGotra.controller!.clear();
        _tfNakshatra.controller!.clear();

        // Release focus from all text fields
        FocusScope.of(context).unfocus();
      }
    }

    Widget addButton = ElevatedButton(
      child: _editIndex == -1 ? Text("Submit") : Text("Update"),
      onPressed: () {
        HapticFeedback.mediumImpact();
        submit();
      },
    );

    Widget clearButton = OutlinedButton(
      child: Text("Clear"),
      onPressed: () {
        HapticFeedback.mediumImpact();
        setState(() {
          _nameController.clear();
          _tfGotra.controller!.clear();
          _tfNakshatra.controller!.clear();
          _editIndex = -1;
          FocusScope.of(context).unfocus();
        });
      },
    );

    Widget buttons = Row(
      children: [
        addButton,
        SizedBox(width: 8),
        clearButton,
      ],
    );

    bool isMobile = MediaQuery.of(context).size.width < 600;

    List<Widget> widgets = [
      // name
      isMobile
          ? nameField
          : Expanded(
              flex: 2,
              child: nameField,
            ),

      SizedBox(
        width: isMobile ? 0 : 8,
        height: isMobile ? 8 : 0,
      ),

      // // Gotra
      isMobile
          ? gotraField
          : Expanded(
              child: gotraField,
            ),

      SizedBox(
        width: isMobile ? 0 : 8,
        height: isMobile ? 8 : 0,
      ),

      // Nakshatra
      isMobile
          ? nakshatraField
          : Expanded(
              child: nakshatraField,
            ),

      SizedBox(
        width: isMobile ? 0 : 8,
        height: isMobile ? 8 : 0,
      ),

      // buttons
      buttons
    ];

    return isMobile ? Column(children: widgets) : Row(children: widgets);
  }

  void _createPdf() async {
    setState(() {
      _isLoading = true;
    });

    final pdf = pw.Document();
    final tableHeaders = ['Sl', 'Name', 'Gotra', 'Nakshatra'];

    String formattedDate = DateFormat('dd MMM, yyyy').format(_selectedDate);

    List sevakartasReversed = List.from(_sevakartas);
    sevakartasReversed.sort((a, b) => b["Name"]!.compareTo(a["Name"]!));

    final tableData = sevakartasReversed.asMap().entries.map((entry) {
      int index = entry.key;
      var sevakarta = entry.value;
      return [
        index + 1,
        sevakarta["Name"]!,
        sevakarta["Gotra"] ?? "",
        sevakarta["Nakshatra"] ?? ""
      ];
    }).toList();

    String pujariTime = "";
    String securityTime = "";
    String dbDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    dynamic data = await FB()
        .getValue(path: "TAS/DataEntries/$dbDate/pujariSignature/Timestamp");
    if (data != null) {
      DateTime parsedData = DateTime.parse(data.toString());
      pujariTime = DateFormat('dd MMM, yyyy - HH:mm').format(parsedData);
    }
    data = await FB()
        .getValue(path: "TAS/DataEntries/$dbDate/securitySignature/Timestamp");
    if (data != null) {
      DateTime parsedData = DateTime.parse(data.toString());
      securityTime = DateFormat('dd MMM, yyyy - HH:mm').format(parsedData);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // header
              pw.Center(
                child: pw.Text(
                  'Tulasi Archana Seva',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  formattedDate,
                  style: pw.TextStyle(fontSize: 16),
                ),
              ),

              pw.SizedBox(height: 16),

              // table of sevakartas
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: tableHeaders.map((header) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(header,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                  ...tableData.map((row) {
                    return pw.TableRow(
                      children: row.map((cell) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(cell.toString()),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),

              // signature boxes
              pw.SizedBox(height: 100),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text("Pujari signature: ",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_pujariSignatureController.text),
                      pw.Text(pujariTime)
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text("Security signature: ",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(_securitySignatureController.text),
                      pw.Text(securityTime)
                    ],
                  )
                ],
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    setState(() {
      _isLoading = false;
    });

    formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    await Printing.sharePdf(
        bytes: pdfBytes, filename: 'TAS_$formattedDate.pdf');
  }

  Widget _createSevakartasList(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: _sevakartas.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Dismissible(
                key: Key(_sevakartas[index]["Name"]!),
                background: Container(
                  color: Colors.blue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                          icon: Icon(Icons.edit, color: Colors.white),
                          onPressed: null),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                          icon: Icon(Icons.delete, color: Colors.white),
                          onPressed: null),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  HapticFeedback.mediumImpact();
                  if (direction == DismissDirection.endToStart) {
                    _createConfirmationDialog(context, index);
                  } else {
                    HapticFeedback.mediumImpact();

                    setState(() {
                      _nameController.text = _sevakartas[index]["Name"]!;
                      _tfGotra.controller!.text = _sevakartas[index]["Gotra"]!;
                      _tfNakshatra.controller!.text =
                          _sevakartas[index]["Nakshatra"]!;
                      _editIndex = index;
                    });
                  }
                  return false;
                },
                child: ListTile(
                  // count
                  leading: Text(
                    "${_sevakartas.length - index}",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),

                  // name
                  title: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(_sevakartas[index]["Name"]!),
                  ),

                  // gotra, nakshatra
                  subtitle: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_sevakartas[index]["Gotra"]!.isNotEmpty) ...[
                          Text(
                            "Gotra: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("${_sevakartas[index]["Gotra"]!} "),
                        ],
                        if (_sevakartas[index]["Nakshatra"]!.isNotEmpty) ...[
                          Text(
                            ", Nakshatra: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_sevakartas[index]["Nakshatra"]!),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
              Divider(), // Bottom border
            ],
          );
        },
      ),
    );
  }

  void _createSignatureDialog() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Signatures"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _pujariSignatureController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Pujari',
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _securitySignatureController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Security',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                FB().setValue(
                  path: "TAS/DataEntries/$formattedDate/pujariSignature",
                  value: {
                    "Signature": _pujariSignatureController.text,
                    "Timestamp": DateTime.now().toString()
                  },
                );
                FB().setValue(
                  path: "TAS/DataEntries/$formattedDate/securitySignature",
                  value: {
                    "Signature": _securitySignatureController.text,
                    "Timestamp": DateTime.now().toString()
                  },
                );
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              // signatures
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: _createSignatureDialog,
              ),

              // create pdf
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: _createPdf,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // date header
                  DateHeader(
                    callbacks: DateHeaderCallbacks(onChange: (DateTime date) {
                      setState(() {
                        _selectedDate = date;
                        refresh();
                      });
                    }),
                  ),

                  // HMI
                  _createHMI(context),

                  Divider(),

                  // List of sevakartas
                  _createSevakartasList(context),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          LoadingOverlay(
            image: "assets/images/NityaSeva/tas.png",
          ),
      ],
    );
  }
}
