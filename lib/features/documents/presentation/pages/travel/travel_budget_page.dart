import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_budget_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_expense_category.dart';
import 'package:pass_doc_manager/domain/documents/usecases/create_scanned_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelBudgetPage extends StatefulWidget {
  const TravelBudgetPage({
    super.key,
    required this.tripId,
    required this.tripTitle,
    this.initialBudget,
    CreateScannedDocument? createDocument,
  }) : _createDocument = createDocument;

  final String tripId;
  final String tripTitle;
  final TravelBudgetEntity? initialBudget;
  final CreateScannedDocument? _createDocument;

  @override
  State<TravelBudgetPage> createState() => _TravelBudgetPageState();
}

class _TravelBudgetPageState extends State<TravelBudgetPage> {
  static const _editableCategories = <TravelExpenseCategory>[
    TravelExpenseCategory.transport,
    TravelExpenseCategory.accommodation,
    TravelExpenseCategory.foodDining,
    TravelExpenseCategory.activities,
    TravelExpenseCategory.shopping,
  ];

  final TextEditingController _totalBudgetController = TextEditingController();
  String _currencyCode = 'USD';
  bool _isSaving = false;

  late final Map<TravelExpenseCategory, double> _allocations;

  CreateScannedDocument get _createUseCase => widget._createDocument ?? getIt();

