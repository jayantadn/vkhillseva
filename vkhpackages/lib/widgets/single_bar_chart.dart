import 'package:flutter/material.dart';
import 'package:vkhpackages/vkhpackages.dart';

/// A reusable widget that displays a horizontal bar chart with a percentage value.
///
/// The bar chart consists of:
/// - A background bar (grey)
/// - A foreground bar (colored) that fills based on the percentage
/// - A text label overlaid on the bar
///
/// Example usage:
/// ```dart
/// SingleBarChart(
///   initialPercentage: 0.75,
///   initialLabel: "75",
///   height: 24,
/// )
/// ```
class SingleBarChart extends StatefulWidget {
  final double initialPercentage;
  final String initialLabel;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;

  const SingleBarChart({
    super.key,
    required this.initialPercentage,
    required this.initialLabel,
    this.height = 24,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.textStyle,
  });

  @override
  State<SingleBarChart> createState() => SingleBarChartState();
}

class SingleBarChartState extends State<SingleBarChart> {
  late double _percentage;
  late String _label;

  @override
  void initState() {
    super.initState();
    _percentage = widget.initialPercentage;
    _label = widget.initialLabel;
  }

  /// Updates the bar chart with a new percentage and label.
  ///
  /// Parameters:
  /// - [percentage]: A value between 0.0 and 1.0 representing the fill percentage
  /// - [label]: The text to display on the bar
  void updateChart(double percentage, String label) {
    setState(() {
      _percentage = percentage.clamp(0.0, 1.0);
      _label = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? Colors.grey[300]!;
    final foregroundColor =
        widget.foregroundColor ?? Utils().getRandomDarkColor();
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(4);

    return LayoutBuilder(
      builder: (context, constraints) {
        double barWidth = constraints.maxWidth * _percentage;

        return Stack(
          children: [
            // Background bar
            Container(
              height: widget.height,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius,
              ),
            ),
            // Foreground bar (filled portion)
            Container(
              height: widget.height,
              width: barWidth,
              decoration: BoxDecoration(
                color: foregroundColor,
                borderRadius: borderRadius,
              ),
            ),
            // Label text
            Positioned.fill(
              child: Center(
                child: Text(
                  _label,
                  style: widget.textStyle ??
                      TextStyle(
                        color: _percentage > 0.5 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black26,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
