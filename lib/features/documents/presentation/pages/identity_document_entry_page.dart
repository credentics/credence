import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/domain/documents/entities/country_catalog.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_holder_relation.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/delete_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/set_primary_identity_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_file_preview_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/services/document_ocr_parser.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

const String _idFormFontDisplay = 'Manrope';
const String _idFormFontBody = 'Manrope';
const String _idFormFontMono = 'JetBrains Mono';

const Color _idFormBg = Color(0xFFFEFCF8);
const Color _idFormSurface = Color(0xFFFFFFFF);
const Color _idFormInk = Color(0xFF2C2925);
const Color _idFormMuted = Color(0xFF8F8980);
const Color _idFormHairline = Color(0xFFEDE8E1);
const Color _idFormField = Color(0xFFF7F4EF);
const Color _idFormPrimary = Color(0xFF2E5BD7);
const Color _idFormRisk = Color(0xFFD44232);

class IdentityDocumentEntryPage extends StatefulWidget {
  const IdentityDocumentEntryPage({
    super.key,
    this.initialType = DocumentType.passport,
    this.documentToEdit,
    CreateScannedDocument? createScannedDocument,
    UpdateDocument? updateDocument,
    DeleteDocument? deleteDocument,
    SetPrimaryIdentityDocument? setPrimaryIdentityDocument,
  }) : _createScannedDocument = createScannedDocument,
       _updateDocument = updateDocument,
       _deleteDocument = deleteDocument,
       _setPrimaryIdentityDocument = setPrimaryIdentityDocument;

  final DocumentType initialType;
  final DocumentDetailEntity? documentToEdit;
  final CreateScannedDocument? _createScannedDocument;
  final UpdateDocument? _updateDocument;
  final DeleteDocument? _deleteDocument;
  final SetPrimaryIdentityDocument? _setPrimaryIdentityDocument;

  @override
  State<IdentityDocumentEntryPage> createState() =>
      _IdentityDocumentEntryPageState();
}

