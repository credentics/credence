import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_country.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_group.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_holder_relation.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_status.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_identity_documents.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/identity_documents_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/identity_documents_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/identity_document_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/document_removal_prompt.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

const String _identityFontDisplay = 'Manrope';
const String _identityFontBody = 'Manrope';
const String _identityFontMono = 'JetBrains Mono';

class IdentityDocumentsPage extends StatelessWidget {
  const IdentityDocumentsPage({
    super.key,
    GetIdentityDocuments? getIdentityDocuments,
    this.embeddedDesktop = false,
  }) : _getIdentityDocuments = getIdentityDocuments;

  final GetIdentityDocuments? _getIdentityDocuments;
  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    final content = BlocProvider(
      create: (_) =>
          IdentityDocumentsCubit(getIdentityDocuments: _getIdentityDocuments)
            ..load(),
      child: _IdentityDocumentsView(embeddedDesktop: embeddedDesktop),
    );

    if (embeddedDesktop) {
      return content;
    }

    return Scaffold(
      backgroundColor: context.appPalette.background,
      body: content,
    );
  }
}

class _IdentityDocumentsView extends StatefulWidget {
  const _IdentityDocumentsView({required this.embeddedDesktop});

  final bool embeddedDesktop;

  @override
  State<_IdentityDocumentsView> createState() => _IdentityDocumentsViewState();
}

class _IdentityDocumentsViewState extends State<_IdentityDocumentsView> {
  final TextEditingController _searchController = TextEditingController();
  IdentityDocumentHolderRelation? _holderFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.embeddedDesktop ? 26.0 : 22.0;
    final palette = context.appPalette;

