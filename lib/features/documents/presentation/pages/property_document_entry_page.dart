import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class PropertyDocumentEntryPage extends StatefulWidget {
  const PropertyDocumentEntryPage({
    super.key,
    required this.propertyId,
    required this.propertyName,
    this.initialAssetType,
    this.documentToEdit,
    CreateScannedDocument? createScannedDocument,
    UpdateDocument? updateDocument,
  }) : _createScannedDocument = createScannedDocument,
       _updateDocument = updateDocument;

  final String propertyId;
  final String propertyName;
  final PropertyAssetType? initialAssetType;
  final DocumentDetailEntity? documentToEdit;
  final CreateScannedDocument? _createScannedDocument;
  final UpdateDocument? _updateDocument;

  @override
  State<PropertyDocumentEntryPage> createState() =>
      _PropertyDocumentEntryPageState();
}

class _PropertyDocumentEntryPageState extends State<PropertyDocumentEntryPage> {
  static const _maxUploadBytes = 10 * 1024 * 1024;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _paymentAmountController =
      TextEditingController();
  final Map<String, TextEditingController> _uploadTitleControllers =
      <String, TextEditingController>{};

  PropertyAssetType? _selectedAssetType;
  DateTime? _issueDate;
  DateTime? _paymentDate;

  bool _isSaving = false;
  bool _isPickingUpload = false;

  String _uploadedFilePath = '';
  String _uploadedFileName = '';
  List<_SelectedPropertyUpload> _selectedUploads =
      const <_SelectedPropertyUpload>[];

  CreateScannedDocument get _createUseCase =>
      widget._createScannedDocument ?? getIt();
  UpdateDocument get _updateUseCase => widget._updateDocument ?? getIt();
  bool get _isEditing => widget.documentToEdit != null;

  @override
  void initState() {
    super.initState();
    _selectedAssetType = widget.initialAssetType;
    _bootstrapFromExistingDocument();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _paymentAmountController.dispose();
    for (final controller in _uploadTitleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploads = _activeUploads;
    final uploadCount = uploads.length;
    final canSave =
        !_isSaving &&
        !_isPickingUpload &&
        uploadCount > 0 &&
        _hasValidTitles(uploads);

    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.surface,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: _isEditing
            ? context.l10n.commonEdit
            : context.l10n.propertyDocumentEntryTitle,
        titleStyle: TextStyle(
          fontSize: 18.5,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            border: Border(
              top: BorderSide(color: context.appPalette.strokeStrong),
            ),
          ),
          child: FilledButton.icon(
            onPressed: canSave ? _save : null,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.save_outlined, size: 20),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: context.appPalette.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.appPalette.primary.withValues(
                alpha: 0.45,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            label: Text(
              _isEditing
                  ? context.l10n.commonSave
                  : context.l10n.propertyDocumentSaveAction,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _sectionTitle(
                  context,
                  icon: Icons.description_outlined,
                  title: context.l10n.propertyDocumentInfoSection,
                ),
                const SizedBox(height: 10),
                _fieldLabel(
                  context,
                  context.l10n.propertyDocumentCategoryLabel,
                ),
                SizedBox(height: 7),
                _categoryDropdown(context),
                if (uploadCount > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.propertyDocumentSharedCategoryHint,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textSecondary,
                      height: 1.28,
                    ),
                  ),
                ],
                const SizedBox(height: 13),
                _fieldLabel(
                  context,
                  context.l10n.propertyDocumentIssueDateLabel,
                ),
                const SizedBox(height: 7),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(22),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: context.appPalette.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: context.appPalette.stroke),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _issueDate == null
                                ? context.l10n.idEntryDateFormatHint
                                : DateFormat.yMd(
                                    Localizations.localeOf(
                                      context,
                                    ).toLanguageTag(),
                                  ).format(_issueDate!),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _issueDate == null
                                  ? context.appPalette.textMuted
                                  : context.appPalette.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: context.appPalette.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _uploadCard(context),
                if (uploadCount > 0) ...[
                  const SizedBox(height: 16),
                  if (uploadCount == 1) ...[
                    _fieldLabel(
                      context,
                      context.l10n.propertyDocumentTitleLabel,
                    ),
                    const SizedBox(height: 7),
                    _titleInput(
                      context,
                      controller: _titleControllerFor(uploads.first),
                    ),
                  ] else ...[
                    _sectionTitle(
                      context,
                      icon: Icons.view_list_rounded,
                      title:
                          context.l10n.propertyDocumentSelectedDocumentsTitle,
                    ),
                    const SizedBox(height: 10),
                    ...uploads.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == uploads.length - 1 ? 0 : 10,
                        ),
                        child: _selectedUploadCard(
                          context,
                          upload: entry.value,
                          index: entry.key,
                          totalUploads: uploads.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PropertyAssetType>(
          value: _selectedAssetType,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 24,
            color: context.appPalette.primary,
          ),
          isExpanded: true,
          hint: Text(
            context.l10n.propertyDocumentCategoryHint,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textMuted,
            ),
          ),
          items: PropertyAssetType.values
              .map(
                (type) => DropdownMenuItem<PropertyAssetType>(
                  value: type,
                  child: Text(
                    _assetTypeLabel(context, type),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            setState(() {
              _selectedAssetType = value;
              if (value != PropertyAssetType.payments) {
                _paymentAmountController.clear();
                _paymentDate = null;
              }
            });
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 21, color: context.appPalette.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: context.appPalette.textPrimary,
            letterSpacing: -0.12,
          ),
        ),
      ],
    );
  }

