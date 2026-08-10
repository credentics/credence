import 'dart:math' as math;
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
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_timeline_event_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelWalletDocumentEntryPage extends StatefulWidget {
  const TravelWalletDocumentEntryPage({
    super.key,
    required this.tripId,
    required this.tripTitle,
    required this.events,
    CreateScannedDocument? createDocument,
  }) : _createDocument = createDocument;

  final String tripId;
  final String tripTitle;
  final List<TravelTimelineEventEntity> events;
  final CreateScannedDocument? _createDocument;

  @override
  State<TravelWalletDocumentEntryPage> createState() =>
      _TravelWalletDocumentEntryPageState();
}

class _TravelWalletDocumentEntryPageState
    extends State<TravelWalletDocumentEntryPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _documentType = _documentTypes.first;
  String? _linkedEventId;
  DateTime? _issueDate;
  String _filePath = '';
  bool _isSaving = false;
  bool _isPicking = false;

  CreateScannedDocument get _createUseCase => widget._createDocument ?? getIt();

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        !_isSaving &&
        _titleController.text.trim().isNotEmpty &&
        _filePath.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.surface,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.travelWalletAddDocumentTitle,
        titleStyle: TextStyle(
          fontSize: 20,
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
            border: Border(top: BorderSide(color: context.appPalette.stroke)),
          ),
          child: FilledButton.icon(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: const Color(0xFF1F57D4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.save_outlined, size: 20),
            label: Text(
              _isSaving
                  ? context.l10n.commonSaving
                  : context.l10n.travelWalletSaveAction,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            const TravelSectionLabel(value: 'Document information'),
            const SizedBox(height: 10),
            _fieldLabel('Document Type'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _documentType,
              decoration: travelInputDecoration(
                context,
                hintText: context.l10n.travelFieldSelectType,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Color(0xFF7E90AB),
              ),
              items: _documentTypes
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
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
                if (value == null) {
                  return;
                }
                setState(() {
                  _documentType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _fieldLabel('Document Title'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: travelInputTextStyle(context),
              decoration: travelInputDecoration(
                context,
                hintText: context.l10n.travelHintDocTitle,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Linked Timeline Event'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _linkedEventId,
              decoration: travelInputDecoration(
                context,
                hintText: context.l10n.commonOptional,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Color(0xFF7E90AB),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    context.l10n.commonOptional,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                ),
                ...widget.events.map(
                  (event) => DropdownMenuItem<String>(
                    value: event.eventId,
                    child: Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _linkedEventId = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _fieldLabel('Issue Date'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickIssueDate,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.appPalette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appPalette.stroke),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _issueDate == null
                            ? context.l10n.idEntryDateFormatHint
                            : DateFormat.yMMMd(
                                Localizations.localeOf(context).toLanguageTag(),
                              ).format(_issueDate!),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _issueDate == null
                              ? const Color(0xFF93A2BA)
                              : context.appPalette.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF7E90AB),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Attach File'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: const _WalletUploadDashedPainter(),
                child: Container(
                  width: double.infinity,
                  height: 136,
                  decoration: BoxDecoration(
                    color: context.appPalette.surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.appPalette.primarySoft,
                        ),
                        alignment: Alignment.center,
                        child: _isPicking
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.upload_file_rounded,
                                size: 22,
                                color: context.appPalette.primary,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _filePath.trim().isEmpty
                            ? context.l10n.travelWalletSelectFile
                            : _filePath.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A7E9E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'PDF, JPG or PNG',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8FA0BA),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel('Notes'),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              style: travelInputTextStyle(context),
              maxLines: 4,
              decoration: travelInputDecoration(
                context,
                hintText: context.l10n.travelHintBookingNotes,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF3D4F6A),
      ),
    );
  }

  Future<void> _pickIssueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _issueDate = picked;
    });
  }

  Future<void> _pickFile() async {
    if (_isPicking || _isSaving) {
      return;
    }
    setState(() {
      _isPicking = true;
    });
    try {
      final picked = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'travel-doc',
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
              'org.openxmlformats.wordprocessingml.document',
              'com.microsoft.word.doc',
              'org.openxmlformats.spreadsheetml.sheet',
              'org.openxmlformats.presentationml.presentation',
              'public.plain-text',
              'public.rtf',
              'public.comma-separated-values-text',
            ],
          ),
        ],
      );
      if (picked == null) {
        return;
      }
      final persistedPath = await _persistTravelAssetFile(
        sourcePath: picked.path.trim(),
      );
      if (persistedPath == null) {
        return;
      }
      setState(() {
        _filePath = persistedPath;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final filePath = _filePath.trim();
    if (title.isEmpty || filePath.isEmpty) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final issueDate = _issueDate == null
          ? ''
          : DateFormat('yyyy-MM-dd').format(_issueDate!);
      final fileName = filePath.split(Platform.pathSeparator).last;
      final fileMime = filePath.inferMimeType();
      final structuredFields = <Map<String, String>>[
        {'label': 'Trip ID', 'value': widget.tripId},
        {'label': 'Record Type', 'value': _travelRecordTypeWalletDocument},
        {'label': 'Document Type', 'value': _documentType},
        {'label': 'Document Title', 'value': title},
        {'label': 'Issue Date', 'value': issueDate},
        {'label': 'Linked Event ID', 'value': _linkedEventId ?? ''},
        {'label': 'File Name', 'value': fileName},
        {'label': 'File Path', 'value': filePath},
        {'label': 'File Mime', 'value': fileMime},
        {'label': 'Notes', 'value': _notesController.text.trim()},
        {
          'label': DocumentMetadataFieldLabels.travelTripId,
          'value': widget.tripId,
        },
        {
          'label': DocumentMetadataFieldLabels.travelRecordType,
          'value': _travelRecordTypeWalletDocument,
        },
        {
          'label': DocumentMetadataFieldLabels.travelDocumentType,
          'value': _documentType,
        },
        {
          'label': DocumentMetadataFieldLabels.travelLinkedEventId,
          'value': _linkedEventId ?? '',
        },
        {
          'label': DocumentMetadataFieldLabels.travelNotes,
          'value': _notesController.text.trim(),
        },
        {
          'label': DocumentMetadataFieldLabels.referenceAssetPath,
          'value': filePath,
        },
        {
          'label': DocumentMetadataFieldLabels.referenceAssetName,
          'value': fileName,
        },
        {
          'label': DocumentMetadataFieldLabels.frontImagePath,
          'value': filePath,
        },
        {
          'label': DocumentMetadataFieldLabels.previewImagePath,
          'value': filePath,
        },
      ].where((item) => (item['value'] ?? '').trim().isNotEmpty).toList();

      await _createUseCase(
        CreateScannedDocumentParams(
          type: DocumentType.other,
          source: DocumentCaptureSource.gallery,
          scanPagesCount: math.max(
            1,
            filePath.toLowerCase().endsWith('.pdf') ? 2 : 1,
          ),
          categoryOverride: DocumentCategoryType.travel,
          documentTypeKeyOverride: 'travel_$_travelRecordTypeWalletDocument',
          issuerOverride: title,
          identifierLabelOverride: 'Trip ID',
          identifierValueOverride: widget.tripId,
          tagsOverride: const ['Travel', 'Document'],
          structuredFieldsOverride: structuredFields,
        ),
      );
      if (!mounted) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<String?> _persistTravelAssetFile({required String sourcePath}) async {
    final normalized = sourcePath.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final originalName = normalized.split(RegExp(r'[\\/]')).last;
    return LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: normalized,
      directoryName: 'travel_trip_assets',
      fileNamePrefix: 'travel_wallet_${_fileNameStem(originalName)}',
    );
  }

  String _fileNameStem(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'file';
    final dot = trimmed.lastIndexOf('.');
    if (dot <= 0) return trimmed;
    return trimmed.substring(0, dot);
  }
}

const String _travelRecordTypeWalletDocument = 'wallet_document';

const List<String> _documentTypes = [
  'Passport Copy',
  'Visa',
  'Ticket',
  'Boarding Pass',
  'Hotel Booking',
  'Insurance',
  'Reservation Confirmation',
  'Other',
];

class _WalletUploadDashedPainter extends CustomPainter {
  const _WalletUploadDashedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7D7F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 8).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