    return BlocBuilder<IdentityDocumentsCubit, IdentityDocumentsState>(
      builder: (context, state) {
        if (state.viewStatus == IdentityDocumentsViewStatus.loading &&
            state.items.isEmpty) {
          return const Center(child: CupertinoActivityIndicator(radius: 12));
        }

        if (state.viewStatus == IdentityDocumentsViewStatus.error &&
            state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage ??
                      context.l10n.identityUnableLoadSecureIds,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: context.read<IdentityDocumentsCubit>().load,
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          );
        }

        final orderedItems = _orderedItems(state.items);
        final groupFilteredItems = _orderedItems(state.filteredItems);
        final visibleItems = _visibleItems(groupFilteredItems);
        final holderCounts = _holderCounts(groupFilteredItems);
        final stats = _IdentityOverviewStats.fromItems(orderedItems);
        final isRefreshing =
            state.viewStatus == IdentityDocumentsViewStatus.loading &&
            orderedItems.isNotEmpty;

        return DecoratedBox(
          decoration: BoxDecoration(color: palette.background),
          child: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: widget.embeddedDesktop ? 780 : 560,
                      ),
                      child: RefreshIndicator.adaptive(
                        color: palette.primary,
                        onRefresh: context.read<IdentityDocumentsCubit>().load,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            widget.embeddedDesktop ? 22 : 12,
                            horizontal,
                            28,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _IdentityTopBar(
                                embeddedDesktop: widget.embeddedDesktop,
                                onBackTap: () =>
                                    Navigator.of(context).maybePop(),
                                onFilterTap: () =>
                                    _showFilterSheet(context, state),
                                onAddTap: () => _openAddDocumentFlow(context),
                              ),
                              const SizedBox(height: 18),
                              _IdentityIntro(
                                stats: stats,
                                primaryDocument: _primaryDocument(orderedItems),
                              ),
                              const SizedBox(height: 16),
                              _IdentityOverviewCard(
                                stats: stats,
                                refreshing: isRefreshing,
                              ),
                              const SizedBox(height: 14),
                              _IdentitySearchField(
                                controller: _searchController,
                                onClear: () => _searchController.clear(),
                              ),
                              const SizedBox(height: 12),
                              if (orderedItems.isEmpty)
                                _NoIdentityDocsCard(
                                  onAddTap: () => _openAddDocumentFlow(context),
                                )
                              else ...[
                                _IdentityFilterStrip(
                                  currentFilter: state.filter,
                                  allCount: stats.totalCount,
                                  personalCount: stats.personalCount,
                                  travelCount: stats.travelCount,
                                  holderFilter: _holderFilter,
                                  holderCounts: holderCounts,
                                  onSelected: context
                                      .read<IdentityDocumentsCubit>()
                                      .setFilter,
                                  onHolderSelected: (relation) {
                                    setState(() {
                                      _holderFilter = relation;
                                    });
                                  },
                                ),
                                const SizedBox(height: 6),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: visibleItems.isEmpty
                                      ? _FilteredEmptyCard(
                                          key: ValueKey(
                                            'identity_empty_${state.filter}',
                                          ),
                                          filter: state.filter,
                                          onResetTap: () => context
                                              .read<IdentityDocumentsCubit>()
                                              .setFilter(
                                                IdentityDocumentsFilter.all,
                                              ),
                                          onClearSearch: () {
                                            setState(() {
                                              _holderFilter = null;
                                            });
                                            _searchController.clear();
                                          },
                                        )
                                      : Column(
                                          key: ValueKey(
                                            'identity_list_${state.filter}_${_holderFilter?.storageKey}_${_searchController.text}_${visibleItems.length}',
                                          ),
                                          children: [
                                            ...visibleItems.asMap().entries.map((
                                              entry,
                                            ) {
                                              final item = entry.value;
                                              return Padding(
                                                padding: EdgeInsets.zero,
                                                child: Dismissible(
                                                  key: ValueKey(
                                                    'identity_document_${item.id}',
                                                  ),
                                                  direction: DismissDirection
                                                      .endToStart,
                                                  background:
                                                      const SizedBox.shrink(),
                                                  secondaryBackground:
                                                      const _SwipeRemoveBackground(),
                                                  confirmDismiss: (_) =>
                                                      _onSwipeRemove(
                                                        context,
                                                        item,
                                                      ),
                                                  child: _IdentityListCard(
                                                    item: item,
                                                    scheme: _identityScheme(
                                                      item,
                                                      entry.key,
                                                    ),
                                                    onTap: () =>
                                                        _openDocumentDetail(
                                                          context,
                                                          item.id,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<IdentityDocumentEntity> _visibleItems(
    List<IdentityDocumentEntity> source,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    Iterable<IdentityDocumentEntity> items = source;

    final holder = _holderFilter;
    if (holder != null) {
      items = items.where((item) => item.holderRelation == holder);
    }

    if (query.isNotEmpty) {
      items = items.where((item) {
        final haystack = [
          item.typeLabel,
          item.issuer,
          item.countryName,
          item.identifierLabel,
          item.identifierValue,
          _groupLabel(item.group),
          item.holderRelation.label,
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      });
    }

    return items.toList(growable: false);
  }

  Map<IdentityDocumentHolderRelation, int> _holderCounts(
    List<IdentityDocumentEntity> items,
  ) {
    final counts = <IdentityDocumentHolderRelation, int>{};
    for (final item in items) {
      counts[item.holderRelation] = (counts[item.holderRelation] ?? 0) + 1;
    }
    return counts;
  }

  IdentityDocumentEntity? _primaryDocument(List<IdentityDocumentEntity> items) {
    for (final item in items) {
      if (item.isPrimary) return item;
    }
    return items.isEmpty ? null : items.first;
  }

  Future<void> _showFilterSheet(
    BuildContext context,
    IdentityDocumentsState state,
  ) async {
    final cubit = context.read<IdentityDocumentsCubit>();
    final selected = await showModalBottomSheet<IdentityDocumentsFilter>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final palette = sheetContext.appPalette;
        final stats = _IdentityOverviewStats.fromItems(
          _orderedItems(state.items),
        );
        return Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.stroke),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.strokeStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                sheetContext.l10n.identityFilterSheetTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sheetContext.l10n.identityFilterSheetSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _IdentityFilterSheetRow(
                label: _filterLabel(sheetContext, IdentityDocumentsFilter.all),
                count: stats.totalCount,
                selected: state.filter == IdentityDocumentsFilter.all,
                onTap: () =>
                    Navigator.of(sheetContext).pop(IdentityDocumentsFilter.all),
              ),
              _IdentityFilterSheetRow(
                label: _filterLabel(
                  sheetContext,
                  IdentityDocumentsFilter.personal,
                ),
                count: stats.personalCount,
                selected: state.filter == IdentityDocumentsFilter.personal,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(IdentityDocumentsFilter.personal),
              ),
              _IdentityFilterSheetRow(
                label: _filterLabel(
                  sheetContext,
                  IdentityDocumentsFilter.travel,
                ),
                count: stats.travelCount,
                selected: state.filter == IdentityDocumentsFilter.travel,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(IdentityDocumentsFilter.travel),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || !context.mounted) return;
    setState(() {
      _holderFilter = null;
    });
    cubit.setFilter(selected);
  }

  List<IdentityDocumentEntity> _orderedItems(
    List<IdentityDocumentEntity> items,
  ) {
    final sorted = [...items];
    sorted.sort((a, b) {
      if (a.isPrimary != b.isPrimary) {
        return a.isPrimary ? -1 : 1;
      }
      final aOrder = _typeOrder(a.typeLabel);
      final bOrder = _typeOrder(b.typeLabel);
      final byType = aOrder.compareTo(bOrder);
      if (byType != 0) {
        return byType;
      }
      return a.issuer.compareTo(b.issuer);
    });
    return sorted;
  }

  int _typeOrder(String typeLabel) {
    final normalized = typeLabel.toLowerCase();
    if (normalized.contains('passport')) {
      return 0;
    }
    if (normalized.contains('driver')) {
      return 1;
    }
    if (normalized.contains('id')) {
      return 2;
    }
    return 3;
  }

  Future<void> _openAddDocumentFlow(BuildContext context) async {
    final createdId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            const IdentityDocumentEntryPage(initialType: DocumentType.passport),
      ),
    );
    if (!context.mounted) {
      return;
    }
    if (createdId != null && createdId.trim().isNotEmpty) {
      await context.read<IdentityDocumentsCubit>().load();
      if (!context.mounted) {
        return;
      }
      await _openDocumentDetail(context, createdId);
      return;
    }
    await context.read<IdentityDocumentsCubit>().load();
  }

  Future<void> _openDocumentDetail(
    BuildContext context,
    String documentId,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(documentId: documentId),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<IdentityDocumentsCubit>().load();
  }

  Future<bool> _onSwipeRemove(
    BuildContext context,
    IdentityDocumentEntity item,
  ) async {
    final decision = await showDocumentRemovalPrompt(
      context: context,
      title: item.issuer,
    );
    if (decision == null || !context.mounted) {
      return false;
    }

    final cubit = context.read<IdentityDocumentsCubit>();
    final success = switch (decision) {
      DocumentRemovalDecision.archive => await cubit.archiveById(item.id),
      DocumentRemovalDecision.delete => await cubit.deleteById(item.id),
    };

    if (!context.mounted) {
      return false;
    }

    if (success) {
      final message = decision == DocumentRemovalDecision.archive
          ? context.l10n.documentsArchived
          : context.l10n.documentsDeleted;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.documentsUnableRemove)),
      );
    }

    // Dismissible is used only for swipe affordance; list mutation is cubit-driven.
    return false;
  }
}

class _IdentityTopBar extends StatelessWidget {
  const _IdentityTopBar({
    required this.embeddedDesktop,
    required this.onBackTap,
    required this.onFilterTap,
    required this.onAddTap,
  });

  final bool embeddedDesktop;
  final VoidCallback onBackTap;
  final VoidCallback onFilterTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!embeddedDesktop)
          _IdentityIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: context.l10n.commonBack,
            onTap: onBackTap,
          )
        else
          const SizedBox(width: 38, height: 38),
        const Spacer(),
        _IdentityIconButton(
          icon: Icons.tune_rounded,
          tooltip: context.l10n.identityFilterTooltip,
          onTap: onFilterTap,
        ),
        const SizedBox(width: 8),
        _IdentityIconButton(
          icon: Icons.add_rounded,
          tooltip: context.l10n.identityAddFirstId,
          onTap: onAddTap,
        ),
      ],
    );
  }
}

class _IdentityIconButton extends StatelessWidget {
  const _IdentityIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final button = Material(
      color: palette.surfaceSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: palette.stroke.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 21, color: palette.textPrimary),
        ),
      ),
    );
    if (tooltip.trim().isEmpty) return button;
    return Tooltip(message: tooltip, child: button);
  }
}

