import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_vaults.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/work_documents_design.dart';
import 'package:pass_doc_manager/l10n/app_localizations.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class WorkDocumentManualEntryPage extends StatefulWidget {
  const WorkDocumentManualEntryPage({
    super.key,
    this.documentToEdit,
    this.initialCompanyName,
    this.initialFolderType,
    this.initialCaptureSource,
    this.initialStatementDate,
    this.initialNetAmount,
    this.initialRecordTitle,
    CreateScannedDocument? createScannedDocument,
    UpdateDocument? updateDocument,
    GetWorkCompanyVaults? getWorkCompanyVaults,
  }) : _createScannedDocument = createScannedDocument,
       _updateDocument = updateDocument,
       _getWorkCompanyVaults = getWorkCompanyVaults;

  final DocumentDetailEntity? documentToEdit;
  final String? initialCompanyName;
  final WorkDocumentFolderType? initialFolderType;
  final DocumentCaptureSource? initialCaptureSource;
  final DateTime? initialStatementDate;
  final String? initialNetAmount;
  final String? initialRecordTitle;
  final CreateScannedDocument? _createScannedDocument;
  final UpdateDocument? _updateDocument;
  final GetWorkCompanyVaults? _getWorkCompanyVaults;

  @override
  State<WorkDocumentManualEntryPage> createState() =>
      _WorkDocumentManualEntryPageState();
}

