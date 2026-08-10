import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/services/address_lookup_service.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class PropertyEntryPage extends StatefulWidget {
  const PropertyEntryPage({
    super.key,
    this.propertyToEdit,
    CreateScannedDocument? createScannedDocument,
    UpdateDocument? updateDocument,
  }) : _createScannedDocument = createScannedDocument,
       _updateDocument = updateDocument;

  final PropertyVaultEntity? propertyToEdit;
  final CreateScannedDocument? _createScannedDocument;
  final UpdateDocument? _updateDocument;

  @override
  State<PropertyEntryPage> createState() => _PropertyEntryPageState();
}

class _PropertyEntryPageState extends State<PropertyEntryPage> {
  static const List<String> _propertyTypes = <String>[
    'Apartment',
    'Single Family House',
    'Condo',
    'Townhouse',
    'Multi-Family',
    'Penthouse',
    'Vacation Home',
    'Land',
    'Commercial',
  ];

  final _formKey = GlobalKey<FormState>();
  final _propertyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressLookupService = AddressLookupService();

  Timer? _addressDebounce;
  int _addressSearchToken = 0;
  bool _isAddressSearching = false;
  bool _showAddressSuggestions = false;
  bool _isApplyingAddressSelection = false;
  bool _isDetectingAddress = false;
  bool _isSaving = false;

  AddressSuggestion? _selectedAddressSuggestion;
  List<AddressSuggestion> _addressSuggestions = const <AddressSuggestion>[];
  String _selectedPropertyType = _propertyTypes.first;
  _PropertyOwnership _ownership = _PropertyOwnership.owned;

  CreateScannedDocument get _createUseCase =>
      widget._createScannedDocument ?? getIt();
  UpdateDocument get _updateUseCase => widget._updateDocument ?? getIt();

  bool get _isEditMode => widget.propertyToEdit != null;

