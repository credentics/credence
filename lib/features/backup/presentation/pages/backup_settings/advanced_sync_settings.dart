// ignore_for_file: unused_element_parameter

part of '../backup_settings_page.dart';

class _AdvancedSyncSettingsCard extends StatefulWidget {
  const _AdvancedSyncSettingsCard();

  @override
  State<_AdvancedSyncSettingsCard> createState() =>
      _AdvancedSyncSettingsCardState();
}

class _AdvancedSyncSettingsCardState extends State<_AdvancedSyncSettingsCard> {
  VaultSyncPrefsDto? _prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final prefs = await getIt<VaultSyncPrefsLocalDataSource>().readPrefs();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _write(VaultSyncPrefsDto prefs) async {
    await getIt<VaultSyncPrefsLocalDataSource>().writePrefs(prefs);
    if (!mounted) return;
    setState(() => _prefs = prefs);
  }

  Future<void> _editPassphrase() async {
    final current = _prefs;
    if (current == null) return;
    final next = await _showSyncTextDialog(
      context,
      title: 'Backup passphrase',
      subtitle: 'Used to decrypt encrypted backup archives and sync mirrors.',
      initialValue: current.passphrase,
      hintText: context.l10n.backupPassphraseHint,
      obscureText: true,
      allowEmpty: true,
    );
    if (next == null || !mounted) return;
    await _write(current.copyWith(passphrase: next));
  }

  Future<void> _editLocalFolder() async {
    final current = _prefs;
    if (current == null) return;
    final next = await _showSyncTextDialog(
      context,
      title: 'Local folder path',
      subtitle: 'Optional local or NAS mirror path for advanced workflows.',
      initialValue: current.localFolderPath,
      hintText: '/Users/name/Credence or /Volumes/NAS/Credence',
      allowEmpty: true,
    );
    if (next == null || !mounted) return;
    await _write(current.copyWith(localFolderPath: next.trim()));
  }

  Future<void> _toggleLocalFolderTarget() async {
    var current = _prefs;
    if (current == null) return;
    var localFolderPath = current.localFolderPath.trim();
    if (current.targetType != 'local_folder' && localFolderPath.isEmpty) {
      final nextPath = await _showSyncTextDialog(
        context,
        title: 'Local folder path',
        subtitle: 'Choose the local or NAS path before enabling this target.',
        initialValue: localFolderPath,
        hintText: '/Users/name/Credence or /Volumes/NAS/Credence',
        allowEmpty: false,
      );
      if (nextPath == null || !mounted) return;
      localFolderPath = nextPath.trim();
      current = current.copyWith(localFolderPath: localFolderPath);
    }

    await _write(
      current.copyWith(
        targetType: current.targetType == 'local_folder'
            ? _cloudTargetFor(current)
            : 'local_folder',
        localFolderPath: localFolderPath,
      ),
    );
  }

