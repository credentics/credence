import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/vault_error_state.dart';
import 'package:pass_doc_manager/app/presentation/widgets/credence_ui.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_preferences_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/pinned_item_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/quick_access_item_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/recent_item_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/smart_reminder_entity.dart';
import 'package:pass_doc_manager/features/home/presentation/cubit/home_cubit.dart';
import 'package:pass_doc_manager/features/home/presentation/cubit/home_state.dart';
import 'package:pass_doc_manager/features/home/presentation/pages/home_preferences_page.dart';
import 'package:pass_doc_manager/features/home/presentation/widgets/home_greeting_header.dart';
import 'package:pass_doc_manager/features/home/presentation/widgets/home_typography.dart';
import 'package:pass_doc_manager/features/notes/presentation/pages/secure_notes_page.dart';
import 'package:pass_doc_manager/features/search/presentation/pages/vault_search_page.dart';
import 'package:pass_doc_manager/features/tasks/presentation/pages/task_list_detail_page.dart';
import 'package:pass_doc_manager/features/vault_sync/presentation/widgets/vault_sync_status_banner.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({
    super.key,
    this.horizontalPadding = 16,
    this.onOpenCredentialDetail,
    this.onOpenDocumentDetail,
    this.onOpenCollectionDetail,
    this.onOpenCredentials,
    this.onOpenDocuments,
    this.onOpenCollections,
    this.onOpenTasks,
    this.onOpenBundles,
  });

  final double horizontalPadding;
  final void Function(BuildContext context, String credentialId)?
  onOpenCredentialDetail;
  final void Function(BuildContext context, String documentId)?
  onOpenDocumentDetail;
  final void Function(BuildContext context, String collectionId)?
  onOpenCollectionDetail;
  final VoidCallback? onOpenCredentials;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenCollections;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenBundles;

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.loading && state.dashboard == null) {
          return _HomeLoadingSkeleton(
            horizontalPadding: widget.horizontalPadding,
          );
        }

        if (state.status == HomeStatus.error && state.dashboard == null) {
          return VaultErrorState(
            icon: Icons.home_outlined,
            message: state.errorMessage ?? context.l10n.homeUnableDashboard,
            onRetry: () => context.read<HomeCubit>().load(),
          );
        }

        final dashboard = state.dashboard;
        if (dashboard == null) {
          return const SizedBox.shrink();
        }

        final prefs = state.preferences ?? HomePreferencesEntity.defaults;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 860;
            final maxWidth = isWide ? 1120.0 : double.infinity;

            return RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().load(),
              color: palette.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  widget.horizontalPadding,
                  12,
                  widget.horizontalPadding,
                  34,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildSections(
                        dashboard,
                        prefs,
                        isWide: isWide,
                        isRefreshing: state.status == HomeStatus.loading,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildSections(
    HomeDashboardEntity dashboard,
    HomePreferencesEntity prefs, {
    required bool isWide,
    required bool isRefreshing,
  }) {
    final sections = <Widget>[
      HomeGreetingHeader(
        firstName: dashboard.firstName,
        photoPath: dashboard.photoPath,
        onSettingsTap: _openPreferences,
      ),
      const SizedBox(height: 14),
      CredenceSearchField(
        hintText: context.l10n.homeSearchVaultDocuments,
        readOnly: true,
        height: 50,
        onTap: _openSearch,
      ),
      if (isRefreshing) ...[
        const SizedBox(height: 10),
        const _HomeRefreshBar(),
      ],
      const SizedBox(height: 18),
      const VaultSyncHomeSignalCard(),
      const SizedBox(height: 18),
    ];

    if (_isEmptyVault(dashboard)) {
      sections.add(_HomeEmptyState(onPrimaryTap: _openSearch));
      sections.add(const SizedBox(height: 22));
      sections.add(
        _VaultStatusHero(
          dashboard: dashboard,
          onTap: () => _openVaultHealth(dashboard),
        ),
      );
      return sections;
    }

    sections.add(
      _VaultStatsSection(
        dashboard: dashboard,
        isWide: isWide,
        onOpenCredentials: widget.onOpenCredentials,
        onOpenDocuments: widget.onOpenDocuments,
        onOpenCollections: widget.onOpenCollections,
        onOpenTasks: widget.onOpenTasks,
      ),
    );
    sections.add(const SizedBox(height: 22));
    sections.add(
      _SmartRemindersRailSection(
        dashboard: dashboard,
        onReminderTap: _handleReminderTap,
        onReminderDismiss: _dismissReminder,
      ),
    );
    sections.add(const SizedBox(height: 22));

    if (isWide) {
      sections.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  if (_shouldShowQuickOpen(dashboard, prefs)) ...[
                    _QuickOpenSection(
                      dashboard: dashboard,
                      onRecentTap: _handleRecentItemTap,
                      onQuickTap: _handleQuickAccessTap,
                      onPinnedTap: _handlePinnedItemTap,
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (prefs.isSectionVisible('insights'))
                    _InsightsBreakdownCard(insights: dashboard.insights),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  if (prefs.isSectionVisible('recentItems')) ...[
                    _RecentActivitySection(
                      items: dashboard.recentItems,
                      onTap: _handleRecentItemTap,
                    ),
                    const SizedBox(height: 22),
                  ],
                  _BottomPreviewsSection(
                    dashboard: dashboard,
                    showSecureNotes: prefs.isSectionVisible('secureNotes'),
                    onOpenCredentials: widget.onOpenCredentials,
                    onOpenDocuments: widget.onOpenDocuments,
                    onOpenCollections: widget.onOpenCollections,
                    onOpenTasks: widget.onOpenTasks,
                    onOpenBundles: widget.onOpenBundles,
                    onOpenSecureNotes: _openSecureNotes,
                    onRecentTap: _handleRecentItemTap,
                    onQuickTap: _handleQuickAccessTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      if (_shouldShowQuickOpen(dashboard, prefs)) {
        sections.add(
          _QuickOpenSection(
            dashboard: dashboard,
            onRecentTap: _handleRecentItemTap,
            onQuickTap: _handleQuickAccessTap,
            onPinnedTap: _handlePinnedItemTap,
          ),
        );
        sections.add(const SizedBox(height: 22));
      }

      if (prefs.isSectionVisible('recentItems')) {
        sections.add(
          _RecentActivitySection(
            items: dashboard.recentItems,
            onTap: _handleRecentItemTap,
          ),
        );
        sections.add(const SizedBox(height: 22));
      }

      if (prefs.isSectionVisible('insights')) {
        sections.add(_InsightsBreakdownCard(insights: dashboard.insights));
        sections.add(const SizedBox(height: 22));
      }

      sections.add(
        _BottomPreviewsSection(
          dashboard: dashboard,
          showSecureNotes: prefs.isSectionVisible('secureNotes'),
          onOpenCredentials: widget.onOpenCredentials,
          onOpenDocuments: widget.onOpenDocuments,
          onOpenCollections: widget.onOpenCollections,
          onOpenTasks: widget.onOpenTasks,
          onOpenBundles: widget.onOpenBundles,
          onOpenSecureNotes: _openSecureNotes,
          onRecentTap: _handleRecentItemTap,
          onQuickTap: _handleQuickAccessTap,
        ),
      );
    }

    sections.add(const SizedBox(height: 22));
    sections.add(
      _VaultStatusHero(
        dashboard: dashboard,
        onTap: () => _openVaultHealth(dashboard),
      ),
    );

    return sections;
  }

  bool _isEmptyVault(HomeDashboardEntity dashboard) =>
      dashboard.totalVaultItems == 0 &&
      dashboard.frequentlyUsed.isEmpty &&
      dashboard.quickAccessGroups.isEmpty &&
      dashboard.recentItems.isEmpty &&
      dashboard.smartReminders.isEmpty;

  bool _shouldShowQuickOpen(
    HomeDashboardEntity dashboard,
    HomePreferencesEntity prefs,
  ) =>
      prefs.isSectionVisible('frequentlyUsed') &&
          dashboard.frequentlyUsed.isNotEmpty ||
      prefs.isSectionVisible('quickAccess') &&
          dashboard.quickAccessGroups.isNotEmpty ||
      dashboard.pinnedItems.isNotEmpty;

  void _handleReminderTap(SmartReminderEntity reminder) {
    switch (reminder.sourceType) {
      case ReminderSourceType.credential:
        widget.onOpenCredentialDetail?.call(context, reminder.sourceId);
      case ReminderSourceType.document:
        widget.onOpenDocumentDetail?.call(context, reminder.sourceId);
      case ReminderSourceType.collection:
        widget.onOpenCollectionDetail?.call(context, reminder.sourceId);
    }
  }

  void _dismissReminder(String reminderId) {
    context.read<HomeCubit>().dismissReminder(reminderId);
  }

  void _handleRecentItemTap(RecentItemEntity item) {
    switch (item.sourceType) {
      case RecentItemSourceType.credential:
        widget.onOpenCredentialDetail?.call(context, item.sourceId);
      case RecentItemSourceType.document:
        widget.onOpenDocumentDetail?.call(context, item.sourceId);
      case RecentItemSourceType.collection:
        widget.onOpenCollectionDetail?.call(context, item.sourceId);
    }
  }

  void _handlePinnedItemTap(PinnedItemEntity item) {
    switch (item.sourceType) {
      case 'credential':
        widget.onOpenCredentialDetail?.call(context, item.sourceId);
      case 'document':
        widget.onOpenDocumentDetail?.call(context, item.sourceId);
      case 'collection':
        widget.onOpenCollectionDetail?.call(context, item.sourceId);
    }
  }

  void _handleQuickAccessTap(String sourceType, String sourceId) {
    switch (sourceType) {
      case 'credential':
        widget.onOpenCredentialDetail?.call(context, sourceId);
      case 'document':
        widget.onOpenDocumentDetail?.call(context, sourceId);
      case 'collection':
        widget.onOpenCollectionDetail?.call(context, sourceId);
      case 'task_list':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskListDetailPage(listId: sourceId),
          ),
        );
    }
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VaultSearchPage(
          onOpenCredential: widget.onOpenCredentialDetail,
          onOpenDocument: widget.onOpenDocumentDetail,
          onOpenCollection: widget.onOpenCollectionDetail,
        ),
      ),
    );
  }

  void _openSecureNotes() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SecureNotesPage()));
  }

  void _openVaultHealth(HomeDashboardEntity dashboard) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _HomeVaultHealthExpandedPage(dashboard: dashboard),
      ),
    );
  }

  void _openPreferences() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<HomeCubit>(),
          child: const HomePreferencesPage(),
        ),
      ),
    );
  }
}

