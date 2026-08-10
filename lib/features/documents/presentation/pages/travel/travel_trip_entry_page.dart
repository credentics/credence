import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelTripEntryPage extends StatefulWidget {
  const TravelTripEntryPage({
    super.key,
    this.editDocumentId,
    this.tripId,
    CreateScannedDocument? createDocument,
    GetDocumentDetail? getDocumentDetail,
    UpdateDocument? updateDocument,
  }) : _createDocument = createDocument,
       _getDocumentDetail = getDocumentDetail,
       _updateDocument = updateDocument;

  final String? editDocumentId;
  final String? tripId;
  final CreateScannedDocument? _createDocument;
  final GetDocumentDetail? _getDocumentDetail;
  final UpdateDocument? _updateDocument;

  @override
  State<TravelTripEntryPage> createState() => _TravelTripEntryPageState();
}

class _TravelTripEntryPageState extends State<TravelTripEntryPage> {
  static const _maxUploadBytes = 10 * 1024 * 1024;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _coverPath = '';
  bool _isSaving = false;
  bool _isPickingCover = false;
  bool _isBootstrapping = false;
  DocumentDetailEntity? _editingDetail;
  final ImagePicker _imagePicker = ImagePicker();

  CreateScannedDocument get _createUseCase => widget._createDocument ?? getIt();
  GetDocumentDetail get _getDetailUseCase =>
      widget._getDocumentDetail ?? getIt();
  UpdateDocument get _updateUseCase => widget._updateDocument ?? getIt();
  bool get _isEditMode => (widget.editDocumentId ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _bootstrapFromExistingDocument();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        !_isSaving &&
        !_isBootstrapping &&
        _titleController.text.trim().isNotEmpty &&
        _destinationController.text.trim().isNotEmpty &&
        _startDate != null &&
        _endDate != null;

    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.surface,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: _isEditMode
            ? context.l10n.travelTripEditTitle
            : context.l10n.travelTripEntryTitle,
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
            border: Border(top: BorderSide(color: Color(0xFFE2E8F2))),
          ),
          child: FilledButton(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: context.appPalette.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.appPalette.primary.withValues(
                alpha: 0.44,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _isSaving
                  ? context.l10n.commonSaving
                  : (_isEditMode
                        ? context.l10n.commonSave
                        : context.l10n.travelTripEntrySaveAction),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isBootstrapping
            ? const Center(child: CircularProgressIndicator.adaptive())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  TravelSectionLabel(
                    value: context.l10n.travelTripDetailsSectionTitle,
                  ),
                  const SizedBox(height: 10),
                  TravelSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(
                          context,
                          context.l10n.travelTripEntryTitleField,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _titleController,
                          style: travelInputTextStyle(context),
                          textInputAction: TextInputAction.next,
                          decoration: travelInputDecoration(
                            context,
                            hintText: context.l10n.travelTripEntryTitleHint,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _fieldLabel(
                          context,
                          context.l10n.travelTripEntryDestinationField,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _destinationController,
                          style: travelInputTextStyle(context),
                          textInputAction: TextInputAction.next,
                          decoration: travelInputDecoration(
                            context,
                            hintText:
                                context.l10n.travelTripEntryDestinationHint,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dateField(
                                context,
                                label:
                                    context.l10n.travelTripEntryStartDateField,
                                value: _startDate,
                                onTap: () => _pickDate(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _dateField(
                                context,
                                label: context.l10n.travelTripEntryEndDateField,
                                value: _endDate,
                                onTap: () => _pickDate(isStart: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _fieldLabel(
                          context,
                          context.l10n.travelTripEntryCoverField,
                        ),
                        const SizedBox(height: 7),
                        InkWell(
                          onTap: _isSaving ? null : _pickCover,
                          borderRadius: BorderRadius.circular(18),
                          child: CustomPaint(
                            painter: const _TripDashedPainter(),
                            child: Container(
                              width: double.infinity,
                              height: 68,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFE5EEFF),
                                    ),
                                    alignment: Alignment.center,
                                    child: _isPickingCover
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            Icons.photo_library_rounded,
                                            size: 18,
                                            color: context.appPalette.primary,
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _coverPath.trim().isEmpty
                                          ? context
                                                .l10n
                                                .travelTripEntryCoverHint
                                          : _displayFileName(_coverPath),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: _coverPath.trim().isEmpty
                                            ? const Color(0xFF93A2BA)
                                            : context.appPalette.textPrimary,
                                      ),
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
                ],
              ),
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 14.2,
        fontWeight: FontWeight.w700,
        color: Color(0xFF394B67),
      ),
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: context.appPalette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD7E0EE)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? context.l10n.idEntryDateFormatHint
                        : DateFormat.yMMMd(
                            Localizations.localeOf(context).toLanguageTag(),
                          ).format(value),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: value == null
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
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickCover() async {
    if (_isPickingCover || _isSaving) {
      return;
    }
    setState(() {
      _isPickingCover = true;
    });
    try {
      final pickedPath = await _pickCoverSourcePath();
      if ((pickedPath ?? '').trim().isEmpty) {
        return;
      }
      final sourceFile = File(pickedPath!.trim());
      if (!await sourceFile.exists()) {
        return;
      }
      final size = await sourceFile.length();
      if (size > _maxUploadBytes) {
        return;
      }
      final persisted = await LocalAssetFileStore.copyIntoAppSupport(
        sourcePath: pickedPath,
        directoryName: 'travel_trip_assets',
        fileNamePrefix: 'trip_cover',
      );
      if (persisted == null) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _coverPath = persisted;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingCover = false;
        });
      }
    }
  }

  Future<String?> _pickCoverSourcePath() async {
    if (Platform.isIOS || Platform.isAndroid) {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 3200,
        maxHeight: 3200,
      );
      return image?.path;
    }
    final picked = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Images',
          extensions: ['jpg', 'jpeg', 'png', 'heic', 'webp'],
          uniformTypeIdentifiers: [
            'public.jpeg',
            'public.png',
            'public.heic',
            'org.webmproject.webp',
            'public.image',
          ],
        ),
      ],
    );
    return picked?.path;
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final destination = _destinationController.text.trim();
    final notes = _notesController.text.trim();
    final start = _startDate;
    final end = _endDate;
    if (title.isEmpty || destination.isEmpty || start == null || end == null) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final tripId = _resolvedTripIdForSave(title);
      final structuredFields = [
        {'label': 'Trip Title', 'value': title},
        {'label': 'Destination', 'value': destination},
        {
          'label': 'Start Date',
          'value': DateFormat('yyyy-MM-dd').format(start),
        },
        {'label': 'End Date', 'value': DateFormat('yyyy-MM-dd').format(end)},
        {'label': 'Trip ID', 'value': tripId},
        {'label': 'Record Type', 'value': _travelRecordTypeTripProfile},
        {'label': 'Cover Image Path', 'value': _coverPath},
        {'label': 'Trip Notes', 'value': notes},
        {'label': DocumentMetadataFieldLabels.travelTripId, 'value': tripId},
        {'label': DocumentMetadataFieldLabels.travelTripTitle, 'value': title},
        {
          'label': DocumentMetadataFieldLabels.travelDestination,
          'value': destination,
        },
        {
          'label': DocumentMetadataFieldLabels.travelStartDate,
          'value': DateFormat('yyyy-MM-dd').format(start),
        },
        {
          'label': DocumentMetadataFieldLabels.travelEndDate,
          'value': DateFormat('yyyy-MM-dd').format(end),
        },
        {
          'label': DocumentMetadataFieldLabels.travelRecordType,
          'value': _travelRecordTypeTripProfile,
        },
        {
          'label': DocumentMetadataFieldLabels.travelCoverImagePath,
          'value': _coverPath,
        },
        {'label': DocumentMetadataFieldLabels.travelNotes, 'value': notes},
      ];
      final tags = <String>{
        'Travel',
        'Trip',
        ...(_editingDetail?.tags ?? const <String>[]),
      }.toList(growable: false);

