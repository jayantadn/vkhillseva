import 'package:flutter/material.dart';

class YearHeader extends StatefulWidget {
  final YearHeaderCallbacks? callbacks;
  final int startYear;
  final bool descending; // when true current year first (default)

  const YearHeader({
    super.key,
    this.callbacks,
    this.startYear = 2020,
    this.descending = true,
  });

  @override
  State<YearHeader> createState() => _YearHeaderState();
}

class _YearHeaderState extends State<YearHeader> {
  late int _currentYear;
  late List<int> _years; // generated from startYear..now
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentYear = DateTime.now().year;
    _buildYearList();
    // Delay to ensure widgets laid out before optional auto scroll
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeScrollToSelected(),
    );
  }

  void _buildYearList() {
    final now = DateTime.now().year;
    final first = widget.startYear;
    final list = <int>[];
    for (int y = first; y <= now; y++) {
      list.add(y);
    }
    _years = widget.descending ? list.reversed.toList() : list;
  }

  void _maybeScrollToSelected() {
    final index = _years.indexOf(_currentYear);
    if (index >= 0) {
      final targetOffset = (index * 90).toDouble(); // approximate item width
      _scrollController.jumpTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  void _select(int year) {
    if (year == _currentYear) return;
    setState(() => _currentYear = year);
    widget.callbacks?.onChange(_currentYear);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children:
              _years
                  .map(
                    (y) => _YearChip(
                      year: y,
                      selected: y == _currentYear,
                      onTap: () => _select(y),
                      theme: theme,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  final int year;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _YearChip({
    required this.year,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final borderColor =
        selected ? baseColor : theme.dividerColor.withOpacity(0.4);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          scale: selected ? 1.06 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 1.2),
              gradient:
                  selected
                      ? LinearGradient(
                        colors: [
                          baseColor.withOpacity(0.95),
                          baseColor.withOpacity(0.70),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              color:
                  selected
                      ? null
                      : theme.colorScheme.surfaceVariant.withOpacity(0.25),
              boxShadow:
                  selected
                      ? [
                        BoxShadow(
                          color: baseColor.withOpacity(0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                      : [],
            ),
            child: Text(
              year.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                color:
                    selected ? onPrimary : theme.textTheme.titleMedium?.color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class YearHeaderCallbacks {
  void Function(int) onChange;
  YearHeaderCallbacks({required this.onChange});
}
