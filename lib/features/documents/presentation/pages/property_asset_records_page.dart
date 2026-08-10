import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/desktop_context_menu.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/presentation/widgets/desktop_list_item_wrapper.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_record_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/delete_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_property_asset_records.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_file_preview_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/property_document_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/utils/document_local_asset_resolver.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

class PropertyAssetRecordsPage extends StatefulWidget {
  const PropertyAssetRecordsPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
    required this.assetType,
    GetPropertyAssetRecords? getPropertyAssetRecords,
    GetDocumentDetail? getDocumentDetail,
    DeleteDocument? deleteDocument,
  }) : _getPropertyAssetRecords = getPropertyAssetRecords,
       _getDocumentDetail = getDocumentDetail,
       _deleteDocument = deleteDocument;

  final String propertyId;
  final String propertyName;
  final PropertyAssetType assetType;
  final GetPropertyAssetRecords? _getPropertyAssetRecords;
  final GetDocumentDetail? _getDocumentDetail;
  final DeleteDocument? _deleteDocument;

  @override
  State<PropertyAssetRecordsPage> createState() =>
      _PropertyAssetRecordsPageState();
}

enum _PropertyRecordSortMode { newestFirst, oldestFirst, title }

class _PropertyAssetRecordsPageState extends State<PropertyAssetRecordsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String _sharingDocumentId = '';
  _PropertyRecordSortMode _sortMode = _PropertyRecordSortMode.newestFirst;

  List<PropertyAssetRecordEntity> _records =
      const <PropertyAssetRecordEntity>[];

  GetPropertyAssetRecords get _getRecordsUseCase =>
      widget._getPropertyAssetRecords ?? getIt();
  GetDocumentDetail get _getDocumentDetail =>
      widget._getDocumentDetail ?? getIt();
  DeleteDocument get _deleteDocument => widget._deleteDocument ?? getIt();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.surface,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: _screenTitle(context),
        titleStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
        actionIcon: Icons.add_rounded,
        onActionPressed: _openAddDocument,
      ),
      body: _buildBody(context),
    );
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

    final documents = _sortedRecords(_records);
    final rentPayments = widget.assetType == PropertyAssetType.payments
        ? documents
              .where((record) => record.hasPaymentDetails)
              .toList(growable: false)
        : const <PropertyAssetRecordEntity>[];

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [
              if (widget.assetType == PropertyAssetType.payments) ...[
                _sectionHeader(
                  context,
                  title: context.l10n.propertyDetailAssetPayments,
                  count: rentPayments.length,
                ),
                const SizedBox(height: 8),
                if (rentPayments.isEmpty)
                  _emptyState(context)
                else
                  ...rentPayments.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _paymentCard(context, record),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.workFolderHistoryAllDocuments(
                        documents.length,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: context.appPalette.textMuted,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openSortSheet,
                    icon: Icon(Icons.sort_rounded, size: 17),
                    label: Text(
                      context.l10n.workFolderHistorySort,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: context.appPalette.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (documents.isEmpty)
                _emptyState(context)
              else
                ...documents.map(
                  (record) => Dismissible(
                    key: ValueKey<String>(
                      'property-${widget.assetType.name}-${record.documentId}',
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDeleteBySwipe(record),
                    background: _swipeDeleteBackground(context),
                    onDismissed: (_) => _onDocumentDismissed(record),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _documentCard(context, record),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required int count,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.appPalette.textPrimary,
            ),
          ),
        ),
        Text(
          widget.assetType == PropertyAssetType.payments
              ? context.l10n.propertyDetailRecordsCount(count)
              : context.l10n.propertyDetailFilesCount(count),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: context.appPalette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _paymentCard(BuildContext context, PropertyAssetRecordEntity record) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = record.paymentDate ?? record.issueDate ?? record.updatedAt;
    final dateLabel = DateFormat.yMMMd(locale).format(date);
    final amount = record.paymentAmountLabel.trim().isEmpty
        ? '--'
        : record.paymentAmountLabel.trim();
    return DesktopListItemWrapper(
      borderRadius: 22,
      onDoubleTap: () => _editDocument(record.documentId),
      contextActions: _desktopActions(record),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: context.appPalette.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.payments_rounded,
                size: 24,
                color: Color(0xFF169A66),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '$amount • $dateLabel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _editDocument(record.documentId),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.edit_rounded,
                size: 22,
                color: context.appPalette.textMuted,
              ),
              tooltip: context.l10n.commonEdit,
            ),
            IconButton(
              onPressed: () => _openDocument(record.documentId),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.remove_red_eye_rounded,
                size: 24,
                color: context.appPalette.textMuted,
              ),
              tooltip: context.l10n.documentPreview,
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentCard(BuildContext context, PropertyAssetRecordEntity item) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = item.issueDate ?? item.updatedAt;
    final dateText = DateFormat.yMMMd(locale).format(date);
    return DesktopListItemWrapper(
      borderRadius: 26,
      onDoubleTap: () => _editDocument(item.documentId),
      contextActions: _desktopActions(item),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18 / 1.1,
                          fontWeight: FontWeight.w700,
                          color: context.appPalette.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        context.l10n.workFolderHistoryAdded(
                          dateText,
                          item.fileSizeLabel,
                        ),
                        style: TextStyle(
                          fontSize: 15 / 1.15,
                          fontWeight: FontWeight.w500,
                          color: context.appPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.appPalette.surfaceSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _documentIcon(item.fileName),
                    color: context.appPalette.primary,
                    size: 27,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openDocument(item.documentId),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.appPalette.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 19),
                    label: Text(
                      context.l10n.documentPreview,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _circleActionButton(
                  icon: Icons.edit_rounded,
                  onTap: () => _editDocument(item.documentId),
                  iconSize: 20,
                  tooltip: context.l10n.commonEdit,
                ),
                const SizedBox(width: 8),
                _circleActionButton(
                  icon: _sharingDocumentId == item.documentId
                      ? Icons.hourglass_top_rounded
                      : Icons.download_rounded,
                  onTap: _sharingDocumentId == item.documentId
                      ? null
                      : () => _shareDocument(item.documentId),
                  iconSize: 21,
                ),
              ],
            ),
          ],
        ),
      ),
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
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<PropertyAssetRecordEntity> _sortedRecords(
    List<PropertyAssetRecordEntity> source,
  ) {
    final sorted = [...source];
    sorted.sort((a, b) {
      final aDate = _sortDateFor(a);
      final bDate = _sortDateFor(b);
      return switch (_sortMode) {
        _PropertyRecordSortMode.newestFirst => bDate.compareTo(aDate),
        _PropertyRecordSortMode.oldestFirst => aDate.compareTo(bDate),
        _PropertyRecordSortMode.title => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
      };
    });
    return sorted;
  }

  DateTime _sortDateFor(PropertyAssetRecordEntity record) {
    return record.paymentDate ?? record.issueDate ?? record.updatedAt;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _getRecordsUseCase(
        GetPropertyAssetRecordsParams(
          propertyId: widget.propertyId,
          assetType: widget.assetType,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _records = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = context.l10n.propertyDetailLoadError;
      });
    }
  }

  Future<void> _openDocument(String documentId) async {
    try {
      final detail = await _getDocumentDetail(
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
                ? _screenTitle(context)
                : detail.fileName.trim(),
            fileName: detail.fileName.trim().isEmpty
                ? normalizedPath.split('/').last
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

  Future<void> _editDocument(String documentId) async {
    try {
      final detail = await _getDocumentDetail(
        GetDocumentDetailParams(documentId: documentId),
      );
      if (!mounted) {
        return;
      }
      final resultId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => PropertyDocumentEntryPage(
            propertyId: widget.propertyId,
            propertyName: widget.propertyName,
            initialAssetType: widget.assetType,
            documentToEdit: detail,
          ),
        ),
      );
      if (!mounted || (resultId ?? '').trim().isEmpty) {
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

  Future<void> _shareDocument(String documentId) async {
    setState(() {
      _sharingDocumentId = documentId;
    });
    try {
      final detail = await _getDocumentDetail(
        GetDocumentDetailParams(documentId: documentId),
      );
      final path =
          await DocumentLocalAssetResolver.resolveFirstExistingSharePath(
            detail,
          );
      if (path == null || path.trim().isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.documentUnableShareFile)),
        );
        return;
      }

      final normalized = DocumentLocalAssetResolver.normalizeLocalPath(path);
      final file = File(normalized);
      if (!file.existsSync()) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.documentFileUnavailable)),
        );
        return;
      }

      final xFile = XFile(
        normalized,
        name: detail.fileName.trim().isEmpty
            ? normalized.split('/').last
            : detail.fileName.trim(),
        mimeType: normalized.inferMimeType(),
      );
      if (!mounted) {
        return;
      }
      final renderBox = context.findRenderObject() as RenderBox?;
      final shareOrigin = renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size;
      await Share.shareXFiles(
        <XFile>[xFile],
        subject: detail.fileName,
        sharePositionOrigin: shareOrigin,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.documentUnableShareFile)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sharingDocumentId = '';
        });
      }
    }
  }

  Future<bool> _confirmDeleteBySwipe(PropertyAssetRecordEntity item) async {
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
        SnackBar(content: Text(context.l10n.documentsUnableRemove)),
      );
      return false;
    }
  }

  void _onDocumentDismissed(PropertyAssetRecordEntity item) {
    setState(() {
      _records = _records
          .where((element) => element.documentId != item.documentId)
          .toList(growable: false);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.documentsDeleted)));
  }

  Future<void> _openAddDocument() async {
    final resultId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PropertyDocumentEntryPage(
          propertyId: widget.propertyId,
          propertyName: widget.propertyName,
          initialAssetType: widget.assetType,
        ),
      ),
    );
    if (!mounted || (resultId ?? '').trim().isEmpty) {
      return;
    }
    await _load();
  }

  Future<void> _openSortSheet() async {
    final selected = await showAdaptiveModal<_PropertyRecordSortMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            decoration: BoxDecoration(
              color: context.appPalette.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sortTile(
                  context,
                  mode: _PropertyRecordSortMode.newestFirst,
                  label: context.l10n.workFolderHistorySortNewest,
                ),
                _sortTile(
                  context,
                  mode: _PropertyRecordSortMode.oldestFirst,
                  label: context.l10n.workFolderHistorySortOldest,
                ),
                _sortTile(
                  context,
                  mode: _PropertyRecordSortMode.title,
                  label: context.l10n.workFolderHistorySortTitle,
                ),
              ],
            ),
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

  Widget _sortTile(
    BuildContext context, {
    required _PropertyRecordSortMode mode,
    required String label,
  }) {
    final selected = mode == _sortMode;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: () => Navigator.of(context).pop(mode),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: selected
              ? context.appPalette.primary
              : context.appPalette.textPrimary,
        ),
      ),
      trailing: selected
          ? Icon(
              Icons.check_rounded,
              size: 18,
              color: context.appPalette.primary,
            )
          : null,
    );
  }

  Widget _circleActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required double iconSize,
    String? tooltip,
  }) {
    final message = (tooltip ?? '').trim();
    final iconWidget = Icon(
      icon,
      size: iconSize,
      color: context.appPalette.textSecondary,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: context.appPalette.surfaceSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: message.isEmpty
              ? iconWidget
              : Tooltip(message: message, child: iconWidget),
        ),
      ),
    );
  }

  List<ContextMenuAction> _desktopActions(PropertyAssetRecordEntity item) {
    return [
      ContextMenuAction(
        icon: Icons.remove_red_eye_rounded,
        label: context.l10n.documentPreview,
        onSelected: () => _openDocument(item.documentId),
      ),
      ContextMenuAction(
        icon: Icons.edit_rounded,
        label: context.l10n.commonEdit,
        onSelected: () => _editDocument(item.documentId),
      ),
      ContextMenuAction(
        icon: Icons.download_rounded,
        label: context.l10n.commonShare,
        onSelected: () => _shareDocument(item.documentId),
      ),
    ];
  }

  IconData _documentIcon(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) {
      return Icons.image_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  String _screenTitle(BuildContext context) {
    return switch (widget.assetType) {
      PropertyAssetType.documents => context.l10n.propertyDetailAssetDocuments,
      PropertyAssetType.contracts => context.l10n.propertyDetailAssetContracts,
      PropertyAssetType.insurance => context.l10n.propertyDetailAssetInsurance,
      PropertyAssetType.payments => context.l10n.propertyDetailAssetPayments,
      PropertyAssetType.maintenance =>
        context.l10n.propertyDetailAssetMaintenance,
      PropertyAssetType.others => context.l10n.propertyDetailAssetOthers,
    };
  }
}
