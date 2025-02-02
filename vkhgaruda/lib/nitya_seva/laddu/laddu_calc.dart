import 'package:flutter/material.dart';
import 'package:vkhgaruda/nitya_seva/laddu/datatypes.dart';
import 'package:vkhgaruda/nitya_seva/laddu/fbl.dart';
import 'package:vkhgaruda/nitya_seva/laddu/utils.dart';
import 'package:vkhgaruda/common/toaster.dart';
import 'package:vkhgaruda/common/utils.dart';

String selectedPurpose = "Others";
bool selectedPurposeChanged = false;

class AddEditStockDialog extends StatefulWidget {
  final bool edit;
  final LadduStock? stock;
  final DateTime? session;

  const AddEditStockDialog(
      {super.key, required this.edit, this.stock, this.session});

  @override
  _AddEditStockDialogState createState() => _AddEditStockDialogState();
}

class _AddEditStockDialogState extends State<AddEditStockDialog> {
  String from = "";
  int procured = 0;
  bool isLoading = false;
  String sessionName = '';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.edit && widget.stock != null) {
      from = widget.stock!.from;
      procured = widget.stock!.count;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.edit ? Text('Edit Stock') : Text('Add Stock'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // text input for collected from
            TextFormField(
              decoration: InputDecoration(labelText: 'From'),
              onChanged: (value) {
                from = value;
              },
              controller: TextEditingController(
                text: widget.edit ? widget.stock!.from : '',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a valid name';
                }
                return null;
              },
            ),

            // text input for packs procured
            TextFormField(
              decoration: InputDecoration(labelText: 'Packs procured'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (value.isNotEmpty) procured = int.parse(value);
              },
              controller: TextEditingController(
                text: widget.edit ? widget.stock!.count.toString() : '',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a valid number';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a value greater than 0';
                }
                return null;
              },
            ),

            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        // delete button
        if (widget.edit)
          ElevatedButton(
            onPressed: () async {
              DateTime session =
                  widget.session ?? await FBL().readLatestLadduSession();

              // check if this is the only stock entry
              List<LadduStock> stocks = await FBL().readLadduStocks(session);
              if (stocks.length == 1) {
                Toaster().error("Cannot delete the only stock entry");
                return;
              }

              // confirm delete
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Confirmation'),
                    content: Text('Are you sure you want to delete?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // Return false
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true); // Return true
                        },
                        child: Text('Confirm'),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                setState(() {
                  isLoading = true;
                });

                await FBL().deleteLadduStock(session, widget.stock!);

                setState(() {
                  isLoading = false;
                });

                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Set the background color to red
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            ),
            child: Text('Delete'),
          ),

        // cancel button
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          ),
          child: Text('Cancel'),
        ),

        // add/edit stock button
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              setState(() {
                isLoading = true;
              });

              String username = Utils().getUsername();

              LadduStock stockNew;
              if (widget.edit) {
                stockNew = LadduStock(
                  timestamp: widget.stock!.timestamp,
                  user: widget.stock!.user,
                  from: from,
                  count: procured,
                );
              } else {
                stockNew = LadduStock(
                  timestamp: DateTime.now(),
                  user: username,
                  from: from,
                  count: procured,
                );
              }

              DateTime session;
              bool status;

              if (widget.edit) {
                session =
                    widget.session ?? await FBL().readLatestLadduSession();
                status = await FBL().editLadduStock(session, stockNew);
              } else {
                // check if session is already running
                session = await FBL().readLatestLadduSession();
                LadduReturn lr = await FBL().readLadduReturnStatus(session);

                if (lr.count >= 0) {
                  // session is closed. create new one.
                  session = await FBL().addLadduSession();
                }

                status = await FBL().addLadduStock(session, stockNew);
              }

              setState(() {
                isLoading = false;
              });

              if (status) {
                Toaster().info("Added successfully");
              } else {
                Toaster().error("Add failed");
              }

              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          ),
          child: Text(widget.edit ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

Future<void> addEditStock(BuildContext context,
    {bool edit = false, LadduStock? stock, DateTime? session}) async {
  showDialog(
    context: context,
    builder: (context) {
      return AddEditStockDialog(edit: edit, stock: stock, session: session);
    },
  );
}

Future<void> returnStock(BuildContext context, {LadduReturn? lr}) async {
  DateTime session = await FBL().readLatestLadduSession();

  List<LadduStock> stocks = await FBL().readLadduStocks(session);
  stocks.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  List<LadduServe> serves = await FBL().readLadduServes(session);
  serves.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  if (stocks.isEmpty) {
    Toaster().error("No stock available");
    return;
  }

  DateTime lastEntry = stocks.last.timestamp;
  if (serves.isNotEmpty && serves.last.timestamp.isAfter(lastEntry)) {
    lastEntry = serves.last.timestamp;
  }

  // sum of all stocks
  int totalStock =
      stocks.fold(0, (previousValue, element) => previousValue + element.count);

  // sum of all distributions
  int totalServe = 0;
  for (var serve in serves) {
    totalServe += CalculateTotalLadduPacksServed(serve);
  }

  int remaining = totalStock - totalServe;

  await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return ReturnStockDialog(
        session: session,
        totalStock: totalStock,
        totalServe: totalServe,
        remaining: remaining,
        lr: lr,
      );
    },
  );
}

// ignore: must_be_immutable
class ReturnStockDialog extends StatefulWidget {
  final DateTime session;
  final int totalStock;
  final int totalServe;
  int remaining;
  String returnedTo;
  int returnCount;
  LadduReturn? lr;

  ReturnStockDialog({
    super.key,
    required this.session,
    required this.totalStock,
    required this.totalServe,
    required this.remaining,
    this.returnedTo = '',
    this.returnCount = 0,
    this.lr,
  });

  @override
  _ReturnStockDialogState createState() => _ReturnStockDialogState();
}

class _ReturnStockDialogState extends State<ReturnStockDialog> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>(); // required for form valudation

  @override
  void initState() {
    super.initState();
    if (widget.lr != null) {
      widget.returnCount = widget.lr!.count;
    } else {
      widget.returnCount = widget.remaining;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Return laddu stock'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextFormField(
                  controller: TextEditingController(
                      text: widget.lr != null ? widget.lr!.to : ''),
                  decoration: InputDecoration(
                    labelText: 'Returned to',
                  ),
                  onChanged: (value) {
                    widget.returnedTo = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: TextEditingController(
                      text: widget.lr != null
                          ? widget.lr!.count.toString()
                          : widget.remaining.toString()),
                  decoration: InputDecoration(
                    labelText: 'Packs returned',
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) widget.returnCount = int.parse(value);
                  },
                ),
              ),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        // cancel button
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          ),
          child: Text('Cancel'),
        ),

        // confirm button
        ElevatedButton(
          onPressed: _isLoading ? null : _confirm,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          ),
          child: Text(widget.lr != null ? 'Update' : 'Return'),
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    // validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (widget.returnCount > widget.remaining) {
      Toaster().error("Not available");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String username = Utils().getUsername();

    await FBL().returnLadduStock(
        widget.session,
        LadduReturn(
            timestamp: DateTime.now(),
            count: widget.returnCount,
            to: widget.returnedTo,
            user: username));

    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).pop(true);
  }
}
