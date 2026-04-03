import 'package:flutter/material.dart';

/// A controlled key-value table widget.
///
/// - Provide rows via the [rows] parameter.
/// - The widget re-renders with new values whenever the parent rebuilds
///   and supplies a different [rows] list.
/// - No internal mutation APIs (addRows, setRows, etc.); state is owned by the parent.
class KVTable extends StatelessWidget {
  final List<MapEntry<String, String>> rows;
  final bool noborder;

  const KVTable({super.key, required this.rows, this.noborder = false});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children:
          rows.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final isLastRow = index == rows.length - 1;

            return TableRow(
              decoration: BoxDecoration(
                border:
                    noborder || isLastRow
                        ? null
                        : const Border(
                          bottom: BorderSide(color: Colors.grey, width: 1.0),
                        ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(entry.value),
                ),
              ],
            );
          }).toList(),
    );
  }
}
