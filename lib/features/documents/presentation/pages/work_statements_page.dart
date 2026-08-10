import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_statement_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/work_company_detail_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/work_company_detail_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_company_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_document_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_folder_documents_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_payslip_history_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class WorkStatementsPage extends StatelessWidget {
  const WorkStatementsPage({
    super.key,
    required this.companyId,
    required this.companyName,
    this.initialFolder,
    GetWorkCompanyDetail? getWorkCompanyDetail,
  }) : _getWorkCompanyDetail = getWorkCompanyDetail;

  final String companyId;
  final String companyName;
  final WorkDocumentFolderType? initialFolder;
  final GetWorkCompanyDetail? _getWorkCompanyDetail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WorkCompanyDetailCubit(getWorkCompanyDetail: _getWorkCompanyDetail)
            ..load(companyId: companyId),
      child: _WorkStatementsView(
        companyId: companyId,
        companyName: companyName,
        initialFolder: initialFolder,
      ),
    );
  }
}

class _WorkStatementsView extends StatefulWidget {
  const _WorkStatementsView({
    required this.companyId,
    required this.companyName,
    required this.initialFolder,
  });

  final String companyId;
  final String companyName;
  final WorkDocumentFolderType? initialFolder;

  @override
  State<_WorkStatementsView> createState() => _WorkStatementsViewState();
}

