import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_structured_field_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_detail.dart';
import 'package:pass_doc_manager/domain/documents/usecases/update_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelTripNotesPage extends StatefulWidget {
  const TravelTripNotesPage({
    super.key,
    required this.documentId,
    required this.fallbackTripTitle,
    GetDocumentDetail? getDocumentDetail,
    UpdateDocument? updateDocument,
  }) : _getDocumentDetail = getDocumentDetail,
       _updateDocument = updateDocument;

  final String documentId;
  final String fallbackTripTitle;
  final GetDocumentDetail? _getDocumentDetail;
  final UpdateDocument? _updateDocument;

  @override
  State<TravelTripNotesPage> createState() => _TravelTripNotesPageState();
}

class _TravelTripNotesPageState extends State<TravelTripNotesPage> {
  final TextEditingController _notesController = TextEditingController();
  DocumentDetailEntity? _detail;
  bool _isLoading = true;
  bool _isSaving = false;

  GetDocumentDetail get _getDetailUseCase =>
      widget._getDocumentDetail ?? getIt();
  UpdateDocument get _updateUseCase => widget._updateDocument ?? getIt();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: GenericAppBar(
        backgroundColor: palette.surface,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.travelTripNotesTitle,
        titleStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border(top: BorderSide(color: palette.stroke)),
          ),
          child: FilledButton(
            onPressed: _isLoading || _isSaving || _detail == null
                ? null
                : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: palette.primary.withValues(alpha: 0.42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _isSaving ? context.l10n.commonSaving : context.l10n.commonSave,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  TravelSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detailTitle(),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.travelHintNotes,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _notesController,
                          style: travelInputTextStyle(context),
                          minLines: 10,
                          maxLines: 18,
                          textInputAction: TextInputAction.newline,
                          decoration: travelInputDecoration(
                            context,
                            hintText: context.l10n.travelHintAdditionalDetails,
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
      _detail = detail;
      _notesController.text = _extractNotes(detail);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.travelTripDetailLoadError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await _updateUseCase(
        UpdateDocumentParams(
          documentId: detail.id,
          type: detail.type,
          source: detail.captureSource,
          scanPagesCount: detail.scanPagesCount > 0 ? detail.scanPagesCount : 1,
          categoryOverride: DocumentCategoryType.travel,
          documentTypeKeyOverride: 'travel_trip_profile',
          structuredFieldsOverride: _structuredFieldsWithNotes(
            detail.structuredFields,
            _notesController.text.trim(),
          ),
        ),
      );
      if (!mounted) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<Map<String, String>> _structuredFieldsWithNotes(
    List<DocumentStructuredFieldEntity> fields,
    String notes,
  ) {
    final updated = fields
        .where((field) => !_isNotesLabel(field.label))
        .map(
          (field) => <String, String>{
            'label': field.label,
            'value': field.value,
          },
        )
        .toList(growable: true);

    if (notes.isNotEmpty) {
      updated.add(<String, String>{'label': 'Trip Notes', 'value': notes});
      updated.add(<String, String>{
        'label': DocumentMetadataFieldLabels.travelNotes,
        'value': notes,
      });
    }

    return updated;
  }

  bool _isNotesLabel(String label) {
    final normalized = label.trim().toLowerCase();
    final canonical =
        DocumentMetadataFieldLabels.toCanonicalClaimKey(label) ?? normalized;
    return canonical == DocumentMetadataFieldLabels.travelNotes ||
        normalized == 'trip notes' ||
        normalized == 'notes';
  }

  String _extractNotes(DocumentDetailEntity detail) {
    for (final field in detail.structuredFields) {
      if (_isNotesLabel(field.label)) {
        final value = field.value.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }

  String _detailTitle() {
    final detail = _detail;
    if (detail == null) {
      return widget.fallbackTripTitle;
    }
    for (final field in detail.structuredFields) {
      final canonical = DocumentMetadataFieldLabels.toCanonicalClaimKey(
        field.label,
      );
      if (canonical == DocumentMetadataFieldLabels.travelTripTitle &&
          field.value.trim().isNotEmpty) {
        return field.value.trim();
      }
    }
    return widget.fallbackTripTitle;
  }
}
