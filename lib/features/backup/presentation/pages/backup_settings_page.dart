// ignore_for_file: unused_element_parameter

import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/vault_error_state.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_prefs_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_type.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/cloud_provider_type.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_passphrase_service.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/dropbox_auth_service.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/google_drive_auth_service.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/backup_state.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/shared_backup_cubit.dart';
import 'package:pass_doc_manager/features/backup/presentation/support/backup_coverage_summary.dart';
import 'package:pass_doc_manager/features/backup/presentation/support/backup_freshness_report.dart';
import 'package:pass_doc_manager/features/backup/presentation/widgets/pending_backup_changes_sheet.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/features/backup/data/datasources/local/backup_local_data_source.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_scheduler.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/features/settings/presentation/widgets/settings_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

part 'backup_settings/advanced_sync_settings.dart';
part 'backup_settings/cloud_provider_section.dart';
part 'backup_settings/google_drive_section.dart';
part 'backup_settings/icloud_section.dart';
part 'backup_settings/dropbox_section.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  @override
  void initState() {
    super.initState();
    if (sharedBackupCubit.state.viewStatus == BackupViewStatus.initial) {
      unawaited(sharedBackupCubit.load());
    }
    final state = sharedBackupCubit.state;
    if (!state.isUploading && !state.isRestoring && !state.isCreating) {
      unawaited(sharedBackupCubit.refreshRemoteStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sharedBackupCubit,
      child: const _BackupSettingsScaffold(),
    );
  }
}

class _BackupSettingsScaffold extends StatelessWidget {
  const _BackupSettingsScaffold();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.background,
      body: const _BackupSettingsBody(),
    );
  }
}

