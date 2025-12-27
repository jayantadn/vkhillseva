import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class KVTable extends StatefulWidget {
  final List<MapEntry<String, String>>? initialRows;

  const KVTable({super.key, this.initialRows});

  @override
  State<KVTable> createState() => KVTableState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<KVTableState> _keyKVTable = GlobalKey<KVTableState>();

class KVTableState extends State<KVTable> {
  final Lock _lock = Lock();
  final List<MapEntry<String, String>> _rows = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialRows != null) {
      _rows.addAll(widget.initialRows!);
    }
    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _rows.clear();

    super.dispose();
  }

  /// Add a new row to the table
  Future<void> addRow(String key, String value) async {
    await _lock.synchronized(() async {
      _rows.add(MapEntry(key, value));
      setState(() {});
    });
  }

  /// Add multiple rows to the table
  Future<void> addRows(List<MapEntry<String, String>> rows) async {
    await _lock.synchronized(() async {
      _rows.addAll(rows);
      setState(() {});
    });
  }

  /// Replace all rows in the table with new rows
  Future<void> setRows(List<MapEntry<String, String>> rows) async {
    await _lock.synchronized(() async {
      _rows.clear();
      _rows.addAll(rows);
      setState(() {});
    });
  }

  /// Clear all rows from the table
  Future<void> clearRows() async {
    await _lock.synchronized(() async {
      _rows.clear();
      setState(() {});
    });
  }

  /// Remove a specific row by index
  Future<void> removeRowAt(int index) async {
    await _lock.synchronized(() async {
      if (index >= 0 && index < _rows.length) {
        _rows.removeAt(index);
        setState(() {});
      }
    });
  }

  Future<void> refresh() async {
    await _lock.synchronized(() async {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children:
          _rows.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            final isLastRow = index == _rows.length - 1;

            return TableRow(
              decoration: BoxDecoration(
                border:
                    isLastRow
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
