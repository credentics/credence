import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_prefs_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/cloud_provider_type.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/backup_state.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/shared_backup_cubit.dart';
import 'package:pass_doc_manager/features/backup/presentation/pages/backup_settings_page.dart';
import 'package:pass_doc_manager/features/backup/presentation/support/backup_coverage_summary.dart';
import 'package:pass_doc_manager/features/backup/presentation/support/backup_freshness_report.dart';
import 'package:pass_doc_manager/features/backup/presentation/widgets/pending_backup_changes_sheet.dart';

const _backupCoverageFontDisplay = 'Manrope';
const _backupCoverageFontMono = 'JetBrains Mono';

class BackupCoverageHomeCard extends StatefulWidget {
  const BackupCoverageHomeCard({super.key});

  @override
  State<BackupCoverageHomeCard> createState() => _BackupCoverageHomeCardState();
}

class _BackupCoverageHomeCardState extends State<BackupCoverageHomeCard> {
  static const _minimumBackgroundCheckInterval = Duration(minutes: 30);
  static BackupFreshnessReport? _cachedFreshnessReport;
  static VaultSyncPrefsDto? _cachedPrefs;
  static BackupState? _cachedBackupState;
  static DateTime? _lastBackgroundCheckAt;
  static Future<void>? _activeBackgroundCheck;

  late final BackupCubit _backupCubit;
  VaultSyncPrefsDto _prefs = const VaultSyncPrefsDto.defaults();
  BackupFreshnessReport? _freshnessReport;

  @override
  void initState() {
    super.initState();
    _backupCubit = sharedBackupCubit;
    _prefs = _cachedPrefs ?? _prefs;
    _freshnessReport = _cachedFreshnessReport;
    unawaited(_load());
  }

  Future<void> _load() async {
    await _loadPrefs();
    if (_backupCubit.state.viewStatus == BackupViewStatus.initial) {
      await _backupCubit.load();
    }
    _cachedBackupState = _backupCubit.state;
    if (!mounted) return;
    setState(() {});
    unawaited(_startBackgroundCheckIfDue());
  }

  Future<void> _loadPrefs() async {
    try {
      final dataSource = getIt<VaultSyncPrefsLocalDataSource>();
      final prefs = await dataSource.readPrefs();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _cachedPrefs = prefs;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _startBackgroundCheckIfDue() async {
    if (_activeBackgroundCheck != null) {
      await _activeBackgroundCheck;
      if (!mounted) return;
      setState(() {
        _prefs = _cachedPrefs ?? _prefs;
        _freshnessReport = _cachedFreshnessReport ?? _freshnessReport;
      });
      return;
    }
    if (_backupCubit.state.isCreating ||
        _backupCubit.state.isUploading ||
        _backupCubit.state.isRestoring) {
      return;
    }
    final intervalMinutes = _prefs.remoteCheckIntervalMinutes;
    if (intervalMinutes <= 0) return;
    final effectiveInterval = Duration(
      minutes: intervalMinutes < _minimumBackgroundCheckInterval.inMinutes
          ? _minimumBackgroundCheckInterval.inMinutes
          : intervalMinutes,
    );
    final last = _lastBackgroundCheckAt;
    if (last != null && DateTime.now().difference(last) < effectiveInterval) {
      return;
    }
    final task = _runBackgroundCheck();
    _activeBackgroundCheck = task;
    await task.whenComplete(() {
      if (identical(_activeBackgroundCheck, task)) {
        _activeBackgroundCheck = null;
      }
    });
  }

  Future<void> _runBackgroundCheck() async {
    _lastBackgroundCheckAt = DateTime.now();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (_backupCubit.state.viewStatus == BackupViewStatus.initial) {
        await _backupCubit.load();
      }
      await _backupCubit.refreshRemoteStatus();
      await _loadPrefs();
      if (!mounted) return;
      final report = await buildBackupFreshnessReport(_prefs);
      if (!mounted) return;
      _cachedFreshnessReport = report;
      _cachedBackupState = _backupCubit.state;
      setState(() => _freshnessReport = report);
    } catch (error) {
      if (!mounted) return;
      final fallback = const BackupFreshnessReport(
        percentage: 0,
        totalCount: 0,
        pendingCount: 0,
        topPendingItems: [],
        currentContentChecksum: null,
        currentContentBackedUp: false,
        currentVaultChecked: true,
      );
      _cachedFreshnessReport = fallback;
      setState(() => _freshnessReport = fallback);
      debugPrint('[BackupCoverageHomeCard] Background check failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackupCubit, BackupState>(
      bloc: _backupCubit,
      builder: (context, state) {
        if (state.viewStatus == BackupViewStatus.ready) {
          _cachedBackupState = state;
        }
        final effectiveState = _cachedBackupState ?? state;
        final provider =
            CloudProviderTypeX.fromKey(_prefs.selectedCloudProvider) ??
            CloudProviderType.dropbox;
        final summary = backupCoverageSummary(
          state: effectiveState,
          provider: provider,
          prefs: _prefs,
          currentContentChecksum: _freshnessReport?.currentContentChecksum,
          currentVaultChecked: _freshnessReport?.currentVaultChecked ?? false,
          currentContentBackedUp:
              _freshnessReport?.currentContentBackedUp ?? false,
          remoteHasNewerCopy: _freshnessReport?.remoteHasNewerCopy ?? false,
        );
        return _BackupCoverageCardSurface(
          provider: provider,
          summary: summary,
          freshnessReport: _freshnessReport,
          isChecking: false,
          onReviewAll:
              _freshnessReport == null ||
                  (_freshnessReport?.pendingCount ?? 0) <= 0
              ? null
              : () => showPendingBackupChangesSheet(
                  context,
                  _freshnessReport,
                  providerLabel: provider.label,
                ),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BackupSettingsPage())),
        );
      },
    );
  }
}

