import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

class ShareButtonWidget extends StatelessWidget {
  const ShareButtonWidget({
    super.key,
    required this.onPressed,
    this.label = 'Share',
    this.isOutlined = false,
  });

  final VoidCallback onPressed;
  final String label;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.share_outlined, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.stroke),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.share_outlined, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
