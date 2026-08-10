import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_file_preview_page.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_country.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_structured_field_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_status.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/archive_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/delete_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/force_expire_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/set_primary_identity_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/extensions/document_field_presentation_extensions.dart';
import 'package:pass_doc_manager/features/documents/presentation/navigation/document_edit_navigator.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/document_removal_prompt.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/work_documents_design.dart';
// TODO: Re-enable when Secure Share is ready
// import 'package:pass_doc_manager/domain/secure_share/entities/share_payload_entity.dart';
// import 'package:pass_doc_manager/features/secure_share/presentation/pages/secure_share_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

class DocumentDetailPage extends StatefulWidget {
  const DocumentDetailPage({
    super.key,
    required this.documentId,
    GetDocumentDetail? getDocumentDetail,
    DeleteDocument? deleteDocument,
    ArchiveDocument? archiveDocument,
    ForceExpireDocument? forceExpireDocument,
    SetPrimaryIdentityDocument? setPrimaryIdentityDocument,
  }) : _getDocumentDetail = getDocumentDetail,
       _deleteDocument = deleteDocument,
       _archiveDocument = archiveDocument,
       _forceExpireDocument = forceExpireDocument,
       _setPrimaryIdentityDocument = setPrimaryIdentityDocument;

  final String documentId;
  final GetDocumentDetail? _getDocumentDetail;
  final DeleteDocument? _deleteDocument;
  final ArchiveDocument? _archiveDocument;
  final ForceExpireDocument? _forceExpireDocument;
  final SetPrimaryIdentityDocument? _setPrimaryIdentityDocument;

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  DocumentDetailEntity? _detail;
  bool _isLoading = true;
  bool _isUpdatingPrimary = false;
  final Map<String, double> _previewAspectRatioCache = <String, double>{};
  final Set<String> _previewAspectRatioPending = <String>{};
  final Map<String, int> _referenceFileSizeCache = <String, int>{};
  final Set<String> _referenceFileSizePending = <String>{};

  GetDocumentDetail get _getDetailUseCase =>
      widget._getDocumentDetail ?? getIt();

  DeleteDocument get _deleteUseCase => widget._deleteDocument ?? getIt();

  ArchiveDocument get _archiveUseCase => widget._archiveDocument ?? getIt();
  ForceExpireDocument get _forceExpireUseCase =>
      widget._forceExpireDocument ?? getIt();
  SetPrimaryIdentityDocument get _setPrimaryUseCase =>
      widget._setPrimaryIdentityDocument ?? getIt();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final l10n = context.l10n;

