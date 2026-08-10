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
import 'package:pass_doc_manager/domain/documents/entities/travel_expense_category.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelExpenseEntryPage extends StatefulWidget {
  const TravelExpenseEntryPage({
    super.key,
    required this.tripId,
    required this.tripTitle,
    CreateScannedDocument? createDocument,
  }) : _createDocument = createDocument;

  final String tripId;
  final String tripTitle;
  final CreateScannedDocument? _createDocument;

  @override
  State<TravelExpenseEntryPage> createState() => _TravelExpenseEntryPageState();
}

class _TravelExpenseEntryPageState extends State<TravelExpenseEntryPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  TravelExpenseCategory _category = TravelExpenseCategory.foodDining;
  DateTime? _date;
  TimeOfDay? _time;
  String _currency = 'USD';
  String _receiptPath = '';
  bool _isSaving = false;
  bool _isPickingReceipt = false;

  CreateScannedDocument get _createUseCase => widget._createDocument ?? getIt();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave =
        !_isSaving &&
        _titleController.text.trim().isNotEmpty &&
        _amountController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.surface,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.travelExpensesAddExpenseTitle,
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
          child: FilledButton(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: const Color(0xFF1F57D4),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFF1F57D4,
              ).withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _isSaving
                  ? context.l10n.commonSaving
                  : context.l10n.travelExpensesAddExpenseAction,
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
            _fieldLabel('Expense Title'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: travelInputTextStyle(context),
              decoration: travelInputDecoration(
                context,
                hintText: context.l10n.travelHintExpenseTitle,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TravelExpenseCategory.values
                  .map((category) {
                    final active = _category == category;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _category = category;
                        });
                      },
                      child: Container(
                        width: 94,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: active
                              ? context.appPalette.primarySoft
                              : context.appPalette.surfaceSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: active
                                ? context.appPalette.primary
                                : context.appPalette.stroke,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _expenseCategoryIcon(category),
                              size: 20,
                              color: active
                                  ? context.appPalette.primary
                                  : context.appPalette.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _expenseCategoryLabel(context, category),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.8,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? context.appPalette.primary
                                    : context.appPalette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _amountInput(context)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 118,
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: travelInputDecoration(context, hintText: 'USD'),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Color(0xFF7E90AB),
                    ),
                    items: _currencies
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
                        _currency = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _fieldLabel('Location'),
            const SizedBox(height: 6),
            TextField(
              controller: _locationController,
              style: travelInputTextStyle(context),
              decoration: travelInputDecoration(
                context,
                hintText: context.l10n.travelHintSearchLocation,
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Color(0xFF8FA0BA),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dateField(
                    label: 'Date',
                    value: _date,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _timeField(
                    label: 'Time',
                    value: _time,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _fieldLabel('Attach Receipt'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickReceipt,
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: const _ExpenseUploadDashedPainter(),
                child: Container(
                  width: double.infinity,
                  height: 124,
                  decoration: BoxDecoration(
                    color: context.appPalette.surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.appPalette.primarySoft,
                        ),
                        alignment: Alignment.center,
                        child: _isPickingReceipt
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
                        _receiptPath.trim().isEmpty
                            ? 'Click to upload or drag and drop'
                            : _receiptPath.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A7E9E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'PNG, JPG or PDF (max. 5MB)',
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
                hintText: context.l10n.travelHintAdditionalDetails,
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

  Widget _amountInput(BuildContext context) {
    final symbol = _currencySymbol(_currency);
    return Container(
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          fontSize: 22 / 1.3,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: const TextStyle(
            fontSize: 22 / 1.3,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC4CFE1),
          ),
          prefixText: '$symbol ',
          prefixStyle: const TextStyle(
            fontSize: 22 / 1.3,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8FA0BA),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: context.appPalette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appPalette.stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? context.l10n.idEntryDateFormatHint
                        : DateFormat.yMd(
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

  Widget _timeField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: context.appPalette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appPalette.stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? '--:--' : value.format(context),
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
                  Icons.access_time_rounded,
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _date = picked;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _time = picked;
    });
  }

  Future<void> _pickReceipt() async {
    if (_isPickingReceipt || _isSaving) {
      return;
    }
    setState(() {
      _isPickingReceipt = true;
    });
    try {
      final picked = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'receipt',
            extensions: [
              'pdf',
              'png',
              'jpg',
              'jpeg',
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
              'public.png',
              'public.jpeg',
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
        _receiptPath = persistedPath;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingReceipt = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final amountRaw = _amountController.text.trim();
    final date = _date;
    if (title.isEmpty || amountRaw.isEmpty) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final amount = _parseAmount(amountRaw);
      final dateIso = date == null ? '' : DateFormat('yyyy-MM-dd').format(date);
      final timeLabel = _time == null
          ? ''
          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';
      final receiptMime = _receiptPath.trim().isEmpty
          ? ''
          : _receiptPath.inferMimeType();
      final structuredFields = <Map<String, String>>[
        {'label': 'Trip ID', 'value': widget.tripId},
        {'label': 'Record Type', 'value': _travelRecordTypeExpense},
        {'label': 'Expense Title', 'value': title},
        {'label': 'Expense Category', 'value': _category.key},
        {'label': 'Amount', 'value': amount.toStringAsFixed(2)},
        {'label': 'Currency', 'value': _currency},
        {'label': 'Location', 'value': _locationController.text.trim()},
        {'label': 'Expense Date', 'value': dateIso},
        {'label': 'Expense Time', 'value': timeLabel},
        {'label': 'Notes', 'value': _notesController.text.trim()},
        {
          'label': DocumentMetadataFieldLabels.travelTripId,
          'value': widget.tripId,
        },
        {
          'label': DocumentMetadataFieldLabels.travelRecordType,
          'value': _travelRecordTypeExpense,
        },
        {
          'label': DocumentMetadataFieldLabels.travelExpenseCategory,
          'value': _category.key,
        },
        {
          'label': DocumentMetadataFieldLabels.travelExpenseAmount,
          'value': amount.toStringAsFixed(2),
        },
        {
          'label': DocumentMetadataFieldLabels.travelExpenseCurrency,
          'value': _currency,
        },
        {
          'label': DocumentMetadataFieldLabels.travelExpenseDate,
          'value': dateIso,
        },
        {
          'label': DocumentMetadataFieldLabels.travelExpenseTime,
          'value': timeLabel,
        },
        {
          'label': DocumentMetadataFieldLabels.travelExpenseLocation,
          'value': _locationController.text.trim(),
        },
        {
          'label': DocumentMetadataFieldLabels.travelNotes,
          'value': _notesController.text.trim(),
        },
        if (_receiptPath.trim().isNotEmpty) ...[
          {
            'label': DocumentMetadataFieldLabels.referenceAssetPath,
            'value': _receiptPath.trim(),
          },
          {
            'label': DocumentMetadataFieldLabels.referenceAssetName,
            'value': _receiptPath.split(Platform.pathSeparator).last,
          },
          {
            'label': DocumentMetadataFieldLabels.frontImagePath,
            'value': _receiptPath.trim(),
          },
          {'label': 'Receipt Mime', 'value': receiptMime},
        ],
      ].where((item) => (item['value'] ?? '').trim().isNotEmpty).toList();

      await _createUseCase(
        CreateScannedDocumentParams(
          type: DocumentType.other,
          source: DocumentCaptureSource.gallery,
          scanPagesCount: math.max(1, _receiptPath.trim().isEmpty ? 1 : 2),
          categoryOverride: DocumentCategoryType.travel,
          documentTypeKeyOverride: 'travel_$_travelRecordTypeExpense',
          issuerOverride: title,
          identifierLabelOverride: 'Trip ID',
          identifierValueOverride: widget.tripId,
          tagsOverride: ['Travel', 'Expense', _category.key],
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
      fileNamePrefix: 'travel_receipt_${_fileNameStem(originalName)}',
    );
  }

  double _parseAmount(String raw) {
    final normalized = raw
        .trim()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  String _fileNameStem(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'file';
    final dot = trimmed.lastIndexOf('.');
    if (dot <= 0) return trimmed;
    return trimmed.substring(0, dot);
  }
}

const List<String> _currencies = ['USD', 'EUR', 'JPY', 'GBP'];
const String _travelRecordTypeExpense = 'expense';

String _currencySymbol(String currencyCode) {
  return switch (currencyCode) {
    'EUR' => '€',
    'JPY' => '¥',
    'GBP' => '£',
    _ => '\$',
  };
}

IconData _expenseCategoryIcon(TravelExpenseCategory category) {
  return switch (category) {
    TravelExpenseCategory.foodDining => Icons.restaurant_rounded,
    TravelExpenseCategory.transport => Icons.directions_car_filled_rounded,
    TravelExpenseCategory.activities => Icons.local_activity_rounded,
    TravelExpenseCategory.accommodation => Icons.hotel_rounded,
    TravelExpenseCategory.shopping => Icons.shopping_bag_rounded,
    TravelExpenseCategory.other => Icons.more_horiz_rounded,
  };
}

String _expenseCategoryLabel(
  BuildContext context,
  TravelExpenseCategory category,
) {
  return switch (category) {
    TravelExpenseCategory.foodDining => context.l10n.travelExpensesCategoryFood,
    TravelExpenseCategory.transport =>
      context.l10n.travelExpensesCategoryTransport,
    TravelExpenseCategory.activities =>
      context.l10n.travelExpensesCategoryActivities,
    TravelExpenseCategory.accommodation =>
      context.l10n.travelExpensesCategoryAccommodation,
    TravelExpenseCategory.shopping =>
      context.l10n.travelExpensesCategoryShopping,
    TravelExpenseCategory.other => context.l10n.travelExpensesCategoryOther,
  };
}

class _ExpenseUploadDashedPainter extends CustomPainter {
  const _ExpenseUploadDashedPainter();

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