class _HomeRefreshBar extends StatelessWidget {
  const _HomeRefreshBar();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 3,
        color: palette.primary,
        backgroundColor: palette.surfaceSoft,
      ),
    );
  }
}

class _VaultStatusHero extends StatelessWidget {
  const _VaultStatusHero({required this.dashboard, required this.onTap});

  final HomeDashboardEntity dashboard;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final healthIssueCount = dashboard.insights.totalIssues;
    final score = _healthScore(healthIssueCount);
    final cardColor = isDark
        ? const Color(0xFF171A22)
        : const Color(0xFF292620);
    final foreground = isDark ? palette.textPrimary : Colors.white;
    final muted = foreground.withValues(alpha: 0.68);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: palette.stroke),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: isDark ? 0.12 : 0.8),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.homeVaultStatus.toUpperCase(),
                      style: TextStyle(
                        fontFamily: homeFontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.25,
                        color: muted,
                      ),
                    ),
                  ),
                  _StatusPill(
                    label: healthIssueCount > 0
                        ? l10n.homeStatusNeedsAttention
                        : l10n.homeHealthy,
                    color: healthIssueCount > 0
                        ? palette.warning
                        : palette.success,
                    light: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontFamily: homeFontDisplay,
                      fontSize: 46,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.8,
                      fontFeatures: homeTabularFigures,
                      color: foreground,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 3, bottom: 5),
                    child: Text(
                      '/100',
                      style: TextStyle(
                        fontFamily: homeFontDisplay,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: score / 100,
                  color: foreground,
                  backgroundColor: foreground.withValues(alpha: 0.16),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                runSpacing: 8,
                spacing: 10,
                children: [
                  _HeroMeta(label: '$healthIssueCount ${l10n.homeIssues}'),
                  _HeroMeta(
                    label:
                        '${dashboard.smartReminders.length} ${l10n.homeSmartReminders}',
                  ),
                  _HeroMeta(
                    label: '${dashboard.totalVaultItems} ${l10n.homeItems}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: homeFontMono,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.75,
        color: (isDark ? Colors.white : Colors.white).withValues(alpha: 0.72),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    this.light = false,
  });

  final String label;
  final Color color;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.94)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: homeFontMono,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: light ? palette.textPrimary : color,
              letterSpacing: -0.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartRemindersRailSection extends StatelessWidget {
  const _SmartRemindersRailSection({
    required this.dashboard,
    required this.onReminderTap,
    required this.onReminderDismiss,
  });

  final HomeDashboardEntity dashboard;
  final ValueChanged<SmartReminderEntity> onReminderTap;
  final ValueChanged<String> onReminderDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sortedReminders = dashboard.smartReminders.toList(growable: false)
      ..sort(_compareReminderDates);
    final reminders = sortedReminders.take(3).toList(growable: false);
    final reminderCount = dashboard.smartReminders.length;
    final palette = context.appPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CredenceSectionLabel(
          label: '${l10n.homeSmartReminders} · $reminderCount',
          padding: EdgeInsets.zero,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.homeSoonestFirst,
                style: TextStyle(
                  fontFamily: homeFontBody,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: palette.textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (reminderCount == 0)
          const _AllGoodAttentionCard()
        else ...[
          CredenceCard(
            radius: 18,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < reminders.length; i++) ...[
                  _SmartReminderRailRow(
                    reminder: reminders[i],
                    onTap: () => onReminderTap(reminders[i]),
                    onDismiss: () => onReminderDismiss(reminders[i].id),
                  ),
                  if (i < reminders.length - 1)
                    Divider(height: 1, color: palette.stroke),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ViewAllRemindersRow(
            count: reminderCount,
            onTap: () => _showAllRemindersSheet(context, sortedReminders),
          ),
        ],
      ],
    );
  }

  static int _compareReminderDates(
    SmartReminderEntity a,
    SmartReminderEntity b,
  ) {
    final aDate = a.relevantAt;
    final bDate = b.relevantAt;
    if (aDate == null && bDate == null) return a.title.compareTo(b.title);
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return aDate.compareTo(bDate);
  }

  void _showAllRemindersSheet(
    BuildContext context,
    List<SmartReminderEntity> reminders,
  ) {
    final palette = context.appPalette;
    final visibleReminders = reminders.toList(growable: true);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.48,
          maxChildSize: 0.95,
          builder: (context, controller) => SafeArea(
            top: false,
            child: ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.strokeStrong,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CredenceSectionLabel(
                  label:
                      '${sheetContext.l10n.homeSmartReminders} · ${visibleReminders.length}',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                if (visibleReminders.isEmpty)
                  const _AllGoodAttentionCard()
                else
                  CredenceCard(
                    radius: 18,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < visibleReminders.length; i++) ...[
                          _SmartReminderRailRow(
                            reminder: visibleReminders[i],
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              onReminderTap(visibleReminders[i]);
                            },
                            onDismiss: () {
                              final reminderId = visibleReminders[i].id;
                              setSheetState(() {
                                visibleReminders.removeWhere(
                                  (reminder) => reminder.id == reminderId,
                                );
                              });
                              onReminderDismiss(reminderId);
                            },
                          ),
                          if (i < visibleReminders.length - 1)
                            Divider(height: 1, color: palette.stroke),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllGoodAttentionCard extends StatelessWidget {
  const _AllGoodAttentionCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    return CredenceCard(
      backgroundColor: palette.success.withValues(alpha: 0.08),
      borderColor: palette.success.withValues(alpha: 0.18),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _SoftIcon(
            icon: Icons.verified_rounded,
            background: palette.success.withValues(alpha: 0.12),
            color: palette.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeNoAttentionNeeded,
                  style: TextStyle(
                    fontFamily: homeFontBody,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.homeNoAttentionSubtitle,
                  style: TextStyle(
                    fontFamily: homeFontBody,
                    fontSize: 12.5,
                    height: 1.35,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartReminderRailRow extends StatelessWidget {
  const _SmartReminderRailRow({
    required this.reminder,
    required this.onTap,
    required this.onDismiss,
  });

  final SmartReminderEntity reminder;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final date = reminder.relevantAt?.toLocal();
    final state = _ReminderDateState.from(date);
    final accent = state.accent(palette);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            _ReminderDateChip(date: date, state: state),
            const SizedBox(width: 13),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 66),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: homeFontBody,
                        fontSize: 15,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _ReminderStatusPill(state: state, date: date),
                        const SizedBox(width: 9),
                        Text(
                          '·',
                          style: TextStyle(
                            fontFamily: homeFontBody,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            _actionLabel(context, reminder.action),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: homeFontBody,
                              fontSize: 11.8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: accent.withValues(alpha: 0.78),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dueLine(context, date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: homeFontBody,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Hide reminder',
                  child: IconButton(
                    onPressed: onDismiss,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: palette.textMuted.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: accent, size: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _dueLine(BuildContext context, DateTime? date) {
    if (date == null) return 'No date set';
    final now = DateTime.now();
    final days = _calendarDayDifference(now, date);
    final formatted = DateFormat.yMMMd(context.l10n.localeName).format(date);
    if (days == 0) return 'Due today · $formatted';
    if (days < 0) {
      final overdueDays = days.abs();
      return 'Overdue by $overdueDays ${overdueDays == 1 ? 'day' : 'days'} · $formatted';
    }
    return 'Due in $days ${days == 1 ? 'day' : 'days'} · $formatted';
  }

  static String _actionLabel(BuildContext context, ReminderAction action) {
    switch (action) {
      case ReminderAction.resolve:
        return 'Action needed';
      case ReminderAction.renew:
        return 'Renewal needed';
      case ReminderAction.uploadNow:
        return 'Upload needed';
      case ReminderAction.viewDetails:
        return 'Review needed';
    }
  }
}

class _ViewAllRemindersRow extends StatelessWidget {
  const _ViewAllRemindersRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return CredenceCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 24,
            color: palette.textSecondary,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View all reminders',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: homeFontBody,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: homeFontBody,
                color: palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFeatures: homeTabularFigures,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.chevron_right_rounded,
            color: palette.textSecondary,
            size: 28,
          ),
        ],
      ),
    );
  }
}

enum _ReminderDateState {
  overdue,
  today,
  close,
  incoming,
  none;

  static _ReminderDateState from(DateTime? date) {
    if (date == null) return _ReminderDateState.none;
    final now = DateTime.now();
    final days = _calendarDayDifference(now, date);
    if (days < 0) return _ReminderDateState.overdue;
    if (days == 0) return _ReminderDateState.today;
    if (days <= 30) return _ReminderDateState.close;
    return _ReminderDateState.incoming;
  }

  Color accent(AppPalette palette) {
    return switch (this) {
      _ReminderDateState.overdue => palette.danger,
      _ReminderDateState.today => palette.primaryAccent,
      _ReminderDateState.close => palette.warning,
      _ReminderDateState.incoming => palette.success,
      _ReminderDateState.none => palette.textMuted,
    };
  }

  Color softBackground(AppPalette palette) {
    return switch (this) {
      _ReminderDateState.overdue => palette.dangerSoft.withValues(alpha: 0.72),
      _ReminderDateState.today => palette.primarySoft.withValues(alpha: 0.86),
      _ReminderDateState.close => palette.warning.withValues(alpha: 0.12),
      _ReminderDateState.incoming => palette.success.withValues(alpha: 0.1),
      _ReminderDateState.none => palette.surfaceSoft,
    };
  }
}

class _ReminderDateChip extends StatelessWidget {
  const _ReminderDateChip({required this.date, required this.state});

  final DateTime? date;
  final _ReminderDateState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final day = date == null
        ? '!'
        : DateFormat.d(context.l10n.localeName).format(date!);
    final month = date == null
        ? 'NOW'
        : DateFormat.MMM(context.l10n.localeName).format(date!);
    final year = date == null
        ? ''
        : DateFormat.y(context.l10n.localeName).format(date!);
    final foreground = state.accent(palette);

    return Container(
      width: 64,
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      decoration: BoxDecoration(
        color: state.softBackground(palette),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: homeFontDisplay,
              fontSize: 23,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
              fontFeatures: homeTabularFigures,
              color: foreground,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            month.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: homeFontMono,
              fontSize: 9.5,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: foreground,
            ),
          ),
          if (year.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              year,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: homeFontMono,
                fontSize: 9.2,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
                color: foreground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderStatusPill extends StatelessWidget {
  const _ReminderStatusPill({required this.state, required this.date});

  final _ReminderDateState state;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = state.accent(palette);
    final label = switch (state) {
      _ReminderDateState.overdue => 'OVERDUE',
      _ReminderDateState.today => 'TODAY',
      _ReminderDateState.close => 'DUE SOON',
      _ReminderDateState.incoming => 'INCOMING',
      _ReminderDateState.none => 'ACTION',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: homeFontMono,
          fontSize: 8.8,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.45,
          color: color,
        ),
      ),
    );
  }
}

class _VaultStatsSection extends StatelessWidget {
  const _VaultStatsSection({
    required this.dashboard,
    required this.isWide,
    required this.onOpenCredentials,
    required this.onOpenDocuments,
    required this.onOpenCollections,
    required this.onOpenTasks,
  });

  final HomeDashboardEntity dashboard;
  final bool isWide;
  final VoidCallback? onOpenCredentials;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenCollections;
  final VoidCallback? onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.appPalette;
    final stats = [
      _StatItem(
        label: l10n.navCredentials,
        value: dashboard.credentialCount,
        caption: l10n.homeLocalOnly,
        icon: Icons.lock_rounded,
        color: palette.primary,
        background: palette.primarySoft,
        onTap: onOpenCredentials,
      ),
      _StatItem(
        label: l10n.navDocuments,
        value: dashboard.documentCount,
        caption: '${dashboard.insights.expiringDocuments} ${l10n.homeAlerts}',
        icon: Icons.description_rounded,
        color: const Color(0xFFD97706),
        background: const Color(0xFFFFF3D8),
        onTap: onOpenDocuments,
      ),
      _StatItem(
        label: l10n.homeSourceCollection,
        value: dashboard.collectionCount,
        caption: l10n.homeLastUpdated,
        icon: Icons.folder_rounded,
        color: const Color(0xFF1152D4),
        background: const Color(0xFFEAF0FF),
        onTap: onOpenCollections,
      ),
      _StatItem(
        label: l10n.navTasks,
        value: dashboard.openTaskCount,
        caption: l10n.homeOpenTasks,
        icon: Icons.checklist_rounded,
        color: const Color(0xFFEC4899),
        background: const Color(0xFFFCE7F3),
        onTap: onOpenTasks,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CredenceSectionLabel(
          label: l10n.homeVaultAtGlance,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = isWide ? 4 : 2;
            final spacing = 10.0;
            final tileWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final stat in stats)
                  SizedBox(
                    width: tileWidth,
                    child: _StatTile(stat: stat),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    required this.background,
    this.onTap,
  });

  final String label;
  final int value;
  final String caption;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onTap;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _StatItem stat;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CredenceCard(
      onTap: stat.onTap,
      padding: const EdgeInsets.all(14),
      backgroundColor: isDark
          ? palette.surface
          : stat.background.withValues(alpha: 0.72),
      borderColor: isDark ? palette.stroke : stat.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SoftIcon(
                icon: stat.icon,
                background: isDark
                    ? stat.color.withValues(alpha: 0.16)
                    : Colors.white,
                color: stat.color,
                size: 34,
                iconSize: 17,
              ),
              const Spacer(),
              Text(
                '${stat.value}',
                style: TextStyle(
                  fontFamily: homeFontDisplay,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  fontFeatures: homeTabularFigures,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: homeFontMono,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stat.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: homeFontBody,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickOpenSection extends StatelessWidget {
  const _QuickOpenSection({
    required this.dashboard,
    required this.onRecentTap,
    required this.onQuickTap,
    required this.onPinnedTap,
  });

  final HomeDashboardEntity dashboard;
  final ValueChanged<RecentItemEntity> onRecentTap;
  final void Function(String sourceType, String sourceId) onQuickTap;
  final ValueChanged<PinnedItemEntity> onPinnedTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final quickItems = _flattenQuickAccess(
      dashboard.quickAccessGroups,
    ).take(5).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CredenceSectionLabel(
          label: l10n.homeQuickOpen,
          padding: EdgeInsets.zero,
        ),
        if (dashboard.frequentlyUsed.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dashboard.frequentlyUsed.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = dashboard.frequentlyUsed[index];
                return _FrequentOpenTile(
                  item: item,
                  onTap: () => onRecentTap(item),
                );
              },
            ),
          ),
        ],
        if (dashboard.pinnedItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PinnedItemsCard(items: dashboard.pinnedItems, onTap: onPinnedTap),
        ],
        if (quickItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          CredenceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < quickItems.length; i++) ...[
                  _QuickItemRow(
                    item: quickItems[i],
                    onTap: () => onQuickTap(
                      quickItems[i].sourceType,
                      quickItems[i].sourceId,
                    ),
                  ),
                  if (i < quickItems.length - 1)
                    Divider(height: 1, color: context.appPalette.stroke),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FrequentOpenTile extends StatelessWidget {
  const _FrequentOpenTile({required this.item, required this.onTap});

  final RecentItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox(
      width: 122,
      child: CredenceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SourceAvatar.recent(item, size: 40),
            const Spacer(),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: homeFontBody,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: homeFontMono,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedItemsCard extends StatelessWidget {
  const _PinnedItemsCard({required this.items, required this.onTap});

  final List<PinnedItemEntity> items;
  final ValueChanged<PinnedItemEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return CredenceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              context.l10n.homePinned.toUpperCase(),
              style: TextStyle(
                fontFamily: homeFontMono,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: palette.textMuted,
              ),
            ),
          ),
          for (var i = 0; i < math.min(items.length, 3); i++) ...[
            _PinnedItemRow(item: items[i], onTap: () => onTap(items[i])),
            if (i < math.min(items.length, 3) - 1)
              Divider(height: 1, color: palette.stroke),
          ],
        ],
      ),
    );
  }
}

class _PinnedItemRow extends StatelessWidget {
  const _PinnedItemRow({required this.item, required this.onTap});

  final PinnedItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _SourceAvatar.pinned(item, size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: homeFontBody,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: homeFontMono,
                      fontSize: 12,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickItemRow extends StatelessWidget {
  const _QuickItemRow({required this.item, required this.onTap});

  final QuickAccessItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = _quickItemColor(item.sourceType, palette);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            _SourceAvatar.quick(item, size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: homeFontBody,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _quickSubtitle(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: homeFontMono,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            _StatusPill(
              label: _sourceLabel(context, item.sourceType),
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  String _quickSubtitle(QuickAccessItemEntity item) {
    final parts = [
      if (item.subtitle.trim().isNotEmpty) item.subtitle,
      if (item.dateLabel?.trim().isNotEmpty ?? false) item.dateLabel!,
    ];
    return parts.join(' · ');
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.items, required this.onTap});

  final List<RecentItemEntity> items;
  final ValueChanged<RecentItemEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CredenceSectionLabel(
          label: l10n.homeRecentActivity,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          CredenceCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _SoftIcon(
                  icon: Icons.history_rounded,
                  background: palette.surfaceSoft,
                  color: palette.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeRecentEmptyTitle,
                        style: TextStyle(
                          fontFamily: homeFontBody,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.homeRecentEmptySubtitle,
                        style: TextStyle(
                          fontFamily: homeFontBody,
                          fontSize: 12.5,
                          height: 1.35,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          CredenceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < math.min(items.length, 6); i++) ...[
                  _RecentActivityRow(
                    item: items[i],
                    onTap: () => onTap(items[i]),
                  ),
                  if (i < math.min(items.length, 6) - 1)
                    Divider(height: 1, color: palette.stroke),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.item, required this.onTap});

  final RecentItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            _SourceAvatar.recent(item, size: 38),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: homeFontBody,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_recentTypeLabel(context, item.sourceType)} · ${item.subtitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: homeFontMono,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _relativeTime(context, item.modifiedAt),
              style: TextStyle(
                fontFamily: homeFontMono,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.25,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsBreakdownCard extends StatelessWidget {
  const _InsightsBreakdownCard({required this.insights});

  final HomeInsights insights;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final rows = _insightRows(context, insights);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CredenceSectionLabel(
          label: context.l10n.homeVaultInsights,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          const _AllGoodAttentionCard()
        else
          CredenceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  _InsightMiniRow(row: rows[i]),
                  if (i < rows.length - 1)
                    Divider(height: 1, color: palette.stroke),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _InsightRowData {
  const _InsightRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class _InsightMiniRow extends StatelessWidget {
  const _InsightMiniRow({required this.row});

  final _InsightRowData row;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _SoftIcon(
            icon: row.icon,
            background: row.color.withValues(alpha: 0.12),
            color: row.color,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: TextStyle(
                    fontFamily: homeFontBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.subtitle,
                  style: TextStyle(
                    fontFamily: homeFontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomPreviewsSection extends StatelessWidget {
  const _BottomPreviewsSection({
    required this.dashboard,
    required this.showSecureNotes,
    required this.onOpenCredentials,
    required this.onOpenDocuments,
    required this.onOpenCollections,
    required this.onOpenTasks,
    required this.onOpenBundles,
    required this.onOpenSecureNotes,
    required this.onRecentTap,
    required this.onQuickTap,
  });

  final HomeDashboardEntity dashboard;
  final bool showSecureNotes;
  final VoidCallback? onOpenCredentials;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenCollections;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenBundles;
  final VoidCallback onOpenSecureNotes;
  final ValueChanged<RecentItemEntity> onRecentTap;
  final void Function(String sourceType, String sourceId) onQuickTap;

  @override
  Widget build(BuildContext context) {
    final credentials = dashboard.recentItems
        .where((item) => item.sourceType == RecentItemSourceType.credential)
        .take(3)
        .toList(growable: false);
    final documents = dashboard.recentItems
        .where((item) => item.sourceType == RecentItemSourceType.document)
        .take(3)
        .toList(growable: false);
    final collections = dashboard.recentItems
        .where((item) => item.sourceType == RecentItemSourceType.collection)
        .take(3)
        .toList(growable: false);
    final taskItem = _firstTaskList(dashboard.quickAccessGroups);

    final sections = <Widget>[
      if (credentials.isNotEmpty) ...[
        CredenceSectionLabel(
          label: context.l10n.navCredentials,
          padding: EdgeInsets.zero,
          trailing: _PreviewSectionAction(onTap: onOpenCredentials),
        ),
        const SizedBox(height: 10),
        _PreviewRowsCard(items: credentials, onTap: onRecentTap),
      ],
      if (documents.isNotEmpty) ...[
        if (credentials.isNotEmpty) const SizedBox(height: 18),
        CredenceSectionLabel(
          label: context.l10n.navDocuments,
          padding: EdgeInsets.zero,
          trailing: _PreviewSectionAction(onTap: onOpenDocuments),
        ),
        const SizedBox(height: 10),
        _PreviewRowsCard(items: documents, onTap: onRecentTap),
      ],
      if (collections.isNotEmpty) ...[
        if (credentials.isNotEmpty || documents.isNotEmpty)
          const SizedBox(height: 18),
        CredenceSectionLabel(
          label: context.l10n.homeSourceCollection,
          padding: EdgeInsets.zero,
          trailing: _PreviewSectionAction(onTap: onOpenCollections),
        ),
        const SizedBox(height: 10),
        _PreviewRowsCard(items: collections, onTap: onRecentTap),
      ],
      if (onOpenBundles != null) ...[
        if (credentials.isNotEmpty ||
            documents.isNotEmpty ||
            collections.isNotEmpty)
          const SizedBox(height: 18),
        CredenceSectionLabel(
          label: context.l10n.bundlesTitle,
          padding: EdgeInsets.zero,
          trailing: _PreviewSectionAction(onTap: onOpenBundles),
        ),
        const SizedBox(height: 10),
        _PreviewCard(
          icon: Icons.folder_zip_rounded,
          title: context.l10n.bundlesTitle,
          subtitle: context.l10n.bundlesEmptySubtitle,
          color: context.appPalette.primary,
          background: context.appPalette.primarySoft,
          onTap: onOpenBundles!,
        ),
      ],
      if (taskItem != null) ...[
        if (credentials.isNotEmpty ||
            documents.isNotEmpty ||
            collections.isNotEmpty ||
            onOpenBundles != null)
          const SizedBox(height: 18),
        CredenceSectionLabel(
          label: context.l10n.navTasks,
          padding: EdgeInsets.zero,
          trailing: _PreviewSectionAction(onTap: onOpenTasks),
        ),
        const SizedBox(height: 10),
        _PreviewCard(
          icon: Icons.checklist_rounded,
          title: context.l10n.navTasks,
          subtitle: taskItem.subtitle,
          color: const Color(0xFFEC4899),
          background: const Color(0xFFFCE7F3),
          onTap:
              onOpenTasks ??
              () => onQuickTap(taskItem.sourceType, taskItem.sourceId),
        ),
      ],
      if (showSecureNotes) ...[
        if (credentials.isNotEmpty ||
            documents.isNotEmpty ||
            collections.isNotEmpty ||
            onOpenBundles != null ||
            taskItem != null)
          const SizedBox(height: 18),
        CredenceSectionLabel(
          label: context.l10n.secureNotesTitle,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 10),
        _PreviewCard(
          icon: Icons.note_alt_rounded,
          title: context.l10n.secureNotesTitle,
          subtitle: context.l10n.secureNotesSubtitle,
          color: const Color(0xFFB87818),
          background: const Color(0xFFFFF3D8),
          onTap: onOpenSecureNotes,
        ),
      ],
    ];

    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }
}

class _PreviewSectionAction extends StatelessWidget {
  const _PreviewSectionAction({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return const SizedBox.shrink();

    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            context.l10n.homeViewAll,
            style: TextStyle(
              fontFamily: homeFontBody,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewRowsCard extends StatelessWidget {
  const _PreviewRowsCard({required this.items, required this.onTap});

  final List<RecentItemEntity> items;
  final ValueChanged<RecentItemEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return CredenceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _PreviewRecentRow(item: items[i], onTap: () => onTap(items[i])),
            if (i < items.length - 1) Divider(height: 1, color: palette.stroke),
          ],
        ],
      ),
    );
  }
}

class _PreviewRecentRow extends StatelessWidget {
  const _PreviewRecentRow({required this.item, required this.onTap});

  final RecentItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _SourceAvatar.recent(item, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: homeFontBody,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_recentTypeLabel(context, item.sourceType)} · ${item.subtitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: homeFontMono,
                      fontSize: 12.3,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _relativeTime(context, item.modifiedAt),
              style: TextStyle(
                fontFamily: homeFontMono,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.25,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CredenceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _SoftIcon(
            icon: icon,
            background: isDark ? color.withValues(alpha: 0.16) : background,
            color: color,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: homeFontBody,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: homeFontBody,
                    fontSize: 12.2,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 22, color: palette.textMuted),
        ],
      ),
    );
  }
}

class _HomeVaultHealthExpandedPage extends StatelessWidget {
  const _HomeVaultHealthExpandedPage({required this.dashboard});

  final HomeDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final healthIssueCount = dashboard.insights.totalIssues;
    final score = _healthScore(healthIssueCount);
    final rows = _insightRows(context, dashboard.insights);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 860
                ? 900.0
                : double.infinity;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CredenceIconButton(
                            icon: Icons.chevron_left_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          CredenceIconButton(
                            icon: Icons.more_horiz_rounded,
                            onTap: null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.vaultHealthPageTitle.toUpperCase(),
                        style: TextStyle(
                          fontFamily: homeFontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.25,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$score ${l10n.vaultHealthOut}',
                        style: TextStyle(
                          fontFamily: homeFontDisplay,
                          fontSize: 30,
                          height: 1.04,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          fontFeatures: homeTabularFigures,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        healthIssueCount == 0
                            ? l10n.vaultHealthAllGood
                            : l10n.vaultHealthIssuesTitle(healthIssueCount),
                        style: TextStyle(
                          fontFamily: homeFontBody,
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _VaultHealthScoreCard(
                        score: score,
                        issueCount: healthIssueCount,
                        dashboard: dashboard,
                      ),
                      const SizedBox(height: 22),
                      CredenceSectionLabel(
                        label: l10n.homeCategories,
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 10),
                      _VaultHealthCategoryCard(insights: dashboard.insights),
                      const SizedBox(height: 22),
                      CredenceSectionLabel(
                        label: healthIssueCount == 0
                            ? l10n.vaultHealthNoIssues
                            : l10n.vaultHealthIssuesTitle(healthIssueCount),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 10),
                      if (rows.isEmpty)
                        const _AllGoodAttentionCard()
                      else
                        CredenceCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < rows.length; i++) ...[
                                _InsightMiniRow(row: rows[i]),
                                if (i < rows.length - 1)
                                  Divider(height: 1, color: palette.stroke),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VaultHealthScoreCard extends StatelessWidget {
  const _VaultHealthScoreCard({
    required this.score,
    required this.issueCount,
    required this.dashboard,
  });

  final int score;
  final int issueCount;
  final HomeDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final scoreColor = issueCount == 0 ? palette.success : palette.warning;

    return CredenceCard(
      backgroundColor: palette.primarySoft.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.32 : 1,
      ),
      borderColor: palette.primary.withValues(alpha: 0.18),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: scoreColor,
                    backgroundColor: palette.stroke,
                  ),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    fontFamily: homeFontDisplay,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    fontFeatures: homeTabularFigures,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScoreMetaLine(
                  label: context.l10n.homeIssues,
                  value: '$issueCount',
                ),
                const SizedBox(height: 10),
                _ScoreMetaLine(
                  label: context.l10n.homeSmartReminders,
                  value: '${dashboard.smartReminders.length}',
                ),
                const SizedBox(height: 10),
                _ScoreMetaLine(
                  label: context.l10n.homeItems,
                  value: '${dashboard.totalVaultItems}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreMetaLine extends StatelessWidget {
  const _ScoreMetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: homeFontMono,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: palette.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: homeFontMono,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontFeatures: homeTabularFigures,
            color: palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _VaultHealthCategoryCard extends StatelessWidget {
  const _VaultHealthCategoryCard({required this.insights});

  final HomeInsights insights;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final rows = [
      _HealthCategoryData(
        label: context.l10n.navCredentials,
        value: insights.securityWarnings,
        color: palette.danger,
      ),
      _HealthCategoryData(
        label: context.l10n.homeExpiringDocuments,
        value: insights.expiringDocuments,
        color: palette.warning,
      ),
      _HealthCategoryData(
        label: context.l10n.homeMissingAttention,
        value: insights.missingFiles,
        color: palette.danger,
      ),
      _HealthCategoryData(
        label: context.l10n.navTasks,
        value: insights.incompleteChecklists,
        color: const Color(0xFFEC4899),
      ),
    ];
    final maxValue = rows.fold<int>(
      1,
      (currentMax, row) => math.max(currentMax, row.value),
    );

    return CredenceCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _VaultHealthCategoryRow(data: rows[i], maxValue: maxValue),
            if (i < rows.length - 1) Divider(height: 1, color: palette.stroke),
          ],
        ],
      ),
    );
  }
}

class _HealthCategoryData {
  const _HealthCategoryData({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _VaultHealthCategoryRow extends StatelessWidget {
  const _VaultHealthCategoryRow({required this.data, required this.maxValue});

  final _HealthCategoryData data;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final progress = data.value == 0 ? 1.0 : data.value / maxValue;
    final color = data.value == 0 ? palette.success : data.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: homeFontBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Text(
                '${data.value}',
                style: TextStyle(
                  fontFamily: homeFontMono,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFeatures: homeTabularFigures,
                  color: data.value == 0 ? palette.textMuted : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              color: color,
              backgroundColor: palette.surfaceSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.onPrimaryTap});

  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    return CredenceCard(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_rounded, size: 38, color: palette.primary),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.homeSetupEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: homeFontDisplay,
              fontSize: 22,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeSetupEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: homeFontBody,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPrimaryTap,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.homeAddFirstItem),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        18,
        horizontalPadding,
        34,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 110, height: 10),
                    SizedBox(height: 10),
                    _SkeletonBox(width: 180, height: 28),
                  ],
                ),
              ),
              _SkeletonBox(width: 42, height: 42, radius: 21),
            ],
          ),
          const SizedBox(height: 18),
          const _SkeletonBox(width: double.infinity, height: 50, radius: 16),
          const SizedBox(height: 18),
          const _SkeletonBox(width: double.infinity, height: 154, radius: 26),
          const SizedBox(height: 20),
          const _SkeletonBox(width: 170, height: 12),
          const SizedBox(height: 10),
          const _SkeletonBox(width: double.infinity, height: 82, radius: 22),
          const SizedBox(height: 10),
          const _SkeletonBox(width: double.infinity, height: 82, radius: 22),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: _SkeletonBox(height: 112, radius: 22)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBox(height: 112, radius: 22)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, required this.height, this.radius = 10});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({
    required this.icon,
    required this.background,
    required this.color,
    this.size = 42,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color background;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class _SourceAvatar extends StatelessWidget {
  const _SourceAvatar._({
    required this.icon,
    required this.color,
    required this.background,
    required this.size,
    this.path,
  });

  factory _SourceAvatar.recent(RecentItemEntity item, {required double size}) {
    final color = _recentColor(item.sourceType);
    return _SourceAvatar._(
      icon: _recentIcon(item.sourceType),
      color: color,
      background: color.withValues(alpha: 0.12),
      size: size,
      path: item.previewImagePath,
    );
  }

  factory _SourceAvatar.pinned(PinnedItemEntity item, {required double size}) {
    final color = _sourceStringColor(item.sourceType);
    return _SourceAvatar._(
      icon: _sourceStringIcon(item.sourceType),
      color: color,
      background: color.withValues(alpha: 0.12),
      size: size,
      path: item.logoPath,
    );
  }

  factory _SourceAvatar.quick(
    QuickAccessItemEntity item, {
    required double size,
  }) {
    final color = _quickItemColorStatic(item.sourceType);
    return _SourceAvatar._(
      icon: _sourceStringIcon(item.sourceType),
      color: color,
      background: color.withValues(alpha: 0.12),
      size: size,
      path: item.logoPath,
    );
  }

  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final String? path;

  @override
  Widget build(BuildContext context) {
    final resolvedPath = path == null
        ? null
        : LocalAssetPathResolver.resolveRuntimePathSync(path!);
    if (resolvedPath != null &&
        resolvedPath.isNotEmpty &&
        File(resolvedPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.32),
        child: Image.file(
          File(resolvedPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          cacheHeight: (size * 3).round(),
        ),
      );
    }

    return _SoftIcon(
      icon: icon,
      background: background,
      color: color,
      size: size,
      iconSize: size * 0.48,
    );
  }
}

List<QuickAccessItemEntity> _flattenQuickAccess(
  List<QuickAccessGroupEntity> groups,
) {
  final flattened = <QuickAccessItemEntity>[];
  for (final group in groups) {
    for (final item in group.items) {
      if (item.children.isEmpty && item.sourceType != 'aggregate') {
        flattened.add(item);
      } else {
        flattened.addAll(
          item.children.where((child) => child.sourceType != 'aggregate'),
        );
      }
    }
  }
  return flattened;
}

QuickAccessItemEntity? _firstTaskList(List<QuickAccessGroupEntity> groups) {
  for (final item in _flattenQuickAccess(groups)) {
    if (item.sourceType == 'task_list') return item;
  }
  return null;
}

int _healthScore(int issueCount) {
  final raw = 100 - issueCount * 7;
  return raw.clamp(56, 100);
}

List<_InsightRowData> _insightRows(
  BuildContext context,
  HomeInsights insights,
) {
  final palette = context.appPalette;
  final rows = <_InsightRowData>[];
  if (insights.expiringDocuments > 0) {
    rows.add(
      _InsightRowData(
        icon: Icons.event_busy_rounded,
        title: context.l10n.homeExpiringDocuments,
        subtitle: '${insights.expiringDocuments} ${context.l10n.homeItems}',
        color: palette.warning,
      ),
    );
  }
  if (insights.missingFiles > 0) {
    rows.add(
      _InsightRowData(
        icon: Icons.warning_amber_rounded,
        title: context.l10n.homeMissingAttention,
        subtitle: '${insights.missingFiles} ${context.l10n.homeItems}',
        color: palette.danger,
      ),
    );
  }
  if (insights.incompleteChecklists > 0) {
    rows.add(
      _InsightRowData(
        icon: Icons.checklist_rounded,
        title: context.l10n.navTasks,
        subtitle: '${insights.incompleteChecklists} ${context.l10n.homeIssues}',
        color: const Color(0xFFEC4899),
      ),
    );
  }
  if (insights.securityWarnings > 0) {
    rows.add(
      _InsightRowData(
        icon: Icons.lock_open_rounded,
        title: context.l10n.navCredentials,
        subtitle: '${insights.securityWarnings} ${context.l10n.homeAlerts}',
        color: palette.danger,
      ),
    );
  }
  return rows;
}

String _relativeTime(BuildContext context, DateTime dt) {
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return context.l10n.homeRelativeJustNow;
  if (diff.inMinutes < 60) {
    return context.l10n.homeRelativeMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) return context.l10n.homeRelativeHoursAgo(diff.inHours);
  if (diff.inDays == 1) return context.l10n.homeRelativeYesterday;
  if (diff.inDays < 7) return context.l10n.homeRelativeDaysAgo(diff.inDays);
  if (diff.inDays < 31) {
    return context.l10n.homeRelativeWeeksAgo((diff.inDays / 7).floor());
  }
  return context.l10n.homeRelativeMonthsAgo((diff.inDays / 30).floor());
}

int _calendarDayDifference(DateTime from, DateTime to) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  return end.difference(start).inDays;
}

IconData _recentIcon(RecentItemSourceType type) {
  switch (type) {
    case RecentItemSourceType.credential:
      return Icons.lock_rounded;
    case RecentItemSourceType.document:
      return Icons.description_rounded;
    case RecentItemSourceType.collection:
      return Icons.folder_rounded;
  }
}

Color _recentColor(RecentItemSourceType type) {
  switch (type) {
    case RecentItemSourceType.credential:
      return const Color(0xFF3B82F6);
    case RecentItemSourceType.document:
      return const Color(0xFFD97706);
    case RecentItemSourceType.collection:
      return const Color(0xFF1152D4);
  }
}

String _recentTypeLabel(BuildContext context, RecentItemSourceType type) {
  switch (type) {
    case RecentItemSourceType.credential:
      return context.l10n.homeSourceCredential;
    case RecentItemSourceType.document:
      return context.l10n.homeSourceDocument;
    case RecentItemSourceType.collection:
      return context.l10n.homeSourceCollection;
  }
}

IconData _sourceStringIcon(String type) {
  switch (type) {
    case 'credential':
      return Icons.lock_rounded;
    case 'document':
      return Icons.description_rounded;
    case 'collection':
      return Icons.folder_rounded;
    case 'task_list':
      return Icons.checklist_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}

Color _sourceStringColor(String type) {
  switch (type) {
    case 'credential':
      return const Color(0xFF3B82F6);
    case 'document':
      return const Color(0xFFD97706);
    case 'collection':
      return const Color(0xFF1152D4);
    case 'task_list':
      return const Color(0xFFEC4899);
    default:
      return const Color(0xFF64748B);
  }
}

Color _quickItemColor(String sourceType, AppPalette palette) {
  if (sourceType == 'credential') return const Color(0xFF3B82F6);
  if (sourceType == 'document') return const Color(0xFFD97706);
  if (sourceType == 'collection') return const Color(0xFF1152D4);
  if (sourceType == 'task_list') return const Color(0xFFEC4899);
  return palette.primary;
}

Color _quickItemColorStatic(String sourceType) {
  if (sourceType == 'credential') return const Color(0xFF3B82F6);
  if (sourceType == 'document') return const Color(0xFFD97706);
  if (sourceType == 'collection') return const Color(0xFF1152D4);
  if (sourceType == 'task_list') return const Color(0xFFEC4899);
  return const Color(0xFF64748B);
}

String _sourceLabel(BuildContext context, String sourceType) {
  switch (sourceType) {
    case 'credential':
      return context.l10n.homeSourceCredential;
    case 'document':
      return context.l10n.homeSourceDocument;
    case 'collection':
      return context.l10n.homeSourceCollection;
    case 'task_list':
      return context.l10n.navTasks;
    default:
      return context.l10n.navVault;
  }
}