  @override
  void initState() {
    super.initState();
    _propertyNameController.text = widget.propertyToEdit?.propertyName ?? '';
    _addressController.text = widget.propertyToEdit?.fullAddress ?? '';
    _selectedAddressSuggestion = decodeAddressSuggestion(
      widget.propertyToEdit?.addressSuggestionJson ?? '',
    );
    final initialType = widget.propertyToEdit?.propertyTypeLabel.trim() ?? '';
    if (initialType.isNotEmpty) {
      final match = _propertyTypes.firstWhere(
        (item) => item.toLowerCase() == initialType.toLowerCase(),
        orElse: () => _propertyTypes.first,
      );
      _selectedPropertyType = match;
    }
    _ownership = _ownershipFromLabel(
      widget.propertyToEdit?.ownershipStatusLabel ?? '',
    );
    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _propertyNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_showAddressSuggestions) {
          setState(() {
            _showAddressSuggestions = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: context.appPalette.backgroundAlt,
        appBar: GenericAppBar(
          backgroundColor: context.appPalette.backgroundAlt,
          centerTitle: false,
          titleSpacing: 0,
          onBackPressed: () => Navigator.of(context).maybePop(),
          title: _isEditMode
              ? l10n.propertyEntryEditTitle
              : l10n.propertyEntryAddTitle,
          titleStyle: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: context.appPalette.textPrimary,
          ),
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                    children: [
                      _PropertyPreviewCard(
                        palette: context.appPalette,
                        previewLabel: context.l10n.documentPreview,
                        propertyName: _propertyNameController.text.trim(),
                        propertyTypeLabel: _propertyTypeLabel(
                          context,
                          _selectedPropertyType,
                        ),
                        ownershipLabel: _ownership == _PropertyOwnership.owned
                            ? context.l10n.propertyEntryOwnedLabel
                            : context.l10n.propertyEntryRentedLabel,
                        address: _addressController.text.trim(),
                        icon: _propertyIconForType(_selectedPropertyType),
                        accent: _ownership == _PropertyOwnership.owned
                            ? context.appPalette.primary
                            : const Color(0xFF1B9A62),
                        mapUrl: _selectedAddressSuggestion == null
                            ? null
                            : _addressLookupService.staticMapUrl(
                                latitude: _selectedAddressSuggestion!.latitude,
                                longitude:
                                    _selectedAddressSuggestion!.longitude,
                              ),
                        isEditMode: _isEditMode,
                      ),
                      const SizedBox(height: 14),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _PropertySectionCard(
                              palette: context.appPalette,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _PropertySectionHeader(
                                    palette: context.appPalette,
                                    title: l10n.propertyEntryCardTitle,
                                    subtitle: l10n.propertyEntryCardSubtitle,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.propertyEntryNameLabel,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.appPalette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _propertyNameController,
                                    onChanged: (_) => setState(() {}),
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return l10n.propertyEntryNameRequired;
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w500,
                                      color: context.appPalette.textPrimary,
                                    ),
                                    decoration: _inputDecoration(
                                      hint: l10n.propertyEntryNameHint,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.propertyEntryAddressLabel,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.appPalette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _addressController,
                                    onChanged: (_) => setState(() {}),
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return l10n
                                            .propertyEntryAddressRequired;
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.done,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w500,
                                      color: context.appPalette.textPrimary,
                                    ),
                                    decoration: _inputDecoration(
                                      hint: l10n.propertyEntryAddressHint,
                                      suffixIcon: _isAddressSearching
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              Icons.location_on_rounded,
                                              size: 20,
                                              color:
                                                  context.appPalette.textMuted,
                                            ),
                                    ),
                                  ),
                                  if (_showAddressSuggestions &&
                                      (_isAddressSearching ||
                                          _addressSuggestions.isNotEmpty)) ...[
                                    const SizedBox(height: 8),
                                    _addressSuggestionPanel(context),
                                  ],
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed:
                                          _isDetectingAddress || _isSaving
                                          ? null
                                          : _autoDetectAddress,
                                      icon: _isDetectingAddress
                                          ? SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color:
                                                    context.appPalette.primary,
                                              ),
                                            )
                                          : Icon(
                                              Icons.near_me_rounded,
                                              size: 16,
                                            ),
                                      label: Text(l10n.propertyEntryAutoDetect),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            context.appPalette.primary,
                                        textStyle: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _PropertySectionCard(
                              palette: context.appPalette,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _PropertySectionHeader(
                                    palette: context.appPalette,
                                    title:
                                        l10n.propertyEntryCategorizationTitle,
                                    subtitle: _isEditMode
                                        ? l10n.propertyEntrySaveAction
                                        : l10n.propertyEntryCreateAction,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.propertyEntryTypeLabel,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.appPalette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedPropertyType,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: context.appPalette.textSecondary,
                                    ),
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w500,
                                      color: context.appPalette.textPrimary,
                                    ),
                                    decoration: _inputDecoration(hint: ''),
                                    borderRadius: BorderRadius.circular(14),
                                    dropdownColor: context.appPalette.surface,
                                    items: _propertyTypes
                                        .map(
                                          (value) => DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              _propertyTypeLabel(
                                                context,
                                                value,
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
                                        _selectedPropertyType = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.propertyEntryOwnershipLabel,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.appPalette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _ownershipSegmentedControl(context),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),
                      FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: context.appPalette.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: context.appPalette.primary
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditMode
                                    ? l10n.propertyEntrySaveAction
                                    : l10n.propertyEntryCreateAction,
                              ),
                      ),
                    ],
                  ),
                  if (_isSaving)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ownershipSegmentedControl(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ownershipSegment(
              label: l10n.propertyEntryOwnedLabel,
              active: _ownership == _PropertyOwnership.owned,
              onTap: () {
                setState(() {
                  _ownership = _PropertyOwnership.owned;
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ownershipSegment(
              label: l10n.propertyEntryRentedLabel,
              active: _ownership == _PropertyOwnership.rented,
              onTap: () {
                setState(() {
                  _ownership = _PropertyOwnership.rented;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownershipSegment({
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
            color: active ? context.appPalette.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: active
                    ? context.appPalette.textPrimary
                    : context.appPalette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressSuggestionPanel(BuildContext context) {
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
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.propertyEntryAddressSearching,
                style: TextStyle(
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

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textMuted,
      ),
      filled: true,
      fillColor: context.appPalette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: Color(0xFFA9BCE4), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE7A8A8), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE09090), width: 1.2),
      ),
      suffixIcon: suffixIcon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 10),
              child: suffixIcon,
            ),
      suffixIconConstraints: const BoxConstraints(minHeight: 24, minWidth: 40),
    );
  }

  void _onAddressChanged() {
    if (_isApplyingAddressSelection) {
      return;
    }
    final query = _addressController.text.trim();
    _addressDebounce?.cancel();
    if (_selectedAddressSuggestion != null &&
        _selectedAddressSuggestion!.displayName.trim().toLowerCase() !=
            query.toLowerCase()) {
      setState(() {
        _selectedAddressSuggestion = null;
      });
    }
    if (query.length < 3) {
      if (_addressSuggestions.isNotEmpty ||
          _showAddressSuggestions ||
          _isAddressSearching) {
        setState(() {
          _addressSuggestions = const <AddressSuggestion>[];
          _showAddressSuggestions = false;
          _isAddressSearching = false;
        });
      }
      _addressSearchToken++;
      return;
    }
    final token = ++_addressSearchToken;
    _addressDebounce = Timer(const Duration(milliseconds: 260), () async {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAddressSearching = true;
        _showAddressSuggestions = true;
      });
      try {
        final suggestions = await _addressLookupService.search(query: query);
        if (!mounted || token != _addressSearchToken) {
          return;
        }
        final current = _addressController.text.trim();
        if (current.toLowerCase() != query.toLowerCase()) {
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
          _showAddressSuggestions = false;
        });
      }
    });
  }

  void _selectAddressSuggestion(AddressSuggestion suggestion) {
    _isApplyingAddressSelection = true;
    _addressController.value = TextEditingValue(
      text: suggestion.displayName,
      selection: TextSelection.collapsed(offset: suggestion.displayName.length),
    );
    _isApplyingAddressSelection = false;
    setState(() {
      _selectedAddressSuggestion = suggestion;
      _addressSuggestions = const <AddressSuggestion>[];
      _showAddressSuggestions = false;
      _isAddressSearching = false;
    });
  }

  Future<void> _autoDetectAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      _showError(context.l10n.propertyEntryAddressRequired);
      return;
    }
    setState(() {
      _isDetectingAddress = true;
    });
    try {
      final suggestion = await _addressLookupService.resolveSingle(
        query: query,
      );
      if (!mounted) {
        return;
      }
      if (suggestion == null) {
        _showError(context.l10n.propertyEntryAddressNotFound);
        return;
      }
      _selectAddressSuggestion(suggestion);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError(context.l10n.propertyEntryAddressNotFound);
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingAddress = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });
    try {
      final propertyName = _propertyNameController.text.trim();
      final fullAddress = _addressController.text.trim();
      final propertyId =
          (widget.propertyToEdit?.propertyId ?? '').trim().isEmpty
          ? _slugify(propertyName)
          : widget.propertyToEdit!.propertyId;
      final ownershipStatus = switch (_ownership) {
        _PropertyOwnership.owned => 'owned',
        _PropertyOwnership.rented => 'rental',
      };
      final addressSuggestionJson = _selectedAddressSuggestion == null
          ? ''
          : encodeAddressSuggestion(_selectedAddressSuggestion!);

      final structuredFields =
          <Map<String, String>>[
                {
                  'label': DocumentMetadataFieldLabels.propertyId,
                  'value': propertyId,
                },
                {
                  'label': DocumentMetadataFieldLabels.propertyName,
                  'value': propertyName,
                },
                {
                  'label': DocumentMetadataFieldLabels.propertyRecordType,
                  'value': 'property_profile',
                },
                {
                  'label': DocumentMetadataFieldLabels.propertyType,
                  'value': _selectedPropertyType,
                },
                {
                  'label': DocumentMetadataFieldLabels.propertyOwnershipStatus,
                  'value': ownershipStatus,
                },
                {
                  'label': DocumentMetadataFieldLabels.propertyFullAddress,
                  'value': fullAddress,
                },
                {
                  'label':
                      DocumentMetadataFieldLabels.propertyAddressSuggestionJson,
                  'value': addressSuggestionJson,
                },
                {
                  'label': DocumentMetadataFieldLabels.claimPropertyId,
                  'value': propertyId,
                },
                {
                  'label': DocumentMetadataFieldLabels.claimPropertyName,
                  'value': propertyName,
                },
                {
                  'label': DocumentMetadataFieldLabels.claimPropertyRecordType,
                  'value': 'property_profile',
                },
                {
                  'label': DocumentMetadataFieldLabels.claimPropertyType,
                  'value': _selectedPropertyType,
                },
                {
                  'label':
                      DocumentMetadataFieldLabels.claimPropertyOwnershipStatus,
                  'value': ownershipStatus,
                },
                {
                  'label': DocumentMetadataFieldLabels.claimPropertyFullAddress,
                  'value': fullAddress,
                },
                {
                  'label': DocumentMetadataFieldLabels
                      .claimPropertyAddressSuggestionJson,
                  'value': addressSuggestionJson,
                },
              ]
              .where((item) => (item['value'] ?? '').trim().isNotEmpty)
              .toList(growable: false);

      final editDocumentId = (widget.propertyToEdit?.profileDocumentId ?? '')
          .trim();
      final resultId = editDocumentId.isEmpty
          ? (await _createUseCase(
              CreateScannedDocumentParams(
                type: DocumentType.other,
                source: DocumentCaptureSource.gallery,
                scanPagesCount: 1,
                categoryOverride: DocumentCategoryType.property,
                documentTypeKeyOverride: 'property_profile',
                issuerOverride: propertyName,
                identifierLabelOverride: 'Property',
                identifierValueOverride: propertyName,
                structuredFieldsOverride: structuredFields,
                tagsOverride: const <String>['property', 'property_profile'],
              ),
            )).id
          : (await _updateUseCase(
              UpdateDocumentParams(
                documentId: editDocumentId,
                type: DocumentType.other,
                source: DocumentCaptureSource.gallery,
                scanPagesCount: 1,
                categoryOverride: DocumentCategoryType.property,
                documentTypeKeyOverride: 'property_profile',
                issuerOverride: propertyName,
                identifierLabelOverride: 'Property',
                identifierValueOverride: propertyName,
                structuredFieldsOverride: structuredFields,
                tagsOverride: const <String>['property', 'property_profile'],
              ),
            )).id;

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(resultId);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError(context.l10n.propertyEntrySaveFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  _PropertyOwnership _ownershipFromLabel(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('rent') || value.contains('lease')) {
      return _PropertyOwnership.rented;
    }
    return _PropertyOwnership.owned;
  }

  String _slugify(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'property' : normalized;
  }
}