      if (_isEditMode && _editingDetail != null) {
        await _updateUseCase(
          UpdateDocumentParams(
            documentId: _editingDetail!.id,
            type: _editingDetail!.type,
            source: _editingDetail!.captureSource,
            scanPagesCount: _editingDetail!.scanPagesCount > 0
                ? _editingDetail!.scanPagesCount
                : 1,
            categoryOverride: DocumentCategoryType.travel,
            documentTypeKeyOverride: 'travel_$_travelRecordTypeTripProfile',
            issuerOverride: title,
            identifierLabelOverride: 'Trip ID',
            identifierValueOverride: tripId,
            tagsOverride: tags,
            structuredFieldsOverride: structuredFields,
          ),
        );
      } else {
        await _createUseCase(
          CreateScannedDocumentParams(
            type: DocumentType.other,
            source: DocumentCaptureSource.gallery,
            scanPagesCount: 1,
            categoryOverride: DocumentCategoryType.travel,
            documentTypeKeyOverride: 'travel_$_travelRecordTypeTripProfile',
            issuerOverride: title,
            identifierLabelOverride: 'Trip ID',
            identifierValueOverride: tripId,
            tagsOverride: tags,
            structuredFieldsOverride: structuredFields,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(tripId);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _bootstrapFromExistingDocument() async {
    final documentId = (widget.editDocumentId ?? '').trim();
    if (documentId.isEmpty) {
      return;
    }
    setState(() {
      _isBootstrapping = true;
    });
    try {
      final detail = await _getDetailUseCase(
        GetDocumentDetailParams(documentId: documentId),
      );
      if (!mounted) {
        return;
      }
      _editingDetail = detail;
      setState(() {
        _titleController.text = _firstMatch(detail, const [
          DocumentMetadataFieldLabels.travelTripTitle,
          'Trip Title',
          'title',
        ]);
        _destinationController.text = _firstMatch(detail, const [
          DocumentMetadataFieldLabels.travelDestination,
          'Destination',
        ]);
        _startDate = _parseFlexibleDate(
          _firstMatch(detail, const [
            DocumentMetadataFieldLabels.travelStartDate,
            'Start Date',
          ]),
        );
        _endDate = _parseFlexibleDate(
          _firstMatch(detail, const [
            DocumentMetadataFieldLabels.travelEndDate,
            'End Date',
          ]),
        );
        _coverPath = _firstMatch(detail, const [
          DocumentMetadataFieldLabels.travelCoverImagePath,
          'Cover Image Path',
        ]);
        _notesController.text = _firstMatch(detail, const [
          DocumentMetadataFieldLabels.travelNotes,
          'Trip Notes',
          'Notes',
        ]);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.travelTripDetailLoadError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrapping = false;
        });
      }
    }
  }

  String _resolvedTripIdForSave(String title) {
    final fromWidget = (widget.tripId ?? '').trim();
    if (fromWidget.isNotEmpty) {
      return fromWidget;
    }
    if (_editingDetail != null) {
      final fromDetail = _firstMatch(_editingDetail!, const [
        DocumentMetadataFieldLabels.travelTripId,
        'Trip ID',
      ]);
      if (fromDetail.trim().isNotEmpty) {
        return fromDetail.trim();
      }
    }
    return _slugify('${title}_${DateTime.now().millisecondsSinceEpoch}');
  }

  String _firstMatch(DocumentDetailEntity detail, List<String> labels) {
    for (final target in labels) {
      final normalizedTarget = target.trim().toLowerCase();
      final canonicalTarget =
          DocumentMetadataFieldLabels.toCanonicalClaimKey(target) ??
          normalizedTarget;
      for (final field in detail.structuredFields) {
        final label = field.label.trim();
        final canonicalLabel = DocumentMetadataFieldLabels.toCanonicalClaimKey(
          label,
        );
        final normalizedLabel = label.toLowerCase();
        if (normalizedLabel == normalizedTarget ||
            canonicalLabel == normalizedTarget ||
            canonicalLabel == canonicalTarget) {
          final value = field.value.trim();
          if (value.isNotEmpty) {
            return value;
          }
        }
      }
    }
    return '';
  }

  DateTime? _parseFlexibleDate(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) {
      return null;
    }
    final direct = DateTime.tryParse(raw);
    if (direct != null) {
      return DateTime(direct.year, direct.month, direct.day);
    }
    try {
      final strict = DateFormat('yyyy-MM-dd').parseStrict(raw);
      return DateTime(strict.year, strict.month, strict.day);
    } catch (_) {
      return null;
    }
  }

  String _displayFileName(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final normalized = trimmed.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? trimmed : parts.last;
  }

  String _slugify(String raw) {
    final normalized = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'trip' : normalized;
  }
}

const String _travelRecordTypeTripProfile = 'trip_profile';

class _TripDashedPainter extends CustomPainter {
  const _TripDashedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7D7F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
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