class _BackupSettingsBody extends StatelessWidget {
  const _BackupSettingsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackupCubit, BackupState>(
      builder: (context, state) {
        if ((state.viewStatus == BackupViewStatus.initial ||
                state.viewStatus == BackupViewStatus.loading) &&
            state.backups.isEmpty) {
          return const Center(child: CupertinoActivityIndicator(radius: 12));
        }

        if (state.viewStatus == BackupViewStatus.error &&
            state.backups.isEmpty) {
          return VaultErrorState(
            icon: Icons.cloud_off_rounded,
            message: state.errorMessage ?? context.l10n.backupErrorLoad,
            onRetry: () => context.read<BackupCubit>().load(),
          );
        }

        final content = SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 90),
                children: [
                  SettingsReferenceTopBar(
                    title: 'Backup & restore',
                    leftLabel: '\u2039 Settings',
                    onLeftTap: () => Navigator.of(context).maybePop(),
                  ),

                  // Success banner
                  if (state.successMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: _SuccessBanner(
                        message: state.successMessage!,
                        onDismiss: () =>
                            context.read<BackupCubit>().clearSuccessMessage(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Error banner
                  if (state.viewStatus == BackupViewStatus.error ||
                      state.errorMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: _ErrorBanner(
                        message:
                            state.errorMessage ?? context.l10n.backupErrorLoad,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Interrupted restore warning
                  if (state.hasInterruptedRestore) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _InterruptedRestoreBanner(
                        onRollback: () => context
                            .read<BackupCubit>()
                            .rollbackInterruptedRestore(),
                        onDismiss: () => context
                            .read<BackupCubit>()
                            .dismissInterruptedRestore(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (state.isCreating || state.isRestoring) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _BackupOperationCard(state: state),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _ReferenceBackupStatus(state: state),
                  const SizedBox(height: 12),
                  _ReferenceBackupActions(
                    isBusy: state.isCreating || state.isRestoring,
                    onBackup: () => _startBackup(context),
                    onRestore: state.lastBackup == null || state.isRestoring
                        ? null
                        : () => _showRestorePreview(context, state.lastBackup!),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: _CloudProviderSection(
                      backupState: state,
                      isUploading: state.isUploading,
                      isRestoring: state.isRestoring,
                      isBusy: state.isCreating || state.isRestoring,
                      hasBackups:
                          state.backups.isNotEmpty || state.lastBackup != null,
                      remoteBackupCount: state.remoteBackupCount,
                      remoteStorageBytes: state.remoteStorageBytes,
                      isLoadingRemote: state.isLoadingRemote,
                      remoteBackups: state.remoteBackups,
                      uploadProgress: state.isUploading
                          ? state.operationProgress
                          : null,
                      uploadMessage: state.isUploading
                          ? state.operationMessage
                          : null,
                      uploadDetail: state.isUploading
                          ? state.operationDetail
                          : null,
                      operationProcessedCount: state.operationProcessedCount,
                      operationTotalCount: state.operationTotalCount,
                      operationEntityCount: state.operationEntityCount,
                      operationFileCount: state.operationFileCount,
                      dropboxSessionExpired: state.dropboxSessionExpired,
                      restoreProgress: state.isRestoring
                          ? state.operationProgress
                          : null,
                      restoreMessage: state.isRestoring
                          ? state.operationMessage
                          : null,
                      restoreDetail: state.isRestoring
                          ? state.operationDetail
                          : null,
                    ),
                  ),
                  const SettingsReferenceGroupHeader('Included in backup'),
                  _IncludedBackupGrid(state: state),
                  const SettingsReferenceGroupHeader('Schedule'),
                  const _BackupScheduleCard(),
                  const SettingsReferenceGroupHeader('Advanced sync'),
                  const _AdvancedSyncSettingsCard(),
                  const SettingsReferenceGroupHeader('History'),
                  SettingsReferenceCard(
                    children: [
                      SettingsReferenceNavRow(
                        icon: Icons.history_rounded,
                        title: 'All backups',
                        subtitle: _allBackupsSubtitle(state),
                        value: state.backups.isEmpty
                            ? null
                            : '${state.backups.length}',
                        onTap: state.backups.isEmpty
                            ? null
                            : () => _showAllBackupsSheet(context, state),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        );

        return Stack(
          children: [
            content,
            if (state.isCreating || state.isRestoring || state.isUploading)
              BackupLiveIslandOverlay(state: state),
          ],
        );
      },
    );
  }

  Future<void> _startBackup(BuildContext context) {
    return _showPassphraseDialog(
      context,
      title: context.l10n.backupCreateTitle,
      subtitle: context.l10n.backupCreateSubtitle,
      actionLabel: context.l10n.backupCreateButton,
      showRememberOption: true,
      onConfirm: (passphrase) async {
        final success = await context.read<BackupCubit>().createBackup(
          passphrase,
        );
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<BackupCubit>().state.errorMessage ??
                    context.l10n.backupErrorCreate,
              ),
              backgroundColor: context.appPalette.danger,
            ),
          );
        }
      },
      onRemember: BackupPassphraseService.storePassphrase,
    );
  }

  Future<void> _showAllBackupsSheet(
    BuildContext context,
    BackupState state,
  ) async {
    final palette = context.appPalette;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (context, controller) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.strokeStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All backups',
                    style: TextStyle(
                      fontFamily: settingsFontDisplay,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.45,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _allBackupsSubtitle(state),
                    style: TextStyle(
                      fontFamily: settingsFontMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.55,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...state.backups.map(
                    (backup) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BackupHistoryCard(
                        backup: backup,
                        isRestoring: state.isRestoring,
                        onRestore: () {
                          Navigator.of(sheetContext).pop();
                          _showRestorePreview(context, backup);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showRestorePreview(
    BuildContext context,
    BackupManifest backup,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.backupRestorePreview,
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
            _previewRow(
              context,
              context.l10n.backupPreviewDate,
              DateFormat(
                'MMM d, y \u2022 hh:mm a',
              ).format(backup.createdAt.toLocal()),
            ),
            _previewRow(
              context,
              context.l10n.backupPreviewType,
              backup.backupType.label,
            ),
            _previewRow(
              context,
              context.l10n.backupPreviewEntities,
              '${backup.entityCount}',
            ),
            _previewRow(
              context,
              context.l10n.backupPreviewFiles,
              '${backup.fileCount}',
            ),
            _previewRow(
              context,
              context.l10n.backupPreviewSize,
              _formatBytes(backup.archiveSizeBytes),
            ),
            _previewRow(
              context,
              context.l10n.backupPreviewDevice,
              backup.deviceName,
            ),
            _previewRow(
              context,
              context.l10n.backupPreviewEncryption,
              backup.encryptionAlgorithm ??
                  context.l10n.backupPreviewEncryptionNone,
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
                      context.l10n.backupRestoreWarning,
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
    );
    if (confirmed != true || !context.mounted) return;

    // Try stored passphrase first — skip dialog if available
    final storedPassphrase =
        await BackupPassphraseService.getStoredPassphrase();

    if (storedPassphrase != null && storedPassphrase.isNotEmpty) {
      if (!context.mounted) return;
      _executeRestore(context, backup.backupId, storedPassphrase);
      return;
    }

    // No stored passphrase — ask user
    if (!context.mounted) return;
    _showPassphraseDialog(
      context,
      title: context.l10n.backupRestoreTitle,
      subtitle: context.l10n.backupRestoreSubtitle,
      actionLabel: context.l10n.commonRestore,
      onConfirm: (passphrase) =>
          _executeRestore(context, backup.backupId, passphrase),
    );
  }

  Future<void> _executeRestore(
    BuildContext context,
    String backupId,
    String passphrase,
  ) async {
    final success = await context.read<BackupCubit>().restoreBackup(
      backupId,
      passphrase,
    );

    if (!context.mounted) {
      return;
    }
    if (!success) {
      final state = context.read<BackupCubit>().state;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? context.l10n.backupErrorRestore),
          backgroundColor: context.appPalette.danger,
        ),
      );
    } else {
      _showBackupRestoreSuccessDialog(context);
    }
  }

  Widget _previewRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceBackupStatus extends StatelessWidget {
  const _ReferenceBackupStatus({required this.state});

  final BackupState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final lastBackup = state.lastBackup;
    final hasBackup = lastBackup != null;
    final isBusy = state.isCreating || state.isRestoring || state.isUploading;
    final totalBytes = _totalBackupBytes(state);
    final iconColor = hasBackup ? palette.success : palette.warning;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: isBusy
                    ? const CupertinoActivityIndicator(
                        radius: 8,
                        color: Colors.white,
                      )
                    : Icon(
                        hasBackup
                            ? Icons.check_rounded
                            : Icons.priority_high_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasBackup ? 'Local snapshot ready.' : 'Backup needed.',
                      style: TextStyle(
                        fontFamily: settingsFontDisplay,
                        color: palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasBackup
                          ? 'LAST BACKUP · ${_relativeBackupAge(lastBackup.createdAt)} · ENCRYPTED'
                          : 'NO SNAPSHOT YET · FILES AND IMAGES INCLUDED',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontMono,
                        color: palette.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.65,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.18,
            children: [
              _BackupMetric(
                value: '${state.backups.length}',
                label: 'Snapshots',
              ),
              _BackupMetric(
                value: _metricBackupSize(totalBytes),
                label: 'MB used',
              ),
              _BackupMetric(
                value: lastBackup?.isEncrypted == false ? 'Local' : 'AES',
                label: lastBackup?.isEncrypted == false ? 'Only' : '256',
              ),
              const _BackupFrequencyMetric(),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackupMetric extends StatelessWidget {
  const _BackupMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: settingsFontDisplay,
                color: palette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.15,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              style: TextStyle(
                fontFamily: settingsFontMono,
                color: palette.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupFrequencyMetric extends StatefulWidget {
  const _BackupFrequencyMetric();

  @override
  State<_BackupFrequencyMetric> createState() => _BackupFrequencyMetricState();
}

class _BackupFrequencyMetricState extends State<_BackupFrequencyMetric> {
  BackupFrequency _frequency = BackupFrequency.daily;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scheduler = BackupScheduler(
      localDataSource: getIt<BackupLocalDataSource>(),
    );
    final frequency = await scheduler.getFrequency();
    if (!mounted) return;
    setState(() => _frequency = frequency);
  }

  @override
  Widget build(BuildContext context) {
    return _BackupMetric(
      value: _frequencyShortValue(_frequency),
      label: _frequency == BackupFrequency.manual ? 'Manual' : 'Auto',
    );
  }
}

class _ReferenceBackupActions extends StatelessWidget {
  const _ReferenceBackupActions({
    required this.isBusy,
    required this.onBackup,
    required this.onRestore,
  });

  final bool isBusy;
  final VoidCallback onBackup;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: isBusy ? null : onBackup,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: palette.textPrimary,
                  foregroundColor: palette.surface,
                  disabledBackgroundColor: palette.textMuted,
                  disabledForegroundColor: palette.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isBusy
                    ? const CupertinoActivityIndicator(
                        radius: 8,
                        color: Colors.white,
                      )
                    : const Text(
                        'Back up now',
                        style: TextStyle(
                          fontFamily: settingsFontDisplay,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.05,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: isBusy ? null : onRestore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.textPrimary,
                  disabledForegroundColor: palette.textMuted,
                  side: BorderSide(color: palette.stroke),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Restore',
                  style: TextStyle(
                    fontFamily: settingsFontDisplay,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncludedBackupGrid extends StatelessWidget {
  const _IncludedBackupGrid({required this.state});

  final BackupState state;

  @override
  Widget build(BuildContext context) {
    final manifest = state.lastBackup;
    final entities = manifest?.entityCount;
    final files = manifest?.fileCount;
    final items = [
      entities == null ? 'Vault records' : '$entities vault records',
      'Documents',
      files == null ? 'Attached files' : '$files attached files',
      'Collections',
      'Bundles',
      'Task lists',
      'Profile · gen log',
      'Settings · icons',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((label) => _IncludedBackupChip(label)).toList(),
      ),
    );
  }
}

class _IncludedBackupChip extends StatelessWidget {
  const _IncludedBackupChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 14, color: palette.success),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: settingsFontDisplay,
              color: palette.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupScheduleCard extends StatefulWidget {
  const _BackupScheduleCard();

  @override
  State<_BackupScheduleCard> createState() => _BackupScheduleCardState();
}

class _BackupScheduleCardState extends State<_BackupScheduleCard> {
  BackupFrequency _selected = BackupFrequency.daily;
  bool _isLoading = true;
  bool _wifiOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final scheduler = BackupScheduler(
        localDataSource: getIt<BackupLocalDataSource>(),
      );
      final frequency = await scheduler.getFrequency();
      if (!mounted) return;
      setState(() {
        _selected = frequency;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setFrequency(BackupFrequency frequency) async {
    setState(() => _selected = frequency);
    try {
      final scheduler = BackupScheduler(
        localDataSource: getIt<BackupLocalDataSource>(),
      );
      await scheduler.setFrequency(frequency);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.backupFrequencyError)),
      );
    }
  }

  Future<void> _pickFrequency() async {
    final palette = context.appPalette;
    final picked = await showModalBottomSheet<BackupFrequency>(
      context: context,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                  'Frequency',
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
                    for (final frequency in BackupFrequency.values)
                      SettingsReferenceNavRow(
                        icon: Icons.calendar_month_rounded,
                        title: frequency.label,
                        subtitle: _frequencyDescription(frequency),
                        value: frequency == _selected ? 'SELECTED' : null,
                        valueTone: SettingsValueTone.ok,
                        showChevron: false,
                        onTap: () => Navigator.of(context).pop(frequency),
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
    await _setFrequency(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SettingsReferenceCard(
        children: [
          SettingsReferenceNavRow(
            icon: Icons.schedule_rounded,
            title: 'Schedule',
            subtitle: 'Loading backup schedule.',
            trailing: const CupertinoActivityIndicator(radius: 8),
            showChevron: false,
          ),
        ],
      );
    }

    return SettingsReferenceCard(
      children: [
        SettingsReferenceNavRow(
          icon: Icons.schedule_rounded,
          title: 'Auto-backup',
          subtitle: 'Runs in the background while charging.',
          trailing: SettingsReferenceToggle(
            isOn: _selected != BackupFrequency.manual,
          ),
          showChevron: false,
          onTap: () => _setFrequency(
            _selected == BackupFrequency.manual
                ? BackupFrequency.daily
                : BackupFrequency.manual,
          ),
        ),
        SettingsReferenceNavRow(
          icon: Icons.calendar_month_rounded,
          title: 'Frequency',
          subtitle: _frequencyDescription(_selected),
          value: _selected.label,
          onTap: _pickFrequency,
        ),
        SettingsReferenceNavRow(
          icon: Icons.wifi_rounded,
          title: 'Wi-Fi only',
          subtitle: 'Skip backups on cellular.',
          trailing: SettingsReferenceToggle(isOn: _wifiOnly),
          showChevron: false,
          onTap: () => setState(() => _wifiOnly = !_wifiOnly),
        ),
      ],
    );
  }
}

class _BackupOperationCard extends StatelessWidget {
  const _BackupOperationCard({required this.state});

  final BackupState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final progress = state.operationProgress?.clamp(0.0, 1.0);
    final title = state.isCreating
        ? context.l10n.backupCreating
        : context.l10n.backupRestoring;
    final icon = state.isCreating
        ? Icons.backup_rounded
        : Icons.restore_rounded;
    final metrics = <Widget>[
      _OperationMetricChip(
        label: 'Records',
        value: '${state.operationEntityCount}',
      ),
      _OperationMetricChip(
        label: 'Files',
        value: '${state.operationFileCount}',
      ),
    ];
    if (state.operationProcessedCount != null &&
        state.operationTotalCount != null) {
      metrics.add(
        _OperationMetricChip(
          label: 'Progress',
          value:
              '${state.operationProcessedCount}/${state.operationTotalCount}',
        ),
      );
    }

    return CollectionsSurfaceCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: collectionsPrimary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.operationMessage ??
                          (state.isCreating
                              ? 'Collecting vault data'
                              : 'Rebuilding your vault'),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (progress == null)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CupertinoActivityIndicator(radius: 9),
                )
              else
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: collectionsPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.operationDetail ?? context.l10n.backupRestoringMessage,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: palette.stroke,
              valueColor: const AlwaysStoppedAnimation<Color>(
                collectionsPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: metrics),
        ],
      ),
    );
  }
}

class BackupLiveIslandOverlay extends StatelessWidget {
  const BackupLiveIslandOverlay({
    required this.state,
    this.onTap,
    this.compact = false,
    super.key,
  });

  final BackupState state;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = state.operationProgress?.clamp(0.0, 1.0).toDouble();
    final percent = progress == null ? null : '${(progress * 100).round()}%';
    final accent = _accentColor(context);
    final title = _title;
    final detail = _detail;
    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 350 : 382),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 9 : 10,
                      compact ? 8 : 9,
                      compact ? 11 : 12,
                      compact ? 8 : 9,
                    ),
                    child: Row(
                      children: [
                        _BackupLiveIslandIcon(icon: _icon, accent: accent),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: settingsFontDisplay,
                                  fontSize: compact ? 13.2 : 13.8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                detail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: settingsFontDisplay,
                                  fontSize: compact ? 10.8 : 11.2,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.64),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (percent == null)
                          const CupertinoActivityIndicator(
                            radius: 8,
                            color: Colors.white,
                          )
                        else
                          Text(
                            percent,
                            style: TextStyle(
                              fontFamily: settingsFontMono,
                              fontSize: compact ? 11 : 11.5,
                              fontWeight: FontWeight.w900,
                              color: accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (progress != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          minHeight: 2.5,
                          value: value,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      bottom: false,
      child: IgnorePointer(
        ignoring: onTap == null,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, compact ? 7 : 8, 14, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey('$title-${state.operationMessage}'),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    if (state.isRestoring) {
      return Icons.restore_rounded;
    }
    if (state.isUploading) {
      return Icons.sync_rounded;
    }
    return Icons.backup_rounded;
  }

  String get _title {
    if (state.isRestoring) {
      return 'Restoring vault';
    }
    if (state.isUploading) {
      return 'Syncing backup';
    }
    return 'Creating backup';
  }

  String get _detail {
    final message = state.operationMessage?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    if (state.isRestoring) {
      return 'Keep Credence open until restore finishes';
    }
    if (state.isUploading) {
      return 'Only missing or changed items are sent';
    }
    return 'Securing local snapshot';
  }

  Color _accentColor(BuildContext context) {
    final palette = context.appPalette;
    if (state.isRestoring) {
      return palette.warning;
    }
    if (state.isUploading) {
      return collectionsPrimary;
    }
    return palette.success;
  }
}

class _BackupLiveIslandIcon extends StatelessWidget {
  const _BackupLiveIslandIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: accent, size: 19),
    );
  }
}

class _OperationMetricChip extends StatelessWidget {
  const _OperationMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.appPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Backup History Card ──

class _BackupHistoryCard extends StatelessWidget {
  const _BackupHistoryCard({
    required this.backup,
    required this.isRestoring,
    required this.onRestore,
  });

  final BackupManifest backup;
  final bool isRestoring;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.yMMMd().add_jm().format(
      backup.createdAt.toLocal(),
    );

    final typeColor = _backupTypeColor(backup.backupType);

    return CollectionsSurfaceCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(
              _backupTypeIcon(backup.backupType),
              size: 20,
              color: typeColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  backup.backupType.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '$dateStr  •  ${_formatBytes(backup.archiveSizeBytes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _RestoreButton(isRestoring: isRestoring, onPressed: onRestore),
        ],
      ),
    );
  }
}

// ── Restore Button ──

class _RestoreButton extends StatelessWidget {
  const _RestoreButton({required this.isRestoring, required this.onPressed});

  final bool isRestoring;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: TextButton(
        onPressed: isRestoring ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: context.appPalette.surfaceSoft,
          foregroundColor: collectionsPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isRestoring
            ? const CupertinoActivityIndicator(radius: 8)
            : Text(
                context.l10n.commonRestore,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ── Error Banner ──

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF81C784)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2B8B0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFB42318),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB42318),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropboxSessionExpiredBanner extends StatelessWidget {
  const _DropboxSessionExpiredBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.link_off_rounded,
            size: 20,
            color: Color(0xFFE8890C),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dropboxSessionExpiredTitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7A5500),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.dropboxSessionExpiredMessage,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A5500),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            icon: const Icon(Icons.close_rounded, color: Color(0xFF7A5500)),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

// ── Cloud Provider Section ──

class _InterruptedRestoreBanner extends StatelessWidget {
  const _InterruptedRestoreBanner({
    required this.onRollback,
    required this.onDismiss,
  });

  final VoidCallback onRollback;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 20,
                color: Color(0xFFE8890C),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.backupInterruptedRestoreDetected,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A5500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.backupInterruptedWarning,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A5500),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7A5500),
                      side: const BorderSide(color: Color(0xFFE8890C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      context.l10n.commonDismiss,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onRollback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8890C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      context.l10n.commonRollback,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──

Color _backupTypeColor(BackupType type) {
  return switch (type) {
    BackupType.full => const Color(0xFF2E7D32),
    BackupType.delta => const Color(0xFF1565C0),
    BackupType.compacted => const Color(0xFFE65100),
  };
}

IconData _backupTypeIcon(BackupType type) {
  return switch (type) {
    BackupType.full => Icons.cloud_done_rounded,
    BackupType.delta => Icons.cloud_sync_rounded,
    BackupType.compacted => Icons.compress_rounded,
  };
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
