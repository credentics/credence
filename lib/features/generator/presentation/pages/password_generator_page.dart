import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/core/utils/sensitive_clipboard.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/generated_password_history_entry_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/evaluate_password_health.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/generate_password.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/get_vault_sync_settings.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/get_vault_sync_status.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/run_vault_sync_now.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/save_vault_sync_settings.dart';
import 'package:pass_doc_manager/features/generator/presentation/cubit/password_generator_cubit.dart';
import 'package:pass_doc_manager/features/generator/presentation/cubit/password_generator_state.dart';
import 'package:pass_doc_manager/features/settings/presentation/pages/vault_sync_settings_page.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credentials_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class PasswordGeneratorPage extends StatelessWidget {
  PasswordGeneratorPage({
    super.key,
    GeneratePassword? generatePassword,
    EvaluatePasswordHealth? evaluatePasswordHealth,
    GetVaultSyncSettings? getVaultSyncSettings,
    SaveVaultSyncSettings? saveVaultSyncSettings,
    GetVaultSyncStatus? getVaultSyncStatus,
    RunVaultSyncNow? runVaultSyncNow,
    this.embeddedDesktop = false,
    this.embeddedMobile = false,
    this.onEmbeddedBackTap,
  }) : generatePassword = generatePassword ?? getIt(),
       evaluatePasswordHealth = evaluatePasswordHealth ?? getIt(),
       getVaultSyncSettings = getVaultSyncSettings ?? getIt(),
       saveVaultSyncSettings = saveVaultSyncSettings ?? getIt(),
       getVaultSyncStatus = getVaultSyncStatus ?? getIt(),
       runVaultSyncNow = runVaultSyncNow ?? getIt();

  final GeneratePassword generatePassword;
  final EvaluatePasswordHealth evaluatePasswordHealth;
  final GetVaultSyncSettings getVaultSyncSettings;
  final SaveVaultSyncSettings saveVaultSyncSettings;
  final GetVaultSyncStatus getVaultSyncStatus;
  final RunVaultSyncNow runVaultSyncNow;
  final bool embeddedDesktop;
  final bool embeddedMobile;
  final VoidCallback? onEmbeddedBackTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PasswordGeneratorCubit(
        generatePassword: generatePassword,
        evaluatePasswordHealth: evaluatePasswordHealth,
      )..load(),
      child: _PasswordGeneratorView(
        getVaultSyncSettings: getVaultSyncSettings,
        saveVaultSyncSettings: saveVaultSyncSettings,
        getVaultSyncStatus: getVaultSyncStatus,
        runVaultSyncNow: runVaultSyncNow,
        embeddedDesktop: embeddedDesktop,
        embeddedMobile: embeddedMobile,
        onEmbeddedBackTap: onEmbeddedBackTap,
      ),
    );
  }
}

class _PasswordGeneratorView extends StatelessWidget {
  const _PasswordGeneratorView({
    required this.getVaultSyncSettings,
    required this.saveVaultSyncSettings,
    required this.getVaultSyncStatus,
    required this.runVaultSyncNow,
    required this.embeddedDesktop,
    required this.embeddedMobile,
    required this.onEmbeddedBackTap,
  });

