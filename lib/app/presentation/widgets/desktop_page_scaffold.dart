import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/presentation/widgets/desktop_breadcrumb.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

/// A scaffold wrapper that adds desktop-appropriate layout to any page.
///
/// On desktop:
/// - Centers content within a maxWidth container
/// - Adds optional breadcrumb navigation
/// - Provides proper scrollbar behavior
/// - Adjusts padding for wider screens
///
/// On mobile: passes through with minimal changes.
///
/// Usage:
/// ```dart
/// DesktopPageScaffold(
///   title: 'Documents',
///   maxContentWidth: 960,
///   breadcrumbs: [
///     BreadcrumbItem(label: 'Home', onTap: () => ...),
///     BreadcrumbItem(label: 'Documents'),
///   ],
///   child: existingPageContent,
/// )
/// ```
class DesktopPageScaffold extends StatelessWidget {
  const DesktopPageScaffold({
    super.key,
    required this.child,
    this.title,
    this.maxContentWidth = 960,
    this.breadcrumbs,
    this.actions,
    this.showAppBar = true,
    this.backgroundColor,
    this.horizontalPadding,
  });

  final Widget child;
  final String? title;
  final double maxContentWidth;
  final List<BreadcrumbItem>? breadcrumbs;
  final List<Widget>? actions;
  final bool showAppBar;
  final Color? backgroundColor;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDesktop = DesktopPlatform.isDesktop;
    final effectivePadding = horizontalPadding ??
        (isDesktop ? 32.0 : 16.0);

    Widget content = child;

    // Wrap in maxWidth constraint on desktop
    if (isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: content,
        ),
      );
    }

    // Add breadcrumbs on desktop
    if (isDesktop && breadcrumbs != null && breadcrumbs!.isNotEmpty) {
      content = Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: effectivePadding,
              vertical: 4,
            ),
            child: DesktopBreadcrumb(items: breadcrumbs!),
          ),
          Expanded(child: content),
        ],
      );
    }

    if (!showAppBar) {
      return Scaffold(
        backgroundColor: backgroundColor ?? palette.background,
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? palette.background,
      appBar: AppBar(
        title: title != null
            ? Text(
                title!,
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              )
            : null,
        backgroundColor: palette.surface,
        elevation: 0,
        foregroundColor: palette.textPrimary,
        centerTitle: !isDesktop,
        actions: actions,
        // Hide back button on desktop when in sidebar-navigated pages
        automaticallyImplyLeading: !isDesktop ||
            Navigator.of(context).canPop(),
      ),
      body: SafeArea(child: content),
    );
  }
}

/// Wraps a full-screen page push to use a constrained dialog on desktop.
/// Use this instead of Navigator.push for pages that should be overlays
/// on desktop (entry forms, editors, etc.).
///
/// Usage:
/// ```dart
/// await pushDesktopAdaptive(
///   context: context,
///   mobileBuilder: (_) => MyFullScreenPage(),
///   desktopDialogWidth: 640,
/// );
/// ```
Future<T?> pushDesktopAdaptive<T>({
  required BuildContext context,
  required WidgetBuilder mobileBuilder,
  double desktopDialogWidth = 640,
  double desktopDialogHeight = 720,
  String? desktopTitle,
}) {
  if (DesktopPlatform.isDesktop) {
    final palette = context.appPalette;
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: palette.surface,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: desktopDialogWidth,
            height: desktopDialogHeight,
            child: mobileBuilder(context),
          ),
        ),
      ),
    );
  }

  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(builder: mobileBuilder),
  );
}