class _IdentityDocumentEntryPageState extends State<IdentityDocumentEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _notesController = TextEditingController();

  late _IdentityFormType _selectedType;
  String _country = 'France';
  IdentityDocumentHolderRelation _holderRelation =
      IdentityDocumentHolderRelation.owner;
  bool _isPrimary = false;
  bool _isSaving = false;
  bool _isPicking = false;
  final List<_IdentityAttachment> _attachments = <_IdentityAttachment>[];
  _IdentitySource _source = _IdentitySource.files;

  CreateScannedDocument get _createUseCase =>
      widget._createScannedDocument ?? getIt();
  UpdateDocument get _updateUseCase => widget._updateDocument ?? getIt();
  DeleteDocument get _deleteUseCase => widget._deleteDocument ?? getIt();
  SetPrimaryIdentityDocument get _setPrimaryUseCase =>
      widget._setPrimaryIdentityDocument ?? getIt();

  bool get _isEditing => widget.documentToEdit != null;

  @override
  void initState() {
    super.initState();
    final detail = widget.documentToEdit;
    if (detail == null) {
      _selectedType = _IdentityFormType.fromDocumentType(widget.initialType);
      _isPrimary = false;
      return;
    }
    _bootstrapFromDetail(detail);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _holderNameController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: _idFormBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _topBar(),
                  const Divider(height: 1, color: _idFormHairline),
                  Expanded(
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        22,
                        16,
                        22,
                        28 + bottomInset,
                      ),
                      children: [
                        if (_isEditing) ...[
                          _filePreviewCard(
                            compact: false,
                            existingLabel: 'existing file',
                          ),
                          const SizedBox(height: 14),
                        ],
                        _sectionLabel('DOCUMENT'),
                        const SizedBox(height: 8),
                        _fieldGroup(
                          children: [
                            _pickerRow(
                              leading: _typeIcon(_selectedType),
                              eyebrow: 'TYPE',
                              title: _selectedType.label,
                              action: 'Change',
                              onTap: _pickType,
                            ),
                            const SizedBox(height: 8),
                            _pickerRow(
                              leading: _CountryFlag(country: _country),
                              eyebrow: 'ISSUING COUNTRY',
                              title: _country,
                              action: 'Change',
                              onTap: _pickCountry,
                            ),
                            const SizedBox(height: 8),
                            _textInput(
                              controller: _numberController,
                              label: _isEditing
                                  ? 'DOCUMENT NUMBER'
                                  : 'DOCUMENT NUMBER · REQUIRED',
                              hint: _selectedType.numberHint,
                              required: true,
                              mono: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _sectionLabel('HOLDER & DATES'),
                        const SizedBox(height: 8),
                        _fieldGroup(
                          children: [
                            _pickerRow(
                              leading: _holderAvatar,
                              eyebrow: 'HOLDER',
                              title: _holderSummary,
                              action: 'Change',
                              onTap: _pickHolder,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _dateInput(
                                    controller: _issueDateController,
                                    label: _isEditing ? 'ISSUED' : 'ISSUE DATE',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _dateInput(
                                    controller: _expiryDateController,
                                    label: _isEditing
                                        ? 'EXPIRES'
                                        : 'EXPIRY · REQUIRED',
                                    required: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _primaryToggle(),
                          ],
                        ),
                        if (!_isEditing) ...[
                          const SizedBox(height: 14),
                          _sectionLabel('ATTACHMENT'),
                          const SizedBox(height: 8),
                          _filePreviewCard(compact: false),
                          const SizedBox(height: 14),
                          _sectionLabel('SOURCE'),
                          const SizedBox(height: 8),
                          _sourceSegmented(),
                        ],
                        const SizedBox(height: 14),
                        _sectionLabel('NOTES'),
                        const SizedBox(height: 8),
                        _textInput(
                          controller: _notesController,
                          label: 'NOTES (OPTIONAL)',
                          hint: 'Carry photocopy, pickup notes, reminders...',
                          minLines: 3,
                          maxLines: 5,
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 18),
                          _dangerZone(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isSaving || _isPicking)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.14),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          TextButton(
            onPressed: (_isSaving || _isPicking)
                ? null
                : () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(
              foregroundColor: _idFormMuted,
              textStyle: const TextStyle(
                fontFamily: _idFormFontBody,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(context.l10n.commonCancel),
          ),
          Expanded(
            child: Text(
              _isEditing ? 'Edit identity document' : 'Add identity document',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _idFormFontDisplay,
                color: _idFormInk,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.25,
              ),
            ),
          ),
          TextButton(
            onPressed: (_isSaving || _isPicking) ? null : _save,
            style: TextButton.styleFrom(
              foregroundColor: _idFormPrimary,
              textStyle: const TextStyle(
                fontFamily: _idFormFontBody,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontFamily: _idFormFontMono,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.22 * 11,
        color: _idFormMuted,
      ),
    );
  }

  Widget _fieldGroup({required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _pickerRow({
    required Widget leading,
    required String eyebrow,
    required String title,
    required String action,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (_isSaving || _isPicking) ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _idFormField,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Align(alignment: Alignment.centerLeft, child: leading),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        fontFamily: _idFormFontMono,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1 * 9.5,
                        color: _idFormMuted,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _idFormFontBody,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: _idFormInk,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                action,
                style: const TextStyle(
                  fontFamily: _idFormFontMono,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: _idFormMuted,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: _idFormMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    bool mono = false,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: required
          ? (value) => (value ?? '').trim().isEmpty
                ? context.l10n.idEntryRequired
                : null
          : null,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      style: TextStyle(
        fontFamily: mono ? _idFormFontMono : _idFormFontBody,
        fontSize: mono ? 16 : 15,
        fontWeight: mono ? FontWeight.w500 : FontWeight.w600,
        color: _idFormInk,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          fontFamily: _idFormFontMono,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
          color: _idFormMuted,
        ),
        hintStyle: const TextStyle(
          fontFamily: _idFormFontBody,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _idFormMuted,
        ),
        filled: true,
        fillColor: _idFormField,
        contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(maxLines > 1 ? 14 : 12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(maxLines > 1 ? 14 : 12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(maxLines > 1 ? 14 : 12),
          borderSide: const BorderSide(color: _idFormInk, width: 1.5),
        ),
      ),
    );
  }

  Widget _dateInput({
    required TextEditingController controller,
    required String label,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: required
          ? (value) => (value ?? '').trim().isEmpty
                ? context.l10n.idEntryRequired
                : null
          : null,
      onTap: () => _pickDate(controller),
      style: const TextStyle(
        fontFamily: _idFormFontMono,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _idFormInk,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'DD/MM/YYYY',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          fontFamily: _idFormFontMono,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
          color: _idFormMuted,
        ),
        hintStyle: const TextStyle(
          fontFamily: _idFormFontMono,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _idFormMuted,
        ),
        filled: true,
        fillColor: _idFormField,
        contentPadding: const EdgeInsets.fromLTRB(14, 18, 12, 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _idFormInk, width: 1.5),
        ),
      ),
    );
  }

  Widget _primaryToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _idFormField,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRIMARY IDENTITY',
                  style: TextStyle(
                    fontFamily: _idFormFontMono,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.95,
                    color: _idFormMuted,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Use as primary',
                  style: TextStyle(
                    fontFamily: _idFormFontBody,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _idFormInk,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isPrimary,
            activeThumbColor: _idFormSurface,
            activeTrackColor: _idFormInk,
            onChanged: (_isSaving || _isPicking)
                ? null
                : (value) => setState(() => _isPrimary = value),
          ),
        ],
      ),
    );
  }

  Widget _filePreviewCard({required bool compact, String? existingLabel}) {
    final attachments = List<_IdentityAttachment>.unmodifiable(_attachments);
    final attachment = attachments.isEmpty ? null : attachments.first;
    final hasAttachment = attachments.isNotEmpty;
    final title = hasAttachment
        ? (attachments.length == 1
              ? attachment!.name
              : '${attachments.length} files selected')
        : (_isEditing
              ? widget.documentToEdit!.fileName
              : 'Tap to add identity file');
    final sub = hasAttachment
        ? (attachments.length == 1
              ? _attachmentSubtitle(attachment!)
              : _attachmentsSubtitle(attachments))
        : (_isEditing
              ? '${widget.documentToEdit!.fileSizeLabel} · ${existingLabel ?? 'existing file'}'
              : 'PDF, JPG or PNG · preview before save');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (_isSaving || _isPicking)
            ? null
            : (hasAttachment ? null : _pickCurrentSource),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: _idFormSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _idFormHairline),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 124,
                    height: 96,
                    child: _attachmentThumb(attachment),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _idFormFontBody,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: _idFormInk,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _idFormFontBody,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _idFormMuted,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              _fileAction(
                                hasAttachment ? 'Add files' : 'Add file',
                                _pickCurrentSource,
                              ),
                              _fileAction(
                                'Preview',
                                attachment == null
                                    ? null
                                    : () => _previewAttachment(attachment),
                              ),
                              _fileAction(
                                _isEditing && !hasAttachment ? 'Keep' : 'Clear',
                                hasAttachment
                                    ? () => setState(_attachments.clear)
                                    : null,
                                danger: hasAttachment,
                                muted: !hasAttachment,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (attachments.length > 1) ...[
                const Divider(height: 1, color: _idFormHairline),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    children: attachments
                        .asMap()
                        .entries
                        .map((entry) {
                          return _attachmentListTile(entry.key, entry.value);
                        })
                        .toList(growable: false),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentListTile(int index, _IdentityAttachment attachment) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: index == _attachments.length - 1 ? 0 : 6,
      ),
      child: Row(
        children: [
          Icon(
            attachment.isImage
                ? Icons.image_outlined
                : Icons.insert_drive_file_outlined,
            size: 16,
            color: _idFormMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _idFormFontBody,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _idFormInk,
              ),
            ),
          ),
          _fileAction('Preview', () => _previewAttachment(attachment)),
          const SizedBox(width: 12),
          _fileAction(
            'Remove',
            () => setState(() => _attachments.removeAt(index)),
            danger: true,
          ),
        ],
      ),
    );
  }

  Widget _fileAction(
    String label,
    VoidCallback? onTap, {
    bool danger = false,
    bool muted = false,
  }) {
    return GestureDetector(
      onTap: (_isSaving || _isPicking) ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: _idFormFontBody,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: onTap == null || muted
              ? _idFormMuted
              : danger
              ? _idFormRisk
              : _idFormInk,
        ),
      ),
    );
  }

  Widget _attachmentThumb(_IdentityAttachment? attachment) {
    final isImage = attachment?.isImage ?? false;
    final path = attachment?.path ?? '';
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _idFormField),
        child: isImage && !kIsWeb && File(path).existsSync()
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: 240,
                cacheHeight: 240,
              )
            : Center(
                child: Container(
                  width: 62,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _idFormSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CustomPaint(
                    painter: _IdentityPaperPainter(
                      accent: attachment?.isPdf == true
                          ? _idFormRisk
                          : _idFormMuted,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sourceSegmented() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _idFormField,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: _IdentitySource.values
            .map((source) {
              final selected = source == _source;
              return Expanded(
                child: GestureDetector(
                  onTap: (_isSaving || _isPicking)
                      ? null
                      : () async {
                          setState(() => _source = source);
                          await _pickCurrentSource();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? _idFormSurface : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      source.label,
                      style: TextStyle(
                        fontFamily: _idFormFontBody,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: selected ? _idFormInk : _idFormMuted,
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _dangerZone() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (_isSaving || _isPicking) ? null : _deleteDocument,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _idFormSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _idFormHairline),
          ),
          child: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: _idFormRisk, size: 20),
              SizedBox(width: 10),
              Text(
                'Delete document',
                style: TextStyle(
                  fontFamily: _idFormFontBody,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _idFormRisk,
                ),
              ),
              Spacer(),
              Text(
                'Removes file',
                style: TextStyle(
                  fontFamily: _idFormFontBody,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _idFormMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeIcon(_IdentityFormType type) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: type.tint,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(type.icon, color: type.accent, size: 19),
    );
  }

  Widget get _holderAvatar {
    final initials = _holderInitials;
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFEAE3F4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: _idFormFontDisplay,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF514166),
        ),
      ),
    );
  }

  String get _holderSummary {
    final name = _holderNameController.text.trim();
    final relation = _holderLabel(_holderRelation).toLowerCase();
    if (name.isEmpty) {
      return relation == 'owner' ? 'Me · owner' : _holderLabel(_holderRelation);
    }
    return '$name · ${relation == 'owner' ? 'me' : relation}';
  }

  String get _holderInitials {
    final name = _holderNameController.text.trim();
    if (name.isEmpty) {
      return _holderRelation == IdentityDocumentHolderRelation.owner
          ? 'ME'
          : _holderLabel(_holderRelation).characters.first.toUpperCase();
    }
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'ME';
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts.last.characters.first : '';
    return '$first$second'.toUpperCase();
  }

  Future<void> _pickType() async {
    final selected = await showModalBottomSheet<_IdentityFormType>(
      context: context,
      backgroundColor: _idFormSurface,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Document type',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _idFormFontDisplay,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _idFormInk,
                  ),
                ),
                const SizedBox(height: 14),
                ..._IdentityFormType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _bottomSheetOption(
                      leading: _typeIcon(type),
                      title: type.label,
                      subtitle: type.subtitle,
                      selected: type == _selectedType,
                      onTap: () => Navigator.of(sheetContext).pop(type),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || selected == _selectedType || !mounted) return;
    setState(() {
      _selectedType = selected;
    });
  }

  Future<void> _pickCountry() async {
    final searchController = TextEditingController();
    var query = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _idFormSurface,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final countries = CountryCatalog.allCountries
                .where(
                  (country) =>
                      country.toLowerCase().contains(query.toLowerCase()),
                )
                .take(80)
                .toList(growable: false);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  18 + MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.72,
                  child: Column(
                    children: [
                      const Text(
                        'Issuing country',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _idFormFontDisplay,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _idFormInk,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (value) =>
                            setSheetState(() => query = value),
                        style: const TextStyle(
                          fontFamily: _idFormFontBody,
                          fontWeight: FontWeight.w600,
                          color: _idFormInk,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          hintText: 'Search country',
                          filled: true,
                          fillColor: _idFormField,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: countries.length,
                          itemBuilder: (context, index) {
                            final country = countries[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _bottomSheetOption(
                                leading: _CountryFlag(country: country),
                                title: country,
                                subtitle: country == _country ? 'Selected' : '',
                                selected: country == _country,
                                onTap: () =>
                                    Navigator.of(sheetContext).pop(country),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    searchController.dispose();
    if (selected == null || selected.trim().isEmpty || !mounted) return;
    setState(() => _country = selected.trim());
  }

  Future<void> _pickHolder() async {
    final nameController = TextEditingController(
      text: _holderNameController.text,
    );
    var relation = _holderRelation;
    final result = await showModalBottomSheet<_HolderPickResult>(
      context: context,
      backgroundColor: _idFormSurface,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  18 + MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Holder',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _idFormFontDisplay,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _idFormInk,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sheetTextField(
                      controller: nameController,
                      label: 'HOLDER NAME',
                      hint: 'e.g. Maya Benoit',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: IdentityDocumentHolderRelation.values
                          .map((item) {
                            final selected = item == relation;
                            return ChoiceChip(
                              label: Text(_holderLabel(item)),
                              selected: selected,
                              onSelected: (_) =>
                                  setSheetState(() => relation = item),
                              labelStyle: TextStyle(
                                fontFamily: _idFormFontBody,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: selected ? _idFormSurface : _idFormInk,
                              ),
                              selectedColor: _idFormInk,
                              backgroundColor: _idFormField,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(
                        _HolderPickResult(
                          name: nameController.text,
                          relation: relation,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _idFormInk,
                        foregroundColor: _idFormSurface,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(context.l10n.commonSave),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    if (result == null || !mounted) return;
    setState(() {
      _holderNameController.text = result.name.trim();
      _holderRelation = result.relation;
    });
  }

  Widget _bottomSheetOption({
    required Widget leading,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0ECE5) : _idFormField,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _idFormInk : Colors.transparent,
              width: selected ? 1.2 : 0,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _idFormFontBody,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _idFormInk,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _idFormFontBody,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _idFormMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded, color: _idFormInk, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontFamily: _idFormFontBody,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _idFormInk,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: _idFormField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final firstDate = DateTime(1900);
    final lastDate = DateTime(2100, 12, 31);
    final parsed = DocumentOcrParser.parseLooseDate(controller.text);
    var initialDate = parsed ?? DateTime.now();
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    });
  }

  Future<void> _pickCurrentSource() async {
    if (_isSaving || _isPicking) return;
    setState(() => _isPicking = true);
    try {
      final attachments = switch (_source) {
        _IdentitySource.files => await _pickFromFiles(),
        _IdentitySource.photos => await _pickFromImageSource(
          ImageSource.gallery,
        ),
        _IdentitySource.scan => await _pickFromImageSource(ImageSource.camera),
      };
      if (attachments.isEmpty || !mounted) return;
      setState(() => _mergeAttachments(attachments));
    } on PlatformException catch (error) {
      _showSnack(
        error.message ?? context.l10n.idEntryUnableAccessCameraLibrary,
      );
    } catch (_) {
      _showSnack(context.l10n.idEntryUnableSelectReferenceAttachment);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<List<_IdentityAttachment>> _pickFromFiles() async {
    final unableAccessPath = context.l10n.idEntryUnableAccessSelectedPath;
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final typeGroup = isIos
        ? const XTypeGroup(
            label: 'identity',
            uniformTypeIdentifiers: ['public.image', 'com.adobe.pdf'],
          )
        : const XTypeGroup(
            label: 'identity',
            extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'],
            uniformTypeIdentifiers: [
              'public.jpeg',
              'public.png',
              'org.webmproject.webp',
              'public.heic',
              'com.adobe.pdf',
            ],
          );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return const <_IdentityAttachment>[];
    final attachments = <_IdentityAttachment>[];
    for (final file in files) {
      final path = file.path.trim();
      if (path.isEmpty) {
        continue;
      }
      final stored = await _persistAttachment(path);
      if (stored == null) continue;
      attachments.add(
        _IdentityAttachment(
          name: file.name.trim().isEmpty
              ? stored.split(Platform.pathSeparator).last
              : file.name.trim(),
          path: stored,
          mime: file.mimeType ?? file.name.inferMimeType(),
        ),
      );
    }
    if (attachments.isEmpty) {
      _showSnack(unableAccessPath);
      return const <_IdentityAttachment>[];
    }
    return attachments;
  }

  Future<List<_IdentityAttachment>> _pickFromImageSource(
    ImageSource source,
  ) async {
    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      _showSnack(context.l10n.idEntryThisOptionMobileOnly);
      return const <_IdentityAttachment>[];
    }
    final picker = ImagePicker();
    final images = source == ImageSource.gallery
        ? await picker.pickMultiImage(
            imageQuality: 96,
            maxWidth: 4096,
            maxHeight: 4096,
          )
        : <XFile>[
            if (await picker.pickImage(
                  source: source,
                  imageQuality: 96,
                  maxWidth: 4096,
                  maxHeight: 4096,
                )
                case final image?)
              image,
          ];
    if (images.isEmpty) return const <_IdentityAttachment>[];

    final attachments = <_IdentityAttachment>[];
    for (final image in images) {
      final stored = await _persistAttachment(image.path);
      if (stored == null) continue;
      attachments.add(
        _IdentityAttachment(
          name: image.name.trim().isEmpty
              ? stored.split(Platform.pathSeparator).last
              : image.name.trim(),
          path: stored,
          mime: image.mimeType ?? image.path.inferMimeType(),
        ),
      );
    }
    return attachments;
  }

  Future<String?> _persistAttachment(String sourcePath) async {
    final unableReadFile = context.l10n.idEntryUnableReadSelectedImage;
    final stored = await LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: sourcePath,
      directoryName: 'identity_documents',
      fileNamePrefix: _selectedType.storageType.key,
    );
    if ((stored ?? '').trim().isEmpty) {
      _showSnack(unableReadFile);
      return null;
    }
    return stored;
  }

  Future<void> _previewAttachment(_IdentityAttachment attachment) async {
    final previewUnavailable = context.l10n.documentPreviewUnavailable;
    final path = attachment.path.trim();
    if (path.isEmpty) return;
    if (!await File(path).exists()) {
      _showSnack(previewUnavailable);
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentFilePreviewPage(
          filePath: path,
          title: attachment.name,
          fileName: attachment.name,
          mimeType: attachment.mime,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSaving = true);

    try {
      final detailToEdit = widget.documentToEdit;
      final type = _selectedType.storageType;
      final structuredFields = _buildStructuredFields(detailToEdit);
      final expiryDate = DocumentOcrParser.parseLooseDate(
        _expiryDateController.text,
      );
      final saved = detailToEdit == null
          ? await _createUseCase(
              CreateScannedDocumentParams(
                type: type,
                source: _source == _IdentitySource.scan
                    ? DocumentCaptureSource.camera
                    : DocumentCaptureSource.gallery,
                scanPagesCount: _scanPagesCountForSave(),
                categoryOverride: DocumentCategoryType.identity,
                documentTypeKeyOverride: _selectedType.documentTypeKeyOverride,
                issuerOverride: _country,
                identifierLabelOverride: _selectedType.numberLabel,
                identifierValueOverride: _numberController.text.trim(),
                expiryDateOverride: expiryDate,
                structuredFieldsOverride: structuredFields,
                tagsOverride: _selectedType.defaultTags,
              ),
            )
          : await _updateUseCase(
              UpdateDocumentParams(
                documentId: detailToEdit.id,
                type: type,
                source: _source == _IdentitySource.scan
                    ? DocumentCaptureSource.camera
                    : DocumentCaptureSource.gallery,
                scanPagesCount: _attachments.isEmpty
                    ? (detailToEdit.scanPagesCount <= 0
                          ? 1
                          : detailToEdit.scanPagesCount)
                    : _scanPagesCountForSave(),
                categoryOverride: DocumentCategoryType.identity,
                documentTypeKeyOverride: _selectedType.documentTypeKeyOverride,
                issuerOverride: _country,
                identifierLabelOverride: _selectedType.numberLabel,
                identifierValueOverride: _numberController.text.trim(),
                expiryDateOverride: expiryDate,
                structuredFieldsOverride: structuredFields,
                tagsOverride: detailToEdit.tags.isEmpty
                    ? _selectedType.defaultTags
                    : detailToEdit.tags,
              ),
            );

      if (_isPrimary != (detailToEdit?.isPrimary ?? false) || _isPrimary) {
        await _setPrimaryUseCase(
          SetPrimaryIdentityDocumentParams(
            documentId: saved.id,
            isPrimary: _isPrimary,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(saved.id);
    } catch (_) {
      if (!mounted) return;
      _showSnack(context.l10n.idEntryUnableSaveDocument);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteDocument() async {
    final detail = widget.documentToEdit;
    if (detail == null || _isSaving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _idFormSurface,
          title: const Text(
            'Delete document?',
            style: TextStyle(
              fontFamily: _idFormFontDisplay,
              fontWeight: FontWeight.w800,
              color: _idFormInk,
            ),
          ),
          content: Text(
            context.l10n.documentRemoveDeleteSubtitle,
            style: const TextStyle(
              fontFamily: _idFormFontBody,
              color: _idFormMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _idFormRisk),
              child: Text(context.l10n.commonDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await _deleteUseCase(DeleteDocumentParams(documentId: detail.id));
      if (!mounted) return;
      Navigator.of(context).pop('__deleted__');
    } catch (_) {
      if (mounted) _showSnack(context.l10n.documentUnableRemove);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<Map<String, String>> _buildStructuredFields(
    DocumentDetailEntity? previous,
  ) {
    final fields = <Map<String, String>>[];
    final added = <String>{};
    final controlled = _controlledLabels.map(_normalizeLabel).toSet();

    void add(String label, String value) {
      final cleanLabel = label.trim();
      final cleanValue = value.trim();
      if (cleanLabel.isEmpty || cleanValue.isEmpty) return;
      final key = _normalizeLabel(cleanLabel);
      if (!added.add(key)) return;
      fields.add({'label': cleanLabel, 'value': cleanValue});
    }

    if (previous != null) {
      for (final field in previous.structuredFields) {
        if (controlled.contains(_normalizeLabel(field.label))) continue;
        add(field.label, field.value);
      }
    }

    final fullName = _holderNameController.text.trim();
    final (familyName, givenName) = _splitFamilyAndGivenName(fullName);
    final issueDate = _issueDateController.text.trim();
    final expiryDate = _expiryDateController.text.trim();
    final claimIssueDate = _claimDateValue(issueDate);
    final claimExpiryDate = _claimDateValue(expiryDate);
    final number = _numberController.text.trim();

    add(_selectedType.numberLabel, number);
    add('Full Name', fullName);
    add('Holder Name', fullName);
    add('Nationality', _country);
    add('Issuing Country', _country);
    add('Issue Date', issueDate);
    add('Expiry Date', expiryDate);
    add('Document Holder', _holderLabel(_holderRelation));
    add('Holder Relation', _holderRelation.storageKey);
    add('Notes', _notesController.text);
    add(DocumentMetadataFieldLabels.familyName, familyName);
    add(DocumentMetadataFieldLabels.givenName, givenName);
    add(DocumentMetadataFieldLabels.nationality, _country);
    add(DocumentMetadataFieldLabels.documentNumber, number);
    add(DocumentMetadataFieldLabels.issuingCountry, _country);
    add(DocumentMetadataFieldLabels.expiryDate, claimExpiryDate);
    add(DocumentMetadataFieldLabels.holderRelation, _holderRelation.storageKey);
    add(DocumentMetadataFieldLabels.claimFamilyName, familyName);
    add(DocumentMetadataFieldLabels.claimGivenName, givenName);
    add(DocumentMetadataFieldLabels.claimNationality, _country);
    add(DocumentMetadataFieldLabels.claimDocumentNumber, number);
    add(DocumentMetadataFieldLabels.claimIssuingCountry, _country);
    add(DocumentMetadataFieldLabels.claimExpiryDate, claimExpiryDate);
    add(
      DocumentMetadataFieldLabels.claimHolderRelation,
      _holderRelation.storageKey,
    );
    if (claimIssueDate.isNotEmpty) {
      add('claim.issue_date', claimIssueDate);
    }

    final attachments = List<_IdentityAttachment>.unmodifiable(_attachments);
    if (attachments.isNotEmpty) {
      final attachment = attachments.first;
      add(DocumentMetadataFieldLabels.referenceAssetName, attachment.name);
      add(DocumentMetadataFieldLabels.referenceAssetPath, attachment.path);
      add(DocumentMetadataFieldLabels.referenceAssetMime, attachment.mime);
      add(
        DocumentMetadataFieldLabels.referenceAssetsJson,
        jsonEncode(
          attachments.map((attachment) => attachment.toJson()).toList(),
        ),
      );
      if (attachment.isImage) {
        add(DocumentMetadataFieldLabels.frontImagePath, attachment.path);
        add(DocumentMetadataFieldLabels.previewImagePath, attachment.path);
        add(DocumentMetadataFieldLabels.previewImageEnabled, 'true');
        add(DocumentMetadataFieldLabels.portrait, attachment.path);
        add(DocumentMetadataFieldLabels.claimPortrait, attachment.path);
      }
      if (attachment.isPdf) {
        add(DocumentMetadataFieldLabels.previewImagePath, attachment.path);
        add(DocumentMetadataFieldLabels.previewImageEnabled, 'true');
      }
    }

    return fields;
  }

  void _bootstrapFromDetail(DocumentDetailEntity detail) {
    _selectedType = _IdentityFormType.fromDetail(detail);
    _numberController.text = _firstNonEmpty([
      _claimValue(detail, DocumentMetadataFieldLabels.documentNumber),
      _fieldValue(detail, [
        'Passport Number',
        'ID Number',
        'Permit Number',
        'License Number',
        'Document ID',
      ]),
      detail.fileName,
    ]);
    _holderNameController.text = _firstNonEmpty([
      _fieldValue(detail, ['Holder Name', 'Full Name', 'Name']),
      _joinNames(
        _claimValue(detail, DocumentMetadataFieldLabels.familyName),
        _claimValue(detail, DocumentMetadataFieldLabels.givenName),
      ),
    ]);
    _country = _firstNonEmpty([
      _claimValue(detail, DocumentMetadataFieldLabels.issuingCountry),
      _claimValue(detail, DocumentMetadataFieldLabels.nationality),
      _fieldValue(detail, ['Issuing Country', 'Nationality', 'Country']),
      detail.issuer,
      'France',
    ]);
    _issueDateController.text = _formatDateInput(
      _fieldValue(detail, ['Issue Date', 'Issued']),
    );
    _expiryDateController.text = _formatDateInput(
      _firstNonEmpty([
        _claimValue(detail, DocumentMetadataFieldLabels.expiryDate),
        _fieldValue(detail, ['Expiry Date', 'Expires', 'Valid Until']),
        detail.expiryDate == null
            ? ''
            : DateFormat('dd/MM/yyyy').format(detail.expiryDate!),
      ]),
    );
    _notesController.text = _fieldValue(detail, ['Notes']);
    _holderRelation = parseIdentityDocumentHolderRelation(
      _firstNonEmpty([
        _claimValue(detail, DocumentMetadataFieldLabels.holderRelation),
        _fieldValue(detail, ['Holder Relation', 'Document Holder']),
      ]),
    );
    _isPrimary = detail.isPrimary;
    _source = detail.captureSource == DocumentCaptureSource.camera
        ? _IdentitySource.scan
        : _IdentitySource.files;
    _attachments
      ..clear()
      ..addAll(_attachmentsFromDetail(detail));
  }

  List<_IdentityAttachment> _attachmentsFromDetail(
    DocumentDetailEntity detail,
  ) {
    final referenceJson = _fieldValue(detail, [
      DocumentMetadataFieldLabels.referenceAssetsJson,
    ]);
    final attachments = <_IdentityAttachment>[];
    if (referenceJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(referenceJson);
        if (decoded is List && decoded.isNotEmpty) {
          for (final item in decoded) {
            if (item is! Map) continue;
            final map = Map<String, dynamic>.from(item);
            final path = _normalizeLocalPath((map['path'] ?? '').toString());
            if (path.isEmpty) continue;
            final name = (map['name'] ?? '').toString().trim();
            final mime = (map['mime'] ?? '').toString().trim();
            attachments.add(
              _IdentityAttachment(
                name: name.isEmpty
                    ? path.split(Platform.pathSeparator).last
                    : name,
                path: path,
                mime: mime.isEmpty ? path.inferMimeType() : mime,
              ),
            );
          }
          if (attachments.isNotEmpty) {
            return attachments;
          }
        }
      } catch (_) {
        // Fall back to single metadata fields below.
      }
    }

    final path = _normalizeLocalPath(
      _firstNonEmpty([
        _fieldValue(detail, [DocumentMetadataFieldLabels.referenceAssetPath]),
        _fieldValue(detail, [DocumentMetadataFieldLabels.previewImagePath]),
        _fieldValue(detail, [DocumentMetadataFieldLabels.frontImagePath]),
      ]),
    );
    if (path.isEmpty) return const <_IdentityAttachment>[];
    final name = _firstNonEmpty([
      _fieldValue(detail, [DocumentMetadataFieldLabels.referenceAssetName]),
      detail.fileName,
      path.split(Platform.pathSeparator).last,
    ]);
    final mime = _firstNonEmpty([
      _fieldValue(detail, [DocumentMetadataFieldLabels.referenceAssetMime]),
      path.inferMimeType(),
    ]);
    return <_IdentityAttachment>[
      _IdentityAttachment(name: name, path: path, mime: mime),
    ];
  }

  String _fieldValue(DocumentDetailEntity detail, List<String> labels) {
    for (final target in labels) {
      final normalized = _normalizeLabel(target);
      for (final field in detail.structuredFields) {
        if (_normalizeLabel(field.label) == normalized) {
          final value = field.value.trim();
          if (value.isNotEmpty) return value;
        }
      }
    }
    return '';
  }

  String _claimValue(DocumentDetailEntity detail, String key) {
    for (final field in detail.structuredFields) {
      final mapped = DocumentMetadataFieldLabels.toCanonicalClaimKey(
        field.label,
      );
      if (mapped == key && field.value.trim().isNotEmpty) {
        return field.value.trim();
      }
    }
    return '';
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final clean = (value ?? '').trim();
      if (clean.isNotEmpty) return clean;
    }
    return '';
  }

  String _formatDateInput(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final parsed = DocumentOcrParser.parseLooseDate(value);
    if (parsed == null) return value;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  String _claimDateValue(String raw) {
    final parsed = DocumentOcrParser.parseLooseDate(raw);
    if (parsed == null) return raw.trim();
    return DateFormat('yyyy-MM-dd').format(parsed);
  }

  (String, String) _splitFamilyAndGivenName(String fullName) {
    final normalized = fullName.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return ('', '');
    final parts = normalized.split(' ');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.skip(1).join(' '));
  }

  String _joinNames(String familyName, String givenName) {
    return [
      familyName.trim(),
      givenName.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
  }

  String _holderLabel(IdentityDocumentHolderRelation relation) {
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

  String _attachmentSubtitle(_IdentityAttachment attachment) {
    final label = resolveFileTypeLabel(
      path: attachment.path,
      mime: attachment.mime,
    );
    final size = _fileSizeLabel(attachment.path);
    final pages = attachment.isPdf ? ' · PDF file' : ' · image';
    return '$label · $size$pages';
  }

  String _attachmentsSubtitle(List<_IdentityAttachment> attachments) {
    final imageCount = attachments
        .where((attachment) => attachment.isImage)
        .length;
    final pdfCount = attachments.where((attachment) => attachment.isPdf).length;
    final otherCount = attachments.length - imageCount - pdfCount;
    final parts = <String>[
      if (pdfCount > 0) '$pdfCount PDF',
      if (imageCount > 0) '$imageCount image${imageCount == 1 ? '' : 's'}',
      if (otherCount > 0) '$otherCount file${otherCount == 1 ? '' : 's'}',
    ];
    return '${attachments.length} files · ${parts.join(' · ')}';
  }

  int _scanPagesCountForSave() {
    if (_attachments.isEmpty) return 1;
    final pdfCount = _attachments
        .where((attachment) => attachment.isPdf)
        .length;
    return pdfCount > 0 ? _attachments.length + pdfCount : _attachments.length;
  }

  void _mergeAttachments(List<_IdentityAttachment> incoming) {
    final existingPaths = _attachments.map((item) => item.path).toSet();
    for (final attachment in incoming) {
      if (attachment.path.trim().isEmpty) continue;
      if (existingPaths.add(attachment.path)) {
        _attachments.add(attachment);
      }
    }
  }

  String _fileSizeLabel(String path) {
    try {
      final bytes = File(path).lengthSync();
      if (bytes <= 0) return 'Ready';
      if (bytes >= 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } catch (_) {
      return 'Ready';
    }
  }

  String _normalizeLocalPath(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('file://')) {
      try {
        return Uri.parse(trimmed).toFilePath();
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  String _normalizeLabel(String raw) => raw.trim().toLowerCase();

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static const Set<String> _controlledLabels = {
    'Passport Number',
    'ID Number',
    'Permit Number',
    'License Number',
    'Document ID',
    'Full Name',
    'Holder Name',
    'Nationality',
    'Issuing Country',
    'Issue Date',
    'Expiry Date',
    'Document Holder',
    'Holder Relation',
    'Notes',
    'claim.issue_date',
    DocumentMetadataFieldLabels.familyName,
    DocumentMetadataFieldLabels.givenName,
    DocumentMetadataFieldLabels.nationality,
    DocumentMetadataFieldLabels.documentNumber,
    DocumentMetadataFieldLabels.issuingCountry,
    DocumentMetadataFieldLabels.expiryDate,
    DocumentMetadataFieldLabels.holderRelation,
    DocumentMetadataFieldLabels.claimFamilyName,
    DocumentMetadataFieldLabels.claimGivenName,
    DocumentMetadataFieldLabels.claimNationality,
    DocumentMetadataFieldLabels.claimDocumentNumber,
    DocumentMetadataFieldLabels.claimIssuingCountry,
    DocumentMetadataFieldLabels.claimExpiryDate,
    DocumentMetadataFieldLabels.claimHolderRelation,
    DocumentMetadataFieldLabels.frontImagePath,
    DocumentMetadataFieldLabels.previewImagePath,
    DocumentMetadataFieldLabels.previewImageEnabled,
    DocumentMetadataFieldLabels.portrait,
    DocumentMetadataFieldLabels.claimPortrait,
    DocumentMetadataFieldLabels.referenceAssetName,
    DocumentMetadataFieldLabels.referenceAssetPath,
    DocumentMetadataFieldLabels.referenceAssetMime,
    DocumentMetadataFieldLabels.referenceAssetsJson,
  };
}

enum _IdentitySource {
  files('Files'),
  photos('Photos'),
  scan('Scan');

  const _IdentitySource(this.label);

  final String label;
}

enum _IdentityFormType {
  passport,
  nationalId,
  residencePermit,
  driversLicense,
  other;

  static _IdentityFormType fromDocumentType(DocumentType type) {
    return switch (type) {
      DocumentType.passport => _IdentityFormType.passport,
      DocumentType.idCard => _IdentityFormType.nationalId,
      DocumentType.driversLicense => _IdentityFormType.driversLicense,
      DocumentType.other => _IdentityFormType.other,
    };
  }

  static _IdentityFormType fromDetail(DocumentDetailEntity detail) {
    if (detail.type == DocumentType.idCard &&
        detail.screenTitle.toLowerCase().contains('residence permit')) {
      return _IdentityFormType.residencePermit;
    }
    return fromDocumentType(detail.type);
  }

  DocumentType get storageType {
    return switch (this) {
      _IdentityFormType.passport => DocumentType.passport,
      _IdentityFormType.nationalId => DocumentType.idCard,
      _IdentityFormType.residencePermit => DocumentType.idCard,
      _IdentityFormType.driversLicense => DocumentType.driversLicense,
      _IdentityFormType.other => DocumentType.other,
    };
  }

  String? get documentTypeKeyOverride {
    return switch (this) {
      _IdentityFormType.nationalId => 'id_card',
      _IdentityFormType.residencePermit => 'residence_permit',
      _ => null,
    };
  }

  String get label {
    return switch (this) {
      _IdentityFormType.passport => 'Passport',
      _IdentityFormType.nationalId => 'National ID',
      _IdentityFormType.residencePermit => 'Residence Permit',
      _IdentityFormType.driversLicense => "Driver's License",
      _IdentityFormType.other => 'Other identity',
    };
  }

  String get subtitle {
    return switch (this) {
      _IdentityFormType.passport => 'Travel identity document',
      _IdentityFormType.nationalId => 'Government ID card',
      _IdentityFormType.residencePermit => 'Permit or residence card',
      _IdentityFormType.driversLicense => 'Driving identity document',
      _IdentityFormType.other => 'Fallback identity record',
    };
  }

  String get numberLabel {
    return switch (this) {
      _IdentityFormType.passport => 'Passport Number',
      _IdentityFormType.nationalId => 'ID Number',
      _IdentityFormType.residencePermit => 'Permit Number',
      _IdentityFormType.driversLicense => 'License Number',
      _IdentityFormType.other => 'Document ID',
    };
  }

  String get numberHint {
    return switch (this) {
      _IdentityFormType.passport => '22FR12345',
      _IdentityFormType.nationalId => 'ID-123456',
      _IdentityFormType.residencePermit => 'RP-123456',
      _IdentityFormType.driversLicense => 'DL-1234-5678',
      _IdentityFormType.other => 'Reference number',
    };
  }

  List<String> get defaultTags {
    return switch (this) {
      _IdentityFormType.passport => const ['Travel', 'ID', 'Personal'],
      _IdentityFormType.nationalId => const ['Travel', 'ID', 'Personal'],
      _IdentityFormType.residencePermit => const ['Travel', 'ID', 'Residence'],
      _IdentityFormType.driversLicense => const ['Driving', 'ID', 'Essential'],
      _IdentityFormType.other => const ['Identity'],
    };
  }

  IconData get icon {
    return switch (this) {
      _IdentityFormType.passport => Icons.description_rounded,
      _IdentityFormType.nationalId => Icons.badge_outlined,
      _IdentityFormType.residencePermit => Icons.credit_card_rounded,
      _IdentityFormType.driversLicense => Icons.directions_car_rounded,
      _IdentityFormType.other => Icons.verified_user_outlined,
    };
  }

  Color get tint {
    return switch (this) {
      _IdentityFormType.passport => const Color(0xFFF7DEE4),
      _IdentityFormType.nationalId => const Color(0xFFE4EAF8),
      _IdentityFormType.residencePermit => const Color(0xFFE4F1EB),
      _IdentityFormType.driversLicense => const Color(0xFFF3E7CE),
      _IdentityFormType.other => const Color(0xFFEAE3F4),
    };
  }

  Color get accent {
    return switch (this) {
      _IdentityFormType.passport => const Color(0xFF6D2C3D),
      _IdentityFormType.nationalId => const Color(0xFF2F57B7),
      _IdentityFormType.residencePermit => const Color(0xFF24745D),
      _IdentityFormType.driversLicense => const Color(0xFF9B651D),
      _IdentityFormType.other => const Color(0xFF5F4A7E),
    };
  }
}

class _IdentityAttachment {
  const _IdentityAttachment({
    required this.name,
    required this.path,
    required this.mime,
  });

  final String name;
  final String path;
  final String mime;

  bool get isImage =>
      mime.isImageMimeType || path.inferMimeType().isImageMimeType;
  bool get isPdf =>
      mime.normalizedMimeType == LocalFileMimeTypes.pdf ||
      path.toLowerCase().endsWith('.pdf');

  Map<String, String> toJson() => {'name': name, 'path': path, 'mime': mime};
}

class _HolderPickResult {
  const _HolderPickResult({required this.name, required this.relation});

  final String name;
  final IdentityDocumentHolderRelation relation;
}

class _CountryFlag extends StatelessWidget {
  const _CountryFlag({required this.country});

  final String country;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(_flagEmoji(country), style: const TextStyle(fontSize: 17)),
    );
  }

  static String _flagEmoji(String rawCountry) {
    final country = rawCountry.trim().toLowerCase();
    return switch (country) {
      'france' => '🇫🇷',
      'tunisia' => '🇹🇳',
      'turkey' || 'türkiye' => '🇹🇷',
      'united states' || 'usa' || 'united states of america' => '🇺🇸',
      'united kingdom' || 'uk' || 'great britain' => '🇬🇧',
      'canada' => '🇨🇦',
      'germany' => '🇩🇪',
      'italy' => '🇮🇹',
      'spain' => '🇪🇸',
      'sweden' => '🇸🇪',
      'switzerland' => '🇨🇭',
      'belgium' => '🇧🇪',
      'netherlands' => '🇳🇱',
      'morocco' => '🇲🇦',
      'algeria' => '🇩🇿',
      'egypt' => '🇪🇬',
      'united arab emirates' => '🇦🇪',
      'saudi arabia' => '🇸🇦',
      'japan' => '🇯🇵',
      'china' => '🇨🇳',
      'india' => '🇮🇳',
      'australia' => '🇦🇺',
      'brazil' => '🇧🇷',
      _ => '🏳️',
    };
  }
}

class _IdentityPaperPainter extends CustomPainter {
  const _IdentityPaperPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF3F4149);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, 10),
        const Radius.circular(2),
      ),
      paint,
    );

    paint.color = const Color(0xFFD8D1C8);
    for (var i = 0; i < 5; i++) {
      final y = 18.0 + (i * 9);
      canvas.drawRect(Rect.fromLTWH(8, y, size.width - 16, 2), paint);
    }

    paint.color = accent.withValues(alpha: 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, size.height - 18, size.width - 20, 8),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _IdentityPaperPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
