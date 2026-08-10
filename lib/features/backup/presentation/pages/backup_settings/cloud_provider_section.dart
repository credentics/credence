// ignore_for_file: unused_element_parameter

part of '../backup_settings_page.dart';

class _CloudProviderSection extends StatefulWidget {
  const _CloudProviderSection({
    required this.backupState,
    required this.isUploading,
    required this.isRestoring,
    required this.isBusy,
    required this.hasBackups,
    this.remoteBackupCount = 0,
    this.remoteStorageBytes = 0,
    this.isLoadingRemote = false,
    this.remoteBackups = const [],
    this.uploadProgress,
    this.uploadMessage,
    this.uploadDetail,
    this.operationProcessedCount,
    this.operationTotalCount,
    this.operationEntityCount = 0,
    this.operationFileCount = 0,
    this.dropboxSessionExpired = false,
    this.restoreProgress,
    this.restoreMessage,
    this.restoreDetail,
  });

  final BackupState backupState;
  final bool isUploading;
  final bool isRestoring;
  final bool isBusy;
  final bool hasBackups;
  final int remoteBackupCount;
  final int remoteStorageBytes;
  final bool isLoadingRemote;
  final List<RemoteBackupInfo> remoteBackups;
  final double? uploadProgress;
  final String? uploadMessage;
  final String? uploadDetail;
  final int? operationProcessedCount;
  final int? operationTotalCount;
  final int operationEntityCount;
  final int operationFileCount;
  final bool dropboxSessionExpired;
  final double? restoreProgress;
  final String? restoreMessage;
  final String? restoreDetail;

  @override
  State<_CloudProviderSection> createState() => _CloudProviderSectionState();
}

