import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vkhillseva/common/utils.dart';

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
    [
      "Amount",
      Utils().formatIndianCurrency("18900"),
      Utils().formatIndianCurrency("0")
    ]
  ];

  // pie chart data
  Map<String, int> countMode = {
    // {mode: count}
    'UPI': 16,
    'Cash': 19,
    'Card': 6,
    'Gift': 0,
  };
  Map<String, int> countModePercentage = {
    // {mode: percentage}
    'UPI': 40,
    'Cash': 45,
    'Card': 15,
  };

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
                      child: Text('37',
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
                        Utils().formatIndianCurrency('18900'),
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

  Widget _wLegends() {
    if (countModePercentage['UPI'] == 0 &&
        countModePercentage['Cash'] == 0 &&
        countModePercentage['Card'] == 0) {
      return const Text("");
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wLegendItem(Colors.orange, 'UPI'),
        _wLegendItem(Colors.green, 'Cash'),
        _wLegendItem(Colors.blue, 'Card'),
      ],
    );
  }

  Widget _wLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  Widget _createModeChart(BuildContext context) {
    double radius = 40;

    if (countModePercentage['UPI'] == 0 &&
        countModePercentage['Cash'] == 0 &&
        countModePercentage['Card'] == 0) {
      return const Text("");
    }

    return PieChart(
      PieChartData(
        sections: [
          // UPI
          PieChartSectionData(
            color: Colors.orange,
            value: countModePercentage['UPI']!.toDouble(),
            title: '${countMode['UPI']}',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: countModePercentage['UPI']! > 9
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge!.color,
            ),
            titlePositionPercentageOffset:
                countModePercentage['UPI']! > 9 ? 0.5 : 1.2,
          ),

          // cash
          PieChartSectionData(
            color: Colors.green,
            value: countModePercentage['Cash']!.toDouble(),
            title: '${countMode['Cash']}',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: countModePercentage['Cash']! > 9
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge!.color,
            ),
            titlePositionPercentageOffset:
                countModePercentage['Cash']! > 9 ? 0.5 : 1.2,
          ),

          // card
          PieChartSectionData(
            color: Colors.blue,
            value: countModePercentage['Card']!.toDouble(),
            title: '${countMode['Card']}',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: countModePercentage['Card']! > 9
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge!.color,
            ),
            titlePositionPercentageOffset:
                countModePercentage['Card']! > 9 ? 0.5 : 1.2,
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 8,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100, // Reduced width
                      height: 100, // Reduced height
                      child: _createModeChart(context),
                    ),
                    const SizedBox(
                        width: 30), // Increased width for more padding
                    _wLegends(),
                  ],
                ),

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
