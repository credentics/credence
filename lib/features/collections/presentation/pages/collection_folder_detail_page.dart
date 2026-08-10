import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_metadata_keys.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/features/collections/presentation/cubit/collection_detail_cubit.dart';
import 'package:pass_doc_manager/features/collections/presentation/cubit/collection_detail_state.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_block_page_factory.dart';
import 'package:pass_doc_manager/features/collections/presentation/support/collection_file_preview_helper.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/static_map_preview.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class CollectionFolderDetailPage extends StatelessWidget {
  const CollectionFolderDetailPage({
    super.key,
    required this.collectionId,
    required this.folderId,
  });

  final String collectionId;
  final String folderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CollectionDetailCubit()..load(collectionId: collectionId),
      child: _CollectionFolderDetailView(
        collectionId: collectionId,
        folderId: folderId,
      ),
    );
  }
}

String _relativeLabel(BuildContext context, DateTime value) {
  final delta = DateTime.now().difference(value);
  if (delta.inMinutes < 1) {
    return context.l10n.collectionDashboardJustNow;
  }
  if (delta.inMinutes < 60) {
    return '${delta.inMinutes}m ago';
  }
  if (delta.inHours < 24) {
    return '${delta.inHours}h ago';
  }
  if (delta.inDays < 7) {
    return '${delta.inDays}d ago';
  }
  return DateFormat.MMMd().format(value);
}

class _CollectionFolderDetailView extends StatefulWidget {
  const _CollectionFolderDetailView({
    required this.collectionId,
    required this.folderId,
  });

  final String collectionId;
  final String folderId;

  @override
  State<_CollectionFolderDetailView> createState() =>
      _CollectionFolderDetailViewState();
}

