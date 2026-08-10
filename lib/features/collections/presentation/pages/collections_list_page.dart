import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/presentation/widgets/desktop_context_menu.dart';
import 'package:pass_doc_manager/app/presentation/widgets/desktop_list_item_wrapper.dart';
import 'package:pass_doc_manager/app/presentation/widgets/vault_error_state.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_template_type.dart';
import 'package:pass_doc_manager/features/collections/presentation/cubit/collections_cubit.dart';
import 'package:pass_doc_manager/features/collections/presentation/cubit/collections_state.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_create_flow_models.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_dashboard_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collections_create_step1_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collections_create_step2_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class CollectionsListPage extends StatelessWidget {
  const CollectionsListPage({super.key, this.embeddedDesktop = false});

  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CollectionsCubit()..load(),
      child: embeddedDesktop
          ? const _CollectionsListView(embeddedDesktop: true)
          : const _CollectionsListScaffold(),
    );
  }
}

class _CollectionsListScaffold extends StatelessWidget {
  const _CollectionsListScaffold();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionsCubit, CollectionsState>(
      builder: (context, state) {
        final palette = context.appPalette;
        return Scaffold(
          backgroundColor: palette.background,
          body: const _CollectionsListView(embeddedDesktop: false),
        );
      },
    );
  }
}

class _CollectionsListView extends StatelessWidget {
  const _CollectionsListView({required this.embeddedDesktop});

  final bool embeddedDesktop;

  static Future<void> openCreateFlow(BuildContext context) async {
    final template = await Navigator.of(context).push<CollectionTemplateType>(
      MaterialPageRoute(builder: (_) => const CollectionsCreateStep2Page()),
    );
    if (!context.mounted || template == null) {
      return;
    }

    final draft = await Navigator.of(context).push<CollectionCreateDraft>(
      MaterialPageRoute(
        builder: (_) => CollectionsCreateStep1Page(
          initialDraft: _draftForTemplate(template),
        ),
      ),
    );
    if (!context.mounted || draft == null) {
      return;
    }

    final created = await context.read<CollectionsCubit>().create(
      name: draft.name,
      iconKey: draft.iconKey,
      iconEmoji: draft.iconEmoji,
      iconImagePath: draft.iconImagePath,
      accentColorHex: draft.accentColorHex,
      template: template,
    );
    if (!context.mounted || created == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionDashboardPage(collectionId: created.id),
      ),
    );

