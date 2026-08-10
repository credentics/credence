import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

/// A reusable full-screen error state widget with icon, message, and retry
/// button. Follows the same visual language used in the profile page's error
/// state and the documents library error widget.
///
/// Usage:
/// ```dart
/// VaultErrorState(
///   message: state.errorMessage ?? context.l10n.commonErrorGeneric,
///   onRetry: () => context.read<MyCubit>().load(),
/// )
/// ```
class VaultErrorState extends StatelessWidget {
  const VaultErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  /// The user-visible error message.
  final String message;

  /// Called when the user taps the retry button.
  final VoidCallback onRetry;

  /// Icon displayed above the message. Defaults to a generic error icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 28, color: const Color(0xFFE8890C)),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.commonRetry),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
