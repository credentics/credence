import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';

/// Makes text selectable on desktop platforms.
/// On mobile, renders a regular Text widget for consistent touch behavior.
class DesktopSelectableText extends StatelessWidget {
  const DesktopSelectableText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.textAlign,
    this.onCopy,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;

  /// Called when user copies text via Cmd+C on desktop.
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.isDesktop) {
      return Text(
        data,
        style: style,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        textAlign: textAlign,
      );
    }

    return SelectableText(
      data,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
    );
  }
}

/// Wraps a child to make its text content copyable via Cmd+C on desktop.
/// Uses a keyboard listener rather than making text selectable.
class DesktopCopyableField extends StatelessWidget {
  const DesktopCopyableField({
    super.key,
    required this.child,
    required this.copyValue,
    this.onCopied,
  });

  final Widget child;
  final String copyValue;
  final VoidCallback? onCopied;

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.isDesktop) return child;

    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: GestureDetector(
        onDoubleTap: () {
          Clipboard.setData(ClipboardData(text: copyValue));
          onCopied?.call();
        },
        child: Tooltip(
          message: 'Double-click to copy',
          waitDuration: const Duration(milliseconds: 800),
          child: child,
        ),
      ),
    );
  }
}