class _CloudProviderSectionState extends State<_CloudProviderSection> {
  CloudProviderType _selected = CloudProviderType.dropbox;
  VaultSyncPrefsDto _prefs = const VaultSyncPrefsDto.defaults();
  BackupFreshnessReport? _freshnessReport;
  bool _isLoading = true;
  bool _isRefreshingFreshness = false;
  bool _refreshFreshnessAgain = false;
  bool _isLoadingFreshness = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedProvider();
  }

  @override
  void didUpdateWidget(covariant _CloudProviderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final uploadFinished = oldWidget.isUploading && !widget.isUploading;
    final restoreFinished = oldWidget.isRestoring && !widget.isRestoring;
    final remoteCheckFinished =
        oldWidget.isLoadingRemote && !widget.isLoadingRemote;
    if (uploadFinished || restoreFinished || remoteCheckFinished) {
      unawaited(_refreshSelectedProviderAndFreshness());
    }
  }

  Future<void> _loadSelectedProvider() async {
    await _refreshSelectedProviderAndFreshness(setLoading: true);
  }

  Future<void> _refreshSelectedProviderAndFreshness({
    bool setLoading = false,
  }) async {
    if (_isRefreshingFreshness) {
      _refreshFreshnessAgain = true;
      return;
    }
    _isRefreshingFreshness = true;
    try {
      if (setLoading && mounted) {
        setState(() => _isLoading = true);
      }
      final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
      final prefs = await syncPrefs.readPrefs();
      final saved = CloudProviderTypeX.fromKey(prefs.selectedCloudProvider);
      if (!mounted) return;
      setState(() {
        _selected = saved ?? CloudProviderType.dropbox;
        _prefs = prefs;
        _isLoading = false;
      });
      await _loadFreshnessReport(prefs);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    } finally {
      _isRefreshingFreshness = false;
      if (_refreshFreshnessAgain && mounted) {
        _refreshFreshnessAgain = false;
        unawaited(_refreshSelectedProviderAndFreshness());
      }
    }
  }

  Future<void> _onProviderSelected(CloudProviderType type) async {
    setState(() {
      _selected = type;
      _prefs = _prefs.copyWith(selectedCloudProvider: type.key);
    });
    try {
      final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
      final prefs = await syncPrefs.readPrefs();
      final updatedPrefs = prefs.copyWith(
        selectedCloudProvider: type.key,
        lastRemoteRevision: 0,
        lastRemoteChecksum: '',
        lastRemoteDeviceId: '',
      );
      await syncPrefs.writePrefs(updatedPrefs);
      if (!mounted) return;
      setState(() => _prefs = updatedPrefs);
      unawaited(_loadFreshnessReport(updatedPrefs));
      unawaited(context.read<BackupCubit>().refreshRemoteStatus());
    } catch (_) {
      // Best-effort persist.
    }
  }

  Future<void> _loadFreshnessReport(VaultSyncPrefsDto prefs) async {
    if (mounted) {
      setState(() => _isLoadingFreshness = true);
    }
    try {
      final report = await buildBackupFreshnessReport(prefs);
      if (!mounted) return;
      setState(() {
        _freshnessReport = report;
        _isLoadingFreshness = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _freshnessReport = const BackupFreshnessReport(
          percentage: 0,
          totalCount: 0,
          pendingCount: 0,
          topPendingItems: [],
          currentContentChecksum: null,
          currentContentBackedUp: false,
          currentVaultChecked: true,
        );
        _isLoadingFreshness = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTransferring = widget.isUploading || widget.isRestoring;
    if (_isLoading && !isTransferring) return const SizedBox.shrink();
    final coverage = backupCoverageSummary(
      state: widget.backupState,
      provider: _selected,
      prefs: _prefs,
      currentContentChecksum: _freshnessReport?.currentContentChecksum,
      currentVaultChecked: _freshnessReport?.currentVaultChecked ?? false,
      currentContentBackedUp: _freshnessReport?.currentContentBackedUp ?? false,
      remoteHasNewerCopy: _freshnessReport?.remoteHasNewerCopy ?? false,
    );
    final isCheckingCoverage =
        _isLoadingFreshness ||
        _freshnessReport == null ||
        widget.isLoadingRemote;
    final canDiscardFromSelectedProvider = switch (_selected) {
      CloudProviderType.dropbox =>
        _prefs.dropboxAccessToken.trim().isNotEmpty ||
            _prefs.dropboxRefreshToken.trim().isNotEmpty,
      CloudProviderType.googleDrive =>
        _prefs.googleDriveAccessToken.trim().isNotEmpty,
      CloudProviderType.iCloud => false,
    };
    final canSyncCloudChanges =
        !_isLoadingFreshness &&
        ((_freshnessReport?.remoteHasNewerCopy ?? false) ||
            (!(_freshnessReport?.currentContentBackedUp ?? false) &&
                (_freshnessReport?.pendingCount ?? 0) > 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: CloudProviderType.values.map((type) {
              final isSelected = type == _selected;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ProviderChip(
                  label: type.label,
                  icon: _providerIcon(type),
                  isSelected: isSelected,
                  isDisabled: false,
                  onTap: () => _onProviderSelected(type),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _CloudCoverageIndicator(
          summary: coverage,
          provider: _selected,
          freshnessReport: _freshnessReport,
          isChecking: isCheckingCoverage,
          onReviewAll:
              _freshnessReport == null ||
                  (_freshnessReport?.pendingCount ?? 0) <= 0
              ? null
              : () => showPendingBackupChangesSheet(
                  context,
                  _freshnessReport,
                  providerLabel: _selected.label,
                ),
          onDiscardLocalChanges:
              _freshnessReport == null ||
                  (_freshnessReport?.pendingCount ?? 0) <= 0 ||
                  backupFreshnessIsMetadataOnly(_freshnessReport) ||
                  isTransferring ||
                  !canDiscardFromSelectedProvider
              ? null
              : () => _handleDiscardLocalChangesPressed(
                  context,
                  _freshnessReport,
                  _selected.label,
                ),
        ),
        const SizedBox(height: 18),
        if (_selected == CloudProviderType.dropbox)
          _DropboxSection(
            isUploading: widget.isUploading,
            isRestoring: widget.isRestoring,
            isBusy: widget.isBusy,
            isCheckingFreshness: isCheckingCoverage,
            hasBackups: widget.hasBackups,
            freshnessReport: _freshnessReport,
            remoteBackupCount: widget.remoteBackupCount,
            remoteStorageBytes: widget.remoteStorageBytes,
            isLoadingRemote: widget.isLoadingRemote,
            remoteBackups: widget.remoteBackups,
            uploadProgress: widget.uploadProgress,
            uploadMessage: widget.uploadMessage,
            uploadDetail: widget.uploadDetail,
            operationProcessedCount: widget.operationProcessedCount,
            operationTotalCount: widget.operationTotalCount,
            operationEntityCount: widget.operationEntityCount,
            operationFileCount: widget.operationFileCount,
            sessionExpired: widget.dropboxSessionExpired,
            restoreProgress: widget.restoreProgress,
            restoreMessage: widget.restoreMessage,
            restoreDetail: widget.restoreDetail,
            canSyncCloudChanges: canSyncCloudChanges,
          )
        else if (_selected == CloudProviderType.iCloud)
          _ICloudSection(
            isUploading: widget.isUploading,
            isBusy: widget.isBusy,
            hasBackups: widget.hasBackups,
          )
        else
          _GoogleDriveSection(
            isUploading: widget.isUploading,
            isRestoring: widget.isRestoring,
            isBusy: widget.isBusy,
            isCheckingFreshness: isCheckingCoverage,
            freshnessReport: _freshnessReport,
            remoteBackupCount: widget.remoteBackupCount,
            remoteStorageBytes: widget.remoteStorageBytes,
            isLoadingRemote: widget.isLoadingRemote,
            remoteBackups: widget.remoteBackups,
            uploadProgress: widget.uploadProgress,
            uploadMessage: widget.uploadMessage,
            uploadDetail: widget.uploadDetail,
            operationProcessedCount: widget.operationProcessedCount,
            operationTotalCount: widget.operationTotalCount,
            operationEntityCount: widget.operationEntityCount,
            operationFileCount: widget.operationFileCount,
            restoreProgress: widget.restoreProgress,
            restoreMessage: widget.restoreMessage,
            restoreDetail: widget.restoreDetail,
            canSyncCloudChanges: canSyncCloudChanges,
          ),
      ],
    );
  }

  IconData _providerIcon(CloudProviderType type) {
    return switch (type) {
      CloudProviderType.dropbox => Icons.cloud_done_rounded,
      CloudProviderType.googleDrive => Icons.add_to_drive_rounded,
      CloudProviderType.iCloud => Icons.cloud_rounded,
    };
  }
}

class _CloudCoverageIndicator extends StatelessWidget {
  const _CloudCoverageIndicator({
    required this.summary,
    required this.provider,
    required this.freshnessReport,
    required this.isChecking,
    required this.onReviewAll,
    required this.onDiscardLocalChanges,
  });

  final BackupCoverageSummary summary;
  final CloudProviderType provider;
  final BackupFreshnessReport? freshnessReport;
  final bool isChecking;
  final VoidCallback? onReviewAll;
  final VoidCallback? onDiscardLocalChanges;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = isChecking
        ? collectionsPrimary
        : _coverageColor(palette, summary.level);
    final icon = isChecking ? Icons.sync_rounded : _coverageIcon(summary.level);
    final pendingItems =
        freshnessReport?.topPendingItems ?? const <BackupFreshnessItem>[];
    final isMetadataOnly = backupFreshnessIsMetadataOnly(freshnessReport);
    final title = isChecking
        ? 'Checking backup'
        : isMetadataOnly
        ? 'Backup metadata needs sync'
        : summary.title;
    final detail = isChecking
        ? 'Calculating local changes and ${provider.label} status.'
        : isMetadataOnly
        ? 'A backup metadata update needs to be uploaded to ${provider.label}.'
        : summary.detail;
    final percentage = freshnessReport?.percentage;
    final value = isChecking
        ? 'CHECK'
        : percentage == null
        ? summary.value.toUpperCase()
        : '${percentage.clamp(0, 100)}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isChecking
                    ? SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontDisplay,
                        color: palette.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontDisplay,
                        color: palette.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(minWidth: 76, maxWidth: 86),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontDisplay,
                        color: palette.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontMono,
                        color: color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.65,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isChecking) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: color.withValues(alpha: 0.18)),
            const SizedBox(height: 8),
            const _BackupPendingLoadingPreviewList(),
          ] else if (pendingItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: color.withValues(alpha: 0.18)),
            const SizedBox(height: 8),
            _BackupPendingPreviewList(
              items: pendingItems,
              pendingCount: freshnessReport?.pendingCount ?? 0,
              onReviewAll: onReviewAll,
              onDiscardLocalChanges: onDiscardLocalChanges,
            ),
          ],
        ],
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

class _BackupPendingPreviewList extends StatelessWidget {
  const _BackupPendingPreviewList({
    required this.items,
    required this.pendingCount,
    this.onReviewAll,
    this.onDiscardLocalChanges,
  });

  final List<BackupFreshnessItem> items;
  final int pendingCount;
  final VoidCallback? onReviewAll;
  final VoidCallback? onDiscardLocalChanges;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'PENDING CHANGES',
                style: TextStyle(
                  fontFamily: settingsFontMono,
                  color: palette.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.75,
                ),
              ),
            ),
            Text(
              pendingCount <= items.length
                  ? '$pendingCount'
                  : '${items.length} of $pendingCount',
              style: TextStyle(
                fontFamily: settingsFontMono,
                color: palette.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.55,
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
                          fontFamily: settingsFontDisplay,
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
        const SizedBox(height: 5),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                Icon(
                  _pendingIcon(item.typeLabel),
                  size: 14,
                  color: palette.textMuted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: settingsFontDisplay,
                          color: palette.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.detail.trim().isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          item.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: settingsFontDisplay,
                            color: palette.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            height: 1.08,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: settingsFontMono,
                    color: palette.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                  ),
                ),
              ],
            ),
          ),
        if (onDiscardLocalChanges != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: onDiscardLocalChanges,
              icon: const Icon(Icons.restore_rounded, size: 16),
              label: const Text('Discard local changes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.danger,
                side: BorderSide(color: palette.danger.withValues(alpha: 0.30)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: settingsFontDisplay,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _pendingIcon(String typeLabel) {
    return pendingBackupChangeIcon(typeLabel);
  }
}

class _BackupPendingLoadingPreviewList extends StatelessWidget {
  const _BackupPendingLoadingPreviewList();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'SCANNING CHANGES',
                style: TextStyle(
                  fontFamily: settingsFontMono,
                  color: palette.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.75,
                ),
              ),
            ),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        for (var index = 0; index < 3; index++)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 7),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: palette.stroke.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: palette.stroke.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(width: 34),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Provider Chip ──

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.isDisabled = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    final labelStyle = TextStyle(
      fontFamily: settingsFontDisplay,
      fontSize: 13,
      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
      letterSpacing: -0.05,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final buttonChild = Text(label, maxLines: 1, style: labelStyle);

    if (isSelected) {
      return SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: isDisabled ? null : onTap,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: palette.textPrimary,
            foregroundColor: palette.surface,
            disabledBackgroundColor: palette.textMuted,
            disabledForegroundColor: palette.surface,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: shape,
          ),
          icon: Icon(icon, size: 18),
          label: buttonChild,
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: isDisabled ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDisabled ? palette.textMuted : palette.textPrimary,
          disabledForegroundColor: palette.textMuted,
          side: BorderSide(color: palette.stroke),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: shape,
        ),
        icon: Icon(icon, size: 18),
        label: buttonChild,
      ),
    );
  }
}

