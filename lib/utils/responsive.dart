import 'package:flutter/material.dart';

/// Responsive breakpoints following Material Design guidelines
class Breakpoints {
  Breakpoints._();

  /// Mobile: 0 - 599px
  static const double mobile = 600;

  /// Tablet: 600 - 904px
  static const double tablet = 905;

  /// Desktop: 905px+
  static const double desktop = 1240;

  /// Large desktop: 1240px+
  static const double largeDesktop = 1440;
}

/// Device type enumeration for responsive layouts
enum DeviceType { mobile, tablet, desktop }

/// Responsive utility class providing breakpoints and helpers
class Responsive {
  Responsive._();

  /// Get the current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.mobile;

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.tablet;
  }

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.tablet;

  /// Check if current device is tablet or larger
  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.mobile;

  /// Get responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 16.0;
      case DeviceType.tablet:
        return 32.0;
      case DeviceType.desktop:
        return 48.0;
    }
  }

  /// Get responsive vertical padding
  static double verticalPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 16.0;
      case DeviceType.tablet:
        return 24.0;
      case DeviceType.desktop:
        return 32.0;
    }
  }

  /// Get responsive content max width for centering content on larger screens
  static double contentMaxWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return double.infinity;
      case DeviceType.tablet:
        return 600.0;
      case DeviceType.desktop:
        return 800.0;
    }
  }

  /// Get responsive grid cross axis count
  static int gridCrossAxisCount(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.desktop:
        return 4;
    }
  }

  /// Get responsive font scale factor
  static double fontScale(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.15;
    }
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, {double baseSize = 24.0}) {
    return baseSize * fontScale(context);
  }

  /// Get responsive spacing
  static double spacing(BuildContext context, {double baseSpacing = 16.0}) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSpacing;
      case DeviceType.tablet:
        return baseSpacing * 1.25;
      case DeviceType.desktop:
        return baseSpacing * 1.5;
    }
  }

  /// Get responsive card width for grid layouts
  static double cardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = horizontalPadding(context) * 2;
    final availableWidth = width - padding;

    if (isMobile(context)) {
      return availableWidth;
    } else if (isTablet(context)) {
      return (availableWidth - 16) / 2; // 2 columns with gap
    } else {
      return (availableWidth - 32) / 3; // 3 columns with gaps
    }
  }

  /// Get number of columns for settings/list layouts
  static int settingsColumns(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 1;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 2;
    }
  }
}

/// Responsive builder widget for building different layouts based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  })  : mobile = null,
        tablet = null,
        desktop = null;

  const ResponsiveBuilder.widgets({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : builder = _defaultBuilder;

  static Widget _defaultBuilder(BuildContext context, DeviceType deviceType) {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);

    // If using builder pattern
    if (mobile == null && tablet == null && desktop == null) {
      return builder(context, deviceType);
    }

    // If using widgets pattern
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile ?? const SizedBox.shrink();
      case DeviceType.tablet:
        return tablet ?? mobile ?? const SizedBox.shrink();
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile ?? const SizedBox.shrink();
    }
  }
}

/// A widget that constrains its child to a maximum width and centers it
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? Responsive.contentMaxWidth(context);
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
        );

    Widget content = child;

    if (effectiveMaxWidth != double.infinity) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: content,
      );

      if (centerContent) {
        content = Center(child: content);
      }
    }

    return Padding(
      padding: effectivePadding,
      child: content,
    );
  }
}

/// A scaffold wrapper that handles responsive layouts for tablet/desktop
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? drawer;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool showDrawerAsRail;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.drawer,
    this.appBar,
    this.bottomNavigationBar,
    this.showDrawerAsRail = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    // On desktop/tablet with drawer, show as side panel
    if ((isDesktop || isTablet) && drawer != null && showDrawerAsRail) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            SizedBox(
              width: isDesktop ? 280 : 72,
              child: drawer,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Default mobile layout
    return Scaffold(
      appBar: appBar,
      body: body,
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Extension methods for BuildContext to easily access responsive utilities
extension ResponsiveExtension on BuildContext {
  /// Get device type
  DeviceType get deviceType => Responsive.getDeviceType(this);

  /// Check if mobile
  bool get isMobile => Responsive.isMobile(this);

  /// Check if tablet
  bool get isTablet => Responsive.isTablet(this);

  /// Check if desktop
  bool get isDesktop => Responsive.isDesktop(this);

  /// Check if tablet or larger
  bool get isTabletOrLarger => Responsive.isTabletOrLarger(this);

  /// Get horizontal padding
  double get horizontalPadding => Responsive.horizontalPadding(this);

  /// Get vertical padding
  double get verticalPadding => Responsive.verticalPadding(this);

  /// Get content max width
  double get contentMaxWidth => Responsive.contentMaxWidth(this);

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;
}
