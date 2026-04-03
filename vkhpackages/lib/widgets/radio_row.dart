import 'package:flutter/material.dart';

class RadioRow extends StatefulWidget {
  final List<String> items;
  final int? selectedIndex;
  final void Function(String) onChanged;
  final Color? color;
  const RadioRow({
    super.key,
    required this.items,
    this.selectedIndex,
    required this.onChanged,
    this.color,
  });

  @override
  State<RadioRow> createState() => RadioRowState();
}

class RadioRowState extends State<RadioRow> {
  String _selectedItem = "";

  @override
  void initState() {
    super.initState();

    if (widget.selectedIndex == -1) {
      _selectedItem = "";
    } else if (widget.selectedIndex != null &&
        widget.selectedIndex! >= 0 &&
        widget.selectedIndex! < widget.items.length) {
      _selectedItem = widget.items[widget.selectedIndex!];
    } else if (widget.items.isNotEmpty) {
      _selectedItem = widget.items.first;
    }
  }

  @override
  dispose() {
    // clear all lists

    // dispose all controllers

    super.dispose();
  }

  void resetSelection() {
    setState(() {
      _selectedItem = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          widget.items.map((item) {
            int index = widget.items.indexOf(item);
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedItem = item;
                  });
                  widget.onChanged(item);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        _selectedItem == item
                            ? widget.color ??
                                Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                    border: Border.all(
                      color:
                          widget.color ?? Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: index == 0 ? Radius.circular(8) : Radius.zero,
                      bottomLeft: index == 0 ? Radius.circular(8) : Radius.zero,
                      topRight:
                          index == widget.items.length - 1
                              ? Radius.circular(8)
                              : Radius.zero,
                      bottomRight:
                          index == widget.items.length - 1
                              ? Radius.circular(8)
                              : Radius.zero,
                    ),
                  ),
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color:
                            _selectedItem == item
                                ? Colors.white
                                : widget.color ??
                                    Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