class _BackupCoverageCardSurface extends StatelessWidget {
  const _BackupCoverageCardSurface({
    required this.provider,
    required this.summary,
    required this.freshnessReport,
    required this.isChecking,
    required this.onReviewAll,
    required this.onTap,
  });

  final CloudProviderType provider;
  final BackupCoverageSummary summary;
  final BackupFreshnessReport? freshnessReport;
  final bool isChecking;
  final VoidCallback? onReviewAll;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final statusColor = _coverageColor(palette, summary.level);
    final icon = _coverageIcon(summary.level);
    final isMetadataOnly =
        !isChecking && backupFreshnessIsMetadataOnly(freshnessReport);
    final quietDetail =
        freshnessReport == null && summary.detail.startsWith('Checking whether')
        ? 'Last known backup state. Updates run quietly in the background.'
        : summary.detail;
    final title = isChecking
        ? 'Checking backup'
        : isMetadataOnly
        ? 'Backup metadata needs sync'
        : summary.title;
    final detail = isChecking
        ? 'Reading local snapshots and ${provider.label} status.'
        : isMetadataOnly
        ? 'A backup metadata update needs to be uploaded to ${provider.label}.'
        : quietDetail;
    final pendingItems = isChecking
        ? const <BackupFreshnessItem>[]
        : (freshnessReport?.topPendingItems ?? const <BackupFreshnessItem>[]);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.stroke),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _backupCoverageFontDisplay,
                            color: palette.textPrimary,
                            fontSize: 16.5,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _backupCoverageFontDisplay,
                            color: palette.textSecondary,
                            fontSize: 12.8,
                            fontWeight: FontWeight.w600,
                            height: 1.28,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ProviderPill(
                    provider: provider,
                    summary: summary,
                    percentage: freshnessReport?.percentage,
                  ),
                ],
              ),
              if (pendingItems.isNotEmpty) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: palette.stroke),
                const SizedBox(height: 10),
                _PendingBackupItemsList(
                  items: pendingItems,
                  pendingCount: freshnessReport?.pendingCount ?? 0,
                  onReviewAll: onReviewAll,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _coverageColor(AppPalette palette, BackupCoverageLevel level) {
    return switch (level) {
      BackupCoverageLevel.complete => palette.success,
      BackupCoverageLevel.partial => palette.warning,
      BackupCoverageLevel.none => palette.danger,
    };
  }

  IconData _coverageIcon(BackupCoverageLevel level) {
    return switch (level) {
      BackupCoverageLevel.complete => Icons.cloud_done_rounded,
      BackupCoverageLevel.partial => Icons.cloud_queue_rounded,
      BackupCoverageLevel.none => Icons.cloud_off_rounded,
    };
  }
}

class _PendingBackupItemsList extends StatelessWidget {
  const _PendingBackupItemsList({
    required this.items,
    required this.pendingCount,
    this.onReviewAll,
  });

  final List<BackupFreshnessItem> items;
  final int pendingCount;
  final VoidCallback? onReviewAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'PENDING CHANGES',
                style: TextStyle(
                  fontFamily: _backupCoverageFontMono,
                  color: palette.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.85,
                ),
              ),
            ),
            Text(
              pendingCount <= items.length
                  ? '$pendingCount'
                  : '${items.length} of $pendingCount',
              style: TextStyle(
                fontFamily: _backupCoverageFontMono,
                color: palette.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
            if (onReviewAll != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onReviewAll,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        color: palette.textPrimary,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Review',
                        style: TextStyle(
                          fontFamily: _backupCoverageFontDisplay,
                          color: palette.textPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                Icon(
                  _itemIcon(item.typeLabel),
                  color: palette.textMuted,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _backupCoverageFontDisplay,
                      color: palette.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.05,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _backupCoverageFontMono,
                    color: palette.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.55,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _itemIcon(String typeLabel) {
    return pendingBackupChangeIcon(typeLabel);
  }
}

class _ProviderPill extends StatelessWidget {
  const _ProviderPill({
    required this.provider,
    required this.summary,
    required this.percentage,
  });

  final CloudProviderType provider;
  final BackupCoverageSummary summary;
  final int? percentage;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final value = percentage == null
        ? summary.value.toUpperCase()
        : '${percentage!.clamp(0, 100)}%';
    return Container(
      constraints: const BoxConstraints(minWidth: 82, maxWidth: 94),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: _pillColor(palette, summary.level),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pillBorderColor(palette, summary.level)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _backupCoverageFontDisplay,
              color: palette.textPrimary,
              fontSize: 12.8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _backupCoverageFontMono,
              color: _pillValueColor(palette, summary.level),
              fontSize: 9.4,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Color _pillColor(AppPalette palette, BackupCoverageLevel level) {
    return switch (level) {
      BackupCoverageLevel.complete => palette.success.withValues(alpha: 0.08),
      BackupCoverageLevel.partial => palette.warning.withValues(alpha: 0.08),
      BackupCoverageLevel.none => palette.danger.withValues(alpha: 0.08),
    };
  }

  Color _pillBorderColor(AppPalette palette, BackupCoverageLevel level) {
    return switch (level) {
      BackupCoverageLevel.complete => palette.success.withValues(alpha: 0.16),
      BackupCoverageLevel.partial => palette.warning.withValues(alpha: 0.16),
      BackupCoverageLevel.none => palette.danger.withValues(alpha: 0.16),
    };
  }

  Color _pillValueColor(AppPalette palette, BackupCoverageLevel level) {
    return switch (level) {
      BackupCoverageLevel.complete => palette.success,
      BackupCoverageLevel.partial => palette.warning,
      BackupCoverageLevel.none => palette.danger,
    };
  }
}
