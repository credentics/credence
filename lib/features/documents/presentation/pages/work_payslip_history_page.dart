import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_statement_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/archive_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/delete_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_vaults.dart';
import 'package:pass_doc_manager/features/documents/presentation/navigation/document_edit_navigator.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_payslip_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_file_preview_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/utils/document_local_asset_resolver.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/document_removal_prompt.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/work_documents_design.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class WorkPayslipHistoryPage extends StatefulWidget {
  const WorkPayslipHistoryPage._({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.companyRole,
    required this.companyLogoPath,
    required this.initialStatements,
    required this.isGlobalScope,
    GetWorkCompanyDetail? getWorkCompanyDetail,
    GetWorkCompanyVaults? getWorkCompanyVaults,
    GetDocumentDetail? getDocumentDetail,
    ArchiveDocument? archiveDocument,
    DeleteDocument? deleteDocument,
  }) : _getWorkCompanyDetail = getWorkCompanyDetail,
       _getWorkCompanyVaults = getWorkCompanyVaults,
       _getDocumentDetail = getDocumentDetail,
       _archiveDocument = archiveDocument,
       _deleteDocument = deleteDocument;

  factory WorkPayslipHistoryPage.company({
    Key? key,
    required String companyId,
    required String companyName,
    String? companyRole,
    String? companyLogoPath,
    List<WorkStatementEntity> initialStatements = const <WorkStatementEntity>[],
    GetWorkCompanyDetail? getWorkCompanyDetail,
    GetDocumentDetail? getDocumentDetail,
    ArchiveDocument? archiveDocument,
    DeleteDocument? deleteDocument,
  }) {
    return WorkPayslipHistoryPage._(
      key: key,
      companyId: companyId,
      companyName: companyName,
      companyRole: companyRole,
      companyLogoPath: companyLogoPath,
      initialStatements: initialStatements,
      isGlobalScope: false,
      getWorkCompanyDetail: getWorkCompanyDetail,
      getDocumentDetail: getDocumentDetail,
      archiveDocument: archiveDocument,
      deleteDocument: deleteDocument,
    );
  }

  factory WorkPayslipHistoryPage.global({
    Key? key,
    GetWorkCompanyDetail? getWorkCompanyDetail,
    GetWorkCompanyVaults? getWorkCompanyVaults,
    GetDocumentDetail? getDocumentDetail,
    ArchiveDocument? archiveDocument,
    DeleteDocument? deleteDocument,
  }) {
    return WorkPayslipHistoryPage._(
      key: key,
      companyId: '',
      companyName: '',
      companyRole: '',
      companyLogoPath: '',
      initialStatements: const <WorkStatementEntity>[],
      isGlobalScope: true,
      getWorkCompanyDetail: getWorkCompanyDetail,
      getWorkCompanyVaults: getWorkCompanyVaults,
      getDocumentDetail: getDocumentDetail,
      archiveDocument: archiveDocument,
      deleteDocument: deleteDocument,
    );
  }

  final String companyId;
  final String companyName;
  final String? companyRole;
  final String? companyLogoPath;
  final List<WorkStatementEntity> initialStatements;
  final bool isGlobalScope;
  final GetWorkCompanyDetail? _getWorkCompanyDetail;
  final GetWorkCompanyVaults? _getWorkCompanyVaults;
  final GetDocumentDetail? _getDocumentDetail;
  final ArchiveDocument? _archiveDocument;
  final DeleteDocument? _deleteDocument;

  @override
  State<WorkPayslipHistoryPage> createState() => _WorkPayslipHistoryPageState();
}