  Future<void> _pickRemoteCheckInterval() async {
    final current = _prefs;
    if (current == null) return;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.appPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final palette = context.appPalette;
        const intervals = [0, 15, 30, 60];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  'Remote checks',
                  style: TextStyle(
                    fontFamily: settingsFontDisplay,
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 12),
                SettingsReferenceCard(
                  margin: EdgeInsets.zero,
                  children: [
                    for (final minutes in intervals)
                      SettingsReferenceNavRow(
                        icon: Icons.schedule_rounded,
                        title: _syncIntervalLabel(minutes),
                        subtitle: minutes == 0
                            ? 'Only check when you manually sync.'
                            : 'Check cloud changes in the background.',
                        value: minutes == current.remoteCheckIntervalMinutes
                            ? 'SELECTED'
                            : null,
                        valueTone: SettingsValueTone.ok,
                        showChevron: false,
                        onTap: () => Navigator.of(context).pop(minutes),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    await _write(current.copyWith(remoteCheckIntervalMinutes: picked));
  }

  Future<void> _toggle({
    required VaultSyncPrefsDto current,
    bool? remoteCheckOnResume,
    bool? wifiOnlySyncChecks,
    bool? lowDataSyncMode,
  }) {
    return _write(
      current.copyWith(
        remoteCheckOnResume: remoteCheckOnResume ?? current.remoteCheckOnResume,
        wifiOnlySyncChecks: wifiOnlySyncChecks ?? current.wifiOnlySyncChecks,
        lowDataSyncMode: lowDataSyncMode ?? current.lowDataSyncMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SettingsReferenceCard(
        children: [
          SettingsReferenceNavRow(
            icon: Icons.tune_rounded,
            title: 'Advanced sync',
            subtitle: 'Loading sync controls.',
            trailing: const CupertinoActivityIndicator(radius: 8),
            showChevron: false,
          ),
        ],
      );
    }

    final prefs = _prefs;
    if (prefs == null) {
      return SettingsReferenceCard(
        children: [
          SettingsReferenceNavRow(
            icon: Icons.tune_rounded,
            title: 'Advanced sync',
            subtitle: 'Unable to load sync controls.',
            value: 'Retry',
            onTap: _load,
          ),
        ],
      );
    }

    return SettingsReferenceCard(
      children: [
        SettingsReferenceNavRow(
          icon: Icons.key_rounded,
          title: 'Backup passphrase',
          subtitle: 'Different from PIN. Required for encrypted restores.',
          value: prefs.passphrase.trim().isEmpty ? 'Unset' : 'Set',
          valueTone: prefs.passphrase.trim().isEmpty
              ? SettingsValueTone.warn
              : SettingsValueTone.ok,
          onTap: _editPassphrase,
        ),
        SettingsReferenceNavRow(
          icon: Icons.folder_copy_rounded,
          title: 'Local folder mirror',
          subtitle: prefs.localFolderPath.trim().isEmpty
              ? 'Optional local or NAS mirror path.'
              : prefs.localFolderPath.trim(),
          value: prefs.localFolderPath.trim().isEmpty ? 'Off' : 'Set',
          onTap: _editLocalFolder,
        ),
        SettingsReferenceNavRow(
          icon: Icons.sync_alt_rounded,
          title: 'Use local folder target',
          subtitle: 'Advanced mode for file system or NAS sync.',
          trailing: SettingsReferenceToggle(
            isOn: prefs.targetType == 'local_folder',
          ),
          showChevron: false,
          onTap: _toggleLocalFolderTarget,
        ),
        SettingsReferenceNavRow(
          icon: Icons.schedule_rounded,
          title: 'Remote check interval',
          subtitle: 'How often Credence checks cloud changes.',
          value: _syncIntervalLabel(prefs.remoteCheckIntervalMinutes),
          onTap: _pickRemoteCheckInterval,
        ),
        SettingsReferenceNavRow(
          icon: Icons.replay_rounded,
          title: 'Check on app resume',
          subtitle: 'Look for cloud changes when Credence opens.',
          trailing: SettingsReferenceToggle(isOn: prefs.remoteCheckOnResume),
          showChevron: false,
          onTap: () => _toggle(
            current: prefs,
            remoteCheckOnResume: !prefs.remoteCheckOnResume,
          ),
        ),
        SettingsReferenceNavRow(
          icon: Icons.wifi_rounded,
          title: 'Wi-Fi only checks',
          subtitle: 'Skip background checks while on cellular.',
          trailing: SettingsReferenceToggle(isOn: prefs.wifiOnlySyncChecks),
          showChevron: false,
          onTap: () => _toggle(
            current: prefs,
            wifiOnlySyncChecks: !prefs.wifiOnlySyncChecks,
          ),
        ),
        SettingsReferenceNavRow(
          icon: Icons.data_saver_on_rounded,
          title: 'Low data mode',
          subtitle: 'Prefer lightweight head checks before transfers.',
          trailing: SettingsReferenceToggle(isOn: prefs.lowDataSyncMode),
          showChevron: false,
          onTap: () =>
              _toggle(current: prefs, lowDataSyncMode: !prefs.lowDataSyncMode),
        ),
      ],
    );
  }
}

String _cloudTargetFor(VaultSyncPrefsDto prefs) {
  return switch (prefs.selectedCloudProvider) {
    'google_drive' when prefs.googleDriveAccessToken.trim().isNotEmpty =>
      'google_drive_cloud',
    'dropbox'
        when prefs.dropboxAccessToken.trim().isNotEmpty ||
            prefs.dropboxRefreshToken.trim().isNotEmpty =>
      'dropbox_cloud',
    _ => 'none',
  };
}

String _syncIntervalLabel(int minutes) {
  return switch (minutes) {
    0 => 'Manual only',
    15 => '15 min',
    30 => '30 min',
    60 => '1 hour',
    _ => '$minutes min',
  };
}

Future<String?> _showSyncTextDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String initialValue,
  required String hintText,
  bool obscureText = false,
  bool allowEmpty = false,
}) async {
  final controller = TextEditingController(text: initialValue);
  var obscured = obscureText;

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
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
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: obscured,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: hintText,
                    filled: true,
                    fillColor: context.appPalette.surfaceSoft,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.appPalette.stroke),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.appPalette.stroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: collectionsPrimary,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: obscureText
                        ? IconButton(
                            icon: Icon(
                              obscured
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 20,
                              color: context.appPalette.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => obscured = !obscured),
                          )
                        : null,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.l10n.commonCancel),
              ),
              TextButton(
                onPressed: () {
                  final value = controller.text;
                  if (!allowEmpty && value.trim().isEmpty) return;
                  Navigator.of(dialogContext).pop(value);
                },
                child: Text(context.l10n.commonSave),
              ),
            ],
          );
        },
      );
    },
  );
}

