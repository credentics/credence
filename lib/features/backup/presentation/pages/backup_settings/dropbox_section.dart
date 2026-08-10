// ignore_for_file: unused_element_parameter

part of '../backup_settings_page.dart';

class _DropboxSection extends StatefulWidget {
  const _DropboxSection({
    required this.isUploading,
    required this.isRestoring,
    required this.isBusy,
    required this.isCheckingFreshness,
    required this.hasBackups,
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
    this.sessionExpired = false,
    this.restoreProgress,
    this.restoreMessage,
    this.restoreDetail,
  });

  final bool isUploading;
  final bool isRestoring;
  final bool isBusy;
  final bool isCheckingFreshness;
  final bool hasBackups;
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
  final bool sessionExpired;
  final double? restoreProgress;
  final String? restoreMessage;
  final String? restoreDetail;

  @override
  State<_DropboxSection> createState() => _DropboxSectionState();
}

class _DropboxSectionState extends State<_DropboxSection> {
  final _codeController = TextEditingController();
  final _authService = DropboxAuthService();
  bool _isConnected = false;
  bool _isLoading = true;
  bool _isAuthenticating = false;
  bool _awaitingCode = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
      final prefs = await syncPrefs.readPrefs();
      final token = prefs.dropboxAccessToken.trim();
      final refreshToken = prefs.dropboxRefreshToken.trim();
      final hasPending = await _authService.hasPendingAuthorization();
      if (!mounted) return;
      setState(() {
        _isConnected = token.isNotEmpty || refreshToken.isNotEmpty;
        _awaitingCode = hasPending && !_isConnected;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startAuth() async {
    context.read<BackupCubit>().clearDropboxSessionExpired();
    setState(() => _isAuthenticating = true);
    try {
      await _authService.startAuthorization();
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _awaitingCode = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _exchangeCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isAuthenticating = true);
    try {
      final result = await _authService.exchangeCode(code);
      if (!mounted) return;
      if (result != null && result.isValid) {
        final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
        final prefs = await syncPrefs.readPrefs();
        await syncPrefs.writePrefs(
          prefs.copyWith(
            dropboxAccessToken: result.accessToken,
            dropboxRefreshToken: result.refreshToken ?? '',
            dropboxAccessTokenExpiresAtIso: result.accessTokenExpiresAtIso(),
            selectedCloudProvider: CloudProviderType.dropbox.key,
          ),
        );
        if (!mounted) return;
        context.read<BackupCubit>().clearDropboxSessionExpired();
        setState(() {
          _isConnected = true;
          _awaitingCode = false;
          _isAuthenticating = false;
          _codeController.clear();
        });
        await context.read<BackupCubit>().refreshRemoteStatus();
      } else {
        if (!mounted) return;
        setState(() => _isAuthenticating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.backupAuthFailed)));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _disconnect() async {
    try {
      final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
      final prefs = await syncPrefs.readPrefs();
      await syncPrefs.writePrefs(
        prefs.copyWith(
          dropboxAccessToken: '',
          dropboxRefreshToken: '',
          dropboxAccessTokenExpiresAtIso: '',
        ),
      );
      if (!mounted) return;
      context.read<BackupCubit>().clearDropboxSessionExpired();
      setState(() {
        _isConnected = false;
        _awaitingCode = false;
      });
    } catch (e) {
      debugPrint('[Dropbox] Disconnect failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.backupDisconnectError)),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
      providerLabel: 'Dropbox',
      freshnessReport: widget.freshnessReport,
    );
    // The mirror couldn't be verified (remoteBackupCount == -1) — e.g. a 409
    // because the cloud has no .credence mirror yet. Always offer a push in
    // that state so the user can (re)seed the cloud, even when the freshness
    // check thinks the local checkpoint is already backed up.
    final cannotVerifyRemote = widget.remoteBackupCount < 0;
    final actionLabel = widget.isCheckingFreshness
        ? 'Checking changes...'
        : cannotVerifyRemote && !widget.canSyncCloudChanges
        ? 'Back up to Dropbox'
        : syncLabel;
    final showSyncAction =
        isTransferring ||
        widget.isCheckingFreshness ||
        widget.canSyncCloudChanges ||
        cannotVerifyRemote;

    return CollectionsSurfaceCard(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isConnectedForUi
                      ? const Color(0xFFE8F5E9)
                      : palette.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isConnectedForUi
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  size: 20,
                  color: isConnectedForUi
                      ? const Color(0xFF2E7D32)
                      : palette.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dropbox',
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
                  onPressed: _isAuthenticating ? null : _startAuth,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isAuthenticating
                        ? 'Opening...'
                        : context.l10n.backupConnect,
                    style: const TextStyle(
                      fontFamily: settingsFontDisplay,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: collectionsPrimary,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.sessionExpired && !_isConnected && !_awaitingCode) ...[
            const SizedBox(height: 14),
            _DropboxSessionExpiredBanner(
              onDismiss: () =>
                  context.read<BackupCubit>().clearDropboxSessionExpired(),
            ),
          ],
          if (_awaitingCode && !_isConnected) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appPalette.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appPalette.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.backupGoogleAuthOpened,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    context.l10n.backupGoogleAuthApprove,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: context.l10n.backupAuthCodeHint,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: context.appPalette.textMuted,
                ),
                filled: true,
                fillColor: context.appPalette.surfaceSoft,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.appPalette.stroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.appPalette.stroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: collectionsPrimary,
                    width: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: _isAuthenticating ? null : _exchangeCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: collectionsPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isAuthenticating
                      ? context.l10n.backupConnecting
                      : context.l10n.backupAuthorize,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
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
          ],
          if (isConnectedForUi) ...[
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
                          'Dropbox',
                        ),
                  icon: widget.isUploading
                      ? const CupertinoActivityIndicator(radius: 11)
                      : widget.isCheckingFreshness
                      ? const CupertinoActivityIndicator(radius: 11)
                      : const Icon(Icons.sync_rounded, size: 22),
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
          ],
          if (_isConnected &&
              !widget.isUploading &&
              !widget.isRestoring &&
              widget.remoteBackups.isNotEmpty) ...[
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
                          Icons.cloud_rounded,
                          size: 16,
                          color: context.appPalette.textMuted,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            backup.fileName.replaceAll('.enc', ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.appPalette.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _formatBytes(backup.sizeBytes),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.appPalette.textSecondary,
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
      ),
    );
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              backup.fileName.replaceAll('.enc', ''),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFE8890C),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.backupCloudRestoreWarning,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A5500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.appPalette.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.commonRestore,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFE53E3E),
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !context.mounted) return;
      if (backup.fileName == 'Credence mirror') {
        final cubit = context.read<BackupCubit>();
        cubit.restoreFromCloud(backup, '').then((success) {
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
        return;
      }
      _showPassphraseDialog(
        context,
        title: context.l10n.backupCloudRestoreTitle,
        subtitle: context.l10n.backupRestoreSubtitle,
        actionLabel: context.l10n.commonRestore,
        onConfirm: (passphrase) async {
          final success = await context.read<BackupCubit>().restoreFromCloud(
            backup,
            passphrase,
          );
          if (!context.mounted) {
            return;
          }
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
        },
      );
    });
  }
}

// ── Interrupted Restore Banner ──