    if (!context.mounted) {
      return;
    }
    await context.read<CollectionsCubit>().load();
  }

  static CollectionCreateDraft _draftForTemplate(CollectionTemplateType type) {
    if (type == CollectionTemplateType.blank) {
      return const CollectionCreateDraft(
        name: '',
        iconKey: 'folder',
        accentColorHex: '#1152D4',
      );
    }

    return CollectionCreateDraft(
      name: type.label,
      iconKey: switch (type) {
        CollectionTemplateType.propertyManagement => 'home_work',
        CollectionTemplateType.travelPlanner => 'flight',
        CollectionTemplateType.weddingPlanner => 'favorite',
        CollectionTemplateType.diplomasCertificates => 'school',
        CollectionTemplateType.taxDocuments => 'payments',
        CollectionTemplateType.bankDocuments => 'work',
        CollectionTemplateType.healthRecords => 'medical_services',
        CollectionTemplateType.projectPlanning => 'workspaces',
        CollectionTemplateType.movingChecklist => 'shopping_bag',
        CollectionTemplateType.vehicleMaintenance => 'directions_car',
        CollectionTemplateType.eventPlanning => 'event',
        CollectionTemplateType.budgetPlanner => 'payments',
        CollectionTemplateType.studyPlanner => 'book',
        CollectionTemplateType.homeRenovation => 'home_repair_service',
        CollectionTemplateType.jobSearch => 'work',
        CollectionTemplateType.petCare => 'pets',
        _ => 'folder',
      },
      iconEmoji: switch (type) {
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
        _ => null,
      },
      accentColorHex: switch (type) {
        CollectionTemplateType.propertyManagement => '#059669',
        CollectionTemplateType.travelPlanner => '#F59E0B',
        CollectionTemplateType.weddingPlanner => '#D946EF',
        CollectionTemplateType.diplomasCertificates => '#E11D48',
        CollectionTemplateType.taxDocuments => '#B87818',
        CollectionTemplateType.bankDocuments => '#0EA5E9',
        CollectionTemplateType.healthRecords => '#10B981',
        CollectionTemplateType.projectPlanning => '#7C3AED',
        CollectionTemplateType.movingChecklist => '#EA580C',
        _ => '#1152D4',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return BlocBuilder<CollectionsCubit, CollectionsState>(
      builder: (context, state) {
        if ((state.viewStatus == CollectionsViewStatus.initial ||
                state.viewStatus == CollectionsViewStatus.loading) &&
            state.collections.isEmpty) {
          return const Center(child: CupertinoActivityIndicator(radius: 12));
        }

        if (state.viewStatus == CollectionsViewStatus.error &&
            state.collections.isEmpty) {
          return VaultErrorState(
            icon: Icons.folder_special_rounded,
            message: state.errorMessage ?? context.l10n.collectionsErrorLoad,
            onRetry: () => context.read<CollectionsCubit>().load(),
          );
        }

        return SafeArea(
          top: true,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: embeddedDesktop ? 760 : 520,
              ),
              child: state.isReorderMode && state.collections.isNotEmpty
                  ? ReorderableListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        embeddedDesktop ? 16 : 14,
                        16,
                        32,
                      ),
                      buildDefaultDragHandles: false,
                      header: embeddedDesktop
                          ? _desktopHeader(context, state, palette)
                          : _mobileReferenceHeader(context, state, palette),
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) {
                          newIndex--;
                        }
                        context.read<CollectionsCubit>().reorderCollections(
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        );
                      },
                      children: [
                        for (var i = 0; i < state.collections.length; i++)
                          Padding(
                            key: ValueKey(state.collections[i].id),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: i,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: palette.textMuted,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _collectionCard(
                                    context,
                                    state.collections[i],
                                    enabled: false,
                                    showChevron: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        embeddedDesktop ? 16 : 0,
                        embeddedDesktop ? 16 : 8,
                        embeddedDesktop ? 16 : 0,
                        embeddedDesktop ? 32 : 112,
                      ),
                      children: [
                        if (embeddedDesktop)
                          _desktopHeader(context, state, palette),
                        if (!embeddedDesktop)
                          _mobileReferenceHeader(context, state, palette),
                        if (state.collections.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: embeddedDesktop ? 0 : 22,
                            ),
                            child: _emptyState(context),
                          )
                        else ...[
                          if (!embeddedDesktop) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
                              child: CollectionsSectionLabel(
                                label:
                                    '${context.l10n.collectionListYours} · ${state.collections.length}',
                              ),
                            ),
                          ],
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: embeddedDesktop ? 0 : 22,
                            ),
                            child: Column(
                              children: [
                                ...state.collections.map(
                                  (collection) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Dismissible(
                                      key: ValueKey(collection.id),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (_) =>
                                          _confirmDeleteCollection(
                                            context,
                                            collection,
                                          ),
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 24,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDE8E8),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete_rounded,
                                          color: Color(0xFFE53E3E),
                                        ),
                                      ),
                                      child: _collectionCard(
                                        context,
                                        collection,
                                        showChevron: embeddedDesktop,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _desktopHeader(
    BuildContext context,
    CollectionsState state,
    AppPalette palette,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            context.l10n.collectionsTitle,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const Spacer(),
          if (state.collections.isNotEmpty && state.isReorderMode)
            TextButton(
              onPressed: () =>
                  context.read<CollectionsCubit>().setReorderMode(false),
              child: Text(
                context.l10n.collectionDashboardDone,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: collectionsPrimary,
                ),
              ),
            )
          else ...[
            if (state.collections.isNotEmpty)
              _roundHeaderButton(
                context,
                icon: Icons.reorder_rounded,
                onTap: () =>
                    context.read<CollectionsCubit>().setReorderMode(true),
              ),
            if (state.collections.isNotEmpty) const SizedBox(width: 10),
            _roundHeaderButton(
              context,
              icon: Icons.add_rounded,
              onTap: () => openCreateFlow(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mobileReferenceHeader(
    BuildContext context,
    CollectionsState state,
    AppPalette palette,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _referenceBackButton(context),
              const Spacer(),
              if (state.collections.isNotEmpty)
                _roundHeaderButton(
                  context,
                  icon: state.isReorderMode
                      ? Icons.check_rounded
                      : Icons.reorder_rounded,
                  onTap: () => context.read<CollectionsCubit>().setReorderMode(
                    !state.isReorderMode,
                  ),
                ),
              if (!state.isReorderMode) ...[
                if (state.collections.isNotEmpty) const SizedBox(width: 8),
                _roundHeaderButton(
                  context,
                  icon: Icons.add_rounded,
                  onTap: () => openCreateFlow(context),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          Text(
            context.l10n.collectionDetailItemCount(state.collections.length),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
              letterSpacing: 1.1,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.collectionsTitle,
            style: TextStyle(
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceBackButton(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: () => Navigator.of(context).maybePop(),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.stroke.withValues(alpha: 0.7)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: palette.textPrimary,
        ),
      ),
    );
  }

  Widget _roundHeaderButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
          border: Border.all(color: palette.stroke),
        ),
        child: Icon(icon, size: 19, color: palette.textPrimary),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final palette = context.appPalette;
    return CollectionsSurfaceCard(
      radius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.collections_bookmark_rounded,
              size: 42,
              color: collectionsPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No collections yet',
            style: TextStyle(
              fontSize: 30 / 1.45,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first collection to organize dynamic blocks.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _collectionCard(
    BuildContext context,
    CollectionEntity collection, {
    bool enabled = true,
    bool showChevron = true,
  }) {
    final palette = context.appPalette;
    final accent = _colorFromHex(collection.accentColorHex);
    final isReferenceRow = !showChevron;
    final radius = isReferenceRow ? 24.0 : 18.0;
    final iconShellSize = isReferenceRow ? 56.0 : 44.0;
    final iconRadius = isReferenceRow ? 18.0 : 13.0;
    final metadata = _collectionMetadata(context, collection);

    return DesktopListItemWrapper(
      onDoubleTap: enabled
          ? () => _openCollection(context, collection.id)
          : null,
      borderRadius: radius,
      contextActions: enabled
          ? [
              ContextMenuAction(
                icon: Icons.open_in_new_rounded,
                label: 'Open',
                onSelected: () => _openCollection(context, collection.id),
              ),
              ContextMenuAction(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                onSelected: () => _confirmDelete(context, collection),
                isDestructive: true,
              ),
            ]
          : const [],
      child: InkWell(
        onTap: enabled ? () => _openCollection(context, collection.id) : null,
        borderRadius: BorderRadius.circular(radius),
        child: CollectionsSurfaceCard(
          padding: isReferenceRow
              ? const EdgeInsets.fromLTRB(18, 18, 18, 18)
              : const EdgeInsets.fromLTRB(16, 14, 16, 14),
          radius: radius,
          child: Row(
            children: [
              buildCollectionLeadingIcon(
                context,
                iconKey: collection.iconKey,
                iconEmoji: collection.iconEmoji,
                iconImagePath: collection.iconImagePath,
                accent: accent,
                shellSize: iconShellSize,
                shellRadius: iconRadius,
                iconSize: isReferenceRow ? 28 : 20,
              ),
              SizedBox(width: isReferenceRow ? 18 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isReferenceRow ? 17.5 : 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: isReferenceRow ? -0.2 : 0,
                        color: palette.textPrimary,
                      ),
                    ),
                    SizedBox(height: isReferenceRow ? 4 : 2),
                    Text(
                      metadata,
                      maxLines: isReferenceRow ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isReferenceRow ? 13.5 : 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: isReferenceRow ? 'JetBrains Mono' : null,
                        letterSpacing: isReferenceRow ? 0.2 : 0.1,
                        height: isReferenceRow ? 1.28 : null,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (collection.isPinLocked)
                Padding(
                  padding: EdgeInsets.only(left: isReferenceRow ? 12 : 8),
                  child: _collectionPinPill(compact: !isReferenceRow),
                )
              else if (isReferenceRow && collection.totalItemsCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    collection.totalItemsCount.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'JetBrains Mono',
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              if (showChevron)
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

  String _collectionMetadata(
    BuildContext context,
    CollectionEntity collection,
  ) {
    final folders = collection.countByType(CollectionBlockType.folder);
    final reminders = collection.countByType(CollectionBlockType.reminder);
    final parts = <String>[
      context.l10n.collectionDetailItemCount(collection.totalItemsCount),
    ];

    if (folders > 0) {
      parts.add(context.l10n.collectionDetailFolderCount(folders));
    }
    if (reminders > 0) {
      parts.add(context.l10n.collectionDetailReminderCount(reminders));
    }

    return parts.join(' · ');
  }

  Widget _collectionPinPill({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF4E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: compact ? 14 : 16,
            color: const Color(0xFF08744E),
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            const Text(
              'PIN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'JetBrains Mono',
                letterSpacing: 1.6,
                color: Color(0xFF08744E),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CollectionEntity collection) {
    _confirmDeleteCollection(context, collection);
  }

  Future<bool> _confirmDeleteCollection(
    BuildContext context,
    CollectionEntity collection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.collectionDetailDeleteBlockTitle),
        content: Text(context.l10n.collectionDetailDeleteBlockMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.collectionDetailCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.l10n.collectionDetailDelete,
              style: const TextStyle(color: Color(0xFFE53E3E)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;
    await context.read<CollectionsCubit>().deleteCollection(collection.id);
    return true;
  }

  Future<void> _openCollection(
    BuildContext context,
    String collectionId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionDashboardPage(collectionId: collectionId),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<CollectionsCubit>().load();
  }
}

Color _colorFromHex(String hex) {
  final normalized = hex.replaceAll('#', '').trim();
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return collectionsPrimary;
  }
  return Color(0xFF000000 | value);
}