class _PropertyPreviewCard extends StatelessWidget {
  const _PropertyPreviewCard({
    required this.palette,
    required this.previewLabel,
    required this.propertyName,
    required this.propertyTypeLabel,
    required this.ownershipLabel,
    required this.address,
    required this.icon,
    required this.accent,
    required this.isEditMode,
    this.mapUrl,
  });

  final AppPalette palette;
  final String previewLabel;
  final String propertyName;
  final String propertyTypeLabel;
  final String ownershipLabel;
  final String address;
  final IconData icon;
  final Color accent;
  final bool isEditMode;
  final String? mapUrl;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.stroke),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        previewLabel.toUpperCase(),
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 10.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isEditMode
                            ? context.l10n.commonEdit
                            : context.l10n.propertyHubAddAction,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 24, color: accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            propertyName.trim().isEmpty
                                ? context.l10n.propertyEntryNameHint
                                : propertyName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            propertyTypeLabel,
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PreviewChip(
                      icon: Icons.verified_user_rounded,
                      label: ownershipLabel,
                      foreground: accent,
                      background: accent.withValues(alpha: 0.1),
                    ),
                    _PreviewChip(
                      icon: Icons.home_work_rounded,
                      label: propertyTypeLabel,
                      foreground: palette.textSecondary,
                      background: palette.surfaceSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasAddress
                            ? address
                            : context.l10n.propertyEntryAddressHint,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasAddress
                              ? palette.textSecondary
                              : palette.textMuted,
                          fontSize: 13.4,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if ((mapUrl ?? '').trim().isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
              child: SizedBox(
                height: 148,
                width: double.infinity,
                child: Image.network(
                  mapUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _PreviewMapFallback(palette: palette, accent: accent),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }
                    return _PreviewMapFallback(
                      palette: palette,
                      accent: accent,
                      loading: true,
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

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMapFallback extends StatelessWidget {
  const _PreviewMapFallback({
    required this.palette,
    required this.accent,
    this.loading = false,
  });

  final AppPalette palette;
  final Color accent;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: palette.surfaceSoft,
      child: Center(
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              )
            : Icon(Icons.map_outlined, size: 28, color: palette.textMuted),
      ),
    );
  }
}

class _PropertySectionCard extends StatelessWidget {
  const _PropertySectionCard({required this.palette, required this.child});

  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke),
      ),
      child: child,
    );
  }
}

