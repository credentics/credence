import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/support/bundle_template_catalog.dart';
import 'package:pass_doc_manager/features/bundles/presentation/support/bundle_template_presentation.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class BundleTemplatePicker extends StatelessWidget {
  const BundleTemplatePicker({
    super.key,
    required this.selectedTemplateKey,
    required this.onChanged,
  });

  final String? selectedTemplateKey;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bundleTemplateSectionTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.bundleTemplateSectionSubtitle,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: palette.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        _TemplateCard(
          title: l10n.bundleTemplateBlankTitle,
          subtitle: l10n.bundleTemplateBlankSubtitle,
          icon: Icons.edit_note_rounded,
          selected: selectedTemplateKey == null || selectedTemplateKey!.isEmpty,
          palette: palette,
          onTap: () => onChanged(null),
        ),
        const SizedBox(height: 10),
        for (final template in BundleTemplateCatalog.templates) ...[
          _TemplateCard(
            title: bundleTemplatePresentationCopy(
              l10n: l10n,
              template: template,
            ).title,
            subtitle: bundleTemplatePresentationCopy(
              l10n: l10n,
              template: template,
            ).summary,
            icon: bundleTemplatePresentationCopy(
              l10n: l10n,
              template: template,
            ).icon,
            selected: selectedTemplateKey == template.key,
            palette: palette,
            onTap: () => onChanged(template.key),
          ),
          if (template != BundleTemplateCatalog.templates.last)
            const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        Text(
          l10n.bundleTemplatePrefillHint,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: palette.textMuted,
            height: 1.32,
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? palette.primary : palette.textMuted;
    return Material(
      color: selected ? palette.primarySoft : palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected
              ? palette.primary.withValues(alpha: 0.3)
              : palette.stroke,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? palette.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? palette.primary : palette.strokeStrong,
                    width: 1.4,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
