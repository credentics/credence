import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_document_manual_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/work_documents_design.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class WorkDocumentEntryPage extends StatefulWidget {
  const WorkDocumentEntryPage({
    super.key,
    this.initialCompanyName,
    this.initialCompanyLogoPath,
  });

  final String? initialCompanyName;
  final String? initialCompanyLogoPath;

  @override
  State<WorkDocumentEntryPage> createState() => _WorkDocumentEntryPageState();
}

class _WorkDocumentEntryPageState extends State<WorkDocumentEntryPage> {
  @override
  Widget build(BuildContext context) {
    final targetCompany = _resolvedCompanyName;
    return Scaffold(
      backgroundColor: context.appPalette.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final rows = _folderRows(context);
          return SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    WorkDesignTopBar(
                      showBack: !isDesktop,
                      onBackTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 18),
                    WorkIntroHeader(
                      kicker: context.l10n.workDocumentEntryTargetVault,
                      title: targetCompany,
                      subtitle: context.l10n.workManualEntrySharedTypeHint,
                      icon: targetCompany,
                      iconPath: widget.initialCompanyLogoPath,
                      iconTint: WorkTint.lavender,
                    ),
                    const SizedBox(height: 18),
                    WorkSectionLabel(
                      value: context.l10n.workDocumentEntryCategories,
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rows.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.34,
                          ),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return WorkFolderTile(
                          title: row.title,
                          count: row.subtitle,
                          icon: row.icon,
                          tint: row.tint,
                          onTap: () => _onFolderTap(row.folder),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<_FolderRowModel> _folderRows(BuildContext context) {
    return [
      _FolderRowModel(
        folder: WorkDocumentFolderType.payslips,
        icon: Icons.payments_outlined,
        tint: WorkTint.blue,
        title: _folderTitle(context, WorkDocumentFolderType.payslips),
        subtitle: _folderSubtitle(context, WorkDocumentFolderType.payslips),
      ),
      _FolderRowModel(
        folder: WorkDocumentFolderType.contracts,
        icon: Icons.assignment_rounded,
        tint: WorkTint.mint,
        title: _folderTitle(context, WorkDocumentFolderType.contracts),
        subtitle: _folderSubtitle(context, WorkDocumentFolderType.contracts),
      ),
      _FolderRowModel(
        folder: WorkDocumentFolderType.taxForms,
        icon: Icons.account_balance_rounded,
        tint: WorkTint.sand,
        title: _folderTitle(context, WorkDocumentFolderType.taxForms),
        subtitle: _folderSubtitle(context, WorkDocumentFolderType.taxForms),
      ),
      _FolderRowModel(
        folder: WorkDocumentFolderType.offboarding,
        icon: Icons.logout_rounded,
        tint: WorkTint.blush,
        title: _folderTitle(context, WorkDocumentFolderType.offboarding),
        subtitle: _folderSubtitle(context, WorkDocumentFolderType.offboarding),
      ),
      _FolderRowModel(
        folder: WorkDocumentFolderType.benefits,
        icon: Icons.health_and_safety_outlined,
        tint: WorkTint.peach,
        title: _folderTitle(context, WorkDocumentFolderType.benefits),
        subtitle: _folderSubtitle(context, WorkDocumentFolderType.benefits),
      ),
      _FolderRowModel(
        folder: WorkDocumentFolderType.milestones,
        icon: Icons.workspace_premium_outlined,
        tint: WorkTint.lavender,
        title: _folderTitle(context, WorkDocumentFolderType.milestones),
        subtitle: _folderSubtitle(context, WorkDocumentFolderType.milestones),
      ),
      _FolderRowModel(
        folder: WorkDocumentFolderType.other,
        icon: Icons.folder_open_rounded,
        tint: WorkTint.neutral,
        title: _folderTitle(context, WorkDocumentFolderType.other),
        subtitle: _folderSubtitle(context, WorkDocumentFolderType.other),
      ),
    ];
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

  String _folderSubtitle(BuildContext context, WorkDocumentFolderType folder) {
    final l10n = context.l10n;
    return switch (folder) {
      WorkDocumentFolderType.payslips => l10n.workCompanyFolderPayslipsSubtitle,
      WorkDocumentFolderType.contracts =>
        l10n.workCompanyFolderContractsSubtitle,
      WorkDocumentFolderType.taxForms => l10n.workCompanyFolderTaxFormsSubtitle,
      WorkDocumentFolderType.offboarding =>
        l10n.workCompanyFolderOffboardingSubtitle,
      WorkDocumentFolderType.benefits => l10n.workCompanyFolderBenefitsSubtitle,
      WorkDocumentFolderType.milestones =>
        l10n.workCompanyFolderMilestonesSubtitle,
      WorkDocumentFolderType.other => l10n.workCompanyFolderOtherSubtitle,
    };
  }

  String get _resolvedCompanyName {
    final value = (widget.initialCompanyName ?? '').trim();
    if (value.isNotEmpty) {
      return value;
    }
    return context.l10n.workPayslipSelectCompanyPlaceholder;
  }

  Future<void> _onFolderTap(WorkDocumentFolderType folder) async {
    final companyName = _resolvedCompanyName.trim();
    if (companyName.isEmpty ||
        companyName == context.l10n.workPayslipSelectCompanyPlaceholder) {
      _showToast(context.l10n.workEntrySelectCompanyFirst);
      return;
    }

    final createdId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => WorkDocumentManualEntryPage(
          initialCompanyName: companyName,
          initialFolderType: folder,
          initialCaptureSource: DocumentCaptureSource.gallery,
        ),
      ),
    );
    if (!mounted || (createdId ?? '').trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop(createdId);
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FolderRowModel {
  const _FolderRowModel({
    required this.folder,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });

  final WorkDocumentFolderType folder;
  final String title;
  final String subtitle;
  final IconData icon;
  final WorkTint tint;
}
