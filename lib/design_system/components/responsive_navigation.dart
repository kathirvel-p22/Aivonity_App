import 'package:flutter/material.dart';
import '../layout/spacing.dart';

/// Navigation item for responsive navigation
class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final Widget Function(BuildContext) builder;
  final bool showInBottomNav;

  const NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
    this.showInBottomNav = true,
  });
}

/// Responsive navigation wrapper that adapts to screen size
class ResponsiveNavigation extends StatefulWidget {
  final List<NavigationItem> items;
  final int initialIndex;
  final String title;

  const ResponsiveNavigation({
    super.key,
    required this.items,
    required this.title,
    this.initialIndex = 0,
  });

  @override
  State<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

class _ResponsiveNavigationState extends State<ResponsiveNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (AivonityBreakpoints.isDesktop(context)) {
      return _buildDesktopLayout();
    } else if (AivonityBreakpoints.isTablet(context)) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Side navigation rail
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: widget.items.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                label: Text(item.label),
              );
            }).toList(),
            leading: Column(
              children: [
                const SizedBox(height: 16),
                CircleAvatar(radius: 20, child: Text(widget.title[0])),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(
            child: Column(
              children: [
                // App bar
                Container(
                  height: 64,
                  padding: AivonitySpacing.horizontalMD,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.items[_currentIndex].label,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      // Desktop-specific actions can go here
                    ],
                  ),
                ),
                // Content
                Expanded(child: widget.items[_currentIndex].builder(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.items[_currentIndex].label),
        centerTitle: false,
      ),
      drawer: _buildDrawer(),
      body: widget.items[_currentIndex].builder(context),
    );
  }

  Widget _buildMobileLayout() {
    final bottomNavItems = widget.items
        .where((item) => item.showInBottomNav)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.items[_currentIndex].label)),
      drawer: widget.items.length > bottomNavItems.length
          ? _buildDrawer()
          : null,
      body: widget.items[_currentIndex].builder(context),
      bottomNavigationBar: bottomNavItems.length > 1
          ? BottomNavigationBar(
              currentIndex: _currentIndex.clamp(0, bottomNavItems.length - 1),
              onTap: (index) {
                setState(() {
                  _currentIndex = widget.items.indexOf(bottomNavItems[index]);
                });
              },
              type: BottomNavigationBarType.fixed,
              items: bottomNavItems.map((item) {
                return BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                );
              }).toList(),
            )
          : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(
                    widget.title[0],
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              selected: _currentIndex == index,
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}

/// Responsive layout builder for content
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints) builder;

  const ResponsiveLayoutBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, constraints);
      },
    );
  }
}

/// Responsive container that adapts its layout based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;
  final double? mobileMaxWidth;
  final double? tabletMaxWidth;
  final double? desktopMaxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileMaxWidth,
    this.tabletMaxWidth,
    this.desktopMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry padding;
    double? maxWidth;

    if (AivonityBreakpoints.isDesktop(context)) {
      padding = desktopPadding ?? AivonitySpacing.paddingXL;
      maxWidth = desktopMaxWidth ?? 1200;
    } else if (AivonityBreakpoints.isTablet(context)) {
      padding = tabletPadding ?? AivonitySpacing.paddingLG;
      maxWidth = tabletMaxWidth ?? 800;
    } else {
      padding = mobilePadding ?? AivonitySpacing.paddingMD;
      maxWidth = mobileMaxWidth;
    }

    Widget content = Padding(padding: padding, child: child);

    if (maxWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Responsive columns that stack on mobile
class ResponsiveColumns extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveColumns({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (AivonityBreakpoints.isMobile(context)) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .expand((child) => [child, SizedBox(height: spacing)])
            .take(children.length * 2 - 1)
            .toList(),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children
          .expand((child) => [Expanded(child: child), SizedBox(width: spacing)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }
}

/// Responsive wrap that adjusts based on screen size
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.spacing = 8,
    this.runSpacing = 8,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: children,
    );
  }
}

