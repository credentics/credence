import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/domain/branding/entities/company_brand_search_result_entity.dart';
import 'package:pass_doc_manager/domain/branding/usecases/download_company_logo_to_local.dart';
import 'package:pass_doc_manager/domain/branding/usecases/search_company_brands.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_vaults.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/services/address_lookup_service.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/work_documents_design.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class WorkCompanyEntryPage extends StatefulWidget {
  const WorkCompanyEntryPage({
    super.key,
    CreateScannedDocument? createScannedDocument,
    GetWorkCompanyVaults? getWorkCompanyVaults,
    SearchCompanyBrands? searchCompanyBrands,
    DownloadCompanyLogoToLocal? downloadCompanyLogoToLocal,
    UpdateDocument? updateDocument,
    this.editDocumentId,
    this.initialDetail,
  }) : _createScannedDocument = createScannedDocument,
       _getWorkCompanyVaults = getWorkCompanyVaults,
       _searchCompanyBrands = searchCompanyBrands,
       _downloadCompanyLogoToLocal = downloadCompanyLogoToLocal,
       _updateDocument = updateDocument;

  final CreateScannedDocument? _createScannedDocument;
  final GetWorkCompanyVaults? _getWorkCompanyVaults;
  final SearchCompanyBrands? _searchCompanyBrands;
  final DownloadCompanyLogoToLocal? _downloadCompanyLogoToLocal;
  final UpdateDocument? _updateDocument;
  final String? editDocumentId;
  final WorkCompanyDetailEntity? initialDetail;

  @override
  State<WorkCompanyEntryPage> createState() => _WorkCompanyEntryPageState();
}