class _IdentityIntro extends StatelessWidget {
  const _IdentityIntro({required this.stats, required this.primaryDocument});

  final _IdentityOverviewStats stats;
  final IdentityDocumentEntity? primaryDocument;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final holderLabel = stats.holderCount == 1
        ? context.l10n.identityHolderSingular
        : context.l10n.identityHolderPlural;
    final primary = primaryDocument;
    final primaryText = primary == null
        ? context.l10n.identityNoPrimaryIdentity
        : context.l10n.identityPrimaryIdentitySet(primary.typeLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.identityIntroEyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: _identityFontMono,
            letterSpacing: 1.2,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.identityYourDocumentsTitle,
          style: TextStyle(
            fontFamily: _identityFontDisplay,
            fontSize: 26,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.65,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${context.l10n.identitySecureIdsStored(stats.totalCount)} · ${stats.holderCount} $holderLabel · $primaryText',
          style: TextStyle(
            fontFamily: _identityFontBody,
            fontSize: 13.5,
            height: 1.35,
            fontWeight: FontWeight.w500,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _IdentitySearchField extends StatelessWidget {
  const _IdentitySearchField({required this.controller, required this.onClear});

  final TextEditingController controller;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: palette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontFamily: _identityFontBody,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: palette.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.identitySearchHint,
                hintStyle: TextStyle(
                  fontFamily: _identityFontMono,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  color: palette.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.trim().isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: palette.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IdentityFilterSheetRow extends StatelessWidget {
  const _IdentityFilterSheetRow({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: selected ? palette.surfaceSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? palette.primary : palette.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontFamily: _identityFontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.35,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityOverviewCard extends StatelessWidget {
  const _IdentityOverviewCard({required this.stats, required this.refreshing});

  final _IdentityOverviewStats stats;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: _OverviewMetric(
                label: _statusLabel(context, IdentityDocumentStatus.valid),
                value: stats.validCount.toString(),
                accentColor: palette.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewMetric(
                label: _statusLabel(
                  context,
                  IdentityDocumentStatus.expiringSoon,
                ),
                value: stats.expiringSoonCount.toString(),
                accentColor: palette.warning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OverviewMetric(
                label: _statusLabel(context, IdentityDocumentStatus.expired),
                value: stats.expiredCount.toString(),
                accentColor: palette.danger,
              ),
            ),
          ],
        ),
        if (refreshing)
          Positioned(
            right: 10,
            top: 10,
            child: CupertinoActivityIndicator(
              radius: 7,
              color: palette.textMuted,
            ),
          ),
      ],
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              fontFamily: _identityFontMono,
              letterSpacing: 1,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: _identityFontDisplay,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityFilterStrip extends StatelessWidget {
  const _IdentityFilterStrip({
    required this.currentFilter,
    required this.allCount,
    required this.personalCount,
    required this.travelCount,
    required this.holderFilter,
    required this.holderCounts,
    required this.onSelected,
    required this.onHolderSelected,
  });

  final IdentityDocumentsFilter currentFilter;
  final int allCount;
  final int personalCount;
  final int travelCount;
  final IdentityDocumentHolderRelation? holderFilter;
  final Map<IdentityDocumentHolderRelation, int> holderCounts;
  final ValueChanged<IdentityDocumentsFilter> onSelected;
  final ValueChanged<IdentityDocumentHolderRelation?> onHolderSelected;

  @override
  Widget build(BuildContext context) {
    final holderEntries = holderCounts.entries.toList()
      ..sort((a, b) => _relationOrder(a.key).compareTo(_relationOrder(b.key)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _IdentityFilterChip(
            label: _filterLabel(context, IdentityDocumentsFilter.all),
            count: allCount,
            selected: currentFilter == IdentityDocumentsFilter.all,
            onTap: () => onSelected(IdentityDocumentsFilter.all),
          ),
          const SizedBox(width: 8),
          _IdentityFilterChip(
            label: _filterLabel(context, IdentityDocumentsFilter.personal),
            count: personalCount,
            selected: currentFilter == IdentityDocumentsFilter.personal,
            onTap: () => onSelected(IdentityDocumentsFilter.personal),
          ),
          const SizedBox(width: 8),
          _IdentityFilterChip(
            label: _filterLabel(context, IdentityDocumentsFilter.travel),
            count: travelCount,
            selected: currentFilter == IdentityDocumentsFilter.travel,
            onTap: () => onSelected(IdentityDocumentsFilter.travel),
          ),
          if (holderEntries.isNotEmpty) ...[
            const SizedBox(width: 12),
            _IdentityFilterChip(
              label: context.l10n.identityAllHolders,
              count: holderEntries.fold<int>(
                0,
                (sum, item) => sum + item.value,
              ),
              selected: holderFilter == null,
              onTap: () => onHolderSelected(null),
              muted: true,
            ),
            for (final entry in holderEntries) ...[
              const SizedBox(width: 8),
              _IdentityFilterChip(
                label: _relationLabel(context, entry.key),
                count: entry.value,
                selected: holderFilter == entry.key,
                onTap: () => onHolderSelected(entry.key),
                muted: true,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _IdentityFilterChip extends StatelessWidget {
  const _IdentityFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final selectedColor = muted ? palette.textPrimary : palette.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? selectedColor : palette.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? selectedColor : palette.stroke,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: _identityFontBody,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : palette.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.16)
                      : palette.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontFamily: _identityFontMono,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: selected ? Colors.white : palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityListCard extends StatelessWidget {
  const _IdentityListCard({
    required this.item,
    required this.scheme,
    required this.onTap,
  });

  final IdentityDocumentEntity item;
  final _IdentityCardScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(item.status);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final countryLabel =
        item.countryName.trim().isEmpty || item.countryName == '-'
        ? context.l10n.identityVaultIdentityFallback
        : item.countryName;
    final expiryText = DateFormat(
      'd MMM yy',
      localeTag,
    ).format(item.expiryDate);
    final title =
        item.typeLabel.toLowerCase().contains(countryLabel.toLowerCase())
        ? item.typeLabel
        : '${item.typeLabel} · $countryLabel';
    final subtitleParts = <String>[
      _relationLabel(context, item.holderRelation),
      if (item.identifierValue.trim().isNotEmpty)
        context.l10n.identityDocumentNumberPrefix(item.identifierValue.trim()),
      context.l10n.identityExpiryShort(expiryText).toLowerCase(),
    ];
    final palette = context.appPalette;
    final accent = scheme.end;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: palette.stroke.withValues(alpha: 0.78)),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _IdentityDocumentIcon(
                icon: scheme.watermarkIcon,
                country: item.country,
                backgroundColor: _identityTint(
                  context,
                  scheme.start,
                  accent,
                  darkAlpha: 0.18,
                ),
                foregroundColor: accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _identityFontBody,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.08,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        if (item.isPrimary) ...[
                          const SizedBox(width: 6),
                          _IdentityMetaPill(
                            label: context.l10n.identityPrimaryBadge
                                .toUpperCase(),
                            foregroundColor: isDark
                                ? const Color(0xFFFFE8A3)
                                : const Color(0xFF7B5A00),
                            backgroundColor: _identityTint(
                              context,
                              const Color(0xFFFFF1B8),
                              const Color(0xFFFFB703),
                              darkAlpha: 0.16,
                            ),
                            borderColor: Colors.transparent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _identityFontBody,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _IdentityMetaPill(
                label: _statusCompactLabel(context, item),
                icon: statusStyle.icon,
                foregroundColor: statusStyle.foregroundColor,
                backgroundColor: _identityTint(
                  context,
                  statusStyle.backgroundColor,
                  statusStyle.foregroundColor,
                  darkAlpha: 0.16,
                ),
                borderColor: Colors.transparent,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityDocumentIcon extends StatelessWidget {
  const _IdentityDocumentIcon({
    required this.icon,
    required this.country,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final DocumentCountry country;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: foregroundColor, size: 22),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -3,
            child: _IdentityCountryFlag(country: country),
          ),
        ],
      ),
    );
  }
}

class _IdentityCountryFlag extends StatelessWidget {
  const _IdentityCountryFlag({required this.country});

  final DocumentCountry country;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    const size = Size(20, 14);
    return Container(
      width: size.width,
      height: size.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: palette.surface, width: 1.5),
      ),
      child: CustomPaint(painter: _IdentityFlagPainter(country)),
    );
  }
}

class _IdentityFlagPainter extends CustomPainter {
  const _IdentityFlagPainter(this.country);

  final DocumentCountry country;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    void rect(Color color, Rect rect) {
      paint.color = color;
      canvas.drawRect(rect, paint);
    }

    void circle(Color color, Offset center, double radius) {
      paint.color = color;
      canvas.drawCircle(center, radius, paint);
    }

    void star(Color color, Offset center, double outerRadius) {
      paint.color = color;
      final innerRadius = outerRadius * 0.42;
      final path = Path();
      for (var index = 0; index < 10; index++) {
        final radius = index.isEven ? outerRadius : innerRadius;
        final angle = -math.pi / 2 + index * math.pi / 5;
        final point = Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    switch (country) {
      case DocumentCountry.france:
      case DocumentCountry.europeanUnion:
        rect(
          const Color(0xFF2449A8),
          Rect.fromLTWH(0, 0, size.width / 3, size.height),
        );
        rect(
          Colors.white,
          Rect.fromLTWH(size.width / 3, 0, size.width / 3, size.height),
        );
        rect(
          const Color(0xFFE04747),
          Rect.fromLTWH(size.width * 2 / 3, 0, size.width / 3, size.height),
        );
        break;
      case DocumentCountry.germany:
        rect(
          const Color(0xFF171717),
          Rect.fromLTWH(0, 0, size.width, size.height / 3),
        );
        rect(
          const Color(0xFFD13A32),
          Rect.fromLTWH(0, size.height / 3, size.width, size.height / 3),
        );
        rect(
          const Color(0xFFFFCE45),
          Rect.fromLTWH(0, size.height * 2 / 3, size.width, size.height / 3),
        );
        break;
      case DocumentCountry.italy:
        rect(
          const Color(0xFF21966C),
          Rect.fromLTWH(0, 0, size.width / 3, size.height),
        );
        rect(
          Colors.white,
          Rect.fromLTWH(size.width / 3, 0, size.width / 3, size.height),
        );
        rect(
          const Color(0xFFD64747),
          Rect.fromLTWH(size.width * 2 / 3, 0, size.width / 3, size.height),
        );
        break;
      case DocumentCountry.tunisia:
        rect(const Color(0xFFE34343), Offset.zero & size);
        final diskCenter = size.center(Offset.zero);
        circle(Colors.white, diskCenter, size.shortestSide * 0.34);
        final crescentCenter = Offset(size.width * 0.46, size.height * 0.5);
        circle(
          const Color(0xFFE34343),
          crescentCenter,
          size.shortestSide * 0.16,
        );
        circle(
          Colors.white,
          Offset(size.width * 0.51, size.height * 0.5),
          size.shortestSide * 0.13,
        );
        star(
          const Color(0xFFE34343),
          Offset(size.width * 0.61, size.height * 0.5),
          size.shortestSide * 0.08,
        );
        break;
      case DocumentCountry.turkey:
        rect(const Color(0xFFE34343), Offset.zero & size);
        circle(
          Colors.white,
          Offset(size.width * 0.42, size.height * 0.5),
          size.shortestSide * 0.25,
        );
        circle(
          const Color(0xFFE34343),
          Offset(size.width * 0.49, size.height * 0.5),
          size.shortestSide * 0.2,
        );
        star(
          Colors.white,
          Offset(size.width * 0.66, size.height * 0.5),
          size.shortestSide * 0.09,
        );
        break;
      case DocumentCountry.unitedStates:
      case DocumentCountry.unitedKingdom:
        rect(const Color(0xFFF7F7F2), Offset.zero & size);
        final stripeHeight = size.height / 7;
        for (var index = 0; index < 7; index += 2) {
          rect(
            const Color(0xFFD94747),
            Rect.fromLTWH(0, stripeHeight * index, size.width, stripeHeight),
          );
        }
        rect(
          const Color(0xFF2449A8),
          Rect.fromLTWH(0, 0, size.width * 0.46, size.height * 0.55),
        );
        break;
      case DocumentCountry.spain:
        rect(
          const Color(0xFFC93A35),
          Rect.fromLTWH(0, 0, size.width, size.height * 0.26),
        );
        rect(
          const Color(0xFFFFD35A),
          Rect.fromLTWH(0, size.height * 0.26, size.width, size.height * 0.48),
        );
        rect(
          const Color(0xFFC93A35),
          Rect.fromLTWH(0, size.height * 0.74, size.width, size.height * 0.26),
        );
        break;
      case DocumentCountry.canada:
      case DocumentCountry.switzerland:
        rect(const Color(0xFFE34343), Offset.zero & size);
        rect(
          Colors.white,
          Rect.fromLTWH(size.width * 0.36, 0, size.width * 0.28, size.height),
        );
        break;
      case DocumentCountry.unitedArabEmirates:
        rect(
          const Color(0xFFE34343),
          Rect.fromLTWH(0, 0, size.width * 0.26, size.height),
        );
        rect(
          const Color(0xFF259260),
          Rect.fromLTWH(
            size.width * 0.26,
            0,
            size.width * 0.74,
            size.height / 3,
          ),
        );
        rect(
          Colors.white,
          Rect.fromLTWH(
            size.width * 0.26,
            size.height / 3,
            size.width * 0.74,
            size.height / 3,
          ),
        );
        rect(
          const Color(0xFF1C1C1C),
          Rect.fromLTWH(
            size.width * 0.26,
            size.height * 2 / 3,
            size.width * 0.74,
            size.height / 3,
          ),
        );
        break;
      case DocumentCountry.unknown:
        rect(const Color(0xFFE8E5DE), Offset.zero & size);
        paint.color = const Color(0xFF9A9388);
        paint.strokeWidth = 1.2;
        canvas.drawLine(
          Offset(size.width * 0.25, size.height * 0.5),
          Offset(size.width * 0.75, size.height * 0.5),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _IdentityFlagPainter oldDelegate) {
    return oldDelegate.country != country;
  }
}

class _IdentityMetaPill extends StatelessWidget {
  const _IdentityMetaPill({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: _identityFontMono,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: foregroundColor,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoIdentityDocsCard extends StatelessWidget {
  const _NoIdentityDocsCard({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.stroke),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(palette.primary, Colors.white, 0.78) ??
                      palette.primarySoft,
                  Color.lerp(palette.primaryAccent, Colors.white, 0.72) ??
                      palette.primarySoft,
                ],
              ),
            ),
            child: Icon(Icons.badge_outlined, color: palette.primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.identityNoIdsYet,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.identityAddFirstDescription,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddTap,
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(context.l10n.identityAddFirstId),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyCard extends StatelessWidget {
  const _FilteredEmptyCard({
    super.key,
    required this.filter,
    required this.onResetTap,
    required this.onClearSearch,
  });

  final IdentityDocumentsFilter filter;
  final VoidCallback onResetTap;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final label = _filterLabel(context, filter).toLowerCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.filter_alt_off_rounded,
              color: palette.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.identityNoDocumentsForFilter(label),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.identityFilteredEmptyDescription,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            children: [
              TextButton(
                onPressed: onResetTap,
                child: Text(context.l10n.documentShowAll),
              ),
              TextButton(
                onPressed: onClearSearch,
                child: Text(context.l10n.identityClearSearch),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwipeRemoveBackground extends StatelessWidget {
  const _SwipeRemoveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFFFBE9EA), Color(0xFFFFFFFF)],
        ),
        border: Border.all(color: const Color(0xFFF3C4C8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.archive_outlined,
            color: context.appPalette.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.delete_outline_rounded,
            color: context.appPalette.danger,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _IdentityOverviewStats {
  const _IdentityOverviewStats({
    required this.totalCount,
    required this.validCount,
    required this.expiringSoonCount,
    required this.expiredCount,
    required this.personalCount,
    required this.travelCount,
    required this.holderCount,
  });

  factory _IdentityOverviewStats.fromItems(List<IdentityDocumentEntity> items) {
    var validCount = 0;
    var expiringSoonCount = 0;
    var expiredCount = 0;
    var personalCount = 0;
    var travelCount = 0;
    final holders = <IdentityDocumentHolderRelation>{};

    for (final item in items) {
      holders.add(item.holderRelation);
      switch (item.status) {
        case IdentityDocumentStatus.valid:
          validCount += 1;
        case IdentityDocumentStatus.expiringSoon:
          expiringSoonCount += 1;
        case IdentityDocumentStatus.expired:
          expiredCount += 1;
      }

      switch (item.group) {
        case IdentityDocumentGroup.personal:
          personalCount += 1;
        case IdentityDocumentGroup.travel:
          travelCount += 1;
      }
    }

    return _IdentityOverviewStats(
      totalCount: items.length,
      validCount: validCount,
      expiringSoonCount: expiringSoonCount,
      expiredCount: expiredCount,
      personalCount: personalCount,
      travelCount: travelCount,
      holderCount: holders.length,
    );
  }

  final int totalCount;
  final int validCount;
  final int expiringSoonCount;
  final int expiredCount;
  final int personalCount;
  final int travelCount;
  final int holderCount;
}

String _statusLabel(BuildContext context, IdentityDocumentStatus status) {
  return switch (status) {
    IdentityDocumentStatus.valid => context.l10n.identityStatusValid,
    IdentityDocumentStatus.expiringSoon =>
      context.l10n.identityStatusExpiringSoon,
    IdentityDocumentStatus.expired => context.l10n.identityStatusExpired,
  };
}

String _relationLabel(
  BuildContext context,
  IdentityDocumentHolderRelation relation,
) {
  return switch (relation) {
    IdentityDocumentHolderRelation.owner => context.l10n.identityRelationOwner,
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
    IdentityDocumentHolderRelation.other => context.l10n.identityRelationOther,
  };
}

String _filterLabel(BuildContext context, IdentityDocumentsFilter filter) {
  return switch (filter) {
    IdentityDocumentsFilter.all => context.l10n.identityFilterAll,
    IdentityDocumentsFilter.personal => context.l10n.identityFilterPersonal,
    IdentityDocumentsFilter.travel => context.l10n.identityFilterTravel,
  };
}

String _groupLabel(IdentityDocumentGroup group) {
  return switch (group) {
    IdentityDocumentGroup.personal => 'Personal',
    IdentityDocumentGroup.travel => 'Travel',
  };
}

IconData _listIconFor(String typeLabel) {
  final normalized = typeLabel.toLowerCase();
  if (normalized.contains('passport')) {
    return Icons.public_rounded;
  }
  if (normalized.contains('driver')) {
    return Icons.directions_car_filled_rounded;
  }
  if (normalized.contains('insurance')) {
    return Icons.health_and_safety_rounded;
  }
  if (normalized.contains('residence')) {
    return Icons.apartment_rounded;
  }
  return Icons.badge_rounded;
}

class _IdentityStatusStyle {
  const _IdentityStatusStyle({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.icon,
  });

  final Color foregroundColor;
  final Color backgroundColor;
  final IconData icon;
}

_IdentityStatusStyle _statusStyle(IdentityDocumentStatus status) {
  return switch (status) {
    IdentityDocumentStatus.valid => const _IdentityStatusStyle(
      foregroundColor: Color(0xFF0A9A57),
      backgroundColor: Color(0xFFD3F3E2),
      icon: Icons.check_circle,
    ),
    IdentityDocumentStatus.expiringSoon => const _IdentityStatusStyle(
      foregroundColor: Color(0xFFD48400),
      backgroundColor: Color(0xFFFBE9B9),
      icon: Icons.access_time_filled_rounded,
    ),
    IdentityDocumentStatus.expired => const _IdentityStatusStyle(
      foregroundColor: Color(0xFFDC2626),
      backgroundColor: Color(0xFFFDE5E5),
      icon: Icons.error_rounded,
    ),
  };
}

String _statusCompactLabel(BuildContext context, IdentityDocumentEntity item) {
  return switch (item.status) {
    IdentityDocumentStatus.valid => context.l10n.identityStatusOk,
    IdentityDocumentStatus.expiringSoon => context.l10n.identityStatusDaysLeft(
      _daysUntil(item.expiryDate),
    ),
    IdentityDocumentStatus.expired => context.l10n.identityStatusExpired,
  };
}

int _daysUntil(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  return target.difference(today).inDays.clamp(0, 9999);
}

int _relationOrder(IdentityDocumentHolderRelation relation) {
  return switch (relation) {
    IdentityDocumentHolderRelation.owner => 0,
    IdentityDocumentHolderRelation.family => 1,
    IdentityDocumentHolderRelation.parent => 2,
    IdentityDocumentHolderRelation.wife => 3,
    IdentityDocumentHolderRelation.husband => 4,
    IdentityDocumentHolderRelation.son => 5,
    IdentityDocumentHolderRelation.daughter => 6,
    IdentityDocumentHolderRelation.other => 7,
  };
}

Color _identityTint(
  BuildContext context,
  Color lightColor,
  Color accent, {
  double darkAlpha = 0.18,
}) {
  final palette = context.appPalette;
  if (Theme.of(context).brightness != Brightness.dark) return lightColor;
  return Color.alphaBlend(accent.withValues(alpha: darkAlpha), palette.surface);
}

_IdentityCardScheme _identityScheme(IdentityDocumentEntity item, int index) {
  final type = item.typeLabel.toLowerCase();

  if (type.contains('passport')) {
    return const _IdentityCardScheme(
      start: Color(0xFFFFEEF1),
      end: Color(0xFF7B3341),
      watermarkIcon: Icons.travel_explore_rounded,
    );
  }

  if (type.contains('driver')) {
    return const _IdentityCardScheme(
      start: Color(0xFFE7F6EF),
      end: Color(0xFF187C63),
      watermarkIcon: Icons.directions_car_filled_rounded,
    );
  }

  if (type.contains('residence')) {
    return const _IdentityCardScheme(
      start: Color(0xFFFFF0DF),
      end: Color(0xFF8A5A13),
      watermarkIcon: Icons.apartment_rounded,
    );
  }

  if (type.contains('id')) {
    return const _IdentityCardScheme(
      start: Color(0xFFEAF0FF),
      end: Color(0xFF2353B8),
      watermarkIcon: Icons.badge_outlined,
    );
  }

  return _IdentityCardScheme(
    start: switch (index % 3) {
      0 => const Color(0xFFF6F1E3),
      1 => const Color(0xFFF0ECFF),
      _ => const Color(0xFFEAF0FF),
    },
    end: switch (index % 3) {
      0 => const Color(0xFF6D6250),
      1 => const Color(0xFF5B45B8),
      _ => const Color(0xFF2353B8),
    },
    watermarkIcon: _listIconFor(item.typeLabel),
  );
}

class _IdentityCardScheme {
  const _IdentityCardScheme({
    required this.start,
    required this.end,
    required this.watermarkIcon,
  });

  final Color start;
  final Color end;
  final IconData watermarkIcon;
}
