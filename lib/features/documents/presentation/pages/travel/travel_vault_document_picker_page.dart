import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/vault_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_vault_documents.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/travel/travel_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TravelVaultDocumentPickerPage extends StatefulWidget {
  const TravelVaultDocumentPickerPage({
    super.key,
    GetVaultDocuments? getVaultDocuments,
  }) : _getVaultDocuments = getVaultDocuments;

  final GetVaultDocuments? _getVaultDocuments;

  @override
  State<TravelVaultDocumentPickerPage> createState() =>
      _TravelVaultDocumentPickerPageState();
}

class _TravelVaultDocumentPickerPageState
    extends State<TravelVaultDocumentPickerPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String _query = '';
  _VaultPickerFilter _selectedFilter = _VaultPickerFilter.all;
  List<VaultDocumentEntity> _items = const <VaultDocumentEntity>[];

  GetVaultDocuments get _getVaultDocuments =>
      widget._getVaultDocuments ?? getIt();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: travelBackgroundColor,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.surface,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.travelWalletChooseFromMyDocumentsOption,
        titleStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 12));
    }
    if ((_errorMessage ?? '').trim().isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: context.appPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: Text(context.l10n.commonRetry)),
          ],
        ),
      );
    }

    final visibleItems = _visibleItems;
    final groupedItems = _groupItemsByCategory(visibleItems);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      children: [
        TextField(
          onChanged: (value) {
            setState(() {
              _query = value.trim();
            });
          },
          decoration: travelInputDecoration(context, 
            hintText: context.l10n.homeSearchVaultDocuments,
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: context.appPalette.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _filtersBar(context),
        const SizedBox(height: 12),
        if (visibleItems.isEmpty)
          TravelSurfaceCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    context.l10n.travelWalletPickerEmptyTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    context.l10n.travelWalletPickerEmptySubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...groupedItems.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 7),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textMuted,
                      ),
                    ),
                  ),
                  ...entry.value.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _documentTile(context, item),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _filtersBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _activeFilters
            .map((filter) {
              final active = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7.5,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? context.appPalette.primary
                          : context.appPalette.surfaceSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: active
                            ? context.appPalette.primary
                            : context.appPalette.stroke,
                      ),
                    ),
                    child: Text(
                      _labelForFilter(context, filter),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : context.appPalette.textSecondary,
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

  Widget _documentTile(BuildContext context, VaultDocumentEntity item) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final expiryText = item.expiryDate == null
        ? context.l10n.travelWalletNoExpirationDate
        : DateFormat.yMMMd(localeTag).format(item.expiryDate!);
    return InkWell(
      onTap: () => Navigator.of(context).pop(item),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _iconBackground(item),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(_iconFor(item), size: 24, color: _iconColor(item)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.documentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    item.documentTypeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 15,
                        color: context.appPalette.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${context.l10n.idEntryExpiryDate}: $expiryText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w500,
                            color: context.appPalette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: context.appPalette.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await _getVaultDocuments(const GetVaultDocumentsParams());
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = context.l10n.identityUnableLoadSecureIds;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<VaultDocumentEntity> get _visibleItems {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _items.where(_matchesFilter).toList(growable: false);
    }
    return _items
        .where((item) {
          return _matchesFilter(item) &&
              (item.documentName.toLowerCase().contains(query) ||
                  item.documentTypeLabel.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  List<_VaultPickerFilter> get _activeFilters {
    final filters = <_VaultPickerFilter>[
      _VaultPickerFilter.all,
      _VaultPickerFilter.priority,
      _VaultPickerFilter.identity,
    ];
    if (_items.any((item) => item.category == DocumentCategoryType.travel)) {
      filters.add(_VaultPickerFilter.travel);
    }
    if (_items.any((item) => item.category == DocumentCategoryType.work)) {
      filters.add(_VaultPickerFilter.work);
    }
    if (_items.any((item) => item.category == DocumentCategoryType.property)) {
      filters.add(_VaultPickerFilter.property);
    }
    if (_items.any(
      (item) =>
          item.category == DocumentCategoryType.other ||
          item.category == DocumentCategoryType.health ||
          item.category == DocumentCategoryType.vehicle,
    )) {
      filters.add(_VaultPickerFilter.other);
    }
    return filters;
  }

  bool _matchesFilter(VaultDocumentEntity item) {
    return switch (_selectedFilter) {
      _VaultPickerFilter.all => true,
      _VaultPickerFilter.priority => _isPriorityType(item),
      _VaultPickerFilter.identity =>
        item.category == DocumentCategoryType.identity,
      _VaultPickerFilter.travel => item.category == DocumentCategoryType.travel,
      _VaultPickerFilter.work => item.category == DocumentCategoryType.work,
      _VaultPickerFilter.property =>
        item.category == DocumentCategoryType.property,
      _VaultPickerFilter.other =>
        item.category == DocumentCategoryType.other ||
            item.category == DocumentCategoryType.health ||
            item.category == DocumentCategoryType.vehicle,
    };
  }

  bool _isPriorityType(VaultDocumentEntity item) {
    final value = '${item.documentTypeLabel} ${item.documentName}'
        .toLowerCase();
    return value.contains('passport') ||
        value.contains('national id') ||
        value.contains('id card') ||
        value.contains('residence permit') ||
        value.contains('driver') ||
        value.contains('visa') ||
        value.contains('travel insurance');
  }

  Map<String, List<VaultDocumentEntity>> _groupItemsByCategory(
    List<VaultDocumentEntity> items,
  ) {
    final grouped = <String, List<VaultDocumentEntity>>{};
    for (final item in items) {
      final key = _sectionTitleFor(item);
      grouped.putIfAbsent(key, () => <VaultDocumentEntity>[]).add(item);
    }
    final entries = grouped.entries.toList(growable: false)
      ..sort(
        (a, b) => _sectionPriority(a.key).compareTo(_sectionPriority(b.key)),
      );
    return <String, List<VaultDocumentEntity>>{
      for (final entry in entries) entry.key: entry.value,
    };
  }

  String _sectionTitleFor(VaultDocumentEntity item) {
    final type = item.documentTypeLabel.toLowerCase();
    if (type.contains('passport')) {
      return 'Passports';
    }
    if (type.contains('national id') ||
        type.contains('id card') ||
        type.contains('residence permit')) {
      return 'ID Cards';
    }
    if (type.contains('driver')) {
      return "Driver's Licenses";
    }
    if (type.contains('visa')) {
      return 'Visas';
    }
    if (type.contains('travel insurance') ||
        (type.contains('insurance') && type.contains('travel'))) {
      return 'Travel Insurance';
    }
    return item.category.label;
  }

  int _sectionPriority(String title) {
    return switch (title) {
      'Passports' => 0,
      'ID Cards' => 1,
      "Driver's Licenses" => 2,
      'Visas' => 3,
      'Travel Insurance' => 4,
      'Identity' => 5,
      'Travel' => 6,
      'Work' => 7,
      'Property' => 8,
      _ => 20,
    };
  }

  String _labelForFilter(BuildContext context, _VaultPickerFilter filter) {
    return switch (filter) {
      _VaultPickerFilter.all => context.l10n.propertyHubFilterAll,
      _VaultPickerFilter.priority => 'Priority',
      _VaultPickerFilter.identity => 'Identity',
      _VaultPickerFilter.travel => 'Travel',
      _VaultPickerFilter.work => 'Work',
      _VaultPickerFilter.property => 'Property',
      _VaultPickerFilter.other => 'Other',
    };
  }

  IconData _iconFor(VaultDocumentEntity item) {
    final type = item.documentTypeLabel.toLowerCase();
    if (type.contains('passport')) {
      return Icons.public_rounded;
    }
    if (type.contains('visa')) {
      return Icons.flight_takeoff_rounded;
    }
    if (type.contains('driver')) {
      return Icons.directions_car_rounded;
    }
    if (type.contains('id')) {
      return Icons.badge_rounded;
    }
    if (type.contains('insurance')) {
      return Icons.health_and_safety_rounded;
    }
    return switch (item.category) {
      DocumentCategoryType.work => Icons.business_center_rounded,
      DocumentCategoryType.property => Icons.home_work_rounded,
      DocumentCategoryType.travel => Icons.luggage_rounded,
      _ => Icons.description_rounded,
    };
  }

  Color _iconBackground(VaultDocumentEntity item) {
    return switch (item.category) {
      DocumentCategoryType.identity => const Color(0xFFEAF0FF),
      DocumentCategoryType.work => const Color(0xFFE8F5EE),
      DocumentCategoryType.property => const Color(0xFFF9F2E2),
      DocumentCategoryType.travel => const Color(0xFFE9F6F8),
      _ => const Color(0xFFF0F2F8),
    };
  }

  Color _iconColor(VaultDocumentEntity item) {
    return switch (item.category) {
      DocumentCategoryType.work => const Color(0xFF1A9D66),
      DocumentCategoryType.property => const Color(0xFFC17A00),
      DocumentCategoryType.travel => const Color(0xFF0E7A8D),
      _ => context.appPalette.primary,
    };
  }
}

enum _VaultPickerFilter {
  all,
  priority,
  identity,
  travel,
  work,
  property,
  other,
}
