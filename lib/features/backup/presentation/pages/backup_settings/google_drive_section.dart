// ignore_for_file: unused_element_parameter

part of '../backup_settings_page.dart';

class _GoogleDriveSection extends StatefulWidget {
  const _GoogleDriveSection({
    required this.isUploading,
    required this.isRestoring,
    required this.isBusy,
    required this.isCheckingFreshness,
    required this.canSyncCloudChanges,
    this.freshnessReport,
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
    this.restoreProgress,
    this.restoreMessage,
    this.restoreDetail,
  });

  final bool isUploading;
  final bool isRestoring;
  final bool isBusy;
  final bool isCheckingFreshness;
  final bool canSyncCloudChanges;
  final BackupFreshnessReport? freshnessReport;
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
  final double? restoreProgress;
  final String? restoreMessage;
  final String? restoreDetail;

  @override
  State<_GoogleDriveSection> createState() => _GoogleDriveSectionState();
}

class _GoogleDriveSectionState extends State<_GoogleDriveSection> {
  bool _isConnected = false;
  bool _isLoading = true;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
      final prefs = await syncPrefs.readPrefs();
      final token = prefs.googleDriveAccessToken.trim();
      if (!mounted) return;
      setState(() {
        _isConnected = token.isNotEmpty;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connect() async {
    setState(() => _isAuthenticating = true);
    try {
      final authService = GoogleDriveAuthService();
      final result = await authService.authorize();
      if (!mounted) return;
      if (result != null && result.isValid) {
        final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
        final prefs = await syncPrefs.readPrefs();
        await syncPrefs.writePrefs(
          prefs.copyWith(
            googleDriveAccessToken: result.accessToken,
            selectedCloudProvider: CloudProviderType.googleDrive.key,
          ),
        );
        if (!mounted) return;
        setState(() {
          _isConnected = true;
          _isAuthenticating = false;
        });
        await context.read<BackupCubit>().refreshRemoteStatus();
      } else {
        if (!mounted) return;
        setState(() => _isAuthenticating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.backupAuthFailed)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAuthenticating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.l10n.backupConnectionFailed}: $e')),
      );
    }
  }

  Future<void> _disconnect() async {
    try {
      final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
      final prefs = await syncPrefs.readPrefs();
      await syncPrefs.writePrefs(prefs.copyWith(googleDriveAccessToken: ''));
      if (!mounted) return;
      setState(() => _isConnected = false);
    } catch (e) {
      debugPrint('[GoogleDrive] Disconnect failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.backupDisconnectError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isTransferring = widget.isUploading || widget.isRestoring;
    if (_isLoading && !isTransferring) return const SizedBox.shrink();
    final isConnectedForUi = _isConnected || isTransferring;
    final transferProgress = widget.isRestoring
        ? widget.restoreProgress
        : widget.uploadProgress;
    final effectiveTransferProgress =
        transferProgress ?? (isTransferring ? 0.0 : null);
    final transferMessage = widget.isRestoring
        ? widget.restoreMessage
        : widget.uploadMessage;
    final transferDetail = widget.isRestoring
        ? widget.restoreDetail
        : widget.uploadDetail;
    final syncLabel = _cloudSyncActionLabel(
      providerLabel: 'Google Drive',
      freshnessReport: widget.freshnessReport,
    );
    final actionLabel = widget.isCheckingFreshness
        ? 'Checking changes...'
        : syncLabel;
    final showSyncAction =
        isTransferring ||
        widget.isCheckingFreshness ||
        widget.canSyncCloudChanges;

    return CollectionsSurfaceCard(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isConnectedForUi
                      ? const Color(0xFFE8F5E9)
                      : context.appPalette.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isConnectedForUi
                      ? Icons.add_to_drive_rounded
                      : Icons.cloud_off_rounded,
                  size: 20,
                  color: isConnectedForUi
                      ? const Color(0xFF2E7D32)
                      : context.appPalette.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Drive',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontDisplay,
                        fontSize: 15.5,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.05,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isConnected
                          ? context.l10n.backupConnected
                          : isConnectedForUi
                          ? 'Sync in progress'
                          : context.l10n.backupNotConnected,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontDisplay,
                        fontSize: 13,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: isConnectedForUi
                            ? const Color(0xFF2E7D32)
                            : palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading && isTransferring)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: CupertinoActivityIndicator(radius: 8),
                )
              else if (_isConnected && !isTransferring)
                TextButton(
                  onPressed: _disconnect,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l10n.backupDisconnect,
                    style: const TextStyle(
                      fontFamily: settingsFontDisplay,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE53E3E),
                    ),
                  ),
                )
              else if (!isConnectedForUi)
                TextButton(
                  onPressed: _isAuthenticating ? null : _connect,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isAuthenticating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: collectionsPrimary,
                          ),
                        )
                      : Text(
                          context.l10n.backupConnect,
                          style: const TextStyle(
                            fontFamily: settingsFontDisplay,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: collectionsPrimary,
                          ),
                        ),
                ),
            ],
          ),
          if (isConnectedForUi) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              decoration: BoxDecoration(
                color: palette.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.backupCloudStorage,
                          style: TextStyle(
                            fontFamily: settingsFontDisplay,
                            fontSize: 15,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        widget.isLoadingRemote
                            ? Text(
                                context.l10n.backupCloudChecking,
                                style: TextStyle(
                                  fontFamily: settingsFontDisplay,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: palette.textSecondary,
                                ),
                              )
                            : widget.remoteBackupCount < 0
                            ? Text(
                                context.l10n.backupCloudUnableCheck,
                                style: const TextStyle(
                                  fontFamily: settingsFontDisplay,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.25,
                                  color: Color(0xFFE53E3E),
                                ),
                              )
                            : Text(
                                '${widget.remoteBackupCount} files • ${_formatBytes(widget.remoteStorageBytes)}',
                                style: TextStyle(
                                  fontFamily: settingsFontDisplay,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.25,
                                  color: palette.textPrimary,
                                ),
                              ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<BackupCubit>().refreshRemoteStatus(),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 25,
                      color: collectionsPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (isTransferring && effectiveTransferProgress != null) ...[
              _CloudTransferProgress(
                isRestoring: widget.isRestoring,
                progress: effectiveTransferProgress,
                message: transferMessage,
                detail: transferDetail,
                processedCount: widget.operationProcessedCount,
                totalCount: widget.operationTotalCount,
                entityCount: widget.operationEntityCount,
                fileCount: widget.operationFileCount,
              ),
              const SizedBox(height: 18),
            ],
            if (showSyncAction)
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  onPressed:
                      isTransferring ||
                          widget.isBusy ||
                          widget.isCheckingFreshness
                      ? null
                      : () => _handleCloudSyncPressed(
                          context,
                          widget.freshnessReport,
                          'Google Drive',
                        ),
                  icon: widget.isUploading
                      ? const CupertinoActivityIndicator(radius: 9)
                      : widget.isCheckingFreshness
                      ? const CupertinoActivityIndicator(radius: 9)
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    widget.isUploading ? 'Synchronizing...' : actionLabel,
                    style: const TextStyle(
                      fontFamily: settingsFontDisplay,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: collectionsPrimary,
                    disabledForegroundColor: palette.textMuted,
                    side: const BorderSide(
                      color: collectionsPrimary,
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            if (!isTransferring && widget.remoteBackups.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: palette.stroke),
              const SizedBox(height: 12),
              Text(
                context.l10n.backupCloudBackups,
                style: TextStyle(
                  fontFamily: settingsFontMono,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.remoteBackups.map(
                (backup) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => _showCloudRestoreDialog(context, backup),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_to_drive_rounded,
                            size: 16,
                            color: palette.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              backup.fileName.replaceAll('.enc', ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _formatBytes(backup.sizeBytes),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.download_rounded,
                            size: 16,
                            color: Color(0xFF1152D4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showCloudRestoreDialog(BuildContext context, RemoteBackupInfo backup) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.backupCloudRestoreTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.appPalette.textPrimary,
          ),
        ),
        content: Text(
          backup.fileName.replaceAll('.enc', ''),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.appPalette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonRestore),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !context.mounted) return;
      context.read<BackupCubit>().restoreFromCloud(backup, '').then((success) {
        if (!context.mounted) return;
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<BackupCubit>().state.errorMessage ??
                    context.l10n.backupErrorRestore,
              ),
              backgroundColor: context.appPalette.danger,
            ),
          );
          return;
        }
        _showBackupRestoreSuccessDialog(context);
      });
    });
  }
}

// ── iCloud Section ──
