import 'package:flutter/material.dart';

/// A responsive scaffold that adapts its layout based on screen size
class ResponsiveScaffold extends StatefulWidget {
  /// The title of the screen
  final String? title;

  /// The subtitle of the screen (shown below the title)
  final String? subtitle;

  /// List of toolbar actions (will automatically overflow to context menu)
  final List<ResponsiveToolbarAction>? toolbarActions;

  /// Content for the left side panel/drawer
  final Widget? sidePanel;

  /// Bottom navigation items
  final List<BottomNavigationBarItem>? bottomNavItems;

  /// Current selected bottom nav index
  final int currentBottomNavIndex;

  /// Callback when bottom nav item is tapped
  final Function(int)? onBottomNavTapped;

  /// Main body content
  final Widget body;

  /// Floating action button
  final Widget? floatingActionButton;

  /// Position of floating action button
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Background color
  final Color? backgroundColor;

  /// App bar elevation
  final double? elevation;

  /// Custom app bar leading widget
  final Widget? leading;

  /// Whether to show the hamburger menu automatically
  final bool automaticallyImplyLeading;

  /// Callback when drawer is opened/closed
  final DrawerCallback? onDrawerChanged;

  const ResponsiveScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.toolbarActions,
    this.sidePanel,
    this.bottomNavItems,
    this.currentBottomNavIndex = 0,
    this.onBottomNavTapped,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.elevation,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onDrawerChanged,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold>
    with TickerProviderStateMixin {
  late AnimationController _drawerAnimationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Breakpoints for responsive design
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  @override
  void initState() {
    super.initState();
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= desktopBreakpoint;
        final isTablet =
            screenWidth >= tabletBreakpoint && screenWidth < desktopBreakpoint;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: widget.backgroundColor,
          appBar: _buildAppBar(context, screenWidth, isDesktop, isTablet),
          drawer: _buildDrawer(context, isDesktop),
          body: _buildBody(context, isDesktop, isTablet),
          bottomNavigationBar: _buildBottomNavigationBar(
            context,
            isDesktop,
            isTablet,
          ),
          floatingActionButton: widget.floatingActionButton,
          floatingActionButtonLocation: widget.floatingActionButtonLocation,
          onDrawerChanged: widget.onDrawerChanged,
        );
      },
    );
  }

  PreferredSizeWidget? _buildAppBar(
    BuildContext context,
    double screenWidth,
    bool isDesktop,
    bool isTablet,
  ) {
    if (widget.title == null && (widget.toolbarActions?.isEmpty ?? true)) {
      return null;
    }

    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (canPop && widget.sidePanel != null && !isDesktop) {
      throw FlutterError(
        'Side panel (hamburger menu) is only allowed on the main page. Do not request a side panel on child pages.',
      );
    }

    return AppBar(
      title:
          (widget.title != null || widget.subtitle != null)
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title != null)
                    Text(
                      widget.title!,
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                    ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                ],
              )
              : null,
      elevation: widget.elevation,
      leading:
          widget.leading ??
          (widget.automaticallyImplyLeading &&
                  widget.sidePanel != null &&
                  !isDesktop &&
                  !canPop
              ? IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
              : null),
      actions: _buildToolbarActions(context, screenWidth, isDesktop),
      automaticallyImplyLeading: widget.automaticallyImplyLeading && !isDesktop,
    );
  }

  List<Widget>? _buildToolbarActions(
    BuildContext context,
    double screenWidth,
    bool isDesktop,
  ) {
    if (widget.toolbarActions == null || widget.toolbarActions!.isEmpty) {
      return null;
    }

    final actions = <Widget>[];
    final overflowActions = <ResponsiveToolbarAction>[];

    // Calculate available space for actions
    final availableSpace =
        screenWidth - 200; // Approximate space excluding title and menu
    final maxVisibleActions = (availableSpace ~/ 48).clamp(
      1,
      widget.toolbarActions!.length,
    );

    for (int i = 0; i < widget.toolbarActions!.length; i++) {
      final action = widget.toolbarActions![i];

      if (i < maxVisibleActions - 1 ||
          widget.toolbarActions!.length == maxVisibleActions) {
        // Show as regular action
        if (action.expandedWidget != null && isDesktop) {
          actions.add(
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ), // reduced padding
              child: action.expandedWidget!,
            ),
          );
        } else {
          actions.add(
            IconButton(
              icon: IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: action.icon,
              ),
              onPressed: action.onPressed,
              tooltip: action.tooltip,
            ),
          );
        }
      } else {
        // Add to overflow menu
        overflowActions.add(action);
      }
    }

    // Add context menu for overflow actions
    if (overflowActions.isNotEmpty) {
      actions.add(
        PopupMenuButton<ResponsiveToolbarAction>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (action) => action.onPressed?.call(),
          itemBuilder:
              (context) =>
                  overflowActions
                      .map(
                        (action) => PopupMenuItem(
                          value: action,
                          child: ListTile(
                            leading: action.icon,
                            title: Text(action.tooltip ?? ''),
                            dense: true,
                          ),
                        ),
                      )
                      .toList(),
        ),
      );
    }

    return actions;
  }

  Widget? _buildDrawer(BuildContext context, bool isDesktop) {
    if (widget.sidePanel == null) return null;

    if (isDesktop) {
      // Don't return drawer for desktop, it will be persistent
      return null;
    }

    return Drawer(child: widget.sidePanel);
  }

  Widget _buildBody(BuildContext context, bool isDesktop, bool isTablet) {
    Widget body = widget.body;

    if (widget.sidePanel != null && isDesktop) {
      // Show persistent side panel for desktop
      return Row(
        children: [
          SizedBox(
            width: 280,
            child: Material(elevation: 2, child: widget.sidePanel!),
          ),
          Expanded(child: body),
        ],
      );
    }

    return body;
  }

  Widget? _buildBottomNavigationBar(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    if (widget.bottomNavItems == null || widget.bottomNavItems!.isEmpty) {
      return null;
    }

    final bottomNav = BottomNavigationBar(
      items: widget.bottomNavItems!,
      currentIndex: widget.currentBottomNavIndex,
      onTap: widget.onBottomNavTapped,
      type:
          widget.bottomNavItems!.length > 3
              ? BottomNavigationBarType.shifting
              : BottomNavigationBarType.fixed,
    );

    // Float bottom navigation for larger screens
    if (isDesktop || isTablet) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: bottomNav,
        ),
      );
    }

    return bottomNav;
  }
}

