import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/vault_error_state.dart';
import 'package:pass_doc_manager/app/presentation/widgets/credence_ui.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/constants/internal_collection_ids.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';
import 'package:pass_doc_manager/domain/collections/usecases/get_collections.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_summary_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_expiry_item_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_recent_activity_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_library_overview.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collections_list_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/document_library_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/document_library_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/identity_document_entry_page.dart';
import 'package:pass_doc_manager/features/notes/presentation/pages/secure_notes_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

const String _documentsFontDisplay = 'Manrope';
const String _documentsFontBody = 'Manrope';
const String _documentsFontMono = 'JetBrains Mono';

class DocumentsLibraryPage extends StatelessWidget {
  const DocumentsLibraryPage({
    super.key,
    GetDocumentLibraryOverview? getOverview,
    GetCollections? getCollections,
    this.embeddedDesktop = false,
    this.onCategoryTap,
    this.onCollectionsTap,
    this.onCollectionTap,
    this.onBundlesTap,
    this.onTasksTap,
    this.onSecureNotesTap,
    this.onSyncNowTap,
  }) : _getOverview = getOverview,
       _getCollections = getCollections;

  final GetDocumentLibraryOverview? _getOverview;
  final GetCollections? _getCollections;
  final bool embeddedDesktop;
  final ValueChanged<DocumentCategoryType>? onCategoryTap;
  final VoidCallback? onCollectionsTap;
  final ValueChanged<String>? onCollectionTap;
  final VoidCallback? onBundlesTap;
  final VoidCallback? onTasksTap;
  final VoidCallback? onSecureNotesTap;
  final VoidCallback? onSyncNowTap;

