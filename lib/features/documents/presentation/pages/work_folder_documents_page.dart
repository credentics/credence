import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_statement_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/delete_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_document_manual_entry_page.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/work_documents_design.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class WorkFolderDocumentsPage extends StatefulWidget {
  const WorkFolderDocumentsPage({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.folderType,
    required this.screenTitle,
    this.initialStatements = const <WorkStatementEntity>[],
    GetWorkCompanyDetail? getWorkCompanyDetail,
    GetDocumentDetail? getDocumentDetail,
    DeleteDocument? deleteDocument,
  }) : _getWorkCompanyDetail = getWorkCompanyDetail,
       _getDocumentDetail = getDocumentDetail,
       _deleteDocument = deleteDocument;

  final String companyId;
  final String companyName;
  final WorkDocumentFolderType folderType;
  final String screenTitle;
  final List<WorkStatementEntity> initialStatements;
  final GetWorkCompanyDetail? _getWorkCompanyDetail;
  final GetDocumentDetail? _getDocumentDetail;
  final DeleteDocument? _deleteDocument;

  @override
  State<WorkFolderDocumentsPage> createState() =>
      _WorkFolderDocumentsPageState();
}

enum _FolderSortMode { newestFirst, oldestFirst, title }

class _WorkFolderDocumentsPageState extends State<WorkFolderDocumentsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _didInitialLoad = false;
  String? _errorMessage;
  String _query = '';
  int? _selectedYear;
  _FolderSortMode _sortMode = _FolderSortMode.newestFirst;
  List<WorkStatementEntity> _allItems = const <WorkStatementEntity>[];
  final Map<String, String> _fileSizesById = <String, String>{};
  final Map<String, String> _fileNamesById = <String, String>{};
  final Map<String, int> _pageCountsById = <String, int>{};
  final Map<String, int> _fileCountsById = <String, int>{};

  GetWorkCompanyDetail get _getWorkCompanyDetail =>
      widget._getWorkCompanyDetail ?? getIt();
  GetDocumentDetail get _getDocumentDetail =>
      widget._getDocumentDetail ?? getIt();
  DeleteDocument get _deleteDocument => widget._deleteDocument ?? getIt();

  @override
  void initState() {
    super.initState();
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

  Future<void> _addDocument() async {
    final entryPage = WorkDocumentManualEntryPage(
      initialCompanyName: widget.companyName,
      initialFolderType: widget.folderType,
    );
    await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => entryPage));
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
                fontFamily: workFontBody,
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
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: years.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final year = index == 0 ? null : years[index - 1];
                          final active = year == _selectedYear;
                          final count = year == null
                              ? _allItems.length
                              : _allItems.where((item) {
                                  final date =
                                      item.statementDate ?? item.updatedAt;
                                  return date.year == year;
                                }).length;
                          return _yearChip(
                            context,
                            label: year == null
                                ? '${context.l10n.workStatementsAllYears} · $count'
                                : '$year · $count',
                            active: active,
                            onTap: () {
                              setState(() {
                                _selectedYear = year;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _sortHeader(context),
                  const SizedBox(height: 8),
                  if (visibleItems.isEmpty)
                    _emptyState(context)
                  else
                    ...visibleItems.map(
                      (item) => Dismissible(
                        key: ValueKey<String>(
                          'work-folder-doc-${item.documentId}',
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDeleteBySwipe(item),
                        background: _swipeDeleteBackground(context),
                        onDismissed: (_) => _onDocumentDismissed(item),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _documentCard(context, item),
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
        WorkCircleButton(
          size: 38,
          icon: Icons.add_rounded,
          onTap: _addDocument,
        ),
      ],
    );
  }

  Widget _folderHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.companyName} · ${widget.screenTitle}'.toUpperCase(),
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
          widget.screenTitle,
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

  Widget _sortHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${context.l10n.workFolderHistorySort} · ${_sortLabel(context)}'
                .toUpperCase(),
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
        TextButton.icon(
          onPressed: _openSortSheet,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            minimumSize: const Size(0, 30),
            foregroundColor: context.appPalette.textMuted,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(
            Icons.tune_rounded,
            size: 12,
            color: context.appPalette.textMuted,
          ),
          label: Text(
            'Change',
            style: TextStyle(
              fontFamily: workFontMono,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
              color: context.appPalette.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _documentCard(BuildContext context, WorkStatementEntity item) {
    final date = item.statementDate ?? item.updatedAt;
    final dateText = _formatFolderDate(context, date);
    final fileSize = (_fileSizesById[item.documentId] ?? '').trim();
    final fileName = (_fileNamesById[item.documentId] ?? '').trim();
    final pageCount = _pageCountsById[item.documentId] ?? 1;
    final filesCount = _fileCountsById[item.documentId] ?? item.filesCount;
    return WorkFolderDocumentCard(
      title: item.title,
      path: fileName,
      metaParts: [
        dateText,
        if (filesCount > 1) context.l10n.documentFilesCount(filesCount),
        if (fileSize.isNotEmpty) fileSize,
        _pageCountLabel(pageCount),
      ],
      onTap: () => _openDocument(item.documentId),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 32,
            color: context.appPalette.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            context.l10n.workFolderHistoryNoDocumentsTitle,
            style: TextStyle(
              fontFamily: workFontDisplay,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.l10n.workFolderHistoryNoDocumentsSubtitle,
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

  Widget _swipeDeleteBackground(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(26),
      ),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.commonRemove,
            style: const TextStyle(
              fontFamily: workFontBody,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<WorkStatementEntity> get _visibleItems {
    final query = _query.trim().toLowerCase();
    final filtered = _allItems
        .where((item) {
          if (_selectedYear != null) {
            final date = item.statementDate ?? item.updatedAt;
            if (date.year != _selectedYear) {
              return false;
            }
          }
          if (query.isEmpty) {
            return true;
          }
          return item.title.toLowerCase().contains(query) ||
              item.label.toLowerCase().contains(query) ||
              item.folderType.label.toLowerCase().contains(query);
        })
        .toList(growable: false);
    filtered.sort((a, b) {
      return switch (_sortMode) {
        _FolderSortMode.newestFirst =>
          (b.statementDate ?? b.updatedAt).compareTo(
            a.statementDate ?? a.updatedAt,
          ),
        _FolderSortMode.oldestFirst =>
          (a.statementDate ?? a.updatedAt).compareTo(
            b.statementDate ?? b.updatedAt,
          ),
        _FolderSortMode.title => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
      };
    });
    return filtered;
  }

  List<int> get _availableYears {
    final years = <int>{};
    for (final item in _allItems) {
      final date = item.statementDate ?? item.updatedAt;
      years.add(date.year);
    }
    return years.toList(growable: false)..sort((a, b) => b.compareTo(a));
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

  String _sortLabel(BuildContext context) {
    return switch (_sortMode) {
      _FolderSortMode.newestFirst =>
        '${context.l10n.workFolderHistorySortNewest} first',
      _FolderSortMode.oldestFirst =>
        '${context.l10n.workFolderHistorySortOldest} first',
      _FolderSortMode.title => context.l10n.workFolderHistorySortTitle,
    };
  }

  String _folderSubtitle(BuildContext context) {
    final count = context.l10n.documentFilesCount(_allItems.length);
    final sortMode = switch (_sortMode) {
      _FolderSortMode.title => 'title',
      _ => 'date',
    };
    return '$count · $_yearRangeLabel · sorted by $sortMode.';
  }

  String _formatFolderDate(BuildContext context, DateTime value) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('d MMM yy', locale).format(value).toUpperCase();
  }

  String _pageCountLabel(int pageCount) {
    final normalized = pageCount <= 0 ? 1 : pageCount;
    return normalized == 1 ? '1 PG' : '$normalized PGS';
  }

  Widget _yearChip(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: active ? palette.textPrimary : palette.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? palette.textPrimary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: workFontBody,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
              color: active ? palette.background : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statements =
          (!_didInitialLoad && widget.initialStatements.isNotEmpty)
          ? widget.initialStatements
          : await _loadFromCompany();
      _didInitialLoad = true;

      final filtered = statements
          .where((item) => item.folderType == widget.folderType)
          .toList(growable: false);
      filtered.sort(
        (a, b) => (b.statementDate ?? b.updatedAt).compareTo(
          a.statementDate ?? a.updatedAt,
        ),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _allItems = filtered;
        _fileSizesById.clear();
        _fileNamesById.clear();
        _pageCountsById.clear();
        _fileCountsById.clear();
        _isLoading = false;
      });

      unawaited(_loadFileMetadata(filtered));
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

  Future<List<WorkStatementEntity>> _loadFromCompany() async {
    final detail = await _getWorkCompanyDetail(
      GetWorkCompanyDetailParams(companyId: widget.companyId),
    );
    return detail.statements;
  }

  Future<void> _loadFileMetadata(List<WorkStatementEntity> items) async {
    if (items.isEmpty) {
      return;
    }
    final details = await Future.wait(
      items.map((item) async {
        try {
          final detail = await _getDocumentDetail(
            GetDocumentDetailParams(documentId: item.documentId),
          );
          return _WorkFolderFileMetadata(
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

  Future<void> _openDocument(String documentId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(documentId: documentId),
      ),
    );
    if (!mounted) return;
    _load();
  }

  Future<bool> _confirmDeleteBySwipe(WorkStatementEntity item) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.documentRemoveTitle(item.title)),
          content: Text(l10n.documentRemoveDeleteSubtitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: context.appPalette.danger,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.commonRemove),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return false;
    }
    try {
      await _deleteDocument(DeleteDocumentParams(documentId: item.documentId));
      return true;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.documentUnableRemove)),
      );
      return false;
    }
  }

  void _onDocumentDismissed(WorkStatementEntity item) {
    if (!mounted) {
      return;
    }
    setState(() {
      _allItems = _allItems
          .where((entry) => entry.documentId != item.documentId)
          .toList(growable: false);
      _fileSizesById.remove(item.documentId);
      _fileNamesById.remove(item.documentId);
      _pageCountsById.remove(item.documentId);
      _fileCountsById.remove(item.documentId);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.documentDeleted)));
  }

  Future<void> _openSearchDialog() async {
    _searchController.text = _query;
    final submitted = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.workFolderHistorySearchTitle),
          content: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.l10n.workFolderHistorySearchHint,
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

  Future<void> _openSortSheet() async {
    final selected = await showAdaptiveModal<_FolderSortMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _sortMode == _FolderSortMode.newestFirst
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                title: Text(context.l10n.workFolderHistorySortNewest),
                onTap: () =>
                    Navigator.of(context).pop(_FolderSortMode.newestFirst),
              ),
              ListTile(
                leading: Icon(
                  _sortMode == _FolderSortMode.oldestFirst
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                title: Text(context.l10n.workFolderHistorySortOldest),
                onTap: () =>
                    Navigator.of(context).pop(_FolderSortMode.oldestFirst),
              ),
              ListTile(
                leading: Icon(
                  _sortMode == _FolderSortMode.title
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                title: Text(context.l10n.workFolderHistorySortTitle),
                onTap: () => Navigator.of(context).pop(_FolderSortMode.title),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _sortMode = selected;
    });
  }
}

class _WorkFolderFileMetadata {
  const _WorkFolderFileMetadata({
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
