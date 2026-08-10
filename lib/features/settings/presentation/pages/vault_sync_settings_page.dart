import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pass_doc_manager/app/app.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/share_position_origin.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/app/theme/theme_controller.dart';
import 'package:pass_doc_manager/features/auth/infrastructure/services/app_lock_service.dart';
import 'package:pass_doc_manager/features/auth/presentation/pages/pin_setup_page.dart';
import 'package:pass_doc_manager/features/auth/presentation/widgets/auth_reference_ui.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_detail_cubit.dart';
import 'package:pass_doc_manager/features/credentials/presentation/pages/credential_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_detail_page.dart';
import 'package:pass_doc_manager/features/vault_import/presentation/pages/vault_import_page.dart';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:pass_doc_manager/app/sync/vault_data_refresh_signal.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_service.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_with_files_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_with_files_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_merge_strategy.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_vault_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_vault_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/portable_data_scope.dart';
import 'package:pass_doc_manager/domain/vault_portability/usecases/export_vault_with_files.dart';
import 'package:pass_doc_manager/domain/vault_portability/usecases/import_vault_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/get_vault_sync_settings.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/get_vault_sync_status.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/run_vault_sync_now.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/save_vault_sync_settings.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_chain.dart';
import 'package:pass_doc_manager/features/backup/domain/usecases/validate_chain.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_passphrase_service.dart';
import 'package:pass_doc_manager/features/backup/presentation/pages/backup_settings_page.dart';
import 'package:pass_doc_manager/features/auth/infrastructure/services/vault_wipe_service.dart';
import 'package:pass_doc_manager/features/collections/presentation/services/reminder_notification_service.dart';
import 'package:pass_doc_manager/features/settings/data/notification_settings_store.dart';
import 'package:pass_doc_manager/features/settings/presentation/cubit/vault_sync_settings_cubit.dart';
import 'package:pass_doc_manager/features/settings/presentation/cubit/vault_sync_settings_state.dart';
import 'package:pass_doc_manager/features/settings/presentation/widgets/settings_reference_ui.dart';
import 'package:pass_doc_manager/features/documents/infrastructure/services/document_expiry_service.dart';
import 'package:pass_doc_manager/features/tasks/infrastructure/services/task_notification_service.dart';
import 'package:pass_doc_manager/features/vault_health/presentation/cubit/vault_health_cubit.dart';
import 'package:pass_doc_manager/features/vault_health/presentation/pages/vault_health_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class VaultSyncSettingsPage extends StatelessWidget {
  VaultSyncSettingsPage({
    super.key,
    GetVaultSyncSettings? getSettings,
    GetVaultSyncStatus? getStatus,
    SaveVaultSyncSettings? saveSettings,
    RunVaultSyncNow? runSyncNow,
    this.embeddedDesktop = false,
  }) : getSettings = getSettings ?? getIt(),
       getStatus = getStatus ?? getIt(),
       saveSettings = saveSettings ?? getIt(),
       runSyncNow = runSyncNow ?? getIt();

  final GetVaultSyncSettings getSettings;
  final GetVaultSyncStatus getStatus;
  final SaveVaultSyncSettings saveSettings;
  final RunVaultSyncNow runSyncNow;
  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VaultSyncSettingsCubit(
        getSettings: getSettings,
        getStatus: getStatus,
        saveSettings: saveSettings,
        runSyncNow: runSyncNow,
      )..load(),
      child: _VaultSyncSettingsView(embeddedDesktop: embeddedDesktop),
    );
  }
}

class _VaultSyncSettingsView extends StatefulWidget {
  const _VaultSyncSettingsView({this.embeddedDesktop = false});

  final bool embeddedDesktop;

  @override
  State<_VaultSyncSettingsView> createState() => _VaultSyncSettingsViewState();
}