  @override
  Widget build(BuildContext context) {
    final content = BlocProvider(
      create: (_) => DocumentLibraryCubit(getOverview: _getOverview)..load(),
      child: _DocumentsLibraryView(
        embeddedDesktop: embeddedDesktop,
        getCollections: _getCollections,
        onCategoryTap: onCategoryTap,
        onCollectionsTap: onCollectionsTap,
        onCollectionTap: onCollectionTap,
        onBundlesTap: onBundlesTap,
        onTasksTap: onTasksTap,
        onSecureNotesTap: onSecureNotesTap,
        onSyncNowTap: onSyncNowTap,
      ),
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

class _DocumentsLibraryView extends StatelessWidget {
  const _DocumentsLibraryView({
    required this.embeddedDesktop,
    required this.getCollections,
    required this.onCategoryTap,
    required this.onCollectionsTap,
    required this.onCollectionTap,
    required this.onBundlesTap,
    required this.onTasksTap,
    required this.onSecureNotesTap,
    required this.onSyncNowTap,
  });

  final bool embeddedDesktop;
  final GetCollections? getCollections;
  final ValueChanged<DocumentCategoryType>? onCategoryTap;
  final VoidCallback? onCollectionsTap;
  final ValueChanged<String>? onCollectionTap;
  final VoidCallback? onBundlesTap;
  final VoidCallback? onTasksTap;
  final VoidCallback? onSecureNotesTap;
  final VoidCallback? onSyncNowTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return BlocBuilder<DocumentLibraryCubit, DocumentLibraryState>(
      builder: (context, state) {
        final overview = state.overview;

        if (overview == null &&
            (state.viewStatus == DocumentLibraryViewStatus.loading ||
                state.viewStatus == DocumentLibraryViewStatus.initial)) {
          return const Center(child: CupertinoActivityIndicator(radius: 12));
        }

        if (overview == null &&
            state.viewStatus == DocumentLibraryViewStatus.error) {
          return VaultErrorState(
            icon: Icons.folder_off_rounded,
            message: state.errorMessage ?? context.l10n.documentsErrorLoad,
            onRetry: () => context.read<DocumentLibraryCubit>().load(),
          );
        }

        final data = overview;
        if (data == null) {
          return const SizedBox.shrink();
        }

        final identity = _summaryFor(
          data.categories,
          DocumentCategoryType.identity,
        );
        final work = _summaryFor(data.categories, DocumentCategoryType.work);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = embeddedDesktop || constraints.maxWidth >= 760;
            final horizontal = embeddedDesktop ? 26.0 : 20.0;
            final maxWidth = embeddedDesktop ? 1120.0 : 760.0;

            return RefreshIndicator(
              color: palette.primary,
              onRefresh: () => context.read<DocumentLibraryCubit>().load(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  embeddedDesktop ? horizontal : 0,
                  embeddedDesktop ? 22 : 12,
                  embeddedDesktop ? horizontal : 0,
                  embeddedDesktop ? 34 : 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: embeddedDesktop ? 0 : 22,
                          ),
                          child: _DocumentsLibraryHeader(
                            totalDocuments: data.totalDocumentsCount,
                            expiringSoonCount: state.expiringDocuments.length,
                            embeddedDesktop: embeddedDesktop,
                            onAddTap: () => _openAddDocument(context),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ReferenceSectionLabel(
                          label: 'Categories · 2',
                          embeddedDesktop: embeddedDesktop,
                        ),
                        const SizedBox(height: 8),
                        _PrimaryCategoryPair(
                          identity: identity,
                          work: work,
                          isWide: isWide,
                          onCategoryTap: onCategoryTap,
                          embeddedDesktop: embeddedDesktop,
                        ),
                        _CollectionsPreviewSection(
                          getCollections: getCollections,
                          embeddedDesktop: embeddedDesktop,
                          onCollectionTap: onCollectionTap,
                          onViewAllTap: onCollectionsTap,
                        ),
                        if (_hasShortcutEntries) ...[
                          const SizedBox(height: 14),
                          _ReferenceSectionLabel(
                            label: 'Workspaces',
                            embeddedDesktop: embeddedDesktop,
                          ),
                          const SizedBox(height: 8),
                          _DocumentShortcutGrid(
                            embeddedDesktop: embeddedDesktop,
                            onCollectionsTap: onCollectionsTap,
                            onBundlesTap: onBundlesTap,
                            onTasksTap: onTasksTap,
                            onSecureNotesTap: onSecureNotesTap,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _ExpiringSoonSection(
                          documents: state.expiringDocuments
                              .take(2)
                              .toList(growable: false),
                          embeddedDesktop: embeddedDesktop,
                          onTap: (document) =>
                              _openDocumentDetail(context, document.documentId),
                        ),
                        const SizedBox(height: 14),
                        _RecentFilesSection(
                          items: data.recentActivity
                              .take(4)
                              .toList(growable: false),
                          embeddedDesktop: embeddedDesktop,
                          onTap: (item) =>
                              _openDocumentDetail(context, item.documentId),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool get _hasShortcutEntries => true;

  DocumentCategorySummaryEntity _summaryFor(
    List<DocumentCategorySummaryEntity> categories,
    DocumentCategoryType type,
  ) {
    for (final category in categories) {
      if (category.category == type) {
        return category;
      }
    }
    return DocumentCategorySummaryEntity(
      category: type,
      documentsCount: 0,
      actionRequiredCount: 0,
    );
  }

  Future<void> _openAddDocument(BuildContext context) async {
    final createdId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            const IdentityDocumentEntryPage(initialType: DocumentType.passport),
      ),
    );
    if (!context.mounted) return;
    if (createdId != null && createdId.trim().isNotEmpty) {
      await context.read<DocumentLibraryCubit>().load();
    }
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
    await context.read<DocumentLibraryCubit>().load();
  }
}

class _DocumentsLibraryHeader extends StatelessWidget {
  const _DocumentsLibraryHeader({
    required this.totalDocuments,
    required this.expiringSoonCount,
    required this.embeddedDesktop,
    required this.onAddTap,
  });

  final int totalDocuments;
  final int expiringSoonCount;
  final bool embeddedDesktop;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.l10n.documentsFilesCompact(totalDocuments)} · $expiringSoonCount expiring soon',
                style: TextStyle(
                  fontFamily: _documentsFontMono,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.navDocuments,
                style: TextStyle(
                  fontFamily: _documentsFontDisplay,
                  fontSize: embeddedDesktop ? 40 : 38,
                  height: 0.98,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.45,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
        _DocumentsReferenceIconButton(
          icon: Icons.add_rounded,
          onTap: onAddTap,
          tooltip: context.l10n.addDocumentTitle,
        ),
      ],
    );
  }
}

class _DocumentsReferenceIconButton extends StatelessWidget {
  const _DocumentsReferenceIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final button = Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: palette.stroke),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 21, color: palette.textPrimary),
        ),
      ),
    );
    if ((tooltip ?? '').trim().isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _ReferenceSectionLabel extends StatelessWidget {
  const _ReferenceSectionLabel({
    required this.label,
    required this.embeddedDesktop,
  });

  final String label;
  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: embeddedDesktop ? 0 : 22),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: _documentsFontMono,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.4,
          color: context.appPalette.textMuted,
        ),
      ),
    );
  }
}

