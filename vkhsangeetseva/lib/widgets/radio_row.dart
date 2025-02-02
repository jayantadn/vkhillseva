import 'package:flutter/material.dart';
import 'package:vkhsangeetseva/common/theme.dart';

class RadioRow extends StatefulWidget {
  final List<String> items;
  final void Function(String) onChanged;
  const RadioRow({super.key, required this.items, required this.onChanged});

  @override
  State<RadioRow> createState() => _RadioRowState();
}

class _RadioRowState extends State<RadioRow> {
  String _selectedItem = "";

  @override
  void initState() {
    super.initState();

    _selectedItem = widget.items.first;
  }

  @override
  dispose() {
    // clear all lists

    // dispose all controllers

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.items.map((item) {
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
                color: _selectedItem == item ? accentColor : Colors.transparent,
                border: Border.all(color: accentColor),
                borderRadius: BorderRadius.only(
                  topLeft: index == 0 ? Radius.circular(8) : Radius.zero,
                  bottomLeft: index == 0 ? Radius.circular(8) : Radius.zero,
                  topRight: index == widget.items.length - 1
                      ? Radius.circular(8)
                      : Radius.zero,
                  bottomRight: index == widget.items.length - 1
                      ? Radius.circular(8)
                      : Radius.zero,
                ),
              ),
              padding: EdgeInsets.all(8),
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: _selectedItem == item ? Colors.white : accentColor,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