class _VaultSyncSettingsViewState extends State<_VaultSyncSettingsView> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VaultSyncSettingsCubit, VaultSyncSettingsState>(
      listener: (context, state) {
        if (state.lastActionMessage != null &&
            state.lastActionMessage!.trim().isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.lastActionMessage!)));
        }
      },
      builder: (context, state) {
        final isBusy =
            state.viewStatus == VaultSyncSettingsViewStatus.loading ||
            state.viewStatus == VaultSyncSettingsViewStatus.saving ||
            state.viewStatus == VaultSyncSettingsViewStatus.syncing;

        if (state.viewStatus == VaultSyncSettingsViewStatus.loading) {
          if (widget.embeddedDesktop) {
            return Center(child: CircularProgressIndicator());
          }
          return Scaffold(
            backgroundColor: context.appPalette.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 980;

            // Always use the mobile-style scaffold so the settings UI is
            // consistent across mobile and desktop. On desktop, we constrain
            // its width so it doesn't stretch too wide.
            final mobileScaffold = _buildMobileSecurityScaffold(
              context,
              state,
              isBusy,
              isDesktop,
            );

            if (!isDesktop) {
              return mobileScaffold;
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: mobileScaffold,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileSecurityScaffold(
    BuildContext context,
    VaultSyncSettingsState state,
    bool isBusy,
    bool isDesktop,
  ) {
    final l10n = context.l10n;
    final canPop = Navigator.of(context).canPop();
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        top: !widget.embeddedDesktop,
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 10 : 0,
            isDesktop ? 8 : 0,
            isDesktop ? 10 : 0,
            24,
          ),
          children: [
            SettingsReferenceTopBar(
              title: 'Settings',
              rightLabel: canPop ? l10n.commonDone : null,
              onRightTap: canPop
                  ? () => Navigator.of(context).maybePop()
                  : null,
            ),
            SettingsReferenceGroupHeader('Security'),
            SettingsReferenceCard(
              children: [
                SettingsReferenceNavRow(
                  icon: Icons.lock_rounded,
                  title: 'Vault security',
                  subtitle: 'PIN, Face ID, auto-lock, privacy',
                  value: 'Healthy',
                  valueTone: SettingsValueTone.ok,
                  onTap: isBusy ? null : () => _openVaultSecurity(context),
                ),
              ],
            ),
            SettingsReferenceGroupHeader('Backup & Sync'),
            SettingsReferenceCard(
              children: [
                SettingsReferenceNavRow(
                  icon: Icons.backup_rounded,
                  title: 'Backup & restore',
                  subtitle: 'Cloud provider, restore, and advanced sync.',
                  onTap: isBusy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const BackupSettingsPage(),
                          ),
                        ),
                ),
              ],
            ),
            SettingsReferenceGroupHeader('Data'),
            SettingsReferenceCard(
              children: [
                SettingsReferenceNavRow(
                  icon: Icons.import_export_rounded,
                  title: 'Import & export',
                  subtitle: 'Vault archives, passwords, CSV, linked files.',
                  onTap: isBusy ? null : () => _openImportExport(context),
                ),
                SettingsReferenceNavRow(
                  icon: Icons.health_and_safety_rounded,
                  title: l10n.vaultHealthPageTitle,
                  subtitle: 'Weak passwords, expiring docs, backup state.',
                  value: state.errorMessage == null ? 'Check' : 'Warn',
                  valueTone: state.errorMessage == null
                      ? SettingsValueTone.neutral
                      : SettingsValueTone.warn,
                  onTap: _openVaultHealth,
                ),
              ],
            ),
            SettingsReferenceGroupHeader('Preferences'),
            SettingsReferenceCard(
              children: [
                SettingsReferenceNavRow(
                  icon: Icons.light_mode_rounded,
                  title: 'Appearance',
                  subtitle: 'Light, dark, or match system.',
                  value: _themeValue(context),
                  onTap: () => _openAppearance(context),
                ),
                SettingsReferenceNavRow(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  subtitle: 'Expiry, reminders, tasks.',
                  value: 'Allowed',
                  valueTone: SettingsValueTone.ok,
                  onTap: () => _openNotifications(context),
                ),
                const SettingsReferenceNavRow(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'App language · auto-detected.',
                  value: 'System',
                  showChevron: false,
                ),
              ],
            ),
            SettingsReferenceGroupHeader('Danger zone', danger: true),
            SettingsReferenceCard(
              danger: true,
              children: [
                SettingsReferenceNavRow(
                  icon: Icons.delete_forever_rounded,
                  title: context.l10n.settingsWipeVaultTitle,
                  subtitle: context.l10n.settingsWipeVaultSubtitle,
                  danger: true,
                  onTap: isBusy ? null : () => _wipeVault(context),
                ),
              ],
            ),
            if (state.errorMessage != null &&
                state.errorMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _buildErrorBanner(state.errorMessage!),
              ),
            ],
            const SettingsReferenceFooterText('CREDENCE · LOCAL FIRST'),
          ],
        ),
      ),
    );
  }

  Future<void> _openVaultHealth() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: getIt<VaultHealthCubit>(),
          child: VaultHealthPage(
            onNavigateToCredential: (ctx, credentialId) {
              Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider(
                    create: (_) =>
                        CredentialDetailCubit()
                          ..load(credentialId: credentialId),
                    child: CredentialDetailPage(),
                  ),
                ),
              );
            },
            onNavigateToDocument: (ctx, documentId) {
              Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) => DocumentDetailPage(documentId: documentId),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openVaultSecurity(BuildContext context) async {
    var biometricAvailable = await AppLockService.isBiometricAvailable();
    var biometricEnabled = await AppLockService.isBiometricEnabled();
    var timeout = await AppLockService.getLockTimeout();
    var lockWhenLeaving = await AppLockService.isLockWhenLeavingEnabled();
    var revealAuthRequired = await AppLockService.isRevealAuthRequired();
    var wipeAfterFive = await AppLockService.isWipeAfterFiveAttemptsEnabled();
    var backupPassphraseSet =
        await BackupPassphraseService.hasStoredPassphrase();
    if (!context.mounted) return;

    String timeoutLabel() {
      return switch (timeout) {
        < 0 => 'Never',
        0 => 'Immediate',
        < 60 => '$timeout s',
        _ => '${timeout ~/ 60} min',
      };
    }

    Future<void> refreshRoute(
      BuildContext routeContext,
      StateSetter setRouteState,
    ) async {
      final nextBiometricAvailable =
          await AppLockService.isBiometricAvailable();
      final nextBiometricEnabled = await AppLockService.isBiometricEnabled();
      final nextTimeout = await AppLockService.getLockTimeout();
      final nextLockWhenLeaving =
          await AppLockService.isLockWhenLeavingEnabled();
      final nextRevealAuthRequired =
          await AppLockService.isRevealAuthRequired();
      final nextWipeAfterFive =
          await AppLockService.isWipeAfterFiveAttemptsEnabled();
      final nextBackupPassphraseSet =
          await BackupPassphraseService.hasStoredPassphrase();
      if (!routeContext.mounted) return;
      setRouteState(() {
        biometricAvailable = nextBiometricAvailable;
        biometricEnabled = nextBiometricEnabled;
        timeout = nextTimeout;
        lockWhenLeaving = nextLockWhenLeaving;
        revealAuthRequired = nextRevealAuthRequired;
        wipeAfterFive = nextWipeAfterFive;
        backupPassphraseSet = nextBackupPassphraseSet;
      });
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => StatefulBuilder(
          builder: (routeContext, setRouteState) => _settingsDetailScaffold(
            routeContext,
            title: 'Auth & Lock',
            children: [
              AuthStatusHero(
                title: 'Vault is healthy',
                subtitle:
                    'PIN · ${biometricEnabled ? 'biometric' : 'PIN fallback'} · local encryption',
              ),
              const AuthSectionHeader('Unlock this device'),
              AuthSettingsRow(
                icon: Icons.face_retouching_natural_rounded,
                title: routeContext.l10n.settingsBiometricTitle,
                subtitle: biometricAvailable
                    ? 'Faster than PIN. Falls back to PIN if it fails.'
                    : 'Biometric unlock is not available on this device.',
                trailing: AuthReferenceToggle(isOn: biometricEnabled),
                showChevron: false,
                onTap: () async {
                  await _showBiometricSheet(routeContext);
                  if (!routeContext.mounted) return;
                  await refreshRoute(routeContext, setRouteState);
                },
              ),
              AuthSettingsRow(
                icon: Icons.pin_rounded,
                title: routeContext.l10n.settingsChangePinTitle,
                subtitle: 'Last changed on this device. Six digits only.',
                value: '6-digit',
                onTap: () => _changePIN(routeContext),
              ),
              AuthSettingsRow(
                icon: Icons.timer_rounded,
                title: routeContext.l10n.settingsAutoLockTitle,
                subtitle: 'Locks the vault after this much idle time.',
                value: timeoutLabel(),
                onTap: () async {
                  await _pickLockTimeout(routeContext);
                  if (!routeContext.mounted) return;
                  await refreshRoute(routeContext, setRouteState);
                },
              ),
              AuthSettingsRow(
                icon: Icons.phonelink_lock_rounded,
                title: 'Lock when leaving the app',
                subtitle: 'Recommended on shared or work devices.',
                trailing: AuthReferenceToggle(isOn: lockWhenLeaving),
                showChevron: false,
                onTap: () async {
                  await AppLockService.setLockWhenLeavingEnabled(
                    !lockWhenLeaving,
                  );
                  if (!routeContext.mounted) return;
                  await refreshRoute(routeContext, setRouteState);
                },
              ),
              const AuthSectionHeader('Backup passphrase'),
              AuthSettingsRow(
                icon: Icons.key_rounded,
                title: 'Backup passphrase',
                subtitle: 'Decrypts every backup archive. Different from PIN.',
                value: backupPassphraseSet ? 'Set' : 'Unset',
                onTap: () async {
                  await _editBackupPassphrase(routeContext);
                  if (!routeContext.mounted) return;
                  await refreshRoute(routeContext, setRouteState);
                },
              ),
              AuthSettingsRow(
                icon: Icons.restore_rounded,
                title: 'Test restore',
                subtitle:
                    'Verifies backup restore logic without changing data.',
                onTap: () => _testRestore(routeContext),
              ),
              const AuthSectionHeader('Recovery'),
              AuthSettingsRow(
                icon: Icons.warning_amber_rounded,
                title: 'After 5 wrong PIN attempts',
                subtitle: wipeAfterFive
                    ? 'Will wipe local vault data after five wrong attempts.'
                    : 'Currently soft-locks the vault instead of wiping.',
                trailing: AuthReferenceToggle(isOn: wipeAfterFive),
                showChevron: false,
                onTap: () async {
                  await _toggleWipeAfterFive(routeContext, wipeAfterFive);
                  if (!routeContext.mounted) return;
                  await refreshRoute(routeContext, setRouteState);
                },
              ),
              AuthSettingsRow(
                icon: Icons.visibility_off_rounded,
                title: routeContext.l10n.settingsRevealAuthTitle,
                subtitle: routeContext.l10n.settingsRevealAuthSubtitle,
                trailing: AuthReferenceToggle(isOn: revealAuthRequired),
                showChevron: false,
                onTap: () async {
                  await _showRevealAuthSheet(routeContext);
                  if (!routeContext.mounted) return;
                  await refreshRoute(routeContext, setRouteState);
                },
              ),
              AuthSettingsRow(
                icon: Icons.lock_rounded,
                title: 'Lock now',
                subtitle: 'Forces the vault back to the unlock screen.',
                onTap: () => _lockVaultNow(routeContext),
              ),
              AuthSectionHeader(
                'Danger zone',
                color: context.appPalette.danger,
              ),
              AuthSettingsRow(
                icon: Icons.delete_outline_rounded,
                title: routeContext.l10n.settingsWipeVaultTitle,
                subtitle:
                    'Deletes all local data. Requires PIN verification. Backups untouched.',
                danger: true,
                onTap: () => _wipeVault(routeContext),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openImportExport(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => _settingsDetailScaffold(
          routeContext,
          title: 'Import & export',
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'Encrypted archives include records, files, images, collection icons, bundle files, settings, and restore metadata.',
                style: TextStyle(
                  fontFamily: settingsFontDisplay,
                  fontSize: 11.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF766F65),
                ),
              ),
            ),
            const SettingsReferenceGroupHeader('Vault archives'),
            SettingsReferenceCard(
              children: [
                SettingsReferenceNavRow(
                  icon: Icons.upload_file_rounded,
                  title: routeContext.l10n.securityExportData,
                  subtitle: routeContext.l10n.settingsExportSubtitle,
                  onTap: () => _navigateToExport(routeContext),
                ),
                SettingsReferenceNavRow(
                  icon: Icons.download_rounded,
                  title: routeContext.l10n.settingsImportVaultTitle,
                  subtitle: routeContext.l10n.settingsImportVaultSubtitle,
                  onTap: () => _importVaultData(routeContext),
                ),
              ],
            ),
            const SettingsReferenceGroupHeader('Password managers'),
            SettingsReferenceCard(
              children: [
                SettingsReferenceNavRow(
                  icon: Icons.password_rounded,
                  title: routeContext.l10n.settingsImportPasswordsTitle,
                  subtitle: routeContext.l10n.settingsImportPasswordsSubtitle,
                  onTap: () => Navigator.of(routeContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const VaultImportPage(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _openAppearance(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => _settingsDetailScaffold(
          routeContext,
          title: 'Appearance',
          children: [
            const SettingsReferenceGroupHeader('Theme'),
            SettingsReferenceCard(
              children: [
                SettingsReferenceNavRow(
                  icon: Icons.brightness_auto_rounded,
                  title: routeContext.l10n.settingsThemeTitle,
                  subtitle: 'Light, dark, or match system.',
                  value: _themeValue(routeContext),
                  onTap: () => _pickTheme(routeContext),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotifications(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const _NotificationsSettingsPage(),
      ),
    );
  }

  Widget _settingsDetailScaffold(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    double? maxWidth,
  }) {
    final palette = context.appPalette;
    final content = ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsReferenceTopBar(
          title: title,
          leftLabel: '‹ Settings',
          onLeftTap: () => Navigator.of(context).maybePop(),
        ),
        ...children,
      ],
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: maxWidth == null
            ? content
            : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: content,
                ),
              ),
      ),
    );
  }

  void _lockVaultNow(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
    AppLockService.requestLock();
  }

  String _themeValue(BuildContext context) {
    return switch (ThemeController.of(context).mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }

  Widget _buildErrorBanner(String message) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.dangerSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.dangerStroke),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: palette.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLockTimeout(BuildContext context) async {
    final current = await AppLockService.getLockTimeout();
    if (!context.mounted) return;
    final l10n = context.l10n;
    final options = <({int value, String label})>[
      (value: 0, label: l10n.settingsLockImmediately),
      (value: 30, label: '30 seconds'),
      (value: 60, label: '1 minute'),
      (value: 300, label: '5 minutes'),
      (value: 900, label: '15 minutes'),
      (value: -1, label: l10n.settingsLockNever),
    ];
    final palette = context.appPalette;
    final selected = await showAdaptiveModal<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.settingsAutoLockTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final opt in options)
                ListTile(
                  onTap: () => Navigator.pop(ctx, opt.value),
                  title: Text(
                    opt.label,
                    style: TextStyle(
                      fontWeight: opt.value == current
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                  trailing: opt.value == current
                      ? Icon(Icons.check_circle, color: palette.primary)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    await AppLockService.setLockTimeout(selected);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsLockTimeoutUpdated)),
      );
    }
  }

  Future<void> _changePIN(BuildContext context) async {
    // First verify current PIN
    final verified = await _verifyCurrentPIN(context);
    if (!verified || !context.mounted) return;

    // Then set new PIN using the setup page
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PinSetupPage(
          showIntro: false,
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsPinUpdatedSuccessfully)),
      );
    }
  }

  Future<bool> _verifyCurrentPIN(BuildContext context) async {
    final palette = context.appPalette;
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enter Current PIN',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.settingsHintPinDigits,
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              final valid = await AppLockService.verifyPin(controller.text);
              if (ctx.mounted) Navigator.pop(ctx, valid);
            },
            child: Text(
              context.l10n.settingsVerify,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.primary,
              ),
            ),
          ),
        ],
      ),
    );
    if (result != true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsIncorrectPin)),
      );
    }
    return result == true;
  }

  Future<void> _editBackupPassphrase(BuildContext context) async {
    final verified = await _verifyCurrentPIN(context);
    if (!verified || !context.mounted) return;

    final hasPassphrase = await BackupPassphraseService.hasStoredPassphrase();
    if (!context.mounted) return;

    final controller = TextEditingController();
    final palette = context.appPalette;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Backup passphrase',
          style: TextStyle(
            color: palette.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          style: TextStyle(color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: hasPassphrase
                ? 'Enter a new backup passphrase'
                : 'Enter backup passphrase',
            helperText: 'Stored on this device. Different from PIN.',
            hintStyle: TextStyle(color: palette.textMuted),
            helperStyle: TextStyle(color: palette.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.stroke),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          if (hasPassphrase)
            TextButton(
              onPressed: () => Navigator.pop(ctx, '__clear__'),
              child: Text('Remove', style: TextStyle(color: palette.danger)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(
              'Save',
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !context.mounted) return;

    if (result == '__clear__') {
      await BackupPassphraseService.clearPassphrase();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup passphrase removed.')),
      );
      return;
    }

    if (result.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a backup passphrase first.')),
      );
      return;
    }

    await BackupPassphraseService.storePassphrase(result.trim());
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Backup passphrase saved.')));
  }

  Future<void> _testRestore(BuildContext context) async {
    try {
      final result = await getIt<ValidateChain>()(const ValidateChainParams());
      if (!context.mounted) return;
      final message = switch (result.status) {
        ChainValidationStatus.valid =>
          'Restore check passed. Backup chain is valid.',
        ChainValidationStatus.empty => 'No backups to test yet.',
        _ => result.message ?? 'Backup restore check failed.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore check failed: $error')));
    }
  }

  Future<void> _toggleWipeAfterFive(
    BuildContext context,
    bool currentlyEnabled,
  ) async {
    if (!currentlyEnabled) {
      final confirmed = await _confirmWipeAfterFive(context);
      if (confirmed != true || !context.mounted) return;
    }

    final verified = await _verifyCurrentPIN(context);
    if (!verified || !context.mounted) return;

    await AppLockService.setWipeAfterFiveAttemptsEnabled(!currentlyEnabled);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currentlyEnabled
              ? 'Wrong PIN attempts now soft-lock the vault.'
              : 'Local wipe after five wrong PIN attempts is enabled.',
        ),
      ),
    );
  }

  Future<bool?> _confirmWipeAfterFive(BuildContext context) {
    final palette = context.appPalette;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Enable local wipe?',
          style: TextStyle(color: palette.danger, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'After five wrong PIN attempts, Credence will delete local vault data on this device. Backups are left untouched.',
          style: TextStyle(color: palette.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Enable',
              style: TextStyle(
                color: palette.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTheme(BuildContext context) async {
    final controller = ThemeController.of(context);
    final current = controller.mode;
    final l10n = context.l10n;

    final options = <({ThemeMode mode, String label, IconData icon})>[
      (
        mode: ThemeMode.system,
        label: l10n.settingsThemeSystem,
        icon: Icons.brightness_auto_rounded,
      ),
      (
        mode: ThemeMode.light,
        label: l10n.settingsThemeLight,
        icon: Icons.light_mode_rounded,
      ),
      (
        mode: ThemeMode.dark,
        label: l10n.settingsThemeDark,
        icon: Icons.dark_mode_rounded,
      ),
    ];

    final palette = context.appPalette;

    await showAdaptiveModal<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.settingsThemeTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              for (final opt in options) ...[
                Material(
                  color: opt.mode == current
                      ? palette.primarySoft
                      : palette.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      controller.setMode(opt.mode);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: opt.mode == current
                              ? palette.primary.withValues(alpha: 0.3)
                              : palette.stroke,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            opt.icon,
                            size: 22,
                            color: opt.mode == current
                                ? palette.primary
                                : palette.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: opt.mode == current
                                    ? palette.primary
                                    : palette.textPrimary,
                              ),
                            ),
                          ),
                          if (opt.mode == current)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 22,
                              color: palette.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBiometricSheet(BuildContext context) async {
    final available = await AppLockService.isBiometricAvailable();
    final enabled = await AppLockService.isBiometricEnabled();
    if (!context.mounted) return;

    final palette = context.appPalette;
    final l10n = context.l10n;

    await showAdaptiveModal<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 28,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.settingsBiometricTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                available
                    ? 'Use Face ID or fingerprint to unlock your vault quickly without entering your PIN.'
                    : 'Biometric authentication is not available on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (available) ...[
                _biometricOption(
                  ctx,
                  icon: Icons.check_circle_rounded,
                  label: l10n.settingsBiometricEnabledLabel,
                  subtitle: l10n.settingsBiometricEnabledSubtitle,
                  selected: enabled,
                  onTap: () async {
                    final authenticated =
                        await AppLockService.authenticateWithBiometrics(
                          reason: 'Enable biometric unlock for Credence',
                        );
                    if (!authenticated) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Biometric verification failed.'),
                          ),
                        );
                      }
                      return;
                    }
                    await AppLockService.setBiometricEnabled(true);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.settingsBiometricEnabled),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                _biometricOption(
                  ctx,
                  icon: Icons.pin_outlined,
                  label: 'PIN Only',
                  subtitle: l10n.settingsBiometricDisabledSubtitle,
                  selected: !enabled,
                  onTap: () async {
                    await AppLockService.setBiometricEnabled(false);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.settingsBiometricDisabled),
                        ),
                      );
                    }
                  },
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Color(0xFFD97706),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your device does not support biometric authentication.',
                          style: TextStyle(
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
        ),
      ),
    );
  }

  Future<void> _showRevealAuthSheet(BuildContext context) async {
    final enabled = await AppLockService.isRevealAuthRequired();
    if (!context.mounted) return;

    final palette = context.appPalette;
    final l10n = context.l10n;

    await showAdaptiveModal<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.lock_open_rounded,
                  size: 28,
                  color: palette.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.settingsRevealAuthTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.settingsRevealAuthSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _biometricOption(
                ctx,
                icon: Icons.shield_rounded,
                label: l10n.settingsRevealAuthEnabled,
                subtitle: l10n.settingsRevealAuthEnabledDetail,
                selected: enabled,
                onTap: () async {
                  await AppLockService.setRevealAuthRequired(true);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsRevealAuthEnabled)),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              _biometricOption(
                ctx,
                icon: Icons.visibility_rounded,
                label: l10n.settingsRevealAuthDisabled,
                subtitle: l10n.settingsRevealAuthDisabledDetail,
                selected: !enabled,
                onTap: () async {
                  await AppLockService.setRevealAuthRequired(false);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsRevealAuthDisabled)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _biometricOption(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final palette = context.appPalette;
    return Material(
      color: selected ? palette.primarySoft : palette.surfaceSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? palette.primary.withValues(alpha: 0.3)
                  : palette.stroke,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? palette.primary : palette.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? palette.primary : palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: palette.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _wipeVault(BuildContext context) async {
    final palette = context.appPalette;
    final controller = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final typed = controller.text.trim().toUpperCase();
            final canWipe = typed == 'WIPE';
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  MediaQuery.viewInsetsOf(ctx).bottom + 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: palette.strokeStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: AuthLockShield(
                        icon: Icons.delete_outline_rounded,
                        warn: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.settingsWipeDialogTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: authDisplayFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.45,
                        color: palette.danger,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This deletes everything stored on this device. Backups remain untouched, but local credentials, documents, collections, bundles, tasks, and settings are removed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: authDisplayFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: palette.textSecondary,
                      ),
                    ),
                    const AuthSectionHeader('What gets deleted'),
                    _WipeConsequenceRow(
                      label: 'Credentials and generated passwords',
                      palette: palette,
                    ),
                    _WipeConsequenceRow(
                      label: 'Documents, files, images, and collection icons',
                      palette: palette,
                    ),
                    _WipeConsequenceRow(
                      label: 'Collections, bundles, tasks, and local settings',
                      palette: palette,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: palette.danger.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TYPE WIPE TO CONFIRM',
                            style: TextStyle(
                              fontFamily: authMonoFont,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: palette.danger,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: controller,
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) => setSheetState(() {}),
                            decoration: InputDecoration(
                              hintText: 'WIPE',
                              filled: true,
                              fillColor: palette.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: palette.danger.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: palette.danger.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: palette.danger,
                                  width: 1.8,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: authMonoFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
                              color: palette.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AuthActionButton(
                            label: 'Restore instead',
                            primary: false,
                            onTap: () => Navigator.pop(ctx, false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AuthActionButton(
                            label: context.l10n.settingsWipeEverything,
                            danger: true,
                            onTap: canWipe
                                ? () => Navigator.pop(ctx, true)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Wipe enables once you type WIPE. PIN verification follows.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: authMonoFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    if (confirmed != true || !context.mounted) return;

    // Double confirm
    final verified = await _verifyCurrentPIN(context);
    if (!verified || !context.mounted) return;

    await VaultWipeService.wipeLocalVault();

    if (context.mounted) {
      // Push a fresh CredenceApp so _resolveGate() re-runs and lands on onboarding
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CredenceApp()),
        (_) => false,
      );
    }
  }

  Future<void> _navigateToExport(BuildContext context) async {
    final passphrase = await _promptPassphrase(context);
    if (passphrase == null || passphrase.isEmpty || !context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExportProgressDialog(passphrase: passphrase),
    );
  }

  Future<void> _importVaultData(BuildContext context) async {
    // 1. Pick a .zip file. file_picker with withData:false streams the archive
    //    to a cache path instead of loading it into the Android Java heap —
    //    file_selector's openFile OOMs on large (100MB+) vault archives.
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: false,
    );
    final pickedPath = picked?.files.single.path;
    if (pickedPath == null || !context.mounted) return;

    // 2. Ask for the passphrase used during export
    final passphrase = await _promptImportPassphrase(context);
    if (passphrase == null || passphrase.isEmpty || !context.mounted) return;

    // 3. Show full-screen import overlay
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _ImportProgressDialog(filePath: pickedPath, passphrase: passphrase),
    );
  }

  Future<String?> _promptImportPassphrase(BuildContext context) async {
    final controller = TextEditingController();
    final palette = context.appPalette;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.settingsImportPassphraseTitle,
          style: TextStyle(color: palette.textPrimary),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: TextStyle(color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: context.l10n.settingsImportPassphraseHint,
            hintStyle: TextStyle(color: palette.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.stroke),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(context.l10n.settingsImportAction),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptPassphrase(BuildContext context) async {
    final controller = TextEditingController();
    final palette = context.appPalette;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.settingsExportPassphraseTitle,
          style: TextStyle(color: palette.textPrimary),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: TextStyle(color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: context.l10n.settingsExportPassphraseHint,
            hintStyle: TextStyle(color: palette.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.stroke),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: palette.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(context.l10n.settingsExportButton),
          ),
        ],
      ),
    );
  }
}

class _WipeConsequenceRow extends StatelessWidget {
  const _WipeConsequenceRow({required this.label, required this.palette});

  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: palette.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: authDisplayFont,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.05,
                color: palette.textPrimary,
              ),
            ),
          ),
          Text(
            'DELETED',
            style: TextStyle(
              fontFamily: authMonoFont,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: palette.danger,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ExportStep { exporting, success, error }

class _ExportProgressDialog extends StatefulWidget {
  const _ExportProgressDialog({required this.passphrase});

  final String passphrase;

  @override
  State<_ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<_ExportProgressDialog> {
  _ExportStep _step = _ExportStep.exporting;
  String _statusMessage = 'Preparing vault export';
  String _statusDetail =
      'Collecting encrypted records, linked files, images, and saved settings.';
  String _errorMessage = '';
  double? _progress = 0.04;
  ExportVaultWithFilesResultEntity? _result;

  @override
  void initState() {
    super.initState();
    _runExport();
  }

  Future<void> _runExport() async {
    try {
      final exportUseCase = getIt<ExportVaultWithFiles>();
      final result = await exportUseCase(
        ExportVaultWithFilesRequestEntity(
          scope: PortableDataScope.all,
          passphrase: widget.passphrase,
          includeCredentials: true,
          includeCollections: true,
          onProgress: _handleExportProgress,
        ),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _statusMessage = 'Opening share sheet';
        _statusDetail =
            'The archive is ready. Share or save it anywhere you want.';
        _progress = 1;
      });

      final xFile = XFile(
        result.archiveFilePath,
        name: result.archiveFilePath.split('/').last,
      );
      await Share.shareXFiles(
        [xFile],
        subject: 'Credence Export',
        sharePositionOrigin: resolveSharePositionOrigin(context),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _step = _ExportStep.success;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _step = _ExportStep.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _handleExportProgress(String message, double? progress) {
    if (!mounted) {
      return;
    }
    setState(() {
      _statusMessage = message;
      _statusDetail = _exportDetailForMessage(message);
      _progress = _exportProgressForMessage(
        message: message,
        rawProgress: progress,
        previousProgress: _progress,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final progressValue = _progress?.clamp(0.0, 1.0);

    return PopScope(
      canPop: _step != _ExportStep.exporting,
      child: Dialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: switch (_step) {
              _ExportStep.exporting => [
                _TransferHeader(
                  icon: Icons.archive_rounded,
                  title: 'Exporting vault',
                  subtitle:
                      'Building a complete archive with records, files, and settings.',
                ),
                const SizedBox(height: 18),
                _TransferStatusCard(
                  message: _statusMessage,
                  detail: _statusDetail,
                  progress: progressValue,
                  accentColor: palette.primary,
                ),
              ],
              _ExportStep.success => [
                _TransferHeader(
                  icon: Icons.check_circle_rounded,
                  title: 'Export complete',
                  subtitle:
                      'The archive was generated successfully and the share sheet was opened.',
                  iconBackground: const Color(0xFF10B981),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _TransferMetricPill(
                      label: 'Documents',
                      value: '${_result?.documentCount ?? 0}',
                    ),
                    _TransferMetricPill(
                      label: 'Passwords',
                      value: '${_result?.passwordCount ?? 0}',
                    ),
                    _TransferMetricPill(
                      label: 'Files',
                      value: '${_result?.fileCount ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
              _ExportStep.error => [
                _TransferHeader(
                  icon: Icons.error_rounded,
                  title: 'Export failed',
                  subtitle: _errorMessage,
                  iconBackground: palette.danger,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.stroke),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(context.l10n.commonCancel),
                  ),
                ),
              ],
            },
          ),
        ),
      ),
    );
  }
}

// ── Import Progress Dialog ──────────────────────────────────────────────────

enum _ImportStep { importing, success, error }

class _ImportProgressDialog extends StatefulWidget {
  const _ImportProgressDialog({
    required this.filePath,
    required this.passphrase,
  });

  final String filePath;
  final String passphrase;

  @override
  State<_ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<_ImportProgressDialog> {
  _ImportStep _step = _ImportStep.importing;
  String _statusMessage = 'Opening backup archive';
  String _statusDetail =
      'Reading the encrypted vault package and preparing local storage.';
  String _errorMessage = '';
  double? _progress = 0.04;
  int _archiveFileCount = 0;
  int _restoredFileCount = 0;
  int _restoredSupplementalCount = 0;
  ImportVaultResultEntity? _importResult;

  @override
  void initState() {
    super.initState();
    _runImport();
  }

  Future<void> _runImport() async {
    try {
      _setImportProgress(
        message: 'Opening backup archive',
        detail:
            'Reading the encrypted vault package and preparing local storage.',
        progress: 0.04,
      );
      final fileBytes = await File(widget.filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(fileBytes);

      // New mirror-format export (Credence-Vault-*.zip): a browsable
      // Collections/Documents/… tree with a `.credence/` metadata folder.
      // Restore it through the same path as the cloud mirror.
      if (archive.findFile(VaultMirrorWorkspace.manifestPath) != null) {
        await _runMirrorArchiveImport(archive);
        return;
      }

      // Legacy encrypted-payload export (a `vault.enc` entry inside the zip).
      final encryptedEntry = archive.findFile('vault.enc');
      if (encryptedEntry == null) {
        if (!mounted) return;
        setState(() {
          _step = _ImportStep.error;
          _errorMessage = context.l10n.settingsImportInvalidFile;
        });
        return;
      }

      final encryptedPayload = encryptedEntry.content as List<int>;
      final archiveFileCount = _countRestorableArchiveFiles(archive);
      _archiveFileCount = archiveFileCount;

      // 1. Extract linked files FIRST — build a path mapping
      _setImportProgress(
        message: 'Extracting archived files',
        detail: archiveFileCount == 0
            ? 'No linked files were found in this archive.'
            : 'Restoring files, images, and attachments to local storage.',
        progress: archiveFileCount == 0 ? 0.52 : 0.08,
      );
      final pathMapping = await _extractLinkedFiles(
        archive,
        onProgress: (processed, total, currentName) {
          if (!mounted) {
            return;
          }
          setState(() {
            _restoredFileCount = processed;
            _statusMessage = 'Extracting archived files';
            _statusDetail = total == 0
                ? 'No linked files were found in this archive.'
                : 'Restored $processed of $total files.';
            _progress = total == 0 ? 0.52 : 0.08 + ((processed / total) * 0.44);
          });
        },
      );

      // 2. Import the vault data (credentials, documents, collections)
      _setImportProgress(
        message: 'Importing vault records',
        detail:
            'Applying encrypted documents, credentials, collections, and profile data.',
        progress: 0.62,
      );
      final importUseCase = getIt<ImportVaultData>();
      final importResult = await importUseCase(
        ImportVaultRequestEntity(
          encryptedPayload: encryptedPayload,
          passphrase: widget.passphrase,
          strategy: ImportMergeStrategy.merge,
        ),
      );
      _importResult = importResult;

      // 3. Rewrite archive paths in Hive to absolute device paths
      if (pathMapping.isNotEmpty) {
        _setImportProgress(
          message: 'Relinking restored files',
          detail: 'Reconnecting imported records to local file paths.',
          progress: 0.84,
        );
        await _rewriteImportedPaths(pathMapping);
      }
      _setImportProgress(
        message: 'Restoring saved settings',
        detail:
            'Bringing back backup history, sync settings, and local preferences.',
        progress: 0.92,
      );
      await _restoreSupplementalBoxes(
        archive,
        onProgress: (processed, total) {
          if (!mounted) {
            return;
          }
          setState(() {
            _restoredSupplementalCount = processed;
            _statusMessage = 'Restoring saved settings';
            _statusDetail = total == 0
                ? 'No additional settings snapshots were found in this archive.'
                : 'Restored $processed of $total saved-state snapshots.';
            _progress = total == 0 ? 0.98 : 0.92 + ((processed / total) * 0.06);
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Restore complete';
        _statusDetail =
            'Everything in this archive is now available on this device.';
        _progress = 1;
        _step = _ImportStep.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _ImportStep.error;
        _errorMessage = e is FormatException
            ? context.l10n.settingsImportInvalidFile
            : context.l10n.settingsImportFailed;
      });
    }
  }

  /// Restores a Credence-Vault-*.zip (mirror-format) export through the same
  /// [VaultMirrorImportService] the cloud restore uses, reading manifest,
  /// snapshot, and files straight from the archive — no temp unpacking.
  Future<void> _runMirrorArchiveImport(Archive archive) async {
    _setImportProgress(
      message: 'Restoring vault',
      detail: 'Reading the archive and restoring your records and files.',
      progress: 0.08,
    );
    final result = await getIt<VaultMirrorImportService>().importFromSource(
      source: ZipArchiveVaultMirrorImportSource(archive),
      mode: VaultMirrorImportMode.merge,
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _statusMessage = progress.message;
          _statusDetail = progress.detail;
          _progress = progress.progress;
          final total = progress.totalCount;
          final processed = progress.processedCount;
          if (total != null) _archiveFileCount = total;
          if (processed != null) _restoredFileCount = processed;
        });
      },
    );
    VaultDataRefreshSignal.notifyRestoreCompleted();

    // The mirror result reports one entity total, not a per-type breakdown, so
    // read the recap counts from the archive's snapshot for the summary pills.
    var documentCount = 0;
    var passwordCount = 0;
    final snapshotEntry = archive.findFile(VaultMirrorWorkspace.snapshotPath);
    if (snapshotEntry != null) {
      try {
        final snapshot = jsonDecode(
          utf8.decode(snapshotEntry.content as List<int>),
        );
        if (snapshot is Map) {
          final documents = snapshot['documents'];
          final credentials = snapshot['credentials'];
          documentCount = documents is List ? documents.length : 0;
          passwordCount = credentials is List ? credentials.length : 0;
        }
      } catch (_) {
        // Recap counts are best-effort; the restore itself already succeeded.
      }
    }

    if (!mounted) return;
    setState(() {
      _importResult = ImportVaultResultEntity(
        importedDocuments: documentCount,
        importedPasswords: passwordCount,
        updatedDocuments: 0,
        updatedPasswords: 0,
      );
      _restoredFileCount = result.fileCount;
      _archiveFileCount = result.fileCount;
      _statusMessage = 'Restore complete';
      _statusDetail =
          result.warningMessage ??
          'Restored ${result.entityCount} records and '
              '${result.fileCount} files from the archive.';
      _progress = 1;
      _step = _ImportStep.success;
    });
  }

  void _setImportProgress({
    required String message,
    required String detail,
    required double? progress,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      _statusMessage = message;
      _statusDetail = detail;
      _progress = progress;
    });
  }

  /// Extracts all linked files from the ZIP archive to the app support directory.
  /// Returns a mapping from archive path → absolute device path for path rewriting.
  Future<Map<String, String>> _extractLinkedFiles(
    Archive archive, {
    void Function(int processed, int total, String currentName)? onProgress,
  }) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final basePath = appSupportDir.path;
    final pathMapping = <String, String>{};

    const knownPrefixes = [
      'files/',
      'collection_block_assets/',
      'collection_icons/',
      'company_logos/',
      'document_images/',
      'identity_documents/',
      'profile_images/',
      'property_document_assets/',
      'reference_assets/',
      'travel_trip_assets/',
      'work_company_logos/',
      'work_document_assets/',
      'work_statement_assets/',
    ];

    final entries = archive
        .where(
          (entry) =>
              entry.isFile &&
              entry.name != 'vault.enc' &&
              entry.name != 'vault.json' &&
              entry.name != 'manifest.json' &&
              !_supplementalBoxArchiveEntries.values.contains(entry.name),
        )
        .toList(growable: false);
    final total = entries.length;
    var processed = 0;

    for (final entry in entries) {
      String targetPath;

      final matchesKnown = knownPrefixes.any((p) => entry.name.startsWith(p));
      if (matchesKnown) {
        if (entry.name.startsWith('files/')) {
          final fileName = entry.name.substring('files/'.length);
          targetPath = '$basePath/document_images/$fileName';
        } else {
          targetPath = '$basePath/${entry.name}';
        }
      } else {
        targetPath = '$basePath/${entry.name}';
      }

      final targetFile = File(targetPath);
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(entry.content as List<int>);

      // Record: archive path → absolute device path
      pathMapping[entry.name] = targetPath;
      processed += 1;
      onProgress?.call(processed, total, entry.name);
    }
    return pathMapping;
  }

  Future<void> _restoreSupplementalBoxes(
    Archive archive, {
    void Function(int processed, int total)? onProgress,
  }) async {
    final existingEntries = _supplementalBoxArchiveEntries.entries
        .where((entry) => archive.findFile(entry.value)?.isFile ?? false)
        .toList(growable: false);
    final total = existingEntries.length;
    var processed = 0;

    for (final entry in existingEntries) {
      final archiveEntry = archive.findFile(entry.value);
      if (archiveEntry == null || !archiveEntry.isFile) {
        continue;
      }

      try {
        final content = archiveEntry.content as List<int>;
        final decoded = jsonDecode(utf8.decode(content));
        if (decoded is! Map) {
          continue;
        }

        final box = await EncryptedHiveBoxFactory.openEncryptedBox(entry.key);
        await box.clear();
        for (final item in decoded.entries) {
          await box.put(item.key, item.value);
        }
      } catch (_) {
        // Keep the main vault import resilient even if an optional box payload is malformed.
      }
      processed += 1;
      onProgress?.call(processed, total);
    }
  }

  int _countRestorableArchiveFiles(Archive archive) {
    return archive
        .where(
          (entry) =>
              entry.isFile &&
              entry.name != 'vault.enc' &&
              entry.name != 'vault.json' &&
              entry.name != 'manifest.json' &&
              !_supplementalBoxArchiveEntries.values.contains(entry.name),
        )
        .length;
  }

  /// Rewrites archive-relative file paths in all Hive boxes to absolute device paths.
  Future<void> _rewriteImportedPaths(Map<String, String> pathMapping) async {
    final docsBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_documents_v1',
    );
    final credsBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_credentials_v1',
    );
    final collectionsBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_collections_v1',
    );
    final profileBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_profile_v1',
    );

    // Rewrite document structuredFields paths
    for (final key in docsBox.keys.toList()) {
      final raw = docsBox.get(key);
      if (raw is! Map) continue;
      final doc = Map<String, dynamic>.from(raw);
      var changed = false;

      if (doc['structuredFields'] is List) {
        final fields = (doc['structuredFields'] as List)
            .map((f) => f is Map ? Map<String, dynamic>.from(f) : f)
            .toList();
        for (var i = 0; i < fields.length; i++) {
          if (fields[i] is! Map<String, dynamic>) continue;
          final field = fields[i] as Map<String, dynamic>;
          final value = (field['value'] ?? '').toString();
          if (value.isEmpty) continue;

          // Check if it's a JSON array (reference assets)
          if (value.startsWith('[')) {
            final rewritten = _rewriteJsonArrayPaths(value, pathMapping);
            if (rewritten != value) {
              field['value'] = rewritten;
              changed = true;
            }
          } else {
            final mapped = _findMappedPath(value, pathMapping);
            if (mapped != null) {
              field['value'] = mapped;
              changed = true;
            }
          }
        }
        if (changed) doc['structuredFields'] = fields;
      }
      if (changed) await docsBox.put(key, doc);
    }

    // Rewrite credential logoPath
    for (final key in credsBox.keys.toList()) {
      final raw = credsBox.get(key);
      if (raw is! Map) continue;
      final cred = Map<String, dynamic>.from(raw);
      final logoPath = (cred['logoPath'] ?? '').toString();
      if (logoPath.isNotEmpty) {
        final mapped = _findMappedPath(logoPath, pathMapping);
        if (mapped != null) {
          cred['logoPath'] = mapped;
          await credsBox.put(key, cred);
        }
      }
    }

    // Rewrite collection block file paths
    for (final key in collectionsBox.keys.toList()) {
      final raw = collectionsBox.get(key);
      if (raw is! Map) continue;
      final col = Map<String, dynamic>.from(raw);
      var changed = false;

      // Collection cover
      for (final field in [
        'cover_image_url',
        'coverImageUrl',
        'icon_image_path',
        'iconImagePath',
      ]) {
        final value = (col[field] ?? '').toString();
        if (value.isNotEmpty) {
          final mapped = _findMappedPath(value, pathMapping);
          if (mapped != null) {
            col[field] = mapped;
            changed = true;
          }
        }
      }

      // Blocks
      if (col['blocks'] is List) {
        final blocks = (col['blocks'] as List)
            .map((b) => b is Map ? Map<String, dynamic>.from(b) : b)
            .toList();
        for (var i = 0; i < blocks.length; i++) {
          if (blocks[i] is! Map<String, dynamic>) continue;
          final block = blocks[i] as Map<String, dynamic>;
          for (final field in [
            'image_url',
            'imageUrl',
            'file_path',
            'filePath',
          ]) {
            final value = (block[field] ?? '').toString();
            if (value.isNotEmpty) {
              final mapped = _findMappedPath(value, pathMapping);
              if (mapped != null) {
                block[field] = mapped;
                changed = true;
              }
            }
          }
          // Block metadata
          if (block['metadata'] is Map) {
            final meta = Map<String, dynamic>.from(block['metadata'] as Map);
            var metaChanged = false;
            for (final mk in meta.keys.toList()) {
              final mv = (meta[mk] ?? '').toString();
              if (mv.isEmpty) continue;
              if (mv.startsWith('[')) {
                final rewritten = _rewriteJsonArrayPaths(mv, pathMapping);
                if (rewritten != mv) {
                  meta[mk] = rewritten;
                  metaChanged = true;
                }
              } else {
                final mapped = _findMappedPath(mv, pathMapping);
                if (mapped != null) {
                  meta[mk] = mapped;
                  metaChanged = true;
                }
              }
            }
            if (metaChanged) {
              block['metadata'] = meta;
              changed = true;
            }
          }
        }
        if (changed) col['blocks'] = blocks;
      }
      if (changed) await collectionsBox.put(key, col);
    }

    final rawProfile = profileBox.get('profile_record');
    if (rawProfile is Map) {
      final profile = Map<String, dynamic>.from(rawProfile);
      final photoPath = (profile['photoPath'] ?? '').toString();
      if (photoPath.isNotEmpty) {
        final mapped = _findMappedPath(photoPath, pathMapping);
        if (mapped != null) {
          profile['photoPath'] = mapped;
          await profileBox.put('profile_record', profile);
        }
      }
    }
  }

  /// Finds the absolute device path for an archive path.
  String? _findMappedPath(String archivePath, Map<String, String> mapping) {
    // Direct match
    if (mapping.containsKey(archivePath)) return mapping[archivePath];
    // Try without leading slash
    final trimmed = archivePath.startsWith('/')
        ? archivePath.substring(1)
        : archivePath;
    if (mapping.containsKey(trimmed)) return mapping[trimmed];
    // Try matching just the filename against all mapped values
    final fileName = archivePath.split('/').last;
    for (final entry in mapping.entries) {
      if (entry.key.endsWith('/$fileName') || entry.key == fileName) {
        return entry.value;
      }
    }
    return null;
  }

  /// Rewrites file paths inside a JSON array string (e.g. reference assets).
  String _rewriteJsonArrayPaths(
    String jsonString,
    Map<String, String> mapping,
  ) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return jsonString;
      var changed = false;
      final rewritten = decoded.map((item) {
        if (item is! Map) return item;
        final path = (item['path'] ?? '').toString();
        if (path.isEmpty) return item;
        final mapped = _findMappedPath(path, mapping);
        if (mapped != null) {
          changed = true;
          return {...item, 'path': mapped};
        }
        return item;
      }).toList();
      return changed ? jsonEncode(rewritten) : jsonString;
    } catch (_) {
      return jsonString;
    }
  }

  void _restartApp() {
    // Pop all routes and push a fresh CredenceApp to fully reload all data.
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CredenceApp()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final progressValue = _progress?.clamp(0.0, 1.0);
    return PopScope(
      canPop: _step != _ImportStep.importing,
      child: Dialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: switch (_step) {
              _ImportStep.importing => [
                _TransferHeader(
                  icon: Icons.restore_rounded,
                  title: 'Restoring vault',
                  subtitle:
                      'Rebuilding your vault data, files, and local settings from the archive.',
                ),
                const SizedBox(height: 18),
                _TransferStatusCard(
                  message: _statusMessage,
                  detail: _statusDetail,
                  progress: progressValue,
                  accentColor: palette.primary,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _TransferMetricPill(
                      label: 'Archive files',
                      value: '$_archiveFileCount',
                    ),
                    _TransferMetricPill(
                      label: 'Restored',
                      value: '$_restoredFileCount',
                    ),
                    _TransferMetricPill(
                      label: 'Settings',
                      value: '$_restoredSupplementalCount',
                    ),
                  ],
                ),
              ],
              _ImportStep.success => [
                _TransferHeader(
                  icon: Icons.check_circle_rounded,
                  title: 'Restore complete',
                  subtitle:
                      'Your vault data, linked files, and local settings were restored successfully.',
                  iconBackground: const Color(0xFF10B981),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _TransferMetricPill(
                      label: 'Docs added',
                      value:
                          '${_importResult?.importedDocuments ?? 0}/${(_importResult?.importedDocuments ?? 0) + (_importResult?.updatedDocuments ?? 0)}',
                    ),
                    _TransferMetricPill(
                      label: 'Passwords',
                      value:
                          '${_importResult?.importedPasswords ?? 0}/${(_importResult?.importedPasswords ?? 0) + (_importResult?.updatedPasswords ?? 0)}',
                    ),
                    _TransferMetricPill(
                      label: 'Files',
                      value: '$_restoredFileCount',
                    ),
                    _TransferMetricPill(
                      label: 'Settings',
                      value: '$_restoredSupplementalCount',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _restartApp,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Restart App'),
                  ),
                ),
              ],
              _ImportStep.error => [
                _TransferHeader(
                  icon: Icons.error_rounded,
                  title: 'Restore failed',
                  subtitle: _errorMessage,
                  iconBackground: palette.danger,
                ),
                const SizedBox(height: 12),
                Text(
                  _statusDetail,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.stroke),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(context.l10n.commonCancel),
                  ),
                ),
              ],
            },
          ),
        ),
      ),
    );
  }
}

