import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_preferences_entity.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:pass_doc_manager/features/home/presentation/cubit/home_cubit.dart';
import 'package:pass_doc_manager/features/home/presentation/cubit/home_state.dart';

class HomePreferencesPage extends StatelessWidget {
  const HomePreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: GenericAppBar(
        title: context.l10n.homePreferencesTitle,
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final prefs = state.preferences ?? HomePreferencesEntity.defaults;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(context.l10n.homeVisibleSections, palette),
                const SizedBox(height: 8),
                _card(
                  palette: palette,
                  children: [
                    for (final entry in _sectionEntries(context))
                      _switchRow(
                        context,
                        palette: palette,
                        label: entry.label,
                        value: prefs.isSectionVisible(entry.key),
                        onChanged: (_) =>
                            context.read<HomeCubit>().toggleSection(entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionLabel(context.l10n.homeSmartRules, palette),
                const SizedBox(height: 8),
                _card(
                  palette: palette,
                  children: [
                    for (final entry in _smartRuleEntries(context))
                      _switchRow(
                        context,
                        palette: palette,
                        label: entry.label,
                        value: prefs.smartRules[entry.key] ?? true,
                        onChanged: (_) =>
                            context.read<HomeCubit>().toggleSmartRule(entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionLabel(context.l10n.homeCategories, palette),
                const SizedBox(height: 8),
                _card(
                  palette: palette,
                  children: [
                    for (final entry in _categoryEntries)
                      _switchRow(
                        context,
                        palette: palette,
                        label: entry.label,
                        value: prefs.isCategoryVisible(entry.key),
                        onChanged: (_) =>
                            context.read<HomeCubit>().toggleCategory(entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      context
                          .read<HomeCubit>()
                          .savePreferences(HomePreferencesEntity.defaults);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.stroke),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.l10n.homeResetDefaults,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _sectionLabel(String text, AppPalette palette) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: palette.textMuted,
      ),
    );
  }

  Widget _card({
    required AppPalette palette,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required AppPalette palette,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: palette.primary,
          ),
        ],
      ),
    );
  }

}

class _SectionEntry {
  const _SectionEntry(this.key, this.label);
  final String key;
  final String label;
}

List<_SectionEntry> _sectionEntries(BuildContext context) => [
  _SectionEntry('reminders', context.l10n.homeSmartReminders),
  _SectionEntry('frequentlyUsed', context.l10n.homeFrequentlyUsed),
  _SectionEntry('quickAccess', context.l10n.homeQuickAccess),
  _SectionEntry('secureNotes', context.l10n.secureNotesTitle),
  _SectionEntry('recentItems', context.l10n.homeRecentItems),
  _SectionEntry('insights', context.l10n.homeVaultInsights),
];

const _categoryEntries = [
  _SectionEntry('ids', 'IDs'),
  _SectionEntry('work', 'Work'),
  _SectionEntry('documents', 'Documents'),
  _SectionEntry('cards', 'Cards'),
  _SectionEntry('collections', 'Collections'),
  _SectionEntry('tasks', 'Tasks'),
];

List<_SectionEntry> _smartRuleEntries(BuildContext context) => [
  _SectionEntry('showExpiring', context.l10n.homeExpiringDocuments),
  _SectionEntry('showMissing', context.l10n.homeMissingAttention),
  _SectionEntry('showRecentlyUpdated', context.l10n.homeRecentlyUpdated),
];
