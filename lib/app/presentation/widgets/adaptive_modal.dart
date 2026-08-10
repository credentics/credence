import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

/// Global override for showModalBottomSheet that adapts for desktop.
///
/// On desktop: wraps the bottom sheet content in a centered dialog with
/// proper sizing, close button, and rounded corners.
///
/// On mobile: passes through to the standard showModalBottomSheet.
///
/// To use globally, call [installAdaptiveModalOverride] once at app startup,
/// or use [showAdaptiveModal] as a direct replacement for showModalBottomSheet.
Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
  bool useSafeArea = false,
  bool showDragHandle = false,
  Color? backgroundColor,
  ShapeBorder? shape,
  BoxConstraints? constraints,
  double? elevation,
  Clip? clipBehavior,
  RouteSettings? routeSettings,
}) {
  if (DesktopPlatform.isDesktop) {
    return _showAsDesktopDialog<T>(
      context: context,
      builder: builder,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor,
      constraints: constraints,
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    shape: shape,
    constraints: constraints,
    elevation: elevation,
    clipBehavior: clipBehavior,
    routeSettings: routeSettings,
  );
}

Future<T?> _showAsDesktopDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  Color? backgroundColor,
  BoxConstraints? constraints,
}) {
  final palette = context.appPalette;
  final screenSize = MediaQuery.sizeOf(context);

  // Determine dialog size based on screen and constraints
  final maxWidth = constraints?.maxWidth.clamp(300.0, 600.0) ?? 480.0;
  final maxHeight = (screenSize.height * 0.8).clamp(300.0, 720.0);

  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: backgroundColor ?? palette.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button row
                if (isDismissible)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: palette.textMuted,
                          ),
                          splashRadius: 16,
                        ),
                      ),
                    ),
                  ),
                Flexible(
                  child: builder(dialogContext),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