class _WorkStatementsViewState extends State<_WorkStatementsView> {
  bool _didApplyInitialFolder = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<WorkCompanyDetailCubit, WorkCompanyDetailState>(
      listenWhen: (previous, current) => previous.detail != current.detail,
      listener: (context, state) {
        if (_didApplyInitialFolder) {
          return;
        }
        final folder = widget.initialFolder;
        if (folder == null || state.detail == null) {
          return;
        }
        _didApplyInitialFolder = true;
        if (folder == WorkDocumentFolderType.payslips) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            unawaited(_openPayslipsHistory(context, state.detail!));
          });
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          unawaited(
            _openFolderDocumentsHistory(context, folder, state.detail!),
          );
        });
      },
      builder: (context, state) {
        final detail = state.detail;
        if ((state.viewStatus == WorkCompanyDetailViewStatus.initial ||
                state.viewStatus == WorkCompanyDetailViewStatus.loading) &&
            detail == null) {
          return Scaffold(
            backgroundColor: context.appPalette.background,
            body: Center(child: CupertinoActivityIndicator(radius: 12)),
          );
        }

        if (state.viewStatus == WorkCompanyDetailViewStatus.error &&
            detail == null) {
          return Scaffold(
            backgroundColor: context.appPalette.background,
            appBar: GenericAppBar(
              backgroundColor: context.appPalette.surface,
              onBackPressed: () => Navigator.of(context).maybePop(),
              title: widget.companyName,
              titleStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
              showDivider: false,
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.errorMessage ?? l10n.workCompanyLoadError,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context
                        .read<WorkCompanyDetailCubit>()
                        .load(companyId: widget.companyId),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            ),
          );
        }

        if (detail == null) {
          return const SizedBox.shrink();
        }

        final selectedFolder = state.selectedFolder;
        final statements = _visibleStatements(
          source: detail.statements,
          selectedFolder: selectedFolder,
        );

        return Scaffold(
          backgroundColor: context.appPalette.background,
          appBar: GenericAppBar(
            backgroundColor: context.appPalette.surface,
            onBackPressed: () => Navigator.of(context).maybePop(),
            title: l10n.workCompanyVaultTitle,
            titleStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textPrimary,
            ),
            actionIcon: Icons.edit_rounded,
            onActionPressed: () => _openEditCompany(context, detail),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openAddRecord(context, detail),
            backgroundColor: context.appPalette.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add_rounded, size: 30),
          ),
          body: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    _CompanySummaryCard(detail: detail),
                    SizedBox(height: 24),
                    Text(
                      l10n.workCompanyFoldersTitle,
                      style: TextStyle(
                        fontSize: 24 / 1.2,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ..._visibleFolders.map((folder) {
                      final summary = _folderSummaryFor(detail, folder);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FolderRowCard(
                          folder: folder,
                          title: _folderTitle(context, folder),
                          filesCount: summary,
                          onTap: () => _onFolderTap(folder, detail),
                        ),
                      );
                    }),
                    SizedBox(height: 16),
                    Text(
                      l10n.documentsRecentActivityTitle,
                      style: TextStyle(
                        fontSize: 24 / 1.2,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (statements.where(_isValidStatement).isEmpty)
                      _emptyRecent(context)
                    else
                      ...statements
                          .where(_isValidStatement)
                          .take(6)
                          .map(
                            (statement) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RecentDocumentTile(
                                statement: statement,
                                subtitle: _recentSubtitle(
                                  context,
                                  statement.statementDate ??
                                      statement.updatedAt,
                                ),
                                onTap: () =>
                                    _openDocument(statement.documentId),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<WorkStatementEntity> _visibleStatements({
    required List<WorkStatementEntity> source,
    required WorkDocumentFolderType? selectedFolder,
  }) {
    final filtered = selectedFolder == null
        ? source
        : source.where((item) => item.folderType == selectedFolder);
    final list = filtered.toList(growable: false);
    list.sort((a, b) {
      final aDate = a.statementDate ?? a.updatedAt;
      final bDate = b.statementDate ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });
    return list;
  }

  int _folderSummaryFor(
    WorkCompanyDetailEntity detail,
    WorkDocumentFolderType folder,
  ) {
    for (final summary in detail.folderSummaries) {
      if (summary.folderType == folder) {
        return summary.documentsCount;
      }
    }
    return 0;
  }

  String _folderTitle(BuildContext context, WorkDocumentFolderType folder) {
    final l10n = context.l10n;
    return switch (folder) {
      WorkDocumentFolderType.payslips => l10n.workCompanyFolderPayslipsTitle,
      WorkDocumentFolderType.contracts => l10n.workCompanyFolderContractsTitle,
      WorkDocumentFolderType.taxForms => l10n.workCompanyFolderTaxFormsTitle,
      WorkDocumentFolderType.offboarding =>
        l10n.workCompanyFolderOffboardingTitle,
      WorkDocumentFolderType.benefits => l10n.workCompanyFolderBenefitsTitle,
      WorkDocumentFolderType.milestones =>
        l10n.workCompanyFolderMilestonesTitle,
      WorkDocumentFolderType.other => l10n.workCompanyFolderOtherTitle,
    };
  }

  Future<void> _onFolderTap(
    WorkDocumentFolderType folder,
    WorkCompanyDetailEntity detail,
  ) async {
    if (folder == WorkDocumentFolderType.payslips) {
      await _openPayslipsHistory(context, detail);
      return;
    }
    await _openFolderDocumentsHistory(context, folder, detail);
  }

  Widget _emptyRecent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.workCompanyRecentEmptyTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.l10n.workCompanyRecentEmptySubtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textSecondary,
              height: 1.32,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocument(String documentId) async {
    final cubit = context.read<WorkCompanyDetailCubit>();

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(documentId: documentId),
      ),
    );

    if (!mounted) return;
    await cubit.load(companyId: widget.companyId);
  }

  Future<void> _openEditCompany(
    BuildContext context,
    WorkCompanyDetailEntity detail,
  ) async {
    final docId = detail.profileDocumentId;
    if (docId == null || docId.trim().isEmpty) return;
    final cubit = context.read<WorkCompanyDetailCubit>();
    await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => WorkCompanyEntryPage(
          editDocumentId: docId,
          initialDetail: detail,
        ),
      ),
    );
    if (!mounted) return;
    await cubit.load(companyId: widget.companyId);
  }

  Future<void> _openAddRecord(
    BuildContext context,
    WorkCompanyDetailEntity detail,
  ) async {
    final cubit = context.read<WorkCompanyDetailCubit>();
    final createdId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => WorkDocumentEntryPage(
          initialCompanyName: detail.companyName,
          initialCompanyLogoPath: detail.companyLogoPath,
        ),
      ),
    );
    if (!mounted || (createdId ?? '').trim().isEmpty) {
      return;
    }
    await cubit.load(companyId: widget.companyId);
  }

  Future<void> _openPayslipsHistory(
    BuildContext context,
    WorkCompanyDetailEntity detail,
  ) async {
    final cubit = context.read<WorkCompanyDetailCubit>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkPayslipHistoryPage.company(
          companyId: detail.companyId,
          companyName: detail.companyName,
          companyRole: detail.roleLabel,
          companyLogoPath: detail.companyLogoPath,
          initialStatements: detail.statements
              .where(
                (item) => item.folderType == WorkDocumentFolderType.payslips,
              )
              .toList(growable: false),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await cubit.load(companyId: widget.companyId);
  }

  Future<void> _openFolderDocumentsHistory(
    BuildContext context,
    WorkDocumentFolderType folder,
    WorkCompanyDetailEntity detail,
  ) async {
    final cubit = context.read<WorkCompanyDetailCubit>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkFolderDocumentsPage(
          companyId: detail.companyId,
          companyName: detail.companyName,
          folderType: folder,
          screenTitle: _folderDocumentsScreenTitle(context, folder),
          initialStatements: detail.statements
              .where((item) => item.folderType == folder)
              .toList(growable: false),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await cubit.load(companyId: widget.companyId);
  }

  String _folderDocumentsScreenTitle(
    BuildContext context,
    WorkDocumentFolderType folder,
  ) {
    final l10n = context.l10n;
    return switch (folder) {
      WorkDocumentFolderType.contracts =>
        l10n.workFolderHistoryContractsAndLegal,
      WorkDocumentFolderType.taxForms => l10n.workCompanyFolderTaxFormsTitle,
      WorkDocumentFolderType.offboarding =>
        l10n.workCompanyFolderOffboardingTitle,
      WorkDocumentFolderType.benefits => l10n.workCompanyFolderBenefitsTitle,
      WorkDocumentFolderType.milestones =>
        l10n.workCompanyFolderMilestonesTitle,
      WorkDocumentFolderType.other => l10n.workCompanyFolderOtherTitle,
      WorkDocumentFolderType.payslips => l10n.workPayslipHistoryTitle,
    };
  }

  bool _isValidStatement(WorkStatementEntity s) {
    final t = s.title.trim();
    if (t.isEmpty) return false;
    if (RegExp(r'^Document_\d+$').hasMatch(t)) return false;
    return true;
  }

  String _recentSubtitle(BuildContext context, DateTime value) {
    final local = value.isUtc ? value.toLocal() : value;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(local.year, local.month, local.day);
    final dayDelta = today.difference(targetDay).inDays;

    if (dayDelta == 1) {
      return '${context.l10n.documentsRelativeYesterday} at ${DateFormat.jm(localeTag).format(local)}';
    }
    if (dayDelta == 0) {
      return DateFormat.jm(localeTag).format(local);
    }
    return DateFormat('MMM d, yyyy', localeTag).format(local);
  }
}

class _CompanySummaryCard extends StatelessWidget {
  const _CompanySummaryCard({required this.detail});

  final WorkCompanyDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final logoPath = (detail.companyLogoPath ?? '').trim();
    final role = detail.roleLabel.trim();
    final roleText = role.isEmpty ? context.l10n.workStatementsSubtitle : role;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4EAF4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: _companyLogo(context, path: logoPath, name: detail.companyName),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                roleText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 34 / 1.9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E56D9),
                ),
              ),
              SizedBox(height: 2),
              Text(
                '@ ${detail.companyName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 41 / 1.9,
                  fontWeight: FontWeight.w800,
                  color: context.appPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _companyLogo(BuildContext context, {required String path, required String name}) {
    if (path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: 240,
          cacheHeight: 240,
        );
      }
    }
    return Text(
      _initials(name),
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: context.appPalette.primary,
      ),
    );
  }
}

