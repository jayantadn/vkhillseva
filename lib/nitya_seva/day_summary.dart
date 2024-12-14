import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:fl_chart/fl_chart.dart';

class DaySummary extends StatefulWidget {
  const DaySummary({super.key});

  @override
  State<DaySummary> createState() => _DaySummaryState();
}

GlobalKey<_DaySummaryState> daySummaryKey = GlobalKey<_DaySummaryState>();

class _DaySummaryState extends State<DaySummary> {
  final Lock _lock = Lock();

  // ticket table data for day summary
  List<String> amountTableHeaderRow = [
    "Seva Ticket",
    "Sat Morning",
    "Sat Evening"
  ];
  List<int> grandTotal = [39, 20300]; // [totalTicket, totalAmount]
  List<List<String>> amountTableTicketRow = [
    ["400", "21", "0"],
    ["500", "14", "0"],
    ["1000", "1", "0"],
    ["2500", "1", "0"],
  ];
  List<List<String>> amountTableTotalRow = [
    ["Total", "37", "0"],
    ["Amount", "18900", "0"]
  ];

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers

    super.dispose();
  }

  void refresh() async {
    await _lock.synchronized(() async {
      // all you need to do
    });

    setState(() {});
  }

  Widget _createTitlebar(BuildContext context) {
    return Container(
      width: double.infinity, // Stretch to full width
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title Text
          Text(
            "Summary",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
          ),

          // Share Button
          GestureDetector(
            child: Icon(Icons.share, color: Colors.white),
            onTap: () {
              // Add your share functionality here
            },
          ),
        ],
      ),
    );
  }

  Widget _createGrandTotal(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // total tickets sold
        SizedBox(
          width: 100, // Set the desired width
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // Set the border radius
            ),
            child: Column(
              children: [
                // total tickets
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(8.0)),
                  child: Container(
                    color: Colors.black, // Dark background for the top row
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text('1000',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  )),
                    ),
                  ),
                ),

                // label
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Total tickets',
                    textAlign: TextAlign.center, // Center the text
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 8), // Add some space between the cards

        // total amount
        SizedBox(
          width: 100, // Set the same width as the first card
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // Set the border radius
            ),
            child: Column(
              children: [
                // total amount
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(8.0)),
                  child: Container(
                    color: Colors.black, // Dark background for the top row
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        '₹ 10000',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ),

                // text label
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Total seva amount',
                    textAlign: TextAlign.center, // Center the text
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _createTicketTable(BuildContext context) {
    if (amountTableHeaderRow.length == 1 || grandTotal[0] == 0) {
      return const Text("no data");
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius:
            BorderRadius.circular(12.0), // Adjust the radius as needed
      ),
      child: Table(
        border: TableBorder(
          top: BorderSide.none,
          bottom: BorderSide.none,
          left: BorderSide.none,
          right: BorderSide.none,
        ), // Remove internal borders
        children: [
          // table header
          TableRow(
            children: amountTableHeaderRow.map((header) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0), // Adjust the padding as needed
                child: Center(
                  child: Text(
                    header,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              );
            }).toList(),
          ),

          // row for entries
          ...amountTableTicketRow.map((row) {
            return TableRow(
              children: row.map((cell) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0), // Adjust the padding as needed
                  child: Center(
                    child: Text(
                      cell.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }).toList(),
            );
          }),

          // row for total
          ...amountTableTotalRow.map((row) {
            return TableRow(
              decoration: amountTableTotalRow.indexOf(row) == 0
                  ? const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey),
                      ),
                    )
                  : null,
              children: row.map((cell) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0), // Adjust the padding as needed
                  child: Center(
                    child: Text(
                      cell.toString(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                );
              }).toList(),
            );
          })
        ],
      ),
    );
  }

  Widget _createModeChart(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 20,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide left titles
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize:
                  40, // Reserve some fixed space for the labels on the right
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(
                      left: 8.0), // Add padding to the left
                  child: Text(
                    value.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22, // Add some reserved size for padding
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding:
                      const EdgeInsets.only(top: 8.0), // Add padding to the top
                  child: Text(
                    value.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Hide top titles
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: 8, color: Colors.lightBlueAccent)],
            showingTooltipIndicators: [0],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: 10, color: Colors.lightBlueAccent)],
            showingTooltipIndicators: [0],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: 14, color: Colors.lightBlueAccent)],
            showingTooltipIndicators: [0],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [BarChartRodData(toY: 15, color: Colors.lightBlueAccent)],
            showingTooltipIndicators: [0],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _createTitlebar(context),

          // body
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                // create chart for payment mode
                SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _createModeChart(context),
                    )),

                SizedBox(height: 8),

                // table for tickets
                _createTicketTable(context),

                SizedBox(height: 8),

                // tiles for total
                _createGrandTotal(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
