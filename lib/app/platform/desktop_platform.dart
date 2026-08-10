import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Centralized desktop platform detection utilities.
/// Use these instead of raw Platform checks throughout the app.
abstract final class DesktopPlatform {
  static bool get isDesktop =>
      !kIsWeb &&
      (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Minimum width at which the desktop sidebar should replace bottom nav.
  static const double sidebarBreakpoint = 760;

  /// Width at which full desktop master-detail layout activates.
  static const double masterDetailBreakpoint = 1080;

  /// Tablet breakpoint for adjusted padding.
  static const double tabletBreakpoint = 700;

  /// Minimum window size for macOS/Windows/Linux.
  static const double minWindowWidth = 900;
  static const double minWindowHeight = 600;
}