class _FolderRowCard extends StatelessWidget {
  const _FolderRowCard({
    required this.folder,
    required this.title,
    required this.filesCount,
    required this.onTap,
  });

  final WorkDocumentFolderType folder;
  final String title;
  final int filesCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _folderVisual(folder);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.appPalette.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: visual.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(visual.icon, size: 24, color: visual.iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.documentsCountLabel(filesCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: context.appPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDocumentTile extends StatelessWidget {
  const _RecentDocumentTile({
    required this.statement,
    required this.subtitle,
    required this.onTap,
  });

  final WorkStatementEntity statement;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final leadingIcon = switch (statement.folderType) {
      WorkDocumentFolderType.contracts => Icons.edit_note_rounded,
      WorkDocumentFolderType.payslips => Icons.download_rounded,
      _ => Icons.description_rounded,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appPalette.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.appPalette.surfaceSoft,
                  borderRadius: BorderRadius.circular(23),
                ),
                alignment: Alignment.center,
                child: Icon(leadingIcon, size: 20, color: Color(0xFF7A8CA8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17 / 1.15,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    if (statement.label.isNotEmpty) ...[
                      SizedBox(height: 1),
                      Text(
                        statement.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13 / 1.1,
                          fontWeight: FontWeight.w600,
                          color: context.appPalette.primary,
                        ),
                      ),
                    ],
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14 / 1.1,
                        fontWeight: FontWeight.w500,
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: context.appPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderVisual {
  const _FolderVisual({
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
}

const List<WorkDocumentFolderType> _visibleFolders = <WorkDocumentFolderType>[
  WorkDocumentFolderType.payslips,
  WorkDocumentFolderType.contracts,
  WorkDocumentFolderType.taxForms,
  WorkDocumentFolderType.offboarding,
  WorkDocumentFolderType.benefits,
  WorkDocumentFolderType.milestones,
  WorkDocumentFolderType.other,
];

_FolderVisual _folderVisual(WorkDocumentFolderType type) {
  return switch (type) {
    WorkDocumentFolderType.payslips => const _FolderVisual(
      icon: Icons.payments_rounded,
      background: Color(0xFFE8EEFF),
      iconColor: Color(0xFF2563EB),
    ),
    WorkDocumentFolderType.contracts => const _FolderVisual(
      icon: Icons.description_rounded,
      background: Color(0xFFE8EEFF),
      iconColor: Color(0xFF2563EB),
    ),
    WorkDocumentFolderType.taxForms => const _FolderVisual(
      icon: Icons.account_balance_rounded,
      background: Color(0xFFE8EEFF),
      iconColor: Color(0xFF2563EB),
    ),
    WorkDocumentFolderType.offboarding => const _FolderVisual(
      icon: Icons.logout_rounded,
      background: Color(0xFFFFE9EE),
      iconColor: Color(0xFFE53E5A),
    ),
    WorkDocumentFolderType.benefits => const _FolderVisual(
      icon: Icons.local_hospital_rounded,
      background: Color(0xFFE8EEFF),
      iconColor: Color(0xFF2563EB),
    ),
    WorkDocumentFolderType.milestones => const _FolderVisual(
      icon: Icons.workspace_premium_outlined,
      background: Color(0xFFE7F7F2),
      iconColor: Color(0xFF059669),
    ),
    WorkDocumentFolderType.other => const _FolderVisual(
      icon: Icons.folder_outlined,
      background: Color(0xFFF3F5F9),
      iconColor: Color(0xFF64748B),
    ),
  };
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'W';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