  final GetVaultSyncSettings getVaultSyncSettings;
  final SaveVaultSyncSettings saveVaultSyncSettings;
  final GetVaultSyncStatus getVaultSyncStatus;
  final RunVaultSyncNow runVaultSyncNow;
  final bool embeddedDesktop;
  final bool embeddedMobile;
  final VoidCallback? onEmbeddedBackTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PasswordGeneratorCubit, PasswordGeneratorState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1080;
            if (isDesktop) {
              if (embeddedDesktop) {
                return _desktopEmbedded(context, state);
              }
              return _desktop(context, state);
            }
            return _mobile(context, state);
          },
        );
      },
    );
  }

  Widget _desktop(BuildContext context, PasswordGeneratorState state) {
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.backgroundAlt,
      body: Column(
        children: [
          _DesktopGeneratorTopBar(
            onVaultTap: () => Navigator.of(context).maybePop(),
            onSettingsTap: () => _openSettings(context),
          ),
          Expanded(
            child: Row(
              children: [
                _DesktopGeneratorSidebar(
                  onVaultTap: () => Navigator.of(context).maybePop(),
                  onHistoryTap: () => _openHistory(context, state),
                ),
                Expanded(child: _desktopContent(context, state)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopEmbedded(BuildContext context, PasswordGeneratorState state) {
    return _desktopContent(
      context,
      state,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
    );
  }

  Widget _desktopContent(
    BuildContext context,
    PasswordGeneratorState state, {
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(38, 32, 38, 30),
  }) {
    return SingleChildScrollView(
      padding: padding,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Password Generator',
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                  color: context.appPalette.textPrimary,
                  letterSpacing: -1.8,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Generate ultra-secure passwords that are impossible to crack but tailored to your specific requirements.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appPalette.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              _DesktopGeneratorCard(
                state: state,
                onCopy: () =>
                    _copyPassword(context, state.password, saveInHistory: true),
                onRegenerate: () =>
                    context.read<PasswordGeneratorCubit>().regenerate(),
                onLengthChanged: (value) => context
                    .read<PasswordGeneratorCubit>()
                    .setLength(value.round()),
                onToggleUppercase: (value) => context
                    .read<PasswordGeneratorCubit>()
                    .toggleUppercase(value),
                onToggleLowercase: (value) => context
                    .read<PasswordGeneratorCubit>()
                    .toggleLowercase(value),
                onToggleNumbers: (value) =>
                    context.read<PasswordGeneratorCubit>().toggleNumbers(value),
                onToggleSymbols: (value) =>
                    context.read<PasswordGeneratorCubit>().toggleSymbols(value),
              ),
              const SizedBox(height: 26),
              _DesktopMetricsRow(state: state),
              if (state.viewStatus == PasswordGeneratorViewStatus.error) ...[
                const SizedBox(height: 16),
                _GeneratorErrorBanner(
                  message:
                      state.errorMessage ?? context.l10n.generatorErrorGenerate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobile(BuildContext context, PasswordGeneratorState state) {
    final report = state.healthReport;
    final password = state.password.trim().isEmpty
        ? 'Tap regenerate to create a password'
        : state.password;
    final score = report?.score ?? 0;
    final recent = state.history.take(3).toList(growable: false);
    final content = CredentialsReferencePage(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          children: [
            CredentialsHeader(
              title: 'Generate password',
              centerTitle: true,
              leading: CredentialsIconButton(
                icon: Icons.close_rounded,
                onTap: () {
                  if (onEmbeddedBackTap != null) {
                    onEmbeddedBackTap!.call();
                    return;
                  }
                  Navigator.of(context).maybePop();
                },
              ),
              trailing: CredentialsTextButton(
                label: 'Use',
                onTap: state.password.trim().isEmpty
                    ? null
                    : () => _copyPassword(
                        context,
                        state.password,
                        saveInHistory: true,
                      ),
                color: state.password.trim().isEmpty
                    ? CredentialsReferenceColors.muted
                    : CredentialsReferenceColors.fg,
                weight: FontWeight.w700,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CredentialsGeneratorDisplay(
                    password: password,
                    score: score,
                    strengthLabel: _strengthLabel(report?.level),
                    caption: _generatorCaption(state),
                    onCopy: state.password.trim().isEmpty
                        ? null
                        : () => _copyPassword(
                            context,
                            state.password,
                            saveInHistory: true,
                          ),
                    onRegenerate: state.isBusy
                        ? null
                        : () => context
                              .read<PasswordGeneratorCubit>()
                              .regenerate(),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text('LENGTH', style: credentialsMonoStyle()),
                          const Spacer(),
                          Text(
                            '${state.length}',
                            style: credentialsDisplayStyle(
                              size: 18,
                              color: CredentialsReferenceColors.fg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5,
                          activeTrackColor: CredentialsReferenceColors.fg,
                          inactiveTrackColor:
                              CredentialsReferenceColors.hairline,
                          thumbColor: CredentialsReferenceColors.fg,
                          overlayColor: CredentialsReferenceColors.fg
                              .withValues(alpha: 0.12),
                        ),
                        child: Slider(
                          value: state.length.clamp(8, 40).toDouble(),
                          min: 8,
                          max: 40,
                          onChanged: (value) => context
                              .read<PasswordGeneratorCubit>()
                              .setLength(value.round()),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['8', '16', '24', '32', '40']
                            .map((label) {
                              return Text(
                                label,
                                style: credentialsMonoStyle(
                                  size: 9.5,
                                  letterSpacing: 0.6,
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const CredentialsSectionLabel('CHARACTER SET'),
                  const SizedBox(height: 8),
                  CredentialsListGroup(
                    children: [
                      _ReferenceGeneratorRuleRow(
                        title: context.l10n.generatorMobileRuleUppercase,
                        meta: 'A-Z',
                        value: state.includeUppercase,
                        onChanged: (value) => context
                            .read<PasswordGeneratorCubit>()
                            .toggleUppercase(value),
                      ),
                      _ReferenceGeneratorRuleRow(
                        title: context.l10n.generatorMobileRuleNumbers,
                        meta: '0-9',
                        value: state.includeNumbers,
                        onChanged: (value) => context
                            .read<PasswordGeneratorCubit>()
                            .toggleNumbers(value),
                      ),
                      _ReferenceGeneratorRuleRow(
                        title: context.l10n.generatorMobileRuleSymbols,
                        meta: '!@#\$%&*',
                        value: state.includeSymbols,
                        onChanged: (value) => context
                            .read<PasswordGeneratorCubit>()
                            .toggleSymbols(value),
                      ),
                      const _ReferenceGeneratorRuleRow(
                        title: 'Avoid ambiguous',
                        meta: 'no 0/O · 1/l/I',
                        value: true,
                      ),
                      const _ReferenceGeneratorRuleRow(
                        title: 'Pronounceable',
                        meta: 'word-style',
                        value: false,
                      ),
                    ],
                  ),
                  if (recent.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const CredentialsSectionLabel('RECENT · LAST 3'),
                    const SizedBox(height: 8),
                    CredentialsCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      radius: 16,
                      child: Column(
                        children: recent
                            .map(
                              (entry) => _ReferenceGeneratorRecentRow(
                                entry: entry,
                                onTap: () => context
                                    .read<PasswordGeneratorCubit>()
                                    .useHistoryPassword(entry.password),
                                onCopy: () =>
                                    _copyPassword(context, entry.password),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                  if (state.errorMessage != null &&
                      state.errorMessage!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _GeneratorErrorBanner(message: state.errorMessage!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (embeddedMobile) {
      return content;
    }

    return Scaffold(
      backgroundColor: CredentialsReferenceColors.bg,
      body: SafeArea(child: content),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VaultSyncSettingsPage(
          getSettings: getVaultSyncSettings,
          getStatus: getVaultSyncStatus,
          saveSettings: saveVaultSyncSettings,
          runSyncNow: runVaultSyncNow,
        ),
      ),
    );
  }

  Future<void> _copyPassword(
    BuildContext context,
    String password, {
    bool saveInHistory = false,
  }) async {
    if (password.trim().isEmpty) {
      return;
    }
    final cubit = context.read<PasswordGeneratorCubit>();
    await SensitiveClipboard.copy(password);
    if (saveInHistory) {
      await cubit.saveCopiedPassword(password: password);
    }
    if (!context.mounted) {
      return;
    }
    _toast(context, 'Password copied.');
  }

  Future<void> _openHistory(
    BuildContext context,
    PasswordGeneratorState state,
  ) async {
    final cubit = context.read<PasswordGeneratorCubit>();
    final isDesktop = MediaQuery.of(context).size.width >= 1080;

    if (isDesktop) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 560),
            child: _PasswordHistoryPanel(
              entries: state.history,
              onCopy: (value) => _copyPassword(context, value),
              onUse: (value) async {
                await cubit.useHistoryPassword(value);
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
                _toast(context, 'Password loaded from history.');
              },
              onClear: state.history.isEmpty
                  ? null
                  : () async {
                      await cubit.clearHistory();
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                      _toast(context, 'History cleared.');
                    },
            ),
          ),
        ),
      );
      return;
    }

    await showAdaptiveModal<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PasswordHistoryPanel(
        entries: state.history,
        onCopy: (value) => _copyPassword(context, value),
        onUse: (value) async {
          await cubit.useHistoryPassword(value);
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pop();
          _toast(context, 'Password loaded from history.');
        },
        onClear: state.history.isEmpty
            ? null
            : () async {
                await cubit.clearHistory();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
                _toast(context, 'History cleared.');
              },
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

String _generatorCaption(PasswordGeneratorState state) {
  final report = state.healthReport;
  if (state.isBusy) {
    return 'Generating';
  }
  if (report == null) {
    return '${state.length} chars';
  }
  return '${state.length} chars · ${report.entropyBits.round()} bits';
}

class _ReferenceGeneratorRuleRow extends StatelessWidget {
  const _ReferenceGeneratorRuleRow({
    required this.title,
    required this.meta,
    required this.value,
    this.onChanged,
  });

  final String title;
  final String meta;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: credentialsBodyStyle(size: 14.5, weight: FontWeight.w700),
            ),
          ),
          Text(
            meta,
            style: credentialsMonoStyle(
              size: 10,
              weight: FontWeight.w600,
              color: CredentialsReferenceColors.muted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 12),
          if (onChanged == null)
            _ReferenceGeneratorStaticToggle(value: value)
          else
            CredentialsToggle(value: value, onChanged: onChanged!),
        ],
      ),
    );
  }
}

class _ReferenceGeneratorStaticToggle extends StatelessWidget {
  const _ReferenceGeneratorStaticToggle({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value
            ? CredentialsReferenceColors.fg.withValues(alpha: 0.72)
            : const Color(0xFFE7E2DA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: CredentialsReferenceColors.surface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ReferenceGeneratorRecentRow extends StatelessWidget {
  const _ReferenceGeneratorRecentRow({
    required this.entry,
    required this.onTap,
    required this.onCopy,
  });

  final GeneratedPasswordHistoryEntryEntity entry;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 15,
                  color: CredentialsReferenceColors.muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.password,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: credentialsMonoStyle(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: CredentialsReferenceColors.fg,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _historyTimeLabel(entry.createdAt),
                style: credentialsMonoStyle(
                  size: 9.5,
                  weight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              IconButton(
                onPressed: onCopy,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_rounded, size: 16),
                color: CredentialsReferenceColors.muted,
                tooltip: context.l10n.generatorCopy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopGeneratorTopBar extends StatelessWidget {
  const _DesktopGeneratorTopBar({
    required this.onVaultTap,
    required this.onSettingsTap,
  });

  final VoidCallback onVaultTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.stroke)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primarySoft,
              border: Border.all(color: palette.stroke),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: palette.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Credence',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 0.95,
              letterSpacing: -1.2,
              color: palette.textPrimary,
            ),
          ),
          SizedBox(width: 24),
          SizedBox(
            width: 230,
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                isDense: true,
                hintText: context.l10n.generatorSearchHint,
                hintStyle: TextStyle(
                  color: palette.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: palette.primary,
                ),
                filled: true,
                fillColor: palette.surfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Spacer(),
          _DesktopTopNavItem(
            label: context.l10n.generatorNavVaults,
            onTap: onVaultTap,
          ),
          _DesktopTopNavItem(
            label: context.l10n.generatorNavPasswords,
            active: true,
          ),
          _DesktopTopNavItem(label: context.l10n.generatorNavSecurity),
          _DesktopTopNavItem(
            label: context.l10n.generatorNavSettings,
            onTap: onSettingsTap,
          ),
          SizedBox(width: 12),
          const _CircleIcon(icon: Icons.notifications_none_rounded),
          SizedBox(width: 8),
          const _CircleIcon(icon: Icons.help_outline_rounded),
          SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.stroke),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _DesktopTopNavItem extends StatelessWidget {
  const _DesktopTopNavItem({
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: active ? palette.primary : palette.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 2,
            color: active ? palette.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _DesktopGeneratorSidebar extends StatelessWidget {
  const _DesktopGeneratorSidebar({
    required this.onVaultTap,
    required this.onHistoryTap,
  });

  final VoidCallback onVaultTap;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(right: BorderSide(color: palette.stroke)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 22, 24, 10),
            child: Text(
              'PERSONAL SECURITY',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w700,
                color: palette.primary,
              ),
            ),
          ),
          _DesktopSideItem(
            icon: Icons.key_rounded,
            label: context.l10n.generatorSideMyPasswords,
            onTap: onVaultTap,
          ),
          _DesktopSideItem(
            icon: Icons.auto_fix_high_rounded,
            label: context.l10n.generatorSideGenerator,
            active: true,
          ),
          _DesktopSideItem(
            icon: Icons.verified_user_outlined,
            label: context.l10n.generatorSideSecurityAudit,
          ),
          _DesktopSideItem(
            icon: Icons.history_toggle_off_rounded,
            label: context.l10n.generatorSideHistory,
            onTap: onHistoryTap,
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(22),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.stroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vault Capacity',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                  ),
                ),
                SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                  child: LinearProgressIndicator(
                    value: 0.64,
                    minHeight: 8,
                    color: palette.primary,
                    backgroundColor: palette.background,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '128 of 200 items used',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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

class _DesktopSideItem extends StatelessWidget {
  const _DesktopSideItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: active ? palette.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active ? palette.primary : palette.textSecondary,
                ),
                SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? palette.primary : palette.textPrimary,
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

class _DesktopGeneratorCard extends StatelessWidget {
  const _DesktopGeneratorCard({
    required this.state,
    required this.onCopy,
    required this.onRegenerate,
    required this.onLengthChanged,
    required this.onToggleUppercase,
    required this.onToggleLowercase,
    required this.onToggleNumbers,
    required this.onToggleSymbols,
  });

  final PasswordGeneratorState state;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;
  final ValueChanged<double> onLengthChanged;
  final ValueChanged<bool> onToggleUppercase;
  final ValueChanged<bool> onToggleLowercase;
  final ValueChanged<bool> onToggleNumbers;
  final ValueChanged<bool> onToggleSymbols;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final report = state.healthReport;
    final score = report?.score ?? 0;
    final strength = _strengthLabel(report?.level);
    final strengthColor = _strengthColor(context, report?.level);
    final shownPassword = state.password.trim().isEmpty
        ? 'kH7\$mQ9!zL2&pX4#vR9@'
        : state.password;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 22, 18, 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.primarySoft, width: 1.6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          shownPassword,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _GradientActionButton(
                        label: context.l10n.generatorCopy,
                        onTap: onCopy,
                        icon: Icons.copy_all_rounded,
                        busy: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: state.isBusy ? null : onRegenerate,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: palette.primarySoft),
                    foregroundColor: palette.primary,
                    backgroundColor: palette.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: state.isBusy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.autorenew_rounded, size: 18),
                  label: Text(
                    state.isBusy
                        ? context.l10n.generatorGenerating
                        : context.l10n.generatorRegenerate,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      context.l10n.generatorStrengthLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.verified, color: strengthColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$strength (${report?.entropyBits.round() ?? 0} bits)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: strengthColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: score / 100,
                    backgroundColor: palette.stroke,
                    color: strengthColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LengthControlPanel(
                    length: state.length,
                    onChanged: onLengthChanged,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'CHARACTER RULES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _RuleToggleRow(
                        code: 'ABC',
                        title: context.l10n.generatorRuleUppercaseLetters,
                        value: state.includeUppercase,
                        onChanged: onToggleUppercase,
                      ),
                      const SizedBox(height: 9),
                      _RuleToggleRow(
                        code: 'abc',
                        title: context.l10n.generatorRuleLowercaseLetters,
                        value: state.includeLowercase,
                        onChanged: onToggleLowercase,
                      ),
                      const SizedBox(height: 9),
                      _RuleToggleRow(
                        code: '123',
                        title: context.l10n.generatorRuleIncludeNumbers,
                        value: state.includeNumbers,
                        onChanged: onToggleNumbers,
                      ),
                      const SizedBox(height: 9),
                      _RuleToggleRow(
                        code: '!@#',
                        title: context.l10n.generatorRuleIncludeSymbols,
                        value: state.includeSymbols,
                        onChanged: onToggleSymbols,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.stroke)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: palette.textSecondary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Securely generated in-browser. No data is sent to our servers.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.textSecondary,
                    ),
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

class _LengthControlPanel extends StatelessWidget {
  const _LengthControlPanel({required this.length, required this.onChanged});

  final int length;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'LENGTH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.primary,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$length',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                  color: palette.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            activeTrackColor: palette.primary,
            inactiveTrackColor: palette.stroke,
            thumbColor: palette.primary,
            overlayColor: palette.primary.withValues(alpha: 0.16),
          ),
          child: Slider(
            value: length.toDouble(),
            min: 8,
            max: 40,
            onChanged: onChanged,
          ),
        ),
        Row(
          children: [
            Text(
              '8 CHARS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.textMuted,
              ),
            ),
            Spacer(),
            Text(
              '40 CHARS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Text(
          'Common industry standards recommend at least 12-16 characters for critical accounts.',
          style: TextStyle(
            fontSize: 13,
            color: palette.textSecondary,
            height: 1.33,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RuleToggleRow extends StatelessWidget {
  const _RuleToggleRow({
    required this.code,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String code;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 32,
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              code,
              style: TextStyle(
                color: palette.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: palette.primary,
            inactiveTrackColor: palette.stroke,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _DesktopMetricsRow extends StatelessWidget {
  const _DesktopMetricsRow({required this.state});

  final PasswordGeneratorState state;

  @override
  Widget build(BuildContext context) {
    final report = state.healthReport;
    final entropy = report?.entropyBits.round() ?? 0;
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.psychology_alt_outlined,
            iconColor: const Color(0xFF1EA672),
            iconBg: const Color(0xFFDBF5E8),
            title: context.l10n.generatorMetricEntropy,
            value: '$entropy bits',
            subtitle: context.l10n.generatorMetricEntropyDesc,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFF2C72E0),
            iconBg: const Color(0xFFDDEBFF),
            title: context.l10n.generatorMetricCrackTime,
            value: report?.estimatedCrackTime ?? 'Unknown',
            subtitle: context.l10n.generatorMetricCrackTimeDesc,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            icon: Icons.swap_horiz_rounded,
            iconColor: const Color(0xFFD28A00),
            iconBg: const Color(0xFFFFEFCF),
            title: context.l10n.generatorMetricEasyToType,
            value: _easyTypeValue(state),
            subtitle: context.l10n.generatorMetricEasyToTypeDesc,
          ),
        ),
      ],
    );
  }

  String _easyTypeValue(PasswordGeneratorState state) {
    if (state.includeNumbers && state.includeSymbols) {
      return 'Balanced';
    }
    if (state.includeNumbers || state.includeSymbols) {
      return 'Moderate';
    }
    return 'High';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 19,
              color: palette.textPrimary,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: palette.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: palette.textSecondary,
              height: 1.32,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.onTap,
    required this.icon,
    required this.busy,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.primary, palette.primaryAccent],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.surface,
            border: Border.all(color: palette.stroke),
          ),
          child: Icon(icon, color: palette.textPrimary, size: 19),
        ),
      ),
    );
  }
}

class _PasswordHistoryPanel extends StatelessWidget {
  const _PasswordHistoryPanel({
    required this.entries,
    required this.onCopy,
    required this.onUse,
    required this.onClear,
  });

  final List<GeneratedPasswordHistoryEntryEntity> entries;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onUse;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.stroke,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Password History',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onClear,
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: palette.danger,
                    ),
                  ),
                ),
              ],
            ),
            if (entries.isEmpty) ...[
              SizedBox(height: 28),
              Icon(
                Icons.history_toggle_off_rounded,
                size: 34,
                color: palette.textMuted,
              ),
              SizedBox(height: 12),
              Text(
                'No generated passwords yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 26),
            ] else ...[
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _PasswordHistoryRow(
                      entry: entry,
                      onCopy: () => onCopy(entry.password),
                      onUse: () => onUse(entry.password),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PasswordHistoryRow extends StatelessWidget {
  const _PasswordHistoryRow({
    required this.entry,
    required this.onCopy,
    required this.onUse,
  });

  final GeneratedPasswordHistoryEntryEntity entry;
  final VoidCallback onCopy;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final scoreLabel = entry.score == null ? '' : ' • ${entry.score}/100';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.stroke),
        color: palette.surfaceSoft,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.password,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '${entry.length} chars • ${_historyTimeLabel(entry.createdAt)}$scoreLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onCopy,
            tooltip: context.l10n.generatorCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: palette.primary,
          ),
          TextButton(
            onPressed: onUse,
            style: TextButton.styleFrom(
              foregroundColor: palette.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: Text(context.l10n.generatorUse),
          ),
        ],
      ),
    );
  }
}

String _historyTimeLabel(DateTime value) {
  final now = DateTime.now();
  var delta = now.difference(value);
  if (delta.isNegative) {
    delta = Duration.zero;
  }
  if (delta.inSeconds < 60) {
    return 'Just now';
  }
  if (delta.inMinutes < 60) {
    return '${delta.inMinutes}m ago';
  }
  if (delta.inHours < 24) {
    return '${delta.inHours}h ago';
  }
  if (delta.inDays == 1) {
    return 'Yesterday';
  }
  if (delta.inDays < 7) {
    return '${delta.inDays}d ago';
  }
  return '${value.day}/${value.month}/${value.year}';
}

class _GeneratorErrorBanner extends StatelessWidget {
  const _GeneratorErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.appPalette.dangerSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appPalette.dangerStroke),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: context.appPalette.danger),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.appPalette.danger,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _strengthLabel(PasswordHealthLevel? level) {
  return switch (level) {
    PasswordHealthLevel.weak => 'Weak',
    PasswordHealthLevel.fair => 'Fair',
    PasswordHealthLevel.strong => 'Strong',
    PasswordHealthLevel.excellent => 'Very Strong',
    null => 'Analyzing',
  };
}

Color _strengthColor(BuildContext context, PasswordHealthLevel? level) {
  final palette = context.appPalette;
  return switch (level) {
    PasswordHealthLevel.weak => palette.danger,
    PasswordHealthLevel.fair => palette.warning,
    PasswordHealthLevel.strong => palette.success,
    PasswordHealthLevel.excellent => palette.success,
    null => palette.primary,
  };
}
