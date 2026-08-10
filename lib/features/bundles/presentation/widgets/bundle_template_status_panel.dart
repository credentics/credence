import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/support/bundle_template_catalog.dart';
import 'package:pass_doc_manager/features/bundles/presentation/support/bundle_template_presentation.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class BundleTemplateStatusPanel extends StatelessWidget {
  const BundleTemplateStatusPanel({
    super.key,
    required this.progress,
    required this.onAddItems,
  });

  final BundleTemplateProgress progress;
  final VoidCallback onAddItems;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final templateCopy = bundleTemplatePresentationCopy(
      l10n: l10n,
      template: progress.template,
    );
    final missingRequired = progress.missingRequired;
    final satisfiedRequired = progress.requirements
        .where((item) => !item.requirement.optional && item.isSatisfied)
        .toList(growable: false);
    final optional = progress.optionalRequirements;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.stroke),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  templateCopy.icon,
                  color: palette.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bundleTemplateChecklistTitle,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.bundleTemplateChecklistSubtitle(
                        progress.completedRequiredCount,
                        progress.totalRequiredCount,
                      ),
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onAddItems,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.bundleTemplateAddMissingAction),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: progress.isReady
                  ? palette.primarySoft
                  : palette.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: progress.isReady
                    ? palette.primary.withValues(alpha: 0.18)
                    : palette.stroke,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  progress.isReady
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: progress.isReady ? palette.success : palette.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.isReady
                            ? l10n.bundleTemplateReadyTitle
                            : l10n.bundleTemplateMissingTitle,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        progress.isReady
                            ? l10n.bundleTemplateReadySubtitle
                            : l10n.bundleTemplateMissingCount(
                                progress.totalMissingRequiredUnits,
                              ),
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (missingRequired.isNotEmpty) ...[
            _SectionLabel(text: l10n.bundleTemplateRequiredLabel),
            const SizedBox(height: 10),
            ...missingRequired.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == missingRequired.length - 1 ? 0 : 10,
                ),
                child: _RequirementTile(progress: entry.value),
              ),
            ),
          ],
          if (satisfiedRequired.isNotEmpty) ...[
            if (missingRequired.isNotEmpty) const SizedBox(height: 14),
            _SectionLabel(text: l10n.bundleTemplateCompletedLabel),
            const SizedBox(height: 10),
            ...satisfiedRequired.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == satisfiedRequired.length - 1 ? 0 : 10,
                ),
                child: _RequirementTile(progress: entry.value),
              ),
            ),
          ],
          if (optional.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionLabel(text: l10n.bundleTemplateOptionalLabel),
            const SizedBox(height: 10),
            ...optional.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == optional.length - 1 ? 0 : 10,
                ),
                child: _RequirementTile(progress: entry.value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.appPalette.textMuted,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({required this.progress});

  final BundleTemplateRequirementProgress progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isSatisfied = progress.isSatisfied;
    final iconColor = isSatisfied ? palette.success : palette.warning;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSatisfied
              ? palette.success.withValues(alpha: 0.16)
              : palette.stroke,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              isSatisfied ? Icons.check_rounded : Icons.radio_button_unchecked,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.requirement.title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  progress.requirement.description,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.stroke),
            ),
            child: Text(
              context.l10n.bundleTemplateMatchedCount(
                progress.matchedCount,
                progress.requirement.minCount,
              ),
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