int _totalBackupBytes(BackupState state) {
  if (state.backups.isEmpty) return state.lastBackup?.archiveSizeBytes ?? 0;
  return state.backups.fold<int>(
    0,
    (total, backup) => total + backup.archiveSizeBytes,
  );
}

String _metricBackupSize(int bytes) {
  if (bytes <= 0) return '0';
  return (bytes / (1024 * 1024)).toStringAsFixed(
    bytes < 10 * 1024 * 1024 ? 1 : 0,
  );
}

String _relativeBackupAge(DateTime createdAt) {
  final now = DateTime.now();
  final local = createdAt.toLocal();
  final difference = now.difference(local);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inHours < 1) return '${difference.inMinutes} min ago';
  if (difference.inDays < 1) return '${difference.inHours} h ago';
  if (difference.inDays < 30) return '${difference.inDays} d ago';
  return DateFormat('MMM d').format(local);
}

String _frequencyShortValue(BackupFrequency frequency) {
  return switch (frequency) {
    BackupFrequency.manual => 'Off',
    BackupFrequency.daily => 'Day',
    BackupFrequency.weekly => 'Wk',
    BackupFrequency.monthly => 'Mo',
  };
}

String _frequencyDescription(BackupFrequency frequency) {
  return switch (frequency) {
    BackupFrequency.manual => 'Manual backups only.',
    BackupFrequency.daily => 'Daily while the app is active.',
    BackupFrequency.weekly => 'Weekly + after important changes.',
    BackupFrequency.monthly => 'Monthly safety snapshot.',
  };
}

String _allBackupsSubtitle(BackupState state) {
  if (state.backups.isEmpty) return 'No snapshots yet';
  final localCount = state.backups.length;
  final remoteCount = state.remoteBackupCount;
  if (remoteCount > 0) {
    return '$remoteCount snapshots in cloud, $localCount local';
  }
  return '$localCount local snapshots';
}

// ── Passphrase Dialog ──

Future<void> _showPassphraseDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String actionLabel,
  required Future<void> Function(String passphrase) onConfirm,
  bool showRememberOption = false,
  void Function(String passphrase)? onRemember,
}) async {
  final controller = TextEditingController();
  var obscured = true;
  var rememberPassphrase = false;

  // Pre-fill from secure storage if available
  if (showRememberOption) {
    final stored = await BackupPassphraseService.getStoredPassphrase();
    if (stored != null && stored.isNotEmpty) {
      controller.text = stored;
      rememberPassphrase = true;
    }
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
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
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: obscured,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: context.l10n.backupPassphraseHint,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textMuted,
                    ),
                    filled: true,
                    fillColor: context.appPalette.surfaceSoft,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.appPalette.stroke),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.appPalette.stroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: collectionsPrimary,
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscured
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                        color: context.appPalette.textMuted,
                      ),
                      onPressed: () => setState(() => obscured = !obscured),
                    ),
                  ),
                ),
                if (showRememberOption) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(
                      () => rememberPassphrase = !rememberPassphrase,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: rememberPassphrase,
                            onChanged: (v) =>
                                setState(() => rememberPassphrase = v ?? false),
                            activeColor: collectionsPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.backupRememberPassphrase,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.appPalette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  context.l10n.commonCancel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final passphrase = controller.text.trim();
                  if (passphrase.isEmpty) return;
                  Navigator.of(dialogContext).pop();
                  if (showRememberOption &&
                      rememberPassphrase &&
                      onRemember != null) {
                    onRemember(passphrase);
                  }
                  await onConfirm(passphrase);
                },
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: collectionsPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  // Controller is cleaned up by GC — manual dispose causes
  // "used after being disposed" when async operations trigger rebuilds.
}

Future<void> _showBackupRestoreSuccessDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F8F1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 30,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.backupRestoreComplete,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.appPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.backupRestoreCompleteMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Done',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: collectionsPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