class _CollectionFolderDetailViewState
    extends State<_CollectionFolderDetailView> {
  final Set<String> _collapsedSectionIds = {};
  final Set<String> _initializedSectionIds = {};
  final Set<String> _pendingDeleteBlockIds = {};
  String? _reorderingSectionId;
  bool _isReorderMode = false;
  static const double _itemCardRadius = 18;
  static const EdgeInsets _itemCardPadding = EdgeInsets.fromLTRB(
    14,
    14,
    14,
    14,
  );
  static const double _itemIconShellSize = 46;
  static const double _itemIconShellRadius = 14;
  static const double _itemIconSize = 21;
  static const double _itemTitleSize = 14.5;
  static const double _itemSubtitleSize = 12;

  String get collectionId => widget.collectionId;
  String get folderId => widget.folderId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionDetailCubit, CollectionDetailState>(
      builder: (context, state) {
        final collection = state.collection;
        if (collection == null &&
            (state.viewStatus == CollectionDetailViewStatus.initial ||
                state.viewStatus == CollectionDetailViewStatus.loading)) {
          return Scaffold(
            backgroundColor: context.appPalette.background,
            body: Center(child: CupertinoActivityIndicator(radius: 12)),
          );
        }

        if (collection == null) {
          return Scaffold(
            backgroundColor: context.appPalette.background,
            appBar: GenericAppBar(
              title: context.l10n.collectionFolderTitle,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            body: Center(
              child: TextButton(
                onPressed: () => context.read<CollectionDetailCubit>().load(
                  collectionId: collectionId,
                ),
                child: Text(context.l10n.collectionFolderRetry),
              ),
            ),
          );
        }

        _syncCollapsedSections(collection.blocks);
        _prunePendingDeleteIds(collection.blocks);
        final visibleBlocks = collection.blocks
            .where((item) => !_pendingDeleteBlockIds.contains(item.id))
            .toList(growable: false);

        CollectionBlockEntity? folder;
        for (final item in visibleBlocks) {
          if (item.id == folderId) {
            folder = item;
            break;
          }
        }
        if (folder == null) {
          return Scaffold(
            backgroundColor: context.appPalette.background,
            appBar: GenericAppBar(
              title: context.l10n.collectionFolderTitle,
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            body: Center(
              child: Text(
                context.l10n.collectionFolderNotFound,
                style: TextStyle(color: context.appPalette.textSecondary),
              ),
            ),
          );
        }

        final selectedFolder = folder;
        final children =
            visibleBlocks
                .where((item) => item.parentBlockId == selectedFolder.id)
                .toList(growable: false)
              ..sort((a, b) => a.position.compareTo(b.position));

        return Scaffold(
          backgroundColor: context.appPalette.background,
          body: SafeArea(
            bottom: false,
            child: _isReorderMode
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: _folderDetailHeader(
                          context,
                          collection.name,
                          selectedFolder,
                          children.length,
                        ),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 112),
                          buildDefaultDragHandles: false,
                          itemCount: children.length,
                          onReorder: (oldIndex, newIndex) {
                            context.read<CollectionDetailCubit>().reorderBlocks(
                              parentBlockId: selectedFolder.id,
                              oldIndex: oldIndex,
                              newIndex: newIndex,
                            );
                          },
                          proxyDecorator: (child, index, animation) => Material(
                            color: Colors.transparent,
                            elevation: 0,
                            child: child,
                          ),
                          itemBuilder: (context, index) {
                            final item = children[index];
                            return Padding(
                              key: ValueKey(item.id),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Icon(
                                        Icons.drag_handle_rounded,
                                        color: context.appPalette.textMuted,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _collectionItemCard(
                                      context,
                                      item,
                                      allBlocks: visibleBlocks,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
                    children: [
                      _folderDetailHeader(
                        context,
                        collection.name,
                        selectedFolder,
                        children.length,
                      ),
                      const SizedBox(height: 18),
                      if (children.isNotEmpty) ...[
                        CollectionsSectionLabel(
                          label: context.l10n.collectionFolderContents,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (children.isEmpty)
                        _emptyInlineCard(context.l10n.collectionFolderEmpty)
                      else
                        ...children.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _collectionItemCard(
                              context,
                              item,
                              allBlocks: visibleBlocks,
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

  void _syncCollapsedSections(List<CollectionBlockEntity> blocks) {
    final sectionsById = <String, CollectionBlockEntity>{
      for (final block in blocks)
        if (block.type == CollectionBlockType.section) block.id: block,
    };
    final sectionIds = sectionsById.keys.toSet();
    _collapsedSectionIds.removeWhere((id) => !sectionIds.contains(id));
    _initializedSectionIds.removeWhere((id) => !sectionIds.contains(id));
    if (_reorderingSectionId != null &&
        !sectionIds.contains(_reorderingSectionId)) {
      _reorderingSectionId = null;
    }
    final unseenIds = sectionIds.difference(_initializedSectionIds);
    _initializedSectionIds.addAll(unseenIds);
    for (final id in unseenIds) {
      final section = sectionsById[id];
      final defaultCollapsed =
          section?.metadata[CollectionBlockMetadataKeys
              .sectionDefaultCollapsed] !=
          'false';
      if (defaultCollapsed) {
        _collapsedSectionIds.add(id);
      } else {
        _collapsedSectionIds.remove(id);
      }
    }
  }

  void _prunePendingDeleteIds(List<CollectionBlockEntity> blocks) {
    final ids = blocks.map((block) => block.id).toSet();
    _pendingDeleteBlockIds.removeWhere((id) => !ids.contains(id));
  }

  Widget _collectionItemCard(
    BuildContext context,
    CollectionBlockEntity block, {
    required List<CollectionBlockEntity> allBlocks,
  }) {
    return switch (block.type) {
      CollectionBlockType.folder => _swipeToDelete(
        context,
        block,
        child: _folderRow(context, block, allBlocks),
      ),
      CollectionBlockType.section => _sectionGroup(context, block, allBlocks),
      CollectionBlockType.document => _swipeToDelete(
        context,
        block,
        child: _documentRow(context, block),
      ),
      CollectionBlockType.note => _swipeToDelete(
        context,
        block,
        child: _noteRow(context, block),
      ),
      CollectionBlockType.checklist => _swipeToDelete(
        context,
        block,
        child: _checklistRow(context, block),
      ),
      CollectionBlockType.link => _swipeToDelete(
        context,
        block,
        child: _linkRow(context, block),
      ),
      CollectionBlockType.image => _swipeToDelete(
        context,
        block,
        child: _imageRow(context, block),
      ),
      CollectionBlockType.expense => _swipeToDelete(
        context,
        block,
        child: _expenseRow(context, block),
      ),
      CollectionBlockType.timeline => _swipeToDelete(
        context,
        block,
        child: _timelineRow(context, block),
      ),
      CollectionBlockType.location => _swipeToDelete(
        context,
        block,
        child: _locationRow(context, block),
      ),
      CollectionBlockType.reminder => _swipeToDelete(
        context,
        block,
        child: _reminderRow(context, block),
      ),
      CollectionBlockType.progress => _swipeToDelete(
        context,
        block,
        child: _progressRow(context, block),
      ),
      CollectionBlockType.input => _swipeToDelete(
        context,
        block,
        child: _inputRow(context, block),
      ),
    };
  }

  Widget _folderRow(
    BuildContext context,
    CollectionBlockEntity folder,
    List<CollectionBlockEntity> allBlocks,
  ) {
    final childCount = allBlocks
        .where((item) => item.parentBlockId == folder.id)
        .length;
    final description = folder.description
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return InkWell(
      onTap: () => _openFolder(context, folder.id),
      onLongPress: () => _showBlockActions(context, folder),
      borderRadius: BorderRadius.circular(_itemCardRadius),
      child: CollectionsSurfaceCard(
        radius: _itemCardRadius,
        padding: _itemCardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildCollectionBlockLeadingIcon(
              context,
              type: CollectionBlockType.folder,
              metadata: folder.metadata,
              shellSize: _itemIconShellSize,
              shellRadius: _itemIconShellRadius,
              iconSize: _itemIconSize,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _itemTitleSize,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.collectionDetailItemCount(childCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _itemSubtitleSize,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrains Mono',
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _itemSubtitleSize,
                        height: 1.32,
                        fontWeight: FontWeight.w500,
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.appPalette.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionGroup(
    BuildContext context,
    CollectionBlockEntity section,
    List<CollectionBlockEntity> allBlocks,
  ) {
    final children =
        allBlocks
            .where((item) => item.parentBlockId == section.id)
            .toList(growable: false)
          ..sort((a, b) => a.position.compareTo(b.position));
    final isCollapsed = _collapsedSectionIds.contains(section.id);
    final isReordering = _reorderingSectionId == section.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _swipeToDelete(
          context,
          section,
          child: _sectionHeader(
            context,
            section,
            children.length,
            isCollapsed,
            isReordering,
          ),
        ),
        AnimatedCrossFade(
          firstChild: _sectionChildrenRail(
            context,
            section.id,
            children,
            allBlocks,
            isReordering,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isCollapsed
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    CollectionBlockEntity section,
    int childCount,
    bool isCollapsed,
    bool isReordering,
  ) {
    final palette = context.appPalette;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        buildCollectionBlockLeadingIcon(
          context,
          type: CollectionBlockType.section,
          metadata: section.metadata,
          shellSize: 28,
          shellRadius: 8,
          iconSize: 14,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                  height: 1.08,
                ),
              ),
              _blockDescriptionPreview(context, section),
              const SizedBox(height: 3),
              Text(
                context.l10n.collectionDetailItemCount(childCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                  color: palette.textSecondary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        if (!isCollapsed && childCount > 1) ...[
          const SizedBox(width: 8),
          _sectionReorderToggleButton(
            context,
            isReordering: isReordering,
            onTap: () {
              setState(() {
                _reorderingSectionId = isReordering ? null : section.id;
              });
            },
          ),
        ],
        const SizedBox(width: 4),
        AnimatedRotation(
          turns: isCollapsed ? -0.25 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.expand_more_rounded,
            color: palette.textMuted,
            size: 23,
          ),
        ),
      ],
    );

    return InkWell(
      onTap: () {
        setState(() {
          if (isCollapsed) {
            _collapsedSectionIds.remove(section.id);
          } else {
            _collapsedSectionIds.add(section.id);
            if (_reorderingSectionId == section.id) {
              _reorderingSectionId = null;
            }
          }
        });
      },
      onLongPress: () => _showBlockActions(context, section),
      borderRadius: BorderRadius.circular(_itemCardRadius),
      child: isCollapsed
          ? CollectionsSurfaceCard(
              radius: _itemCardRadius,
              padding: _itemCardPadding,
              child: content,
            )
          : Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                border: Border.all(color: palette.stroke),
              ),
              child: content,
            ),
    );
  }

  Widget _sectionChildrenRail(
    BuildContext context,
    String sectionId,
    List<CollectionBlockEntity> children,
    List<CollectionBlockEntity> allBlocks,
    bool isReordering,
  ) {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(
          left: BorderSide(color: palette.stroke),
          right: BorderSide(color: palette.stroke),
          bottom: BorderSide(color: palette.stroke),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Stack(
        children: [
          Positioned(
            left: 7,
            top: 0,
            bottom: 10,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                color: palette.stroke.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Column(
              children: [
                if (isReordering)
                  _sectionReorderList(context, sectionId, children)
                else ...[
                  ...children.map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _collectionItemCard(
                        context,
                        child,
                        allBlocks: allBlocks,
                      ),
                    ),
                  ),
                  _sectionAddBlockButton(context, sectionId),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionReorderToggleButton(
    BuildContext context, {
    required bool isReordering,
    required VoidCallback onTap,
  }) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 30,
        padding: EdgeInsets.symmetric(horizontal: isReordering ? 10 : 8),
        decoration: BoxDecoration(
          color: isReordering ? palette.surfaceSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.stroke),
        ),
        alignment: Alignment.center,
        child: isReordering
            ? Text(
                context.l10n.collectionDashboardDone,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: collectionsPrimary,
                ),
              )
            : Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: palette.textMuted,
              ),
      ),
    );
  }

  Widget _sectionReorderList(
    BuildContext context,
    String sectionId,
    List<CollectionBlockEntity> children,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      buildDefaultDragHandles: false,
      itemCount: children.length,
      onReorder: (oldIndex, newIndex) {
        context.read<CollectionDetailCubit>().reorderBlocks(
          parentBlockId: sectionId,
          oldIndex: oldIndex,
          newIndex: newIndex,
        );
      },
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = Curves.easeOut.transform(animation.value);
          return Transform.scale(
            scale: 1 + (0.02 * t),
            child: Material(color: Colors.transparent, child: child),
          );
        },
        child: child,
      ),
      itemBuilder: (context, index) {
        final child = children[index];
        return Padding(
          key: ValueKey('section_reorder_${child.id}'),
          padding: const EdgeInsets.only(bottom: 8),
          child: _sectionReorderBlockRow(context, child, index),
        );
      },
    );
  }

  Widget _sectionReorderBlockRow(
    BuildContext context,
    CollectionBlockEntity block,
    int index,
  ) {
    final palette = context.appPalette;
    return InkWell(
      onLongPress: () => _showBlockActions(context, block),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.stroke),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 22,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            _listIconForBlock(context, block),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  _blockDescriptionPreview(context, block),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showBlockActions(context, block),
              icon: Icon(
                Icons.more_horiz_rounded,
                color: palette.textMuted,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionAddBlockButton(BuildContext context, String sectionId) {
    final palette = context.appPalette;
    return InkWell(
      onTap: () => _addBlock(context, sectionId),
      borderRadius: BorderRadius.circular(18),
      child: CollectionsDashedOutline(
        color: palette.stroke.withValues(alpha: 0.75),
        radius: 18,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 20, color: palette.textMuted),
              const SizedBox(width: 8),
              Text(
                context.l10n.collectionDashboardAddBlock,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checklistRow(BuildContext context, CollectionBlockEntity block) {
    return CollectionsChecklistPreviewCard(
      block: block,
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
      onToggleItem: (index) =>
          _toggleChecklistPreviewItem(context, block, index),
    );
  }

  Widget _progressRow(BuildContext context, CollectionBlockEntity block) {
    return CollectionsProgressPreviewCard(
      block: block,
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
    );
  }

  Widget _inputRow(BuildContext context, CollectionBlockEntity block) {
    final label = (block.metadata['label'] ?? block.title).trim();
    final value = (block.metadata['value'] ?? block.subtitle).trim();
    return InkWell(
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
      borderRadius: BorderRadius.circular(_itemCardRadius),
      child: CollectionsSurfaceCard(
        radius: _itemCardRadius,
        padding: _itemCardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _listIconForBlock(context, block),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'JetBrains Mono',
                      color: context.appPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? '-' : value,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: _itemTitleSize,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  _blockDescriptionPreview(context, block),
                ],
              ),
            ),
            IconButton(
              tooltip: context.l10n.collectionDashboardCopy,
              onPressed: value.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: value));
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.collectionDashboardCopied),
                        ),
                      );
                    },
              icon: const Icon(Icons.copy_rounded),
              color: collectionsPrimary,
              disabledColor: context.appPalette.textMuted.withValues(
                alpha: 0.45,
              ),
              iconSize: 20,
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleChecklistPreviewItem(
    BuildContext context,
    CollectionBlockEntity block,
    int index,
  ) async {
    if (index < 0 || index >= block.checklistItems.length) {
      return;
    }
    final items = block.checklistItems.toList(growable: false);
    items[index] = items[index].copyWith(isDone: !items[index].isDone);
    await context.read<CollectionDetailCubit>().saveBlock(
      block.copyWith(
        checklistItems: items,
        isCompleted: items.isNotEmpty && items.every((item) => item.isDone),
      ),
    );
  }

  Widget _documentRow(BuildContext context, CollectionBlockEntity block) {
    final fileType = (block.fileType ?? '').trim();
    final size = (block.fileSizeLabel ?? '').trim();
    final subtitle = [
      if (fileType.isNotEmpty) fileType,
      if (size.isNotEmpty) size,
    ].join(' • ');

    return InkWell(
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
      borderRadius: BorderRadius.circular(_itemCardRadius),
      child: CollectionsSurfaceCard(
        radius: _itemCardRadius,
        padding: _itemCardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _listIconForBlock(context, block),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _itemTitleSize,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _itemSubtitleSize,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'JetBrains Mono',
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                  ],
                  _blockDescriptionPreview(context, block),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showBlockActions(context, block),
              icon: Icon(
                Icons.more_horiz_rounded,
                size: 22,
                color: context.appPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteRow(BuildContext context, CollectionBlockEntity block) {
    final preview = _notePreviewText(block);
    return InkWell(
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
      borderRadius: BorderRadius.circular(_itemCardRadius),
      child: CollectionsSurfaceCard(
        radius: _itemCardRadius,
        padding: _itemCardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _listIconForBlock(context, block),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _itemTitleSize,
                      fontWeight: FontWeight.w700,
                      color: context.appPalette.textPrimary,
                    ),
                  ),
                  if (preview.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _itemSubtitleSize,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkRow(BuildContext context, CollectionBlockEntity block) {
    final domain = (block.domainLabel ?? '').trim().isNotEmpty
        ? block.domainLabel!.trim()
        : _domainFromUrl(block.url);
    final palette = context.appPalette;
    return InkWell(
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
      borderRadius: BorderRadius.circular(16),
      child: CollectionsSurfaceCard(
        radius: 16,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _linkLeadingIcon(context, block, palette),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (domain.isNotEmpty)
                    Text(
                      domain,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'JetBrains Mono',
                        color: collectionsPrimary,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    block.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  _blockDescriptionPreview(context, block),
                  const SizedBox(height: 2),
                  Text(
                    'Saved · ${context.l10n.collectionDetailOpenLink} →',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: palette.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _imageRow(BuildContext context, CollectionBlockEntity block) {
    final description = _blockDescriptionText(block);
    return InkWell(
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
      borderRadius: BorderRadius.circular(_itemCardRadius),
      child: CollectionsSurfaceCard(
        radius: _itemCardRadius,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_itemCardRadius),
          child: SizedBox(
            height: 232,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _resolveImageWidget(
                  block.imageUrl ?? block.filePath,
                  fallback: _imagePlaceholder(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        if (collectionBlockHasCustomIcon(block.metadata))
                          buildCollectionBlockLeadingIcon(
                            context,
                            type: block.type,
                            metadata: block.metadata,
                            shellSize: 28,
                            shellRadius: 8,
                            iconSize: 14,
                          )
                        else
                          const Icon(
                            Icons.image_outlined,
                            size: 13,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                block.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: _itemTitleSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: _itemSubtitleSize,
                                    height: 1.2,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _blockCardHeader(
    BuildContext context,
    String label, {
    String? trailing,
    Widget? trailingWidget,
    CollectionBlockEntity? block,
  }) {
    final palette = context.appPalette;
    return Row(
      children: [
        if (block != null && collectionBlockHasCustomIcon(block.metadata)) ...[
          buildCollectionBlockLeadingIcon(
            context,
            type: block.type,
            metadata: block.metadata,
            shellSize: 28,
            shellRadius: 9,
            iconSize: 14,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w900,
              fontFamily: 'JetBrains Mono',
              color: palette.textMuted,
            ),
          ),
        ),
        if (trailingWidget != null)
          trailingWidget
        else if ((trailing ?? '').trim().isNotEmpty)
          Text(
            trailing!.trim(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
              color: palette.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _expenseRow(BuildContext context, CollectionBlockEntity block) {
    final amountLabel = _expenseAmountLabel(block);
    final dateLabel = DateFormat.MMMd().format(
      block.eventAt ?? block.updatedAt,
    );
    final category = (block.metadata['category'] ?? 'General').toUpperCase();
    final palette = context.appPalette;
    return InkWell(
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
      borderRadius: BorderRadius.circular(16),
      child: CollectionsSurfaceCard(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _blockCardHeader(
              context,
              'EXPENSE · $category',
              trailing: dateLabel,
              block: block,
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountLabel,
                  style: TextStyle(
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 7),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    block.currencyCode ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              block.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: palette.textSecondary,
              ),
            ),
            _blockDescriptionPreview(context, block),
          ],
        ),
      ),
    );
  }

  Widget _timelineRow(BuildContext context, CollectionBlockEntity block) {
    final dateTimeLabel = block.eventAt == null
        ? _relativeLabel(context, block.updatedAt)
        : DateFormat('MMM d • hh:mm a').format(block.eventAt!);
    final location = (block.locationLabel ?? block.metadata['location'] ?? '')
        .trim();
    final subtitleText = block.subtitle.trim();
    final body = [
      if (subtitleText.isNotEmpty) subtitleText,
      if (location.isNotEmpty && location != subtitleText) location,
    ].join(' · ');
    final day = block.eventAt == null
        ? '--'
        : DateFormat('d').format(block.eventAt!);
    final month = block.eventAt == null
        ? ''
        : DateFormat('MMM').format(block.eventAt!).toUpperCase();
    final palette = context.appPalette;

    return InkWell(
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
      borderRadius: BorderRadius.circular(16),
      child: CollectionsSurfaceCard(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _blockCardHeader(
              context,
              'TIMELINE EVENT',
              trailing: dateTimeLabel,
              block: block,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Column(
                    children: [
                      Text(
                        month,
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'JetBrains Mono',
                          color: palette.textMuted,
                        ),
                      ),
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 23,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                      _blockDescriptionPreview(context, block),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderRow(BuildContext context, CollectionBlockEntity block) {
    final dateLabel = block.eventAt != null
        ? DateFormat('MMM d').format(block.eventAt!).toUpperCase()
        : '';
    final repeat = block.repeatInterval;
    final palette = context.appPalette;
    return InkWell(
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
      borderRadius: BorderRadius.circular(16),
      child: CollectionsSurfaceCard(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _blockCardHeader(
              context,
              'REMINDER',
              block: block,
              trailingWidget: dateLabel.isEmpty
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8890C),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'JetBrains Mono',
                              color: Color(0xFFE8890C),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              block.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            if (repeat != null && repeat.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${context.l10n.collectionEntryReminderRepeat} · $repeat',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ],
            _blockDescriptionPreview(context, block),
          ],
        ),
      ),
    );
  }

  Widget _locationRow(BuildContext context, CollectionBlockEntity block) {
    final subtitle =
        (block.subtitle.trim().isNotEmpty
                ? block.subtitle
                : (block.locationLabel ?? '').trim())
            .trim();
    final palette = context.appPalette;
    return InkWell(
      onTap: () => _openCollectionBlock(context, block),
      onLongPress: () => _showBlockActions(context, block),
      borderRadius: BorderRadius.circular(16),
      child: CollectionsSurfaceCard(
        radius: 16,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              SizedBox(
                height: 118,
                width: double.infinity,
                child: block.latitude != null && block.longitude != null
                    ? StaticMapPreview(
                        latitude: block.latitude!,
                        longitude: block.longitude!,
                        height: 118,
                      )
                    : _locationMapPlaceholder(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    if (collectionBlockHasCustomIcon(block.metadata))
                      buildCollectionBlockLeadingIcon(
                        context,
                        type: block.type,
                        metadata: block.metadata,
                        shellSize: 28,
                        shellRadius: 9,
                        iconSize: 14,
                      )
                    else
                      Icon(
                        Icons.location_on_outlined,
                        color: palette.textMuted,
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            block.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: _itemTitleSize,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: _itemSubtitleSize,
                                fontWeight: FontWeight.w600,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                          _blockDescriptionPreview(context, block),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.collectionDetailOpenInMaps,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'JetBrains Mono',
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addBlock(BuildContext context, String? parentBlockId) async {
    final type = await showCollectionsAddBlockSheet(context);
    if (!context.mounted || type == null) {
      return;
    }
    final block = await Navigator.of(context).push<CollectionBlockEntity>(
      MaterialPageRoute(
        builder: (_) => createCollectionEntryPageForType(
          type: type,
          collectionId: collectionId,
          parentBlockId: parentBlockId,
        ),
      ),
    );
    if (!context.mounted || block == null) {
      return;
    }
    await context.read<CollectionDetailCubit>().saveBlock(block);
  }

  Future<void> _openFolder(BuildContext context, String nestedFolderId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionFolderDetailPage(
          collectionId: collectionId,
          folderId: nestedFolderId,
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<CollectionDetailCubit>().load(
      collectionId: collectionId,
    );
  }

  String _notePreviewText(CollectionBlockEntity block) {
    final description = block.description.trim();
    if (description.isNotEmpty) {
      return description;
    }
    return block.subtitle.trim();
  }

  String _blockDescriptionText(CollectionBlockEntity block) {
    return block.description.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Widget _blockDescriptionPreview(
    BuildContext context,
    CollectionBlockEntity block, {
    int maxLines = 2,
  }) {
    final description = _blockDescriptionText(block);
    if (description.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        description,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: _itemSubtitleSize,
          height: 1.32,
          fontWeight: FontWeight.w500,
          color: context.appPalette.textSecondary,
        ),
      ),
    );
  }

  Future<void> _openCollectionBlock(
    BuildContext context,
    CollectionBlockEntity block,
  ) async {
    if (_isContainerBlock(block)) {
      await _openContainerBlock(context, block);
      return;
    }
    if (block.type == CollectionBlockType.document ||
        block.type == CollectionBlockType.image) {
      await openCollectionFilePreview(context, block);
      return;
    }
    await _editBlock(context, block);
  }

  bool _isContainerBlock(CollectionBlockEntity block) {
    return block.type == CollectionBlockType.folder ||
        block.type == CollectionBlockType.section;
  }

  Future<void> _openContainerBlock(
    BuildContext context,
    CollectionBlockEntity block,
  ) async {
    if (!_isContainerBlock(block)) return;
    await _openFolder(context, block.id);
  }

  void _showBlockActions(BuildContext context, CollectionBlockEntity block) {
    showAdaptiveModal<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final palette = context.appPalette;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.stroke),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isContainerBlock(block))
                    _blockActionRow(
                      context,
                      icon: Icons.open_in_new_rounded,
                      label: context.l10n.tooltipOpenDetails,
                      showChevron: true,
                      onTap: () {
                        Navigator.of(context).pop();
                        _openContainerBlock(context, block);
                      },
                    ),
                  _blockActionRow(
                    context,
                    icon: Icons.edit_rounded,
                    label: context.l10n.commonEdit,
                    showChevron: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      _editBlock(context, block);
                    },
                  ),
                  _blockActionRow(
                    context,
                    icon: Icons.copy_rounded,
                    label: context.l10n.collectionBlockDuplicate,
                    onTap: () {
                      Navigator.of(context).pop();
                      _duplicateBlock(context, block);
                    },
                  ),
                  _blockActionRow(
                    context,
                    icon: Icons.delete_rounded,
                    label: context.l10n.collectionBlockDelete,
                    danger: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      _deleteBlockWithConfirm(context, block);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _blockActionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
    bool showChevron = false,
  }) {
    final palette = context.appPalette;
    final color = danger ? palette.danger : palette.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: danger ? palette.danger : palette.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: palette.textMuted,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _duplicateBlock(
    BuildContext context,
    CollectionBlockEntity block,
  ) async {
    await context.read<CollectionDetailCubit>().duplicateBlock(block.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.collectionBlockDuplicated)),
    );
  }

  Future<void> _deleteBlockWithConfirm(
    BuildContext context,
    CollectionBlockEntity block,
  ) async {
    final confirmed = await _confirmDeleteBlock(context, block);
    if (!context.mounted || confirmed != true) return;
    await context.read<CollectionDetailCubit>().deleteBlock(block.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.collectionBlockDeleted)),
    );
  }

  Future<void> _editBlock(
    BuildContext context,
    CollectionBlockEntity block,
  ) async {
    final updated = await Navigator.of(context).push<CollectionBlockEntity>(
      MaterialPageRoute(
        builder: (_) => createCollectionEntryPageForType(
          type: block.type,
          collectionId: collectionId,
          parentBlockId: block.parentBlockId,
          initialBlock: block,
        ),
      ),
    );
    if (!context.mounted || updated == null) {
      return;
    }
    await context.read<CollectionDetailCubit>().saveBlock(updated);
  }

  Future<bool?> _confirmDeleteBlock(
    BuildContext context,
    CollectionBlockEntity block,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.collectionBlockDelete),
          content: Text(block.title),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                context.l10n.collectionBlockDelete,
                style: TextStyle(color: context.appPalette.danger),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _swipeToDelete(
    BuildContext context,
    CollectionBlockEntity block, {
    required Widget child,
  }) {
    if (_isReorderMode || _reorderingSectionId != null) {
      return child;
    }
    return Dismissible(
      key: ValueKey('collection_block_${block.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async =>
          await _confirmDeleteBlock(context, block) ?? false,
      onDismissed: (_) => _handleSwipeDelete(context, block),
      background: _deleteSwipeBackground(context),
      child: child,
    );
  }

  Widget _deleteSwipeBackground(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(_itemCardRadius),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete_rounded, color: palette.danger, size: 20),
          const SizedBox(width: 8),
          Text(
            context.l10n.collectionBlockDelete,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: palette.danger,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSwipeDelete(
    BuildContext context,
    CollectionBlockEntity block,
  ) async {
    setState(() {
      _pendingDeleteBlockIds.add(block.id);
    });
    try {
      await context.read<CollectionDetailCubit>().deleteBlock(block.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionBlockDeleted)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pendingDeleteBlockIds.remove(block.id);
      });
    }
  }

  Widget _folderDetailHeader(
    BuildContext context,
    String collectionName,
    CollectionBlockEntity folder,
    int childCount,
  ) {
    final palette = context.appPalette;
    final blockKind = folder.type == CollectionBlockType.section
        ? context.l10n.collectionBlockSection
        : context.l10n.collectionBlockFolder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _folderHeaderButton(
              context,
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            if (_isReorderMode)
              _folderHeaderTextButton(
                context,
                label: context.l10n.collectionDashboardDone,
                onTap: () => setState(() => _isReorderMode = false),
              )
            else ...[
              _folderHeaderRoundButton(
                context,
                icon: Icons.add_rounded,
                iconSize: 22,
                onTap: () => _addBlock(context, folder.id),
              ),
              const SizedBox(width: 8),
              _folderHeaderButton(
                context,
                icon: Icons.edit_rounded,
                onTap: () => _editBlock(context, folder),
              ),
              const SizedBox(width: 8),
              _folderHeaderButton(
                context,
                icon: Icons.swap_vert_rounded,
                onTap: () => setState(() {
                  _reorderingSectionId = null;
                  _isReorderMode = true;
                }),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _folderBreadcrumb(context, collectionName, folder.title),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildCollectionBlockLeadingIcon(
              context,
              type: folder.type,
              metadata: folder.metadata,
              shellSize: 48,
              shellRadius: 16,
              iconSize: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      blockKind,
                      context.l10n.collectionDetailItemCount(childCount),
                    ].join(' · ').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'JetBrains Mono',
                      letterSpacing: 1.25,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    folder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.45,
                      color: palette.textPrimary,
                      height: 1.05,
                    ),
                  ),
                  if (folder.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      folder.description.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                        height: 1.15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _folderHeaderRoundButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 20,
  }) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: palette.surface,
            shape: BoxShape.circle,
            border: Border.all(color: palette.stroke),
          ),
          child: Icon(icon, size: iconSize, color: palette.textPrimary),
        ),
      ),
    );
  }

  Widget _folderHeaderTextButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: palette.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: collectionsPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _folderHeaderButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 20, color: palette.textPrimary),
        ),
      ),
    );
  }

  Widget _folderBreadcrumb(
    BuildContext context,
    String collectionName,
    String folderName,
  ) {
    final palette = context.appPalette;
    return Text(
      '$collectionName / $folderName',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        fontFamily: 'JetBrains Mono',
        color: palette.textMuted,
      ),
    );
  }

  Widget _listIconForBlock(BuildContext context, CollectionBlockEntity block) {
    if (collectionBlockHasCustomIcon(block.metadata)) {
      return buildCollectionBlockLeadingIcon(
        context,
        type: block.type,
        metadata: block.metadata,
        shellSize: _itemIconShellSize,
        shellRadius: _itemIconShellRadius,
        iconSize: _itemIconSize,
      );
    }

    if (block.type == CollectionBlockType.document) {
      return _fileTypeIconShell(block.fileType);
    }

    return _typeIconShell(type: block.type);
  }

  Widget _typeIconShell({required CollectionBlockType type}) {
    if (type == CollectionBlockType.input) {
      final palette = context.appPalette;
      return Container(
        width: _itemIconShellSize,
        height: _itemIconShellSize,
        decoration: BoxDecoration(
          color: palette.surfaceSoft,
          borderRadius: BorderRadius.circular(_itemIconShellRadius),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 26,
          height: 17,
          decoration: BoxDecoration(
            color: palette.textSecondary,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: const Text(
            '123',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              fontFamily: 'JetBrains Mono',
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Container(
      width: _itemIconShellSize,
      height: _itemIconShellSize,
      decoration: BoxDecoration(
        color: _iconShellBackground(type),
        borderRadius: BorderRadius.circular(_itemIconShellRadius),
      ),
      alignment: Alignment.center,
      child: Icon(
        _iconForList(type),
        color: _iconColor(type),
        size: _itemIconSize,
      ),
    );
  }

  Widget _fileTypeIconShell(String? rawType) {
    final normalized = (rawType ?? '').trim().toUpperCase();
    final rawLabel = normalized.isEmpty
        ? 'DOC'
        : normalized.split(RegExp(r'\s+')).first;
    final label = rawLabel.length <= 4 ? rawLabel : rawLabel.substring(0, 4);
    final isPdf = label == 'PDF';
    final background = isPdf
        ? const Color(0xFFFFE7EE)
        : const Color(0xFFE8EEFF);
    final foreground = isPdf
        ? const Color(0xFFE34E74)
        : const Color(0xFF2A5CD6);
    return Container(
      width: _itemIconShellSize,
      height: _itemIconShellSize,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(_itemIconShellRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          fontFamily: 'JetBrains Mono',
          letterSpacing: 0.6,
          color: foreground,
        ),
      ),
    );
  }

  IconData _iconForList(CollectionBlockType type) {
    return switch (type) {
      CollectionBlockType.folder => Icons.folder_rounded,
      CollectionBlockType.section => Icons.view_agenda_rounded,
      CollectionBlockType.document => Icons.description_rounded,
      CollectionBlockType.note => Icons.notes_rounded,
      CollectionBlockType.input => Icons.input_rounded,
      CollectionBlockType.checklist => Icons.check_circle_outline_rounded,
      CollectionBlockType.link => Icons.link_rounded,
      CollectionBlockType.image => Icons.image_rounded,
      CollectionBlockType.expense => Icons.payments_rounded,
      CollectionBlockType.timeline => Icons.calendar_month_rounded,
      CollectionBlockType.location => Icons.place_rounded,
      CollectionBlockType.reminder => Icons.notifications_rounded,
      CollectionBlockType.progress => Icons.donut_small_rounded,
    };
  }

  Color _iconShellBackground(CollectionBlockType type) {
    return switch (type) {
      CollectionBlockType.folder => const Color(0xFFE8EEFF),
      CollectionBlockType.section => const Color(0xFFE8ECF4),
      CollectionBlockType.document => const Color(0xFFF0F3F8),
      CollectionBlockType.note => const Color(0xFFE8F0FF),
      CollectionBlockType.input => const Color(0xFFF2F4F8),
      CollectionBlockType.checklist => const Color(0xFFE5F8EC),
      CollectionBlockType.link => const Color(0xFFFDE8EA),
      CollectionBlockType.image => const Color(0xFFFDECF3),
      CollectionBlockType.expense => const Color(0xFFE2F6EC),
      CollectionBlockType.timeline => const Color(0xFFEDECFF),
      CollectionBlockType.location => const Color(0xFFEAF0FF),
      CollectionBlockType.reminder => const Color(0xFFFFF3E0),
      CollectionBlockType.progress => const Color(0xFFE8F0FF),
    };
  }

  Color _iconColor(CollectionBlockType type) {
    return switch (type) {
      CollectionBlockType.folder => const Color(0xFF2A5CD6),
      CollectionBlockType.section => const Color(0xFF5C6F8A),
      CollectionBlockType.document => const Color(0xFF5C6E89),
      CollectionBlockType.note => const Color(0xFF3367E8),
      CollectionBlockType.input => const Color(0xFF7889A6),
      CollectionBlockType.checklist => const Color(0xFF1AA75F),
      CollectionBlockType.link => const Color(0xFFE7453F),
      CollectionBlockType.image => const Color(0xFFE55B87),
      CollectionBlockType.expense => const Color(0xFF13A567),
      CollectionBlockType.timeline => const Color(0xFF5A55E5),
      CollectionBlockType.location => const Color(0xFF3D79EA),
      CollectionBlockType.reminder => const Color(0xFFE8890C),
      CollectionBlockType.progress => const Color(0xFF3B6DE8),
    };
  }

  Widget _linkLeadingIcon(
    BuildContext context,
    CollectionBlockEntity block,
    AppPalette palette,
  ) {
    if (collectionBlockHasCustomIcon(block.metadata)) {
      return buildCollectionBlockLeadingIcon(
        context,
        type: block.type,
        metadata: block.metadata,
        shellSize: 56,
        shellRadius: 14,
        iconSize: 22,
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            blockColor(CollectionBlockType.link).withValues(alpha: 0.22),
            palette.surfaceSoft,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.link_rounded,
        color: blockColor(CollectionBlockType.link),
        size: 25,
      ),
    );
  }

  Widget _resolveImageWidget(String? url, {required Widget fallback}) {
    final trimmed = (url ?? '').trim();
    if (trimmed.isEmpty) {
      return fallback;
    }

    if (trimmed.startsWith('/') || trimmed.startsWith('file://')) {
      final provider = resolveLocalFileImageProvider(trimmed);
      if (provider != null) {
        return Image(
          image: provider,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      }
      return fallback;
    }

    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      headers: const {'User-Agent': 'Credence/1.0'},
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _imagePlaceholder() {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.surfaceSoft, palette.stroke],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.image_rounded, size: 36, color: palette.textMuted),
    );
  }

  Widget _locationMapPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC7E0D1), Color(0xFFE7F1EA)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.map_rounded, size: 34, color: Color(0xFF7EA58E)),
    );
  }

  String _domainFromUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return value;
    }
    final host = uri.host.trim();
    if (host.isEmpty) {
      return value;
    }
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  String _expenseAmountLabel(CollectionBlockEntity block) {
    final amount = block.amount;
    final currency = (block.currencyCode ?? '').trim().toUpperCase();
    if (amount == null) {
      return currency.isEmpty
          ? '0'
          : NumberFormat.simpleCurrency(
              name: currency,
              decimalDigits: 0,
            ).format(0);
    }
    final integer = amount.truncateToDouble() == amount;
    if (currency.isEmpty) {
      return integer ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
    }
    return NumberFormat.simpleCurrency(
      name: currency,
      decimalDigits: integer ? 0 : 2,
    ).format(amount);
  }

  Widget _emptyInlineCard(String label) {
    return CollectionsSurfaceCard(
      radius: _itemCardRadius,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: context.appPalette.textSecondary,
        ),
      ),
    );
  }
}