  Widget _uploadCard(BuildContext context) {
    final uploads = _activeUploads;
    final uploadCount = uploads.length;
    final primaryUpload = uploadCount == 0 ? null : uploads.first;
    final subtitle = uploadCount == 0
        ? context.l10n.idEntryMultipleFilesHint
        : uploadCount == 1
        ? primaryUpload!.name
        : '${context.l10n.documentFilesCount(uploadCount)} • ${primaryUpload!.name}';
    return InkWell(
      onTap: _isSaving ? null : _pickUploadFile,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: uploadCount == 0
              ? context.appPalette.surface
              : context.appPalette.primarySoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appPalette.stroke, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.appPalette.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: _isPickingUpload
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.appPalette.primary,
                        ),
                      ),
                    )
                  : Icon(
                      uploadCount == 0
                          ? Icons.upload_file_rounded
                          : Icons.check_circle_rounded,
                      size: 22,
                      color: context.appPalette.primary,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.propertyDocumentSelectFile,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    uploadCount == 0
                        ? '${context.l10n.propertyDocumentUploadHint}\n${context.l10n.idEntryMultipleFilesHint}'
                        : subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: uploadCount == 0
                          ? context.appPalette.textSecondary
                          : context.appPalette.primary,
                      height: 1.28,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: context.appPalette.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _outlinedInput({Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: color ?? context.appPalette.stroke),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: context.appPalette.primary,
      ),
    );
  }

  Widget _titleInput(
    BuildContext context, {
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.appPalette.textPrimary,
      ),
      decoration: _textFieldDecoration(
        context,
        hintText: context.l10n.propertyDocumentTitleHint,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: context.appPalette.primary),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _issueDate = picked;
    });
  }

  Widget _selectedUploadCard(
    BuildContext context, {
    required _SelectedPropertyUpload upload,
    required int index,
    required int totalUploads,
  }) {
    final categoryLabel = _selectedAssetType == null
        ? context.l10n.propertyDocumentCategoryHint
        : _assetTypeLabel(context, _selectedAssetType!);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.appPalette.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: context.appPalette.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.propertyDocumentSelectedDocumentLabel(
                        index + 1,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      upload.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isEditing && totalUploads > 1)
                IconButton(
                  onPressed: () => _removeUpload(upload),
                  splashRadius: 18,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: context.appPalette.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaChip(
                context,
                icon: Icons.folder_outlined,
                label: categoryLabel,
              ),
              _metaChip(
                context,
                icon: Icons.insert_drive_file_outlined,
                label: resolveFileTypeLabel(
                  path: upload.path,
                  mime: upload.mime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _fieldLabel(context, context.l10n.propertyDocumentTitleLabel),
          const SizedBox(height: 7),
          _titleInput(context, controller: _titleControllerFor(upload)),
        ],
      ),
    );
  }

  Widget _metaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.appPalette.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.appPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickUploadFile() async {
    if (_isPickingUpload || _isSaving) {
      return;
    }
    setState(() {
      _isPickingUpload = true;
    });
    try {
      const typeGroups = <XTypeGroup>[
        XTypeGroup(
          label: 'documents',
          extensions: [
            'pdf',
            'jpg',
            'jpeg',
            'png',
            'doc',
            'docx',
            'xls',
            'xlsx',
            'ppt',
            'pptx',
            'txt',
            'rtf',
            'csv',
          ],
          uniformTypeIdentifiers: [
            'com.adobe.pdf',
            'public.jpeg',
            'public.png',
            'com.microsoft.word.doc',
            'org.openxmlformats.wordprocessingml.document',
            'com.microsoft.excel.xls',
            'org.openxmlformats.spreadsheetml.sheet',
            'com.microsoft.powerpoint.ppt',
            'org.openxmlformats.presentationml.presentation',
            'public.plain-text',
            'public.rtf',
            'public.comma-separated-values-text',
          ],
        ),
      ];
      final selectedFiles = await (_isEditing
          ? () async {
              final selected = await openFile(acceptedTypeGroups: typeGroups);
              return selected == null ? const <XFile>[] : <XFile>[selected];
            }()
          : openFiles(acceptedTypeGroups: typeGroups));
      if (selectedFiles.isEmpty) {
        return;
      }

      final uploads = <_SelectedPropertyUpload>[];
      for (final selected in selectedFiles) {
        final sourcePath = selected.path.trim();
        if (sourcePath.isEmpty) {
          continue;
        }
        final sourceFile = File(sourcePath);
        if (!await sourceFile.exists()) {
          if (!mounted) {
            return;
          }
          _showToast(context.l10n.propertyDocumentFileMissing);
          return;
        }

        final fileSize = await sourceFile.length();
        if (fileSize > _maxUploadBytes) {
          if (!mounted) {
            return;
          }
          _showToast(context.l10n.propertyDocumentFileTooLarge);
          return;
        }

        final persisted = await _persistUploadFile(sourcePath: sourcePath);
        if ((persisted ?? '').trim().isEmpty) {
          if (!mounted) {
            return;
          }
          _showToast(context.l10n.propertyDocumentPersistFailed);
          return;
        }
        final normalized = persisted!.trim();
        uploads.add(
          _SelectedPropertyUpload(
            path: normalized,
            name: _fileNameFromPath(normalized),
            mime: normalized.inferMimeType(),
          ),
        );
      }
      if (uploads.isEmpty) {
        return;
      }

      if (!mounted) {
        return;
      }
      _setSelectedUploads(uploads);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast(context.l10n.propertyDocumentSelectFileFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isPickingUpload = false;
        });
      }
    }
  }

  void _bootstrapFromExistingDocument() {
    final detail = widget.documentToEdit;
    if (detail == null) {
      return;
    }

    final title = _detailFieldValue(detail, const ['document title']);
    if (title.isNotEmpty) {
      _titleController.text = title;
    }

    final assetTypeValue = _detailFieldValue(detail, const [
      DocumentMetadataFieldLabels.propertyAssetType,
    ]);
    final matchedAssetType = PropertyAssetType.values.where(
      (type) => type.name == assetTypeValue.trim().toLowerCase(),
    );
    if (matchedAssetType.isNotEmpty) {
      _selectedAssetType = matchedAssetType.first;
    }

    _issueDate = _parseStoredDate(
      _detailFieldValue(detail, const [
        DocumentMetadataFieldLabels.propertyIssueDate,
      ]),
    );

    _paymentAmountController.text = _paymentAmountInputValue(
      _detailFieldValue(detail, const [
        DocumentMetadataFieldLabels.propertyPaymentAmount,
      ]),
    );
    _paymentDate = _parseStoredDate(
      _detailFieldValue(detail, const [
        DocumentMetadataFieldLabels.propertyPaymentDate,
      ]),
    );

    final existingFilePath = _detailFieldValue(detail, const [
      DocumentMetadataFieldLabels.referenceAssetPath,
      DocumentMetadataFieldLabels.frontImagePath,
      DocumentMetadataFieldLabels.previewImagePath,
    ]);
    final existingFileName = _detailFieldValue(detail, const [
      DocumentMetadataFieldLabels.referenceAssetName,
    ]);
    _uploadedFilePath = existingFilePath;
    _uploadedFileName = existingFileName.isNotEmpty
        ? existingFileName
        : (existingFilePath.isNotEmpty
              ? _fileNameFromPath(existingFilePath)
              : detail.fileName);
    if (_uploadedFilePath.trim().isNotEmpty) {
      _selectedUploads = <_SelectedPropertyUpload>[
        _SelectedPropertyUpload(
          path: _uploadedFilePath.trim(),
          name: _uploadedFileName.trim().isEmpty
              ? _fileNameFromPath(_uploadedFilePath)
              : _uploadedFileName.trim(),
          mime: _uploadedFilePath.inferMimeType(),
        ),
      ];
      _syncUploadTitleControllers(
        _selectedUploads,
        initialTitles: <String, String>{
          _uploadedFilePath.trim(): _titleController.text.trim(),
        },
      );
    }
  }

  Future<String?> _persistUploadFile({required String sourcePath}) async {
    final propertySlug = _slugify(widget.propertyName);
    return LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: sourcePath,
      directoryName: 'property_document_assets',
      fileNamePrefix: 'property_doc_$propertySlug',
    );
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    final selectedAssetType = _selectedAssetType;
    if (selectedAssetType == null) {
      _showToast(context.l10n.propertyDocumentCategoryRequired);
      return;
    }

    final uploads = _activeUploads;
    if (uploads.isEmpty) {
      _showToast(context.l10n.propertyDocumentUploadRequired);
      return;
    }
    if (!_hasValidTitles(uploads)) {
      _showToast(context.l10n.propertyDocumentTitleRequired);
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final issueIso = _issueDate == null
          ? ''
          : DateFormat('yyyy-MM-dd').format(_issueDate!);
      final paymentIso = _paymentDate == null
          ? ''
          : DateFormat('yyyy-MM-dd').format(_paymentDate!);
      final paymentAmount = _formatPaymentAmount(
        _paymentAmountController.text.trim(),
      );
      final categoryLabel = _assetTypeLabel(context, selectedAssetType);
      final savedIds = <String>[];
      for (final upload in uploads) {
        final documentName = _resolvedDocumentName(
          explicitTitle: _resolvedUploadTitle(upload),
          upload: upload,
        );
        final referencePayload = <Map<String, String>>[
          {
            'name': upload.name,
            'path': upload.path,
            'mime': upload.mime,
            'label': categoryLabel,
          },
        ];

        final structuredFields = <Map<String, String>>[
          {'label': 'Document Category', 'value': categoryLabel},
          {'label': 'Document Title', 'value': documentName},
          {
            'label': DocumentMetadataFieldLabels.propertyId,
            'value': widget.propertyId,
          },
          {
            'label': DocumentMetadataFieldLabels.propertyName,
            'value': widget.propertyName,
          },
          {
            'label': DocumentMetadataFieldLabels.propertyRecordType,
            'value': 'document',
          },
          {
            'label': DocumentMetadataFieldLabels.propertyAssetType,
            'value': selectedAssetType.name,
          },
          {
            'label': DocumentMetadataFieldLabels.propertyIssueDate,
            'value': issueIso,
          },
          {
            'label': DocumentMetadataFieldLabels.propertyPaymentAmount,
            'value': paymentAmount,
          },
          {
            'label': DocumentMetadataFieldLabels.propertyPaymentDate,
            'value': paymentIso,
          },
          {
            'label': DocumentMetadataFieldLabels.frontImagePath,
            'value': upload.path,
          },
          {
            'label': DocumentMetadataFieldLabels.previewImagePath,
            'value': upload.path,
          },
          {
            'label': DocumentMetadataFieldLabels.previewImageEnabled,
            'value': 'true',
          },
          {
            'label': DocumentMetadataFieldLabels.referenceAssetsJson,
            'value': jsonEncode(referencePayload),
          },
          {
            'label': DocumentMetadataFieldLabels.referenceAssetName,
            'value': upload.name,
          },
          {
            'label': DocumentMetadataFieldLabels.referenceAssetPath,
            'value': upload.path,
          },
          {
            'label': DocumentMetadataFieldLabels.referenceAssetMime,
            'value': upload.mime,
          },
          {
            'label': DocumentMetadataFieldLabels.referenceAssetLabel,
            'value': categoryLabel,
          },
          {
            'label': DocumentMetadataFieldLabels.claimPropertyId,
            'value': widget.propertyId,
          },
          {
            'label': DocumentMetadataFieldLabels.claimPropertyName,
            'value': widget.propertyName,
          },
          {
            'label': DocumentMetadataFieldLabels.claimPropertyRecordType,
            'value': 'document',
          },
          {
            'label': DocumentMetadataFieldLabels.claimPropertyAssetType,
            'value': selectedAssetType.name,
          },
          {
            'label': DocumentMetadataFieldLabels.claimPropertyIssueDate,
            'value': issueIso,
          },
          {
            'label': DocumentMetadataFieldLabels.claimPropertyPaymentAmount,
            'value': paymentAmount,
          },
          {
            'label': DocumentMetadataFieldLabels.claimPropertyPaymentDate,
            'value': paymentIso,
          },
        ].where((field) => (field['value'] ?? '').trim().isNotEmpty).toList();

        final saved = _isEditing
            ? await _updateUseCase(
                UpdateDocumentParams(
                  documentId: widget.documentToEdit!.id,
                  type: DocumentType.other,
                  source:
                      widget.documentToEdit?.captureSource ??
                      DocumentCaptureSource.gallery,
                  scanPagesCount: widget.documentToEdit?.scanPagesCount ?? 1,
                  categoryOverride: DocumentCategoryType.property,
                  documentTypeKeyOverride: 'other',
                  issuerOverride: widget.propertyName,
                  identifierLabelOverride: categoryLabel,
                  identifierValueOverride: documentName,
                  structuredFieldsOverride: structuredFields,
                  tagsOverride: <String>['property', selectedAssetType.name],
                ),
              )
            : await _createUseCase(
                CreateScannedDocumentParams(
                  type: DocumentType.other,
                  source: DocumentCaptureSource.gallery,
                  scanPagesCount: 1,
                  categoryOverride: DocumentCategoryType.property,
                  documentTypeKeyOverride: 'other',
                  issuerOverride: widget.propertyName,
                  identifierLabelOverride: categoryLabel,
                  identifierValueOverride: documentName,
                  structuredFieldsOverride: structuredFields,
                  tagsOverride: <String>['property', selectedAssetType.name],
                ),
              );
        savedIds.add(saved.id);
      }
      if (!mounted) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(savedIds.isEmpty ? 'saved' : savedIds.first);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast(context.l10n.propertyDocumentSaveFailed);
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _assetTypeLabel(BuildContext context, PropertyAssetType type) {
    return switch (type) {
      PropertyAssetType.documents => context.l10n.propertyDetailAssetDocuments,
      PropertyAssetType.contracts => context.l10n.propertyDetailAssetContracts,
      PropertyAssetType.insurance => context.l10n.propertyDetailAssetInsurance,
      PropertyAssetType.payments =>
        context.l10n.propertyDocumentCategoryRentPayment,
      PropertyAssetType.maintenance =>
        context.l10n.propertyDetailAssetMaintenance,
      PropertyAssetType.others => context.l10n.propertyDetailAssetOthers,
    };
  }

  String _fileNameFromPath(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return '';
    }
    final sanitized = normalized.replaceAll('\\', '/');
    final index = sanitized.lastIndexOf('/');
    if (index == -1 || index >= sanitized.length - 1) {
      return sanitized;
    }
    return sanitized.substring(index + 1);
  }

  String _formatPaymentAmount(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return '';
    }
    if (RegExp(r'^[\$\€\£\¥]|^[A-Za-z]{3}\s').hasMatch(value)) {
      return value;
    }
    return '\$ $value';
  }

  String _paymentAmountInputValue(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return '';
    }
    return value
        .replaceFirst(RegExp(r'^[\$\€\£\¥]\s*'), '')
        .replaceFirst(RegExp(r'^[A-Za-z]{3}\s+'), '');
  }

  DateTime? _parseStoredDate(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse(trimmed)?.toLocal();
  }

  String _detailFieldValue(DocumentDetailEntity detail, List<String> labels) {
    for (final target in labels) {
      final normalizedTarget = target.trim().toLowerCase();
      for (final field in detail.structuredFields) {
        final label = field.label.trim();
        final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(
          label,
        );
        final normalizedLabel = label.toLowerCase();
        if (normalizedLabel != normalizedTarget &&
            canonical != normalizedTarget) {
          continue;
        }
        final value = field.value.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }

  String _slugify(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'property' : normalized;
  }

  List<_SelectedPropertyUpload> get _activeUploads {
    if (_selectedUploads.isNotEmpty) {
      return _selectedUploads;
    }
    final normalizedPath = _uploadedFilePath.trim();
    if (normalizedPath.isEmpty) {
      return const <_SelectedPropertyUpload>[];
    }
    return <_SelectedPropertyUpload>[
      _SelectedPropertyUpload(
        path: normalizedPath,
        name: _uploadedFileName.trim().isEmpty
            ? _fileNameFromPath(normalizedPath)
            : _uploadedFileName.trim(),
        mime: normalizedPath.inferMimeType(),
      ),
    ];
  }

  bool _hasValidTitles(List<_SelectedPropertyUpload> uploads) {
    if (uploads.isEmpty) {
      return false;
    }
    if (uploads.length == 1) {
      return _resolvedUploadTitle(uploads.first).isNotEmpty;
    }
    return uploads.every((upload) => _resolvedUploadTitle(upload).isNotEmpty);
  }

  String _resolvedDocumentName({
    required String explicitTitle,
    required _SelectedPropertyUpload upload,
  }) {
    final trimmedTitle = explicitTitle.trim();
    if (trimmedTitle.isNotEmpty) {
      return trimmedTitle;
    }
    final readable = _readableFileStem(upload.name);
    if (readable.isNotEmpty) {
      return readable;
    }
    return _assetTypeLabel(
      context,
      _selectedAssetType ?? PropertyAssetType.documents,
    );
  }

  String _fileStem(String fileName) {
    final normalized = fileName.trim();
    if (normalized.isEmpty) {
      return '';
    }
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex <= 0) {
      return normalized;
    }
    return normalized.substring(0, dotIndex);
  }

  String _readableFileStem(String fileName) {
    return _fileStem(
      fileName,
    ).replaceAll(RegExp(r'[_-]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  TextEditingController _titleControllerFor(_SelectedPropertyUpload upload) {
    return _uploadTitleControllers.putIfAbsent(
      upload.path,
      () => TextEditingController(
        text: _defaultUploadTitle(
          upload,
          allowSharedTitle: _activeUploads.length <= 1,
        ),
      ),
    );
  }

  void _syncUploadTitleControllers(
    List<_SelectedPropertyUpload> uploads, {
    Map<String, String> initialTitles = const <String, String>{},
  }) {
    final allowSharedTitle = uploads.length <= 1;
    final activePaths = uploads.map((upload) => upload.path).toSet();
    final removedPaths = _uploadTitleControllers.keys
        .where((path) => !activePaths.contains(path))
        .toList(growable: false);
    for (final path in removedPaths) {
      _uploadTitleControllers.remove(path)?.dispose();
    }
    for (final upload in uploads) {
      final seededTitle = (initialTitles[upload.path] ?? '').trim();
      _uploadTitleControllers.putIfAbsent(
        upload.path,
        () => TextEditingController(
          text: seededTitle.isEmpty
              ? _defaultUploadTitle(upload, allowSharedTitle: allowSharedTitle)
              : seededTitle,
        ),
      );
    }
  }

  void _setSelectedUploads(List<_SelectedPropertyUpload> uploads) {
    _syncUploadTitleControllers(uploads);
    setState(() {
      _selectedUploads = uploads;
      _uploadedFilePath = uploads.first.path;
      _uploadedFileName = uploads.first.name;
      if (uploads.length == 1) {
        _titleController.text = _titleControllerFor(uploads.first).text;
      } else {
        _titleController.clear();
      }
    });
  }

  void _removeUpload(_SelectedPropertyUpload upload) {
    final remaining = _selectedUploads
        .where((item) => item.path != upload.path)
        .toList(growable: false);
    _uploadTitleControllers.remove(upload.path)?.dispose();
    if (remaining.isEmpty) {
      setState(() {
        _selectedUploads = const <_SelectedPropertyUpload>[];
        _uploadedFilePath = '';
        _uploadedFileName = '';
        _titleController.clear();
      });
      return;
    }
    _syncUploadTitleControllers(remaining);
    setState(() {
      _selectedUploads = remaining;
      _uploadedFilePath = remaining.first.path;
      _uploadedFileName = remaining.first.name;
      if (remaining.length == 1) {
        _titleController.text = _titleControllerFor(remaining.first).text;
      } else {
        _titleController.clear();
      }
    });
  }

  String _resolvedUploadTitle(_SelectedPropertyUpload upload) {
    final controller = _uploadTitleControllers[upload.path];
    if (controller != null) {
      return controller.text.trim();
    }
    if (_activeUploads.length <= 1) {
      return _titleController.text.trim();
    }
    return '';
  }

  String _defaultUploadTitle(
    _SelectedPropertyUpload upload, {
    required bool allowSharedTitle,
  }) {
    if (allowSharedTitle && _titleController.text.trim().isNotEmpty) {
      return _titleController.text.trim();
    }
    final readable = _readableFileStem(upload.name);
    return readable.isEmpty ? _fileStem(upload.name) : readable;
  }

  InputDecoration _textFieldDecoration(
    BuildContext context, {
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textMuted,
      ),
      filled: true,
      fillColor: context.appPalette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: _outlinedInput(),
      enabledBorder: _outlinedInput(),
      focusedBorder: _outlinedInput(color: const Color(0xFFADC1EA)),
    );
  }

  void _showToast(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(trimmed), behavior: SnackBarBehavior.floating),
    );
  }
}

class _SelectedPropertyUpload {
  const _SelectedPropertyUpload({
    required this.path,
    required this.name,
    required this.mime,
  });

  final String path;
  final String name;
  final String mime;
}