class _TransferHeader extends StatelessWidget {
  const _TransferHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final backgroundColor = iconBackground ?? palette.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 30, color: backgroundColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransferStatusCard extends StatelessWidget {
  const _TransferStatusCard({
    required this.message,
    required this.detail,
    required this.progress,
    required this.accentColor,
  });

  final String message;
  final String detail;
  final double? progress;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final normalizedProgress = progress?.clamp(0.0, 1.0);
    final percentLabel = normalizedProgress == null
        ? null
        : '${(normalizedProgress * 100).round()}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              if (percentLabel != null)
                Text(
                  percentLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalizedProgress,
              minHeight: 8,
              backgroundColor: palette.stroke,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferMetricPill extends StatelessWidget {
  const _TransferMetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
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
              color: palette.textMuted,
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSettingsPage extends StatefulWidget {
  const _NotificationsSettingsPage();

  @override
  State<_NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState
    extends State<_NotificationsSettingsPage> {
  static const _leadDayOptions = <int>[30, 14, 7, 3, 1];

  final _store = NotificationSettingsStore.instance;

  NotificationSettingsPrefs _prefs = NotificationSettingsPrefs.defaults;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await _store.read();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _isLoading = false;
    });
  }

  Future<void> _save(NotificationSettingsPrefs prefs) async {
    setState(() => _prefs = prefs);
    try {
      await _store.write(prefs);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save notification setting.')),
      );
      return;
    }
    try {
      await _refreshNotificationSchedules(prefs);
    } catch (error) {
      debugPrint('Could not refresh notification schedules: $error');
    }
  }

  Future<void> _refreshNotificationSchedules(
    NotificationSettingsPrefs prefs,
  ) async {
    await _refreshCollectionReminderSchedules(prefs);
    await getIt<DocumentExpiryService>().scheduleExpiryNotifications();
    await getIt<TaskNotificationService>().scheduleTaskNotifications();
  }

  Future<void> _refreshCollectionReminderSchedules(
    NotificationSettingsPrefs prefs,
  ) async {
    final dataSource = getIt<CollectionsLocalDataSource>();
    final collections = await dataSource.getCollections();
    final notificationService = ReminderNotificationService.instance;
    final now = DateTime.now();

    for (final collection in collections) {
      for (final block in collection.blocks) {
        if (block.typeKey != 'reminder') continue;
        await notificationService.cancelReminder(block.id);

        final scheduledAt = DateTime.tryParse(block.eventAtIso ?? '');
        if (!prefs.collectionRemindersEnabled ||
            scheduledAt == null ||
            scheduledAt.isBefore(now)) {
          continue;
        }

        await notificationService.scheduleReminder(
          id: block.id,
          title: block.title,
          body: block.description.trim().isEmpty ? null : block.description,
          scheduledAt: scheduledAt,
          repeatInterval: block.repeatInterval,
          kind: ReminderNotificationKind.collection,
        );
      }
    }
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      await ReminderNotificationService.instance.init();
      await ReminderNotificationService.instance.requestPermissions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permission requested.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the notification permission prompt.'),
        ),
      );
    }
  }

  Future<void> _pickQuietHours() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(_prefs.quietStartMinutes),
      helpText: 'Quiet hours start',
    );
    if (start == null || !mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: _timeOfDay(_prefs.quietEndMinutes),
      helpText: 'Quiet hours end',
    );
    if (end == null || !mounted) return;

    await _save(
      _prefs.copyWith(
        quietStartMinutes: _minutesFromTime(start),
        quietEndMinutes: _minutesFromTime(end),
      ),
    );
  }

  void _toggleLeadDay(String label) {
    final day = int.tryParse(label.split(' ').first);
    if (day == null) return;
    final next = Set<int>.of(_prefs.leadDays);
    if (next.contains(day)) {
      if (next.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keep at least one lead time.')),
        );
        return;
      }
      next.remove(day);
    } else {
      next.add(day);
    }
    _save(_prefs.copyWith(leadDays: next));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            SettingsReferenceTopBar(
              title: 'Notifications',
              leftLabel: '‹ Settings',
              onLeftTap: () => Navigator.of(context).maybePop(),
            ),
            if (_isLoading)
              SettingsReferenceCard(
                children: [
                  SettingsReferenceNavRow(
                    icon: Icons.notifications_rounded,
                    title: 'Notifications',
                    subtitle: 'Loading notification settings.',
                    trailing: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.textPrimary,
                      ),
                    ),
                    showChevron: false,
                  ),
                ],
              )
            else ...[
              SettingsReferencePermissionCard(
                title: 'Notifications for Credence',
                subtitle: 'Tap to allow banners + sounds',
                onTap: _requestNotificationPermissions,
              ),
              const SettingsReferenceGroupHeader('Document reminders'),
              SettingsReferenceCard(
                children: [
                  SettingsReferenceNavRow(
                    icon: Icons.timer_rounded,
                    title: 'Expiry alerts',
                    subtitle: 'Passports, IDs, work contracts.',
                    trailing: SettingsReferenceToggle(
                      isOn: _prefs.expiryAlertsEnabled,
                    ),
                    showChevron: false,
                    onTap: () => _save(
                      _prefs.copyWith(
                        expiryAlertsEnabled: !_prefs.expiryAlertsEnabled,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const SettingsReferenceGroupHeader('Lead time'),
              SettingsReferenceChips(
                labels: _leadDayOptions.map((day) => '$day d').toList(),
                selected: _prefs.leadDays.map((day) => '$day d').toSet(),
                onTap: _toggleLeadDay,
              ),
              const SettingsReferenceGroupHeader('Collection reminders'),
              SettingsReferenceCard(
                children: [
                  SettingsReferenceNavRow(
                    icon: Icons.event_note_rounded,
                    title: 'All collection reminders',
                    subtitle: 'Reminder blocks · smart-reminders feed.',
                    trailing: SettingsReferenceToggle(
                      isOn: _prefs.collectionRemindersEnabled,
                    ),
                    showChevron: false,
                    onTap: () => _save(
                      _prefs.copyWith(
                        collectionRemindersEnabled:
                            !_prefs.collectionRemindersEnabled,
                      ),
                    ),
                  ),
                  SettingsReferenceNavRow(
                    icon: Icons.widgets_rounded,
                    title: 'Show in Lock Screen widget',
                    subtitle: 'Today + overdue only.',
                    trailing: SettingsReferenceToggle(
                      isOn: _prefs.lockScreenWidgetEnabled,
                    ),
                    showChevron: false,
                    onTap: () => _save(
                      _prefs.copyWith(
                        lockScreenWidgetEnabled:
                            !_prefs.lockScreenWidgetEnabled,
                      ),
                    ),
                  ),
                ],
              ),
              const SettingsReferenceGroupHeader('Tasks'),
              SettingsReferenceCard(
                children: [
                  SettingsReferenceNavRow(
                    icon: Icons.checklist_rounded,
                    title: 'Due-today digest',
                    subtitle: 'One alert at 8 AM.',
                    trailing: SettingsReferenceToggle(
                      isOn: _prefs.dueTodayDigestEnabled,
                    ),
                    showChevron: false,
                    onTap: () => _save(
                      _prefs.copyWith(
                        dueTodayDigestEnabled: !_prefs.dueTodayDigestEnabled,
                      ),
                    ),
                  ),
                  SettingsReferenceNavRow(
                    icon: Icons.error_outline_rounded,
                    title: 'Overdue alerts',
                    subtitle: 'Per task · daily until done.',
                    trailing: SettingsReferenceToggle(
                      isOn: _prefs.overdueAlertsEnabled,
                    ),
                    showChevron: false,
                    onTap: () => _save(
                      _prefs.copyWith(
                        overdueAlertsEnabled: !_prefs.overdueAlertsEnabled,
                      ),
                    ),
                  ),
                ],
              ),
              const SettingsReferenceGroupHeader('Quiet hours'),
              SettingsReferenceCard(
                children: [
                  SettingsReferenceNavRow(
                    icon: Icons.nightlight_round,
                    title: 'Do not disturb',
                    subtitle: 'Reminders queue silently.',
                    value: _quietHoursLabel(_prefs),
                    showChevron: false,
                    onTap: _pickQuietHours,
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }

  String _quietHoursLabel(NotificationSettingsPrefs prefs) {
    return '${_formatMinutes(prefs.quietStartMinutes)} → '
        '${_formatMinutes(prefs.quietEndMinutes)}';
  }

  String _formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay _timeOfDay(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  int _minutesFromTime(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
}

double? _exportProgressForMessage({
  required String message,
  required double? rawProgress,
  required double? previousProgress,
}) {
  final normalized = message.trim().toLowerCase();
  if (normalized.startsWith('loading encrypted vault snapshot')) {
    return 0.08;
  }
  if (normalized.startsWith('resolving linked files')) {
    return 0.18;
  }
  if (normalized.startsWith('collecting app settings')) {
    return 0.28;
  }
  if (normalized.startsWith('scanning local asset folders')) {
    return 0.38;
  }
  if (normalized.startsWith('encrypting vault payload')) {
    return 0.54;
  }
  if (normalized.startsWith('preparing archive container')) {
    return 0.64;
  }
  if (normalized.startsWith('adding files')) {
    final clamped = (rawProgress ?? 0).clamp(0.0, 1.0);
    return 0.68 + (clamped * 0.24);
  }
  if (normalized.startsWith('finalizing archive')) {
    return 0.95;
  }
  if (normalized.startsWith('archive ready')) {
    return 1.0;
  }
  return previousProgress ?? rawProgress;
}

String _exportDetailForMessage(String message) {
  final normalized = message.trim().toLowerCase();
  if (normalized.startsWith('loading encrypted vault snapshot')) {
    return 'Reading documents, credentials, collections, and profile data.';
  }
  if (normalized.startsWith('resolving linked files')) {
    return 'Finding every file path stored inside vault records.';
  }
  if (normalized.startsWith('collecting app settings')) {
    return 'Capturing local settings, sync preferences, and backup metadata.';
  }
  if (normalized.startsWith('scanning local asset folders')) {
    return 'Sweeping asset folders to include images, PDFs, logos, and attachments that are stored locally.';
  }
  if (normalized.startsWith('encrypting vault payload')) {
    return 'Encrypting the portable vault snapshot with your passphrase.';
  }
  if (normalized.startsWith('preparing archive container')) {
    return 'Creating the zip container and writing archive metadata.';
  }
  if (normalized.startsWith('adding files')) {
    return 'Copying every linked asset into the export archive.';
  }
  if (normalized.startsWith('finalizing archive')) {
    return 'Closing the archive and validating the final file.';
  }
  if (normalized.startsWith('archive ready')) {
    return 'The archive is complete and ready to share or save.';
  }
  return 'Working on your encrypted export.';
}

const Map<String, String> _supplementalBoxArchiveEntries = <String, String>{
  'credence_backup_journal_v1': 'supplemental_boxes/credence_backup_journal_v1.json',
  'credence_generator_history_v1':
      'supplemental_boxes/credence_generator_history_v1.json',
  'credence_home_prefs_v1': 'supplemental_boxes/credence_home_prefs_v1.json',
  'credence_sync_prefs_v1': 'supplemental_boxes/credence_sync_prefs_v1.json',
  'credence_notification_settings_v1':
      'supplemental_boxes/credence_notification_settings_v1.json',
};
