import 'package:flutter/widgets.dart';

/// Utility functions for responsive screen sizing
class ScreenUtils {
  /// Get percentage of screen width
  ///
  /// Example: `ScreenUtils.widthPercent(context, 50)` returns 50% of screen width
  static double widthPercent(BuildContext context, double percent) {
    return MediaQuery.of(context).size.width * (percent / 100);
  }

  /// Get percentage of screen height
  ///
  /// Example: `ScreenUtils.heightPercent(context, 30)` returns 30% of screen height
  static double heightPercent(BuildContext context, double percent) {
    return MediaQuery.of(context).size.height * (percent / 100);
  }

  /// Get screen width
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get percentage of screen width as SizedBox
  static SizedBox widthBox(BuildContext context, double percent) {
    return SizedBox(width: widthPercent(context, percent));
  }

  /// Get percentage of screen height as SizedBox
  static SizedBox heightBox(BuildContext context, double percent) {
    return SizedBox(height: heightPercent(context, percent));
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get safe area padding
  static EdgeInsets safePadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get bottom safe area padding (for notches/home indicators)
  static double safeBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Get top safe area padding (for status bar)
  static double safeTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
}

/// Extension methods for easier access to screen utilities
extension ScreenUtilsExtension on BuildContext {
  /// Get percentage of screen width
  double widthPercent(double percent) =>
      ScreenUtils.widthPercent(this, percent);

  /// Get percentage of screen height
  double heightPercent(double percent) =>
      ScreenUtils.heightPercent(this, percent);

  /// Get screen width
  double get screenWidth => ScreenUtils.width(this);

  /// Get screen height
  double get screenHeight => ScreenUtils.height(this);

  /// Check if landscape
  bool get isLandscape => ScreenUtils.isLandscape(this);

  /// Check if portrait
  bool get isPortrait => ScreenUtils.isPortrait(this);
}