class _PrimaryCategoryPair extends StatelessWidget {
  const _PrimaryCategoryPair({
    required this.identity,
    required this.work,
    required this.isWide,
    required this.onCategoryTap,
    required this.embeddedDesktop,
  });

  final DocumentCategorySummaryEntity identity;
  final DocumentCategorySummaryEntity work;
  final bool isWide;
  final ValueChanged<DocumentCategoryType>? onCategoryTap;
  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _CategoryHeroTile(
        category: identity,
        minHeight: 178,
        onTap: () => onCategoryTap?.call(DocumentCategoryType.identity),
      ),
      _CategoryHeroTile(
        category: work,
        minHeight: 178,
        onTap: () => onCategoryTap?.call(DocumentCategoryType.work),
      ),
    ];

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: tiles[0]),
          const SizedBox(width: 12),
          Expanded(child: tiles[1]),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!embeddedDesktop) const SizedBox(width: 22),
        Expanded(child: tiles[0]),
        const SizedBox(width: 10),
        Expanded(child: tiles[1]),
        if (!embeddedDesktop) const SizedBox(width: 22),
      ],
    );
  }
}

class _CategoryHeroTile extends StatelessWidget {
  const _CategoryHeroTile({
    required this.category,
    required this.minHeight,
    required this.onTap,
  });

  final DocumentCategorySummaryEntity category;
  final double minHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final scheme = _categoryVisual(category.category);
    final accent = scheme.iconColor;
    final documentsLabel = context.l10n.documentsFilesCompact(
      category.documentsCount,
    );
    final meta = category.hasActionRequired
        ? '${category.documentsCount} DOCS · ${category.actionRequiredCount} EXPIRING'
        : category.category == DocumentCategoryType.work
        ? _workCategoryMeta(context)
        : documentsLabel.toUpperCase();