class _PropertySectionHeader extends StatelessWidget {
  const _PropertySectionHeader({
    required this.palette,
    required this.title,
    required this.subtitle,
  });

  final AppPalette palette;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: palette.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

enum _PropertyOwnership { owned, rented }

IconData _propertyIconForType(String rawType) {
  final normalized = rawType.trim().toLowerCase();
  if (normalized.contains('office') || normalized.contains('commercial')) {
    return Icons.apartment_rounded;
  }
  if (normalized.contains('house') ||
      normalized.contains('townhouse') ||
      normalized.contains('vacation')) {
    return Icons.house_rounded;
  }
  if (normalized.contains('condo') || normalized.contains('apartment')) {
    return Icons.location_city_rounded;
  }
  if (normalized.contains('land')) {
    return Icons.terrain_rounded;
  }
  return Icons.domain_rounded;
}

String _propertyTypeLabel(BuildContext context, String value) {
  return switch (value) {
    'Apartment' => context.l10n.propertyTypeApartment,
    'Single Family House' => context.l10n.propertyTypeSingleFamily,
    'Condo' => context.l10n.propertyTypeCondo,
    'Townhouse' => context.l10n.propertyTypeTownhouse,
    'Multi-Family' => context.l10n.propertyTypeMultiFamily,
    'Penthouse' => context.l10n.propertyTypePenthouse,
    'Vacation Home' => context.l10n.propertyTypeVacationHome,
    'Land' => context.l10n.propertyTypeLand,
    'Commercial' => context.l10n.propertyTypeCommercial,
    _ => value,
  };
}
