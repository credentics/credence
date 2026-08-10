import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

/// Adaptive modal that shows a bottom sheet on mobile and a centered dialog
/// or side panel on desktop. Drop-in replacement for showModalBottomSheet.
///
/// Usage:
/// ```dart
/// showAdaptiveSheet(
///   context: context,
///   title: 'Choose Option',
///   builder: (context) => MySheetContent(),
/// );
/// ```
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isDismissible = true,
  bool useRootNavigator = false,
  double maxDialogWidth = 520,
  double maxDialogHeight = 680,
  bool useSidePanel = false,
}) {
  if (DesktopPlatform.isDesktop) {
    if (useSidePanel) {
      return _showSidePanel<T>(
        context: context,
        builder: builder,
        title: title,
        isDismissible: isDismissible,
      );
    }
    return _showDesktopDialog<T>(
      context: context,
      builder: builder,
      title: title,
      isDismissible: isDismissible,
      maxWidth: maxDialogWidth,
      maxHeight: maxDialogHeight,
    );
  }

  // Mobile: standard bottom sheet
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final palette = context.appPalette;
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
            Flexible(child: builder(context)),
          ],
        ),
      );
    },
  );
}

Future<T?> _showDesktopDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isDismissible = true,
  double maxWidth = 520,
  double maxHeight = 680,
}) {
  final palette = context.appPalette;
  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: palette.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      if (isDismissible)
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: palette.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              Flexible(child: builder(context)),
            ],
          ),
        ),
      );
    },
  );
}

Future<T?> _showSidePanel<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isDismissible = true,
}) {
  final palette = context.appPalette;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          elevation: 16,
          shadowColor: palette.shadow.withValues(alpha: 0.2),
          child: Container(
            width: 420,
            height: double.infinity,
            color: palette.surface,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: palette.stroke),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title ?? '',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(child: builder(context)),
              ],
            ),
          ),
        ),
      );
    },
  );
}