class _CloudTransferProgress extends StatefulWidget {
  const _CloudTransferProgress({
    required this.isRestoring,
    this.progress,
    this.message,
    this.detail,
    this.processedCount,
    this.totalCount,
    this.entityCount = 0,
    this.fileCount = 0,
  });

  final bool isRestoring;
  final double? progress;
  final String? message;
  final String? detail;
  final int? processedCount;
  final int? totalCount;
  final int entityCount;
  final int fileCount;

  @override
  State<_CloudTransferProgress> createState() => _CloudTransferProgressState();
}

class _CloudTransferProgressState extends State<_CloudTransferProgress> {
  late final DateTime _startedAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final clampedProgress = widget.progress?.clamp(0.0, 1.0).toDouble();
    final percent = clampedProgress == null
        ? null
        : '${(clampedProgress * 100).round()}%';
    final label =
        widget.message ??
        (widget.isRestoring
            ? 'Restoring vault...'
            : 'Synchronizing changes...');
    final detail = widget.detail?.trim() ?? '';
    final stepLabel = _stepLabel();
    final elapsedLabel = _elapsedLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: settingsFontDisplay,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: palette.textSecondary,
                ),
              ),
            ),
            if (percent != null)
              Text(
                percent,
                style: const TextStyle(
                  fontFamily: settingsFontDisplay,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: collectionsPrimary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _ProgressPill(label: stepLabel, icon: Icons.route_rounded),
            if (widget.fileCount > 0)
              _ProgressPill(
                label: '${widget.fileCount} files',
                icon: Icons.description_rounded,
              ),
            if (widget.entityCount > 0)
              _ProgressPill(
                label: '${widget.entityCount} records',
                icon: Icons.storage_rounded,
              ),
            _ProgressPill(label: elapsedLabel, icon: Icons.timer_rounded),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clampedProgress,
            backgroundColor: palette.stroke.withValues(alpha: 0.55),
            valueColor: const AlwaysStoppedAnimation<Color>(collectionsPrimary),
            minHeight: 6,
          ),
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: settingsFontDisplay,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.15,
              color: palette.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  String _stepLabel() {
    final processed = widget.processedCount;
    final total = widget.totalCount;
    if (processed != null && total != null && total > 1) {
      return '${processed.clamp(0, total)} of $total';
    }
    final progress = widget.progress ?? 0;
    if (progress < 0.12) return 'Scanning';
    if (progress < 0.16) return 'Planning';
    if (progress < 0.38) return 'Folders';
    if (progress < 0.92) {
      return widget.isRestoring ? 'Downloading' : 'Uploading';
    }
    if (progress < 1) return 'Finalizing';
    return 'Complete';
  }

  String _elapsedLabel() {
    final elapsed = DateTime.now().difference(_startedAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: palette.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: settingsFontDisplay,
              color: palette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

String _cloudSyncActionLabel({
  required String providerLabel,
  required BackupFreshnessReport? freshnessReport,
}) {
  final pendingCount = freshnessReport?.pendingCount ?? 0;
  final isCurrent = freshnessReport?.currentContentBackedUp ?? false;
  if (backupFreshnessHasRemoteChanges(freshnessReport)) {
    return 'Synchronize from $providerLabel';
  }
  if (backupFreshnessIsMetadataOnly(freshnessReport)) {
    return 'Synchronize backup metadata';
  }
  final deleteCount = backupFreshnessDeleteCount(freshnessReport);
  if (!isCurrent && deleteCount > 0) {
    final deleteLabel = deleteCount == 1 ? 'deletion' : 'deletions';
    return 'Review $deleteCount $deleteLabel';
  }
  if (!isCurrent && pendingCount > 0) {
    final changeLabel = pendingCount == 1 ? 'change' : 'changes';
    return 'Synchronize $pendingCount $changeLabel';
  }
  return 'Synchronize with $providerLabel';
}

Future<void> _handleCloudSyncPressed(
  BuildContext context,
  BackupFreshnessReport? report,
  String providerLabel,
) async {
  if (!backupFreshnessHasDeletes(report)) {
    context.read<BackupCubit>().uploadToCloud();
    return;
  }
  final decision = await showPendingBackupChangesSheet(
    context,
    report,
    requireDeleteDecision: true,
    providerLabel: providerLabel,
  );
  if (!context.mounted || decision == null) return;
  context.read<BackupCubit>().uploadToCloud(
    allowDeletes: decision == PendingBackupChangesDecision.confirmDeletes,
  );
}

Future<void> _handleDiscardLocalChangesPressed(
  BuildContext context,
  BackupFreshnessReport? report,
  String providerLabel,
) async {
  final confirmed = await showDiscardLocalChangesConfirmation(
    context,
    report,
    providerLabel: providerLabel,
  );
  if (!context.mounted || !confirmed) return;

  final success = await context
      .read<BackupCubit>()
      .discardLocalChangesFromCloud();
  if (!context.mounted || success) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        context.read<BackupCubit>().state.errorMessage ??
            'Could not discard local changes.',
      ),
      backgroundColor: context.appPalette.danger,
    ),
  );
}

// ── Google Drive Section ──