/// Defines a toolbar action that can be responsive
class ResponsiveToolbarAction {
  /// The icon to display
  final Widget icon;

  /// Tooltip text
  final String? tooltip;

  /// Callback when pressed
  final VoidCallback? onPressed;

  /// Expanded widget for larger screens (e.g., search bar instead of search icon)
  final Widget? expandedWidget;

  /// Priority for showing in toolbar (higher priority items stay visible longer)
  final int priority;

  const ResponsiveToolbarAction({
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.expandedWidget,
    this.priority = 0,
  });
}

/// Extension to help with responsive design
extension ResponsiveHelper on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < 600;
  bool get isTablet =>
      MediaQuery.of(this).size.width >= 600 &&
      MediaQuery.of(this).size.width < 900;
  bool get isDesktop => MediaQuery.of(this).size.width >= 900;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}

/// Predefined responsive toolbar actions
class ResponsiveToolbarActions {
  static ResponsiveToolbarAction search({
    required VoidCallback onPressed,
    TextEditingController? controller,
    String? hintText,
    Function(String)? onSubmitted,
  }) {
    return ResponsiveToolbarAction(
      icon: const Icon(Icons.search),
      tooltip: 'Search',
      onPressed: onPressed,
      priority: 10,
      expandedWidget: SizedBox(
        width: 200,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText ?? 'Search...',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  static ResponsiveToolbarAction favorite({
    required VoidCallback onPressed,
    bool isFavorite = false,
  }) {
    return ResponsiveToolbarAction(
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      onPressed: onPressed,
      priority: 5,
    );
  }

  static ResponsiveToolbarAction share({required VoidCallback onPressed}) {
    return ResponsiveToolbarAction(
      icon: const Icon(Icons.share),
      tooltip: 'Share',
      onPressed: onPressed,
      priority: 3,
    );
  }

  static ResponsiveToolbarAction settings({required VoidCallback onPressed}) {
    return ResponsiveToolbarAction(
      icon: const Icon(Icons.settings),
      tooltip: 'Settings',
      onPressed: onPressed,
      priority: 1,
    );
  }
}
