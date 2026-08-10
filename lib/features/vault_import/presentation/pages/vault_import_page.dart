import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_selector/file_selector.dart';
import 'package:pass_doc_manager/app/presentation/widgets/vault_error_state.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_credential_entity.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_source.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credentials_reference_ui.dart';
import 'package:pass_doc_manager/features/vault_import/presentation/cubit/vault_import_cubit.dart';
import 'package:pass_doc_manager/features/vault_import/presentation/cubit/vault_import_state.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class VaultImportPage extends StatefulWidget {
  const VaultImportPage({super.key});

  @override
  State<VaultImportPage> createState() => _VaultImportPageState();
}

class _VaultImportPageState extends State<VaultImportPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VaultImportCubit(),
      child: CredentialsReferencePage(
        child: Scaffold(
          backgroundColor: CredentialsReferenceColors.bg,
          body: SafeArea(
            child: BlocBuilder<VaultImportCubit, VaultImportState>(
              builder: (context, state) {
                return switch (state.status) {
                  VaultImportStatus.initial => _buildSourceSelection(context),
                  VaultImportStatus.sourceSelected => _buildFilePick(context),
                  VaultImportStatus.parsing => _buildParsing(context),
                  VaultImportStatus.previewing => _buildPreview(context, state),
                  VaultImportStatus.importing => _buildImporting(context),
                  VaultImportStatus.complete => _buildComplete(context, state),
                  VaultImportStatus.error => _buildError(context, state),
                  VaultImportStatus.filePicked => _buildFilePick(context),
                };
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceSelection(BuildContext context) {
    final cubit = context.read<VaultImportCubit>();

    return Column(
      children: [
        CredentialsHeader(
          title: 'Import credentials',
          centerTitle: true,
          leading: CredentialsTextButton(
            label: 'Cancel',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          trailing: const SizedBox(width: 44),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CredentialsCard(
                  color: CredentialsReferenceColors.lavender,
                  borderColor: const Color(0xFFD8C7EE),
                  padding: const EdgeInsets.all(16),
                  radius: 18,
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: CredentialsReferenceColors.fg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.file_upload_outlined,
                          color: CredentialsReferenceColors.surface,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local-only import',
                              style: credentialsBodyStyle(
                                size: 15,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Pick a source. We parse locally and stage duplicates before anything is written.',
                              style: credentialsBodyStyle(
                                size: 12.5,
                                color: CredentialsReferenceColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const CredentialsSectionLabel('Managers'),
                const SizedBox(height: 8),
                ...ImportSource.values.map(
                  (source) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CredentialsImportSourceRow(
                      title: source.label,
                      subtitle: source.fileType,
                      icon: _sourceIconData(source),
                      color: _sourceColor(source),
                      onTap: () => cubit.selectSource(source),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CredentialsCard(
                  color: CredentialsReferenceColors.blue,
                  borderColor: Colors.transparent,
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'CSV and JSON files never leave the device. Duplicates are detected against the current credentials vault.',
                    style: credentialsBodyStyle(
                      size: 12.5,
                      color: const Color(0xFF526476),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePick(BuildContext context) {
    final cubit = context.read<VaultImportCubit>();
    final source = context.read<VaultImportCubit>().state.source;

    if (source == null) {
      return _buildError(context, context.read<VaultImportCubit>().state);
    }

    final instructions = switch (source) {
      ImportSource.onePassword => context.l10n.importInstructions1Password,
      ImportSource.bitwarden => context.l10n.importInstructionsBitwarden,
      ImportSource.chrome => context.l10n.importInstructionsChrome,
      ImportSource.safari => context.l10n.importInstructionsSafari,
      ImportSource.lastPass => context.l10n.importInstructionsLastPass,
    };

    return Column(
      children: [
        CredentialsHeader(
          title: '${source.label} import',
          centerTitle: true,
          leading: CredentialsTextButton(
            label: 'Back',
            onTap: () => cubit.reset(),
          ),
          trailing: const SizedBox(width: 44),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CredentialsImportSourceRow(
                  title: source.label,
                  subtitle: source.fileType,
                  icon: _sourceIconData(source),
                  color: _sourceColor(source),
                ),
                const SizedBox(height: 14),
                CredentialsCard(
                  padding: const EdgeInsets.all(16),
                  radius: 18,
                  child: Text(
                    instructions,
                    style: credentialsBodyStyle(
                      size: 13,
                      color: CredentialsReferenceColors.muted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => _pickFile(context, cubit, source),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4EF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CredentialsReferenceColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: CredentialsReferenceColors.lavender,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: CredentialsReferenceColors.fg,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.l10n.importSelectFile,
                          style: credentialsDisplayStyle(size: 22),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          source.fileType.toUpperCase(),
                          style: credentialsMonoStyle(size: 10.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParsing(BuildContext context) {
    return _buildBusyState(
      title: 'Reading credentials',
      subtitle:
          'Parsing the file locally and checking for matching vault entries.',
      icon: Icons.manage_search_rounded,
    );
  }

  Widget _buildPreview(BuildContext context, VaultImportState state) {
    final cubit = context.read<VaultImportCubit>();
    final q = _searchQuery.toLowerCase();
    final filteredWithIndex = <(int, ImportCredentialEntity)>[];
    for (var i = 0; i < state.parsedItems.length; i++) {
      final item = state.parsedItems[i];
      if (q.isEmpty ||
          item.serviceName.toLowerCase().contains(q) ||
          item.username.toLowerCase().contains(q) ||
          item.url.toLowerCase().contains(q)) {
        filteredWithIndex.add((i, item));
      }
    }
    final source = state.source;
    final sourceLabel = source?.label ?? 'Vault';
    final newCount = state.parsedItems.length - state.duplicateCount;

    return Column(
      children: [
        CredentialsHeader(
          title: '$sourceLabel import',
          centerTitle: true,
          leading: CredentialsTextButton(
            label: 'Back',
            onTap: () => cubit.reset(),
          ),
          trailing: CredentialsTextButton(
            label: 'All',
            color: CredentialsReferenceColors.fg,
            onTap: () => cubit.selectAll(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 118),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CredentialsCard(
                  color: CredentialsReferenceColors.lavender,
                  borderColor: const Color(0xFFD7C7EB),
                  padding: const EdgeInsets.all(16),
                  radius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.importPreview,
                        style: credentialsDisplayStyle(size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Found ${state.parsedItems.length} credentials. Select what should enter your vault.',
                        style: credentialsBodyStyle(
                          size: 13,
                          color: CredentialsReferenceColors.muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ImportMetricStrip(
                        metrics: [
                          _ImportMetric(
                            label: 'selected',
                            value: state.selectedCount.toString(),
                          ),
                          _ImportMetric(
                            label: 'new',
                            value: newCount.toString(),
                          ),
                          _ImportMetric(
                            label: 'duplicates',
                            value: state.duplicateCount.toString(),
                            color: state.duplicateCount > 0
                                ? CredentialsReferenceColors.warn
                                : CredentialsReferenceColors.muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      CredentialsChip(
                        label: 'All ${state.parsedItems.length}',
                        active: true,
                      ),
                      const SizedBox(width: 8),
                      CredentialsChip(label: 'New $newCount'),
                      const SizedBox(width: 8),
                      CredentialsChip(
                        label: 'Duplicates ${state.duplicateCount}',
                      ),
                      const SizedBox(width: 8),
                      CredentialsChip(label: 'Selected ${state.selectedCount}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CredentialsSearchField(
                  controller: _searchController,
                  hint: 'Search credentials',
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  trailing: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: CredentialsReferenceColors.muted,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                CredentialsListGroup(
                  children: filteredWithIndex.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              'No credentials match this search.',
                              textAlign: TextAlign.center,
                              style: credentialsBodyStyle(
                                size: 13,
                                color: CredentialsReferenceColors.muted,
                              ),
                            ),
                          ),
                        ]
                      : filteredWithIndex
                            .map((entry) {
                              final (originalIndex, item) = entry;
                              return CredentialsImportCredentialRow(
                                title: item.serviceName,
                                subtitle: item.username.isEmpty
                                    ? (item.url.isEmpty
                                          ? 'No username'
                                          : item.url)
                                    : item.username,
                                selected: item.isSelected,
                                tag: _importTag(item),
                                tagTone: _importTagTone(item),
                                onTap: () =>
                                    cubit.toggleItemSelection(originalIndex),
                                onLongPress: () =>
                                    _showCredentialPreview(context, item),
                              );
                            })
                            .toList(growable: false),
                ),
                if (state.duplicateCount > 0) ...[
                  const SizedBox(height: 14),
                  CredentialsCard(
                    color: const Color(0xFFF5EAD7),
                    borderColor: Colors.transparent,
                    padding: const EdgeInsets.all(14),
                    radius: 16,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: CredentialsReferenceColors.warn,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.importDuplicates(state.duplicateCount),
                            style: credentialsBodyStyle(
                              size: 12.5,
                              color: CredentialsReferenceColors.warn,
                              height: 1.35,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => cubit.deselectDuplicates(),
                          child: Text(
                            'Skip',
                            style: credentialsBodyStyle(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: CredentialsReferenceColors.warn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
            decoration: const BoxDecoration(
              color: CredentialsReferenceColors.bg,
              border: Border(
                top: BorderSide(color: CredentialsReferenceColors.hairline),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CredentialsPrimaryButton(
                  label: state.selectedCount == 0
                      ? context.l10n.importImportSelected
                      : 'Import ${state.selectedCount} credentials',
                  icon: Icons.download_done_rounded,
                  onTap: state.canImport ? () => cubit.executeImport() : null,
                  backgroundColor: CredentialsReferenceColors.fg,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: state.selectedCount > 0 ? cubit.deselectAll : null,
                  child: Text(
                    'Deselect all',
                    style: credentialsBodyStyle(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: state.selectedCount > 0
                          ? CredentialsReferenceColors.muted
                          : const Color(0xFFC8C1B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCredentialPreview(
    BuildContext context,
    ImportCredentialEntity item,
  ) {
    showAdaptiveModal<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CredentialsReferenceColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CredentialsReferenceColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                CredentialsBrandAvatar(serviceName: item.serviceName, size: 58),
                const SizedBox(height: 12),
                Text(
                  item.serviceName,
                  textAlign: TextAlign.center,
                  style: credentialsDisplayStyle(size: 24),
                ),
                const SizedBox(height: 18),
                CredentialsListGroup(
                  children: [
                    CredentialsField(
                      label: 'Username',
                      value: item.username.isEmpty
                          ? 'Not provided'
                          : item.username,
                    ),
                    CredentialsField(
                      label: 'Password',
                      value: '\u2022' * (item.password.length.clamp(6, 20)),
                    ),
                    if (item.url.isNotEmpty)
                      CredentialsField(label: 'URL', value: item.url),
                    if ((item.totp ?? '').isNotEmpty)
                      const CredentialsField(
                        label: 'TOTP',
                        value: 'Configured',
                      ),
                    if (item.notes.isNotEmpty)
                      CredentialsField(label: 'Notes', value: item.notes),
                  ],
                ),
                if (item.isDuplicate)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ImportNoticeBanner(
                      icon: Icons.warning_amber_rounded,
                      title: 'Duplicate credential',
                      message:
                          'This service and username already exist in your vault.',
                      color: CredentialsReferenceColors.warn,
                    ),
                  ),
                const SizedBox(height: 18),
                CredentialsPrimaryButton(
                  label: 'Close',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImporting(BuildContext context) {
    return _buildBusyState(
      title: 'Saving credentials',
      subtitle: 'Selected entries are being written to your vault.',
      icon: Icons.lock_rounded,
    );
  }

  Widget _buildComplete(BuildContext context, VaultImportState state) {
    final result = state.importResult;

    if (result == null) {
      return _buildError(context, state);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: CredentialsReferenceColors.mint,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: CredentialsReferenceColors.ok,
              size: 42,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.importSuccess,
            textAlign: TextAlign.center,
            style: credentialsDisplayStyle(size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.importCompleted(
              result.imported,
              result.skippedDuplicates,
            ),
            textAlign: TextAlign.center,
            style: credentialsBodyStyle(
              size: 14,
              color: CredentialsReferenceColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          _ImportMetricStrip(
            metrics: [
              _ImportMetric(
                label: 'imported',
                value: result.imported.toString(),
                color: CredentialsReferenceColors.ok,
              ),
              _ImportMetric(
                label: 'skipped',
                value: result.skippedDuplicates.toString(),
              ),
              _ImportMetric(
                label: 'errors',
                value: result.errors.toString(),
                color: result.errors > 0
                    ? CredentialsReferenceColors.risk
                    : CredentialsReferenceColors.muted,
              ),
            ],
          ),
          if (result.errors > 0) ...[
            const SizedBox(height: 14),
            _ImportNoticeBanner(
              icon: Icons.error_outline_rounded,
              title: 'Some entries failed',
              message: context.l10n.importErrors(result.errors),
              color: CredentialsReferenceColors.risk,
            ),
          ],
          const Spacer(),
          CredentialsPrimaryButton(
            label: 'Done',
            icon: Icons.check_rounded,
            onTap: () {
              context.read<VaultImportCubit>().reset();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: CredentialsReferenceColors.fg,
                  backgroundColor: CredentialsReferenceColors.hairline,
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: CredentialsReferenceColors.lavender,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: CredentialsReferenceColors.fg,
                  size: 25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: credentialsDisplayStyle(size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: credentialsBodyStyle(
              size: 14,
              color: CredentialsReferenceColors.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  IconData _sourceIconData(ImportSource source) {
    return switch (source) {
      ImportSource.onePassword => Icons.vpn_key_rounded,
      ImportSource.bitwarden => Icons.security_rounded,
      ImportSource.chrome => Icons.language_rounded,
      ImportSource.safari => Icons.explore_rounded,
      ImportSource.lastPass => Icons.password_rounded,
    };
  }

  Color _sourceColor(ImportSource source) {
    return switch (source) {
      ImportSource.onePassword => const Color(0xFF302A3E),
      ImportSource.bitwarden => const Color(0xFF2F6FDB),
      ImportSource.chrome => const Color(0xFF3E9A6B),
      ImportSource.safari => const Color(0xFF4D8FC8),
      ImportSource.lastPass => const Color(0xFFC64E3C),
    };
  }

  String _importTag(ImportCredentialEntity item) {
    if (!item.isSelected) {
      return 'off';
    }
    return item.isDuplicate ? 'dup' : 'new';
  }

  CredentialsPillTone _importTagTone(ImportCredentialEntity item) {
    if (!item.isSelected) {
      return CredentialsPillTone.ghost;
    }
    return item.isDuplicate ? CredentialsPillTone.warn : CredentialsPillTone.ok;
  }

  Widget _buildError(BuildContext context, VaultImportState state) {
    return VaultErrorState(
      message: state.errorMessage ?? context.l10n.commonErrorGeneric,
      onRetry: () {
        context.read<VaultImportCubit>().reset();
      },
      icon: Icons.upload_file_rounded,
    );
  }

  Future<void> _pickFile(
    BuildContext context,
    VaultImportCubit cubit,
    ImportSource source,
  ) async {
    final typeGroup = switch (source) {
      ImportSource.bitwarden => XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
        uniformTypeIdentifiers: ['public.json'],
      ),
      _ => XTypeGroup(
        label: 'CSV',
        extensions: ['csv'],
        uniformTypeIdentifiers: ['public.comma-separated-values-text'],
      ),
    };

    final dangerColor = context.appPalette.danger;
    try {
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) {
        return;
      }

      final content = await file.readAsString();
      if (!context.mounted) {
        return;
      }
      await cubit.parseFile(fileContent: content);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read file: $e'),
            backgroundColor: dangerColor,
          ),
        );
      }
    }
  }
}

class _ImportMetric {
  const _ImportMetric({
    required this.label,
    required this.value,
    this.color = CredentialsReferenceColors.fg,
  });

  final String label;
  final String value;
  final Color color;
}

class _ImportMetricStrip extends StatelessWidget {
  const _ImportMetricStrip({required this.metrics});

  final List<_ImportMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return CredentialsCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i != 0) const SizedBox(width: 10),
            Expanded(child: _ImportMetricCell(metric: metrics[i])),
          ],
        ],
      ),
    );
  }
}

class _ImportMetricCell extends StatelessWidget {
  const _ImportMetricCell({required this.metric});

  final _ImportMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.value,
          style: credentialsDisplayStyle(size: 20, color: metric.color),
        ),
        const SizedBox(height: 2),
        Text(
          metric.label.toUpperCase(),
          style: credentialsMonoStyle(size: 9.5),
        ),
      ],
    );
  }
}

class _ImportNoticeBanner extends StatelessWidget {
  const _ImportNoticeBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CredentialsCard(
      color: color.withValues(alpha: 0.12),
      borderColor: color.withValues(alpha: 0.24),
      padding: const EdgeInsets.all(14),
      radius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: CredentialsReferenceColors.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: credentialsBodyStyle(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: credentialsBodyStyle(
                    size: 12.5,
                    color: CredentialsReferenceColors.fg.withValues(
                      alpha: 0.72,
                    ),
                    height: 1.4,
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