    if (_isLoading || detail == null) {
      return Scaffold(
        backgroundColor: context.appPalette.surfaceSoft,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final palette = context.appPalette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;
        final maxContentWidth = isDesktop ? 540.0 : constraints.maxWidth;
        final visibleStructuredFields = _visibleStructuredFields(detail);
        final referenceAssets = _resolvedReferenceAssets(detail);
        final hasPreviewSection = _hasPreviewAsset(detail);

        if (detail.category == DocumentCategoryType.identity) {
          return _identityDetailScaffold(
            detail: detail,
            referenceAssets: referenceAssets,
            hasPreviewSection: hasPreviewSection,
            maxContentWidth: isDesktop ? 620 : constraints.maxWidth,
          );
        }

        if (detail.category == DocumentCategoryType.work) {
          return _workDetailScaffold(
            detail: detail,
            referenceAssets: referenceAssets,
            maxContentWidth: isDesktop ? 720 : constraints.maxWidth,
          );
        }

        return Scaffold(
          backgroundColor: palette.background,
          appBar: GenericAppBar(
            backgroundColor: palette.background,
            onBackPressed: () => Navigator.of(context).maybePop(),
            title: detail.screenTitle,
            titleStyle: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
            actions: [
              IconButton(
                onPressed: _openEdit,
                tooltip: l10n.commonEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              PopupMenuButton<_DocumentDetailMenuAction>(
                tooltip: l10n.commonMore,
                onSelected: _onMenuActionSelected,
                itemBuilder: (context) => [
                  // TODO: Re-enable when Secure Share is ready
                  // PopupMenuItem(
                  //   value: _DocumentDetailMenuAction.secureShare,
                  //   child: Row(children: [
                  //     const Icon(Icons.share_rounded, size: 18),
                  //     const SizedBox(width: 8),
                  //     Text(l10n.shareTitle),
                  //   ]),
                  // ),
                  if (_canForceExpire(detail))
                    PopupMenuItem(
                      value: _DocumentDetailMenuAction.forceExpire,
                      child: Row(
                        children: [
                          const Icon(Icons.event_busy_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.documentForceExpire),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: _DocumentDetailMenuAction.remove,
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.commonRemove),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                children: [
                  if (hasPreviewSection) ...[
                    _previewCard(detail),
                    const SizedBox(height: 12),
                  ],
                  if (detail.category == DocumentCategoryType.identity) ...[
                    _primaryDocumentCard(detail),
                    const SizedBox(height: 12),
                  ],
                  if (detail.expiryDate != null) ...[
                    _expiryStatusBanner(detail),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Text(
                        l10n.documentStructuredInformation,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.9,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: palette.stroke),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: visibleStructuredFields
                          .asMap()
                          .entries
                          .map((entry) {
                            final field = entry.value;
                            return Column(
                              children: [
                                _fieldRow(
                                  label: field.label,
                                  value: field.value,
                                  icon: field.label.documentFieldIcon,
                                  tint: field.label.documentFieldTint(context),
                                  onCopy: () => _copy(field.value),
                                ),
                                if (entry.key !=
                                    visibleStructuredFields.length - 1)
                                  Divider(
                                    height: 1,
                                    color: palette.strokeStrong,
                                  ),
                              ],
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                  if (referenceAssets.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _referenceFilesSection(referenceAssets),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: palette.stroke,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: palette.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.documentDateAdded(
                              DateFormat.yMMMd(
                                Localizations.localeOf(context).toLanguageTag(),
                              ).format(detail.uploadDate),
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          referenceAssets.length > 1
                              ? l10n.documentFilesCount(referenceAssets.length)
                              : detail.fileSizeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
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
      },
    );
  }

  Widget _identityDetailScaffold({
    required DocumentDetailEntity detail,
    required List<_ReferenceAssetItem> referenceAssets,
    required bool hasPreviewSection,
    required double maxContentWidth,
  }) {
    final palette = context.appPalette;
    final info = _identityDetailInfo(detail);
    final filePath = _primaryIdentityFilePath(detail, referenceAssets);
    final fieldSections = _identityFieldSections(detail);
    final fileAvailable = (filePath ?? '').trim().isNotEmpty;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _IdentityDetailTopBar(
                  onBackTap: () => Navigator.of(context).maybePop(),
                  canShare: fileAvailable,
                  onShareTap: fileAvailable
                      ? () => _shareLocalFile(
                          filePath!,
                          fileName: detail.fileName,
                        )
                      : null,
                  onEditTap: _openEdit,
                  canForceExpire: _canForceExpire(detail),
                  onForceExpireTap: () => _onMenuActionSelected(
                    _DocumentDetailMenuAction.forceExpire,
                  ),
                  onRemoveTap: () =>
                      _onMenuActionSelected(_DocumentDetailMenuAction.remove),
                ),
                const SizedBox(height: 20),
                _identityHero(detail: detail, info: info),
                const SizedBox(height: 14),
                if (hasPreviewSection && fileAvailable)
                  _identityPreviewTile(
                    detail: detail,
                    referenceAssets: referenceAssets,
                    filePath: filePath!,
                  )
                else
                  _identityMissingFileBanner(detail),
                const SizedBox(height: 14),
                _identityActionGrid(detail: detail, filePath: filePath),
                const SizedBox(height: 14),
                if (detail.expiryDate != null) ...[
                  _expiryStatusBanner(detail),
                  const SizedBox(height: 14),
                ],
                _primaryDocumentCard(detail),
                for (final section in fieldSections) ...[
                  const SizedBox(height: 14),
                  _identityFieldGroup(section),
                ],
                if (referenceAssets.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _referenceFilesSection(referenceAssets),
                ],
                const SizedBox(height: 14),
                _identityFooterMeta(detail),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _workDetailScaffold({
    required DocumentDetailEntity detail,
    required List<_ReferenceAssetItem> referenceAssets,
    required double maxContentWidth,
  }) {
    final palette = context.appPalette;
    final asset = referenceAssets.isEmpty ? null : referenceAssets.first;
    final filePath =
        (asset?.path.trim().isNotEmpty == true
            ? asset!.path
            : _resolvePreviewImagePath(detail)) ??
        '';
    final fileMime = asset?.mime.trim().isNotEmpty == true
        ? asset!.mime
        : filePath.inferMimeType();
    final hasFile = filePath.trim().isNotEmpty;
    final companyNameRaw = _workFieldValue(
      detail,
      DocumentMetadataFieldLabels.workCompanyName,
      fallbackLabels: const ['Company Name'],
    );
    final companyName = companyNameRaw.trim().isEmpty
        ? detail.issuer
        : companyNameRaw;
    final folderLabel = _workFolderLabel(detail);
    final documentLabelRaw = _workFieldValue(
      detail,
      DocumentMetadataFieldLabels.workStatementLabel,
      fallbackLabels: const ['Document Type'],
    );
    final documentLabel = documentLabelRaw.trim().isEmpty
        ? folderLabel
        : documentLabelRaw;
    final documentTitleRaw = _workFieldValue(
      detail,
      DocumentMetadataFieldLabels.workStatementTitle,
      fallbackLabels: const ['Document Title'],
    );
    final documentTitle = documentTitleRaw.trim().isEmpty
        ? detail.screenTitle
        : documentTitleRaw;
    final dateLabel = _workDateLabel(detail);
    final sizeLabel = asset == null
        ? detail.fileSizeLabel
        : (_resolveReferenceFileSizeLabel(asset.path) ?? detail.fileSizeLabel);
    final filesLabel = referenceAssets.length > 1
        ? context.l10n.documentFilesCount(referenceAssets.length)
        : sizeLabel;
    final infoFields = _workDetailInfoFields(
      companyName: companyName,
      folderLabel: folderLabel,
      documentLabel: documentLabel,
      dateLabel: dateLabel,
      sizeLabel: filesLabel,
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                WorkDesignTopBar(
                  onBackTap: () => Navigator.of(context).maybePop(),
                  onSearchTap: null,
                  onFilterTap: null,
                  onMoreTap: () => _showDocumentActionsSheet(detail),
                  onAddTap: null,
                ),
                const SizedBox(height: 18),
                WorkIntroHeader(
                  kicker: [context.l10n.workHubTitle, folderLabel].join(' · '),
                  title: documentTitle,
                  subtitle: [
                    if (companyName.trim().isNotEmpty) companyName,
                    if (dateLabel.trim().isNotEmpty) dateLabel,
                    if (documentLabel.trim().isNotEmpty) documentLabel,
                  ].join(' · '),
                  icon: companyName,
                  iconTint: WorkTint.lavender,
                ),
                const SizedBox(height: 16),
                if (hasFile && referenceAssets.length > 1)
                  _referenceFilesSection(referenceAssets)
                else if (hasFile)
                  WorkFileCard(
                    title: documentTitle,
                    meta: [
                      if ((asset?.name ?? detail.fileName).trim().isNotEmpty)
                        asset?.name ?? detail.fileName,
                      resolveFileTypeLabel(path: filePath, mime: fileMime),
                      if (sizeLabel.trim().isNotEmpty) sizeLabel,
                    ].join(' · '),
                    path: filePath,
                    mime: fileMime,
                    onTap: () => _openFileFullscreen(
                      filePath: filePath,
                      mime: fileMime,
                      title: documentTitle,
                    ),
                    trailing: WorkCircleButton(
                      size: 38,
                      icon: Icons.ios_share_rounded,
                      onTap: () => _shareLocalFile(
                        filePath,
                        fileName: asset?.name ?? detail.fileName,
                      ),
                    ),
                  )
                else
                  _workMissingFileCard(detail),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _IdentityActionButton(
                        icon: Icons.visibility_outlined,
                        label: context.l10n.documentPreview,
                        enabled: hasFile,
                        onTap: hasFile
                            ? () => _openFileFullscreen(
                                filePath: filePath,
                                mime: fileMime,
                                title: documentTitle,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _IdentityActionButton(
                        icon: Icons.edit_outlined,
                        label: context.l10n.commonEdit,
                        emphasized: true,
                        onTap: _openEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _IdentityActionButton(
                        icon: Icons.ios_share_rounded,
                        label: context.l10n.commonShare,
                        enabled: hasFile,
                        onTap: hasFile
                            ? () => _shareLocalFile(
                                filePath,
                                fileName: asset?.name ?? detail.fileName,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _IdentityActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: context.l10n.commonRemove,
                        danger: true,
                        onTap: () => _onMenuActionSelected(
                          _DocumentDetailMenuAction.remove,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                WorkSectionLabel(
                  value: context.l10n.documentStructuredInformation,
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.stroke),
                  ),
                  child: Column(
                    children: infoFields
                        .asMap()
                        .entries
                        .map((entry) {
                          final field = entry.value;
                          return Column(
                            children: [
                              _fieldRow(
                                label: field.label,
                                value: field.value,
                                icon: field.icon,
                                tint: field.tint,
                                onCopy: () => _copy(field.value),
                              ),
                              if (entry.key != infoFields.length - 1)
                                Divider(height: 1, color: palette.strokeStrong),
                            ],
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 14),
                _identityFooterMeta(detail),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _workMissingFileCard(DocumentDetailEntity detail) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          WorkFileThumb(path: detail.fileName, mime: ''),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.documentFileUnavailable,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
          WorkCircleButton(
            size: 38,
            icon: Icons.edit_outlined,
            onTap: _openEdit,
          ),
        ],
      ),
    );
  }

  List<_WorkDetailField> _workDetailInfoFields({
    required String companyName,
    required String folderLabel,
    required String documentLabel,
    required String dateLabel,
    required String sizeLabel,
  }) {
    final palette = context.appPalette;
    return <_WorkDetailField>[
      if (companyName.trim().isNotEmpty)
        _WorkDetailField(
          label: context.l10n.workEntryCompanyNameLabel,
          value: companyName,
          icon: Icons.apartment_rounded,
          tint: palette.primary,
        ),
      if (folderLabel.trim().isNotEmpty)
        _WorkDetailField(
          label: context.l10n.workEntryFolderTypeLabel,
          value: folderLabel,
          icon: Icons.folder_outlined,
          tint: workTintForeground(context, WorkTint.lavender),
        ),
      if (documentLabel.trim().isNotEmpty)
        _WorkDetailField(
          label: context.l10n.workManualEntryDocumentTypeLabel,
          value: documentLabel,
          icon: Icons.label_outline_rounded,
          tint: workTintForeground(context, WorkTint.blue),
        ),
      if (dateLabel.trim().isNotEmpty)
        _WorkDetailField(
          label: context.l10n.workEntryStatementDateLabel,
          value: dateLabel,
          icon: Icons.calendar_today_outlined,
          tint: workTintForeground(context, WorkTint.sand),
        ),
      if (sizeLabel.trim().isNotEmpty)
        _WorkDetailField(
          label: sizeLabel.toLowerCase().contains('files')
              ? 'Files'
              : 'File size',
          value: sizeLabel,
          icon: Icons.storage_outlined,
          tint: workTintForeground(context, WorkTint.mint),
        ),
    ];
  }

  String _workFieldValue(
    DocumentDetailEntity detail,
    String canonicalKey, {
    List<String> fallbackLabels = const <String>[],
  }) {
    final targetLabels = <String>{
      canonicalKey.trim().toLowerCase(),
      '${DocumentMetadataFieldLabels.claimPrefix}$canonicalKey'
          .trim()
          .toLowerCase(),
      for (final label in fallbackLabels) label.trim().toLowerCase(),
    };
    for (final field in detail.structuredFields) {
      final normalized = field.label.trim().toLowerCase();
      final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(
        field.label,
      );
      if (!targetLabels.contains(normalized) &&
          !targetLabels.contains((canonical ?? '').trim().toLowerCase())) {
        continue;
      }
      final value = field.value.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _workFolderLabel(DocumentDetailEntity detail) {
    final raw = _workFieldValue(
      detail,
      DocumentMetadataFieldLabels.workFolderType,
      fallbackLabels: const ['Folder Type'],
    );
    if (raw.trim().isEmpty) {
      return detail.tags.isEmpty ? '' : detail.tags.first;
    }
    final normalized = raw.trim().toLowerCase();
    for (final value in WorkDocumentFolderType.values) {
      if (value.key.toLowerCase() == normalized ||
          value.label.toLowerCase() == normalized) {
        return value.label;
      }
    }
    return raw;
  }

  String _workDateLabel(DocumentDetailEntity detail) {
    final raw = _workFieldValue(
      detail,
      DocumentMetadataFieldLabels.workStatementDate,
      fallbackLabels: const ['Date'],
    );
    final date = DateTime.tryParse(raw) ?? detail.updatedAt;
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
  }

  Widget _identityHero({
    required DocumentDetailEntity detail,
    required _IdentityDetailInfo info,
  }) {
    final palette = context.appPalette;
    final scheme = _identityDetailScheme(detail.type);
    final heroBackground = _identityDetailTint(
      context,
      scheme.background,
      scheme.accent,
      darkAlpha: 0.18,
    );
    final status = _identityDetailStatus(context, detail);
    final typeCountry = [
      info.typeLabel.toUpperCase(),
      if (info.countryLabel.isNotEmpty) info.countryLabel.toUpperCase(),
      if (detail.isPrimary) context.l10n.identityPrimaryBadge.toUpperCase(),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: heroBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _identityDetailTint(
            context,
            scheme.border,
            scheme.accent,
            darkAlpha: 0.32,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: palette.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.surface.withValues(alpha: 0.7)),
            ),
            alignment: Alignment.center,
            child: info.country == DocumentCountry.unknown
                ? Icon(scheme.icon, size: 27, color: scheme.accent)
                : _DetailCountryFlag(
                    country: info.country,
                    size: const Size(34, 24),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeCountry,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: scheme.accent,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  info.holderLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _IdentityDetailPill(
                      label: status.label,
                      icon: status.icon,
                      foregroundColor: status.foreground,
                      backgroundColor: _identityDetailTint(
                        context,
                        status.background,
                        status.foreground,
                        darkAlpha: 0.18,
                      ),
                    ),
                    _IdentityDetailPill(
                      label: '${info.fileTypeLabel} · ${detail.fileSizeLabel}',
                      foregroundColor: palette.textSecondary,
                      backgroundColor: palette.surface.withValues(alpha: 0.72),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityPreviewTile({
    required DocumentDetailEntity detail,
    required List<_ReferenceAssetItem> referenceAssets,
    required String filePath,
  }) {
    final palette = context.appPalette;
    final normalizedPath = _normalizeLocalPath(filePath);
    final isPdf = _isPdfFile(
      path: normalizedPath,
      mime: normalizedPath.inferMimeType(),
    );
    final imageProvider = isPdf
        ? null
        : resolveLocalFileImageProvider(normalizedPath);
    final asset = referenceAssets.cast<_ReferenceAssetItem?>().firstWhere(
      (item) => item?.path == normalizedPath,
      orElse: () => referenceAssets.isEmpty ? null : referenceAssets.first,
    );
    final title = asset?.displayTitle ?? detail.fileName;
    final sizeLabel = asset == null
        ? detail.fileSizeLabel
        : (_resolveReferenceFileSizeLabel(asset.path) ?? detail.fileSizeLabel);
    final subtitleParts = <String>[
      resolveFileTypeLabel(
        path: normalizedPath,
        mime: normalizedPath.inferMimeType(),
      ),
      if (sizeLabel.trim().isNotEmpty) sizeLabel,
      if (detail.scanPagesCount > 0)
        context.l10n.identityDetailPagesCount(detail.scanPagesCount),
      DateFormat.yMMMd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(detail.uploadDate),
    ];

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openFileFullscreen(
          filePath: normalizedPath,
          mime: normalizedPath.inferMimeType(),
          title: detail.screenTitle,
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 82,
                height: 104,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: palette.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.stroke),
                ),
                child: imageProvider != null
                    ? Image(image: imageProvider, fit: BoxFit.cover)
                    : isPdf
                    ? _embeddedPdfPreview(normalizedPath)
                    : Icon(
                        Icons.insert_drive_file_rounded,
                        size: 32,
                        color: palette.primary,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trim().isEmpty ? detail.screenTitle : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleParts.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${context.l10n.documentPreview} ›',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: palette.primary,
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

  Widget _identityMissingFileBanner(DocumentDetailEntity detail) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _identityDetailTint(
          context,
          const Color(0xFFFFF8E8),
          palette.warning,
          darkAlpha: 0.14,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _identityDetailTint(
            context,
            const Color(0xFFF0D99F),
            palette.warning,
            darkAlpha: 0.28,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.surface.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.file_present_outlined,
              color: palette.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.identityDetailFileMissingTitle,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.identityDetailFileMissingDescription,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openEdit,
            tooltip: context.l10n.commonEdit,
            icon: Icon(Icons.edit_outlined, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _identityActionGrid({
    required DocumentDetailEntity detail,
    required String? filePath,
  }) {
    final hasFile = (filePath ?? '').trim().isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: _IdentityActionButton(
            icon: Icons.visibility_outlined,
            label: context.l10n.documentPreview,
            enabled: hasFile,
            onTap: hasFile
                ? () => _openFileFullscreen(
                    filePath: filePath!,
                    mime: filePath.inferMimeType(),
                    title: detail.screenTitle,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _IdentityActionButton(
            icon: Icons.ios_share_rounded,
            label: context.l10n.commonShare,
            enabled: hasFile,
            onTap: hasFile
                ? () => _shareLocalFile(filePath!, fileName: detail.fileName)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _IdentityActionButton(
            icon: Icons.edit_outlined,
            label: context.l10n.commonEdit,
            emphasized: true,
            onTap: _openEdit,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _IdentityActionButton(
            icon: Icons.delete_outline_rounded,
            label: context.l10n.commonRemove,
            danger: true,
            onTap: () =>
                _onMenuActionSelected(_DocumentDetailMenuAction.remove),
          ),
        ),
      ],
    );
  }

  Widget _identityFieldGroup(_IdentityFieldSection section) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.stroke),
          ),
          child: Column(
            children: section.fields
                .asMap()
                .entries
                .map((entry) {
                  return Column(
                    children: [
                      _identityFieldRow(entry.value),
                      if (entry.key != section.fields.length - 1)
                        Divider(height: 1, color: palette.stroke),
                    ],
                  );
                })
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  Widget _identityFieldRow(_IdentityDisplayField field) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _identityDetailTint(
                context,
                field.tint.withValues(alpha: 0.12),
                field.tint,
                darkAlpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(field.icon, size: 19, color: field.tint),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  field.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copy(field.value),
            tooltip: context.l10n.commonCopied,
            icon: Icon(Icons.copy_rounded, color: palette.textMuted, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _identityFooterMeta(DocumentDetailEntity detail) {
    final palette = context.appPalette;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: palette.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '${context.l10n.documentDateAdded(DateFormat.yMMMd(localeTag).format(detail.uploadDate))} · ${detail.captureSource.name}',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
          ),
          Text(
            detail.fileSizeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  _IdentityDetailInfo _identityDetailInfo(DocumentDetailEntity detail) {
    final givenName = _firstClaimValue(
      detail,
      DocumentMetadataFieldLabels.givenName,
    );
    final familyName = _firstClaimValue(
      detail,
      DocumentMetadataFieldLabels.familyName,
    );
    final holder = [
      givenName,
      familyName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    final countryRaw = _firstClaimValue(
      detail,
      DocumentMetadataFieldLabels.issuingCountry,
    );
    final country = _parseDocumentCountry(
      countryRaw.trim().isNotEmpty ? countryRaw : detail.issuer,
    );
    final typeLabel = detail.type == DocumentType.other
        ? detail.screenTitle
        : detail.type.label;

    return _IdentityDetailInfo(
      typeLabel: typeLabel,
      country: country,
      countryLabel: countryRaw.trim().isNotEmpty
          ? countryRaw.trim()
          : country == DocumentCountry.unknown
          ? ''
          : country.label,
      holderLabel: holder.isNotEmpty ? holder : detail.issuer,
      fileTypeLabel: _identityFileTypeLabel(detail),
    );
  }

  String _identityFileTypeLabel(DocumentDetailEntity detail) {
    final extension = detail.fileName.split('.').last.trim().toUpperCase();
    if (extension.length <= 5 && extension != detail.fileName.toUpperCase()) {
      return extension;
    }
    return detail.type.label;
  }

  String? _primaryIdentityFilePath(
    DocumentDetailEntity detail,
    List<_ReferenceAssetItem> referenceAssets,
  ) {
    final previewPath = _resolvePreviewImagePath(detail);
    if ((previewPath ?? '').trim().isNotEmpty) {
      return previewPath;
    }
    if (referenceAssets.isNotEmpty) {
      return referenceAssets.first.path;
    }
    return null;
  }

  List<_IdentityFieldSection> _identityFieldSections(
    DocumentDetailEntity detail,
  ) {
    const documentKeys = <String>[
      DocumentMetadataFieldLabels.documentNumber,
      DocumentMetadataFieldLabels.issuingCountry,
      DocumentMetadataFieldLabels.nationality,
      DocumentMetadataFieldLabels.expiryDate,
    ];
    const holderKeys = <String>[
      DocumentMetadataFieldLabels.givenName,
      DocumentMetadataFieldLabels.familyName,
      DocumentMetadataFieldLabels.birthDate,
      DocumentMetadataFieldLabels.sex,
      DocumentMetadataFieldLabels.holderRelation,
      DocumentMetadataFieldLabels.ageOver18,
    ];
    final usedKeys = <String>{};
    final sections = <_IdentityFieldSection>[];

    List<_IdentityDisplayField> fieldsFor(List<String> canonicalKeys) {
      final fields = <_IdentityDisplayField>[];
      for (final key in canonicalKeys) {
        for (final field in detail.structuredFields) {
          final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(
            field.label,
          );
          if (canonical != key) {
            continue;
          }
          final value = field.value.trim();
          if (value.isEmpty || usedKeys.contains(key)) {
            continue;
          }
          usedKeys.add(key);
          fields.add(_identityDisplayField(field, canonical));
          break;
        }
      }
      return fields;
    }

    final documentFields = fieldsFor(documentKeys);
    if (documentFields.isNotEmpty) {
      sections.add(
        _IdentityFieldSection(
          title: context.l10n.identityDetailSectionDocument,
          fields: documentFields,
        ),
      );
    }

    final holderFields = fieldsFor(holderKeys);
    if (holderFields.isNotEmpty) {
      sections.add(
        _IdentityFieldSection(
          title: context.l10n.identityDetailSectionHolder,
          fields: holderFields,
        ),
      );
    }

    final otherFields = <_IdentityDisplayField>[];
    for (final field in detail.structuredFields) {
      if (_isAttachmentMetadataField(field.label)) {
        continue;
      }
      final value = field.value.trim();
      if (value.isEmpty) {
        continue;
      }
      final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(
        field.label,
      );
      if (canonical != null && usedKeys.contains(canonical)) {
        continue;
      }
      if (canonical != null) {
        usedKeys.add(canonical);
      }
      otherFields.add(_identityDisplayField(field, canonical));
    }
    if (otherFields.isNotEmpty) {
      sections.add(
        _IdentityFieldSection(
          title: context.l10n.identityDetailSectionOtherDetails,
          fields: otherFields,
        ),
      );
    }

    return sections;
  }

  _IdentityDisplayField _identityDisplayField(
    DocumentStructuredFieldEntity field,
    String? canonical,
  ) {
    return _IdentityDisplayField(
      label: _identityFieldLabel(context, field.label, canonical),
      value: field.value.trim(),
      icon: _identityFieldIcon(field.label, canonical),
      tint: _identityFieldTint(canonical),
    );
  }

  bool _isAttachmentMetadataField(String label) {
    final normalized = _normalizeLabel(label);
    return normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.frontImagePath) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.backImagePath) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.previewImagePath) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.previewImageEnabled) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.referenceAssetName) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.referenceAssetLabel) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.referenceAssetPath) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.referenceAssetMime) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.referenceAssetsJson);
  }

  String _firstClaimValue(DocumentDetailEntity detail, String canonicalKey) {
    for (final field in detail.structuredFields) {
      final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(
        field.label,
      );
      if (canonical == canonicalKey) {
        final value = field.value.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }

  Widget _previewCard(DocumentDetailEntity detail) {
    final l10n = context.l10n;
    final palette = context.appPalette;
    final visual = _previewVisual(detail.type);
    final previewImagePath = _resolvePreviewImagePath(detail);
    final previewImageProvider = resolveLocalFileImageProvider(
      previewImagePath,
    );
    final hasPreviewAsset = (previewImagePath ?? '').trim().isNotEmpty;
    final isPreviewPdf = _isPdfFile(
      path: previewImagePath,
      mime: previewImagePath?.inferMimeType(),
    );
    final previewAspectRatio = _resolvedPreviewAspectRatio(
      type: detail.type,
      imagePath: previewImagePath,
      imageProvider: previewImageProvider,
    );

    return AspectRatio(
      aspectRatio: previewAspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF556070), width: 1.3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [visual.start, visual.end],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C111827),
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: previewImageProvider != null
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Image(
                                image: previewImageProvider,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.01),
                                      Colors.black.withValues(alpha: 0.12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : isPreviewPdf &&
                            (previewImagePath ?? '').trim().isNotEmpty
                      ? _embeddedPdfPreview(previewImagePath!)
                      : isPreviewPdf
                      ? _pdfPreviewPlaceholder()
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.06),
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.02),
                                        Colors.black.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 18,
                                right: 18,
                                top: 18,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(
                                    7,
                                    (index) => Padding(
                                      padding: const EdgeInsets.only(bottom: 7),
                                      child: Container(
                                        height: 4,
                                        width: index.isEven
                                            ? 170
                                            : double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.34,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            if (previewImageProvider == null && !isPreviewPdf)
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 98,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    visual.icon,
                    color: Colors.white.withValues(alpha: 0.56),
                    size: 26,
                  ),
                ),
              ),
            Positioned(
              left: 62,
              right: 62,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: hasPreviewAsset
                            ? () => _openFileFullscreen(
                                filePath: previewImagePath!,
                                mime: previewImagePath.inferMimeType(),
                                title: detail.screenTitle,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.zoom_in_rounded,
                                color: hasPreviewAsset
                                    ? palette.primary
                                    : palette.textMuted,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                l10n.documentPreview,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: hasPreviewAsset
                                      ? palette.textPrimary
                                      : palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 18, color: palette.stroke),
                    Expanded(
                      child: InkWell(
                        onTap: hasPreviewAsset
                            ? () => _shareLocalFile(
                                previewImagePath!,
                                fileName: detail.fileName,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.share_outlined,
                                color: hasPreviewAsset
                                    ? palette.primary
                                    : palette.textMuted,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                l10n.commonShare,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: hasPreviewAsset
                                      ? palette.textPrimary
                                      : palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _resolvedPreviewAspectRatio({
    required DocumentType type,
    required String? imagePath,
    required ImageProvider? imageProvider,
  }) {
    final normalizedPath = (imagePath ?? '').trim();
    if (normalizedPath.isNotEmpty && imageProvider != null) {
      _schedulePreviewAspectRatioPrime(
        imagePath: normalizedPath,
        imageProvider: imageProvider,
      );
      final cached = _previewAspectRatioCache[normalizedPath];
      if (cached != null && cached.isFinite && cached > 0) {
        return cached.clamp(0.8, 2.4).toDouble();
      }
    }
    return _defaultPreviewAspectRatio(type);
  }

  void _schedulePreviewAspectRatioPrime({
    required String imagePath,
    required ImageProvider imageProvider,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _primePreviewAspectRatio(
        imagePath: imagePath,
        imageProvider: imageProvider,
      );
    });
  }

  void _primePreviewAspectRatio({
    required String imagePath,
    required ImageProvider imageProvider,
  }) {
    if (_previewAspectRatioCache.containsKey(imagePath) ||
        _previewAspectRatioPending.contains(imagePath)) {
      return;
    }
    _previewAspectRatioPending.add(imagePath);

    final stream = imageProvider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        final width = imageInfo.image.width.toDouble();
        final height = imageInfo.image.height.toDouble();
        if (width > 0 && height > 0) {
          final ratio = width / height;
          final previousRatio = _previewAspectRatioCache[imagePath];
          _previewAspectRatioCache[imagePath] = ratio;

          final ratioChanged =
              previousRatio == null || (previousRatio - ratio).abs() > 0.0001;
          if (mounted && ratioChanged) {
            _scheduleRebuild();
          }
        }
        _previewAspectRatioPending.remove(imagePath);
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        _previewAspectRatioPending.remove(imagePath);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  double _defaultPreviewAspectRatio(DocumentType type) {
    return switch (type) {
      DocumentType.passport => 1.58,
      DocumentType.idCard => 1.58,
      DocumentType.driversLicense => 1.58,
      DocumentType.other => 1.35,
    };
  }

  List<DocumentStructuredFieldEntity> _visibleStructuredFields(
    DocumentDetailEntity detail,
  ) {
    return detail.structuredFields
        .where((field) => !_isMetadataField(field.label))
        .toList(growable: false);
  }

  bool _isMetadataField(String label) {
    final normalized = label.trim().toLowerCase();
    if (DocumentMetadataFieldLabels.isClaimFieldLabel(normalized)) {
      return true;
    }
    return normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.frontImagePath) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.backImagePath) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.previewImagePath) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.previewImageEnabled) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.referenceAssetName) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.referenceAssetLabel) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.referenceAssetPath) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.referenceAssetMime) ||
        normalized ==
            _normalizeLabel(DocumentMetadataFieldLabels.referenceAssetsJson);
  }

  String _normalizeLabel(String value) => value.trim().toLowerCase();

  String? _resolvePreviewImagePath(DocumentDetailEntity detail) {
    final previewEnabledRaw = _fieldValueByLabel(
      detail: detail,
      label: DocumentMetadataFieldLabels.previewImageEnabled,
    );
    if ((previewEnabledRaw ?? '').trim().toLowerCase() == 'false') {
      return null;
    }

    final rawPath =
        _fieldValueByLabel(
          detail: detail,
          label: DocumentMetadataFieldLabels.previewImagePath,
        ) ??
        _fieldValueByLabel(
          detail: detail,
          label: DocumentMetadataFieldLabels.frontImagePath,
        );
    if ((rawPath ?? '').trim().isEmpty) {
      final referenceAssets = _resolvedReferenceAssets(detail);
      for (final asset in referenceAssets) {
        if (asset.isImage || asset.isPdf) {
          return asset.path;
        }
      }
      return null;
    }
    final normalized = _normalizeLocalPath(rawPath!);
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String? _fieldValueByLabel({
    required DocumentDetailEntity detail,
    required String label,
  }) {
    final normalized = _normalizeLabel(label);
    for (final field in detail.structuredFields) {
      if (_normalizeLabel(field.label) == normalized) {
        final value = field.value.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  Widget _referenceFilesSection(List<_ReferenceAssetItem> assets) {
    final l10n = context.l10n;
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.documentReferenceFiles,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: palette.textSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.appPalette.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.documentFilesCount(assets.length),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: palette.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...assets.asMap().entries.map((entry) {
              final index = entry.key;
              final asset = entry.value;
              return Column(
                children: [
                  _referenceFileRow(asset),
                  if (index != assets.length - 1)
                    Divider(height: 1, color: palette.strokeStrong),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _referenceFileRow(_ReferenceAssetItem asset) {
    final l10n = context.l10n;
    final palette = context.appPalette;
    final isImage = asset.isImage;
    final imageProvider = isImage
        ? resolveLocalFileImageProvider(asset.path)
        : null;
    final canPreview = imageProvider != null || asset.isPdf;
    final sizeLabel = _resolveReferenceFileSizeLabel(asset.path);
    final typeAndSizeLabel = sizeLabel == null
        ? '${asset.typeLabel} • ...'
        : '${asset.typeLabel} • $sizeLabel';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.stroke),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageProvider != null
                ? Image(image: imageProvider, fit: BoxFit.cover)
                : Icon(
                    asset.mime.toLowerCase().contains('pdf')
                        ? Icons.picture_as_pdf_rounded
                        : Icons.insert_drive_file_rounded,
                    size: 22,
                    color: palette.primary,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                if (asset.hasLabel) ...[
                  const SizedBox(height: 1),
                  Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 1),
                Text(
                  typeAndSizeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canPreview
                ? () => _openFileFullscreen(
                    filePath: asset.path,
                    mime: asset.mime,
                    title: asset.displayTitle,
                  )
                : null,
            tooltip: canPreview
                ? l10n.documentPreview
                : l10n.documentPreviewUnavailable,
            icon: Icon(
              Icons.zoom_in_rounded,
              size: 19,
              color: canPreview ? palette.primary : palette.textMuted,
            ),
          ),
          IconButton(
            onPressed: () => _shareLocalFile(asset.path, fileName: asset.name),
            tooltip: l10n.commonShare,
            icon: Icon(
              Icons.share_outlined,
              size: 18,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveReferenceFileSizeLabel(String path) {
    final normalizedPath = _normalizeLocalPath(path);
    if (normalizedPath.isEmpty) {
      return null;
    }
    final cachedBytes = _referenceFileSizeCache[normalizedPath];
    if (cachedBytes != null) {
      if (cachedBytes < 0) {
        return '--';
      }
      return _formatBytes(cachedBytes);
    }
    _primeReferenceFileSize(path: normalizedPath);
    return null;
  }

  void _primeReferenceFileSize({required String path}) {
    if (path.isEmpty ||
        _referenceFileSizeCache.containsKey(path) ||
        _referenceFileSizePending.contains(path)) {
      return;
    }
    _referenceFileSizePending.add(path);
    final file = XFile(path);
    file
        .length()
        .then((bytes) {
          _referenceFileSizePending.remove(path);
          _referenceFileSizeCache[path] = bytes;
          _scheduleRebuild();
        })
        .catchError((_) {
          _referenceFileSizePending.remove(path);
          _referenceFileSizeCache[path] = -1;
          _scheduleRebuild();
        });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final decimals = value >= 100 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }

  void _scheduleRebuild() {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  List<_ReferenceAssetItem> _resolvedReferenceAssets(
    DocumentDetailEntity detail,
  ) {
    final assets = <_ReferenceAssetItem>[];
    final seenPaths = <String>{};

    void addAsset({
      required String name,
      required String path,
      required String mime,
      String label = '',
    }) {
      final normalizedPath = _normalizeLocalPath(path);
      if (normalizedPath.isEmpty) {
        return;
      }
      final dedupeKey = normalizedPath.toLowerCase();
      if (!seenPaths.add(dedupeKey)) {
        return;
      }
      final resolvedMime = mime.trim().isEmpty
          ? normalizedPath.inferMimeType()
          : mime.trim();
      assets.add(
        _ReferenceAssetItem(
          name: name.trim().isEmpty
              ? normalizedPath.split('/').last
              : name.trim(),
          path: normalizedPath,
          mime: resolvedMime,
          label: label.trim(),
        ),
      );
    }

    final jsonRaw = _fieldValueByLabel(
      detail: detail,
      label: DocumentMetadataFieldLabels.referenceAssetsJson,
    );
    if ((jsonRaw ?? '').trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonRaw!);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) {
              continue;
            }
            final dynamicName = item['name'];
            final dynamicPath = item['path'];
            final dynamicMime = item['mime'];
            final dynamicLabel = item['label'];
            addAsset(
              name: dynamicName is String ? dynamicName : '',
              path: dynamicPath is String ? dynamicPath : '',
              mime: dynamicMime is String ? dynamicMime : '',
              label: dynamicLabel is String ? dynamicLabel : '',
            );
          }
        }
      } catch (e) {
        debugPrint('[DocumentDetail] Failed to parse asset list: $e');
      }
    }

    final legacyPath = _fieldValueByLabel(
      detail: detail,
      label: DocumentMetadataFieldLabels.referenceAssetPath,
    );
    if ((legacyPath ?? '').trim().isNotEmpty) {
      addAsset(
        name:
            _fieldValueByLabel(
              detail: detail,
              label: DocumentMetadataFieldLabels.referenceAssetName,
            ) ??
            '',
        path: legacyPath!,
        mime:
            _fieldValueByLabel(
              detail: detail,
              label: DocumentMetadataFieldLabels.referenceAssetMime,
            ) ??
            '',
        label:
            _fieldValueByLabel(
              detail: detail,
              label: DocumentMetadataFieldLabels.referenceAssetLabel,
            ) ??
            '',
      );
    }

    return assets;
  }

  bool _isPdfFile({required String? path, required String? mime}) {
    final normalizedMime = (mime ?? '').trim().toLowerCase();
    if (normalizedMime == LocalFileMimeTypes.pdf) {
      return true;
    }
    final normalizedPath = (path ?? '').trim().toLowerCase();
    return normalizedPath.endsWith('.pdf');
  }

  Future<void> _openFileFullscreen({
    required String filePath,
    required String title,
    String? mime,
  }) async {
    final normalizedPath = _normalizeLocalPath(filePath);
    if (normalizedPath.isEmpty) {
      _showSnack(context.l10n.documentFileUnavailable);
      return;
    }
    final isPdf = _isPdfFile(
      path: normalizedPath,
      mime: (mime ?? normalizedPath.inferMimeType()),
    );
    final imageProvider = isPdf
        ? null
        : resolveLocalFileImageProvider(normalizedPath);
    if (!isPdf && imageProvider == null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DocumentFilePreviewPage(
            filePath: normalizedPath,
            title: title,
            mimeType: mime ?? normalizedPath.inferMimeType(),
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _FullscreenFileViewer(
          title: title,
          imageProvider: imageProvider,
          pdfPath: isPdf ? normalizedPath : null,
          onShare: () => _shareLocalFile(normalizedPath, fileName: title),
        ),
      ),
    );
  }

  Widget _pdfPreviewPlaceholder() {
    final palette = context.appPalette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withValues(alpha: 0.24),
            Colors.black.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                color: palette.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.documentPdfPreview,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _embeddedPdfPreview(String filePath) {
    final normalizedPath = _normalizeLocalPath(filePath);
    if (normalizedPath.isEmpty) {
      return _pdfPreviewPlaceholder();
    }
    return IgnorePointer(
      ignoring: true,
      child: PdfViewer.file(
        normalizedPath,
        params: PdfViewerParams(
          backgroundColor: Colors.transparent,
          margin: 0,
          pageDropShadow: null,
          pageAnchor: PdfPageAnchor.center,
          pageAnchorEnd: PdfPageAnchor.center,
          calculateInitialZoom: (document, controller, fitZoom, coverZoom) {
            return fitZoom;
          },
        ),
      ),
    );
  }

  bool _hasPreviewAsset(DocumentDetailEntity detail) {
    final previewPath = _resolvePreviewImagePath(detail);
    if ((previewPath ?? '').trim().isEmpty) {
      return false;
    }
    if (_isPdfFile(path: previewPath, mime: previewPath?.inferMimeType())) {
      return true;
    }
    return resolveLocalFileImageProvider(previewPath) != null;
  }

  // TODO: Re-enable when Secure Share is ready
  // void _openSecureShare() { ... }

  Future<void> _shareLocalFile(String path, {String? fileName}) async {
    final l10n = context.l10n;
    final normalizedPath = _normalizeLocalPath(path);
    if (normalizedPath.isEmpty) {
      _showSnack(l10n.documentFileUnavailable);
      return;
    }
    final xFile = XFile(
      normalizedPath,
      name: (fileName ?? '').trim().isNotEmpty
          ? fileName!.trim()
          : normalizedPath.split('/').last,
    );
    try {
      final length = await xFile.length();
      if (length <= 0) {
        _showSnack(l10n.documentFileUnavailableOrEmpty);
        return;
      }
    } on PlatformException catch (error) {
      _showSnack(_shareErrorMessage(error));
      return;
    } catch (_) {
      _showSnack(l10n.documentFileUnavailableOnDevice);
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      final anchor = context.findRenderObject() as RenderBox?;
      final shareOrigin = anchor != null
          ? anchor.localToGlobal(Offset.zero) & anchor.size
          : null;
      await Share.shareXFiles(
        [xFile],
        subject: xFile.name,
        sharePositionOrigin: shareOrigin,
      );
    } on MissingPluginException {
      _showSnack(l10n.documentSharingUnavailableBuild);
    } on PlatformException catch (error) {
      _showSnack(_shareErrorMessage(error));
    } catch (_) {
      _showSnack(l10n.documentUnableShareFile);
    }
  }

  String _shareErrorMessage(PlatformException error) {
    final message = '${error.code} ${error.message ?? ''}'.toLowerCase();
    if (message.contains('not found') ||
        message.contains('no such file') ||
        message.contains('does not exist')) {
      return context.l10n.documentShareErrorFileNotFound;
    }
    if (message.contains('permission') || message.contains('denied')) {
      return context.l10n.documentShareErrorPermissionDenied;
    }
    if (message.contains('unavailable') || message.contains('not available')) {
      return context.l10n.documentShareErrorUnavailable;
    }
    return context.l10n.documentUnableShareFile;
  }

  String _normalizeLocalPath(String rawPath) {
    return LocalAssetPathResolver.resolveRuntimePathSync(rawPath);
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _fieldRow({
    required String label,
    required String value,
    required IconData icon,
    required Color tint,
    required VoidCallback onCopy,
  }) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: tint, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: Icon(Icons.copy_rounded, color: palette.textMuted, size: 19),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final detail = await _getDetailUseCase(
        GetDocumentDetailParams(documentId: widget.documentId),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.documentUnableLoad)));
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _onMenuActionSelected(_DocumentDetailMenuAction action) async {
    // TODO: Re-enable when Secure Share is ready
    // if (action == _DocumentDetailMenuAction.secureShare) {
    //   _openSecureShare();
    //   return;
    // }

    if (action == _DocumentDetailMenuAction.forceExpire) {
      await _forceExpireDocument();
      return;
    }

    if (action != _DocumentDetailMenuAction.remove) {
      return;
    }

    final detail = _detail;
    if (detail == null) {
      return;
    }

    final decision = await showDocumentRemovalPrompt(
      context: context,
      title: detail.issuer,
    );
    if (decision == null || !mounted) {
      return;
    }

    try {
      if (decision == DocumentRemovalDecision.archive) {
        await _archiveUseCase(ArchiveDocumentParams(documentId: detail.id));
        if (!mounted) {
          return;
        }
        _showSnack(context.l10n.documentArchived);
        Navigator.of(context).pop(true);
        return;
      }

      await _deleteUseCase(DeleteDocumentParams(documentId: detail.id));
      if (!mounted) {
        return;
      }
      _showSnack(context.l10n.documentDeleted);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack(context.l10n.documentUnableRemove);
    }
  }

  Future<void> _forceExpireDocument() async {
    final detail = _detail;
    if (detail == null || !_canForceExpire(detail)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = dialogContext.appPalette;
        return AlertDialog(
          backgroundColor: palette.surface,
          title: Text(dialogContext.l10n.documentForceExpireTitle),
          content: Text(dialogContext.l10n.documentForceExpireDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogContext.l10n.documentForceExpireConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final updated = await _forceExpireUseCase(
        ForceExpireDocumentParams(documentId: detail.id),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = updated;
      });
      _showSnack(context.l10n.documentForcedExpired);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack(context.l10n.documentUnableForceExpire);
    }
  }

  Future<void> _showDocumentActionsSheet(DocumentDetailEntity detail) async {
    final action = await showModalBottomSheet<_DocumentDetailMenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final palette = sheetContext.appPalette;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: palette.stroke),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: palette.strokeStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                _DocumentActionSheetTile(
                  icon: Icons.edit_outlined,
                  label: sheetContext.l10n.commonEdit,
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_DocumentDetailMenuAction.edit),
                ),
                if (_canForceExpire(detail))
                  _DocumentActionSheetTile(
                    icon: Icons.event_busy_rounded,
                    label: sheetContext.l10n.documentForceExpire,
                    onTap: () => Navigator.of(
                      sheetContext,
                    ).pop(_DocumentDetailMenuAction.forceExpire),
                  ),
                _DocumentActionSheetTile(
                  icon: Icons.delete_outline_rounded,
                  label: sheetContext.l10n.commonRemove,
                  danger: true,
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_DocumentDetailMenuAction.remove),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) {
      return;
    }
    if (action == _DocumentDetailMenuAction.edit) {
      await _openEdit();
      return;
    }
    await _onMenuActionSelected(action);
  }

  bool _canForceExpire(DocumentDetailEntity detail) {
    final expiry = detail.expiryDate;
    if (expiry == null) {
      return true;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(expiry.year, expiry.month, expiry.day);
    return !expiryDate.isBefore(today);
  }

  Future<void> _copy(String value) async {
    if (value.trim().isEmpty) {
      return;
    }
    final copiedLabel = context.l10n.commonCopied;
    await Clipboard.setData(ClipboardData(text: value));
    _showSnack(copiedLabel);
  }

  Widget _expiryStatusBanner(DocumentDetailEntity detail) {
    final expiry = detail.expiryDate!;
    final now = DateTime.now();
    final daysUntil = expiry.difference(now).inDays;
    final isExpired = daysUntil < 0;
    final isExpiringSoon = !isExpired && daysUntil <= 30;
    final isValid = !isExpired && !isExpiringSoon;

    final Color accentColor;
    final Color bgColor;
    final Color borderColor;
    final IconData icon;
    final String title;
    final String subtitle;

    if (isExpired) {
      accentColor = const Color(0xFFB42318);
      bgColor = const Color(0xFFFFF4F2);
      borderColor = const Color(0xFFF2B8B0);
      icon = Icons.error_rounded;
      title = 'Expired';
      final daysAgo = -daysUntil;
      subtitle = daysAgo == 0
          ? 'Expired today'
          : 'Expired $daysAgo day${daysAgo == 1 ? '' : 's'} ago';
    } else if (isExpiringSoon) {
      accentColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFF8EB);
      borderColor = const Color(0xFFF5DBA3);
      icon = Icons.schedule_rounded;
      title = 'Expiring Soon';
      subtitle = daysUntil == 0
          ? 'Expires today'
          : 'Expires in $daysUntil day${daysUntil == 1 ? '' : 's'}';
    } else {
      accentColor = const Color(0xFF059669);
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      icon = Icons.verified_rounded;
      title = 'Valid';
      subtitle = 'Expires on ${DateFormat.yMMMd().format(expiry)}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 21, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isValid
                        ? context.appPalette.textSecondary
                        : accentColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (!isValid)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                DateFormat.yMMMd().format(expiry),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _primaryDocumentCard(DocumentDetailEntity detail) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.appPalette.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: palette.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.documentPrimaryIdTitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  context.l10n.documentPrimaryIdSubtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: detail.isPrimary,
            onChanged: _isUpdatingPrimary ? null : _onPrimaryToggle,
            activeThumbColor: palette.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _onPrimaryToggle(bool value) async {
    final detail = _detail;
    if (detail == null || detail.category != DocumentCategoryType.identity) {
      return;
    }
    if (detail.isPrimary == value) {
      return;
    }

    setState(() {
      _isUpdatingPrimary = true;
      _detail = DocumentDetailEntity(
        id: detail.id,
        type: detail.type,
        category: detail.category,
        screenTitle: detail.screenTitle,
        issuer: detail.issuer,
        fileName: detail.fileName,
        structuredFields: detail.structuredFields,
        tags: detail.tags,
        uploadDate: detail.uploadDate,
        fileSizeLabel: detail.fileSizeLabel,
        isVerifiedScan: detail.isVerifiedScan,
        isFavorite: detail.isFavorite,
        isPrimary: value,
        status: detail.status,
        captureSource: detail.captureSource,
        scanPagesCount: detail.scanPagesCount,
        updatedAt: detail.updatedAt,
        referenceFilesCount: detail.referenceFilesCount,
        expiryDate: detail.expiryDate,
      );
    });

    try {
      await _setPrimaryUseCase(
        SetPrimaryIdentityDocumentParams(
          documentId: detail.id,
          isPrimary: value,
        ),
      );
      if (!mounted) {
        return;
      }
      _showSnack(
        value
            ? context.l10n.documentPrimarySet
            : context.l10n.documentPrimaryRemoved,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
      });
      _showSnack(context.l10n.documentPrimaryUnableUpdate);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPrimary = false;
        });
      }
    }
  }

  Future<void> _openEdit() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }

    final savedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DocumentEditNavigator.buildEditPage(detail: detail),
      ),
    );

    if (!mounted || (savedId ?? '').trim().isEmpty) {
      return;
    }
    if (savedId == '__deleted__') {
      Navigator.of(context).pop(true);
      return;
    }
    await _load();
    if (!mounted) {
      return;
    }
    _showSnack(context.l10n.documentUpdated);
  }
}

class _WorkDetailField {
  const _WorkDetailField({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
}

class _IdentityDetailInfo {
  const _IdentityDetailInfo({
    required this.typeLabel,
    required this.country,
    required this.countryLabel,
    required this.holderLabel,
    required this.fileTypeLabel,
  });

  final String typeLabel;
  final DocumentCountry country;
  final String countryLabel;
  final String holderLabel;
  final String fileTypeLabel;
}

class _IdentityFieldSection {
  const _IdentityFieldSection({required this.title, required this.fields});

  final String title;
  final List<_IdentityDisplayField> fields;
}

class _IdentityDisplayField {
  const _IdentityDisplayField({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
}

class _DocumentActionSheetTile extends StatelessWidget {
  const _DocumentActionSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final foreground = danger ? palette.danger : palette.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: danger ? palette.dangerSoft : palette.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityDetailTopBar extends StatelessWidget {
  const _IdentityDetailTopBar({
    required this.onBackTap,
    required this.canShare,
    required this.onShareTap,
    required this.onEditTap,
    required this.canForceExpire,
    required this.onForceExpireTap,
    required this.onRemoveTap,
  });

  final VoidCallback onBackTap;
  final bool canShare;
  final VoidCallback? onShareTap;
  final VoidCallback onEditTap;
  final bool canForceExpire;
  final VoidCallback onForceExpireTap;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Row(
      children: [
        _IdentityHeaderButton(
          icon: Icons.chevron_left_rounded,
          tooltip: context.l10n.commonBack,
          onTap: onBackTap,
        ),
        const Spacer(),
        _IdentityHeaderButton(
          icon: Icons.ios_share_rounded,
          tooltip: context.l10n.commonShare,
          onTap: canShare ? onShareTap : null,
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: context.l10n.commonMore,
          color: palette.surface,
          onSelected: (value) {
            if (value == 'edit') {
              onEditTap();
              return;
            }
            if (value == 'force_expire') {
              onForceExpireTap();
              return;
            }
            if (value == 'remove') {
              onRemoveTap();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(context.l10n.commonEdit),
                ],
              ),
            ),
            if (canForceExpire)
              PopupMenuItem(
                value: 'force_expire',
                child: Row(
                  children: [
                    const Icon(Icons.event_busy_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(context.l10n.documentForceExpire),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: palette.danger,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.commonRemove,
                    style: TextStyle(color: palette.danger),
                  ),
                ],
              ),
            ),
          ],
          icon: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: palette.stroke),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityHeaderButton extends StatelessWidget {
  const _IdentityHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? palette.surfaceSoft
            : palette.surfaceSoft.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: palette.stroke),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: enabled ? palette.textPrimary : palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityDetailPill extends StatelessWidget {
  const _IdentityDetailPill({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foregroundColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityActionButton extends StatelessWidget {
  const _IdentityActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.emphasized = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool emphasized;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final active = enabled && onTap != null;
    final foreground = danger
        ? palette.danger
        : emphasized
        ? Colors.white
        : palette.textPrimary;
    final background = emphasized
        ? palette.primary
        : danger
        ? palette.dangerSoft
        : palette.surface;

    return Material(
      color: active ? background : palette.surfaceSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: danger
                  ? palette.dangerStroke
                  : emphasized
                  ? palette.primary
                  : palette.stroke,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? foreground : palette.textMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: active ? foreground : palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityDetailScheme {
  const _IdentityDetailScheme({
    required this.background,
    required this.border,
    required this.accent,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color accent;
  final IconData icon;
}

class _IdentityStatusPresentation {
  const _IdentityStatusPresentation({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
}

_IdentityDetailScheme _identityDetailScheme(DocumentType type) {
  return switch (type) {
    DocumentType.passport => const _IdentityDetailScheme(
      background: Color(0xFFFFEEF1),
      border: Color(0xFFF1D5DA),
      accent: Color(0xFF7B3341),
      icon: Icons.travel_explore_rounded,
    ),
    DocumentType.idCard => const _IdentityDetailScheme(
      background: Color(0xFFEAF0FF),
      border: Color(0xFFD8E2FF),
      accent: Color(0xFF2353B8),
      icon: Icons.badge_outlined,
    ),
    DocumentType.driversLicense => const _IdentityDetailScheme(
      background: Color(0xFFE7F6EF),
      border: Color(0xFFCDEBDD),
      accent: Color(0xFF187C63),
      icon: Icons.directions_car_filled_rounded,
    ),
    DocumentType.other => const _IdentityDetailScheme(
      background: Color(0xFFF6F1E3),
      border: Color(0xFFE9E0C8),
      accent: Color(0xFF6D6250),
      icon: Icons.description_rounded,
    ),
  };
}

_IdentityStatusPresentation _identityDetailStatus(
  BuildContext context,
  DocumentDetailEntity detail,
) {
  return switch (detail.status) {
    IdentityDocumentStatus.valid => _IdentityStatusPresentation(
      label: context.l10n.identityStatusOk,
      icon: Icons.check_circle_rounded,
      foreground: const Color(0xFF0A8F55),
      background: const Color(0xFFDDF4E8),
    ),
    IdentityDocumentStatus.expiringSoon => _IdentityStatusPresentation(
      label: detail.expiryDate == null
          ? context.l10n.identityDetailStatusExpiring.toUpperCase()
          : context.l10n
                .identityDetailStatusExpiresIn(
                  _identityDaysUntil(detail.expiryDate!),
                )
                .toUpperCase(),
      icon: Icons.schedule_rounded,
      foreground: const Color(0xFFD48400),
      background: const Color(0xFFFBE9B9),
    ),
    IdentityDocumentStatus.expired => _IdentityStatusPresentation(
      label: context.l10n.identityStatusExpired.toUpperCase(),
      icon: Icons.error_rounded,
      foreground: const Color(0xFFDC2626),
      background: const Color(0xFFFDE5E5),
    ),
  };
}

int _identityDaysUntil(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  return target.difference(today).inDays.clamp(0, 9999);
}

Color _identityDetailTint(
  BuildContext context,
  Color lightColor,
  Color accent, {
  double darkAlpha = 0.18,
}) {
  final palette = context.appPalette;
  if (Theme.of(context).brightness != Brightness.dark) {
    return lightColor;
  }
  return Color.alphaBlend(accent.withValues(alpha: darkAlpha), palette.surface);
}

String _identityFieldLabel(
  BuildContext context,
  String fallback,
  String? canonical,
) {
  final label = switch (canonical) {
    DocumentMetadataFieldLabels.documentNumber =>
      context.l10n.identityFieldDocumentNumber,
    DocumentMetadataFieldLabels.issuingCountry =>
      context.l10n.identityFieldIssuingCountry,
    DocumentMetadataFieldLabels.expiryDate => context.l10n.identityFieldExpires,
    DocumentMetadataFieldLabels.nationality =>
      context.l10n.identityFieldNationality,
    DocumentMetadataFieldLabels.givenName =>
      context.l10n.identityFieldGivenName,
    DocumentMetadataFieldLabels.familyName =>
      context.l10n.identityFieldFamilyName,
    DocumentMetadataFieldLabels.birthDate =>
      context.l10n.identityFieldDateOfBirth,
    DocumentMetadataFieldLabels.sex => context.l10n.identityFieldSex,
    DocumentMetadataFieldLabels.holderRelation =>
      context.l10n.identityFieldHolder,
    DocumentMetadataFieldLabels.ageOver18 =>
      context.l10n.identityFieldAgeOver18,
    _ => fallback,
  };
  return label.trim().replaceAll('_', ' ').toUpperCase();
}

IconData _identityFieldIcon(String fallback, String? canonical) {
  return switch (canonical) {
    DocumentMetadataFieldLabels.documentNumber => Icons.tag_rounded,
    DocumentMetadataFieldLabels.issuingCountry => Icons.flag_outlined,
    DocumentMetadataFieldLabels.expiryDate => Icons.event_outlined,
    DocumentMetadataFieldLabels.nationality => Icons.public_rounded,
    DocumentMetadataFieldLabels.givenName ||
    DocumentMetadataFieldLabels.familyName => Icons.person_outline_rounded,
    DocumentMetadataFieldLabels.birthDate => Icons.cake_outlined,
    DocumentMetadataFieldLabels.sex => Icons.wc_rounded,
    DocumentMetadataFieldLabels.holderRelation => Icons.group_outlined,
    DocumentMetadataFieldLabels.ageOver18 => Icons.verified_user_outlined,
    _ => fallback.documentFieldIcon,
  };
}

Color _identityFieldTint(String? canonical) {
  return switch (canonical) {
    DocumentMetadataFieldLabels.documentNumber => const Color(0xFF2353B8),
    DocumentMetadataFieldLabels.issuingCountry => const Color(0xFF7B3341),
    DocumentMetadataFieldLabels.expiryDate => const Color(0xFFD48400),
    DocumentMetadataFieldLabels.nationality => const Color(0xFF187C63),
    DocumentMetadataFieldLabels.givenName ||
    DocumentMetadataFieldLabels.familyName => const Color(0xFF5B45B8),
    DocumentMetadataFieldLabels.birthDate => const Color(0xFF6D6250),
    DocumentMetadataFieldLabels.sex => const Color(0xFF187C63),
    DocumentMetadataFieldLabels.holderRelation => const Color(0xFF2353B8),
    DocumentMetadataFieldLabels.ageOver18 => const Color(0xFF0A8F55),
    _ => const Color(0xFF6D6250),
  };
}

DocumentCountry _parseDocumentCountry(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return DocumentCountry.unknown;
  }
  if (normalized.contains('france') ||
      normalized == 'fr' ||
      normalized == 'fra') {
    return DocumentCountry.france;
  }
  if (normalized.contains('germany') ||
      normalized.contains('deutschland') ||
      normalized == 'de') {
    return DocumentCountry.germany;
  }
  if (normalized.contains('italy') ||
      normalized.contains('italia') ||
      normalized == 'it') {
    return DocumentCountry.italy;
  }
  if (normalized.contains('spain') ||
      normalized.contains('espana') ||
      normalized == 'es') {
    return DocumentCountry.spain;
  }
  if (normalized.contains('tunisia') ||
      normalized.contains('tunisie') ||
      normalized == 'tn') {
    return DocumentCountry.tunisia;
  }
  if (normalized.contains('turkey') || normalized == 'tr') {
    return DocumentCountry.turkey;
  }
  if (normalized.contains('canada') || normalized == 'ca') {
    return DocumentCountry.canada;
  }
  if (normalized.contains('switzerland') || normalized == 'ch') {
    return DocumentCountry.switzerland;
  }
  if (normalized.contains('united states') ||
      normalized == 'us' ||
      normalized == 'usa') {
    return DocumentCountry.unitedStates;
  }
  if (normalized.contains('united kingdom') ||
      normalized == 'uk' ||
      normalized == 'gb') {
    return DocumentCountry.unitedKingdom;
  }
  if (normalized.contains('emirates') ||
      normalized == 'ae' ||
      normalized == 'uae') {
    return DocumentCountry.unitedArabEmirates;
  }
  if (normalized.contains('europe')) {
    return DocumentCountry.europeanUnion;
  }
  return DocumentCountry.unknown;
}

class _DetailCountryFlag extends StatelessWidget {
  const _DetailCountryFlag({required this.country, required this.size});

  final DocumentCountry country;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: size.width,
      height: size.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: palette.surface, width: 1.5),
      ),
      child: CustomPaint(painter: _DetailCountryFlagPainter(country)),
    );
  }
}

class _DetailCountryFlagPainter extends CustomPainter {
  const _DetailCountryFlagPainter(this.country);

  final DocumentCountry country;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    void rect(Color color, Rect rect) {
      paint.color = color;
      canvas.drawRect(rect, paint);
    }

    void circle(Color color, Offset center, double radius) {
      paint.color = color;
      canvas.drawCircle(center, radius, paint);
    }

    void star(Color color, Offset center, double outerRadius) {
      paint.color = color;
      final innerRadius = outerRadius * 0.42;
      final path = Path();
      for (var index = 0; index < 10; index++) {
        final radius = index.isEven ? outerRadius : innerRadius;
        final angle = -math.pi / 2 + index * math.pi / 5;
        final point = Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    switch (country) {
      case DocumentCountry.france:
      case DocumentCountry.europeanUnion:
        rect(
          const Color(0xFF2449A8),
          Rect.fromLTWH(0, 0, size.width / 3, size.height),
        );
        rect(
          Colors.white,
          Rect.fromLTWH(size.width / 3, 0, size.width / 3, size.height),
        );
        rect(
          const Color(0xFFE04747),
          Rect.fromLTWH(size.width * 2 / 3, 0, size.width / 3, size.height),
        );
        break;
      case DocumentCountry.germany:
        rect(
          const Color(0xFF171717),
          Rect.fromLTWH(0, 0, size.width, size.height / 3),
        );
        rect(
          const Color(0xFFD13A32),
          Rect.fromLTWH(0, size.height / 3, size.width, size.height / 3),
        );
        rect(
          const Color(0xFFFFCE45),
          Rect.fromLTWH(0, size.height * 2 / 3, size.width, size.height / 3),
        );
        break;
      case DocumentCountry.italy:
        rect(
          const Color(0xFF21966C),
          Rect.fromLTWH(0, 0, size.width / 3, size.height),
        );
        rect(
          Colors.white,
          Rect.fromLTWH(size.width / 3, 0, size.width / 3, size.height),
        );
        rect(
          const Color(0xFFD64747),
          Rect.fromLTWH(size.width * 2 / 3, 0, size.width / 3, size.height),
        );
        break;
      case DocumentCountry.tunisia:
        rect(const Color(0xFFE34343), Offset.zero & size);
        final diskCenter = size.center(Offset.zero);
        circle(Colors.white, diskCenter, size.shortestSide * 0.34);
        final crescentCenter = Offset(size.width * 0.46, size.height * 0.5);
        circle(
          const Color(0xFFE34343),
          crescentCenter,
          size.shortestSide * 0.16,
        );
        circle(
          Colors.white,
          Offset(size.width * 0.51, size.height * 0.5),
          size.shortestSide * 0.13,
        );
        star(
          const Color(0xFFE34343),
          Offset(size.width * 0.61, size.height * 0.5),
          size.shortestSide * 0.08,
        );
        break;
      case DocumentCountry.turkey:
        rect(const Color(0xFFE34343), Offset.zero & size);
        circle(
          Colors.white,
          Offset(size.width * 0.42, size.height * 0.5),
          size.shortestSide * 0.25,
        );
        circle(
          const Color(0xFFE34343),
          Offset(size.width * 0.49, size.height * 0.5),
          size.shortestSide * 0.2,
        );
        star(
          Colors.white,
          Offset(size.width * 0.66, size.height * 0.5),
          size.shortestSide * 0.09,
        );
        break;
      case DocumentCountry.unitedStates:
      case DocumentCountry.unitedKingdom:
        rect(const Color(0xFFF7F7F2), Offset.zero & size);
        final stripeHeight = size.height / 7;
        for (var index = 0; index < 7; index += 2) {
          rect(
            const Color(0xFFD94747),
            Rect.fromLTWH(0, stripeHeight * index, size.width, stripeHeight),
          );
        }
        rect(
          const Color(0xFF2449A8),
          Rect.fromLTWH(0, 0, size.width * 0.46, size.height * 0.55),
        );
        break;
      case DocumentCountry.spain:
        rect(
          const Color(0xFFC93A35),
          Rect.fromLTWH(0, 0, size.width, size.height * 0.26),
        );
        rect(
          const Color(0xFFFFD35A),
          Rect.fromLTWH(0, size.height * 0.26, size.width, size.height * 0.48),
        );
        rect(
          const Color(0xFFC93A35),
          Rect.fromLTWH(0, size.height * 0.74, size.width, size.height * 0.26),
        );
        break;
      case DocumentCountry.canada:
      case DocumentCountry.switzerland:
        rect(const Color(0xFFE34343), Offset.zero & size);
        rect(
          Colors.white,
          Rect.fromLTWH(size.width * 0.36, 0, size.width * 0.28, size.height),
        );
        break;
      case DocumentCountry.unitedArabEmirates:
        rect(
          const Color(0xFFE34343),
          Rect.fromLTWH(0, 0, size.width * 0.26, size.height),
        );
        rect(
          const Color(0xFF259260),
          Rect.fromLTWH(
            size.width * 0.26,
            0,
            size.width * 0.74,
            size.height / 3,
          ),
        );
        rect(
          Colors.white,
          Rect.fromLTWH(
            size.width * 0.26,
            size.height / 3,
            size.width * 0.74,
            size.height / 3,
          ),
        );
        rect(
          const Color(0xFF1C1C1C),
          Rect.fromLTWH(
            size.width * 0.26,
            size.height * 2 / 3,
            size.width * 0.74,
            size.height / 3,
          ),
        );
        break;
      case DocumentCountry.unknown:
        rect(const Color(0xFFE8E5DE), Offset.zero & size);
        paint
          ..color = const Color(0xFF9A9388)
          ..strokeWidth = 1.2;
        canvas.drawLine(
          Offset(size.width * 0.24, size.height * 0.5),
          Offset(size.width * 0.76, size.height * 0.5),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DetailCountryFlagPainter oldDelegate) {
    return oldDelegate.country != country;
  }
}

enum _DocumentDetailMenuAction { edit, forceExpire, remove }

_PreviewVisual _previewVisual(DocumentType type) {
  return switch (type) {
    DocumentType.passport => const _PreviewVisual(
      start: Color(0xFF3B4E68),
      end: Color(0xFF7EC0E4),
      icon: Icons.book_rounded,
    ),
    DocumentType.idCard => const _PreviewVisual(
      start: Color(0xFF0E2433),
      end: Color(0xFF245260),
      icon: Icons.badge_rounded,
    ),
    DocumentType.driversLicense => const _PreviewVisual(
      start: Color(0xFF4B5563),
      end: Color(0xFF9CA3AF),
      icon: Icons.directions_car_filled_rounded,
    ),
    DocumentType.other => const _PreviewVisual(
      start: Color(0xFF1F2937),
      end: Color(0xFF374151),
      icon: Icons.description_rounded,
    ),
  };
}

class _PreviewVisual {
  const _PreviewVisual({
    required this.start,
    required this.end,
    required this.icon,
  });

  final Color start;
  final Color end;
  final IconData icon;
}

class _ReferenceAssetItem {
  const _ReferenceAssetItem({
    required this.name,
    required this.path,
    required this.mime,
    required this.label,
  });

  final String name;
  final String path;
  final String mime;
  final String label;

  String get normalizedLabel => label.trim();
  bool get hasLabel => normalizedLabel.isNotEmpty;
  String get displayTitle => hasLabel ? normalizedLabel : name;

  bool get isImage {
    final normalizedMime = mime.trim().toLowerCase();
    if (normalizedMime.startsWith('image/')) {
      return true;
    }
    final normalizedPath = path.trim().toLowerCase();
    return normalizedPath.endsWith('.png') ||
        normalizedPath.endsWith('.jpg') ||
        normalizedPath.endsWith('.jpeg') ||
        normalizedPath.endsWith('.webp') ||
        normalizedPath.endsWith('.heic');
  }

  bool get isPdf {
    final normalizedMime = mime.trim().toLowerCase();
    if (normalizedMime == LocalFileMimeTypes.pdf) {
      return true;
    }
    return path.trim().toLowerCase().endsWith('.pdf');
  }

  String get typeLabel {
    return resolveFileTypeLabel(path: path, mime: mime);
  }
}

class _FullscreenFileViewer extends StatefulWidget {
  const _FullscreenFileViewer({
    required this.title,
    required this.imageProvider,
    required this.pdfPath,
    required this.onShare,
  }) : assert(
         imageProvider != null || pdfPath != null,
         'Either imageProvider or pdfPath must be provided.',
       );

  final String title;
  final ImageProvider<Object>? imageProvider;
  final String? pdfPath;
  final VoidCallback onShare;

  @override
  State<_FullscreenFileViewer> createState() => _FullscreenFileViewerState();
}

class _FullscreenFileViewerState extends State<_FullscreenFileViewer> {
  @override
  Widget build(BuildContext context) {
    final pdfPath = widget.pdfPath;
    final imageProvider = widget.imageProvider;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: GenericAppBar(
        backgroundColor: Colors.black,
        centerTitle: false,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: widget.title.trim().isEmpty
            ? context.l10n.identityYourDocumentsTitle
            : widget.title,
        titleStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleColor: Colors.white,
        iconColor: Colors.white,
        iconBackgroundColor: Colors.white.withValues(alpha: 0.12),
        actionIcon: Icons.share_outlined,
        actionTooltip: context.l10n.commonShare,
        onActionPressed: widget.onShare,
        showDivider: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (pdfPath != null)
            PdfViewer.file(
              pdfPath,
              params: PdfViewerParams(
                backgroundColor: Colors.black,
                margin: 0,
                pageDropShadow: null,
                pageAnchor: PdfPageAnchor.center,
                pageAnchorEnd: PdfPageAnchor.center,
                calculateInitialZoom:
                    (document, controller, fitZoom, coverZoom) {
                      return coverZoom;
                    },
              ),
            )
          else
            InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: SizedBox.expand(
                child: Image(
                  image: imageProvider!,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          context.l10n.documentUnableRenderImagePreview,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