    return CredenceCard(
      onTap: onTap,
      radius: 22,
      padding: const EdgeInsets.all(14),
      backgroundColor: _referenceTint(
        context,
        scheme.cardBackground,
        accent,
        darkAlpha: 0.18,
      ),
      borderColor: Colors.transparent,
      child: SizedBox(
        height: minHeight - 28,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                '${_categoryTitle(context, category.category).toUpperCase()} · ${category.documentsCount}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _documentsFontMono,
                  fontSize: 10.5,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.15,
                  color: accent,
                ),
              ),
            ),
            Positioned.fill(
              top: 30,
              bottom: 52,
              child: Center(
                child: _MiniDocumentStack(
                  category: category.category,
                  accent: accent,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _categoryTitle(context, category.category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _documentsFontDisplay,
                      fontSize: 16,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.25,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _documentsFontMono,
                      fontSize: 10.2,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.65,
                      color: palette.textSecondary,
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

class _MiniDocumentStack extends StatelessWidget {
  const _MiniDocumentStack({required this.category, required this.accent});

  final DocumentCategoryType category;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final labels = category == DocumentCategoryType.identity
        ? const ['ID FR', 'PDF', 'JPEG']
        : const ['PDF', 'PDF', 'PDF'];
    return SizedBox(
      height: 58,
      width: 104,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 50,
            top: 8,
            child: _MiniDocument(
              label: labels[2],
              accent: accent.withValues(alpha: 0.82),
              isImage: category == DocumentCategoryType.identity,
              rotation: 8,
            ),
          ),
          Positioned(
            left: 27,
            top: 3,
            child: _MiniDocument(
              label: labels[1],
              accent: accent.withValues(alpha: 0.9),
              rotation: 2,
            ),
          ),
          Positioned(
            left: 4,
            top: 0,
            child: _MiniDocument(
              label: labels[0],
              accent: accent,
              rotation: -7,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDocument extends StatelessWidget {
  const _MiniDocument({
    required this.label,
    required this.accent,
    this.isImage = false,
    this.rotation = 0,
  });

  final String label;
  final Color accent;
  final bool isImage;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Transform.rotate(
      angle: rotation * 0.0174533,
      child: Container(
        width: 46,
        height: 58,
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.stroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isImage)
              Center(child: Icon(Icons.image_outlined, size: 18, color: accent))
            else ...[
              Positioned(
                left: 8,
                right: 8,
                top: 12,
                child: Container(height: 3, color: palette.textMuted),
              ),
              Positioned(
                left: 8,
                right: 10,
                top: 21,
                child: Container(
                  height: 2,
                  color: palette.stroke.withValues(alpha: 0.6),
                ),
              ),
              Positioned(
                left: 8,
                right: 14,
                top: 28,
                child: Container(
                  height: 2,
                  color: palette.stroke.withValues(alpha: 0.6),
                ),
              ),
            ],
            Positioned(
              left: 5,
              right: 5,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _documentsFontMono,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionsPreviewSection extends StatefulWidget {
  const _CollectionsPreviewSection({
    required this.getCollections,
    required this.embeddedDesktop,
    required this.onCollectionTap,
    required this.onViewAllTap,
  });

  final GetCollections? getCollections;
  final bool embeddedDesktop;
  final ValueChanged<String>? onCollectionTap;
  final VoidCallback? onViewAllTap;

  @override
  State<_CollectionsPreviewSection> createState() =>
      _CollectionsPreviewSectionState();
}

class _CollectionsPreviewSectionState
    extends State<_CollectionsPreviewSection> {
  late Future<List<CollectionEntity>> _collectionsFuture;

  @override
  void initState() {
    super.initState();
    _collectionsFuture = _loadCollections();
  }

  @override
  void didUpdateWidget(covariant _CollectionsPreviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.getCollections != widget.getCollections) {
      _collectionsFuture = _loadCollections();
    }
  }

  Future<List<CollectionEntity>> _loadCollections() async {
    try {
      final getCollections = widget.getCollections ?? getIt<GetCollections>();
      final collections = await getCollections(const GetCollectionsParams());
      return collections
          .where(
            (collection) => collection.id != internalSecureNotesCollectionId,
          )
          .toList(growable: false);
    } catch (_) {
      return const <CollectionEntity>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CollectionEntity>>(
      future: _collectionsFuture,
      builder: (context, snapshot) {
        final collections = snapshot.data ?? const <CollectionEntity>[];
        if (collections.isEmpty) {
          return const SizedBox.shrink();
        }

        final preview = collections.take(6).toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.embeddedDesktop ? 0 : 22,
              ),
              child: _PlainSectionLabel(
                label:
                    '${context.l10n.collectionsTitle} · ${collections.length}',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.embeddedDesktop ? 0 : 22,
              ),
              child: _CollectionsPreviewList(
                collections: preview,
                totalCount: collections.length,
                onCollectionTap: widget.onCollectionTap,
                onViewAllTap: widget.onViewAllTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CollectionsPreviewList extends StatelessWidget {
  const _CollectionsPreviewList({
    required this.collections,
    required this.totalCount,
    required this.onCollectionTap,
    required this.onViewAllTap,
  });

  final List<CollectionEntity> collections;
  final int totalCount;
  final ValueChanged<String>? onCollectionTap;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int index = 0; index < collections.length; index++) ...[
            _CollectionPreviewRow(
              collection: collections[index],
              onTap: onCollectionTap == null
                  ? null
                  : () => onCollectionTap!(collections[index].id),
            ),
            if (index != collections.length - 1)
              Divider(height: 1, color: palette.stroke),
          ],
          if (onViewAllTap != null) ...[
            Divider(height: 1, color: palette.stroke),
            _ViewAllCollectionsRow(
              totalCount: totalCount,
              onTap: onViewAllTap!,
            ),
          ],
        ],
      ),
    );
  }
}

class _CollectionPreviewRow extends StatelessWidget {
  const _CollectionPreviewRow({required this.collection, required this.onTap});

  final CollectionEntity collection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final accent = _collectionAccentFromHex(collection.accentColorHex);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              buildCollectionLeadingIcon(
                context,
                iconKey: collection.iconKey,
                iconEmoji: collection.iconEmoji,
                iconImagePath: collection.iconImagePath,
                accent: accent,
                shellSize: 32,
                shellRadius: 9,
                iconSize: 17,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  collection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _documentsFontDisplay,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.08,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _CollectionPreviewMeta(collection: collection),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionPreviewMeta extends StatelessWidget {
  const _CollectionPreviewMeta({required this.collection});

  final CollectionEntity collection;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final count = collection.totalItemsCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (collection.isPinLocked) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 10,
                  color: palette.textPrimary,
                ),
                const SizedBox(width: 3),
                Text(
                  'PIN',
                  style: TextStyle(
                    fontFamily: _documentsFontMono,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          count == 1 ? '1 ITEM' : '$count ITEMS',
          style: TextStyle(
            fontFamily: _documentsFontMono,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ViewAllCollectionsRow extends StatelessWidget {
  const _ViewAllCollectionsRow({required this.totalCount, required this.onTap});

  final int totalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: palette.surfaceSoft.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'VIEW ALL $totalCount',
                  style: TextStyle(
                    fontFamily: _documentsFontMono,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                    color: palette.textMuted,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentShortcutGrid extends StatelessWidget {
  const _DocumentShortcutGrid({
    required this.embeddedDesktop,
    required this.onCollectionsTap,
    required this.onBundlesTap,
    required this.onTasksTap,
    required this.onSecureNotesTap,
  });

  final bool embeddedDesktop;
  final VoidCallback? onCollectionsTap;
  final VoidCallback? onBundlesTap;
  final VoidCallback? onTasksTap;
  final VoidCallback? onSecureNotesTap;

  @override
  Widget build(BuildContext context) {
    final openCollections =
        onCollectionsTap ??
        () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CollectionsListPage(),
            ),
          );
        };
    final entries = <_ShortcutData>[
      if (!embeddedDesktop)
        _ShortcutData(
          title: context.l10n.collectionsTitle,
          subtitle: context.l10n.documentsCollectionsEntrySubtitle,
          icon: Icons.folder_copy_outlined,
          accent: const Color(0xFF2563EB),
          softColor: const Color(0xFFEAF0FF),
          onTap: openCollections,
        ),
      _ShortcutData(
        title: context.l10n.secureNotesTitle,
        subtitle: context.l10n.secureNotesSubtitle,
        icon: Icons.sticky_note_2_outlined,
        accent: const Color(0xFF2F2A3A),
        softColor: const Color(0xFFF1EDF7),
        onTap:
            onSecureNotesTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SecureNotesPage(),
                ),
              );
            },
      ),
      if (!embeddedDesktop && onBundlesTap != null)
        _ShortcutData(
          title: context.l10n.bundlesTitle,
          subtitle: context.l10n.documentsBundlesEntrySubtitle,
          icon: Icons.folder_zip_rounded,
          accent: const Color(0xFF8A5A13),
          softColor: const Color(0xFFFFF0DF),
          onTap: onBundlesTap!,
        ),
      if (!embeddedDesktop && onTasksTap != null)
        _ShortcutData(
          title: context.l10n.tasksTitle,
          subtitle: context.l10n.documentsTasksEntrySubtitle,
          icon: Icons.checklist_rounded,
          accent: const Color(0xFF6D6250),
          softColor: const Color(0xFFF6F1E3),
          onTap: onTasksTap!,
        ),
    ];

    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: embeddedDesktop ? 0 : 22),
      child: _WorkspaceRows(entries: entries),
    );
  }
}

class _WorkspaceRows extends StatelessWidget {
  const _WorkspaceRows({required this.entries});

  final List<_ShortcutData> entries;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        children: [
          for (int index = 0; index < entries.length; index++) ...[
            if (index != 0)
              Divider(
                height: 1,
                thickness: 1,
                color: palette.stroke.withValues(alpha: 0.6),
              ),
            _WorkspaceRow(data: entries[index]),
          ],
        ],
      ),
    );
  }
}

class _WorkspaceRow extends StatelessWidget {
  const _WorkspaceRow({required this.data});

  final _ShortcutData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _referenceTint(context, data.softColor, data.accent),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(data.icon, color: data.accent, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _documentsFontDisplay,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.12,
                  color: palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ExpiringSoonSection extends StatelessWidget {
  const _ExpiringSoonSection({
    required this.documents,
    required this.embeddedDesktop,
    required this.onTap,
  });

  final List<DocumentExpiryItemEntity> documents;
  final bool embeddedDesktop;
  final ValueChanged<DocumentExpiryItemEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: embeddedDesktop ? 0 : 22),
          child: _PlainSectionLabel(
            label: 'Expiring soon · ${documents.length}',
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: embeddedDesktop ? 0 : 22),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.stroke),
            ),
            child: documents.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _ExpiryGlyph(
                          urgency: ExpiryUrgency.safe,
                          backgroundColor: palette.surfaceSoft,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No documents expiring soon',
                            style: TextStyle(
                              fontFamily: _documentsFontBody,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      for (
                        int index = 0;
                        index < documents.length;
                        index++
                      ) ...[
                        if (index != 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: palette.stroke.withValues(alpha: 0.6),
                          ),
                        _ExpiryRow(
                          document: documents[index],
                          onTap: () => onTap(documents[index]),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ExpiryRow extends StatelessWidget {
  const _ExpiryRow({required this.document, required this.onTap});

  final DocumentExpiryItemEntity document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _ExpiryGlyph(
              urgency: document.urgency,
              backgroundColor: _expiryTint(context, document.urgency),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${document.documentType} · ${document.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _documentsFontDisplay,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.08,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _expiryMeta(context, document),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _documentsFontMono,
                      fontSize: 9.8,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.85,
                      color: _expiryColor(document.urgency),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ExpiryGlyph extends StatelessWidget {
  const _ExpiryGlyph({required this.urgency, required this.backgroundColor});

  final ExpiryUrgency urgency;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        urgency == ExpiryUrgency.safe
            ? Icons.check_circle_outline_rounded
            : Icons.schedule_rounded,
        size: 18,
        color: _expiryColor(urgency),
      ),
    );
  }
}

class _PlainSectionLabel extends StatelessWidget {
  const _PlainSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: _documentsFontMono,
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.1,
        color: context.appPalette.textMuted,
      ),
    );
  }
}

class _RecentFilesSection extends StatelessWidget {
  const _RecentFilesSection({
    required this.items,
    required this.embeddedDesktop,
    required this.onTap,
  });

  final List<DocumentRecentActivityEntity> items;
  final bool embeddedDesktop;
  final ValueChanged<DocumentRecentActivityEntity> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: embeddedDesktop ? 0 : 22),
          child: _PlainSectionLabel(
            label:
                '${context.l10n.documentsRecentFilesTitle} · ${items.length}',
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: embeddedDesktop ? 0 : 22),
            child: _ActivityEmptyCard(),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: embeddedDesktop ? 0 : 22),
            child: Column(
              children: [
                for (int index = 0; index < items.length; index++) ...[
                  _RecentFileRow(
                    item: items[index],
                    onTap: () => onTap(items[index]),
                    showTopDivider: index != 0,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentFileRow extends StatelessWidget {
  const _RecentFileRow({
    required this.item,
    required this.onTap,
    required this.showTopDivider,
  });

  final DocumentRecentActivityEntity item;
  final VoidCallback onTap;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final scheme = _categoryVisual(item.category);
    final extension = _fileExtensionLabel(item.fileName);
    return Padding(
      padding: EdgeInsets.only(top: showTopDivider ? 8 : 0),
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.stroke),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _DocumentFileThumb(
                  extension: extension,
                  accent: _isImageFile(item.fileName)
                      ? const Color(0xFF187C63)
                      : scheme.iconColor,
                  isImage: _isImageFile(item.fileName),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _documentsFontDisplay,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.18,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        [
                          _categoryTitle(context, item.category),
                          if (item.filesCount > 1)
                            context.l10n.documentFilesCount(item.filesCount),
                          _compactRelativeLabel(context, item.updatedAt),
                        ].join('  ·  ').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _documentsFontMono,
                          fontSize: 10.2,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.9,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentFileThumb extends StatelessWidget {
  const _DocumentFileThumb({
    required this.extension,
    required this.accent,
    required this.isImage,
  });

  final String extension;
  final Color accent;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox(
      width: 52,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 42,
            height: 52,
            decoration: BoxDecoration(
              color: isImage
                  ? _referenceTint(
                      context,
                      const Color(0xFFE7F6EF),
                      const Color(0xFF187C63),
                    )
                  : palette.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.stroke),
            ),
            child: isImage
                ? Icon(Icons.image_outlined, color: accent, size: 22)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 26, height: 4, color: palette.textMuted),
                      const SizedBox(height: 5),
                      Container(
                        width: 24,
                        height: 2,
                        color: palette.stroke.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 22,
                        height: 2,
                        color: palette.stroke.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
          ),
          if (!isImage)
            Positioned(
              left: 5,
              right: 5,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
                child: Text(
                  extension,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _documentsFontMono,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityEmptyCard extends StatelessWidget {
  const _ActivityEmptyCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Text(
        context.l10n.documentsNoRecentActivity,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}

class _ShortcutData {
  const _ShortcutData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.softColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color softColor;
  final VoidCallback onTap;
}

String _workCategoryMeta(BuildContext context) {
  return [context.l10n.documentsCategorySubtitleWork].join().toUpperCase();
}

Color _collectionAccentFromHex(String hex) {
  final normalized = hex.replaceAll('#', '').trim();
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return collectionsPrimary;
  }
  return Color(0xFF000000 | value);
}

Color _expiryColor(ExpiryUrgency urgency) {
  return switch (urgency) {
    ExpiryUrgency.expired => const Color(0xFFD13B2F),
    ExpiryUrgency.critical => const Color(0xFFD13B2F),
    ExpiryUrgency.warning => const Color(0xFFB27400),
    ExpiryUrgency.safe => const Color(0xFF148F5D),
  };
}

Color _expiryTint(BuildContext context, ExpiryUrgency urgency) {
  final color = switch (urgency) {
    ExpiryUrgency.expired || ExpiryUrgency.critical => const Color(0xFFFFECE9),
    ExpiryUrgency.warning => const Color(0xFFFFF1D8),
    ExpiryUrgency.safe => const Color(0xFFE7F6EF),
  };
  return _referenceTint(context, color, _expiryColor(urgency));
}

String _expiryMeta(BuildContext context, DocumentExpiryItemEntity document) {
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  final date = DateFormat.MMMd(localeTag).format(document.expiryDate);
  final days = document.daysRemaining;
  if (document.urgency == ExpiryUrgency.expired || (days != null && days < 0)) {
    return 'EXPIRED $date · RENEW';
  }
  if (days == null) return 'EXPIRES $date';
  if (days == 0) return 'EXPIRES TODAY · RENEW';
  return 'EXPIRES $date · $days D LEFT';
}

String _compactRelativeLabel(BuildContext context, DateTime value) {
  final now = DateTime.now();
  final delta = now.difference(value);
  if (delta.inMinutes < 1) {
    return context.l10n.documentsRelativeJustNow;
  }
  if (delta.inMinutes < 60) {
    return '${delta.inMinutes}m ago';
  }
  if (delta.inHours < 24) {
    return '${delta.inHours}h ago';
  }
  if (delta.inDays == 1) {
    return context.l10n.documentsRelativeYesterday;
  }
  return '${delta.inDays}d ago';
}

String _fileExtensionLabel(String fileName) {
  final normalized = fileName.trim().toLowerCase();
  final dotIndex = normalized.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == normalized.length - 1) {
    return 'DOC';
  }
  final extension = normalized.substring(dotIndex + 1);
  if (_isImageExtension(extension)) return 'IMG';
  if (extension.length > 4) return extension.substring(0, 4).toUpperCase();
  return extension.toUpperCase();
}

bool _isImageFile(String fileName) {
  final normalized = fileName.trim().toLowerCase();
  final dotIndex = normalized.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == normalized.length - 1) return false;
  return _isImageExtension(normalized.substring(dotIndex + 1));
}

bool _isImageExtension(String extension) {
  return switch (extension) {
    'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' || 'gif' => true,
    _ => false,
  };
}

Color _referenceTint(
  BuildContext context,
  Color lightColor,
  Color accent, {
  double darkAlpha = 0.18,
}) {
  final palette = context.appPalette;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (!isDark) return lightColor;
  return Color.alphaBlend(accent.withValues(alpha: darkAlpha), palette.surface);
}

_CategoryVisual _categoryVisual(DocumentCategoryType category) {
  return switch (category) {
    DocumentCategoryType.identity => const _CategoryVisual(
      cardBackground: Color(0xFFFFEEF1),
      iconBackground: Color(0xFFFFF7F8),
      iconColor: Color(0xFF7B3341),
      icon: Icons.person_outline_rounded,
    ),
    DocumentCategoryType.work => const _CategoryVisual(
      cardBackground: Color(0xFFF0ECFF),
      iconBackground: Color(0xFFFAF8FF),
      iconColor: Color(0xFF5B45B8),
      icon: Icons.work_outline_rounded,
    ),
    DocumentCategoryType.property => const _CategoryVisual(
      cardBackground: Color(0xFFFCF7E9),
      iconBackground: Color(0xFFF5EFDE),
      iconColor: Color(0xFFD97706),
      icon: Icons.home_rounded,
    ),
    DocumentCategoryType.vehicle => const _CategoryVisual(
      cardBackground: Color(0xFFF5F7FA),
      iconBackground: Color(0xFFF2F4F8),
      iconColor: Color(0xFF64748B),
      icon: Icons.directions_car_rounded,
    ),
    DocumentCategoryType.health => const _CategoryVisual(
      cardBackground: Color(0xFFFFF1F3),
      iconBackground: Color(0xFFFCECEF),
      iconColor: Color(0xFFE11D48),
      icon: Icons.medical_services_rounded,
    ),
    DocumentCategoryType.travel => const _CategoryVisual(
      cardBackground: Color(0xFFF0F4FF),
      iconBackground: Color(0xFFEAF0FF),
      iconColor: Color(0xFF2563EB),
      icon: Icons.flight_takeoff_rounded,
    ),
    DocumentCategoryType.other => const _CategoryVisual(
      cardBackground: Color(0xFFF6F8FB),
      iconBackground: Color(0xFFEEF2F7),
      iconColor: Color(0xFF64748B),
      icon: Icons.folder_rounded,
    ),
  };
}

String _categoryTitle(BuildContext context, DocumentCategoryType category) {
  return switch (category) {
    DocumentCategoryType.identity => context.l10n.documentsCategoryIdentity,
    DocumentCategoryType.work => context.l10n.documentsCategoryWork,
    DocumentCategoryType.property => context.l10n.documentsCategoryProperty,
    DocumentCategoryType.vehicle => context.l10n.documentsCategoryAuto,
    DocumentCategoryType.health => context.l10n.documentsCategoryHealth,
    DocumentCategoryType.travel => context.l10n.documentsCategoryTravel,
    DocumentCategoryType.other => context.l10n.documentsCategoryOther,
  };
}

class _CategoryVisual {
  const _CategoryVisual({
    required this.cardBackground,
    required this.iconBackground,
    required this.iconColor,
    required this.icon,
  });

  final Color cardBackground;
  final Color iconBackground;
  final Color iconColor;
  final IconData icon;
}
