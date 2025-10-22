import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileMaxWidth = 450;
  static const double tabletMaxWidth = 800;
  static const double desktopMaxWidth = 1400;

  /// Check if current platform is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= mobileMaxWidth;
  }

  /// Check if current platform is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileMaxWidth && width <= tabletMaxWidth;
  }

  /// Check if current platform is desktop
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > tabletMaxWidth && width <= desktopMaxWidth;
  }

  /// Check if current platform is wide desktop (4K and above)
  static bool isWideDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > desktopMaxWidth;
  }

  /// Check if running on web platform
  static bool isWeb() {
    return kIsWeb;
  }

  /// Check if running on desktop OS (Windows, macOS, Linux)
  static bool isDesktopOS() {
    return defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Check if running on mobile OS (Android, iOS)
  static bool isMobileOS() {
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Check if should use web-first layout (web or desktop OS)
  static bool shouldUseWebLayout() {
    return isWeb() || isDesktopOS();
  }

  /// Check if running on Android browser
  static bool isAndroidBrowser() {
    return kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  /// Get responsive font size
  static double getFontSize(BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get responsive padding
  static EdgeInsets getPadding(BuildContext context, {
    EdgeInsets mobile = const EdgeInsets.all(12),
    EdgeInsets tablet = const EdgeInsets.all(16),
    EdgeInsets desktop = const EdgeInsets.all(24),
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, {
    double mobile = 8,
    double tablet = 12,
    double desktop = 16,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get responsive grid columns
  static int getGridColumns(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int wideDesktop = 4,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isWideDesktop(context)) return wideDesktop;
    return desktop;
  }

  /// Get responsive container width
  static double? getContainerWidth(BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get sidebar width based on screen size
  static double getSidebarWidth(BuildContext context, {bool isCollapsed = false}) {
    if (isCollapsed) return 80;
    
    if (isMobile(context)) return double.infinity; // Full width drawer
    if (isTablet(context)) return 280;
    if (isWideDesktop(context)) return 300;
    return 240; // Standard desktop
  }

  /// Get app bar height
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) return 56;
    if (isTablet(context)) return 60;
    return 70; // Desktop
  }

  /// Get icon size
  static double getIconSize(BuildContext context, {
    double mobile = 20,
    double tablet = 22,
    double desktop = 24,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get button height
  static double getButtonHeight(BuildContext context, {
    double mobile = 44,
    double tablet = 48,
    double desktop = 52,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get responsive value based on screen size
  static T getValue<T>(BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
    T? wideDesktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isWideDesktop(context) && wideDesktop != null) return wideDesktop;
    return desktop;
  }

  /// Get device type string
  static String getDeviceType(BuildContext context) {
    if (isMobile(context)) return 'mobile';
    if (isTablet(context)) return 'tablet';
    if (isWideDesktop(context)) return 'wide-desktop';
    return 'desktop';
  }
}

/// Extension to add responsive methods to BuildContext
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveHelper.isMobile(this);
  bool get isTablet => ResponsiveHelper.isTablet(this);
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  bool get isWideDesktop => ResponsiveHelper.isWideDesktop(this);
  
  double responsiveFontSize({
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) => ResponsiveHelper.getFontSize(this, mobile: mobile, tablet: tablet, desktop: desktop);
  
  EdgeInsets responsivePadding({
    EdgeInsets mobile = const EdgeInsets.all(12),
    EdgeInsets tablet = const EdgeInsets.all(16),
    EdgeInsets desktop = const EdgeInsets.all(24),
  }) => ResponsiveHelper.getPadding(this, mobile: mobile, tablet: tablet, desktop: desktop);
  
  double responsiveSpacing({
    double mobile = 8,
    double tablet = 12,
    double desktop = 16,
  }) => ResponsiveHelper.getSpacing(this, mobile: mobile, tablet: tablet, desktop: desktop);
}