import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/gestures.dart';
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
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_vaults.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/work_documents_design.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class WorkPayslipEntryPage extends StatefulWidget {
  const WorkPayslipEntryPage({
    super.key,
    required this.initialCompanyName,
    this.initialCompanyLogoPath,
    this.documentToEdit,
  });

  final String initialCompanyName;
  final String? initialCompanyLogoPath;
  final DocumentDetailEntity? documentToEdit;

  @override
  State<WorkPayslipEntryPage> createState() => _WorkPayslipEntryPageState();
}

class _WorkPayslipEntryPageState extends State<WorkPayslipEntryPage> {
  final _netSalaryController = TextEditingController();
  final _imagePicker = ImagePicker();
  final Map<String, TextEditingController> _uploadTitleControllers =
      <String, TextEditingController>{};

  late int _selectedYear;
  late int _selectedMonth;
  String _selectedCurrencyCode = _currencyOptions.first.code;
  bool _isSaving = false;
  bool _isPickingUpload = false;
  bool _isLoadingCompanies = false;
  String _uploadedFilePath = '';
  String _uploadedFileName = '';
  String _uploadedFileMime = '';
  List<_SelectedPayslipUpload> _selectedUploads =
      const <_SelectedPayslipUpload>[];
  DocumentCaptureSource _captureSource = DocumentCaptureSource.gallery;
  _PayslipFileSource _selectedSourceOption = _PayslipFileSource.gallery;
  List<WorkCompanyVaultEntity> _companies = const <WorkCompanyVaultEntity>[];
  WorkCompanyVaultEntity? _selectedCompany;

  CreateScannedDocument get _createUseCase => getIt();
  UpdateDocument get _updateUseCase => getIt();
  GetWorkCompanyVaults get _getWorkCompaniesUseCase => getIt();

