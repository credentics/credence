import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_summary_entity.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/company_logo_avatar.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class CredentialListItemCard extends StatefulWidget {
  const CredentialListItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onCopy,
    this.onToggleFavorite,
  });

  final CredentialSummaryEntity item;
  final VoidCallback onTap;
  final Future<bool> Function() onCopy;
  final VoidCallback? onToggleFavorite;

  @override
  State<CredentialListItemCard> createState() => _CredentialListItemCardState();
}

class _CredentialListItemCardState extends State<CredentialListItemCard> {
  bool _isCopied = false;
  Timer? _copiedTimer;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _onCopyTapped() async {
    final copied = await widget.onCopy();
    if (!copied || !mounted) return;

    _copiedTimer?.cancel();
    setState(() => _isCopied = true);

    _copiedTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final cat = widget.item.category;
    final catColor = _categoryColor(cat);

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.stroke),
          ),
          child: Row(
            children: [
              // Logo in rounded square
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: CompanyLogoAvatar(
                  serviceName: widget.item.displayName,
                  localImagePath: widget.item.logoPath,
                  size: 36,
                  borderRadius: BorderRadius.circular(12),
                  fallbackColor: Color(widget.item.brandHex),
                ),
              ),
              const SizedBox(width: 12),
              // Favorite indicator when the card is display-only.
              if (widget.item.isFavorite && widget.onToggleFavorite == null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.star_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.item.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        if (widget.item.breachedCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              context.l10n.breachWarningBadge,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Favorite toggle
              if (widget.onToggleFavorite != null)
                GestureDetector(
                  onTap: widget.onToggleFavorite,
                  child: Icon(
                    widget.item.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: widget.item.isFavorite
                        ? const Color(0xFFF59E0B)
                        : palette.textMuted,
                    size: 22,
                  ),
                ),
              const SizedBox(width: 4),
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: catColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Copy button
              Material(
                color: _isCopied
                    ? const Color(0xFFE6F8F1)
                    : palette.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _onCopyTapped,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(
                      _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 17,
                      color: _isCopied
                          ? const Color(0xFF059669)
                          : palette.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _categoryColor(CredentialCategory cat) {
    return switch (cat) {
      CredentialCategory.work => const Color(0xFF8B5CF6),
      CredentialCategory.finance => const Color(0xFF059669),
      CredentialCategory.social => const Color(0xFF3B82F6),
      CredentialCategory.shopping => const Color(0xFFD97706),
      CredentialCategory.entertainment => const Color(0xFFE11D48),
      CredentialCategory.developer => const Color(0xFF1152D4),
      CredentialCategory.general => const Color(0xFF5C6D84),
    };
  }
}
