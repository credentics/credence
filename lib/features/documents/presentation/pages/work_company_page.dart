import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_recent_activity_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/work_company_detail_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/work_company_detail_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_file_preview_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_company_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_document_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_folder_documents_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/utils/document_local_asset_resolver.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/work_documents_design.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class WorkCompanyPage extends StatelessWidget {
  const WorkCompanyPage({
    super.key,
    required this.companyId,
    GetWorkCompanyDetail? getWorkCompanyDetail,
  }) : _getWorkCompanyDetail = getWorkCompanyDetail;

  final String companyId;
  final GetWorkCompanyDetail? _getWorkCompanyDetail;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WorkCompanyDetailCubit(getWorkCompanyDetail: _getWorkCompanyDetail)
            ..load(companyId: companyId),
      child: _WorkCompanyView(companyId: companyId),
    );
  }
}

class _WorkCompanyView extends StatelessWidget {
  const _WorkCompanyView({required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkCompanyDetailCubit, WorkCompanyDetailState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.appPalette.background,
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WorkCompanyDetailState state) {
    final detail = state.detail;
    if ((state.viewStatus == WorkCompanyDetailViewStatus.initial ||
            state.viewStatus == WorkCompanyDetailViewStatus.loading) &&
        detail == null) {
      return const Center(child: CupertinoActivityIndicator(radius: 12));
    }
    if (state.viewStatus == WorkCompanyDetailViewStatus.error &&
        detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage ?? context.l10n.workCompanyLoadError,
              style: TextStyle(
                fontFamily: workFontBody,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<WorkCompanyDetailCubit>().load(
                companyId: companyId,
              ),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    if (detail == null) {
      return const SizedBox.shrink();
    }

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final startedAtText = detail.startedAt == null
        ? '--'
        : DateFormat.yMMMd(localeTag).format(detail.startedAt!);
    final lastAccessText = detail.lastAccessAt == null
        ? context.l10n.workHubNoAccessYet
        : _relativeLabel(context, detail.lastAccessAt!);

    final validActivity = detail.recentActivity
        .where(_isValidActivity)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                children: [
                  WorkDesignTopBar(
                    showBack: !isDesktop,
                    onBackTap: () => Navigator.of(context).maybePop(),
                    onMoreTap: () => _openEditCompany(context, detail),
                    onAddTap: () => _openAddRecord(context, detail),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.appPalette.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: context.appPalette.stroke),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WorkCompanyLogo(
                          name: detail.companyName,
                          logoPath: detail.companyLogoPath,
                          size: 54,
                          tint: WorkTint.lavender,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: WorkIntroHeader(
                            kicker:
                                '${context.l10n.workCompanyVaultTitle} · ${context.l10n.documentFilesCount(detail.documentsCount)}',
                            title: detail.companyName,
                            subtitle: [
                              if (detail.roleLabel.trim().isNotEmpty)
                                detail.roleLabel.trim(),
                              if (detail.addressLabel.trim().isNotEmpty)
                                detail.addressLabel.trim(),
                              if (startedAtText != '--') startedAtText,
                            ].join(' · '),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  WorkSectionLabel(
                    value:
                        '${context.l10n.workCompanyFoldersTitle} · ${detail.folderSummaries.length}',
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detail.folderSummaries.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.92,
                        ),
                    itemBuilder: (context, index) {
                      final item = detail.folderSummaries[index];
                      return WorkFolderTile(
                        title: _folderTitle(context, item.folderType),
                        count: context.l10n.documentFilesCount(
                          item.documentsCount,
                        ),
                        icon: _folderVisual(item.folderType).icon,
                        tint: _folderTint(item.folderType),
                        onTap: () => _openStatements(
                          context,
                          detail,
                          initialFolder: item.folderType,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  WorkSectionLabel(
                    value:
                        '${context.l10n.documentsRecentActivityTitle} · ${validActivity.length}',
                  ),
                  const SizedBox(height: 8),
                  if (validActivity.isEmpty)
                    _emptyActivityCard(context)
                  else
                    ...validActivity
                        .take(8)
                        .map(
                          (activity) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: WorkFileCard(
                              title: activity.title,
                              meta: [
                                if (activity.filesCount > 1)
                                  context.l10n.documentFilesCount(
                                    activity.filesCount,
                                  ),
                                _recentActivitySubtitle(
                                  context,
                                  activity.updatedAt,
                                ),
                                if (lastAccessText !=
                                    context.l10n.workHubNoAccessYet)
                                  lastAccessText,
                              ].join(' · '),
                              onTap: () => _openDocumentDetail(
                                context,
                                activity.documentId,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyActivityCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Text(
        context.l10n.documentsNoRecentActivity,
        style: TextStyle(
          fontFamily: workFontBody,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.appPalette.textSecondary,
        ),
      ),
    );
  }

  Future<void> _openDocumentDetail(
    BuildContext context,
    String documentId,
  ) async {
    try {
      final getDocumentDetail = getIt<GetDocumentDetail>();
      final detail = await getDocumentDetail(
        GetDocumentDetailParams(documentId: documentId),
      );
      final rawPath =
          await DocumentLocalAssetResolver.resolveFirstExistingSharePath(
            detail,
          );
      final normalizedPath = DocumentLocalAssetResolver.normalizeLocalPath(
        rawPath ?? '',
      );
      if (normalizedPath.trim().isEmpty || !File(normalizedPath).existsSync()) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.documentFileUnavailable)),
        );
        return;
      }

      if (!context.mounted) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DocumentFilePreviewPage(
            filePath: normalizedPath,
            title: detail.fileName.trim().isEmpty
                ? normalizedPath.split('/').last
                : detail.fileName.trim(),
            fileName: detail.fileName.trim().isEmpty
                ? normalizedPath.split('/').last
                : detail.fileName.trim(),
            mimeType: normalizedPath.inferMimeType(),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.documentUnableOpenPreview)),
      );
    }

    if (!context.mounted) {
      return;
    }
    final detail = context.read<WorkCompanyDetailCubit>().state.detail;
    if (detail == null) {
      return;
    }
    await context.read<WorkCompanyDetailCubit>().load(
      companyId: detail.companyId,
    );
  }

  Future<void> _openStatements(
    BuildContext context,
    WorkCompanyDetailEntity detail, {
    WorkDocumentFolderType? initialFolder,
  }) async {
    final folder = initialFolder ?? WorkDocumentFolderType.other;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkFolderDocumentsPage(
          companyId: detail.companyId,
          companyName: detail.companyName,
          folderType: folder,
          screenTitle: _folderTitle(context, folder),
          initialStatements: detail.statements,
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<WorkCompanyDetailCubit>().load(
      companyId: detail.companyId,
    );
  }

  Future<void> _openEditCompany(
    BuildContext context,
    WorkCompanyDetailEntity detail,
  ) async {
    final docId = detail.profileDocumentId;
    if (docId == null || docId.trim().isEmpty) return;

    await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            WorkCompanyEntryPage(editDocumentId: docId, initialDetail: detail),
      ),
    );
    if (!context.mounted) return;
    await context.read<WorkCompanyDetailCubit>().load(
      companyId: detail.companyId,
    );
  }

  Future<void> _openAddRecord(
    BuildContext context,
    WorkCompanyDetailEntity detail,
  ) async {
    final createdId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => WorkDocumentEntryPage(
          initialCompanyName: detail.companyName,
          initialCompanyLogoPath: detail.companyLogoPath,
        ),
      ),
    );
    if (!context.mounted || (createdId ?? '').trim().isEmpty) {
      return;
    }
    await context.read<WorkCompanyDetailCubit>().load(
      companyId: detail.companyId,
    );
  }

  /// Filters out activities with auto-generated or empty titles.
  bool _isValidActivity(WorkCompanyRecentActivityEntity a) {
    final t = a.title.trim();
    if (t.isEmpty) return false;
    // Auto-generated titles look like "Document_1774387976457"
    if (RegExp(r'^Document_\d+$').hasMatch(t)) return false;
    return true;
  }

  String _recentActivitySubtitle(BuildContext context, DateTime updatedAt) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final local = updatedAt.toLocal();
    final date = DateFormat.yMMMd(localeTag).format(local);
    final time = DateFormat.jm(localeTag).format(local);
    return '$date • $time';
  }
}

class _FolderVisual {
  const _FolderVisual({required this.icon});

