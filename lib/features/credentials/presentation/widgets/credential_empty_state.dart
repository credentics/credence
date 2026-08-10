import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class CredentialEmptyState extends StatelessWidget {
  const CredentialEmptyState({super.key, this.onAddTap});

  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon stack — layered circles for depth
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primarySoft,
                    ),
                  ),
                  // Inner circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          palette.primaryAccent,
                          palette.primary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              context.l10n.credentialEmptyTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.credentialEmptySubtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: palette.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Add credential button
            if (onAddTap != null)
              FilledButton.icon(
                onPressed: onAddTap,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  context.l10n.credentialEmptyAction,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
