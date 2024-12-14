import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class DaySummary extends StatefulWidget {
  const DaySummary({super.key});

  @override
  State<DaySummary> createState() => _DaySummaryState();
}

GlobalKey<_DaySummaryState> daySummaryKey = GlobalKey<_DaySummaryState>();

class _DaySummaryState extends State<DaySummary> {
  final Lock _lock = Lock();

  @override
  void initState() {
    super.initState();

    refresh();
  }

  void refresh() async {
    await _lock.synchronized(() async {
      // all you need to do
    });

    setState(() {});
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
          // title bar
          Container(
            width: double.infinity, // Stretch to full width
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),

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
                IconButton(
                  icon: Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // Add your share functionality here
                  },
                ),
              ],
            ),
          ),

          // body
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // total tickets sold
                    SizedBox(
                      width: 100, // Set the desired width
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              8.0), // Set the border radius
                        ),
                        child: Column(
                          children: [
                            // total tickets
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8.0)),
                              child: Container(
                                color: Colors
                                    .black, // Dark background for the top row
                                width: double.infinity,
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text('1000',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
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
                          borderRadius: BorderRadius.circular(
                              8.0), // Set the border radius
                        ),
                        child: Column(
                          children: [
                            // total amount
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8.0)),
                              child: Container(
                                color: Colors
                                    .black, // Dark background for the top row
                                width: double.infinity,
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Text(
                                    '₹ 10000',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