class _WorkDocumentManualEntryPageState
    extends State<WorkDocumentManualEntryPage> {
  final _notesController = TextEditingController();
  final _labelController = TextEditingController();
  final _imagePicker = ImagePicker();
  final Map<String, TextEditingController> _uploadTitleControllers =
      <String, TextEditingController>{};

  late _WorkDocumentTypeOption _selectedType;
  DateTime? _effectiveDate;
  DateTime? _expiryDate;
  bool _isOngoing = true;

  bool _isSaving = false;
  bool _isPickingUpload = false;
  bool _isLoadingCompanies = false;

  String _uploadedFilePath = '';
  String _uploadedFileName = '';
  String _uploadedFileMime = '';
  List<_SelectedWorkUpload> _selectedUploads = const <_SelectedWorkUpload>[];
  DocumentCaptureSource _captureSource = DocumentCaptureSource.gallery;
  _WorkFileSource _selectedSourceOption = _WorkFileSource.gallery;

  List<WorkCompanyVaultEntity> _companies = const <WorkCompanyVaultEntity>[];
  WorkCompanyVaultEntity? _selectedCompany;

  CreateScannedDocument get _createUseCase =>
      widget._createScannedDocument ?? getIt();
  UpdateDocument get _updateUseCase => widget._updateDocument ?? getIt();
  GetWorkCompanyVaults get _getWorkCompaniesUseCase =>
      widget._getWorkCompanyVaults ?? getIt();

  bool get _isEditing => widget.documentToEdit != null;

  @override
  void initState() {
    super.initState();
    _selectedType = _workDocumentTypeOptions.first;
    _bootstrap();
    unawaited(_loadCompanies());
  }

  @override
  void dispose() {
    _notesController.dispose();
    _labelController.dispose();
    for (final controller in _uploadTitleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uploads = _activeUploads;
    final canSave =
        !_isSaving &&
        !_isPickingUpload &&
        _selectedCompany != null &&
        uploads.isNotEmpty;
    final selectedCompany = _selectedCompany;
    final fileSelected = uploads.isNotEmpty;

    return Scaffold(
      backgroundColor: context.appPalette.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    _formHeader(context, canSave: canSave),
                    WorkEditorSectionLabel(
                      value: uploads.length > 1
                          ? 'Shared for all files'
                          : 'Category',
                    ),
                    _workDetailsGroup(context, selectedCompany),
                    if (_isLoadingCompanies) ...[
                      SizedBox(height: 8),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    WorkEditorSectionLabel(
                      value: fileSelected
                          ? (uploads.length == 1
                                ? 'Document · 1 file'
                                : '${uploads.length} documents · individual titles')
                          : 'Document',
                    ),
                    if (!fileSelected)
                      _wrapWithDropTarget(
                        _uploadCard(
                          context,
                          hasUpload: false,
                          uploads: uploads,
                          onTap: (_isPickingUpload || _isSaving)
                              ? null
                              : _pickUploadFile,
                        ),
                      )
                    else ...[
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
                            sharedTypeLabel: _selectedType.label(context.l10n),
                          ),
                        ),
                      ),
                      if (!_isEditing) ...[
                        const SizedBox(height: 10),
                        WorkDashedAdd(
                          label: l10n.workManualEntryUploadTitle,
                          onTap: (_isPickingUpload || _isSaving)
                              ? null
                              : _pickUploadFile,
                        ),
                      ],
                    ],
                    WorkEditorSectionLabel(value: 'Source'),
                    WorkSourceSegmented(
                      labels: [
                        l10n.idEntryChooseFile,
                        l10n.profileChooseFromLibrary,
                        l10n.workPayslipPickCamera,
                      ],
                      selectedIndex: _sourceIndex,
                      onSelected: (index) {
                        if (_isPickingUpload || _isSaving) {
                          return;
                        }
                        _pickUploadFile(
                          sourceOverride: _fileSourceForIndex(index),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    WorkHelpText(
                      value: uploads.length > 1
                          ? l10n.workManualEntrySharedTypeHint
                          : l10n.idEntryMultipleFilesHint,
                    ),
                    WorkEditorSectionLabel(
                      value: l10n.workManualEntrySectionNotes,
                    ),
                    TextField(
                      controller: _notesController,
                      style: TextStyle(
                        fontFamily: workFontBody,
                        color: context.appPalette.textPrimary,
                      ),
                      minLines: 4,
                      maxLines: 6,
                      decoration: _textFieldDecoration(
                        context,
                        hintText: l10n.workManualEntryNotesHint,
                        multiline: true,
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
            if (_isSaving)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.12),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _formHeader(BuildContext context, {required bool canSave}) {
    final title = _isEditing
        ? context.l10n.workManualEntryEditTitle
        : context.l10n.workManualEntryAddTitle;
    return WorkSheetHeader(
      title: title,
      onCancel: () => Navigator.of(context).maybePop(),
      onSave: _save,
      saveLabel: context.l10n.commonSave,
      saveEnabled: canSave,
      isSaving: _isSaving,
    );
  }

  Widget _workDetailsGroup(
    BuildContext context,
    WorkCompanyVaultEntity? selectedCompany,
  ) {
    final l10n = context.l10n;
    final selectedCompanyName = selectedCompany?.companyName.trim() ?? '';
    return WorkFieldGroup(
      children: [
        WorkPickerField(
          label: l10n.workManualEntryDocumentTypeLabel,
          value: _selectedType.label(l10n),
          onTap: _pickDocumentType,
        ),
        WorkPickerField(
          label: l10n.workManualEntryAssignVaultLabel,
          value: selectedCompanyName.isEmpty
              ? l10n.workPayslipSelectCompanyPlaceholder
              : selectedCompanyName,
          leading: WorkCompanyLogo(
            name: selectedCompanyName.isEmpty ? 'Company' : selectedCompanyName,
            logoPath: selectedCompany?.companyLogoPath,
            size: 28,
            tint: WorkTint.mint,
          ),
          onTap: _isLoadingCompanies ? null : _pickCompany,
        ),
        WorkPickerField(
          label: l10n.workManualEntryEffectiveDateLabel,
          value: _formattedDate(context, _effectiveDate),
          monospaceValue: true,
          trailing: Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: context.appPalette.textMuted,
          ),
          onTap: () => _pickDate(
            current: _effectiveDate,
            onPick: (date) {
              _effectiveDate = date;
            },
          ),
        ),
        WorkPickerField(
          label: l10n.workManualEntryExpiryDateLabel,
          value: _isOngoing
              ? l10n.workManualEntryOngoingLabel
              : _formattedDate(context, _expiryDate),
          monospaceValue: !_isOngoing,
          trailing: Switch.adaptive(
            value: _isOngoing,
            onChanged: (value) {
              setState(() {
                _isOngoing = value;
                if (_isOngoing) {
                  _expiryDate = null;
                }
              });
            },
          ),
          onTap: _isOngoing
              ? null
              : () => _pickDate(
                  current: _expiryDate,
                  onPick: (date) {
                    _expiryDate = date;
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _pickDocumentType() async {
    final selected = await showAdaptiveModal<_WorkDocumentTypeOption>(
      context: context,
      backgroundColor: context.appPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            itemBuilder: (context, index) {
              final option = _workDocumentTypeOptions[index];
              final isSelected =
                  option.translationKey == _selectedType.translationKey;
              return ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected ? context.appPalette.primarySoft : null,
                title: Text(
                  option.label(context.l10n),
                  style: TextStyle(
                    fontFamily: workFontBody,
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                subtitle: Text(
                  option.folderType.label,
                  style: TextStyle(
                    fontFamily: workFontMono,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: context.appPalette.textMuted,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: context.appPalette.primary,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemCount: _workDocumentTypeOptions.length,
          ),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _selectedType = selected;
    });
  }

  String _formattedDate(BuildContext context, DateTime? value) {
    if (value == null) {
      return context.l10n.workManualEntryDatePlaceholder;
    }
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(value);
  }

  int get _sourceIndex {
    return switch (_selectedSourceOption) {
      _WorkFileSource.gallery => 1,
      _WorkFileSource.camera => 2,
      _WorkFileSource.files => 0,
    };
  }

  _WorkFileSource _fileSourceForIndex(int index) {
    return switch (index) {
      1 => _WorkFileSource.gallery,
      2 => _WorkFileSource.camera,
      _ => _WorkFileSource.files,
    };
  }

  Future<void> _handleFileDrop(List<String> paths) async {
    final l10n = context.l10n;
    try {
      final candidatePaths = _isEditing
          ? paths.take(1).toList(growable: false)
          : paths;
      final uploads = <_SelectedWorkUpload>[];
      for (final path in candidatePaths) {
        final file = File(path);
        if (!await file.exists()) {
          continue;
        }
        final byteLength = await file.length();
        if (byteLength > _maxUploadBytes) {
          _showToast(l10n.workManualEntryFileTooLarge);
          return;
        }
        final persistedPath = await _persistUploadFile(sourcePath: path);
        if (!mounted) {
          return;
        }
        if ((persistedPath ?? '').trim().isEmpty) {
          _showToast(l10n.workPayslipUnableSaveFileLocally);
          return;
        }
        final normalized = persistedPath!.trim();
        uploads.add(
          _SelectedWorkUpload(
            path: normalized,
            name: _fileNameFromPath(normalized),
            mime: normalized.inferMimeType(),
          ),
        );
      }
      if (uploads.isEmpty) {
        return;
      }
      _setSelectedUploads(
        _mergeUploads(uploads),
        captureSource: DocumentCaptureSource.gallery,
        sourceOption: _WorkFileSource.files,
      );
    } catch (_) {
      if (!mounted) return;
      _showToast(l10n.workPayslipUnableSelectFile);
    }
  }

  bool get _isDesktop {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;
  }

  Widget _wrapWithDropTarget(Widget child) {
    if (!_isDesktop) return child;
    return DropTarget(
      onDragDone: (details) {
        if (details.files.isNotEmpty) {
          _handleFileDrop(
            details.files.map((file) => file.path).toList(growable: false),
          );
        }
      },
      child: child,
    );
  }

  Widget _uploadCard(
    BuildContext context, {
    required bool hasUpload,
    required List<_SelectedWorkUpload> uploads,
    required VoidCallback? onTap,
  }) {
    final l10n = context.l10n;
    final primaryUpload = uploads.isEmpty ? null : uploads.first;
    final subtitle = hasUpload
        ? uploads.length == 1
              ? '${primaryUpload!.name} • ${resolveFileTypeLabel(path: primaryUpload.path, mime: primaryUpload.mime)}'
              : '${l10n.documentFilesCount(uploads.length)} • ${primaryUpload!.name}'
        : '${l10n.workManualEntryUploadSubtitle}\n${l10n.idEntryMultipleFilesHint}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: hasUpload
                ? context.appPalette.primarySoft
                : context.appPalette.surface,
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
                child: Icon(
                  hasUpload
                      ? Icons.check_circle_rounded
                      : Icons.upload_file_rounded,
                  size: 22,
                  color: context.appPalette.primary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.workManualEntryUploadTitle,
                      style: TextStyle(
                        fontFamily: workFontDisplay,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: workFontMono,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        color: hasUpload
                            ? const Color(0xFF2D56BF)
                            : context.appPalette.textSecondary,
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
              _isPickingUpload
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: context.appPalette.textMuted,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedUploadCard(
    BuildContext context, {
    required _SelectedWorkUpload upload,
    required int index,
    required int totalUploads,
    required String sharedTypeLabel,
  }) {
    final fileTypeLabel = resolveFileTypeLabel(
      path: upload.path,
      mime: upload.mime,
    );
    final metaParts = <String>[
      context.l10n.workManualEntrySelectedDocumentLabel(index + 1),
      sharedTypeLabel,
      fileTypeLabel,
    ];
    return WorkBatchUploadRow(
      fileName: upload.name,
      fileMeta: metaParts.join(' · '),
      controller: _titleControllerFor(upload),
      hintText: context.l10n.workManualEntryDocumentTitleHint,
      path: upload.path,
      mime: upload.mime,
      onRemove: !_isEditing && totalUploads > 1
          ? () => _removeUpload(upload)
          : null,
    );
  }

  Future<void> _pickDate({
    required DateTime? current,
    required void Function(DateTime date) onPick,
  }) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 60),
      lastDate: DateTime(now.year + 80),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      onPick(selected);
    });
  }

  Future<void> _loadCompanies() async {
    if (_isLoadingCompanies) {
      return;
    }
    setState(() {
      _isLoadingCompanies = true;
    });
    try {
      final companies = await _getWorkCompaniesUseCase(
        const GetWorkCompanyVaultsParams(),
      );
      if (!mounted) {
        return;
      }
      final uniqueById = <String, WorkCompanyVaultEntity>{};
      for (final item in companies) {
        final key = item.companyId.trim().toLowerCase();
        if (key.isEmpty || uniqueById.containsKey(key)) {
          continue;
        }
        uniqueById[key] = item;
      }
      final values = uniqueById.values.toList(growable: false)
        ..sort(
          (a, b) => a.companyName.toLowerCase().compareTo(
            b.companyName.toLowerCase(),
          ),
        );

      WorkCompanyVaultEntity? selected = _selectedCompany;
      if (selected == null && values.isNotEmpty) {
        final initialName = (widget.initialCompanyName ?? '')
            .trim()
            .toLowerCase();
        if (initialName.isNotEmpty) {
          for (final company in values) {
            if (company.companyName.trim().toLowerCase() == initialName) {
              selected = company;
              break;
            }
          }
        }
        selected ??= values.first;
      }

      if (selected == null &&
          (widget.initialCompanyName ?? '').trim().isNotEmpty) {
        selected = _fallbackCompany(name: widget.initialCompanyName!.trim());
      }

      setState(() {
        _companies = values;
        _selectedCompany = selected;
        _isLoadingCompanies = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      final fallback = (widget.initialCompanyName ?? '').trim().isEmpty
          ? null
          : _fallbackCompany(name: widget.initialCompanyName!.trim());
      setState(() {
        _companies = const <WorkCompanyVaultEntity>[];
        _selectedCompany = fallback;
        _isLoadingCompanies = false;
      });
    }
  }

  WorkCompanyVaultEntity _fallbackCompany({required String name}) {
    final now = DateTime.now();
    return WorkCompanyVaultEntity(
      companyId: _slugify(name),
      companyName: name,
      profileDocumentId: null,
      documentsCount: 0,
      lastUpdatedAt: now,
      lastAccessAt: null,
      isPinned: false,
      totalStorageBytes: 0,
      roleLabel: '',
      contactLabel: '',
      addressLabel: '',
      startedAt: null,
      finishedAt: null,
      companyLogoPath: null,
    );
  }

  Future<void> _pickCompany() async {
    final l10n = context.l10n;
    if (_companies.isEmpty) {
      _showToast(l10n.workPayslipNoCompanyAvailable);
      return;
    }
    final selected = await showAdaptiveModal<WorkCompanyVaultEntity>(
      context: context,
      backgroundColor: context.appPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            itemCount: _companies.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: context.appPalette.stroke),
            itemBuilder: (context, index) {
              final item = _companies[index];
              final isSelected = item.companyId == _selectedCompany?.companyId;
              return ListTile(
                minLeadingWidth: 0,
                dense: true,
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.appPalette.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  child: _companyLogo(path: item.companyLogoPath),
                ),
                title: Text(
                  item.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: workFontDisplay,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n.documentFilesCount(item.documentsCount),
                  style: TextStyle(
                    fontFamily: workFontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: context.appPalette.primary,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(item),
              );
            },
          ),
        );
      },
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _selectedCompany = selected;
    });
  }

  Future<void> _pickUploadFile({_WorkFileSource? sourceOverride}) async {
    if (_isPickingUpload || _isSaving) {
      return;
    }
    final l10n = context.l10n;
    setState(() {
      _isPickingUpload = true;
    });
    try {
      List<String> sourcePaths = const <String>[];
      var source = DocumentCaptureSource.gallery;
      final pickedSource =
          sourceOverride ??
          await showAdaptiveModal<_WorkFileSource>(
            context: context,
            backgroundColor: context.appPalette.background,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            builder: (context) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sourceTile(
                        title: l10n.workPayslipPickCamera,
                        icon: Icons.photo_camera_rounded,
                        onTap: () =>
                            Navigator.of(context).pop(_WorkFileSource.camera),
                      ),
                      const SizedBox(height: 8),
                      _sourceTile(
                        title: l10n.profileChooseFromLibrary,
                        icon: Icons.photo_library_rounded,
                        onTap: () =>
                            Navigator.of(context).pop(_WorkFileSource.gallery),
                      ),
                      const SizedBox(height: 8),
                      _sourceTile(
                        title: l10n.idEntryChooseFile,
                        icon: Icons.folder_open_rounded,
                        onTap: () =>
                            Navigator.of(context).pop(_WorkFileSource.files),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
      if (pickedSource == null || !mounted) {
        return;
      }
      switch (pickedSource) {
        case _WorkFileSource.camera:
          final sourcePath = await _pickImageFromCamera();
          sourcePaths = sourcePath == null
              ? const <String>[]
              : <String>[sourcePath];
          source = DocumentCaptureSource.camera;
          break;
        case _WorkFileSource.gallery:
          sourcePaths = await _pickImagesFromGallery();
          source = DocumentCaptureSource.gallery;
          break;
        case _WorkFileSource.files:
          sourcePaths = await _pickUploadsFromFileBrowser();
          source = DocumentCaptureSource.gallery;
          break;
      }

      if (sourcePaths.isEmpty) {
        return;
      }

      final uploads = <_SelectedWorkUpload>[];
      for (final rawPath in sourcePaths) {
        final normalized = _normalizeLocalPath(rawPath);
        if (normalized.isEmpty) {
          continue;
        }
        if (!_isSupportedUploadPath(normalized)) {
          _showToast(l10n.workManualEntryUploadSubtitle);
          return;
        }
        final sourceFile = File(normalized);
        if (!await sourceFile.exists()) {
          _showToast(l10n.workPayslipUnableSelectFile);
          return;
        }
        final byteLength = await sourceFile.length();
        if (byteLength > _maxUploadBytes) {
          _showToast(l10n.workManualEntryFileTooLarge);
          return;
        }
        final persistedPath = await _persistUploadFile(sourcePath: normalized);
        if (!mounted) {
          return;
        }
        if ((persistedPath ?? '').trim().isEmpty) {
          _showToast(l10n.workPayslipUnableSaveFileLocally);
          return;
        }
        final persisted = persistedPath!.trim();
        uploads.add(
          _SelectedWorkUpload(
            path: persisted,
            name: _fileNameFromPath(persisted),
            mime: persisted.inferMimeType(),
          ),
        );
      }
      if (uploads.isEmpty) {
        return;
      }
      _setSelectedUploads(
        _mergeUploads(uploads),
        captureSource: source,
        sourceOption: pickedSource,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast(l10n.workPayslipUnableSelectFile);
    } finally {
      if (mounted) {
        setState(() {
          _isPickingUpload = false;
        });
      }
    }
  }

  Widget _sourceTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.appPalette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.appPalette.stroke),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: context.appPalette.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: workFontBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.appPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _pickUploadsFromFileBrowser() async {
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final typeGroup = isIos
        ? const XTypeGroup(
            label: 'upload',
            uniformTypeIdentifiers: [
              'public.image',
              'com.adobe.pdf',
              'org.openxmlformats.wordprocessingml.document',
              'com.microsoft.word.doc',
              'org.openxmlformats.spreadsheetml.sheet',
              'com.microsoft.excel.xls',
              'org.openxmlformats.presentationml.presentation',
              'com.microsoft.powerpoint.ppt',
              'public.plain-text',
              'public.rtf',
              'public.comma-separated-values-text',
            ],
          )
        : const XTypeGroup(
            label: 'upload',
            extensions: <String>[
              'jpg',
              'jpeg',
              'png',
              'pdf',
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
              'public.jpeg',
              'public.png',
              'com.adobe.pdf',
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
          );
    final files = _isEditing
        ? () async {
            final file = await openFile(acceptedTypeGroups: [typeGroup]);
            return file == null ? const <XFile>[] : <XFile>[file];
          }()
        : openFiles(acceptedTypeGroups: [typeGroup]);
    return files.then(
      (value) => value.map((file) => file.path).toList(growable: false),
    );
  }

  Future<String?> _pickImageFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 96,
      maxWidth: 4096,
      maxHeight: 4096,
    );
    return image?.path;
  }

  Future<List<String>> _pickImagesFromGallery() async {
    if (_isEditing) {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 3200,
        maxHeight: 3200,
      );
      return image == null ? const <String>[] : <String>[image.path];
    }
    final images = await _imagePicker.pickMultiImage(
      imageQuality: 95,
      maxWidth: 3200,
      maxHeight: 3200,
    );
    return images.map((image) => image.path).toList(growable: false);
  }

  Future<String?> _persistUploadFile({required String sourcePath}) async {
    final companySlug = _slugify(_selectedCompany?.companyName ?? 'company');
    return LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: sourcePath,
      directoryName: 'work_document_assets',
      fileNamePrefix: 'work_doc_$companySlug',
    );
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    final selectedCompany = _selectedCompany;
    if (selectedCompany == null) {
      _showToast(context.l10n.workEntrySelectCompanyFirst);
      return;
    }
    final uploads = _activeUploads;
    if (uploads.isEmpty) {
      _showToast(context.l10n.workManualEntrySelectUploadFirst);
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final companyName = selectedCompany.companyName.trim();
      final companyId = selectedCompany.companyId.trim().isEmpty
          ? _slugify(companyName)
          : selectedCompany.companyId.trim();
      final companyLogoPath = (selectedCompany.companyLogoPath ?? '').trim();
      final typeLabel = _selectedType.label(context.l10n);
      final folderType = _selectedType.folderType;
      final notes = _notesController.text.trim();
      final effectiveIso = _effectiveDate == null
          ? ''
          : DateFormat('yyyy-MM-dd').format(_effectiveDate!);
      final expiryIso = (_isOngoing || _expiryDate == null)
          ? ''
          : DateFormat('yyyy-MM-dd').format(_expiryDate!);
      final detailToEdit = widget.documentToEdit;
      final savedIds = <String>[];
      final failedUploads = <_SelectedWorkUpload>[];
      for (final upload in uploads) {
        final statementTitle = _resolvedStatementTitle(
          explicitLabel: _resolvedUploadTitle(upload),
          fallbackTypeLabel: typeLabel,
          upload: upload,
        );
        final referencePayload = <Map<String, String>>[
          {
            'name': upload.name,
            'path': upload.path,
            'mime': upload.mime,
            'label': typeLabel,
          },
        ];

        final structuredFields =
            <Map<String, String>>[
                  {'label': 'Company Name', 'value': companyName},
                  {'label': 'Document Type', 'value': typeLabel},
                  {'label': 'Folder Type', 'value': folderType.label},
                  {'label': 'File Name', 'value': upload.name},
                  {
                    'label': DocumentMetadataFieldLabels.workCompanyId,
                    'value': companyId,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workCompanyName,
                    'value': companyName,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workCompanyLogoPath,
                    'value': companyLogoPath,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workFolderType,
                    'value': folderType.key,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workRecordType,
                    'value': 'statement',
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workStatementTitle,
                    'value': statementTitle,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workStatementDate,
                    'value': effectiveIso,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workStartDate,
                    'value': effectiveIso,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workEndDate,
                    'value': expiryIso,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workStatementStatus,
                    'value': _isOngoing ? 'ongoing' : 'fixed',
                  },
                  {'label': 'Notes', 'value': notes},
                  {
                    'label': DocumentMetadataFieldLabels.workStatementLabel,
                    'value': typeLabel,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workPinned,
                    'value': 'false',
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
                    'value': typeLabel,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkCompanyId,
                    'value': companyId,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkCompanyName,
                    'value': companyName,
                  },
                  {
                    'label':
                        DocumentMetadataFieldLabels.claimWorkCompanyLogoPath,
                    'value': companyLogoPath,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkFolderType,
                    'value': folderType.key,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkRecordType,
                    'value': 'statement',
                  },
                  {
                    'label':
                        DocumentMetadataFieldLabels.claimWorkStatementTitle,
                    'value': statementTitle,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkStatementDate,
                    'value': effectiveIso,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkStartDate,
                    'value': effectiveIso,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkEndDate,
                    'value': expiryIso,
                  },
                  {
                    'label':
                        DocumentMetadataFieldLabels.claimWorkStatementStatus,
                    'value': _isOngoing ? 'ongoing' : 'fixed',
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkPinned,
                    'value': 'false',
                  },
                ]
                .where((field) => (field['value'] ?? '').trim().isNotEmpty)
                .toList(growable: false);

        try {
          final saved = detailToEdit == null
              ? await _createUseCase(
                  CreateScannedDocumentParams(
                    type: DocumentType.other,
                    source: _captureSource,
                    scanPagesCount: 1,
                    categoryOverride: DocumentCategoryType.work,
                    documentTypeKeyOverride: 'other',
                    issuerOverride: companyName,
                    identifierLabelOverride: folderType.label,
                    identifierValueOverride: statementTitle,
                    structuredFieldsOverride: structuredFields,
                    tagsOverride: <String>[folderType.label, 'Work', typeLabel],
                  ),
                )
              : await _updateUseCase(
                  UpdateDocumentParams(
                    documentId: detailToEdit.id,
                    type: DocumentType.other,
                    source: _captureSource,
                    scanPagesCount: detailToEdit.scanPagesCount,
                    categoryOverride: DocumentCategoryType.work,
                    documentTypeKeyOverride: 'other',
                    issuerOverride: companyName,
                    identifierLabelOverride: folderType.label,
                    identifierValueOverride: statementTitle,
                    structuredFieldsOverride: structuredFields,
                    tagsOverride: <String>[folderType.label, 'Work', typeLabel],
                  ),
                );
          savedIds.add(saved.id);
        } catch (_) {
          failedUploads.add(upload);
        }
      }
      if (!mounted) {
        return;
      }
      if (failedUploads.isNotEmpty) {
        _setSelectedUploads(failedUploads, captureSource: _captureSource);
        _showToast(context.l10n.idEntryUnableSaveDocument);
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(savedIds.isEmpty ? 'saved' : savedIds.first);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showToast(context.l10n.idEntryUnableSaveDocument);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _bootstrap() {
    _captureSource = widget.initialCaptureSource ?? _captureSource;
    if (widget.initialFolderType != null) {
      final matchingByFolder = _workDocumentTypeOptions.firstWhere(
        (option) => option.folderType == widget.initialFolderType,
        orElse: () => _workDocumentTypeOptions.first,
      );
      _selectedType = matchingByFolder;
    }
    final detail = widget.documentToEdit;
    if (detail == null) {
      final initialDate = widget.initialStatementDate;
      if (initialDate != null) {
        _effectiveDate = initialDate;
      }
      final initialTitle = (widget.initialRecordTitle ?? '').trim();
      if (initialTitle.isNotEmpty) {
        final normalizedTitle = initialTitle.toLowerCase();
        for (final option in _workDocumentTypeOptions) {
          if (option.translationKey == normalizedTitle) {
            _selectedType = option;
            break;
          }
        }
      }
      return;
    }

    final companyName = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.workCompanyName,
      'Company Name',
    ]);
    if (companyName.trim().isNotEmpty) {
      _selectedCompany = _fallbackCompany(name: companyName);
    }

    final title = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.workStatementTitle,
      'Document Type',
      'Document Title',
    ]).toLowerCase();
    for (final option in _workDocumentTypeOptions) {
      if (option.translationKey == title) {
        _selectedType = option;
        break;
      }
    }

    final startRaw = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.workStartDate,
      DocumentMetadataFieldLabels.workStatementDate,
    ]);
    final endRaw = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.workEndDate,
    ]);
    _effectiveDate = DateTime.tryParse(startRaw);
    _expiryDate = DateTime.tryParse(endRaw);
    _isOngoing = _expiryDate == null;
    _notesController.text = _firstMatch(detail, const ['Notes']);
    _labelController.text = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.workStatementTitle,
      'Document Title',
    ]);

    _uploadedFilePath = _firstMatch(detail, const [
      DocumentMetadataFieldLabels.previewImagePath,
      DocumentMetadataFieldLabels.frontImagePath,
      DocumentMetadataFieldLabels.referenceAssetPath,
    ]);
    if (_uploadedFilePath.trim().isNotEmpty) {
      _uploadedFileName = _fileNameFromPath(_uploadedFilePath);
      _uploadedFileMime = _uploadedFilePath.inferMimeType();
      _selectedUploads = <_SelectedWorkUpload>[
        _SelectedWorkUpload(
          path: _uploadedFilePath.trim(),
          name: _uploadedFileName,
          mime: _uploadedFileMime,
        ),
      ];
      _syncUploadTitleControllers(
        _selectedUploads,
        initialTitles: <String, String>{
          _uploadedFilePath.trim(): _labelController.text.trim(),
        },
      );
    }
  }

  String _firstMatch(DocumentDetailEntity detail, List<String> labels) {
    for (final target in labels) {
      final normalizedTarget = target.trim().toLowerCase();
      for (final field in detail.structuredFields) {
        final label = field.label.trim();
        final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(
          label,
        );
        final normalizedLabel = label.toLowerCase();
        if (normalizedLabel == normalizedTarget ||
            canonical == normalizedTarget) {
          final value = field.value.trim();
          if (value.isNotEmpty) {
            return value;
          }
        }
      }
    }
    return '';
  }

  bool _isSupportedUploadPath(String path) {
    final ext = _extensionFromPath(path).replaceFirst('.', '');
    return _supportedUploadExtensions.contains(ext);
  }

  String _extensionFromPath(String path) {
    final normalized = path.trim().toLowerCase();
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == normalized.length - 1) {
      return '.pdf';
    }
    final ext = normalized.substring(dotIndex);
    return RegExp(r'^\.[a-z0-9]{2,5}$').hasMatch(ext) ? ext : '.pdf';
  }

  String _normalizeLocalPath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.startsWith('file://')) {
      try {
        return Uri.parse(trimmed).toFilePath();
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return '';
    }
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }

  String _slugify(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'company' : normalized;
  }

  Widget _companyLogo({required String? path}) {
    final normalizedPath = (path ?? '').trim();
    if (normalizedPath.isNotEmpty) {
      final file = File(normalizedPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: 120,
          cacheHeight: 120,
        );
      }
    }
    return Icon(
      Icons.apartment_rounded,
      size: 20,
      color: context.appPalette.primary,
    );
  }

  List<_SelectedWorkUpload> get _activeUploads {
    if (_selectedUploads.isNotEmpty) {
      return _selectedUploads;
    }
    final filePath = _uploadedFilePath.trim();
    if (filePath.isEmpty) {
      return const <_SelectedWorkUpload>[];
    }
    return <_SelectedWorkUpload>[
      _SelectedWorkUpload(
        path: filePath,
        name: _uploadedFileName.trim().isEmpty
            ? _fileNameFromPath(filePath)
            : _uploadedFileName.trim(),
        mime: _uploadedFileMime.trim().isEmpty
            ? filePath.inferMimeType()
            : _uploadedFileMime.trim(),
      ),
    ];
  }

  String _resolvedStatementTitle({
    required String explicitLabel,
    required String fallbackTypeLabel,
    required _SelectedWorkUpload upload,
  }) {
    final explicit = explicitLabel.trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final readable = _readableFileStem(upload.name);
    if (readable.isNotEmpty) {
      return readable;
    }
    return fallbackTypeLabel;
  }

  TextEditingController _titleControllerFor(_SelectedWorkUpload upload) {
    return _uploadTitleControllers.putIfAbsent(
      upload.path,
      () => TextEditingController(
        text: _defaultUploadTitle(
          upload,
          allowSharedLabel: _activeUploads.length <= 1,
        ),
      ),
    );
  }

  void _syncUploadTitleControllers(
    List<_SelectedWorkUpload> uploads, {
    Map<String, String> initialTitles = const <String, String>{},
  }) {
    final allowSharedLabel = uploads.length <= 1;
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
              ? _defaultUploadTitle(upload, allowSharedLabel: allowSharedLabel)
              : seededTitle,
        ),
      );
    }
  }

  void _setSelectedUploads(
    List<_SelectedWorkUpload> uploads, {
    required DocumentCaptureSource captureSource,
    _WorkFileSource? sourceOption,
  }) {
    _syncUploadTitleControllers(uploads);
    setState(() {
      _captureSource = captureSource;
      if (sourceOption != null) {
        _selectedSourceOption = sourceOption;
      }
      _selectedUploads = uploads;
      _uploadedFilePath = uploads.first.path;
      _uploadedFileName = uploads.first.name;
      _uploadedFileMime = uploads.first.mime;
      if (uploads.length == 1) {
        _labelController.text = _titleControllerFor(uploads.first).text;
      }
    });
  }

  List<_SelectedWorkUpload> _mergeUploads(List<_SelectedWorkUpload> uploads) {
    if (_isEditing || _selectedUploads.isEmpty) {
      return uploads;
    }
    final byPath = <String, _SelectedWorkUpload>{
      for (final upload in _selectedUploads) upload.path: upload,
    };
    for (final upload in uploads) {
      byPath[upload.path] = upload;
    }
    return byPath.values.toList(growable: false);
  }

  void _removeUpload(_SelectedWorkUpload upload) {
    final remaining = _selectedUploads
        .where((item) => item.path != upload.path)
        .toList(growable: false);
    _uploadTitleControllers.remove(upload.path)?.dispose();
    if (remaining.isEmpty) {
      setState(() {
        _selectedUploads = const <_SelectedWorkUpload>[];
        _uploadedFilePath = '';
        _uploadedFileName = '';
        _uploadedFileMime = '';
        _labelController.clear();
      });
      return;
    }
    _syncUploadTitleControllers(remaining);
    setState(() {
      _selectedUploads = remaining;
      _uploadedFilePath = remaining.first.path;
      _uploadedFileName = remaining.first.name;
      _uploadedFileMime = remaining.first.mime;
      if (remaining.length == 1) {
        _labelController.text = _titleControllerFor(remaining.first).text;
      }
    });
  }

  String _resolvedUploadTitle(_SelectedWorkUpload upload) {
    final controller = _uploadTitleControllers[upload.path];
    if (controller != null) {
      return controller.text.trim();
    }
    if (_activeUploads.length <= 1) {
      return _labelController.text.trim();
    }
    return '';
  }

  String _defaultUploadTitle(
    _SelectedWorkUpload upload, {
    required bool allowSharedLabel,
  }) {
    if (allowSharedLabel && _labelController.text.trim().isNotEmpty) {
      return _labelController.text.trim();
    }
    final readable = _readableFileStem(upload.name);
    return readable.isEmpty ? _fileStem(upload.name) : readable;
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

  InputDecoration _textFieldDecoration(
    BuildContext context, {
    required String hintText,
    bool multiline = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: workFontBody,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textMuted,
        height: multiline ? 1.4 : null,
      ),
      filled: true,
      fillColor: context.appPalette.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appPalette.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appPalette.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.appPalette.primary),
      ),
      contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SelectedWorkUpload {
  const _SelectedWorkUpload({
    required this.path,
    required this.name,
    required this.mime,
  });

  final String path;
  final String name;
  final String mime;
}

