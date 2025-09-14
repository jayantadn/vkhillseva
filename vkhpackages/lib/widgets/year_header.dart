import 'package:flutter/material.dart';

class YearHeader extends StatefulWidget {
  final void Function(int)? onYearChanged;
  final int startYear;
  final bool descending; // when true current year first (default)

  const YearHeader({
    super.key,
    this.onYearChanged,
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
  bool _showLeftFade = false;
  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    _currentYear = DateTime.now().year;
    _buildYearList();
    // Delay to ensure widgets laid out before optional auto scroll
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeScrollToSelected(),
    );
    _scrollController.addListener(_updateFades);
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
    _updateFades();
  }

  void _updateFades() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final left = offset > 4;
    final right = (max - offset) > 4;
    if (left != _showLeftFade || right != _showRightFade) {
      setState(() {
        _showLeftFade = left;
        _showRightFade = right;
      });
    }
  }

  void _select(int year) {
    if (year == _currentYear) return;
    setState(() => _currentYear = year);
    widget.onYearChanged?.call(_currentYear);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;
    final primary = theme.colorScheme.primary;
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              // Subtle primary-tinted gradient background
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withOpacity(0.12),
                  primary.withOpacity(0.05),
                  primary.withOpacity(0.08),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  _updateFades();
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
              ),
            ),
          ),
          if (_showLeftFade)
            Positioned(
              left: 8,
              top: 4,
              bottom: 4,
              width: 28,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(32),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [bg.withOpacity(0.85), bg.withOpacity(0.0)],
                    ),
                  ),
                ),
              ),
            ),
          if (_showRightFade)
            Positioned(
              right: 8,
              top: 4,
              bottom: 4,
              width: 28,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(32),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [bg.withOpacity(0.85), bg.withOpacity(0.0)],
                    ),
                  ),
                ),
              ),
            ),
        ],
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
        selected ? baseColor : theme.dividerColor.withOpacity(0.35);
    return Padding(
      // Further reduced vertical padding
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          // Reduced internal padding
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
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
          child: Center(
            child: Text(
              year.toString(),
              strutStyle: const StrutStyle(height: 1.3, leading: 0.2),
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