class _WorkPayslipHistoryPageState extends State<WorkPayslipHistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _didInitialLoad = false;
  String? _errorMessage;
  String _query = '';
  int? _selectedYear;
  List<_PayslipHistoryItem> _allItems = const <_PayslipHistoryItem>[];
  final Map<String, String> _fileSizesById = <String, String>{};
  final Map<String, String> _fileNamesById = <String, String>{};
  final Map<String, int> _pageCountsById = <String, int>{};
  final Map<String, int> _fileCountsById = <String, int>{};

  GetWorkCompanyDetail get _getWorkCompanyDetail =>
      widget._getWorkCompanyDetail ?? getIt();
  GetWorkCompanyVaults get _getWorkCompanyVaults =>
      widget._getWorkCompanyVaults ?? getIt();
  GetDocumentDetail get _getDocumentDetail =>
      widget._getDocumentDetail ?? getIt();
  ArchiveDocument get _archiveDocument => widget._archiveDocument ?? getIt();
  DeleteDocument get _deleteDocument => widget._deleteDocument ?? getIt();

  @override
  void initState() {
    super.initState();
    _searchController.text = _query;
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPalette.background,
      body: _buildBody(context),
    );
  }

  Future<void> _addPayslip() async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => WorkPayslipEntryPage(
          initialCompanyName: widget.companyName,
          initialCompanyLogoPath: widget.companyLogoPath,
        ),
      ),
    );
    if (!mounted) return;
    _load();
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 12));
    }
    if ((_errorMessage ?? '').trim().isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: _load, child: Text(context.l10n.commonRetry)),
          ],
        ),
      );
    }

    final visibleItems = _visibleItems;
    final years = _availableYears;

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
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
                children: [
                  _folderTopBar(context, showBack: !isDesktop),
                  const SizedBox(height: 12),
                  _folderHeader(context),
                  if (years.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _yearSelector(years),
                  ],
                  const SizedBox(height: 10),
                  _sortHeader(context, visibleCount: visibleItems.length),
                  const SizedBox(height: 8),
                  if (visibleItems.isEmpty)
                    _emptyState(context)
                  else
                    ...visibleItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _historyItemCard(context, item),
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

  Widget _folderTopBar(BuildContext context, {required bool showBack}) {
    return Row(
      children: [
        if (showBack)
          WorkCircleButton(
            size: 38,
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          )
        else
          const SizedBox(width: 38, height: 38),
        const Spacer(),
        WorkCircleButton(
          size: 38,
          icon: Icons.tune_rounded,
          onTap: _openSearchDialog,
        ),
        const SizedBox(width: 8),
        WorkCircleButton(size: 38, icon: Icons.add_rounded, onTap: _addPayslip),
      ],
    );
  }

  Widget _folderHeader(BuildContext context) {
    final kicker = widget.isGlobalScope
        ? 'Documents · Work'
        : '${widget.companyName} · Payslips';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: workFontMono,
            fontSize: 11,
            height: 1.15,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.4,
            color: context.appPalette.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          WorkDocumentFolderType.payslips.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: workFontDisplay,
            fontSize: 26,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.65,
            color: context.appPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _folderSubtitle(context),
          style: TextStyle(
            fontFamily: workFontBody,
            fontSize: 13.5,
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _sortHeader(BuildContext context, {required int visibleCount}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Sort · newest first'.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: workFontMono,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: context.appPalette.textMuted,
            ),
          ),
        ),
        Text(
          context.l10n.workPayslipHistoryItemsCount(visibleCount),
          style: TextStyle(
            fontFamily: workFontMono,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            color: context.appPalette.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _yearSelector(List<int> years) {
    final options = <int?>[null, ...years];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final year = options[index];
          final selected = year == _selectedYear;
          final count = year == null
              ? _allItems.length
              : _allItems
                    .where((item) => item.referenceDate.year == year)
                    .length;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _selectedYear = year),
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? context.appPalette.textPrimary
                      : context.appPalette.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? context.appPalette.textPrimary
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  year == null
                      ? '${context.l10n.workStatementsAllYears} · $count'
                      : '$year · $count',
                  style: TextStyle(
                    fontFamily: workFontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? context.appPalette.background
                        : context.appPalette.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _historyItemCard(BuildContext context, _PayslipHistoryItem item) {
    final dateText = _formatFolderDate(context, item.referenceDate);
    final fileSize = (_fileSizesById[item.documentId] ?? '').trim();
    final fileName = (_fileNamesById[item.documentId] ?? '').trim();
    final pageCount = _pageCountsById[item.documentId] ?? 1;
    final filesCount = _fileCountsById[item.documentId] ?? 1;
    return WorkFolderDocumentCard(
      title: item.title,
      path: fileName,
      metaParts: [
        dateText,
        if (filesCount > 1) context.l10n.documentFilesCount(filesCount),
        if (fileSize.isNotEmpty) fileSize,
        _pageCountLabel(pageCount),
        if (widget.isGlobalScope && item.companyName.trim().isNotEmpty)
          item.companyName.trim(),
      ],
      onTap: () => _openDocument(item),
      onLongPress: () => _openDocumentActions(item),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 30,
            color: context.appPalette.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            context.l10n.workPayslipHistoryNoDataTitle,
            style: TextStyle(
              fontFamily: workFontDisplay,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.l10n.workPayslipHistoryNoDataSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: workFontBody,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textSecondary,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }

  List<_PayslipHistoryItem> get _visibleItems {
    final query = _query.trim().toLowerCase();
    final selectedYear = _selectedYear;
    final filtered = _allItems.where((item) {
      if (selectedYear != null && item.referenceDate.year != selectedYear) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final haystack =
          '${item.title} ${item.companyName} ${item.netAmountLabel}'
              .toLowerCase();
      return haystack.contains(query);
    });
    return filtered.toList(growable: false);
  }

  List<int> get _availableYears {
    final years =
        _allItems
            .map((item) => item.referenceDate.year)
            .toSet()
            .toList(growable: false)
          ..sort((a, b) => b.compareTo(a));
    return years;
  }

  String get _yearRangeLabel {
    final years = _availableYears;
    if (years.isEmpty) {
      return '--';
    }
    final min = years.reduce((a, b) => a < b ? a : b);
    final max = years.reduce((a, b) => a > b ? a : b);
    return min == max ? '$max' : '$min → $max';
  }

  String _folderSubtitle(BuildContext context) {
    return '${context.l10n.documentFilesCount(_allItems.length)} · $_yearRangeLabel · sorted by date.';
  }

  String _formatFolderDate(BuildContext context, DateTime value) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('d MMM yy', locale).format(value).toUpperCase();
  }

  String _pageCountLabel(int pageCount) {
    final normalized = pageCount <= 0 ? 1 : pageCount;
    return normalized == 1 ? '1 PG' : '$normalized PGS';
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = widget.isGlobalScope
          ? await _loadGlobalPayslips()
          : await _loadCompanyPayslips();

      if (!mounted) {
        return;
      }
      setState(() {
        _allItems = items;
        _selectedYear = null;
        _fileSizesById.clear();
        _fileNamesById.clear();
        _pageCountsById.clear();
        _fileCountsById.clear();
        _isLoading = false;
      });

      unawaited(_loadFileMetadata(items));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.workCompanyLoadError;
      });
    }
  }

  Future<void> _loadFileMetadata(List<_PayslipHistoryItem> items) async {
    if (items.isEmpty) {
      return;
    }
    final details = await Future.wait(
      items.map((item) async {
        try {
          final detail = await _getDocumentDetail(
            GetDocumentDetailParams(documentId: item.documentId),
          );
          return _PayslipFileMetadata(
            documentId: item.documentId,
            fileName: detail.fileName.trim(),
            fileSizeLabel: detail.fileSizeLabel.trim(),
            pageCount: detail.scanPagesCount,
            filesCount: detail.referenceFilesCount,
          );
        } catch (_) {
          return null;
        }
      }),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      for (final detail in details) {
        if (detail == null) {
          continue;
        }
        if (detail.fileSizeLabel.isNotEmpty) {
          _fileSizesById[detail.documentId] = detail.fileSizeLabel;
        }
        if (detail.fileName.isNotEmpty) {
          _fileNamesById[detail.documentId] = detail.fileName;
        }
        _pageCountsById[detail.documentId] = detail.pageCount <= 0
            ? 1
            : detail.pageCount;
        _fileCountsById[detail.documentId] = detail.filesCount <= 0
            ? 1
            : detail.filesCount;
      }
    });
  }

  Future<List<_PayslipHistoryItem>> _loadCompanyPayslips() async {
    if (!_didInitialLoad && widget.initialStatements.isNotEmpty) {
      _didInitialLoad = true;
      return _mapPayslipItems(
        statements: widget.initialStatements,
        companyName: widget.companyName,
        companyRole: widget.companyRole ?? '',
        companyLogoPath: widget.companyLogoPath ?? '',
      );
    }
    _didInitialLoad = true;

    final detail = await _getWorkCompanyDetail(
      GetWorkCompanyDetailParams(companyId: widget.companyId),
    );
    return _mapPayslipItems(
      statements: detail.statements,
      companyName: detail.companyName,
      companyRole: detail.roleLabel,
      companyLogoPath: detail.companyLogoPath ?? '',
    );
  }

  Future<List<_PayslipHistoryItem>> _loadGlobalPayslips() async {
    final companies = await _getWorkCompanyVaults(
      const GetWorkCompanyVaultsParams(),
    );
    if (companies.isEmpty) {
      return const <_PayslipHistoryItem>[];
    }

    final details = await Future.wait(
      companies.map((company) async {
        try {
          return await _getWorkCompanyDetail(
            GetWorkCompanyDetailParams(companyId: company.companyId),
          );
        } catch (_) {
          return null;
        }
      }),
    );

    final items = <_PayslipHistoryItem>[];
    for (var i = 0; i < details.length; i++) {
      final detail = details[i];
      if (detail == null) {
        continue;
      }
      final company = companies[i];
      items.addAll(
        _mapPayslipItems(
          statements: detail.statements,
          companyName: detail.companyName,
          companyRole: detail.roleLabel.isNotEmpty
              ? detail.roleLabel
              : company.roleLabel,
          companyLogoPath:
              detail.companyLogoPath ?? company.companyLogoPath ?? '',
        ),
      );
    }

    return items;
  }

  List<_PayslipHistoryItem> _mapPayslipItems({
    required List<WorkStatementEntity> statements,
    required String companyName,
    required String companyRole,
    required String companyLogoPath,
  }) {
    final mapped =
        statements
            .where((item) => item.folderType == WorkDocumentFolderType.payslips)
            .map(
              (item) => _PayslipHistoryItem(
                documentId: item.documentId,
                title: item.title,
                referenceDate: item.statementDate ?? item.updatedAt,
                netAmountLabel: item.netAmountLabel,
                statusLabel: item.statusLabel,
                companyName: companyName,
                companyRole: companyRole,
                companyLogoPath: companyLogoPath,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.referenceDate.compareTo(a.referenceDate));
    return mapped;
  }

  Future<void> _openDocument(_PayslipHistoryItem item) async {
    try {
      final detail = await _getDocumentDetail(
        GetDocumentDetailParams(documentId: item.documentId),
      );
      final rawPath =
          await DocumentLocalAssetResolver.resolveFirstExistingSharePath(
            detail,
          );
      final normalizedPath = DocumentLocalAssetResolver.normalizeLocalPath(
        rawPath ?? '',
      );
      if (normalizedPath.trim().isEmpty || !File(normalizedPath).existsSync()) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.documentFileUnavailable)),
        );
        return;
      }

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DocumentFilePreviewPage(
            filePath: normalizedPath,
            title: detail.fileName.trim().isEmpty
                ? item.title
                : detail.fileName.trim(),
            fileName: detail.fileName.trim().isEmpty
                ? item.title
                : detail.fileName.trim(),
            mimeType: normalizedPath.inferMimeType(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.documentUnableOpenPreview)),
      );
    }
  }

  Future<void> _openDocumentActions(_PayslipHistoryItem item) async {
    final action = await showAdaptiveModal<_PayslipDocumentAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = context.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(l10n.commonEdit),
                onTap: () =>
                    Navigator.of(context).pop(_PayslipDocumentAction.edit),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(l10n.commonRemove),
                onTap: () =>
                    Navigator.of(context).pop(_PayslipDocumentAction.remove),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == null || !mounted) {
      return;
    }
    if (action == _PayslipDocumentAction.edit) {
      await _editDocument(item.documentId);
      return;
    }
    await _removeDocument(item.documentId);
  }

  Future<void> _editDocument(String documentId) async {
    try {
      final detail = await _getDocumentDetail(
        GetDocumentDetailParams(documentId: documentId),
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => DocumentEditNavigator.buildEditPage(detail: detail),
        ),
      );
      if (!mounted) {
        return;
      }
      await _load();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.documentUnableLoad)));
    }
  }

  Future<void> _removeDocument(String documentId) async {
    try {
      final detail = await _getDocumentDetail(
        GetDocumentDetailParams(documentId: documentId),
      );
      if (!mounted) {
        return;
      }
      final decision = await showDocumentRemovalPrompt(
        context: context,
        title: detail.issuer,
      );
      if (decision == null) {
        return;
      }

      if (decision == DocumentRemovalDecision.archive) {
        await _archiveDocument(ArchiveDocumentParams(documentId: documentId));
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.documentArchived)));
      } else {
        await _deleteDocument(DeleteDocumentParams(documentId: documentId));
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.documentDeleted)));
      }
      await _load();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.documentUnableRemove)),
      );
    }
  }

  Future<void> _openSearchDialog() async {
    final submitted = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.workPayslipHistorySearchButton),
          content: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.l10n.workPayslipHistorySearchHint,
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: Text(context.l10n.workPayslipHistorySearchClear),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_searchController.text.trim()),
              child: Text(context.l10n.workPayslipHistorySearchApply),
            ),
          ],
        );
      },
    );
    if (submitted == null) {
      return;
    }
    setState(() {
      _query = submitted.trim();
    });
  }
}

class _PayslipHistoryItem {
  const _PayslipHistoryItem({
    required this.documentId,
    required this.title,
    required this.referenceDate,
    required this.netAmountLabel,
    required this.statusLabel,
    required this.companyName,
    required this.companyRole,
    required this.companyLogoPath,
  });

  final String documentId;
  final String title;
  final DateTime referenceDate;
  final String netAmountLabel;
  final String statusLabel;
  final String companyName;
  final String companyRole;
  final String companyLogoPath;
}

class _PayslipFileMetadata {
  const _PayslipFileMetadata({
    required this.documentId,
    required this.fileName,
    required this.fileSizeLabel,
    required this.pageCount,
    required this.filesCount,
  });

  final String documentId;
  final String fileName;
  final String fileSizeLabel;
  final int pageCount;
  final int filesCount;
}

enum _PayslipDocumentAction { edit, remove }
