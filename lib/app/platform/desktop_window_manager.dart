import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';

/// Initializes window management for desktop platforms.
/// Call this once from main() before runApp().
Future<void> initDesktopWindow() async {
  if (!DesktopPlatform.isDesktop) return;

  await windowManager.ensureInitialized();

  const minSize = Size(
    DesktopPlatform.minWindowWidth,
    DesktopPlatform.minWindowHeight,
  );

  final windowOptions = WindowOptions(
    size: const Size(1280, 820),
    minimumSize: minSize,
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: DesktopPlatform.isMacOS
        ? TitleBarStyle.hidden
        : TitleBarStyle.normal,
    title: 'Credence',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

/// Updates the window title to reflect the current section.
Future<void> setDesktopWindowTitle(String section) async {
  if (!DesktopPlatform.isDesktop) return;
  final title = section.isEmpty ? 'Credence' : 'Credence — $section';
  await windowManager.setTitle(title);
}
