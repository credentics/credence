import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_template_type.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

TextStyle _collectionDisplayStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color color = const Color(0xFF1D1A16),
  double? height,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: 'Manrope',
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle _collectionBodyStyle({
  required double fontSize,
  required FontWeight fontWeight,
  Color color = const Color(0xFF1D1A16),
  double? height,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: 'Manrope',
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle _collectionMonoStyle({
  required double size,
  required FontWeight weight,
  Color color = const Color(0xFF8A837B),
  double? height,
  double letterSpacing = 1.2,
}) {
  return TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class CollectionsCreateStep2Page extends StatefulWidget {
  const CollectionsCreateStep2Page({super.key});

  @override
  State<CollectionsCreateStep2Page> createState() =>
      _CollectionsCreateStep2PageState();
}

class _CollectionsCreateStep2PageState
    extends State<CollectionsCreateStep2Page> {
  CollectionTemplateType _selected = CollectionTemplateType.propertyManagement;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 720 ? 4 : 2;
    final entries = _filteredEntries(context);
    final searching = _searchQuery.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFFEFCF8),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            _sheetHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                children: [
                  _templateModeToggle(),
                  const SizedBox(height: 14),
                  _searchField(),
                  const SizedBox(height: 14),
                  Text(
                    searching
                        ? 'SEARCH RESULTS · ${entries.length}'
                        : 'FOR YOUR LIFE · ${entries.length}',
                    style: _collectionMonoStyle(
                      size: 10,
                      weight: FontWeight.w600,
                      color: const Color(0xFF9E978E),
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: width >= 720 ? 1.38 : 1.42,
                    ),
                    itemBuilder: (context, index) {
                      return _templateTile(entry: entries[index]);
                    },
                  ),
                  if (_searchQuery.isNotEmpty && entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: context.appPalette.textMuted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.l10n.collectionsNoTemplatesFound,
                            style: _collectionBodyStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.appPalette.textSecondary,
                            ),
                          ),
                        ],
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

  Widget _sheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
      child: Row(
        children: [
          _headerTextButton(
            label: 'Cancel',
            color: const Color(0xFF8A837B),
            weight: FontWeight.w500,
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              'New collection',
              textAlign: TextAlign.center,
              style: _collectionDisplayStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          _headerTextButton(
            label: 'Continue',
            color: const Color(0xFF1D1A16),
            weight: FontWeight.w700,
            onTap: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }

  Widget _headerTextButton({
    required String label,
    required Color color,
    required FontWeight weight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 78,
        height: 34,
        child: Align(
          alignment: label == 'Cancel'
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Text(
            label,
            style: _collectionBodyStyle(
              fontSize: 15,
              fontWeight: weight,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _templateModeToggle() {
    final usingBlank = _selected == CollectionTemplateType.blank;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              label: 'Start blank',
              active: usingBlank,
              onTap: () =>
                  setState(() => _selected = CollectionTemplateType.blank),
            ),
          ),
          Expanded(
            child: _modeButton(
              label: 'From template',
              active: !usingBlank,
              onTap: () {
                if (_selected == CollectionTemplateType.blank) {
                  final filtered = _filteredEntries(context);
                  setState(() {
                    _selected = filtered.isEmpty
                        ? CollectionTemplateType.propertyManagement
                        : filtered.first.template;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : const [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _collectionBodyStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.07,
            color: active ? const Color(0xFF1D1A16) : const Color(0xFF8A837B),
          ),
        ),
      ),
    );
  }

  List<_TemplateEntry> _filteredEntries(BuildContext context) {
    final all = _orderedTemplateEntries(context);
    if (_searchQuery.isEmpty) return all.take(12).toList(growable: false);
    final q = _searchQuery.toLowerCase();
    return all.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q) ||
          (e.tag?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<_TemplateEntry> _orderedTemplateEntries(BuildContext context) {
    final entries = _buildTemplateEntries(context);
    final byType = {for (final entry in entries) entry.template: entry};
    const order = [
      CollectionTemplateType.propertyManagement,
      CollectionTemplateType.travelPlanner,
      CollectionTemplateType.weddingPlanner,
      CollectionTemplateType.diplomasCertificates,
      CollectionTemplateType.taxDocuments,
      CollectionTemplateType.bankDocuments,
      CollectionTemplateType.healthRecords,
      CollectionTemplateType.projectPlanning,
      CollectionTemplateType.movingChecklist,
      CollectionTemplateType.petCare,
      CollectionTemplateType.vehicleMaintenance,
      CollectionTemplateType.insurancePolicies,
    ];
    return [
      for (final type in order)
        if (byType[type] != null) byType[type]!,
      for (final entry in entries)
        if (!order.contains(entry.template)) entry,
    ];
  }

  Widget _searchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0EA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
        style: _collectionBodyStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1D1A16),
        ),
        decoration: InputDecoration(
          hintText: 'Search 24 templates',
          hintStyle: _collectionBodyStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF9E978E),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 21,
            color: Color(0xFF8A837B),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: const Color(0xFF8A837B),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // Kept for the full-image card variant used in earlier mobile layouts.
  // ignore: unused_element
  Widget _templateCard({required _TemplateEntry entry}) {
    final active = _selected == entry.template;
    return InkWell(
      onTap: () => setState(() => _selected = entry.template),
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active
                ? collectionsPrimary.withValues(alpha: 0.8)
                : collectionsCardBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      entry.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: context.appPalette.surfaceSoft,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_rounded,
                          size: 38,
                          color: Color(0xFF8EA1C0),
                        ),
                      ),
                    ),
                    // Gradient overlay for readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Block count badge
                    Positioned(
                      bottom: 8,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: context.appPalette.surface.withValues(
                            alpha: 0.85,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.l10n.collectionTemplateBlocksCount(
                            entry.blockCount,
                          ),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: context.appPalette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    // Preview button
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _showPreview(entry),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.appPalette.surface.withValues(
                              alpha: 0.85,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_rounded,
                                size: 13,
                                color: collectionsPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.l10n.collectionTemplatePreview,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: collectionsPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tag
                    if (entry.tag != null)
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: entry.tag == 'Popular'
                                ? const Color(0xFFFFF3E0)
                                : const Color(0xFFE7EFFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _localizedTag(context, entry.tag!),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: entry.tag == 'Popular'
                                  ? const Color(0xFFD97706)
                                  : collectionsPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.appPalette.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          entry.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: context.appPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _selectBadge(active),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _templateTile({required _TemplateEntry entry}) {
    final active = _selected == entry.template;
    final tint = _templateTint(entry.template);
    return InkWell(
      onTap: () => setState(() => _selected = entry.template),
      onLongPress: () => _showPreview(entry),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? const Color(0xFF1D1A16) : const Color(0xFFF1ECE5),
            width: active ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _templateEmoji(entry.template),
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _screen12Title(entry),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _collectionBodyStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.06,
                    color: const Color(0xFF1D1A16),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _screen12Subtitle(entry),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _collectionBodyStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8A837B),
                  ),
                ),
              ],
            ),
            if (active)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1A16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFFFEFCF8),
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _screen12Title(_TemplateEntry entry) {
    return switch (entry.template) {
      CollectionTemplateType.propertyManagement => 'Property file',
      CollectionTemplateType.travelPlanner => 'Travel planner',
      CollectionTemplateType.weddingPlanner => 'Wedding planner',
      CollectionTemplateType.diplomasCertificates => 'Diplomas',
      CollectionTemplateType.taxDocuments => 'Tax records',
      CollectionTemplateType.bankDocuments => 'Bank documents',
      CollectionTemplateType.healthRecords => 'Health records',
      CollectionTemplateType.projectPlanning => 'Project planner',
      CollectionTemplateType.movingChecklist => 'Moving checklist',
      CollectionTemplateType.petCare => 'Pet care',
      _ => entry.title,
    };
  }

  String _screen12Subtitle(_TemplateEntry entry) {
    return switch (entry.template) {
      CollectionTemplateType.propertyManagement =>
        'Lease, EDF, insurance, IBAN',
      CollectionTemplateType.travelPlanner => 'Flights, stays, visa, budget',
      CollectionTemplateType.weddingPlanner => 'Vendors, guests, budget',
      CollectionTemplateType.diplomasCertificates =>
        'Originals, transcripts, copies',
      CollectionTemplateType.taxDocuments => 'Returns, receipts, attestations',
      CollectionTemplateType.bankDocuments => 'RIB, statements, contracts',
      CollectionTemplateType.healthRecords => 'Vaccines, scans, prescriptions',
      CollectionTemplateType.projectPlanning => 'Briefs, milestones, files',
      CollectionTemplateType.movingChecklist => 'Logistics, deposit, transfers',
      CollectionTemplateType.petCare => 'Vet, vaccines, microchip ID',
      _ => entry.description,
    };
  }

  String _templateEmoji(CollectionTemplateType template) {
    return switch (template) {
      CollectionTemplateType.propertyManagement => '🏠',
      CollectionTemplateType.travelPlanner => '✈️',
      CollectionTemplateType.weddingPlanner => '💍',
      CollectionTemplateType.diplomasCertificates => '🎓',
      CollectionTemplateType.taxDocuments => '💰',
      CollectionTemplateType.bankDocuments => '🏦',
      CollectionTemplateType.healthRecords => '🩺',
      CollectionTemplateType.projectPlanning => '📋',
      CollectionTemplateType.movingChecklist => '📦',
      CollectionTemplateType.petCare => '🐾',
      CollectionTemplateType.vehicleMaintenance => '🚗',
      CollectionTemplateType.budgetPlanner => '📊',
      CollectionTemplateType.studyPlanner => '📚',
      CollectionTemplateType.homeRenovation => '🛠️',
      CollectionTemplateType.recipeBook => '🍱',
      CollectionTemplateType.fitnessTracker => '🏋️',
      CollectionTemplateType.jobSearch => '💼',
      CollectionTemplateType.eventPlanning => '🎯',
      _ => '📁',
    };
  }

  Color _templateTint(CollectionTemplateType template) {
    return switch (template) {
      CollectionTemplateType.propertyManagement ||
      CollectionTemplateType.healthRecords => const Color(0xFFDDF2E8),
      CollectionTemplateType.travelPlanner ||
      CollectionTemplateType.petCare => const Color(0xFFF6E4CC),
      CollectionTemplateType.weddingPlanner ||
      CollectionTemplateType.diplomasCertificates => const Color(0xFFE9E0F6),
      CollectionTemplateType.taxDocuments ||
      CollectionTemplateType.movingChecklist => const Color(0xFFF5DFDD),
      CollectionTemplateType.bankDocuments ||
      CollectionTemplateType.projectPlanning => const Color(0xFFDDEAF7),
      _ => const Color(0xFFF4EFE4),
    };
  }

  Widget _selectBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? collectionsPrimary : context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active
            ? context.l10n.collectionsSelected
            : context.l10n.collectionsSelect,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : context.appPalette.textSecondary,
        ),
      ),
    );
  }

  String _localizedTag(BuildContext context, String tag) {
    return switch (tag) {
      'Popular' => context.l10n.collectionTemplateTagPopular,
      'New' => context.l10n.collectionTemplateTagNew,
      _ => tag,
    };
  }

  void _showPreview(_TemplateEntry entry) {
    showAdaptiveModal<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: context.appPalette.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appPalette.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Header image
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: Image.network(
                          entry.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: context.appPalette.surfaceSoft,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_rounded,
                              size: 48,
                              color: Color(0xFF8EA1C0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: context.appPalette.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                entry.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.appPalette.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: context.appPalette.stroke),
                  // Block list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            '${context.l10n.collectionsIncludedBlocks} (${entry.blockCount})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Color(0xFF8798B5),
                            ),
                          ),
                        ),
                        for (final block in entry.previewBlocks)
                          _previewBlockRow(block),
                      ],
                    ),
                  ),
                  // Use button
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: context.appPalette.stroke),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          setState(() => _selected = entry.template);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: collectionsPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(context.l10n.collectionsUseTemplate),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _previewBlockRow(_PreviewBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.appPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: block.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(block.icon, size: 17, color: block.iconColor),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  Text(
                    block.typeLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textMuted,
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
}

// ── Data ──

class _PreviewBlock {
  const _PreviewBlock({
    required this.title,
    required this.typeLabel,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String typeLabel;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
}

class _TemplateEntry {
  const _TemplateEntry({
    required this.template,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.blockCount,
    required this.previewBlocks,
    this.tag,
  });

  final CollectionTemplateType template;
  final String title;
  final String description;
  final String imageUrl;
  final int blockCount;
  final List<_PreviewBlock> previewBlocks;
  final String? tag;
}

const _iconFolder = (
  Icons.folder_rounded,
  Color(0xFFE8EEFF),
  Color(0xFF2A5CD6),
);
const _iconSection = (
  Icons.view_agenda_rounded,
  Color(0xFFF0E8FF),
  Color(0xFF7C3AED),
);
const _iconChecklist = (
  Icons.checklist_rounded,
  Color(0xFFE8F8F2),
  Color(0xFF19A672),
);
const _iconNote = (
  Icons.sticky_note_2_rounded,
  Color(0xFFE8F8F2),
  Color(0xFF19A672),
);
const _iconExpense = (
  Icons.payments_rounded,
  Color(0xFFF9EEDC),
  Color(0xFFE89A16),
);
const _iconLink = (Icons.link_rounded, Color(0xFFE8F8FD), Color(0xFF2AAEDC));
const _iconTimeline = (
  Icons.event_rounded,
  Color(0xFFE8EEFF),
  Color(0xFF2A5CD6),
);
const _iconReminder = (
  Icons.alarm_rounded,
  Color(0xFFFFF3E0),
  Color(0xFFF29918),
);
const _iconInput = (
  Icons.text_fields_rounded,
  Color(0xFFF2F5FB),
  Color(0xFF5C6D84),
);
const _iconProgress = (
  Icons.donut_small_rounded,
  Color(0xFFE8F0FF),
  Color(0xFF3B6DE8),
);

_PreviewBlock _pb(String title, String type, (IconData, Color, Color) style) =>
    _PreviewBlock(
      title: title,
      typeLabel: type,
      icon: style.$1,
      iconBg: style.$2,
      iconColor: style.$3,
    );

List<_TemplateEntry> _buildTemplateEntries(BuildContext context) {
  final l = context.l10n;
  return <_TemplateEntry>[
    _TemplateEntry(
      template: CollectionTemplateType.propertyManagement,
      title: l.collectionTemplatePropertyManagementTitle,
      description: l.collectionTemplatePropertyManagementDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1400&q=80',
      blockCount: 9,
      tag: 'Popular',
      previewBlocks: [
        _pb('Documents', 'Folder', _iconFolder),
        _pb('Contracts & Lease', 'Folder', _iconFolder),
        _pb('Insurance', 'Folder', _iconFolder),
        _pb('Rent / Quittance', 'Folder', _iconFolder),
        _pb('Maintenance', 'Folder', _iconFolder),
        _pb('Utilities', 'Folder', _iconFolder),
        _pb('Property Address', 'Input', _iconInput),
        _pb('Move-in Inspection', 'Checklist', _iconChecklist),
        _pb('Lease renewal check', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.travelPlanner,
      title: l.collectionTemplateTravelPlannerTitle,
      description: l.collectionTemplateTravelPlannerDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=1400&q=80',
      blockCount: 3,
      tag: 'Popular',
      previewBlocks: [
        _pb('Itinerary', 'Folder', _iconFolder),
        _pb('Bookings & Tickets', 'Folder', _iconFolder),
        _pb('Budget & Expenses', 'Folder', _iconFolder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.weddingPlanner,
      title: l.collectionTemplateWeddingPlannerTitle,
      description: l.collectionTemplateWeddingPlannerDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=1400&q=80',
      blockCount: 8,
      tag: 'New',
      previewBlocks: [
        _pb('Vendors', 'Section', _iconSection),
        _pb('Guest List', 'Section', _iconSection),
        _pb('Wedding Day Checklist', 'Checklist', _iconChecklist),
        _pb('Venue Deposit', 'Expense', _iconExpense),
        _pb('Ceremony', 'Timeline', _iconTimeline),
        _pb('Wedding Inspiration', 'Link', _iconLink),
        _pb('Invitation Tracker', 'Note', _iconNote),
        _pb('Send save-the-dates', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.budgetPlanner,
      title: l.collectionTemplateBudgetPlannerTitle,
      description: l.collectionTemplateBudgetPlannerDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=1400&q=80',
      blockCount: 5,
      tag: 'Popular',
      previewBlocks: [
        _pb('Monthly Income', 'Input', _iconInput),
        _pb('Monthly Bills', 'Checklist', _iconChecklist),
        _pb('Savings Goal', 'Expense', _iconExpense),
        _pb('Budget Spreadsheet', 'Link', _iconLink),
        _pb('Review budget', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.eventPlanning,
      title: l.collectionTemplateEventPlanningTitle,
      description: l.collectionTemplateEventPlanningDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=1400&q=80',
      blockCount: 6,
      previewBlocks: [
        _pb('Vendors', 'Section', _iconSection),
        _pb('Venue Setup', 'Checklist', _iconChecklist),
        _pb('Venue Deposit', 'Expense', _iconExpense),
        _pb('Ceremony', 'Timeline', _iconTimeline),
        _pb('Guest Dietary Notes', 'Note', _iconNote),
        _pb('Send invitations', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.projectPlanning,
      title: l.collectionTemplateProjectPlanningTitle,
      description: l.collectionTemplateProjectPlanningDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=1400&q=80',
      blockCount: 7,
      previewBlocks: [
        _pb('Planning', 'Section', _iconSection),
        _pb('Resources', 'Section', _iconSection),
        _pb('Sprint Goals', 'Checklist', _iconChecklist),
        _pb('Project Kickoff', 'Timeline', _iconTimeline),
        _pb('Architecture Decisions', 'Note', _iconNote),
        _pb('Project Board', 'Link', _iconLink),
        _pb('Weekly standup', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.freelanceTracker,
      title: l.collectionTemplateFreelanceTrackerTitle,
      description: l.collectionTemplateFreelanceTrackerDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1400&q=80',
      blockCount: 30,
      tag: 'New',
      previewBlocks: [
        _pb('Project 1 — Client Name', 'Section', _iconSection),
        _pb('Client / Rate / Status', 'Input', _iconInput),
        _pb('Milestones', 'Checklist', _iconChecklist),
        _pb('Contracts & Documents', 'Folder', _iconFolder),
        _pb('Project 2 — Client Name', 'Section', _iconSection),
        _pb('Payments & Invoicing', 'Section', _iconSection),
        _pb('Missing Payments', 'Checklist', _iconChecklist),
        _pb('Total Received / Outstanding', 'Expense', _iconExpense),
        _pb('Revenue Targets', 'Section', _iconSection),
        _pb('Monthly Revenue', 'Progress', _iconProgress),
        _pb('Keep the Rhythm', 'Section', _iconSection),
        _pb('Weekly Review', 'Checklist', _iconChecklist),
        _pb('Weekly / Monthly reminders', 'Reminder', _iconReminder),
        _pb('Portfolio', 'Link', _iconLink),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.homeRenovation,
      title: l.collectionTemplateHomeRenovationTitle,
      description: l.collectionTemplateHomeRenovationDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1581858726788-75bc0f6a952d?auto=format&fit=crop&w=1400&q=80',
      blockCount: 7,
      previewBlocks: [
        _pb('Rooms', 'Section', _iconSection),
        _pb('Kitchen Remodel', 'Checklist', _iconChecklist),
        _pb('Contractor Quote', 'Expense', _iconExpense),
        _pb('Flooring Materials', 'Expense', _iconExpense),
        _pb('Renovation Timeline', 'Timeline', _iconTimeline),
        _pb('Inspiration Board', 'Link', _iconLink),
        _pb('Contractor follow-up', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.studyPlanner,
      title: l.collectionTemplateStudyPlannerTitle,
      description: l.collectionTemplateStudyPlannerDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&w=1400&q=80',
      blockCount: 6,
      previewBlocks: [
        _pb('Courses', 'Section', _iconSection),
        _pb('Study Schedule', 'Checklist', _iconChecklist),
        _pb('Exam Dates', 'Timeline', _iconTimeline),
        _pb('Study Resources', 'Link', _iconLink),
        _pb('Assignment Notes', 'Note', _iconNote),
        _pb('Study session', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.fitnessTracker,
      title: l.collectionTemplateFitnessTrackerTitle,
      description: l.collectionTemplateFitnessTrackerDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=1400&q=80',
      blockCount: 5,
      previewBlocks: [
        _pb('Weekly Workout Plan', 'Checklist', _iconChecklist),
        _pb('Personal Records', 'Note', _iconNote),
        _pb('Gym Membership', 'Expense', _iconExpense),
        _pb('Workout Routines', 'Link', _iconLink),
        _pb('Weigh-in', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.recipeBook,
      title: l.collectionTemplateRecipeBookTitle,
      description: l.collectionTemplateRecipeBookDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1466637574441-749b8f19452f?auto=format&fit=crop&w=1400&q=80',
      blockCount: 5,
      previewBlocks: [
        _pb('Breakfast', 'Folder', _iconFolder),
        _pb('Dinner', 'Folder', _iconFolder),
        _pb("Grandma's Pasta Sauce", 'Note', _iconNote),
        _pb('Grocery List', 'Checklist', _iconChecklist),
        _pb('Cooking Techniques', 'Link', _iconLink),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.jobSearch,
      title: l.collectionTemplateJobSearchTitle,
      description: l.collectionTemplateJobSearchDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?auto=format&fit=crop&w=1400&q=80',
      blockCount: 7,
      previewBlocks: [
        _pb('Applications', 'Section', _iconSection),
        _pb('Resume Notes', 'Note', _iconNote),
        _pb('Interview Prep', 'Checklist', _iconChecklist),
        _pb('Phone Screen', 'Timeline', _iconTimeline),
        _pb('LinkedIn Profile', 'Link', _iconLink),
        _pb('Desired Salary', 'Input', _iconInput),
        _pb('Follow up', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.movingChecklist,
      title: l.collectionTemplateMovingChecklistTitle,
      description: l.collectionTemplateMovingChecklistDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1600585152220-90363fe7e115?auto=format&fit=crop&w=1400&q=80',
      blockCount: 6,
      previewBlocks: [
        _pb('Before Moving Day', 'Section', _iconSection),
        _pb('Packing', 'Checklist', _iconChecklist),
        _pb('Utilities', 'Checklist', _iconChecklist),
        _pb('Moving Company', 'Expense', _iconExpense),
        _pb('Moving Day', 'Timeline', _iconTimeline),
        _pb('Cancel old lease', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.petCare,
      title: l.collectionTemplatePetCareTitle,
      description: l.collectionTemplatePetCareDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=1400&q=80',
      blockCount: 7,
      previewBlocks: [
        _pb('Microchip ID', 'Input', _iconInput),
        _pb('Breed', 'Input', _iconInput),
        _pb('Vaccination Schedule', 'Checklist', _iconChecklist),
        _pb('Vet Visit', 'Expense', _iconExpense),
        _pb('Feeding Schedule', 'Note', _iconNote),
        _pb('Flea & tick treatment', 'Reminder', _iconReminder),
        _pb('Pet Insurance', 'Link', _iconLink),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.vehicleMaintenance,
      title: l.collectionTemplateVehicleMaintenanceTitle,
      description: l.collectionTemplateVehicleMaintenanceDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=1400&q=80',
      blockCount: 7,
      previewBlocks: [
        _pb('VIN', 'Input', _iconInput),
        _pb('License Plate', 'Input', _iconInput),
        _pb('Oil Change', 'Expense', _iconExpense),
        _pb('New Tires', 'Expense', _iconExpense),
        _pb('Maintenance Schedule', 'Checklist', _iconChecklist),
        _pb('Next Service', 'Timeline', _iconTimeline),
        _pb('Insurance renewal', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.diplomasCertificates,
      title: l.collectionTemplateDiplomasCertificatesTitle,
      description: l.collectionTemplateDiplomasCertificatesDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1523050854058-8df90110c476?auto=format&fit=crop&w=1400&q=80',
      blockCount: 6,
      tag: 'New',
      previewBlocks: [
        _pb('Degrees', 'Folder', _iconFolder),
        _pb('Professional Certifications', 'Folder', _iconFolder),
        _pb('Diploma Checklist', 'Checklist', _iconChecklist),
        _pb('Transcript', 'Note', _iconNote),
        _pb('Graduation Date', 'Timeline', _iconTimeline),
        _pb('Diploma verification', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.bankDocuments,
      title: l.collectionTemplateBankDocumentsTitle,
      description: l.collectionTemplateBankDocumentsDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=1400&q=80',
      blockCount: 6,
      tag: 'New',
      previewBlocks: [
        _pb('Bank Accounts', 'Section', _iconSection),
        _pb('RIB / IBAN', 'Input', _iconInput),
        _pb('Account Number', 'Input', _iconInput),
        _pb('Bank Name', 'Input', _iconInput),
        _pb('Monthly Statements', 'Folder', _iconFolder),
        _pb('Bank fee review', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.healthRecords,
      title: l.collectionTemplateHealthRecordsTitle,
      description: l.collectionTemplateHealthRecordsDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=1400&q=80',
      blockCount: 7,
      previewBlocks: [
        _pb('Medical History', 'Section', _iconSection),
        _pb('Vaccinations', 'Checklist', _iconChecklist),
        _pb('Blood Type', 'Input', _iconInput),
        _pb('Allergies', 'Note', _iconNote),
        _pb('Doctor Visit', 'Expense', _iconExpense),
        _pb('Annual checkup', 'Reminder', _iconReminder),
        _pb('Health Insurance', 'Link', _iconLink),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.taxDocuments,
      title: l.collectionTemplateTaxDocumentsTitle,
      description: l.collectionTemplateTaxDocumentsDesc,
      imageUrl:
          'https://images.unsplash.com/photo-1554224154-26032ffc0d07?auto=format&fit=crop&w=1400&q=80',
      blockCount: 7,
      previewBlocks: [
        _pb('Tax Returns', 'Folder', _iconFolder),
        _pb('Receipts & Deductions', 'Folder', _iconFolder),
        _pb('Tax ID', 'Input', _iconInput),
        _pb('Annual Income', 'Input', _iconInput),
        _pb('Tax Filing Deadline', 'Timeline', _iconTimeline),
        _pb('File tax return', 'Reminder', _iconReminder),
        _pb('Tax Portal', 'Link', _iconLink),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.warrantyTracker,
      title: 'Warranty Tracker',
      description: 'Track product warranties, receipts, and claim deadlines',
      imageUrl:
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=1400&q=80',
      blockCount: 16,
      tag: 'New',
      previewBlocks: [
        _pb('Active Warranties', 'Section', _iconSection),
        _pb('Product Name', 'Input', _iconInput),
        _pb('Brand / Manufacturer', 'Input', _iconInput),
        _pb('Warranty Expiry', 'Reminder', _iconReminder),
        _pb('Receipts & Proof of Purchase', 'Folder', _iconFolder),
        _pb('Extended Warranties', 'Section', _iconSection),
        _pb('Policy Number', 'Input', _iconInput),
        _pb('Extended Warranty Documents', 'Folder', _iconFolder),
        _pb('Expired / Claimed', 'Section', _iconSection),
        _pb('Archive', 'Note', _iconNote),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.subscriptionManager,
      title: 'Subscription Manager',
      description: 'Monitor recurring subscriptions, costs, and renewals',
      imageUrl:
          'https://images.unsplash.com/photo-1563986768609-322da13575f2?auto=format&fit=crop&w=1400&q=80',
      blockCount: 18,
      tag: 'Popular',
      previewBlocks: [
        _pb('Active Subscriptions', 'Section', _iconSection),
        _pb('Service Name', 'Input', _iconInput),
        _pb('Monthly Cost', 'Input', _iconInput),
        _pb('Cancellation Link', 'Link', _iconLink),
        _pb('Renewal Reminder', 'Reminder', _iconReminder),
        _pb('Entertainment', 'Section', _iconSection),
        _pb('Productivity & Cloud', 'Section', _iconSection),
        _pb('Health & Fitness', 'Section', _iconSection),
        _pb('Paused / Cancelled', 'Section', _iconSection),
        _pb('Archive', 'Note', _iconNote),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.homeMaintenance,
      title: 'Home Maintenance',
      description:
          'Manage appliances, service contacts, inspections, and repairs',
      imageUrl:
          'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=1400&q=80',
      blockCount: 30,
      tag: 'New',
      previewBlocks: [
        _pb('Appliances & Equipment', 'Section', _iconSection),
        _pb('Manuals & Receipts', 'Folder', _iconFolder),
        _pb('Service Contacts', 'Section', _iconSection),
        _pb('Annual Inspections', 'Section', _iconSection),
        _pb('Boiler / Heating Service', 'Reminder', _iconReminder),
        _pb('Repairs & History', 'Section', _iconSection),
        _pb('Repair Log', 'Note', _iconNote),
        _pb('Utility Providers', 'Section', _iconSection),
        _pb('Home Improvement Projects', 'Section', _iconSection),
        _pb('Current Projects', 'Checklist', _iconChecklist),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.movieLibrary,
      title: 'Movie Library',
      description: 'Track movies to watch, ratings, reviews, and favorites',
      imageUrl:
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=1400&q=80',
      blockCount: 18,
      tag: 'New',
      previewBlocks: [
        _pb('Watchlist', 'Section', _iconSection),
        _pb('Title', 'Input', _iconInput),
        _pb('Director', 'Input', _iconInput),
        _pb('Year', 'Input', _iconInput),
        _pb('Genre', 'Input', _iconInput),
        _pb('Platform', 'Input', _iconInput),
        _pb('Watched', 'Section', _iconSection),
        _pb('Rating', 'Input', _iconInput),
        _pb('Notes & Reviews', 'Note', _iconNote),
        _pb('Yearly Goal', 'Progress', _iconProgress),
        _pb('All-Time Favorites', 'Folder', _iconFolder),
        _pb('Letterboxd / IMDb Profile', 'Link', _iconLink),
        _pb('Movie night', 'Reminder', _iconReminder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.readingList,
      title: 'Reading List',
      description:
          'Track books you\'re reading, want to read, and finished books with ratings and notes',
      imageUrl:
          'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=1400&q=80',
      blockCount: 15,
      tag: 'New',
      previewBlocks: [
        _pb('Currently Reading', 'Section', _iconSection),
        _pb('Title', 'Input', _iconInput),
        _pb('Author', 'Input', _iconInput),
        _pb('Genre', 'Input', _iconInput),
        _pb('Reading Progress', 'Progress', _iconProgress),
        _pb('To Read', 'Section', _iconSection),
        _pb('To Read List', 'Checklist', _iconChecklist),
        _pb('ISBN', 'Input', _iconInput),
        _pb('Finished', 'Section', _iconSection),
        _pb('Reviews & Notes', 'Note', _iconNote),
        _pb('Book Photos', 'Folder', _iconFolder),
        _pb('Rating', 'Input', _iconInput),
        _pb('Goodreads Profile', 'Link', _iconLink),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.wineCellar,
      title: 'Wine Cellar',
      description:
          'Organize your wine collection with tasting notes, ratings, and wishlist management',
      imageUrl:
          'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?auto=format&fit=crop&w=1400&q=80',
      blockCount: 14,
      tag: 'New',
      previewBlocks: [
        _pb('Collection', 'Section', _iconSection),
        _pb('Name', 'Input', _iconInput),
        _pb('Vintage', 'Input', _iconInput),
        _pb('Region', 'Input', _iconInput),
        _pb('Grape Variety', 'Input', _iconInput),
        _pb('Price', 'Input', _iconInput),
        _pb('Tasting Notes', 'Section', _iconSection),
        _pb('Tasting Notes', 'Note', _iconNote),
        _pb('Rating', 'Input', _iconInput),
        _pb('Pairing Suggestions', 'Input', _iconInput),
        _pb('Wishlist', 'Section', _iconSection),
        _pb('Wines to Try', 'Checklist', _iconChecklist),
        _pb('Label Photos', 'Folder', _iconFolder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.medicalTracker,
      title: 'Medical Tracker',
      description:
          'Keep your health records, medications, appointments, and insurance information organized and accessible',
      imageUrl:
          'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?auto=format&fit=crop&w=1400&q=80',
      blockCount: 20,
      tag: 'New',
      previewBlocks: [
        _pb('Medications', 'Section', _iconSection),
        _pb('Current Medications', 'Checklist', _iconChecklist),
        _pb('Dosage', 'Input', _iconInput),
        _pb('Prescribing Doctor', 'Input', _iconInput),
        _pb('Appointments', 'Section', _iconSection),
        _pb('Next Appointment', 'Timeline', _iconTimeline),
        _pb('Doctor / Clinic', 'Input', _iconInput),
        _pb('Phone', 'Input', _iconInput),
        _pb('Records', 'Section', _iconSection),
        _pb('Lab Results', 'Folder', _iconFolder),
        _pb('Prescriptions', 'Folder', _iconFolder),
        _pb('Medical History', 'Note', _iconNote),
        _pb('Insurance', 'Section', _iconSection),
        _pb('Patient Portal', 'Link', _iconLink),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.emergencyContacts,
      title: 'Emergency Contacts',
      description:
          'Store critical emergency contact information and medical details for quick access in emergencies',
      imageUrl:
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1400&q=80',
      blockCount: 12,
      tag: 'New',
      previewBlocks: [
        _pb('Primary Contacts', 'Section', _iconSection),
        _pb('Name', 'Input', _iconInput),
        _pb('Relation', 'Input', _iconInput),
        _pb('Phone', 'Input', _iconInput),
        _pb('Email', 'Input', _iconInput),
        _pb('Medical Info', 'Section', _iconSection),
        _pb('Blood Type', 'Input', _iconInput),
        _pb('Allergies', 'Input', _iconInput),
        _pb('Medical Conditions', 'Note', _iconNote),
        _pb('Home', 'Section', _iconSection),
        _pb('Address', 'Input', _iconInput),
        _pb('Important Documents', 'Folder', _iconFolder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.digitalAccounts,
      title: 'Digital Accounts',
      description:
          'Manage and track all your digital accounts, subscriptions, and authentication methods securely',
      imageUrl:
          'https://images.unsplash.com/photo-1563013544-824ae1b704d3?auto=format&fit=crop&w=1400&q=80',
      blockCount: 16,
      tag: 'New',
      previewBlocks: [
        _pb('Active Accounts', 'Section', _iconSection),
        _pb('Service Name', 'Input', _iconInput),
        _pb('Email Used', 'Input', _iconInput),
        _pb('Recovery Email', 'Input', _iconInput),
        _pb('2FA Method', 'Input', _iconInput),
        _pb('Subscription Status', 'Input', _iconInput),
        _pb('Subscriptions', 'Section', _iconSection),
        _pb('Active Subscriptions', 'Checklist', _iconChecklist),
        _pb('Monthly Total', 'Expense', _iconExpense),
        _pb('Archived', 'Section', _iconSection),
        _pb('Closed Accounts', 'Note', _iconNote),
        _pb('Account Screenshots', 'Folder', _iconFolder),
      ],
    ),
    _TemplateEntry(
      template: CollectionTemplateType.insurancePolicies,
      title: 'Insurance Policies',
      description:
          'Track all your insurance policies, coverage details, agent information, and claims history',
      imageUrl:
          'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?auto=format&fit=crop&w=1400&q=80',
      blockCount: 18,
      tag: 'New',
      previewBlocks: [
        _pb('Active Policies', 'Section', _iconSection),
        _pb('Provider', 'Input', _iconInput),
        _pb('Policy Number', 'Input', _iconInput),
        _pb('Coverage Type', 'Input', _iconInput),
        _pb('Premium', 'Input', _iconInput),
        _pb('Deductible', 'Input', _iconInput),
        _pb('Contacts', 'Section', _iconSection),
        _pb('Agent Name', 'Input', _iconInput),
        _pb('Agent Phone', 'Input', _iconInput),
        _pb('Agent Email', 'Input', _iconInput),
        _pb('Claims', 'Section', _iconSection),
        _pb('Open Claims', 'Checklist', _iconChecklist),
        _pb('Claim History', 'Note', _iconNote),
        _pb('Renewal Date', 'Timeline', _iconTimeline),
      ],
    ),
  ];
}
