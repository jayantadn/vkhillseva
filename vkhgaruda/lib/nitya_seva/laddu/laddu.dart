import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/nitya_seva/laddu/avilability_bar.dart';
import 'package:vkhgaruda/nitya_seva/laddu/datatypes.dart';
import 'package:vkhgaruda/nitya_seva/laddu/fbl.dart';
import 'package:vkhgaruda/nitya_seva/laddu/laddu_calc.dart';
import 'package:vkhgaruda/nitya_seva/laddu/laddu_settings.dart';
import 'package:vkhgaruda/nitya_seva/laddu/log.dart';
import 'package:vkhgaruda/nitya_seva/laddu/service_select.dart';
import 'package:vkhgaruda/nitya_seva/laddu/summary.dart';
import 'package:vkhgaruda/nitya_seva/laddu/utils.dart';
import 'package:intl/intl.dart';
import 'package:vkhpackages/vkhpackages.dart';

class LadduMain extends StatefulWidget {

  const LadduMain({super.key});


  @override
  _LadduSevaState createState() => _LadduSevaState();
}

class _LadduSevaState extends State<LadduMain> {
  LadduReturn? _lr;
  final Lock _lock = Lock();
  bool _isLoading = true;
  Map<String, dynamic>? _sessionData;

  // final GlobalKey<AvailabilityBarState> _keyAvailabilityBar =
  //     GlobalKey<AvailabilityBarState>();

  @override
  initState() {
    super.initState();

    refresh().then((data) async {
      await _ensureReturn(context);

      // FBL().listenForChange("LadduSeva",
      //     FBLCallbacks(onChange: (String changeType, dynamic data) async {
      //   await refresh();
      // }));
    });
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here

      // read database and populate data
      _sessionData = await FBL().readLatestLadduSessionData();
      _lr = readLadduReturnStatus(_sessionData);
    });

    // refresh all child widgets

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      setState(() {});
    }

  }

  Widget _createReturnTile(LadduReturn lr) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ListTile(
          // title
          title: Text(
            DateFormat('dd-MM-yyyy HH:mm:ss').format(lr.timestamp),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF8A0303)),
          ),

          // icon
          leading: Icon(Icons.undo, color: Color(0xFF8A0303)),

          // body
          subtitle: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sevakarta: ${lr.user}',
                  style: TextStyle(color: Color(0xFF8A0303)),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Laddu packs returned: ${lr.count}',
                  style: TextStyle(color: Color(0xFF8A0303)),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Returned to: ${lr.to}',
                  style: TextStyle(color: Color(0xFF8A0303)),
                ),
              ),
            ],
          ),

          // the count
          trailing: Container(
            padding: EdgeInsets.all(8.0), // Add padding around the text
            decoration: BoxDecoration(
              color: Colors.red[50], // Change background color to red
              border: Border.all(
                  color: Color(0xFF8A0303), width: 2.0), // Add a border
              borderRadius:
                  BorderRadius.circular(12.0), // Make the border circular
            ),
            child: Text(
              lr.count.toString(),
              style: TextStyle(
                  fontSize: 18.0,
                  color: Color(0xFF8A0303)), // Increase the font size
            ),
          ),

          // on tap
          onTap: () async {
            returnStock(context, lr: lr);
          }),
    );
  }

  void _createServeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ServiceSelect();
      },
    );
  }  

  Future<void> _ensureReturn(BuildContext context) async {
    if (_lr == null || _lr!.count == -1) {
      // session in progress

      List<LadduServe> serves = readLadduServes(_sessionData);

      // check if last serve is more than 2 days old
      if (serves.isNotEmpty &&
          serves.last.timestamp
              .isBefore(DateTime.now().subtract(Duration(days: 2)))) {
        // total stock
        List<LadduStock> stocks = readLadduStocks(_sessionData);
        stocks.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (stocks.isEmpty) {
          return;
        }
        int totalStock = stocks.fold(
            0, (previousValue, element) => previousValue + element.count);

        // total serve
        int totalServe = 0;
        for (var serve in serves) {
          totalServe += CalculateTotalLadduPacksServed(serve);
        }

        int remaining = totalStock - totalServe;
        if (remaining < 0) {
          remaining = 0;
        }

        await FBL().returnLadduStock(
            
            LadduReturn(
                timestamp: DateTime.now(),
                count: remaining,
                to: "Unknown",
                user: "Auto Return"));

        Toaster().info("Auto returned");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          title: Text('Laddu distribution'),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LadduSettings()),
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: refresh,

          // here a ListView is used to allow the content to be scrollable and refreshable.
          // If you use ListView.builder inside this, then the ListView here can be removed.
          child: ListView(
            children: [
              AvailabilityBar(
                  key: AvailabilityBarKey, sessionData: _sessionData ?? {}),

              Divider(),
              Summary(key: SummaryKey, sessionData: _sessionData ?? {}),

              // button row
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // stock button
                  ElevatedButton.icon(
                    onPressed: () async {
                      addEditStock(context);
                    },
                    icon: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    label: Text('Stock'),
                  ),
      
                  // serve button
                  ElevatedButton.icon(
                    onPressed: (_lr == null || _lr!.count == -1)
                        ? () async {
                            _createServeDialog(context);
                          }
                        : null,
                    icon: Icon(Icons.remove, color: Colors.white),
                    label: Text('Serve'),
                  ),
      
                  // return button
                  ElevatedButton.icon(
                    onPressed: (_lr == null || _lr!.count == -1)
                        ? () {
                            returnStock(context);
                          }
                        : null,
                    icon: Icon(Icons.undo, color: Colors.white),
                    label: Text('Return'),
                  )
                ],
              ),

              Divider(),

              // if session is closed, display a message and the return tile
              if (_lr != null && _lr!.count >= 0)
                Column(
                  children: [
                    Text(
                      "Click '+ Stock' to start new session",
                      style: TextStyle(color: Colors.red, fontSize: 20.0),
                    ),
                    Divider(),
                    _createReturnTile(_lr!),
                    Divider(),
                  ],
                ),

              Log(key: LogKey),
            ],
          ),
        ),
      ),
    
      // circular progress indicator
      if (_isLoading) LoadingOverlay(),
    ]);
  }
}