  final IconData icon;
}

_FolderVisual _folderVisual(WorkDocumentFolderType type) {
  return switch (type) {
    WorkDocumentFolderType.payslips => const _FolderVisual(
      icon: Icons.badge_outlined,
    ),
    WorkDocumentFolderType.contracts => const _FolderVisual(
      icon: Icons.description_outlined,
    ),
    WorkDocumentFolderType.taxForms => const _FolderVisual(
      icon: Icons.account_balance_wallet_outlined,
    ),
    WorkDocumentFolderType.offboarding => const _FolderVisual(
      icon: Icons.logout_rounded,
    ),
    WorkDocumentFolderType.benefits => const _FolderVisual(
      icon: Icons.medical_services_outlined,
    ),
    WorkDocumentFolderType.milestones => const _FolderVisual(
      icon: Icons.workspace_premium_outlined,
    ),
    WorkDocumentFolderType.other => const _FolderVisual(
      icon: Icons.folder_outlined,
    ),
  };
}

String _folderTitle(BuildContext context, WorkDocumentFolderType type) {
  final l10n = context.l10n;
  return switch (type) {
    WorkDocumentFolderType.payslips => l10n.workCompanyFolderPayslipsTitle,
    WorkDocumentFolderType.contracts => l10n.workCompanyFolderContractsTitle,
    WorkDocumentFolderType.taxForms => l10n.workCompanyFolderTaxFormsTitle,
    WorkDocumentFolderType.offboarding =>
      l10n.workCompanyFolderOffboardingTitle,
    WorkDocumentFolderType.benefits => l10n.workCompanyFolderBenefitsTitle,
    WorkDocumentFolderType.milestones => l10n.workCompanyFolderMilestonesTitle,
    WorkDocumentFolderType.other => l10n.workCompanyFolderOtherTitle,
  };
}

WorkTint _folderTint(WorkDocumentFolderType type) {
  return switch (type) {
    WorkDocumentFolderType.payslips => WorkTint.blue,
    WorkDocumentFolderType.contracts => WorkTint.peach,
    WorkDocumentFolderType.taxForms => WorkTint.sand,
    WorkDocumentFolderType.offboarding => WorkTint.blush,
    WorkDocumentFolderType.benefits => WorkTint.mint,
    WorkDocumentFolderType.milestones => WorkTint.lavender,
    WorkDocumentFolderType.other => WorkTint.neutral,
  };
}

String _relativeLabel(BuildContext context, DateTime value) {
  final now = DateTime.now();
  final localValue = value.isUtc ? value.toLocal() : value;
  final delta = now.difference(localValue);
  if (delta.isNegative || delta.inMinutes < 1) {
    return context.l10n.documentsRelativeJustNow;
  }
  if (delta.inMinutes < 60) {
    return context.l10n.homeRelativeMinutesAgo(delta.inMinutes);
  }
  if (delta.inHours < 24) {
    return context.l10n.homeRelativeHoursAgo(delta.inHours);
  }
  if (delta.inDays == 1) {
    return context.l10n.documentsRelativeYesterday;
  }
  if (delta.inDays < 7) {
    return context.l10n.homeRelativeDaysAgo(delta.inDays);
  }
  if (delta.inDays < 30) {
    final weeks = (delta.inDays / 7).floor().clamp(1, 4);
    return context.l10n.homeRelativeWeeksAgo(weeks);
  }
  if (delta.inDays < 365) {
    final months = (delta.inDays / 30).floor().clamp(1, 12);
    return context.l10n.homeRelativeMonthsAgo(months);
  }
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(localeTag).format(localValue);
}