class _WorkCompanyEntryPageState extends State<WorkCompanyEntryPage> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _roleController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _contactController = TextEditingController();
  final _entryDateController = TextEditingController();
  final _endDateController = TextEditingController();

  final _imagePicker = ImagePicker();
  final _addressLookupService = AddressLookupService();

  bool _isOngoing = true;
  bool _isSaving = false;
  bool _isDetectingLogo = false;
  bool _isPickingLogo = false;
  String _logoLocalPath = '';
  String _logoRemoteUrl = '';
  DateTime? _entryDate;
  DateTime? _endDate;
  Timer? _addressDebounce;
  int _addressSearchToken = 0;
  bool _isAddressSearching = false;
  bool _showAddressSuggestions = false;
  bool _isApplyingAddressSelection = false;
  AddressSuggestion? _selectedOfficeAddress;
  List<AddressSuggestion> _addressSuggestions = const <AddressSuggestion>[];
  bool _isLoadingExistingCompanies = false;
  bool _showCompanySuggestions = false;
  bool _isApplyingCompanySelection = false;
  List<WorkCompanyVaultEntity> _existingCompanies =
      const <WorkCompanyVaultEntity>[];
  List<WorkCompanyVaultEntity> _companySuggestions =
      const <WorkCompanyVaultEntity>[];
  Timer? _brandSearchDebounce;
  int _brandSearchToken = 0;
  bool _isSearchingBrandSuggestions = false;
  List<CompanyBrandSearchResultEntity> _brandSuggestions =
      const <CompanyBrandSearchResultEntity>[];

  CreateScannedDocument get _createUseCase =>
      widget._createScannedDocument ?? getIt();
  GetWorkCompanyVaults get _getWorkCompaniesUseCase =>
      widget._getWorkCompanyVaults ?? getIt();
  SearchCompanyBrands get _searchLogoUseCase =>
      widget._searchCompanyBrands ?? getIt();
  DownloadCompanyLogoToLocal get _downloadLogoUseCase =>
      widget._downloadCompanyLogoToLocal ?? getIt();
  UpdateDocument get _updateUseCase => widget._updateDocument ?? getIt();

  bool get _isEditMode => (widget.editDocumentId ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _applyInitialDetail(widget.initialDetail);
    _companyNameController.addListener(_onCompanyNameChanged);
    _officeAddressController.addListener(_onOfficeAddressChanged);
    unawaited(_loadExistingCompanies());
  }

  @override
  void dispose() {
    _brandSearchDebounce?.cancel();
    _addressDebounce?.cancel();
    _companyNameController.removeListener(_onCompanyNameChanged);
    _officeAddressController.removeListener(_onOfficeAddressChanged);
    _companyNameController.dispose();
    _roleController.dispose();
    _officeAddressController.dispose();
    _contactController.dispose();
    _entryDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPalette.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    if (_showAddressSuggestions || _showCompanySuggestions) {
                      setState(() {
                        _showAddressSuggestions = false;
                        _showCompanySuggestions = false;
                      });
                    }
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      WorkSheetHeader(
                        title: _isEditMode
                            ? context.l10n.workCompanyEditTitle
                            : context.l10n.workCompanyAddTitle,
                        onCancel: () => Navigator.of(context).maybePop(),
                        onSave: _save,
                        saveLabel: context.l10n.commonSave,
                        saveEnabled: !_isSaving && !_isPickingLogo,
                        isSaving: _isSaving,
                      ),
                      _sectionTitle('COMPANY LOGO'),
                      const SizedBox(height: 10),
                      _logoCard(context),
                      const SizedBox(height: 18),
                      _sectionTitle('COMPANY INFORMATION'),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _companyNameInput(context),
                            const SizedBox(height: 12),
                            _input(
                              controller: _roleController,
                              label: context.l10n.workCompanyFieldRole,
                              hint: 'e.g. Senior Engineer',
                              icon: Icons.badge_outlined,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _dateInput(
                                    controller: _entryDateController,
                                    label:
                                        context.l10n.workCompanyFieldEntryDate,
                                    hint: 'mm/dd/yy',
                                    onTap: () => _pickDate(
                                      current: _entryDate,
                                      onPicked: (value) {
                                        _entryDate = value;
                                        _entryDateController.text = DateFormat(
                                          'MM/dd/yy',
                                        ).format(value);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: _residencyToggle()),
                              ],
                            ),
                            if (!_isOngoing) ...[
                              const SizedBox(height: 12),
                              _dateInput(
                                controller: _endDateController,
                                label: context.l10n.workCompanyFieldEndDate,
                                hint: 'mm/dd/yy',
                                onTap: () => _pickDate(
                                  current: _endDate,
                                  onPicked: (value) {
                                    _endDate = value;
                                    _endDateController.text = DateFormat(
                                      'MM/dd/yy',
                                    ).format(value);
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _officeAddressInput(context),
                            const SizedBox(height: 10),
                            _mapPreviewCard(context),
                            const SizedBox(height: 12),
                            _input(
                              controller: _contactController,
                              label: context.l10n.workCompanyFieldContact,
                              hint: context.l10n.workCompanyHintContact,
                              icon: Icons.phone_outlined,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: (_isSaving || _isPickingLogo) ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.shield_outlined, size: 19),
                        label: Text(
                          _isSaving
                              ? context.l10n.commonSaving
                              : (_isEditMode
                                    ? context.l10n.commonSave
                                    : 'Create Company Vault'),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: context.appPalette.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: context.appPalette.primary
                              .withValues(alpha: 0.55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: workFontBody,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isSaving)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadExistingCompanies() async {
    if (_isLoadingExistingCompanies) {
      return;
    }
    setState(() {
      _isLoadingExistingCompanies = true;
    });
    try {
      final companies = await _getWorkCompaniesUseCase(
        const GetWorkCompanyVaultsParams(),
      );
      if (!mounted) {
        return;
      }
      final uniqueByName = <String, WorkCompanyVaultEntity>{};
      for (final company in companies) {
        final key = company.companyName.trim().toLowerCase();
        if (key.isEmpty || uniqueByName.containsKey(key)) {
          continue;
        }
        uniqueByName[key] = company;
      }
      final values = uniqueByName.values.toList(growable: false)
        ..sort(
          (a, b) => a.companyName.toLowerCase().compareTo(
            b.companyName.toLowerCase(),
          ),
        );
      setState(() {
        _isLoadingExistingCompanies = false;
        _existingCompanies = values;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingExistingCompanies = false;
        _existingCompanies = const <WorkCompanyVaultEntity>[];
      });
    }
  }

  void _onCompanyNameChanged() {
    if (_isApplyingCompanySelection) {
      return;
    }
    final query = _companyNameController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _brandSearchDebounce?.cancel();
      _brandSearchToken++;
      if (_showCompanySuggestions ||
          _companySuggestions.isNotEmpty ||
          _brandSuggestions.isNotEmpty ||
          _isSearchingBrandSuggestions) {
        setState(() {
          _showCompanySuggestions = false;
          _companySuggestions = const <WorkCompanyVaultEntity>[];
          _brandSuggestions = const <CompanyBrandSearchResultEntity>[];
          _isSearchingBrandSuggestions = false;
        });
      }
      return;
    }
    final suggestions = _existingCompanies
        .where((item) => item.companyName.toLowerCase().contains(query))
        .take(6)
        .toList(growable: false);
    setState(() {
      _companySuggestions = suggestions;
      _showCompanySuggestions =
          suggestions.isNotEmpty ||
          _brandSuggestions.isNotEmpty ||
          _isSearchingBrandSuggestions;
    });
    _scheduleBrandSuggestionLookup(query);
  }

  void _scheduleBrandSuggestionLookup(String query) {
    _brandSearchDebounce?.cancel();
    if (query.length < 2) {
      if (_brandSuggestions.isNotEmpty || _isSearchingBrandSuggestions) {
        setState(() {
          _brandSuggestions = const <CompanyBrandSearchResultEntity>[];
          _isSearchingBrandSuggestions = false;
          _showCompanySuggestions = _companySuggestions.isNotEmpty;
        });
      }
      return;
    }
    final token = ++_brandSearchToken;
    _brandSearchDebounce = Timer(const Duration(milliseconds: 260), () async {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSearchingBrandSuggestions = true;
        _showCompanySuggestions = true;
      });
      try {
        final results = await _searchLogoUseCase(query: query);
        if (!mounted || token != _brandSearchToken) {
          return;
        }
        final current = _companyNameController.text.trim().toLowerCase();
        if (current != query) {
          return;
        }
        final merged = <String>{};
        final filtered = <CompanyBrandSearchResultEntity>[];
        for (final item in results) {
          final key = '${item.name.trim().toLowerCase()}|${item.domain}';
          if (merged.contains(key)) {
            continue;
          }
          merged.add(key);
          filtered.add(item);
          if (filtered.length >= 6) {
            break;
          }
        }
        setState(() {
          _isSearchingBrandSuggestions = false;
          _brandSuggestions = filtered;
          _showCompanySuggestions =
              _companySuggestions.isNotEmpty || filtered.isNotEmpty;
        });
      } catch (_) {
        if (!mounted || token != _brandSearchToken) {
          return;
        }
        setState(() {
          _isSearchingBrandSuggestions = false;
          _brandSuggestions = const <CompanyBrandSearchResultEntity>[];
          _showCompanySuggestions = _companySuggestions.isNotEmpty;
        });
      }
    });
  }

  void _selectCompanySuggestion(WorkCompanyVaultEntity company) {
    _isApplyingCompanySelection = true;
    _companyNameController.value = TextEditingValue(
      text: company.companyName,
      selection: TextSelection.collapsed(offset: company.companyName.length),
    );
    _isApplyingCompanySelection = false;
    setState(() {
      _showCompanySuggestions = false;
      _companySuggestions = const <WorkCompanyVaultEntity>[];
      _brandSuggestions = const <CompanyBrandSearchResultEntity>[];
      _isSearchingBrandSuggestions = false;
    });
  }

  Future<void> _selectBrandSuggestion(
    CompanyBrandSearchResultEntity suggestion,
  ) async {
    _isApplyingCompanySelection = true;
    _companyNameController.value = TextEditingValue(
      text: suggestion.name,
      selection: TextSelection.collapsed(offset: suggestion.name.length),
    );
    _isApplyingCompanySelection = false;
    setState(() {
      _showCompanySuggestions = false;
      _companySuggestions = const <WorkCompanyVaultEntity>[];
      _brandSuggestions = const <CompanyBrandSearchResultEntity>[];
      _isSearchingBrandSuggestions = false;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    await _applyDetectedLogo(suggestion);
  }

  Widget _companyNameInput(BuildContext context) {
    final showPanel =
        _showCompanySuggestions &&
        (_companySuggestions.isNotEmpty ||
            _brandSuggestions.isNotEmpty ||
            _isSearchingBrandSuggestions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Name'.toUpperCase(),
          style: TextStyle(
            fontFamily: workFontMono,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: context.appPalette.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: _companyNameController,
          validator: _required,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            fontFamily: workFontBody,
            fontSize: 16.5,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textPrimary,
          ),
          decoration: _decor(
            hint: 'e.g. Acme Corporation',
            prefix: Icon(
              Icons.business_rounded,
              color: context.appPalette.textMuted,
              size: 21,
            ),
            suffix:
                (_isLoadingExistingCompanies || _isSearchingBrandSuggestions)
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (_companyNameController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _isApplyingCompanySelection = true;
                            _companyNameController.clear();
                            _isApplyingCompanySelection = false;
                            _brandSearchDebounce?.cancel();
                            _brandSearchToken++;
                            setState(() {
                              _showCompanySuggestions = false;
                              _companySuggestions =
                                  const <WorkCompanyVaultEntity>[];
                              _brandSuggestions =
                                  const <CompanyBrandSearchResultEntity>[];
                              _isSearchingBrandSuggestions = false;
                            });
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: context.appPalette.textMuted,
                            size: 20,
                          ),
                        )),
          ),
          onTap: () {
            if (_showAddressSuggestions || _showCompanySuggestions) {
              setState(() {
                _showAddressSuggestions = false;
              });
            }
            if ((_companySuggestions.isNotEmpty ||
                    _brandSuggestions.isNotEmpty ||
                    _isSearchingBrandSuggestions) &&
                !_showCompanySuggestions) {
              setState(() {
                _showCompanySuggestions = true;
              });
            }
          },
        ),
        if (showPanel) ...[
          const SizedBox(height: 8),
          _companySuggestionsPanel(context),
        ],
      ],
    );
  }

  Widget _companySuggestionsPanel(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount:
            _companySuggestions.length +
            _brandSuggestions.length +
            (_isSearchingBrandSuggestions ? 1 : 0),
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: context.appPalette.stroke),
        itemBuilder: (context, index) {
          if (index < _companySuggestions.length) {
            final company = _companySuggestions[index];
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
              minLeadingWidth: 0,
              leading: _companySuggestionLeading(company),
              title: Text(
                company.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: workFontDisplay,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.appPalette.textPrimary,
                ),
              ),
              subtitle: Text(
                _companySuggestionSubtitle(company),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: workFontMono,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: context.appPalette.textSecondary,
                ),
              ),
              onTap: () => _selectCompanySuggestion(company),
            );
          }

          final localIndex = index - _companySuggestions.length;
          if (_isSearchingBrandSuggestions && localIndex == 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final brandIndex =
              localIndex - (_isSearchingBrandSuggestions ? 1 : 0);
          final suggestion = _brandSuggestions[brandIndex];
          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            minLeadingWidth: 0,
            leading: _brandSuggestionLeading(suggestion),
            title: Text(
              suggestion.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: workFontDisplay,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
            subtitle: Text(
              suggestion.domain,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: workFontMono,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                color: context.appPalette.textSecondary,
              ),
            ),
            onTap: () => unawaited(_selectBrandSuggestion(suggestion)),
          );
        },
      ),
    );
  }

  Widget _companySuggestionLeading(WorkCompanyVaultEntity company) {
    final logoPath = (company.companyLogoPath ?? '').trim();
    if (logoPath.isNotEmpty && File(logoPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(logoPath),
          width: 22,
          height: 22,
          fit: BoxFit.cover,
          cacheWidth: 66,
          cacheHeight: 66,
          errorBuilder: (_, _, _) => Icon(
            Icons.apartment_rounded,
            color: context.appPalette.textMuted,
            size: 18,
          ),
        ),
      );
    }
    return Icon(
      Icons.apartment_rounded,
      color: context.appPalette.textMuted,
      size: 18,
    );
  }

  Widget _brandSuggestionLeading(CompanyBrandSearchResultEntity suggestion) {
    final iconUrl = suggestion.iconUrl.trim();
    if (iconUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          iconUrl,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Icon(
            Icons.business_rounded,
            color: context.appPalette.textMuted,
            size: 18,
          ),
        ),
      );
    }
    return Icon(
      Icons.business_rounded,
      color: context.appPalette.textMuted,
      size: 18,
    );
  }

  String _companySuggestionSubtitle(WorkCompanyVaultEntity company) {
    final parts = <String>[];
    if (company.roleLabel.trim().isNotEmpty) {
      parts.add(company.roleLabel.trim());
    }
    if (company.addressLabel.trim().isNotEmpty) {
      parts.add(company.addressLabel.trim());
    }
    if (parts.isEmpty) {
      return '${company.documentsCount} records';
    }
    return parts.join(' • ');
  }

  Widget _officeAddressInput(BuildContext context) {
    final showPanel =
        _showAddressSuggestions &&
        (_isAddressSearching || _addressSuggestions.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Office Address'.toUpperCase(),
          style: TextStyle(
            fontFamily: workFontMono,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: context.appPalette.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: _officeAddressController,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            fontFamily: workFontBody,
            fontSize: 16.5,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textPrimary,
          ),
          decoration: _decor(
            hint: context.l10n.workCompanyHintLocation,
            prefix: Icon(
              Icons.location_on_outlined,
              color: context.appPalette.textMuted,
              size: 21,
            ),
            suffix: _isAddressSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : (_officeAddressController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _addressDebounce?.cancel();
                            _isApplyingAddressSelection = true;
                            _officeAddressController.clear();
                            _isApplyingAddressSelection = false;
                            setState(() {
                              _selectedOfficeAddress = null;
                              _addressSuggestions = const <AddressSuggestion>[];
                              _showAddressSuggestions = false;
                              _isAddressSearching = false;
                            });
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: context.appPalette.textMuted,
                            size: 20,
                          ),
                        )),
          ),
          onTap: () {
            if (_showCompanySuggestions) {
              setState(() {
                _showCompanySuggestions = false;
              });
            }
            if (_addressSuggestions.isNotEmpty && !_showAddressSuggestions) {
              setState(() {
                _showAddressSuggestions = true;
              });
            }
          },
        ),
        if (showPanel) ...[
          const SizedBox(height: 8),
          _addressSuggestionsPanel(context),
        ],
      ],
    );
  }

  Widget _addressSuggestionsPanel(BuildContext context) {
    if (_isAddressSearching) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Searching addresses...',
                style: TextStyle(
                  fontFamily: workFontBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.appPalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _addressSuggestions.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: context.appPalette.stroke),
        itemBuilder: (context, index) {
          final suggestion = _addressSuggestions[index];
          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            minLeadingWidth: 0,
            leading: Icon(
              Icons.place_outlined,
              color: context.appPalette.textMuted,
              size: 18,
            ),
            title: Text(
              suggestion.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: workFontBody,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textPrimary,
              ),
            ),
            onTap: () => _selectAddressSuggestion(suggestion),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String value) {
    return Text(
      value,
      style: TextStyle(
        fontFamily: workFontMono,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: context.appPalette.textSecondary,
      ),
    );
  }

  Widget _logoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 140,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: (_isSaving || _isPickingLogo || _isDetectingLogo)
                        ? null
                        : _pickLogo,
                    child: Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        color: context.appPalette.surfaceSoft,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: context.appPalette.stroke,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _logoPreview(),
                    ),
                  ),
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: (_isSaving || _isPickingLogo || _isDetectingLogo)
                            ? null
                            : _pickLogo,
                        borderRadius: BorderRadius.circular(22),
                        child: Ink(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.appPalette.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_isDetectingLogo || _isSaving || _isPickingLogo)
                  ? null
                  : _autoDetectLogo,
              icon: _isDetectingLogo
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.appPalette.primary,
                      ),
                    )
                  : Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(context.l10n.workCompanyAutoDetectLogo),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE9EEFF),
                foregroundColor: context.appPalette.primary,
                elevation: 0,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            context.l10n.workCompanyUploadManually,
            style: TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoPreview() {
    final localPath = _logoLocalPath.trim();
    if (localPath.isNotEmpty && File(localPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(localPath),
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          cacheWidth: 264,
          cacheHeight: 264,
        ),
      );
    }
    if (_logoRemoteUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _logoRemoteUrl,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) {
            return Icon(
              Icons.business_rounded,
              size: 38,
              color: context.appPalette.textMuted,
            );
          },
        ),
      );
    }
    return Icon(
      Icons.business_rounded,
      size: 38,
      color: context.appPalette.textMuted,
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: workFontMono,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: context.appPalette.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          textInputAction: textInputAction,
          style: TextStyle(
            fontFamily: workFontBody,
            fontSize: 16.5,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textPrimary,
          ),
          decoration: _decor(
            hint: hint,
            prefix: Icon(icon, color: context.appPalette.textMuted, size: 21),
          ),
        ),
      ],
    );
  }

  Widget _dateInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: workFontMono,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: context.appPalette.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: TextStyle(
            fontFamily: workFontMono,
            fontSize: 16.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
            color: context.appPalette.textPrimary,
          ),
          decoration: _decor(
            hint: hint,
            prefix: Icon(
              Icons.calendar_month_rounded,
              color: context.appPalette.textMuted,
              size: 21,
            ),
            suffix: Icon(
              Icons.calendar_today_outlined,
              color: context.appPalette.textPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _residencyToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Residency'.toUpperCase(),
          style: TextStyle(
            fontFamily: workFontMono,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: context.appPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF2F8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3E8F2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _residencySegment(
                  label: context.l10n.workCompanyStatusOngoing,
                  active: _isOngoing,
                  onTap: () {
                    setState(() {
                      _isOngoing = true;
                      _endDate = null;
                      _endDateController.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _residencySegment(
                  label: context.l10n.workCompanyStatusFixed,
                  active: !_isOngoing,
                  onTap: () {
                    setState(() {
                      _isOngoing = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _residencySegment({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active
                    ? context.appPalette.primary
                    : context.appPalette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mapPreviewCard(BuildContext context) {
    final selectedAddress = _selectedOfficeAddress;
    final hasAddress = _officeAddressController.text.trim().isNotEmpty;
    final mapUrl = selectedAddress == null
        ? ''
        : _addressLookupService.staticMapUrl(
            latitude: selectedAddress.latitude,
            longitude: selectedAddress.longitude,
          );
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: context.appPalette.surfaceSoft,
        border: Border.all(color: context.appPalette.stroke),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: selectedAddress == null
                  ? ColoredBox(
                      color: context.appPalette.surfaceSoft,
                      child: Icon(
                        Icons.map_outlined,
                        size: 96,
                        color: context.appPalette.surfaceSoft,
                      ),
                    )
                  : Image.network(
                      mapUrl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) {
                        return ColoredBox(
                          color: context.appPalette.surfaceSoft,
                          child: Icon(
                            Icons.map_outlined,
                            size: 96,
                            color: context.appPalette.surfaceSoft,
                          ),
                        );
                      },
                    ),
            ),
            if (selectedAddress != null)
              Positioned(
                top: 8,
                left: 10,
                right: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      selectedAddress.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            FilledButton(
              onPressed: _isAddressSearching
                  ? null
                  : () => _resolveAddressForMapPreview(showFeedback: true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(126, 40),
                backgroundColor: context.appPalette.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              child: Text(
                hasAddress && selectedAddress != null
                    ? 'UPDATE MAP'
                    : context.l10n.workCompanyPreviewMap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onOfficeAddressChanged() {
    if (_isApplyingAddressSelection) {
      return;
    }
    final query = _officeAddressController.text.trim();
    _addressDebounce?.cancel();

    var changed = false;
    if (_selectedOfficeAddress != null &&
        _selectedOfficeAddress!.displayName.trim().toLowerCase() !=
            query.toLowerCase()) {
      _selectedOfficeAddress = null;
      changed = true;
    }

    if (query.length < 3) {
      if (_isAddressSearching ||
          _showAddressSuggestions ||
          _addressSuggestions.isNotEmpty) {
        _isAddressSearching = false;
        _showAddressSuggestions = false;
        _addressSuggestions = const <AddressSuggestion>[];
        changed = true;
      }
      if (changed && mounted) {
        setState(() {});
      }
      return;
    }

    if (!_showAddressSuggestions) {
      _showAddressSuggestions = true;
      changed = true;
    }
    if (changed && mounted) {
      setState(() {});
    }

    _addressDebounce = Timer(
      const Duration(milliseconds: 340),
      () => _searchOfficeAddressSuggestions(query),
    );
  }

  Future<void> _searchOfficeAddressSuggestions(String query) async {
    final token = ++_addressSearchToken;
    if (mounted) {
      setState(() {
        _isAddressSearching = true;
      });
    }
    try {
      final suggestions = await _addressLookupService.search(query: query);
      if (!mounted || token != _addressSearchToken) {
        return;
      }
      final latestQuery = _officeAddressController.text.trim().toLowerCase();
      if (latestQuery != query.trim().toLowerCase()) {
        return;
      }
      setState(() {
        _isAddressSearching = false;
        _addressSuggestions = suggestions;
        _showAddressSuggestions = suggestions.isNotEmpty;
      });
    } catch (_) {
      if (!mounted || token != _addressSearchToken) {
        return;
      }
      setState(() {
        _isAddressSearching = false;
        _addressSuggestions = const <AddressSuggestion>[];
      });
    }
  }

  void _selectAddressSuggestion(AddressSuggestion suggestion) {
    _addressDebounce?.cancel();
    _isApplyingAddressSelection = true;
    _officeAddressController.value = TextEditingValue(
      text: suggestion.displayName,
      selection: TextSelection.collapsed(offset: suggestion.displayName.length),
    );
    _isApplyingAddressSelection = false;
    setState(() {
      _selectedOfficeAddress = suggestion;
      _isAddressSearching = false;
      _showAddressSuggestions = false;
      _addressSuggestions = const <AddressSuggestion>[];
    });
  }

  Future<void> _resolveAddressForMapPreview({bool showFeedback = false}) async {
    final query = _officeAddressController.text.trim();
    if (query.isEmpty) {
      _toast('Add office address to preview map.');
      return;
    }
    final selected = _selectedOfficeAddress;
    if (selected != null &&
        selected.displayName.trim().toLowerCase() == query.toLowerCase()) {
      if (showFeedback) {
        _toast('Map preview updated.');
      }
      return;
    }
    _addressDebounce?.cancel();
    final token = ++_addressSearchToken;
    if (mounted) {
      setState(() {
        _isAddressSearching = true;
      });
    }
    try {
      final resolved = await _addressLookupService.resolveSingle(query: query);
      if (!mounted || token != _addressSearchToken) {
        return;
      }
      if (resolved == null) {
        setState(() {
          _isAddressSearching = false;
          _addressSuggestions = const <AddressSuggestion>[];
          _showAddressSuggestions = false;
        });
        _toast('Unable to resolve this address. Please refine it.');
        return;
      }
      _isApplyingAddressSelection = true;
      _officeAddressController.value = TextEditingValue(
        text: resolved.displayName,
        selection: TextSelection.collapsed(offset: resolved.displayName.length),
      );
      _isApplyingAddressSelection = false;
      setState(() {
        _isAddressSearching = false;
        _selectedOfficeAddress = resolved;
        _showAddressSuggestions = false;
        _addressSuggestions = const <AddressSuggestion>[];
      });
      if (showFeedback) {
        _toast('Map preview updated.');
      }
    } catch (_) {
      if (!mounted || token != _addressSearchToken) {
        return;
      }
      setState(() {
        _isAddressSearching = false;
      });
      _toast('Unable to load map preview right now.');
    }
  }

  InputDecoration _decor({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: workFontBody,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textMuted,
      ),
      prefixIcon: prefix == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: prefix,
            ),
      suffixIcon: suffix == null
          ? null
          : Padding(padding: const EdgeInsets.only(right: 10), child: suffix),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
      suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 24),
      filled: true,
      fillColor: context.appPalette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: context.appPalette.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: context.appPalette.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: context.appPalette.primary, width: 1.4),
      ),
    );
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final initial = current ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 20),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      onPicked(selected);
    });
  }

  Future<void> _autoDetectLogo() async {
    if (_isDetectingLogo || _isSaving || _isPickingLogo) {
      return;
    }
    final query = _companyNameController.text.trim();
    if (query.length < 2) {
      _toast('Enter company name first.');
      return;
    }

    setState(() {
      _isDetectingLogo = true;
    });

    try {
      final results = await _searchLogoUseCase(query: query);
      if (!mounted) {
        return;
      }
      if (results.isEmpty) {
        _toast('No matching logo found.');
        return;
      }
      await _applyDetectedLogo(results.first);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _toast(context.l10n.credentialsUnableSearchBrands);
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLogo = false;
        });
      }
    }
  }

  Future<void> _applyDetectedLogo(
    CompanyBrandSearchResultEntity suggestion,
  ) async {
    final localPath = await _downloadLogoUseCase(
      iconUrl: suggestion.iconUrl,
      domain: suggestion.domain,
    );
    if (!mounted) {
      return;
    }
    if ((localPath ?? '').trim().isEmpty) {
      _toast(context.l10n.credentialsUnableSaveLogoLocally);
      return;
    }
    setState(() {
      _logoLocalPath = localPath!.trim();
      _logoRemoteUrl = suggestion.iconUrl;
    });
    _toast('Company logo updated.');
  }

  Future<void> _pickLogo() async {
    if (_isPickingLogo || _isSaving || _isDetectingLogo) {
      return;
    }
    setState(() {
      _isPickingLogo = true;
    });

    try {
      final source = await showAdaptiveModal<_LogoSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: Text(context.l10n.commonTakePhoto),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_LogoSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: Text(context.l10n.commonChooseFromGallery),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_LogoSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open_rounded),
                  title: Text(context.l10n.commonBrowseFiles),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_LogoSource.files),
                ),
              ],
            ),
          );
        },
      );
      if (!mounted || source == null) {
        return;
      }
      final selectedPath = await _pickImageFromSource(source);

      final normalized = selectedPath?.trim() ?? '';
      if (normalized.isEmpty || !mounted) {
        return;
      }

      final persisted = await _persistLogoFile(sourcePath: normalized);
      if (!mounted) {
        return;
      }
      if ((persisted ?? '').trim().isEmpty) {
        _toast('Unable to save logo right now.');
        return;
      }
      setState(() {
        _logoLocalPath = persisted!.trim();
        _logoRemoteUrl = '';
      });
      _toast('Logo selected.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _toast('Unable to select logo right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isPickingLogo = false;
        });
      }
    }
  }

  Future<String?> _pickImageFromFiles() async {
    final result = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'logo',
          extensions: <String>['png', 'jpg', 'jpeg'],
          uniformTypeIdentifiers: ['public.png', 'public.jpeg'],
        ),
      ],
    );
    if (result == null) {
      return null;
    }
    return result.path;
  }

  Future<String?> _pickImageFromSource(_LogoSource source) async {
    if (source == _LogoSource.files) {
      return _pickImageFromFiles();
    }
    final image = await _imagePicker.pickImage(
      source: source == _LogoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1800,
    );
    return image?.path;
  }

  Future<String?> _persistLogoFile({required String sourcePath}) async {
    final path = sourcePath.trim();
    if (path.isEmpty) {
      return null;
    }
    try {
      final sourceFile = File(path);
      if (!await sourceFile.exists()) {
        return null;
      }
      final bytesLength = await sourceFile.length();
      const maxBytes = 5 * 1024 * 1024;
      if (bytesLength > maxBytes) {
        _toast('Logo file must be up to 5MB.');
        return null;
      }
      final slug = _slugify(_companyNameController.text.trim());
      return LocalAssetFileStore.copyIntoAppSupport(
        sourcePath: path,
        directoryName: 'work_company_logos',
        fileNamePrefix: '${slug}_logo',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    if (_isSaving || _isPickingLogo || _isDetectingLogo) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_entryDate == null) {
      _toast('Please select entry date.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final companyName = _companyNameController.text.trim();
      final initialCompanyId = widget.initialDetail?.companyId.trim() ?? '';
      final companyId = initialCompanyId.isEmpty
          ? _slugify(companyName)
          : initialCompanyId;
      final role = _roleController.text.trim();
      final officeAddress = _officeAddressController.text.trim();
      final contact = _contactController.text.trim();
      final officeLocation = _selectedOfficeAddress == null
          ? ''
          : encodeAddressSuggestion(_selectedOfficeAddress!);
      final startDateIso = DateFormat('yyyy-MM-dd').format(_entryDate!);
      final endDateIso = _endDate == null
          ? ''
          : DateFormat('yyyy-MM-dd').format(_endDate!);
      final logoPath = _logoLocalPath.trim();

      final fields =
          <Map<String, String>>[
                {
                  'label': DocumentMetadataFieldLabels.workCompanyId,
                  'value': companyId,
                },
                {
                  'label': DocumentMetadataFieldLabels.workCompanyName,
                  'value': companyName,
                },
                {
                  'label': DocumentMetadataFieldLabels.workRecordType,
                  'value': 'company_profile',
                },
                {'label': DocumentMetadataFieldLabels.workRole, 'value': role},
                {
                  'label': DocumentMetadataFieldLabels.workStartDate,
                  'value': startDateIso,
                },
                {
                  'label': DocumentMetadataFieldLabels.workEndDate,
                  'value': _isOngoing ? '' : endDateIso,
                },
                {
                  'label': DocumentMetadataFieldLabels.workContact,
                  'value': contact,
                },
                {
                  'label': DocumentMetadataFieldLabels.workAddress,
                  'value': officeAddress,
                },
                {
                  'label': DocumentMetadataFieldLabels.workLocation,
                  'value': officeLocation,
                },
                {
                  'label': DocumentMetadataFieldLabels.workPinned,
                  'value': 'false',
                },
                {
                  'label': DocumentMetadataFieldLabels.workCompanyLogoPath,
                  'value': logoPath,
                },
                {'label': 'Company Name', 'value': companyName},
                {'label': 'Role', 'value': role},
                {'label': 'Entry Date', 'value': startDateIso},
                {'label': 'Office Address', 'value': officeAddress},
                {'label': 'Primary Contact', 'value': contact},
                {
                  'label': 'Residency',
                  'value': _isOngoing ? 'ongoing' : 'fixed',
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
                  'label': DocumentMetadataFieldLabels.claimWorkRecordType,
                  'value': 'company_profile',
                },
                {
                  'label': DocumentMetadataFieldLabels.claimWorkRole,
                  'value': role,
                },
                {
                  'label': DocumentMetadataFieldLabels.claimWorkStartDate,
                  'value': startDateIso,
                },
                {
                  'label': DocumentMetadataFieldLabels.claimWorkEndDate,
                  'value': _isOngoing ? '' : endDateIso,
                },
                {
                  'label': DocumentMetadataFieldLabels.claimWorkContact,
                  'value': contact,
                },
                {
                  'label': DocumentMetadataFieldLabels.claimWorkAddress,
                  'value': officeAddress,
                },
                {
                  'label': DocumentMetadataFieldLabels.claimWorkLocation,
                  'value': officeLocation,
                },
                {
                  'label': DocumentMetadataFieldLabels.claimWorkPinned,
                  'value': 'false',
                },
                {
                  'label': DocumentMetadataFieldLabels.claimWorkCompanyLogoPath,
                  'value': logoPath,
                },
              ]
              .where((field) => (field['value'] ?? '').trim().isNotEmpty)
              .toList(growable: false);

      final editDocumentId = widget.editDocumentId?.trim() ?? '';
      if (editDocumentId.isNotEmpty) {
        final updated = await _updateUseCase(
          UpdateDocumentParams(
            documentId: editDocumentId,
            type: DocumentType.other,
            source: DocumentCaptureSource.gallery,
            scanPagesCount: 1,
            categoryOverride: DocumentCategoryType.work,
            documentTypeKeyOverride: 'other',
            issuerOverride: companyName,
            identifierLabelOverride: 'Company',
            identifierValueOverride: companyName,
            structuredFieldsOverride: fields,
            tagsOverride: const <String>['Work', 'Company'],
          ),
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(updated.id);
        return;
      }

      final created = await _createUseCase(
        CreateScannedDocumentParams(
          type: DocumentType.other,
          source: DocumentCaptureSource.gallery,
          scanPagesCount: 1,
          categoryOverride: DocumentCategoryType.work,
          documentTypeKeyOverride: 'other',
          issuerOverride: companyName,
          identifierLabelOverride: 'Company',
          identifierValueOverride: companyName,
          structuredFieldsOverride: fields,
          tagsOverride: const <String>['Work', 'Company'],
        ),
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(created.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _toast(context.l10n.idEntryUnableSaveDocument);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return context.l10n.idEntryRequired;
    }
    return null;
  }

  String _slugify(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'company' : normalized;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _applyInitialDetail(WorkCompanyDetailEntity? detail) {
    if (detail == null) {
      return;
    }
    _companyNameController.text = detail.companyName.trim();
    _roleController.text = detail.roleLabel.trim();
    _contactController.text = detail.contactLabel.trim();
    _officeAddressController.text = detail.addressLabel.trim();
    _logoLocalPath = (detail.companyLogoPath ?? '').trim();

    final startedAt = detail.startedAt;
    _entryDate = startedAt;
    _entryDateController.text = startedAt == null
        ? ''
        : DateFormat('MM/dd/yy').format(startedAt);

    final finishedAt = detail.finishedAt;
    _isOngoing = finishedAt == null;
    _endDate = finishedAt;
    _endDateController.text = finishedAt == null
        ? ''
        : DateFormat('MM/dd/yy').format(finishedAt);
  }
}

enum _LogoSource { camera, gallery, files }
