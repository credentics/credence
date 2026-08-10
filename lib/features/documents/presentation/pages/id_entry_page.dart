import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/domain/documents/entities/country_catalog.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_holder_relation.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/services/document_ocr_parser.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class IdEntryPage extends StatefulWidget {
  const IdEntryPage({
    super.key,
    required this.type,
    this.autoStartScan = false,
    this.documentToEdit,
    CreateScannedDocument? createScannedDocument,
    UpdateDocument? updateDocument,
  }) : _createScannedDocument = createScannedDocument,
       _updateDocument = updateDocument;

  final DocumentType type;
  final bool autoStartScan;
  final DocumentDetailEntity? documentToEdit;
  final CreateScannedDocument? _createScannedDocument;
  final UpdateDocument? _updateDocument;

  @override
  State<IdEntryPage> createState() => _IdEntryPageState();
}

class _IdEntryPageState extends State<IdEntryPage> {
  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
  };
  static const Set<String> _referenceExtensions = {..._imageExtensions, 'pdf'};

  final _ocrParser = const DocumentOcrParser();
  final _formKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _authorityController = TextEditingController();
  final _issuerController = TextEditingController();
  final _notesController = TextEditingController();
  String _detectedSex = '';
  IdentityDocumentHolderRelation _holderRelation =
      IdentityDocumentHolderRelation.owner;
  _IdentityDocumentSubtype _identitySubtype = _IdentityDocumentSubtype.idCard;
  bool _identitySubtypeManuallySet = false;
  final List<_ReferenceAttachment> _referenceAttachments =
      <_ReferenceAttachment>[];
  bool _useUploadedImageAsPreview = true;
  bool _hasShownPreviewNotice = false;
  String? _previewImagePath;

  bool _isSaving = false;
  bool _isScanning = false;
  DocumentCaptureSource _captureSource = DocumentCaptureSource.gallery;
  int _existingScanPagesCount = 1;

  final Map<_CaptureSide, String> _capturedPaths = <_CaptureSide, String>{};
  final Map<_CaptureSide, int> _capturedPages = <_CaptureSide, int>{};

  CreateScannedDocument get _createUseCase =>
      widget._createScannedDocument ?? getIt();
  UpdateDocument get _updateUseCase => widget._updateDocument ?? getIt();

  bool get _requiresTwoSides {
    return widget.type == DocumentType.idCard ||
        widget.type == DocumentType.driversLicense;
  }

  bool get _mobileCaptureSupported {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  bool get _ocrSupported => _mobileCaptureSupported;

  @override
  void initState() {
    super.initState();
    final detail = widget.documentToEdit;
    if (detail == null) {
      _bootstrapDefaults();
    } else {
      _bootstrapFromDocument(detail);
    }
    if (widget.autoStartScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _captureAndAutofill(
            _CaptureSide.front,
            inputMethod: _CaptureInputMethod.camera,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _fullNameController.dispose();
    _countryController.dispose();
    _birthDateController.dispose();
    _expiryDateController.dispose();
    _authorityController.dispose();
    _issuerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final captureHint = l10n.idEntryTapCaptureOrUpload;
    final canSubmit = !_isSaving && !_isScanning;
    return Scaffold(
      backgroundColor: context.appPalette.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    _entryTopBar(canSubmit: canSubmit),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          children: [
                            _identityEntryHero(),
                            const SizedBox(height: 14),
                            _entrySection(
                              title: l10n.idEntryAttachmentSection,
                              children: [
                                _captureSlot(side: _CaptureSide.front),
                                const SizedBox(height: 8),
                                _slotCaption(
                                  title: l10n.idEntryUploadFrontSide,
                                  subtitle: captureHint,
                                ),
                                if (_requiresTwoSides) ...[
                                  const SizedBox(height: 14),
                                  _captureSlot(side: _CaptureSide.back),
                                  const SizedBox(height: 8),
                                  _slotCaption(
                                    title: l10n.idEntryUploadBackSide,
                                    subtitle: captureHint,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 14),
                            _entrySection(
                              title: _informationTitle,
                              children: _formFields(),
                            ),
                            const SizedBox(height: 14),
                            _previewPreferenceCard(),
                            const SizedBox(height: 12),
                            _referenceAttachmentCard(),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: canSubmit ? _save : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: context.appPalette.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                _primaryActionLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
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
            ),
            if (_isSaving || _isScanning)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.15),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _entryTopBar({required bool canSubmit}) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Row(
        children: [
          TextButton(
            onPressed: _isSaving || _isScanning
                ? null
                : () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(
              foregroundColor: palette.textSecondary,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(context.l10n.commonCancel),
          ),
          Expanded(
            child: Text(
              _uploadHeaderTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: palette.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: canSubmit ? _save : null,
            style: TextButton.styleFrom(
              foregroundColor: palette.primary,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Widget _identityEntryHero() {
    final palette = context.appPalette;
    final scheme = _entrySchemeForType(widget.type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _entryTint(context, scheme.background, scheme.accent),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _entryTint(
            context,
            scheme.border,
            scheme.accent,
            darkAlpha: 0.32,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Icon(scheme.icon, color: scheme.accent, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.documentToEdit == null
                      ? context.l10n.idEntryAddIdentityDocumentEyebrow
                            .toUpperCase()
                      : context.l10n.idEntryEditIdentityDocumentEyebrow
                            .toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: scheme.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _uploadHeaderSubtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entrySection({
    required String title,
    required List<Widget> children,
  }) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.45,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.stroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _captureSlot({required _CaptureSide side}) {
    final l10n = context.l10n;
    final palette = context.appPalette;
    final label = _captureSideLabel(side, context);
    final imagePath = _capturedPaths[side];
    final image = !kIsWeb && imagePath != null && imagePath.trim().isNotEmpty
        ? File(imagePath)
        : null;
    final hasFile = image != null && image.existsSync();

    final card = InkWell(
      onTap: (_isSaving || _isScanning) ? null : () => _onCaptureTap(side),
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 176,
        child: CustomPaint(
          painter: _DashedRoundedBorderPainter(
            color: palette.strokeStrong,
            radius: 24,
            strokeWidth: 1.5,
            dashWidth: 8,
            dashGap: 6,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: palette.surfaceSoft,
              child: hasFile
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(image, fit: BoxFit.cover, cacheWidth: 1200),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 42,
                            color: Colors.black.withValues(alpha: 0.25),
                            alignment: Alignment.center,
                            child: Text(
                              l10n.idEntryCaptureSideCaptured(label),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 42,
                            color: context.appPalette.primary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
    return card;
  }

  Widget _slotCaption({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.appPalette.textPrimary,
          ),
        ),
        SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.appPalette.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _identitySubtypeField() {
    return DropdownButtonFormField<_IdentityDocumentSubtype>(
      initialValue: _identitySubtype,
      isExpanded: true,
      menuMaxHeight: 260,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
        color: Color(0xFF9AA7BC),
      ),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: context.l10n.idEntryDocumentTypeHint,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF8A97AD),
        ),
        filled: true,
        fillColor: context.appPalette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.primary, width: 1.2),
        ),
      ),
      items: _IdentityDocumentSubtype.values
          .map(
            (subtype) => DropdownMenuItem<_IdentityDocumentSubtype>(
              value: subtype,
              child: Text(_identitySubtypeLabel(subtype, context)),
            ),
          )
          .toList(growable: false),
      onChanged: (_isSaving || _isScanning)
          ? null
          : (value) {
              if (value == null || value == _identitySubtype) {
                return;
              }
              setState(() {
                _identitySubtype = value;
                _identitySubtypeManuallySet = true;
              });
            },
    );
  }

  Widget _previewPreferenceCard() {
    final l10n = context.l10n;
    final frontPath = _capturedPaths[_CaptureSide.front]?.trim() ?? '';
    final hasFrontImage = frontPath.isNotEmpty;
    final effectivePreviewPath = (_previewImagePath ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                size: 18,
                color: context.appPalette.primary,
              ),
              SizedBox(width: 8),
              Text(
                l10n.idEntryPreviewImageTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            l10n.idEntryPreviewImageDescription,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textSecondary,
              height: 1.3,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.idEntryUseFrontImageInDetails,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textPrimary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: _useUploadedImageAsPreview,
                onChanged: (!hasFrontImage || _isSaving || _isScanning)
                    ? null
                    : (enabled) {
                        setState(() {
                          _useUploadedImageAsPreview = enabled;
                          _previewImagePath = enabled ? frontPath : null;
                        });
                      },
                activeThumbColor: context.appPalette.primary,
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            hasFrontImage
                ? (_useUploadedImageAsPreview && effectivePreviewPath.isNotEmpty
                      ? l10n.idEntryPreviewUsesFrontImage
                      : l10n.idEntryPreviewDisabledNotice)
                : l10n.idEntryUploadFrontFirst,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textSecondary,
              height: 1.25,
            ),
          ),
          if (effectivePreviewPath.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              effectivePreviewPath.split(Platform.pathSeparator).last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _referenceAttachmentCard() {
    final l10n = context.l10n;
    final attachments = List<_ReferenceAttachment>.unmodifiable(
      _referenceAttachments,
    );
    final hasSelection = attachments.isNotEmpty;
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: 18,
                color: context.appPalette.primary,
              ),
              SizedBox(width: 8),
              Text(
                l10n.idEntryReferenceAttachmentsTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.appPalette.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            l10n.idEntryReferenceAttachmentDescription,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: (_isSaving || _isScanning) ? null : _pickReferenceAttachment,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: context.appPalette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.appPalette.stroke),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    color: context.appPalette.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasSelection
                          ? l10n.idEntryReferenceFilesAttached(
                              attachments.length,
                            )
                          : l10n.idEntryAddReferenceImagePdf,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: hasSelection
                            ? context.appPalette.textPrimary
                            : context.appPalette.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: context.appPalette.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (hasSelection) ...[
            const SizedBox(height: 8),
            ...attachments.asMap().entries.map((entry) {
              final index = entry.key;
              final attachment = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == attachments.length - 1 ? 0 : 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.appPalette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appPalette.stroke),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file_outlined,
                        size: 16,
                        color: context.appPalette.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachment.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: context.appPalette.textPrimary,
                              ),
                            ),
                            if (attachment.hasLabel) ...[
                              SizedBox(height: 1),
                              Text(
                                attachment.normalizedLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.appPalette.primary,
                                ),
                              ),
                            ],
                            SizedBox(height: 1),
                            Text(
                              attachment.path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.appPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: (_isSaving || _isScanning)
                            ? null
                            : () => _editReferenceAttachmentLabel(index),
                        icon: Icon(
                          attachment.hasLabel
                              ? Icons.edit_rounded
                              : Icons.label_outline_rounded,
                          size: 18,
                          color: context.appPalette.textSecondary,
                        ),
                        tooltip: attachment.hasLabel
                            ? l10n.idEntryEditLabel
                            : l10n.idEntryAddLabel,
                      ),
                      IconButton(
                        onPressed: (_isSaving || _isScanning)
                            ? null
                            : () {
                                setState(() {
                                  _referenceAttachments.removeAt(index);
                                });
                              },
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: context.appPalette.textSecondary,
                        ),
                        tooltip: l10n.commonRemove,
                      ),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.idEntryMultipleFilesHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textMuted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: (_isSaving || _isScanning)
                      ? null
                      : () {
                          setState(() {
                            _referenceAttachments.clear();
                          });
                        },
                  child: Text(l10n.idEntryClearAll),
                ),
              ],
            ),
          ],
        ],
      ),
    );
    return card;
  }

  Future<void> _onCaptureTap(_CaptureSide side) async {
    if (_isSaving || _isScanning) {
      return;
    }

    final existingImagePath = _existingCapturePath(side);
    if (existingImagePath != null) {
      final action = await _selectExistingCaptureAction(side);
      if (action == null || !mounted) {
        return;
      }
      if (action == _CaptureExistingAction.preview) {
        await _openCapturePreview(side: side, imagePath: existingImagePath);
        return;
      }
    }

    final inputMethod = await _selectInputMethod();
    if (inputMethod == null || !mounted) {
      return;
    }
    await _captureAndAutofill(side, inputMethod: inputMethod);
  }

  String? _existingCapturePath(_CaptureSide side) {
    if (kIsWeb) {
      return null;
    }
    final path = (_capturedPaths[side] ?? '').trim();
    if (path.isEmpty) {
      return null;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    return path;
  }

  Future<_CaptureExistingAction?> _selectExistingCaptureAction(
    _CaptureSide side,
  ) {
    return showAdaptiveModal<_CaptureExistingAction>(
      context: context,
      backgroundColor: context.appPalette.background,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.idEntryCaptureAlreadyAdded(
                    _captureSideLabel(side, context),
                  ),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  context.l10n.idEntryCapturePreviewOrReplaceQuestion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                _sourceOptionTile(
                  title: context.l10n.documentPreview,
                  subtitle: context.l10n.idEntryOpenCurrentImageFullscreen,
                  icon: Icons.visibility_outlined,
                  onTap: () =>
                      Navigator.of(context).pop(_CaptureExistingAction.preview),
                ),
                const SizedBox(height: 8),
                _sourceOptionTile(
                  title: context.l10n.idEntryReplace,
                  subtitle: context.l10n.idEntryChooseImageSourceReplace,
                  icon: Icons.swap_horiz_rounded,
                  onTap: () =>
                      Navigator.of(context).pop(_CaptureExistingAction.replace),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCapturePreview({
    required _CaptureSide side,
    required String imagePath,
  }) async {
    if (kIsWeb) {
      return;
    }
    final file = File(imagePath);
    if (!await file.exists()) {
      if (mounted) {
        _showSnack(context.l10n.idEntryPreviewImageUnavailable);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CapturePreviewPage(
          title: _captureSideLabel(side, context),
          imagePath: imagePath,
        ),
      ),
    );
  }

  Future<_CaptureInputMethod?> _selectInputMethod() {
    return showAdaptiveModal<_CaptureInputMethod>(
      context: context,
      backgroundColor: context.appPalette.background,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.idEntryChooseImageSource,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  context.l10n.idEntryImageUsedForOcrAndPreview,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                _sourceOptionTile(
                  title: context.l10n.profileTakePhoto,
                  subtitle: context.l10n.idEntryUseCameraAutoCrop,
                  icon: Icons.photo_camera_rounded,
                  onTap: () =>
                      Navigator.of(context).pop(_CaptureInputMethod.camera),
                ),
                const SizedBox(height: 8),
                _sourceOptionTile(
                  title: context.l10n.idEntryPhotoLibrary,
                  subtitle: context.l10n.idEntrySelectClearImageFromGallery,
                  icon: Icons.photo_library_rounded,
                  onTap: () =>
                      Navigator.of(context).pop(_CaptureInputMethod.gallery),
                ),
                const SizedBox(height: 8),
                _sourceOptionTile(
                  title: context.l10n.idEntryChooseFile,
                  subtitle: context.l10n.idEntryPickImageOrPdf,
                  icon: Icons.folder_open_rounded,
                  onTap: () =>
                      Navigator.of(context).pop(_CaptureInputMethod.file),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sourceOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFEAF0FF),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: context.appPalette.primary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: context.appPalette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _formFields() {
    final l10n = context.l10n;
    final widgets = <Widget>[];

    void addLabel(String text) {
      widgets.add(
        Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: context.appPalette.textPrimary,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 6));
    }

    void addGap(double value) {
      widgets.add(SizedBox(height: value));
    }

    if (widget.type == DocumentType.passport) {
      addLabel(l10n.idEntryPassportNumber);
      widgets.add(
        _inputField(
          controller: _identifierController,
          hint: l10n.idEntryEnterPassportNumber,
          validator: _requiredValidator,
        ),
      );
      addGap(12);
      addLabel(l10n.idEntryFullNameAsPassport);
      widgets.add(
        _inputField(
          controller: _fullNameController,
          hint: l10n.idEntryEnterFullName,
          validator: _requiredValidator,
        ),
      );
      addGap(12);
      widgets.add(
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.idEntryNationality,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _countryDropdownField(
                    controller: _countryController,
                    validator: _requiredValidator,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.idEntryDateOfBirth,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _expiryDatePickerField(
                    controller: _birthDateController,
                    hint: l10n.idEntryDateFormatHint,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      addGap(12);
      widgets.add(
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.idEntryExpiryDate,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _expiryDatePickerField(
                    controller: _expiryDateController,
                    hint: l10n.idEntrySelectExpiryDate,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.idEntryIssuingCountry,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _countryDropdownField(
                    controller: _issuerController,
                    validator: _requiredValidator,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      addGap(12);
      addLabel(l10n.idEntryDocumentHolder);
      widgets.add(_relationDropdownField());
      return widgets;
    }

    if (widget.type == DocumentType.idCard) {
      addLabel(l10n.idEntryDocumentType);
      widgets.add(_identitySubtypeField());
      addGap(12);
      addLabel(_identifierLabel);
      widgets.add(
        _inputField(
          controller: _identifierController,
          hint: _identifierPlaceholder,
          validator: _requiredValidator,
        ),
      );
      addGap(12);
      addLabel(l10n.idEntryFullName);
      widgets.add(
        _inputField(
          controller: _fullNameController,
          hint: l10n.idEntryAsShownOnDocument,
          validator: _requiredValidator,
        ),
      );
      addGap(12);
      if (_identitySubtype == _IdentityDocumentSubtype.residencePermit) {
        widgets.add(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.idEntryNationality,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _countryDropdownField(
                      controller: _countryController,
                      validator: _requiredValidator,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.idEntryIssuingCountry,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _countryDropdownField(
                      controller: _issuerController,
                      validator: _requiredValidator,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        addGap(12);
        addLabel(l10n.idEntryExpiryDate);
        widgets.add(
          _expiryDatePickerField(
            controller: _expiryDateController,
            hint: l10n.idEntrySelectExpiryDate,
          ),
        );
      } else {
        widgets.add(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.idEntryNationality,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _countryDropdownField(
                      controller: _countryController,
                      validator: _requiredValidator,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.idEntryExpiryDate,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _expiryDatePickerField(
                      controller: _expiryDateController,
                      hint: l10n.idEntrySelectExpiryDate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      addGap(12);
      addLabel(l10n.idEntryDocumentHolder);
      widgets.add(_relationDropdownField());
      return widgets;
    }

    addLabel(_identifierLabel);
    widgets.add(
      _inputField(
        controller: _identifierController,
        hint: _identifierPlaceholder,
        validator: _requiredValidator,
      ),
    );
    addGap(12);
    addLabel(l10n.idEntryFullName);
    widgets.add(
      _inputField(
        controller: _fullNameController,
        hint: l10n.idEntryNameFromDocument,
      ),
    );
    addGap(12);
    widgets.add(
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.idEntryCountry,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                _countryDropdownField(controller: _countryController),
              ],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.idEntryExpiryDate,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                _expiryDatePickerField(
                  controller: _expiryDateController,
                  hint: l10n.idEntrySelectExpiryDate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    addGap(12);
    addLabel(l10n.idEntryIssuingAuthority);
    widgets.add(
      _inputField(
        controller: _authorityController,
        hint: l10n.idEntryAuthorityDepartment,
      ),
    );
    addGap(12);
    addLabel(l10n.credentialFieldNotes);
    widgets.add(
      _inputField(
        controller: _notesController,
        hint: l10n.idEntryOptionalNotes,
        minLines: 2,
        maxLines: 4,
      ),
    );
    addGap(12);
    addLabel(l10n.idEntryDocumentHolder);
    widgets.add(_relationDropdownField());

    return widgets;
  }

  Widget _relationDropdownField() {
    return DropdownButtonFormField<IdentityDocumentHolderRelation>(
      initialValue: _holderRelation,
      isExpanded: true,
      menuMaxHeight: 360,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
        color: Color(0xFF9AA7BC),
      ),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: context.l10n.idEntrySelectHolderRelation,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF8A97AD),
        ),
        filled: true,
        fillColor: context.appPalette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.primary, width: 1.2),
        ),
      ),
      items: IdentityDocumentHolderRelation.values
          .map(
            (relation) => DropdownMenuItem<IdentityDocumentHolderRelation>(
              value: relation,
              child: Text(_holderRelationLabel(relation, context)),
            ),
          )
          .toList(growable: false),
      onChanged: (_isSaving || _isScanning)
          ? null
          : (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _holderRelation = value;
              });
            },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    IconData? suffixIcon,
    int minLines = 1,
    int maxLines = 1,
  }) {
    final isMultiline = maxLines > 1 || minLines > 1;
    final borderRadius = BorderRadius.circular(isMultiline ? 24 : 999);

    return TextFormField(
      controller: controller,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: isMultiline ? TextInputType.multiline : TextInputType.text,
      textInputAction: isMultiline
          ? TextInputAction.newline
          : TextInputAction.next,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintMaxLines: isMultiline ? 3 : 1,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF8A97AD),
        ),
        suffixIcon: suffixIcon == null
            ? null
            : Icon(suffixIcon, size: 20, color: const Color(0xFF9AA7BC)),
        filled: true,
        fillColor: context.appPalette.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isMultiline ? 13 : 15,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: context.appPalette.primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _countryDropdownField({
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    final selected = controller.text.trim();
    final options =
        selected.isEmpty || CountryCatalog.allCountries.contains(selected)
        ? CountryCatalog.allCountries
        : <String>[selected, ...CountryCatalog.allCountries];

    return DropdownButtonFormField<String>(
      initialValue: selected.isEmpty ? null : selected,
      isExpanded: true,
      menuMaxHeight: 360,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
        color: Color(0xFF9AA7BC),
      ),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: context.l10n.idEntryCountry,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF8A97AD),
        ),
        filled: true,
        fillColor: context.appPalette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.primary, width: 1.2),
        ),
      ),
      items: options
          .map(
            (country) => DropdownMenuItem<String>(
              value: country,
              child: Text(
                country,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (_isSaving || _isScanning)
          ? null
          : (value) {
              if (value == null) {
                return;
              }
              setState(() {
                controller.text = value;
              });
            },
      validator: validator == null ? null : (_) => validator(controller.text),
    );
  }

  Widget _expiryDatePickerField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: true,
      onTap: () => _pickDate(controller),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: context.appPalette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: context.appPalette.textMuted,
        ),
        suffixIcon: Icon(
          Icons.calendar_month_outlined,
          size: 20,
          color: context.appPalette.textMuted,
        ),
        filled: true,
        fillColor: context.appPalette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: context.appPalette.primary, width: 1.2),
        ),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final firstDate = DateTime(1900, 1, 1);
    final lastDate = DateTime(2100, 12, 31);
    final parsed = DocumentOcrParser.parseLooseDate(controller.text);
    var initialDate = parsed ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: context.l10n.idEntrySelectDate,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    });
  }

  Future<void> _captureAndAutofill(
    _CaptureSide side, {
    required _CaptureInputMethod inputMethod,
  }) async {
    if (_isSaving || _isScanning) {
      return;
    }

    await _runCaptureFlow(() async {
      final imagePaths = switch (inputMethod) {
        _CaptureInputMethod.camera => await _captureFromCamera(),
        _CaptureInputMethod.gallery => await _pickFromGallery(),
        _CaptureInputMethod.file => await _pickCaptureImageFromFiles(),
      };
      if (imagePaths.isEmpty) {
        return;
      }
      await _ingestCaptureInput(
        side: side,
        rawPaths: imagePaths,
        source: switch (inputMethod) {
          _CaptureInputMethod.camera => DocumentCaptureSource.camera,
          _CaptureInputMethod.gallery => DocumentCaptureSource.gallery,
          _CaptureInputMethod.file => DocumentCaptureSource.gallery,
        },
      );
    });
  }

  Future<void> _runCaptureFlow(Future<void> Function() action) async {
    if (_isScanning) {
      return;
    }
    final l10n = context.l10n;
    setState(() {
      _isScanning = true;
    });

    try {
      await action();
    } on PlatformException catch (error) {
      _showSnack(_scannerErrorMessage(error));
    } catch (_) {
      _showSnack(l10n.idEntryUnableProcessImage);
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _ingestCaptureInput({
    required _CaptureSide side,
    required List<String> rawPaths,
    required DocumentCaptureSource source,
  }) async {
    final l10n = context.l10n;
    final normalizedPaths = rawPaths
        .map(_normalizeLocalPath)
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    if (normalizedPaths.isEmpty) {
      return;
    }

    final firstPath = normalizedPaths.first;
    if (!_isImagePath(firstPath)) {
      _showSnack(l10n.idEntryUseImageForOcr);
      return;
    }

    final persistedPath = await _persistCapturedImage(
      sourcePath: firstPath,
      side: side,
    );
    if (persistedPath == null || persistedPath.trim().isEmpty) {
      _showSnack(l10n.idEntryUnableSaveSelectedImageLocally);
      return;
    }
    final persistedExists = await File(persistedPath).exists();
    if (!persistedExists) {
      _showSnack(l10n.idEntryUnableReadSelectedImage);
      return;
    }

    _captureSource = source;
    _capturedPaths[side] = persistedPath;
    _capturedPages[side] = normalizedPaths.length;

    if (side == _CaptureSide.front) {
      await _ensurePreviewPreference();
      if (!mounted) {
        return;
      }
      if (_useUploadedImageAsPreview) {
        _previewImagePath = persistedPath;
      }
      await _runFrontOcr(path: persistedPath, side: side);
    } else {
      _showSnack(l10n.idEntryBackSideCapturedNotice);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _runFrontOcr({
    required String path,
    required _CaptureSide side,
  }) async {
    final l10n = context.l10n;
    final sideLabel = _captureSideLabel(side, context).toLowerCase();
    if (!_ocrSupported) {
      _showSnack(l10n.idEntryOcrMobileOnly);
      return;
    }

    TextRecognizer? recognizer;
    try {
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      final rawText = result.text.trim();
      if (rawText.isEmpty) {
        _showSnack(l10n.idEntryNoReadableTextDetected);
        return;
      }

      final suggestion = _ocrParser.parse(
        type: widget.type,
        recognizedText: rawText,
      );
      _applySuggestion(suggestion);
      _applyDetectedIdentitySubtype(suggestion.detectedIdType);

      final mismatch = !_isDetectedTypeCompatible(suggestion.detectedIdType);
      final confidence = (suggestion.confidence * 100).round();
      if (mismatch) {
        _showSnack(
          l10n.idEntryDetectedTypeVerifyFields(suggestion.detectedIdType.label),
        );
      } else {
        _showSnack(
          l10n.idEntryDetectedTypeWithConfidence(
            confidence,
            suggestion.detectedIdType.label,
            sideLabel,
          ),
        );
      }
    } finally {
      await recognizer?.close();
    }
  }

  Future<List<String>> _captureFromCamera() async {
    if (!_mobileCaptureSupported) {
      _showSnack(context.l10n.idEntryCameraMobileOnly);
      return const [];
    }
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 98,
      maxWidth: 4096,
      maxHeight: 4096,
    );
    if (image == null) {
      return const [];
    }
    return [image.path];
  }

  Future<List<String>> _pickFromGallery() async {
    if (!_mobileCaptureSupported) {
      _showSnack(context.l10n.idEntryPhotoLibraryMobileOnly);
      return const [];
    }
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
      maxWidth: 3200,
      maxHeight: 3200,
    );
    if (image == null) {
      return const [];
    }
    return [image.path];
  }

  Future<List<String>> _pickCaptureImageFromFiles() async {
    final l10n = context.l10n;
    const typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
      uniformTypeIdentifiers: [
        'public.jpeg',
        'public.png',
        'org.webmproject.webp',
        'public.heic',
      ],
    );
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) {
      return const [];
    }
    final path = _normalizeLocalPath(file.path);
    if (path.isEmpty) {
      _showSnack(l10n.idEntryUnableAccessSelectedPath);
      return const [];
    }
    return [path];
  }

  Future<void> _pickReferenceAttachment() async {
    final l10n = context.l10n;
    final source = await showAdaptiveModal<_ReferenceAttachmentSource>(
      context: context,
      backgroundColor: context.appPalette.background,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.idEntryReferenceAttachmentTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  context.l10n.idEntryReferenceAttachmentChooseSource,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                _sourceOptionTile(
                  title: context.l10n.idEntryTakeReferencePhoto,
                  subtitle: context.l10n.idEntryCaptureClearImageFromCamera,
                  icon: Icons.photo_camera_rounded,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_ReferenceAttachmentSource.camera),
                ),
                const SizedBox(height: 8),
                _sourceOptionTile(
                  title: context.l10n.profileChooseFromLibrary,
                  subtitle: context.l10n.idEntrySelectImageFromGallery,
                  icon: Icons.photo_library_rounded,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_ReferenceAttachmentSource.gallery),
                ),
                const SizedBox(height: 8),
                _sourceOptionTile(
                  title: context.l10n.idEntryChooseFile,
                  subtitle: context.l10n.idEntryPickImageOrPdf,
                  icon: Icons.folder_open_rounded,
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_ReferenceAttachmentSource.file),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null || !mounted) {
      return;
    }

    try {
      switch (source) {
        case _ReferenceAttachmentSource.camera:
          await _pickReferenceFromImageSource(ImageSource.camera);
          break;
        case _ReferenceAttachmentSource.gallery:
          await _pickReferenceFromImageSource(ImageSource.gallery);
          break;
        case _ReferenceAttachmentSource.file:
          await _pickReferenceFromFileBrowser();
          break;
      }
    } on PlatformException catch (error) {
      _showSnack(_scannerErrorMessage(error));
    } catch (_) {
      _showSnack(l10n.idEntryUnableSelectReferenceAttachment);
    }
  }

  Future<void> _pickReferenceFromImageSource(ImageSource source) async {
    if (!_mobileCaptureSupported) {
      _showSnack(context.l10n.idEntryThisOptionMobileOnly);
      return;
    }
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 4096,
      maxHeight: 4096,
    );
    if (image == null || !mounted) {
      return;
    }
    await _applyReferenceFileSelections([
      _PendingReferenceSelection(sourcePath: image.path),
    ]);
  }

  Future<void> _pickReferenceFromFileBrowser() async {
    final l10n = context.l10n;
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final typeGroup = isIos
        ? const XTypeGroup(
            label: 'reference',
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
            label: 'reference',
            extensions: [
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
              'org.webmproject.webp',
              'public.heic',
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
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty || !mounted) {
      return;
    }

    final selections = <_PendingReferenceSelection>[];
    for (final file in files) {
      final inputPath = (file.path).trim();
      if (inputPath.isEmpty) {
        continue;
      }
      selections.add(
        _PendingReferenceSelection(
          sourcePath: inputPath,
          preferredName: file.name.trim(),
        ),
      );
    }
    if (selections.isEmpty) {
      _showSnack(l10n.idEntryUnableAccessSelectedPath);
      return;
    }
    await _applyReferenceFileSelections(selections);
  }

  Future<void> _applyReferenceFileSelections(
    List<_PendingReferenceSelection> selections,
  ) async {
    if (selections.isEmpty) {
      return;
    }
    final l10n = context.l10n;

    final newlyAdded = <_ReferenceAttachment>[];
    for (final selection in selections) {
      final normalizedSourcePath = _normalizeLocalPath(selection.sourcePath);
      if (normalizedSourcePath.trim().isEmpty) {
        continue;
      }
      if (!_isReferencePath(normalizedSourcePath)) {
        continue;
      }
      final storedPath = await _persistReferenceFile(
        sourcePath: normalizedSourcePath,
      );
      if (storedPath == null || storedPath.trim().isEmpty) {
        continue;
      }
      final storedExists = await File(storedPath).exists();
      if (!storedExists) {
        continue;
      }
      final fallbackName = storedPath.split(Platform.pathSeparator).last;
      final resolvedName = (selection.preferredName ?? '').trim().isNotEmpty
          ? selection.preferredName!.trim()
          : fallbackName;
      newlyAdded.add(
        _ReferenceAttachment(
          name: resolvedName,
          path: storedPath,
          mime: resolvedName.inferMimeType(),
        ),
      );
    }

    if (newlyAdded.isEmpty) {
      _showSnack(l10n.idEntryNoValidReferenceFileAdded);
      return;
    }

    if (!mounted) {
      return;
    }

    var insertedCount = 0;
    setState(() {
      for (final attachment in newlyAdded) {
        final alreadyExists = _referenceAttachments.any(
          (current) =>
              current.path.trim().toLowerCase() ==
              attachment.path.trim().toLowerCase(),
        );
        if (!alreadyExists) {
          _referenceAttachments.add(attachment);
          insertedCount++;
        }
      }
    });

    if (insertedCount <= 0) {
      _showSnack(l10n.idEntrySelectedFilesAlreadyAttached);
      return;
    }
    if (insertedCount == 1) {
      _showSnack(context.l10n.idEntryReferenceAttachmentAdded);
      return;
    }
    _showSnack(context.l10n.idEntryReferenceAttachmentsAdded(insertedCount));
  }

  Future<void> _editReferenceAttachmentLabel(int index) async {
    if (index < 0 || index >= _referenceAttachments.length) {
      return;
    }
    final attachment = _referenceAttachments[index];
    final controller = TextEditingController(text: attachment.normalizedLabel);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final palette = context.appPalette;
        return AlertDialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            context.l10n.idEntryReferenceLabelTitle,
            style: TextStyle(color: palette.textPrimary),
          ),
          content: TextField(
            controller: controller,
            maxLength: 48,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: context.l10n.idEntryReferenceLabelHint,
              hintStyle: TextStyle(color: palette.textMuted),
              counterStyle: TextStyle(color: palette.textMuted),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: palette.stroke),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: palette.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: Text(context.l10n.idEntryClearLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(context.l10n.commonSave),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!mounted || result == null || index >= _referenceAttachments.length) {
      return;
    }
    final normalizedLabel = _sanitizeReferenceLabel(result);
    setState(() {
      _referenceAttachments[index] = _referenceAttachments[index].copyWith(
        label: normalizedLabel,
      );
    });
    _showSnack(
      normalizedLabel.isEmpty
          ? context.l10n.idEntryReferenceLabelCleared
          : context.l10n.idEntryReferenceLabelSaved,
    );
  }

  String _sanitizeReferenceLabel(String raw) {
    final compact = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return '';
    }
    if (compact.length <= 48) {
      return compact;
    }
    return compact.substring(0, 48).trim();
  }

  Future<String?> _persistCapturedImage({
    required String sourcePath,
    required _CaptureSide side,
  }) async {
    return LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: sourcePath,
      directoryName: 'document_images',
      fileNamePrefix: '${widget.type.key}_${side.name}',
    );
  }

  Future<String?> _persistReferenceFile({required String sourcePath}) async {
    return LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: sourcePath,
      directoryName: 'reference_assets',
      fileNamePrefix: '${widget.type.key}_reference',
    );
  }

  String _extensionFromPath(String path) {
    final normalized = path.trim();
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == normalized.length - 1) {
      return '.jpg';
    }
    final rawExtension = normalized.substring(dotIndex).toLowerCase();
    final isValid = RegExp(r'^\.[a-z0-9]{2,5}$').hasMatch(rawExtension);
    return isValid ? rawExtension : '.jpg';
  }

  bool _isImagePath(String path) {
    final extension = _extensionFromPath(path).replaceFirst('.', '');
    return _imageExtensions.contains(extension);
  }

  bool _isReferencePath(String path) {
    final extension = _extensionFromPath(path).replaceFirst('.', '');
    return _referenceExtensions.contains(extension);
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

  Future<void> _ensurePreviewPreference() async {
    if (_hasShownPreviewNotice || !mounted) {
      return;
    }
    _hasShownPreviewNotice = true;
    _showSnack(context.l10n.idEntryFrontImagePreviewNotice);
  }

  void _applySuggestion(DocumentAutoFillSuggestion suggestion) {
    if (suggestion.identifierValue.trim().isNotEmpty) {
      _identifierController.text = suggestion.identifierValue;
    }
    if (suggestion.birthDate != null &&
        _birthDateController.text.trim().isEmpty) {
      _birthDateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(suggestion.birthDate!);
    }
    if (suggestion.expiryDate != null &&
        _expiryDateController.text.trim().isEmpty) {
      _expiryDateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(suggestion.expiryDate!);
    }

    final fieldsByLabel = <String, String>{
      for (final field in suggestion.structuredFields)
        (field['label'] ?? '').toLowerCase(): (field['value'] ?? '').trim(),
    };

    String? claimValue(String canonicalClaimKey) {
      for (final entry in fieldsByLabel.entries) {
        final mappedKey = DocumentMetadataFieldLabels.toCanonicalClaimKey(
          entry.key,
        );
        if (mappedKey == canonicalClaimKey && entry.value.trim().isNotEmpty) {
          return entry.value.trim();
        }
      }
      return null;
    }

    String? firstNonEmpty(List<String?> values) {
      for (final value in values) {
        if ((value ?? '').trim().isNotEmpty) {
          return value!.trim();
        }
      }
      return null;
    }

    var fullName = firstNonEmpty([
      fieldsByLabel['full name'],
      fieldsByLabel['name'],
    ]);
    fullName ??= () {
      final familyName = claimValue(DocumentMetadataFieldLabels.familyName);
      final givenName = claimValue(DocumentMetadataFieldLabels.givenName);
      if ((familyName ?? '').isEmpty && (givenName ?? '').isEmpty) {
        return null;
      }
      return <String>[
        if ((familyName ?? '').isNotEmpty) familyName!,
        if ((givenName ?? '').isNotEmpty) givenName!,
      ].join(' ').trim();
    }();
    if (fullName != null) {
      _fullNameController.text = fullName;
    }

    final country = firstNonEmpty([
      claimValue(DocumentMetadataFieldLabels.nationality),
      fieldsByLabel['nationality'],
      fieldsByLabel['country'],
    ]);
    if (country != null) {
      _countryController.text = country;
    }

    final issuingCountry = firstNonEmpty([
      claimValue(DocumentMetadataFieldLabels.issuingCountry),
      fieldsByLabel['issuing country'],
    ]);
    if (issuingCountry != null) {
      _issuerController.text = issuingCountry;
    } else if (country != null && _issuerController.text.trim().isEmpty) {
      _issuerController.text = country;
    }

    final identifier = firstNonEmpty([
      claimValue(DocumentMetadataFieldLabels.documentNumber),
      fieldsByLabel['passport number'],
      fieldsByLabel['id number'],
      fieldsByLabel['license number'],
    ]);
    if (identifier != null && _identifierController.text.trim().isEmpty) {
      _identifierController.text = identifier;
    }

    final authority = firstNonEmpty([
      fieldsByLabel['issuing authority'],
      fieldsByLabel['authority'],
    ]);
    if (authority != null) {
      _authorityController.text = authority;
    }

    final birth = fieldsByLabel['birth date'];
    final claimBirthDate = claimValue(DocumentMetadataFieldLabels.birthDate);
    final resolvedBirth = firstNonEmpty([birth, claimBirthDate]);
    if ((resolvedBirth ?? '').trim().isNotEmpty &&
        _birthDateController.text.isEmpty) {
      _birthDateController.text = resolvedBirth!;
    }

    final expiry = fieldsByLabel['expiry date'];
    final claimExpiryDate = claimValue(DocumentMetadataFieldLabels.expiryDate);
    final resolvedExpiry = firstNonEmpty([expiry, claimExpiryDate]);
    if ((resolvedExpiry ?? '').trim().isNotEmpty &&
        _expiryDateController.text.isEmpty) {
      _expiryDateController.text = resolvedExpiry!;
    }

    final rawSex = firstNonEmpty([
      claimValue(DocumentMetadataFieldLabels.sex),
      fieldsByLabel['sex'],
      fieldsByLabel['gender'],
      fieldsByLabel['claim.sex'],
    ]);
    if ((rawSex ?? '').trim().isNotEmpty) {
      _detectedSex = _normalizeSexValue(rawSex!);
    }
  }

  void _applyDetectedIdentitySubtype(ScannedIdType detectedType) {
    if (widget.type != DocumentType.idCard || _identitySubtypeManuallySet) {
      return;
    }
    final subtype = _identitySubtypeFromDetected(detectedType);
    if (subtype == null || subtype == _identitySubtype || !mounted) {
      return;
    }
    setState(() {
      _identitySubtype = subtype;
    });
  }

  _IdentityDocumentSubtype? _identitySubtypeFromDetected(
    ScannedIdType detectedType,
  ) {
    return switch (detectedType) {
      ScannedIdType.residencePermit => _IdentityDocumentSubtype.residencePermit,
      ScannedIdType.idCard ||
      ScannedIdType.proofOfAgeCard ||
      ScannedIdType.studentId ||
      ScannedIdType.disabilityCard => _IdentityDocumentSubtype.idCard,
      _ => null,
    };
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final structuredFields = _buildStructuredFields();
      final parsedExpiry = DocumentOcrParser.parseLooseDate(
        _expiryDateController.text,
      );
      final detailToEdit = widget.documentToEdit;
      final resolvedTags = detailToEdit != null && detailToEdit.tags.isNotEmpty
          ? detailToEdit.tags
          : _defaultTagsForType(widget.type);

      final saved = detailToEdit == null
          ? await _createUseCase(
              CreateScannedDocumentParams(
                type: widget.type,
                source: _captureSource,
                scanPagesCount: _totalScannedPages,
                documentTypeKeyOverride: _documentTypeKeyOverrideForSave,
                issuerOverride: _issuerForSave,
                identifierLabelOverride: _identifierLabel,
                identifierValueOverride: _identifierController.text.trim(),
                expiryDateOverride: parsedExpiry,
                structuredFieldsOverride: structuredFields,
                tagsOverride: resolvedTags,
              ),
            )
          : await _updateUseCase(
              UpdateDocumentParams(
                documentId: detailToEdit.id,
                type: widget.type,
                source: _captureSource,
                scanPagesCount: _totalScannedPages,
                documentTypeKeyOverride: _documentTypeKeyOverrideForSave,
                issuerOverride: _issuerForSave,
                identifierLabelOverride: _identifierLabel,
                identifierValueOverride: _identifierController.text.trim(),
                expiryDateOverride: parsedExpiry,
                structuredFieldsOverride: structuredFields,
                tagsOverride: resolvedTags,
              ),
            );
      if (!mounted) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(saved.id);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack(context.l10n.idEntryUnableSaveDocument);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<Map<String, String>> _buildStructuredFields() {
    final fields = <Map<String, String>>[];
    final addedLabels = <String>{};
    final fullName = _fullNameController.text.trim();
    final (familyName, givenName) = _splitFamilyAndGivenName(fullName);
    final birthDateText = _birthDateController.text.trim();
    final expiryDateText = _expiryDateController.text.trim();
    final claimBirthDate = _claimDateValue(birthDateText);
    final claimExpiryDate = _claimDateValue(expiryDateText);
    final birthDate = _tryParseFieldDate(birthDateText);
    final ageOver18 = birthDate != null ? _isAgeOver18(birthDate) : null;
    final documentNumber = _identifierController.text.trim();
    final nationality = _countryController.text.trim();
    final issuingCountry = _issuerForSave.trim();
    final portraitPath = (_capturedPaths[_CaptureSide.front] ?? '').trim();

    void add(String label, String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return;
      }
      final uniqueLabel = label.trim();
      if (!addedLabels.add(uniqueLabel)) {
        return;
      }
      fields.add({'label': label, 'value': trimmed});
    }

    switch (widget.type) {
      case DocumentType.passport:
        add('Passport Number', _identifierController.text);
        add('Full Name', _fullNameController.text);
        add('Nationality', _countryController.text);
        add('Birth Date', _birthDateController.text);
        add('Expiry Date', _expiryDateController.text);
        add('Issuing Country', _issuerController.text);
        break;
      case DocumentType.idCard:
        add(_identifierLabel, _identifierController.text);
        add('Full Name', _fullNameController.text);
        add('Nationality', _countryController.text);
        add('Issuing Country', _issuerController.text);
        add('Expiry Date', _expiryDateController.text);
        break;
      case DocumentType.driversLicense:
        add('License Number', _identifierController.text);
        add('Full Name', _fullNameController.text);
        add('Birth Date', _birthDateController.text);
        add('Expiry Date', _expiryDateController.text);
        add('Issuing Authority', _authorityController.text);
        break;
      case DocumentType.other:
        add('Document ID', _identifierController.text);
        add('Issuer', _issuerController.text);
        add('Notes', _notesController.text);
        break;
    }

    add(
      DocumentMetadataFieldLabels.frontImagePath,
      _capturedPaths[_CaptureSide.front] ?? '',
    );
    add(
      DocumentMetadataFieldLabels.backImagePath,
      _capturedPaths[_CaptureSide.back] ?? '',
    );
    add(
      DocumentMetadataFieldLabels.previewImagePath,
      _useUploadedImageAsPreview ? (_previewImagePath ?? '') : '',
    );
    add(
      DocumentMetadataFieldLabels.previewImageEnabled,
      _useUploadedImageAsPreview ? 'true' : 'false',
    );
    add(DocumentMetadataFieldLabels.familyName, familyName);
    add(DocumentMetadataFieldLabels.givenName, givenName);
    add(DocumentMetadataFieldLabels.birthDate, claimBirthDate);
    add(DocumentMetadataFieldLabels.nationality, nationality);
    add(DocumentMetadataFieldLabels.sex, _detectedSex);
    add(DocumentMetadataFieldLabels.documentNumber, documentNumber);
    add(DocumentMetadataFieldLabels.issuingCountry, issuingCountry);
    add(DocumentMetadataFieldLabels.expiryDate, claimExpiryDate);
    add(DocumentMetadataFieldLabels.portrait, portraitPath);
    add(DocumentMetadataFieldLabels.holderRelation, _holderRelation.storageKey);
    add(
      DocumentMetadataFieldLabels.ageOver18,
      ageOver18 == null ? '' : (ageOver18 ? 'true' : 'false'),
    );
    add(DocumentMetadataFieldLabels.claimFamilyName, familyName);
    add(DocumentMetadataFieldLabels.claimGivenName, givenName);
    add(DocumentMetadataFieldLabels.claimBirthDate, claimBirthDate);
    add(DocumentMetadataFieldLabels.claimNationality, nationality);
    add(DocumentMetadataFieldLabels.claimSex, _detectedSex);
    add(DocumentMetadataFieldLabels.claimDocumentNumber, documentNumber);
    add(DocumentMetadataFieldLabels.claimIssuingCountry, issuingCountry);
    add(DocumentMetadataFieldLabels.claimExpiryDate, claimExpiryDate);
    add(DocumentMetadataFieldLabels.claimPortrait, portraitPath);
    add(
      DocumentMetadataFieldLabels.claimHolderRelation,
      _holderRelation.storageKey,
    );
    add(
      DocumentMetadataFieldLabels.claimAgeOver18,
      ageOver18 == null ? '' : (ageOver18 ? 'true' : 'false'),
    );
    final referenceAssets = _referenceAttachments
        .map((item) => item.toJson())
        .toList(growable: false);
    if (referenceAssets.isNotEmpty) {
      add(
        DocumentMetadataFieldLabels.referenceAssetsJson,
        jsonEncode(referenceAssets),
      );
      final first = _referenceAttachments.first;
      add(DocumentMetadataFieldLabels.referenceAssetName, first.name);
      if (first.hasLabel) {
        add(
          DocumentMetadataFieldLabels.referenceAssetLabel,
          first.normalizedLabel,
        );
      }
      add(DocumentMetadataFieldLabels.referenceAssetPath, first.path);
      add(DocumentMetadataFieldLabels.referenceAssetMime, first.mime);
    }

    return fields;
  }

  (String, String) _splitFamilyAndGivenName(String fullName) {
    final normalized = fullName.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return ('', '');
    }
    final parts = normalized.split(' ');
    if (parts.length == 1) {
      return (parts.first, '');
    }
    return (parts.first, parts.skip(1).join(' '));
  }

  DateTime? _tryParseFieldDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    final formats = <DateFormat>[
      DateFormat('dd/MM/yyyy'),
      DateFormat('d/M/yyyy'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd MMM yyyy'),
      DateFormat('d MMM yyyy'),
    ];
    for (final format in formats) {
      try {
        return format.parseStrict(value);
      } catch (_) {
        // Expected: trying multiple date formats — move to next pattern.
      }
    }
    return null;
  }

  String _claimDateValue(String raw) {
    final parsed = _tryParseFieldDate(raw);
    if (parsed == null) {
      return raw.trim();
    }
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  bool _isAgeOver18(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final hasNotReachedBirthday =
        now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day);
    if (hasNotReachedBirthday) {
      age -= 1;
    }
    return age >= 18;
  }

  String _normalizeSexValue(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'm' || normalized == 'male') {
      return 'M';
    }
    if (normalized == 'f' || normalized == 'female') {
      return 'F';
    }
    return value.trim().toUpperCase();
  }

  List<String> _defaultTagsForType(DocumentType type) {
    return switch (type) {
      DocumentType.passport => const ['Travel', 'ID', 'Personal'],
      DocumentType.idCard => const ['Travel', 'ID', 'Personal'],
      DocumentType.driversLicense => const ['Driving', 'ID', 'Essential'],
      DocumentType.other => const ['Document'],
    };
  }

  bool _isDetectedTypeCompatible(ScannedIdType detected) {
    return switch (widget.type) {
      DocumentType.passport => detected == ScannedIdType.passport,
      DocumentType.idCard =>
        _identitySubtype == _IdentityDocumentSubtype.idCard
            ? detected == ScannedIdType.idCard ||
                  detected == ScannedIdType.studentId ||
                  detected == ScannedIdType.disabilityCard ||
                  detected == ScannedIdType.proofOfAgeCard
            : detected == ScannedIdType.residencePermit,
      DocumentType.driversLicense => detected == ScannedIdType.driversLicense,
      DocumentType.other => true,
    };
  }

  int get _totalScannedPages {
    if (_capturedPages.isEmpty) {
      return _existingScanPagesCount <= 0 ? 1 : _existingScanPagesCount;
    }
    final sum = _capturedPages.values.fold<int>(0, (acc, count) => acc + count);
    return sum <= 0 ? 1 : sum;
  }

  String get _uploadHeaderTitle {
    final l10n = context.l10n;
    return switch (widget.type) {
      DocumentType.passport => l10n.idEntryPassport,
      DocumentType.idCard =>
        _identitySubtype == _IdentityDocumentSubtype.idCard
            ? l10n.idEntryIdDocuments
            : l10n.idEntryResidencePermit,
      DocumentType.driversLicense => l10n.idEntryDriversLicense,
      DocumentType.other => l10n.idEntryDocumentImages,
    };
  }

  String get _uploadHeaderSubtitle {
    final l10n = context.l10n;
    return switch (widget.type) {
      DocumentType.passport => l10n.idEntryPassportUploadSubtitle,
      DocumentType.idCard =>
        _identitySubtype == _IdentityDocumentSubtype.idCard
            ? l10n.idEntryIdentityUploadSubtitle
            : l10n.idEntryResidencePermitUploadSubtitle,
      DocumentType.driversLicense => l10n.idEntryDriversLicenseUploadSubtitle,
      DocumentType.other => l10n.idEntryDocumentUploadSubtitle,
    };
  }

  String get _informationTitle {
    final l10n = context.l10n;
    return switch (widget.type) {
      DocumentType.passport => l10n.idEntryPassportInformation,
      DocumentType.idCard =>
        _identitySubtype == _IdentityDocumentSubtype.idCard
            ? l10n.idEntryIdInformation
            : l10n.idEntryResidencePermitInformation,
      DocumentType.driversLicense => l10n.idEntryDriversLicenseInformation,
      DocumentType.other => l10n.idEntryDocumentInformation,
    };
  }

  String get _primaryActionLabel {
    return context.l10n.commonSave;
  }

  String get _identifierLabel {
    final l10n = context.l10n;
    return switch (widget.type) {
      DocumentType.passport => l10n.idEntryPassportNumber,
      DocumentType.idCard =>
        _identitySubtype == _IdentityDocumentSubtype.idCard
            ? l10n.idEntryIdNumber
            : l10n.idEntryPermitNumber,
      DocumentType.driversLicense => l10n.idEntryLicenseNumber,
      DocumentType.other => l10n.idEntryDocumentId,
    };
  }

  String get _identifierPlaceholder {
    final l10n = context.l10n;
    return switch (widget.type) {
      DocumentType.passport => 'A12345678',
      DocumentType.idCard =>
        _identitySubtype == _IdentityDocumentSubtype.idCard
            ? l10n.idEntryEnterIdentificationNumber
            : l10n.idEntryEnterPermitNumber,
      DocumentType.driversLicense => 'DL-1234-5678',
      DocumentType.other => l10n.idEntryReference,
    };
  }

  String? get _documentTypeKeyOverrideForSave {
    if (widget.type != DocumentType.idCard) {
      return null;
    }
    return _identitySubtype.rawTypeKey;
  }

  String get _issuerForSave {
    if (widget.type == DocumentType.passport) {
      final nationality = _countryController.text.trim();
      if (nationality.isNotEmpty) {
        return nationality;
      }
      return _issuerController.text.trim();
    }
    if (widget.type == DocumentType.idCard) {
      final issuingCountry = _issuerController.text.trim();
      if (issuingCountry.isNotEmpty) {
        return issuingCountry;
      }
      final authority = _authorityController.text.trim();
      if (authority.isNotEmpty) {
        return authority;
      }
      return _countryController.text.trim();
    }
    if (widget.type == DocumentType.driversLicense) {
      final authority = _authorityController.text.trim();
      if (authority.isNotEmpty) {
        return authority;
      }
      return _countryController.text.trim();
    }
    return _issuerController.text.trim().isEmpty
        ? context.l10n.idEntryDocument
        : _issuerController.text.trim();
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return context.l10n.idEntryRequired;
    }
    return null;
  }

  void _bootstrapFromDocument(DocumentDetailEntity detail) {
    _captureSource = detail.captureSource;
    _existingScanPagesCount = detail.scanPagesCount <= 0
        ? 1
        : detail.scanPagesCount;
    _hasShownPreviewNotice = true;

    if (widget.type == DocumentType.idCard) {
      _identitySubtype =
          detail.screenTitle.toLowerCase().contains('residence permit')
          ? _IdentityDocumentSubtype.residencePermit
          : _IdentityDocumentSubtype.idCard;
      _identitySubtypeManuallySet = false;
    }

    final familyName = _claimValue(
      detail,
      DocumentMetadataFieldLabels.familyName,
    );
    final givenName = _claimValue(
      detail,
      DocumentMetadataFieldLabels.givenName,
    );
    final resolvedFullName = _firstNonEmpty([
      _fieldValueByLabels(detail, const ['Full Name', 'Name']),
      _joinNames(familyName, givenName),
    ]);
    final resolvedCountry = _firstNonEmpty([
      _claimValue(detail, DocumentMetadataFieldLabels.nationality),
      _fieldValueByLabels(detail, const ['Nationality', 'Country']),
    ]);
    final resolvedIssuerCountry = _firstNonEmpty([
      _claimValue(detail, DocumentMetadataFieldLabels.issuingCountry),
      _fieldValueByLabels(detail, const [
        'Issuing Country',
        'Issuing Authority',
        'Authority',
      ]),
      detail.issuer,
    ]);
    final resolvedIdentifier = _firstNonEmpty([
      _claimValue(detail, DocumentMetadataFieldLabels.documentNumber),
      _fieldValueByLabels(detail, const [
        'Passport Number',
        'ID Number',
        'Permit Number',
        'License Number',
      ]),
    ]);
    final resolvedBirthDate = _firstNonEmpty([
      _claimValue(detail, DocumentMetadataFieldLabels.birthDate),
      _fieldValueByLabels(detail, const ['Birth Date', 'Date of Birth']),
    ]);
    final resolvedExpiryDate = _firstNonEmpty([
      _claimValue(detail, DocumentMetadataFieldLabels.expiryDate),
      _fieldValueByLabels(detail, const ['Expiry Date', 'Valid Until']),
      detail.expiryDate == null
          ? null
          : DateFormat('dd/MM/yyyy').format(detail.expiryDate!),
    ]);
    final resolvedSex = _firstNonEmpty([
      _claimValue(detail, DocumentMetadataFieldLabels.sex),
      _fieldValueByLabels(detail, const ['Sex', 'Gender']),
    ]);

    _identifierController.text = resolvedIdentifier ?? '';
    _fullNameController.text = resolvedFullName ?? '';
    _countryController.text = resolvedCountry ?? '';
    _birthDateController.text = _formatDateForInput(resolvedBirthDate ?? '');
    _expiryDateController.text = _formatDateForInput(resolvedExpiryDate ?? '');
    _issuerController.text = resolvedIssuerCountry ?? '';
    _authorityController.text =
        _fieldValueByLabels(detail, const ['Issuing Authority', 'Authority']) ??
        '';
    _notesController.text = _fieldValueByLabels(detail, const ['Notes']) ?? '';
    _detectedSex = (resolvedSex ?? '').isEmpty
        ? ''
        : _normalizeSexValue(resolvedSex!);
    final resolvedHolderRelation = _firstNonEmpty([
      _claimValue(detail, DocumentMetadataFieldLabels.holderRelation),
      _fieldValueByLabels(detail, const [
        'Holder Relation',
        'Document Holder',
        'Relation',
        'Relationship',
      ]),
    ]);
    _holderRelation = parseIdentityDocumentHolderRelation(
      resolvedHolderRelation,
    );

    final frontPath = _normalizeLocalPath(
      _metadataValue(detail, DocumentMetadataFieldLabels.frontImagePath) ?? '',
    );
    final backPath = _normalizeLocalPath(
      _metadataValue(detail, DocumentMetadataFieldLabels.backImagePath) ?? '',
    );
    if (frontPath.isNotEmpty) {
      _capturedPaths[_CaptureSide.front] = frontPath;
    }
    if (backPath.isNotEmpty) {
      _capturedPaths[_CaptureSide.back] = backPath;
    }

    final previewEnabledRaw = _metadataValue(
      detail,
      DocumentMetadataFieldLabels.previewImageEnabled,
    )?.trim().toLowerCase();
    _useUploadedImageAsPreview = previewEnabledRaw != 'false';
    final explicitPreviewPath = _normalizeLocalPath(
      _metadataValue(detail, DocumentMetadataFieldLabels.previewImagePath) ??
          '',
    );
    final fallbackPreviewPath = frontPath;
    final resolvedPreviewPath = explicitPreviewPath.isNotEmpty
        ? explicitPreviewPath
        : fallbackPreviewPath;
    _previewImagePath =
        _useUploadedImageAsPreview && resolvedPreviewPath.isNotEmpty
        ? resolvedPreviewPath
        : null;

    _referenceAttachments
      ..clear()
      ..addAll(_referenceAttachmentsFromDetail(detail));
  }

  List<_ReferenceAttachment> _referenceAttachmentsFromDetail(
    DocumentDetailEntity detail,
  ) {
    final items = <_ReferenceAttachment>[];
    final seenPaths = <String>{};

    void addItem({
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
      final resolvedName = name.trim().isEmpty
          ? normalizedPath.split(Platform.pathSeparator).last
          : name.trim();
      final resolvedMime = mime.trim().isEmpty
          ? resolvedName.inferMimeType()
          : mime.trim();
      items.add(
        _ReferenceAttachment(
          name: resolvedName,
          path: normalizedPath,
          mime: resolvedMime,
          label: label.trim(),
        ),
      );
    }

    final jsonRaw = _metadataValue(
      detail,
      DocumentMetadataFieldLabels.referenceAssetsJson,
    );
    if ((jsonRaw ?? '').trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonRaw!);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map) {
              continue;
            }
            final map = Map<String, dynamic>.from(item);
            addItem(
              name: (map['name'] ?? '').toString(),
              path: (map['path'] ?? '').toString(),
              mime: (map['mime'] ?? '').toString(),
              label: (map['label'] ?? '').toString(),
            );
          }
        }
      } catch (e) {
        debugPrint('[IdEntry] Failed to parse metadata items: $e');
      }
    }

    addItem(
      name:
          _metadataValue(
            detail,
            DocumentMetadataFieldLabels.referenceAssetName,
          ) ??
          '',
      path:
          _metadataValue(
            detail,
            DocumentMetadataFieldLabels.referenceAssetPath,
          ) ??
          '',
      mime:
          _metadataValue(
            detail,
            DocumentMetadataFieldLabels.referenceAssetMime,
          ) ??
          '',
      label:
          _metadataValue(
            detail,
            DocumentMetadataFieldLabels.referenceAssetLabel,
          ) ??
          '',
    );

    return items;
  }

  String? _metadataValue(DocumentDetailEntity detail, String label) {
    return _fieldValueByLabels(detail, <String>[label]);
  }

  String? _claimValue(DocumentDetailEntity detail, String canonicalClaimKey) {
    for (final field in detail.structuredFields) {
      final mappedKey = DocumentMetadataFieldLabels.toCanonicalClaimKey(
        field.label,
      );
      if (mappedKey != canonicalClaimKey) {
        continue;
      }
      final value = field.value.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _fieldValueByLabels(
    DocumentDetailEntity detail,
    List<String> labels,
  ) {
    for (final target in labels) {
      final normalizedTarget = target.trim().toLowerCase();
      for (final field in detail.structuredFields) {
        if (field.label.trim().toLowerCase() != normalizedTarget) {
          continue;
        }
        final value = field.value.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  String _formatDateForInput(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    final parsed = DocumentOcrParser.parseLooseDate(value);
    if (parsed == null) {
      return value;
    }
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  String? _joinNames(String? familyName, String? givenName) {
    final family = (familyName ?? '').trim();
    final given = (givenName ?? '').trim();
    if (family.isEmpty && given.isEmpty) {
      return null;
    }
    if (given.isEmpty) {
      return family;
    }
    if (family.isEmpty) {
      return given;
    }
    return '$family $given';
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  void _bootstrapDefaults() {
    _detectedSex = '';
    _holderRelation = IdentityDocumentHolderRelation.owner;
    switch (widget.type) {
      case DocumentType.passport:
        _countryController.text = 'United Kingdom';
        _issuerController.text = 'United Kingdom';
        break;
      case DocumentType.idCard:
        _identitySubtype = _IdentityDocumentSubtype.idCard;
        _identitySubtypeManuallySet = false;
        _countryController.text = 'United States';
        break;
      case DocumentType.driversLicense:
        _countryController.text = 'United States';
        _authorityController.text = 'Department of State Services';
        break;
      case DocumentType.other:
        _issuerController.text = context.l10n.idEntryOtherDocument;
        break;
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _scannerErrorMessage(PlatformException error) {
    if (error.code == 'UNAVAILABLE') {
      return context.l10n.idEntryCameraLibraryUnavailable;
    }
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return context.l10n.idEntryUnableAccessCameraLibrary;
  }

  String _captureSideLabel(_CaptureSide side, BuildContext context) {
    return switch (side) {
      _CaptureSide.front => context.l10n.idEntryFrontSide,
      _CaptureSide.back => context.l10n.idEntryBackSide,
    };
  }

  String _identitySubtypeLabel(
    _IdentityDocumentSubtype subtype,
    BuildContext context,
  ) {
    return switch (subtype) {
      _IdentityDocumentSubtype.idCard => context.l10n.idEntryIdCard,
      _IdentityDocumentSubtype.residencePermit =>
        context.l10n.idEntryResidencePermit,
    };
  }

  String _holderRelationLabel(
    IdentityDocumentHolderRelation relation,
    BuildContext context,
  ) {
    return switch (relation) {
      IdentityDocumentHolderRelation.owner =>
        context.l10n.identityRelationOwner,
      IdentityDocumentHolderRelation.family =>
        context.l10n.identityRelationFamily,
      IdentityDocumentHolderRelation.parent =>
        context.l10n.identityRelationParent,
      IdentityDocumentHolderRelation.wife => context.l10n.identityRelationWife,
      IdentityDocumentHolderRelation.husband =>
        context.l10n.identityRelationHusband,
      IdentityDocumentHolderRelation.son => context.l10n.identityRelationSon,
      IdentityDocumentHolderRelation.daughter =>
        context.l10n.identityRelationDaughter,
      IdentityDocumentHolderRelation.other =>
        context.l10n.identityRelationOther,
    };
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap;
  }
}

class _ReferenceAttachment {
  const _ReferenceAttachment({
    required this.name,
    required this.path,
    required this.mime,
    this.label = '',
  });

  final String name;
  final String path;
  final String mime;
  final String label;

  String get normalizedLabel => label.trim();
  bool get hasLabel => normalizedLabel.isNotEmpty;

  _ReferenceAttachment copyWith({
    String? name,
    String? path,
    String? mime,
    String? label,
  }) {
    return _ReferenceAttachment(
      name: name ?? this.name,
      path: path ?? this.path,
      mime: mime ?? this.mime,
      label: label ?? this.label,
    );
  }

  Map<String, String> toJson() {
    final payload = <String, String>{'name': name, 'path': path, 'mime': mime};
    if (hasLabel) {
      payload['label'] = normalizedLabel;
    }
    return payload;
  }
}

class _PendingReferenceSelection {
  const _PendingReferenceSelection({
    required this.sourcePath,
    this.preferredName,
  });

  final String sourcePath;
  final String? preferredName;
}

enum _CaptureSide { front, back }

enum _CaptureInputMethod { camera, gallery, file }

enum _CaptureExistingAction { preview, replace }

enum _ReferenceAttachmentSource { camera, gallery, file }

enum _IdentityDocumentSubtype { idCard, residencePermit }

class _EntryScheme {
  const _EntryScheme({
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

_EntryScheme _entrySchemeForType(DocumentType type) {
  return switch (type) {
    DocumentType.passport => const _EntryScheme(
      background: Color(0xFFFFEEF1),
      border: Color(0xFFF1D5DA),
      accent: Color(0xFF7B3341),
      icon: Icons.travel_explore_rounded,
    ),
    DocumentType.idCard => const _EntryScheme(
      background: Color(0xFFEAF0FF),
      border: Color(0xFFD8E2FF),
      accent: Color(0xFF2353B8),
      icon: Icons.badge_outlined,
    ),
    DocumentType.driversLicense => const _EntryScheme(
      background: Color(0xFFE7F6EF),
      border: Color(0xFFCDEBDD),
      accent: Color(0xFF187C63),
      icon: Icons.directions_car_filled_rounded,
    ),
    DocumentType.other => const _EntryScheme(
      background: Color(0xFFF6F1E3),
      border: Color(0xFFE9E0C8),
      accent: Color(0xFF6D6250),
      icon: Icons.description_rounded,
    ),
  };
}

Color _entryTint(
  BuildContext context,
  Color lightColor,
  Color accent, {
  double darkAlpha = 0.18,
}) {
  if (Theme.of(context).brightness != Brightness.dark) {
    return lightColor;
  }
  return Color.alphaBlend(
    accent.withValues(alpha: darkAlpha),
    context.appPalette.surface,
  );
}

class _CapturePreviewPage extends StatelessWidget {
  const _CapturePreviewPage({required this.title, required this.imagePath});

  final String title;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: GenericAppBar(
        backgroundColor: Colors.black,
        onBackPressed: () => Navigator.of(context).maybePop(),
        iconColor: Colors.white,
        iconBackgroundColor: const Color(0x1FFFFFFF),
        title: context.l10n.idEntryPreviewTitle(title),
        titleColor: Colors.white,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        showDivider: false,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            cacheWidth: 2400,
            errorBuilder: (context, error, stackTrace) {
              return Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  context.l10n.idEntryUnableLoadPreviewImage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

extension on _IdentityDocumentSubtype {
  String get rawTypeKey {
    return switch (this) {
      _IdentityDocumentSubtype.idCard => 'id_card',
      _IdentityDocumentSubtype.residencePermit => 'residence_permit',
    };
  }
}