enum _WorkFileSource { camera, gallery, files }

class _WorkDocumentTypeOption {
  const _WorkDocumentTypeOption({
    required this.translationKey,
    required this.folderType,
    required this.label,
  });

  final String translationKey;
  final WorkDocumentFolderType folderType;
  final String Function(AppLocalizations l10n) label;
}

const Set<String> _supportedUploadExtensions = <String>{
  'jpg',
  'jpeg',
  'png',
  'webp',
  'heic',
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'txt',
  'rtf',
  'csv',
};

const int _maxUploadBytes = 10 * 1024 * 1024;

const List<_WorkDocumentTypeOption> _workDocumentTypeOptions =
    <_WorkDocumentTypeOption>[
      _WorkDocumentTypeOption(
        translationKey: 'employment contract',
        folderType: WorkDocumentFolderType.contracts,
        label: _labelEmploymentContract,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'employer certificate',
        folderType: WorkDocumentFolderType.contracts,
        label: _labelEmployerCertificate,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'internship agreement',
        folderType: WorkDocumentFolderType.contracts,
        label: _labelInternshipAgreement,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'tax declaration',
        folderType: WorkDocumentFolderType.taxForms,
        label: _labelTaxDeclaration,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'tax certificate',
        folderType: WorkDocumentFolderType.taxForms,
        label: _labelTaxCertificate,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'benefits enrollment',
        folderType: WorkDocumentFolderType.benefits,
        label: _labelBenefitsEnrollment,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'insurance coverage',
        folderType: WorkDocumentFolderType.benefits,
        label: _labelInsuranceCoverage,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'salary slip',
        folderType: WorkDocumentFolderType.payslips,
        label: _labelSalarySlip,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'resignation letter',
        folderType: WorkDocumentFolderType.offboarding,
        label: _labelResignationLetter,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'termination notice',
        folderType: WorkDocumentFolderType.offboarding,
        label: _labelTerminationNotice,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'final settlement',
        folderType: WorkDocumentFolderType.offboarding,
        label: _labelFinalSettlement,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'end of service certificate',
        folderType: WorkDocumentFolderType.offboarding,
        label: _labelEndOfServiceCert,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'non-compete agreement',
        folderType: WorkDocumentFolderType.contracts,
        label: _labelNonCompete,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'reference letter',
        folderType: WorkDocumentFolderType.milestones,
        label: _labelReferenceLetter,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'performance review',
        folderType: WorkDocumentFolderType.milestones,
        label: _labelPerformanceReview,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'promotion letter',
        folderType: WorkDocumentFolderType.milestones,
        label: _labelPromotionLetter,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'training certificate',
        folderType: WorkDocumentFolderType.milestones,
        label: _labelTrainingCert,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'quittance',
        folderType: WorkDocumentFolderType.other,
        label: _labelQuittance,
      ),
      _WorkDocumentTypeOption(
        translationKey: 'other work document',
        folderType: WorkDocumentFolderType.other,
        label: _labelOtherWorkDocument,
      ),
    ];