  @override
  void initState() {
    super.initState();
    _allocations = {for (final category in _editableCategories) category: 0};
    final seed = widget.initialBudget;
    if (seed != null) {
      _totalBudgetController.text = seed.totalBudget.toStringAsFixed(0);
      _currencyCode = seed.currencyCode.trim().isEmpty
          ? 'USD'
          : seed.currencyCode;
      for (final item in seed.allocations) {
        if (_allocations.containsKey(item.category)) {
          _allocations[item.category] = item.amount;
        }
      }
    } else {
      _totalBudgetController.text = '2000';
      _allocations[TravelExpenseCategory.transport] = 800;
      _allocations[TravelExpenseCategory.accommodation] = 700;
      _allocations[TravelExpenseCategory.foodDining] = 250;
      _allocations[TravelExpenseCategory.activities] = 150;
      _allocations[TravelExpenseCategory.shopping] = 100;
    }
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = _totalBudget;
    final allocated = _allocatedAmount;
    final remaining = (totalBudget - allocated)
        .clamp(0.0, double.infinity)
        .toDouble();
    final progress = totalBudget <= 0
        ? 0.0
        : (allocated / totalBudget).clamp(0.0, 1.0).toDouble();
    final palette = context.appPalette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: GenericAppBar(
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.travelBudgetTitle,
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
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: const Color(0xFF1F57D4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              _isSaving
                  ? context.l10n.commonSaving
                  : context.l10n.travelBudgetSaveAction,
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
            TravelSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Total Budget Amount'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _totalBudgetController,
                    style: travelInputTextStyle(context),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: travelInputDecoration(
                      context,
                      hintText: '5000',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, top: 12),
                        child: Text(
                          _currencySymbol(_currencyCode),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.appPalette.textMuted,
                          ),
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  _fieldLabel('Currency'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _currencyCode,
                    decoration: travelInputDecoration(context, hintText: 'USD'),
                    icon: Icon(
                      Icons.swap_vert_rounded,
                      size: 18,
                      color: context.appPalette.textMuted,
                    ),
                    items: _currencies
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              '$item - ${_currencyName(item)}',
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
                        _currencyCode = value;
                      });
                    },
                  ),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        context.l10n.travelBudgetAllocated(
                          _formatMoney(allocated, _currencyCode),
                        ),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: context.appPalette.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        context.l10n.travelBudgetRemaining(
                          _formatMoney(remaining, _currencyCode),
                        ),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: context.appPalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: progress,
                      backgroundColor: palette.stroke,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1F57D4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Text(
                  context.l10n.travelBudgetBreakdownTitle,
                  style: TextStyle(
                    fontSize: 35 / 2.15,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._editableCategories.map((category) {
              final allocatedAmount = _allocations[category] ?? 0;
              final ratio = totalBudget <= 0
                  ? 0.0
                  : (allocatedAmount / totalBudget).clamp(0.0, 1.0).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TravelSurfaceCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _categorySoftColor(category),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _expenseCategoryIcon(category),
                              size: 18,
                              color: _categoryColor(category),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _expenseCategoryLabel(context, category),
                              style: TextStyle(
                                fontSize: 17 / 1.2,
                                fontWeight: FontWeight.w700,
                                color: context.appPalette.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _formatMoney(allocatedAmount, _currencyCode),
                            style: TextStyle(
                              fontSize: 18 / 1.2,
                              fontWeight: FontWeight.w700,
                              color: context.appPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: const Color(0xFF1F57D4),
                          inactiveTrackColor: context.appPalette.stroke,
                          thumbColor: const Color(0xFF1F57D4),
                          overlayColor: const Color(0x221F57D4),
                        ),
                        child: Slider(
                          value: ratio,
                          onChanged: (value) {
                            setState(() {
                              _allocations[category] = (value * totalBudget);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: context.appPalette.textSecondary,
      ),
    );
  }

  double get _totalBudget {
    final normalized = _totalBudgetController.text
        .trim()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  double get _allocatedAmount {
    return _allocations.values.fold<double>(0, (sum, value) => sum + value);
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final total = _totalBudget;
      final allocations = _editableCategories
          .map(
            (category) => {
              'category': category.key,
              'amount': (_allocations[category] ?? 0).toStringAsFixed(2),
            },
          )
          .toList(growable: false);
      final structuredFields = <Map<String, String>>[
        {'label': 'Trip ID', 'value': widget.tripId},
        {'label': 'Record Type', 'value': _travelRecordTypeBudget},
        {'label': 'Budget Total', 'value': total.toStringAsFixed(2)},
        {'label': 'Currency', 'value': _currencyCode},
        {'label': 'Budget Allocations', 'value': jsonEncode(allocations)},
        {
          'label': DocumentMetadataFieldLabels.travelTripId,
          'value': widget.tripId,
        },
        {
          'label': DocumentMetadataFieldLabels.travelRecordType,
          'value': _travelRecordTypeBudget,
        },
        {
          'label': DocumentMetadataFieldLabels.travelBudgetTotal,
          'value': total.toStringAsFixed(2),
        },
        {
          'label': DocumentMetadataFieldLabels.travelBudgetCurrency,
          'value': _currencyCode,
        },
        {
          'label': DocumentMetadataFieldLabels.travelBudgetAllocationsJson,
          'value': jsonEncode(allocations),
        },
      ];
      await _createUseCase(
        CreateScannedDocumentParams(
          type: DocumentType.other,
          source: DocumentCaptureSource.gallery,
          scanPagesCount: math.max(1, allocations.length),
          categoryOverride: DocumentCategoryType.travel,
          documentTypeKeyOverride: 'travel_$_travelRecordTypeBudget',
          issuerOverride: '${widget.tripTitle} Budget',
          identifierLabelOverride: 'Trip ID',
          identifierValueOverride: widget.tripId,
          tagsOverride: const ['Travel', 'Budget'],
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

  String _formatMoney(double value, String currencyCode) {
    final symbol = _currencySymbol(currencyCode);
    return '$symbol${value.toStringAsFixed(0)}';
  }
}

const String _travelRecordTypeBudget = 'budget';
const List<String> _currencies = ['USD', 'EUR', 'JPY', 'GBP'];

String _currencyName(String code) {
  return switch (code) {
    'EUR' => 'Euro',
    'JPY' => 'Japanese Yen',
    'GBP' => 'British Pound',
    _ => 'US Dollar',
  };
}

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

Color _categorySoftColor(TravelExpenseCategory category) {
  return switch (category) {
    TravelExpenseCategory.transport => const Color(0xFFEAF0FD),
    TravelExpenseCategory.accommodation => const Color(0xFFF2E9FD),
    TravelExpenseCategory.foodDining => const Color(0xFFFDEFD9),
    TravelExpenseCategory.activities => const Color(0xFFE8F8EE),
    TravelExpenseCategory.shopping => const Color(0xFFFDEAF2),
    TravelExpenseCategory.other => const Color(0xFFF0F3F8),
  };
}

Color _categoryColor(TravelExpenseCategory category) {
  return switch (category) {
    TravelExpenseCategory.transport => const Color(0xFF1F57D4),
    TravelExpenseCategory.accommodation => const Color(0xFF8A3FFC),
    TravelExpenseCategory.foodDining => const Color(0xFFEF7D1A),
    TravelExpenseCategory.activities => const Color(0xFF10A26C),
    TravelExpenseCategory.shopping => const Color(0xFFE91E63),
    TravelExpenseCategory.other => const Color(0xFF64748B),
  };
}