  bool get _isEditing => widget.documentToEdit != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _bootstrapEdit();
    unawaited(_loadCompanies());
  }

  void _bootstrapEdit() {
    final detail = widget.documentToEdit;
    if (detail == null) return;

    final fields = detail.structuredFields;
    String findField(List<String> labels) {
      for (final target in labels) {
        final t = target.trim().toLowerCase();
        for (final f in fields) {
          final l = f.label.trim().toLowerCase();
          final c = DocumentMetadataFieldLabels.toCanonicalClaimKey(f.label);
          if (l == t || c == t) {
            final v = f.value.trim();
            if (v.isNotEmpty) return v;
          }
        }
      }
      return '';
    }

    final dateRaw = findField(const [
      DocumentMetadataFieldLabels.workStatementDate,
      DocumentMetadataFieldLabels.workStartDate,
    ]);
    final parsed = DateTime.tryParse(dateRaw);
    if (parsed != null) {
      _selectedYear = parsed.year;
      _selectedMonth = parsed.month;
    }

    _netSalaryController.text = findField(const [
      DocumentMetadataFieldLabels.workStatementNetAmount,
    ]);

    final currency = findField(const [
      DocumentMetadataFieldLabels.workStatementCurrency,
    ]);
    if (currency.isNotEmpty) {
      _selectedCurrencyCode = currency;
    }

    final filePath = findField(const [
      DocumentMetadataFieldLabels.frontImagePath,
      DocumentMetadataFieldLabels.referenceAssetPath,
    ]);
    final title = findField(const [
      DocumentMetadataFieldLabels.workStatementTitle,
      'Document Title',
    ]);
    if (filePath.isNotEmpty) {
      _uploadedFilePath = filePath;
      _uploadedFileName = filePath.split('/').last;
      _uploadedFileMime = filePath.inferMimeType();
      _selectedUploads = <_SelectedPayslipUpload>[
        _SelectedPayslipUpload(
          path: _uploadedFilePath.trim(),
          name: _uploadedFileName,
          mime: _uploadedFileMime,
        ),
      ];
      _syncUploadTitleControllers(
        _selectedUploads,
        initialTitles: <String, String>{filePath.trim(): title},
      );
    }
  }

  @override
  void dispose() {
    _netSalaryController.dispose();
    for (final controller in _uploadTitleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedCompany = _selectedCompany;
    final uploads = _activeUploads;
    final hasUpload = uploads.isNotEmpty;
    final canSave =
        !_isSaving && !_isPickingUpload && selectedCompany != null && hasUpload;

    return Scaffold(
      backgroundColor: context.appPalette.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    WorkSheetHeader(
                      title: _isEditing
                          ? l10n.commonEdit
                          : l10n.workPayslipAddTitle,
                      onCancel: () => Navigator.of(context).maybePop(),
                      onSave: _savePayslip,
                      saveLabel: uploads.length > 1
                          ? '${l10n.commonSave} · ${uploads.length}'
                          : l10n.commonSave,
                      saveEnabled: canSave,
                      isSaving: _isSaving,
                    ),
                    WorkEditorSectionLabel(value: 'Shared for all files'),
                    _payslipSharedFields(context, selectedCompany),
                    if (_isLoadingCompanies) ...[
                      SizedBox(height: 8),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    WorkEditorSectionLabel(
                      value: hasUpload
                          ? (uploads.length == 1
                                ? 'Document · 1 file'
                                : '${uploads.length} documents · individual titles')
                          : 'Document',
                    ),
                    if (!hasUpload)
                      _uploadMethodCard(context)
                    else ...[
                      ...uploads.asMap().entries.map(
                        (entry) => Padding(
                          padding: EdgeInsets.only(
                            bottom: entry.key == uploads.length - 1 ? 0 : 10,
                          ),
                          child: _selectedUploadRow(
                            context,
                            upload: entry.value,
                            index: entry.key,
                            totalUploads: uploads.length,
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
                      value: l10n.workPayslipSectionPaymentMonth,
                    ),
                    const SizedBox(height: 8),
                    _paymentMonthSelector(context),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        WorkEditorSectionLabel(
                          value: l10n.workPayslipSectionNetSalary,
                        ),
                        const Spacer(),
                        Text(
                          l10n.workPayslipOptional,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.appPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _netSalaryInput(context),
                    SizedBox(height: 22),
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

  Widget _payslipSharedFields(
    BuildContext context,
    WorkCompanyVaultEntity? selectedCompany,
  ) {
    final l10n = context.l10n;
    final companyName = selectedCompany?.companyName.trim() ?? '';
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateText = DateFormat.MMMMd(
      localeTag,
    ).format(DateTime(_selectedYear, _selectedMonth, 1));
    return WorkFieldGroup(
      children: [
        WorkPickerField(
          label: 'Type',
          value: WorkDocumentFolderType.payslips.label,
          trailing: const SizedBox(width: 18),
        ),
        WorkPickerField(
          label: l10n.workPayslipSectionTargetVault,
          value: companyName.isEmpty
              ? l10n.workPayslipSelectCompanyPlaceholder
              : companyName,
          leading: WorkCompanyLogo(
            name: companyName.isEmpty ? 'Company' : companyName,
            logoPath: selectedCompany?.companyLogoPath,
            size: 28,
            tint: WorkTint.mint,
          ),
          onTap: _isLoadingCompanies ? null : _pickCompany,
        ),
        WorkPickerField(
          label: l10n.workPayslipSectionPaymentMonth,
          value: '$dateText $_selectedYear',
          monospaceValue: true,
          trailing: Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: context.appPalette.textMuted,
          ),
          onTap: _pickYear,
        ),
      ],
    );
  }

  Widget _selectedUploadRow(
    BuildContext context, {
    required _SelectedPayslipUpload upload,
    required int index,
    required int totalUploads,
  }) {
    final fileType = resolveFileTypeLabel(path: upload.path, mime: upload.mime);
    return WorkBatchUploadRow(
      fileName: upload.name,
      fileMeta:
          '${context.l10n.workManualEntrySelectedDocumentLabel(index + 1)} · $fileType',
      controller: _titleControllerFor(upload),
      hintText: context.l10n.workManualEntryDocumentTitleHint,
      path: upload.path,
      mime: upload.mime,
      onRemove: !_isEditing && totalUploads > 1
          ? () => _removeUpload(upload)
          : null,
    );
  }

  int get _sourceIndex {
    return switch (_selectedSourceOption) {
      _PayslipFileSource.gallery => 1,
      _PayslipFileSource.camera => 2,
      _PayslipFileSource.files => 0,
    };
  }

  _PayslipFileSource _fileSourceForIndex(int index) {
    return switch (index) {
      1 => _PayslipFileSource.gallery,
      2 => _PayslipFileSource.camera,
      _ => _PayslipFileSource.files,
    };
  }

  Widget _paymentMonthSelector(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: const MaterialScrollBehavior().copyWith(
                dragDevices: const <PointerDeviceKind>{
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                },
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(12, (index) {
                    final month = index + 1;
                    final label = DateFormat.MMM(
                      localeTag,
                    ).format(DateTime(_selectedYear, month, 1));
                    final active = month == _selectedMonth;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonth = month;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        width: 72,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: active
                              ? context.appPalette.primarySoft
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: active
                                ? const Color(0xFF1D56D5)
                                : context.appPalette.textMuted,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pickYear,
            child: Container(
              width: 82,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: context.appPalette.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                '$_selectedYear',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _netSalaryInput(BuildContext context) {
    final selectedCurrency = _currencyOptions.firstWhere(
      (option) => option.code == _selectedCurrencyCode,
      orElse: () => _currencyOptions.first,
    );
    return Container(
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 126,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCurrencyCode,
              isDense: true,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: context.appPalette.textMuted,
              ),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1,
                color: context.appPalette.textPrimary,
              ),
              selectedItemBuilder: (context) => _currencyOptions
                  .map(
                    (option) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        option.code,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: context.appPalette.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              items: _currencyOptions
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option.code,
                      child: Text(
                        option.code,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: context.appPalette.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedCurrencyCode = value;
                });
              },
            ),
          ),
          Container(width: 1, height: 36, color: context.appPalette.stroke),
          Expanded(
            child: TextField(
              controller: _netSalaryController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                prefixText: '${selectedCurrency.symbol} ',
                prefixStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.textMuted,
                ),
                hintText: context.l10n.workPayslipNetSalaryHint,
                hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickYear() async {
    final years = List<int>.generate(
      126,
      (index) => DateTime.now().year + 5 - index,
    );
    final picked = await showAdaptiveModal<int>(
      context: context,
      backgroundColor: context.appPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
            itemBuilder: (context, index) {
              final year = years[index];
              final selected = year == _selectedYear;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: selected ? context.appPalette.primarySoft : null,
                title: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? const Color(0xFF1D56D5)
                        : context.appPalette.textPrimary,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(year),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemCount: years.length,
          ),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedYear = picked;
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
        final initialName = widget.initialCompanyName.trim().toLowerCase();
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

      if (selected == null && widget.initialCompanyName.trim().isNotEmpty) {
        selected = _fallbackCompany(
          name: widget.initialCompanyName,
          logoPath: widget.initialCompanyLogoPath,
        );
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
      final fallback = widget.initialCompanyName.trim().isEmpty
          ? null
          : _fallbackCompany(
              name: widget.initialCompanyName,
              logoPath: widget.initialCompanyLogoPath,
            );
      setState(() {
        _companies = const <WorkCompanyVaultEntity>[];
        _selectedCompany = fallback;
        _isLoadingCompanies = false;
      });
    }
  }

  WorkCompanyVaultEntity _fallbackCompany({
    required String name,
    required String? logoPath,
  }) {
    final now = DateTime.now();
    return WorkCompanyVaultEntity(
      companyId: _slugify(name),
      companyName: name.trim(),
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
      companyLogoPath: (logoPath ?? '').trim().isEmpty ? null : logoPath,
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
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n.documentFilesCount(item.documentsCount),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

  Widget _uploadMethodCard(BuildContext context) {
    final l10n = context.l10n;
    final uploads = _activeUploads;
    final hasUpload = uploads.isNotEmpty;
    final primaryUpload = uploads.isEmpty ? null : uploads.first;
    final subtitle = hasUpload
        ? uploads.length == 1
              ? '${primaryUpload!.name} • ${resolveFileTypeLabel(path: primaryUpload.path, mime: primaryUpload.mime)}'
              : '${l10n.documentFilesCount(uploads.length)} • ${primaryUpload!.name}'
        : '${l10n.workPayslipMethodUploadPdfSubtitle}\n${l10n.idEntryMultipleFilesHint}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (_isPickingUpload || _isSaving) ? null : _pickUploadFile,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: hasUpload
                ? context.appPalette.primarySoft
                : context.appPalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasUpload
                  ? const Color(0xFFC4D5FF)
                  : context.appPalette.stroke,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: hasUpload
                      ? context.appPalette.primarySoft
                      : context.appPalette.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  hasUpload
                      ? Icons.check_circle_rounded
                      : Icons.upload_file_rounded,
                  color: context.appPalette.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.workPayslipMethodUploadPdfTitle,
                      style: TextStyle(
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: hasUpload
                            ? const Color(0xFF2851B7)
                            : context.appPalette.textSecondary,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
              _isPickingUpload
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      hasUpload
                          ? Icons.refresh_rounded
                          : Icons.chevron_right_rounded,
                      size: 22,
                      color: context.appPalette.textMuted,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickUploadFile({_PayslipFileSource? sourceOverride}) async {
    if (_isPickingUpload || _isSaving) {
      return;
    }
    final l10n = context.l10n;
    setState(() {
      _isPickingUpload = true;
    });
    try {
      List<String> sourcePaths = const <String>[];
      DocumentCaptureSource source = DocumentCaptureSource.gallery;
      final pickedSource =
          sourceOverride ??
          await showAdaptiveModal<_PayslipFileSource>(
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
                        title: context.l10n.workPayslipPickCamera,
                        icon: Icons.photo_camera_rounded,
                        onTap: () => Navigator.of(
                          context,
                        ).pop(_PayslipFileSource.camera),
                      ),
                      const SizedBox(height: 8),
                      _sourceTile(
                        title: context.l10n.profileChooseFromLibrary,
                        icon: Icons.photo_library_rounded,
                        onTap: () => Navigator.of(
                          context,
                        ).pop(_PayslipFileSource.gallery),
                      ),
                      const SizedBox(height: 8),
                      _sourceTile(
                        title: context.l10n.idEntryChooseFile,
                        icon: Icons.folder_open_rounded,
                        onTap: () =>
                            Navigator.of(context).pop(_PayslipFileSource.files),
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
        case _PayslipFileSource.camera:
          final sourcePath = await _pickImageFromCamera();
          sourcePaths = sourcePath == null
              ? const <String>[]
              : <String>[sourcePath];
          source = DocumentCaptureSource.camera;
          break;
        case _PayslipFileSource.gallery:
          sourcePaths = await _pickImagesFromGallery();
          source = DocumentCaptureSource.gallery;
          break;
        case _PayslipFileSource.files:
          sourcePaths = await _pickUploadsFromFileBrowser();
          source = DocumentCaptureSource.gallery;
          break;
      }
      if (!mounted) {
        return;
      }

      if (sourcePaths.isEmpty) {
        return;
      }

      final uploads = <_SelectedPayslipUpload>[];
      for (final rawPath in sourcePaths) {
        final normalized = _normalizeLocalPath(rawPath);
        if (normalized.isEmpty) {
          continue;
        }
        if (!_isSupportedUploadPath(normalized)) {
          _showToast(l10n.idEntryPickImageOrPdf);
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
          _SelectedPayslipUpload(
            path: persisted,
            name: _fileNameFromPath(persisted),
            mime: persisted.inferMimeType(),
          ),
        );
      }
      if (uploads.isEmpty) {
        return;
      }
      _syncUploadTitleControllers(uploads);
      setState(() {
        _captureSource = source;
        _selectedSourceOption = pickedSource;
        _selectedUploads = uploads;
        _uploadedFilePath = uploads.first.path;
        _uploadedFileName = uploads.first.name;
        _uploadedFileMime = uploads.first.mime;
      });
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
            ],
            uniformTypeIdentifiers: [
              'public.jpeg',
              'public.png',
              'public.heic',
              'org.webmproject.webp',
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
      directoryName: 'work_statement_assets',
      fileNamePrefix: 'payslip_$companySlug',
    );
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

  Future<void> _savePayslip() async {
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
      _showToast(context.l10n.workPayslipSelectFileFirst);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final statementDate = DateTime(_selectedYear, _selectedMonth, 1);
      final dateIso = DateFormat('yyyy-MM-dd').format(statementDate);
      final localeTag = Localizations.localeOf(context).toLanguageTag();
      final monthLabel = DateFormat(
        'MMMM yyyy',
        localeTag,
      ).format(statementDate);
      final baseTitle = context.l10n.workPayslipTitleTemplate(monthLabel);
      final netAmount = _netSalaryController.text.trim();
      final currency = _selectedCurrencyCode;
      final companyName = selectedCompany.companyName.trim();
      final companyId = selectedCompany.companyId.trim().isEmpty
          ? _slugify(companyName)
          : selectedCompany.companyId.trim();
      final companyLogoPath = (selectedCompany.companyLogoPath ?? '').trim();
      final detailToEdit = widget.documentToEdit;
      final savedIds = <String>[];
      final failedUploads = <_SelectedPayslipUpload>[];
      for (final upload in uploads) {
        final title = _resolvedPayslipTitle(
          baseTitle: baseTitle,
          upload: upload,
          totalUploads: uploads.length,
        );
        final referencePayload = <Map<String, String>>[
          {
            'name': upload.name,
            'path': upload.path,
            'mime': upload.mime,
            'label': WorkDocumentFolderType.payslips.label,
          },
        ];

        final fields =
            <Map<String, String>>[
                  {'label': 'Company Name', 'value': companyName},
                  {'label': 'Document Title', 'value': title},
                  {
                    'label': 'Folder Type',
                    'value': WorkDocumentFolderType.payslips.label,
                  },
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
                    'value': WorkDocumentFolderType.payslips.key,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workRecordType,
                    'value': 'statement',
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workStatementTitle,
                    'value': title,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workStatementDate,
                    'value': dateIso,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workStatementNetAmount,
                    'value': netAmount,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workStatementCurrency,
                    'value': currency,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.workStatementStatus,
                    'value': 'active',
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
                    'value': WorkDocumentFolderType.payslips.label,
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
                    'value': WorkDocumentFolderType.payslips.key,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkRecordType,
                    'value': 'statement',
                  },
                  {
                    'label':
                        DocumentMetadataFieldLabels.claimWorkStatementTitle,
                    'value': title,
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkStatementDate,
                    'value': dateIso,
                  },
                  {
                    'label':
                        DocumentMetadataFieldLabels.claimWorkStatementNetAmount,
                    'value': netAmount,
                  },
                  {
                    'label':
                        DocumentMetadataFieldLabels.claimWorkStatementCurrency,
                    'value': currency,
                  },
                  {
                    'label':
                        DocumentMetadataFieldLabels.claimWorkStatementStatus,
                    'value': 'active',
                  },
                  {
                    'label': DocumentMetadataFieldLabels.claimWorkPinned,
                    'value': 'false',
                  },
                ]
                .where((field) => (field['value'] ?? '').trim().isNotEmpty)
                .toList(growable: false);

        try {
          final saved = detailToEdit != null
              ? await _updateUseCase(
                  UpdateDocumentParams(
                    documentId: detailToEdit.id,
                    type: DocumentType.other,
                    source: _captureSource,
                    scanPagesCount: detailToEdit.scanPagesCount,
                    categoryOverride: DocumentCategoryType.work,
                    documentTypeKeyOverride: 'other',
                    issuerOverride: companyName,
                    identifierLabelOverride:
                        WorkDocumentFolderType.payslips.label,
                    identifierValueOverride: title,
                    structuredFieldsOverride: fields,
                    tagsOverride: const <String>['Payslips', 'Work'],
                  ),
                )
              : await _createUseCase(
                  CreateScannedDocumentParams(
                    type: DocumentType.other,
                    source: _captureSource,
                    scanPagesCount: 1,
                    categoryOverride: DocumentCategoryType.work,
                    documentTypeKeyOverride: 'other',
                    issuerOverride: companyName,
                    identifierLabelOverride:
                        WorkDocumentFolderType.payslips.label,
                    identifierValueOverride: title,
                    structuredFieldsOverride: fields,
                    tagsOverride: const <String>['Payslips', 'Work'],
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
        _syncUploadTitleControllers(failedUploads);
        setState(() {
          _selectedUploads = failedUploads;
          _uploadedFilePath = failedUploads.first.path;
          _uploadedFileName = failedUploads.first.name;
          _uploadedFileMime = failedUploads.first.mime;
        });
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

  String _slugify(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'company' : normalized;
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<_SelectedPayslipUpload> get _activeUploads {
    if (_selectedUploads.isNotEmpty) {
      return _selectedUploads;
    }
    final uploadPath = _uploadedFilePath.trim();
    if (uploadPath.isEmpty) {
      return const <_SelectedPayslipUpload>[];
    }
    return <_SelectedPayslipUpload>[
      _SelectedPayslipUpload(
        path: uploadPath,
        name: _uploadedFileName.trim().isEmpty
            ? _fileNameFromPath(uploadPath)
            : _uploadedFileName.trim(),
        mime: _uploadedFileMime.trim().isEmpty
            ? uploadPath.inferMimeType()
            : _uploadedFileMime.trim(),
      ),
    ];
  }

  TextEditingController _titleControllerFor(_SelectedPayslipUpload upload) {
    return _uploadTitleControllers.putIfAbsent(
      upload.path,
      () => TextEditingController(text: _defaultPayslipTitle(upload)),
    );
  }

  void _syncUploadTitleControllers(
    List<_SelectedPayslipUpload> uploads, {
    Map<String, String> initialTitles = const <String, String>{},
  }) {
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
              ? _defaultPayslipTitle(upload)
              : seededTitle,
        ),
      );
    }
  }

  void _removeUpload(_SelectedPayslipUpload upload) {
    final remaining = _selectedUploads
        .where((item) => item.path != upload.path)
        .toList(growable: false);
    _uploadTitleControllers.remove(upload.path)?.dispose();
    _syncUploadTitleControllers(remaining);
    setState(() {
      _selectedUploads = remaining;
      if (remaining.isEmpty) {
        _uploadedFilePath = '';
        _uploadedFileName = '';
        _uploadedFileMime = '';
      } else {
        _uploadedFilePath = remaining.first.path;
        _uploadedFileName = remaining.first.name;
        _uploadedFileMime = remaining.first.mime;
      }
    });
  }

  String _resolvedPayslipTitle({
    required String baseTitle,
    required _SelectedPayslipUpload upload,
    required int totalUploads,
  }) {
    final explicit = _uploadTitleControllers[upload.path]?.text.trim() ?? '';
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final trimmedBaseTitle = baseTitle.trim();
    if (totalUploads <= 1) {
      return trimmedBaseTitle;
    }
    final fileTitle = _defaultPayslipTitle(upload);
    return fileTitle.isEmpty ? trimmedBaseTitle : fileTitle;
  }

  String _defaultPayslipTitle(_SelectedPayslipUpload upload) {
    final readable = _fileStem(
      upload.name,
    ).replaceAll(RegExp(r'[_-]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
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
}

class _SelectedPayslipUpload {
  const _SelectedPayslipUpload({
    required this.path,
    required this.name,
    required this.mime,
  });

  final String path;
  final String name;
  final String mime;
}

class _CurrencyOption {
  const _CurrencyOption({required this.code, required this.symbol});

  final String code;
  final String symbol;
}

enum _PayslipFileSource { camera, gallery, files }

const List<_CurrencyOption> _currencyOptions = <_CurrencyOption>[
  _CurrencyOption(code: 'USD', symbol: r'$'),
  _CurrencyOption(code: 'EUR', symbol: '€'),
  _CurrencyOption(code: 'GBP', symbol: '£'),
  _CurrencyOption(code: 'CHF', symbol: 'CHF'),
  _CurrencyOption(code: 'TND', symbol: 'TND'),
  _CurrencyOption(code: 'AED', symbol: 'AED'),
  _CurrencyOption(code: 'SAR', symbol: 'SAR'),
  _CurrencyOption(code: 'MAD', symbol: 'MAD'),
  _CurrencyOption(code: 'JPY', symbol: 'JPY'),
  _CurrencyOption(code: 'CAD', symbol: 'CAD'),
  _CurrencyOption(code: 'AUD', symbol: 'AUD'),
];

const Set<String> _supportedUploadExtensions = <String>{
  'jpg',
  'jpeg',
  'png',
  'webp',
  'heic',
  'pdf',
};