String _labelEmploymentContract(AppLocalizations l10n) =>
    l10n.workManualEntryTypeEmploymentContract;

String _labelEmployerCertificate(AppLocalizations l10n) =>
    l10n.workManualEntryTypeEmployerCertificate;

String _labelInternshipAgreement(AppLocalizations l10n) =>
    l10n.workManualEntryTypeInternshipAgreement;

String _labelTaxDeclaration(AppLocalizations l10n) =>
    l10n.workManualEntryTypeTaxDeclaration;

String _labelTaxCertificate(AppLocalizations l10n) =>
    l10n.workManualEntryTypeTaxCertificate;

String _labelBenefitsEnrollment(AppLocalizations l10n) =>
    l10n.workManualEntryTypeBenefitsEnrollment;

String _labelInsuranceCoverage(AppLocalizations l10n) =>
    l10n.workManualEntryTypeInsuranceCoverage;

String _labelResignationLetter(AppLocalizations l10n) =>
    l10n.workManualEntryTypeResignationLetter;

String _labelTerminationNotice(AppLocalizations l10n) =>
    l10n.workManualEntryTypeTerminationNotice;

String _labelPerformanceReview(AppLocalizations l10n) =>
    l10n.workManualEntryTypePerformanceReview;

String _labelPromotionLetter(AppLocalizations l10n) =>
    l10n.workManualEntryTypePromotionLetter;

String _labelFinalSettlement(AppLocalizations l10n) =>
    l10n.workManualEntryTypeFinalSettlement;

String _labelEndOfServiceCert(AppLocalizations l10n) =>
    l10n.workManualEntryTypeEndOfServiceCert;

String _labelNonCompete(AppLocalizations l10n) =>
    l10n.workManualEntryTypeNonCompete;

String _labelSalarySlip(AppLocalizations l10n) =>
    l10n.workManualEntryTypeSalarySlip;

String _labelReferenceLetter(AppLocalizations l10n) =>
    l10n.workManualEntryTypeReferenceLetter;

String _labelTrainingCert(AppLocalizations l10n) =>
    l10n.workManualEntryTypeTrainingCert;

String _labelQuittance(AppLocalizations l10n) =>
    l10n.workManualEntryTypeQuittance;

String _labelOtherWorkDocument(AppLocalizations l10n) =>
    l10n.workManualEntryTypeOther;
