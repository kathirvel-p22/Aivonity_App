import 'package:flutter/material.dart';

/// Consistent spacing system for AIVONITY design system
class AivonitySpacing {
  // Base spacing unit (8px)
  static const double _baseUnit = 8.0;

  // Spacing values
  static const double xs = _baseUnit * 0.5; // 4px
  static const double sm = _baseUnit; // 8px
  static const double md = _baseUnit * 2; // 16px
  static const double lg = _baseUnit * 3; // 24px
  static const double xl = _baseUnit * 4; // 32px
  static const double xxl = _baseUnit * 6; // 48px
  static const double xxxl = _baseUnit * 8; // 64px

  // Edge insets
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets horizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXL = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets verticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXL = EdgeInsets.symmetric(vertical: xl);

  // SizedBox widgets for spacing
  static const Widget gapXS = SizedBox(width: xs, height: xs);
  static const Widget gapSM = SizedBox(width: sm, height: sm);
  static const Widget gapMD = SizedBox(width: md, height: md);
  static const Widget gapLG = SizedBox(width: lg, height: lg);
  static const Widget gapXL = SizedBox(width: xl, height: xl);

  // Horizontal gaps
  static const Widget hGapXS = SizedBox(width: xs);
  static const Widget hGapSM = SizedBox(width: sm);
  static const Widget hGapMD = SizedBox(width: md);
  static const Widget hGapLG = SizedBox(width: lg);
  static const Widget hGapXL = SizedBox(width: xl);

  // Vertical gaps
  static const Widget vGapXS = SizedBox(height: xs);
  static const Widget vGapSM = SizedBox(height: sm);
  static const Widget vGapMD = SizedBox(height: md);
  static const Widget vGapLG = SizedBox(height: lg);
  static const Widget vGapXL = SizedBox(height: xl);
}

/// Responsive breakpoints for different screen sizes
class AivonityBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktop;
  }
}

/// Responsive layout helper
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (AivonityBreakpoints.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (AivonityBreakpoints.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

/// Grid layout with consistent spacing
class AivonityGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const AivonityGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = AivonitySpacing.md,
    this.crossAxisSpacing = AivonitySpacing.md,
    this.childAspectRatio = 1.0,
    this.padding = AivonitySpacing.paddingMD,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
        children: children,
      ),
    );
  }
}

/// Responsive grid that adapts to screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.padding = AivonitySpacing.paddingMD,
  });

  @override
  Widget build(BuildContext context) {
    int crossAxisCount;

    if (AivonityBreakpoints.isLargeDesktop(context)) {
      crossAxisCount = 4;
    } else if (AivonityBreakpoints.isDesktop(context)) {
      crossAxisCount = 3;
    } else if (AivonityBreakpoints.isTablet(context)) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return AivonityGrid(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      padding: padding,
      children: children,
    );
  }
}

