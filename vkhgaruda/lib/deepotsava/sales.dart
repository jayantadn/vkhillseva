import 'package:flutter/material.dart';
import 'package:vkhgaruda/deepotsava/dashboard.dart';
import 'package:vkhgaruda/deepotsava/datatypes.dart';
import 'package:vkhgaruda/deepotsava/hmi.dart';
import 'package:vkhgaruda/deepotsava/log.dart';
import 'package:vkhgaruda/deepotsava/stats.dart';
import 'package:vkhgaruda/deepotsava/stock.dart';
import 'package:vkhgaruda/deepotsava/themeDeepotsava.dart';
import 'package:vkhpackages/widgets/date_header.dart';

class Sales extends StatefulWidget {
  final String stall;

  const Sales({super.key, required this.stall});

  @override
  _SalesState createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  @override
  initState() {
    super.initState();

    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  Widget _createCardPage() {
    return Card(
      child: SizedBox(
        height: 150.0,
        child: PageView(
          children: [
            StockPage(stall: widget.stall),
            StatsPage(stall: widget.stall),
          ],
        ),
      ),
    );
  }

  Future<void> serveLamps(DeepamSale sale) async {
    if (mounted) {
      dashboardKey.currentState!.addLampsServed(sale);
      logKey.currentState!.addLog(sale);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Select theme based on the value of stall
    ThemeData selectedTheme;
    if (widget.stall == 'RRG') {
      selectedTheme = themeRRG;
    } else if (widget.stall == 'RKC') {
      selectedTheme = themeRKC;
    } else {
      selectedTheme = themeDefault;
    }

    return Theme(
      data: selectedTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.stall} Deepam Sales'),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,

          // here a ListView is used to allow the content to be scrollable and refreshable.
          // If you use ListView.builder inside this, then the ListView here can be removed.
          child: ListView(
            children: [
              DateHeader(),
              _createCardPage(),
              Dashboard(key: dashboardKey, stall: widget.stall),
              HMI(
                  stall: widget.stall,
                  callbacks: HMICallbacks(add: serveLamps)),
              Log(key: logKey, stall: widget.stall),
            ],
          ),
        ),
      ),
    );
  }
}
