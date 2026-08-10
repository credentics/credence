import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_checklist_item_entity.dart';
import 'package:pass_doc_manager/features/collections/presentation/cubit/collection_detail_cubit.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_add_block_pages.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_folder_detail_page.dart';
import 'package:pass_doc_manager/features/collections/presentation/services/link_preview_service.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/static_map_preview.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_file_preview_page.dart';
import 'package:pass_doc_manager/features/notes/presentation/support/note_markdown_support.dart';
import 'package:pass_doc_manager/features/notes/presentation/widgets/note_markdown_view.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';

class CollectionBlockDetailResult {
  const CollectionBlockDetailResult({this.updatedBlock, this.deleted = false});

  final CollectionBlockEntity? updatedBlock;
  final bool deleted;
}

class CollectionBlockDetailPage extends StatefulWidget {
  const CollectionBlockDetailPage({
    super.key,
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;

  @override
  State<CollectionBlockDetailPage> createState() =>
      _CollectionBlockDetailPageState();
}

class _CollectionBlockDetailPageState extends State<CollectionBlockDetailPage> {
  late CollectionBlockEntity block;
  String? _linkPreviewImage;
  bool _linkPreviewLoading = false;

  String get collectionId => widget.collectionId;

  @override
  void initState() {
    super.initState();
    block = widget.block;
    if (block.type == CollectionBlockType.link) {
      _fetchLinkPreview();
    }
  }

  Future<void> _fetchLinkPreview() async {
    // Skip fetch if already stored
    if ((block.imageUrl ?? '').trim().isNotEmpty) {
      _linkPreviewImage = block.imageUrl;
      return;
    }
    final url = (block.url ?? '').trim();
    if (url.isEmpty) return;
    setState(() => _linkPreviewLoading = true);
    final data = await LinkPreviewService().fetch(
      url.startsWith('http') ? url : 'https://$url',
    );
    if (!mounted) return;
    setState(() {
      _linkPreviewLoading = false;
      _linkPreviewImage = data?.imageUrl;
      if (data?.imageUrl != null) {
        // Persist the preview image in the block
        block = block.copyWith(imageUrl: data!.imageUrl);
      }
    });
  }

  void _toggleChecklistItem(int index) {
    final items = block.checklistItems.toList();
    final item = items[index];
    items[index] = CollectionChecklistItemEntity(
      id: item.id,
      title: item.title,
      isDone: !item.isDone,
    );
    setState(() {
      block = block.copyWith(checklistItems: items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    if (block.isFolder || block.isSection) {
      return CollectionFolderDetailPage(
        collectionId: collectionId,
        folderId: block.id,
      );
    }
    if (block.type == CollectionBlockType.note) {
      return _notePreviewScaffold(context, palette);
    }
    return Scaffold(
      backgroundColor: palette.background,
      appBar: GenericAppBar(
        showBackButton: true,
        onBackPressed: () {
          _popWithResult();
        },
        title: _titleForType(context, block.type),
        actions: [
          IconButton(
            onPressed: () => _showMore(context),
            icon: Icon(
              Icons.more_horiz_rounded,
              color: palette.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _heroCard(context),
            const SizedBox(height: 14),
            _actionButton(
              label: _deleteLabel(),
              icon: Icons.delete_rounded,
              destructive: true,
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _popWithResult() {
    if (block != widget.block) {
      Navigator.of(
        context,
      ).pop(CollectionBlockDetailResult(updatedBlock: block));
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _notePreviewScaffold(BuildContext context, AppPalette palette) {
    final breadcrumb = _noteBreadcrumb(context);
    final stats = _noteStatsLabel(block);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
              child: Row(
                children: [
                  _noteHeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: _popWithResult,
                  ),
                  const Spacer(),
                  _noteHeaderButton(
                    icon: Icons.edit_rounded,
                    onTap: () => _edit(context),
                  ),
                  const SizedBox(width: 8),
                  _noteHeaderButton(
                    icon: Icons.more_horiz_rounded,
                    onTap: () => _showMore(context),
                  ),
                ],
              ),
            ),
            if (breadcrumb.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                child: Text(
                  breadcrumb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.l10n.collectionBlockNote.toUpperCase()} · MARKDOWN',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    block.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.45,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NoteMarkdownView(
                    markdown: block.description,
                    emptyLabel: context.l10n.collectionEntryHintNoteContent,
                    style: NoteMarkdownViewStyle.reference,
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: palette.stroke.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    stats,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: palette.textMuted,
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

  Widget _noteHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.stroke.withValues(alpha: 0.72)),
          ),
          child: Icon(icon, size: 20, color: palette.textPrimary),
        ),
      ),
    );
  }

  String _noteBreadcrumb(BuildContext context) {
    final collection = _collectionDetailCubitOrNull(context)?.state.collection;
    final collectionName = collection?.name.trim() ?? '';
    final parentId = block.parentBlockId;
    var parentName = '';
    if (collection != null && parentId != null) {
      for (final candidate in collection.blocks) {
        if (candidate.id == parentId) {
          parentName = candidate.title.trim();
          break;
        }
      }
    }
    if (collectionName.isEmpty) {
      return parentName;
    }
    if (parentName.isEmpty) {
      return collectionName;
    }
    return '$collectionName / $parentName';
  }

  String _noteStatsLabel(CollectionBlockEntity note) {
    final plain = NoteMarkdownSupport.plainTextFromMarkdown(note.description);
    final words = plain
        .split(RegExp(r'\s+'))
        .where((value) => value.trim().isNotEmpty)
        .length;
    final minutes = words == 0 ? 1 : (words / 200).ceil();
    return 'Updated ${DateFormat('d MMM').format(note.updatedAt)} · $minutes min read · $words words';
  }

  CollectionDetailCubit? _collectionDetailCubitOrNull(BuildContext context) {
    try {
      return context.read<CollectionDetailCubit>();
    } catch (_) {
      return null;
    }
  }

  Widget _heroCard(BuildContext context) {
    switch (block.type) {
      case CollectionBlockType.document:
        return _documentHero(context);
      case CollectionBlockType.note:
        return _noteHero();
      case CollectionBlockType.input:
        return _inputHero();
      case CollectionBlockType.checklist:
        return _checklistHero();
      case CollectionBlockType.link:
        return _linkHero();
      case CollectionBlockType.image:
        return _imageHero();
      case CollectionBlockType.expense:
        return _expenseHero();
      case CollectionBlockType.timeline:
        return _timelineHero(context);
      case CollectionBlockType.location:
        return _locationHero();
      case CollectionBlockType.reminder:
        return _reminderHero();
      case CollectionBlockType.progress:
        return _progressHero();
      case CollectionBlockType.folder:
        return _folderHero();
      case CollectionBlockType.section:
        return _sectionHero();
    }
  }

  Widget _folderHero() {
    return CollectionsSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          buildCollectionBlockLeadingIcon(
            context,
            type: CollectionBlockType.folder,
            metadata: block.metadata,
            shellSize: 76,
            shellRadius: 20,
            iconSize: 38,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 30 / 1.45,
                    fontWeight: FontWeight.w800,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  block.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHero() {
    return CollectionsSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          buildCollectionBlockLeadingIcon(
            context,
            type: CollectionBlockType.section,
            metadata: block.metadata,
            shellSize: 76,
            shellRadius: 20,
            iconSize: 38,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 30 / 1.45,
                    fontWeight: FontWeight.w800,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  block.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentHero(BuildContext context) {
    final filePath = (block.filePath ?? '').trim();
    final resolvedFilePath = LocalAssetPathResolver.resolveRuntimePathSync(
      filePath,
    );
    final hasFile =
        resolvedFilePath.isNotEmpty && File(resolvedFilePath).existsSync();
    final isPdf = hasFile && resolvedFilePath.toLowerCase().endsWith('.pdf');
    final imageProvider = hasFile && !isPdf
        ? resolveLocalFileImageProvider(resolvedFilePath)
        : null;
    final canPreviewInline = isPdf || imageProvider != null;

    return CollectionsSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          GestureDetector(
            onTap: hasFile
                ? () => _previewFile(context, resolvedFilePath)
                : null,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Container(
                height: 280,
                width: double.infinity,
                color: context.appPalette.surfaceSoft,
                child: canPreviewInline
                    ? _buildInlinePreview(
                        isPdf,
                        resolvedFilePath,
                        imageProvider,
                      )
                    : _buildDocumentPlaceholder(hasFile),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 29 / 1.45,
                    fontWeight: FontWeight.w800,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${block.fileType ?? 'PDF'} • ${block.fileSizeLabel ?? '1.2 MB'} • Updated ${_relativeLabel(block.updatedAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _outlinedButton(
                        label: context.l10n.collectionDetailPreview,
                        icon: Icons.visibility_rounded,
                        onTap: () => _previewFile(context, resolvedFilePath),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _outlinedButton(
                        label: context.l10n.collectionDetailDownload,
                        icon: Icons.download_rounded,
                        onTap: () => _shareFile(context, resolvedFilePath),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteHero() {
    return CollectionsSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: context.appPalette.surfaceSoft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.lightbulb_rounded,
              size: 54,
              color: collectionsPrimary,
            ),
          ),
          Container(height: 4, color: collectionsPrimary),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.appPalette.surfaceSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${context.l10n.collectionBlockNote.toUpperCase()} · MARKDOWN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: collectionsPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 33 / 1.45,
                    fontWeight: FontWeight.w800,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                NoteMarkdownView(
                  markdown: block.description,
                  emptyLabel: context.l10n.collectionEntryHintNoteContent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputHero() {
    final label = block.title;
    final value = block.subtitle.trim().isNotEmpty ? block.subtitle : '-';

    return CollectionsSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.appPalette.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 26,
                  height: 17,
                  decoration: BoxDecoration(
                    color: context.appPalette.textSecondary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '123',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.appPalette.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: context.appPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _inlineButton(
                  label: context.l10n.collectionDashboardCopy,
                  icon: Icons.copy_rounded,
                  color: collectionsPrimary,
                  textColor: Colors.white,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final copiedLabel = context.l10n.collectionDashboardCopied;
                    await Clipboard.setData(ClipboardData(text: value));
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(copiedLabel)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _outlinedButton(
                  label: context.l10n.collectionDetailDelete,
                  icon: Icons.delete_rounded,
                  onTap: () => _confirmDelete(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checklistHero() {
    final total = block.checklistItems.length;
    final done = block.checklistItems.where((item) => item.isDone).length;
    final ratio = total == 0 ? 0.0 : done / total;
    final percent = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          block.title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: context.appPalette.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        CollectionsSurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.collectionDetailCompletionProgress,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.appPalette.textSecondary,
                ),
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.collectionDetailTaskCount(done, total),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: collectionsPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: ratio,
                  color: collectionsPrimary,
                  backgroundColor: context.appPalette.stroke,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CollectionsSectionLabel(label: context.l10n.collectionDetailTaskList),
        const SizedBox(height: 10),
        for (var i = 0; i < block.checklistItems.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _checklistItemRow(block.checklistItems[i], i),
          ),
      ],
    );
  }

  Widget _checklistItemRow(CollectionChecklistItemEntity item, int index) {
    return GestureDetector(
      onTap: () => _toggleChecklistItem(index),
      child: CollectionsSurfaceCard(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.isDone
                    ? collectionsPrimary
                    : context.appPalette.stroke,
                shape: BoxShape.circle,
              ),
              child: item.isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: item.isDone
                          ? context.appPalette.textSecondary
                          : context.appPalette.textPrimary,
                      decoration: item.isDone
                          ? TextDecoration.none
                          : TextDecoration.none,
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

  Widget _linkHero() {
    final previewImage = _linkPreviewImage ?? block.imageUrl;
    final hasImage = (previewImage ?? '').trim().isNotEmpty;
    final domain = block.domainLabel ?? _extractDomain(block.url);
    final url = (block.url ?? '').trim();

    return CollectionsSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: _linkPreviewLoading
                  ? Container(
                      color: context.appPalette.surfaceSoft,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: collectionsPrimary,
                        ),
                      ),
                    )
                  : hasImage
                  ? Image.network(
                      previewImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _linkPlaceholder(),
                    )
                  : _linkPlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 29 / 1.45,
                    fontWeight: FontWeight.w800,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  domain,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: collectionsPrimary,
                  ),
                ),
                if (block.description.trim().isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    block.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _inlineButton(
                  label: context.l10n.collectionDetailOpenLink,
                  color: collectionsPrimary,
                  textColor: Colors.white,
                  icon: Icons.open_in_new_rounded,
                  onTap: () {
                    if (url.isNotEmpty) {
                      Share.share(url, subject: block.title);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkPlaceholder() {
    return Container(
      color: context.appPalette.surfaceSoft,
      alignment: Alignment.center,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14124C9C),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.link_rounded,
          color: collectionsPrimary,
          size: 32,
        ),
      ),
    );
  }

  Widget _imageHero() {
    final imagePath = (block.imageUrl ?? block.filePath ?? '').trim();
    final hasImage = imagePath.isNotEmpty;

    return CollectionsSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: hasImage ? () => _previewFile(context, imagePath) : null,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: hasImage
                    ? _resolveImageContent(imagePath)
                    : Container(
                        color: context.appPalette.surfaceSoft,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_rounded,
                          size: 48,
                          color: context.appPalette.textMuted,
                        ),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 29 / 1.45,
                    fontWeight: FontWeight.w800,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                if (block.subtitle.trim().isNotEmpty) ...[
                  SizedBox(height: 3),
                  Text(
                    block.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _inlineButton(
                  label: context.l10n.collectionDetailPreview,
                  color: collectionsPrimary,
                  textColor: Colors.white,
                  icon: Icons.visibility_rounded,
                  onTap: hasImage
                      ? () => _previewFile(context, imagePath)
                      : () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resolveImageContent(String path) {
    final fallbackColor = context.appPalette.surfaceSoft;
    final trimmed = path.trim();
    if (trimmed.startsWith('/') || trimmed.startsWith('file://')) {
      final provider = resolveLocalFileImageProvider(trimmed);
      if (provider != null) {
        return Image(
          image: provider,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: fallbackColor),
        );
      }
    }
    if (trimmed.startsWith('http')) {
      return Image.network(
        trimmed,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: fallbackColor),
      );
    }
    return Container(color: fallbackColor);
  }

  Widget _expenseHero() {
    final currencySymbol = switch (block.currencyCode ?? 'USD') {
      'EUR' => '€',
      'GBP' => '£',
      _ => '\$',
    };
    final amount = (block.amount ?? 0).toStringAsFixed(2);
    final filePath = (block.filePath ?? '').trim();
    final hasReceipt = filePath.isNotEmpty;
    final receiptImage = block.imageUrl ?? (hasReceipt ? filePath : null);

    return CollectionsSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: const BoxDecoration(
              color: collectionsPrimary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currencySymbol$amount',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    block.metadata['category'] ?? 'Expense',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (receiptImage != null) ...[
            GestureDetector(
              onTap: () => _previewFile(context, filePath),
              child: _expenseReceiptPreview(receiptImage),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eventInfoRow(
                  Icons.calendar_today_rounded,
                  block.eventAt != null
                      ? DateFormat('EEEE, MMM d, y').format(block.eventAt!)
                      : context.l10n.collectionDetailDateNotSet,
                ),
                const SizedBox(height: 6),
                _eventInfoRow(
                  Icons.payments_rounded,
                  '${block.currencyCode ?? 'USD'} $amount',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseReceiptPreview(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('/') || trimmed.startsWith('file://')) {
      final provider = resolveLocalFileImageProvider(trimmed);
      if (provider != null) {
        return SizedBox(
          height: 180,
          width: double.infinity,
          child: Image(
            image: provider,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      }
    }
    if (trimmed.startsWith('http')) {
      return SizedBox(
        height: 180,
        width: double.infinity,
        child: Image.network(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _timelineHero(BuildContext context) {
    final location = (block.locationLabel ?? '').trim();
    final description = block.description.trim();
    final filePath = (block.filePath ?? '').trim();
    final hasFile = filePath.isNotEmpty;
    final hasImage = (block.imageUrl ?? '').trim().isNotEmpty;

    return CollectionsSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: hasFile ? () => _previewFile(context, filePath) : null,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: (hasImage || hasFile) ? 200 : 140,
                width: double.infinity,
                child: hasFile
                    ? _resolveImageContent(filePath)
                    : hasImage
                    ? Image.network(
                        block.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _eventPlaceholder(),
                      )
                    : _eventPlaceholder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.appPalette.surfaceSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (block.metadata['category'] ?? 'Event').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: collectionsPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 32 / 1.45,
                    fontWeight: FontWeight.w800,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _eventInfoRow(
                  Icons.calendar_today_rounded,
                  block.eventAt == null
                      ? context.l10n.collectionDetailDateNotSet
                      : DateFormat('EEEE, MMM d, y').format(block.eventAt!),
                ),
                const SizedBox(height: 6),
                _eventInfoRow(
                  Icons.access_time_filled_rounded,
                  block.eventAt == null
                      ? context.l10n.collectionDetailTimeNotSet
                      : DateFormat('hh:mm a').format(block.eventAt!),
                ),
                const SizedBox(height: 6),
                _eventInfoRow(
                  Icons.place_rounded,
                  location.isNotEmpty
                      ? location
                      : context.l10n.collectionDetailNoLocationSet,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1, color: context.appPalette.stroke),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.collectionDetailDescription,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: context.appPalette.textMuted,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                if (hasFile) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1, color: context.appPalette.stroke),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.collectionDetailAttachment,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: context.appPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _previewFile(context, filePath),
                    child: _attachmentRow(filePath),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventPlaceholder() {
    return Container(
      color: context.appPalette.surfaceSoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.event_rounded,
        color: context.appPalette.textMuted,
        size: 46,
      ),
    );
  }

  Widget _eventInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: context.appPalette.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.appPalette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _attachmentRow(String filePath) {
    final fileName = filePath.split('/').last;
    final typeLabel = filePath.inferFileTypeLabel();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: context.appPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appPalette.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.appPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.description_rounded,
              size: 18,
              color: collectionsPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.open_in_new_rounded,
            size: 18,
            color: context.appPalette.textMuted,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _reminderHero() {
    final description = block.description.trim();

    return CollectionsSurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notifications_rounded,
                  size: 21,
                  color: Color(0xFFE8890C),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 29 / 1.45,
                    fontWeight: FontWeight.w800,
                    color: context.appPalette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _eventInfoRow(
            Icons.calendar_today_rounded,
            block.eventAt != null
                ? DateFormat('EEEE, MMM d, y').format(block.eventAt!)
                : context.l10n.collectionDetailDateNotSet,
          ),
          const SizedBox(height: 6),
          _eventInfoRow(
            Icons.access_time_filled_rounded,
            block.eventAt != null
                ? DateFormat('hh:mm a').format(block.eventAt!)
                : context.l10n.collectionDetailTimeNotSet,
          ),
          if (block.repeatInterval != null) ...[
            const SizedBox(height: 6),
            _eventInfoRow(Icons.repeat_rounded, block.repeatInterval!),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: context.appPalette.stroke),
            const SizedBox(height: 14),
            Text(
              context.l10n.collectionDetailDescription,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.appPalette.textMuted,
              ),
            ),
            SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: context.appPalette.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _outlinedButton(
            label: context.l10n.collectionDetailDeleteReminder,
            icon: Icons.delete_rounded,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Widget _progressHero() {
    final current = block.amount ?? 0;
    final target = double.tryParse(block.metadata['target_amount'] ?? '') ?? 0;
    final ratio = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final pct = (ratio * 100).toStringAsFixed(0);
    final unit = (block.metadata['unit'] ?? '').trim();
    final currentLabel = unit.isNotEmpty
        ? '$unit${current.toStringAsFixed(2)}'
        : current.toStringAsFixed(2);
    final targetLabel = unit.isNotEmpty
        ? '$unit${target.toStringAsFixed(2)}'
        : target.toStringAsFixed(2);
    final isComplete = ratio >= 1.0;
    final accentColor = isComplete
        ? context.appPalette.success
        : collectionsPrimary;
    final description = block.description.trim();

    return CollectionsSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Column(
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      targetLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eventInfoRow(
                  Icons.donut_small_rounded,
                  '$currentLabel of $targetLabel',
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _eventInfoRow(Icons.straighten_rounded, unit),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1, color: context.appPalette.stroke),
                  const SizedBox(height: 14),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: context.appPalette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationHero() {
    final address = (block.locationLabel ?? block.subtitle).trim();

    return CollectionsSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: block.latitude != null && block.longitude != null
                  ? StaticMapPreview(
                      latitude: block.latitude!,
                      longitude: block.longitude!,
                      height: 220,
                    )
                  : _locationMapFallback(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                    fontSize: 29 / 1.45,
                    fontWeight: FontWeight.w800,
                    color: context.appPalette.textPrimary,
                  ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: context.appPalette.textSecondary,
                        ),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.appPalette.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (block.latitude != null && block.longitude != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        size: 16,
                        color: context.appPalette.textSecondary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${block.latitude!.toStringAsFixed(4)}, ${block.longitude!.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.appPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationMapFallback() {
    return Container(
      color: context.appPalette.surfaceSoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.map_rounded,
        size: 48,
        color: context.appPalette.textMuted,
      ),
    );
  }

  Widget _inlineButton({
    required String label,
    required Color color,
    required Color textColor,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlinePreview(
    bool isPdf,
    String filePath,
    ImageProvider? imageProvider,
  ) {
    if (isPdf) {
      return IgnorePointer(
        child: PdfViewer.file(
          filePath,
          params: PdfViewerParams(
            backgroundColor: context.appPalette.surfaceSoft,
            margin: 0,
            pageDropShadow: null,
            pageAnchor: PdfPageAnchor.center,
            pageAnchorEnd: PdfPageAnchor.center,
            calculateInitialZoom: (document, controller, fitZoom, coverZoom) {
              return fitZoom;
            },
          ),
        ),
      );
    }
    return Image(
      image: imageProvider!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildDocumentPlaceholder(true),
    );
  }

  Widget _buildDocumentPlaceholder(bool hasFile) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18124C9C),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.picture_as_pdf_rounded,
            color: collectionsPrimary,
            size: 50,
          ),
        ),
        if (hasFile) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              context.l10n.collectionDetailPreviewAvailable,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: collectionsPrimary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _previewFile(BuildContext context, String filePath) {
    final resolvedPath = LocalAssetPathResolver.resolveRuntimePathSync(
      filePath,
    );
    if (resolvedPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionDetailNoFileAttached)),
      );
      return;
    }
    final file = File(resolvedPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionDetailFileNotFound)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentFilePreviewPage(
          filePath: resolvedPath,
          title: block.title,
          mimeType: resolvedPath.inferMimeType(),
        ),
      ),
    );
  }

  Future<void> _shareFile(BuildContext context, String filePath) async {
    final resolvedPath = LocalAssetPathResolver.resolveRuntimePathSync(
      filePath,
    );
    if (resolvedPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionDetailNoFileAttached)),
      );
      return;
    }
    final file = File(resolvedPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionDetailFileNotFound)),
      );
      return;
    }
    final xFile = XFile(resolvedPath, mimeType: resolvedPath.inferMimeType());
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await Share.shareXFiles(
      [xFile],
      subject: block.title,
      sharePositionOrigin: origin,
    );
  }

  Widget _outlinedButton({
    required String label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        height: 46,
        decoration: BoxDecoration(
          color: context.appPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.appPalette.stroke),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: context.appPalette.textPrimary),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final palette = context.appPalette;
    final color = destructive ? palette.danger : palette.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 54,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.stroke),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleForType(BuildContext context, CollectionBlockType type) {
    final l = context.l10n;
    return switch (type) {
      CollectionBlockType.folder => l.collectionDetailFolderTitle,
      CollectionBlockType.document => l.collectionDetailDocumentTitle,
      CollectionBlockType.note => l.collectionDetailNoteTitle,
      CollectionBlockType.input => l.collectionDetailInputTitle,
      CollectionBlockType.checklist => l.collectionDetailChecklistTitle,
      CollectionBlockType.link => l.collectionDetailLinkTitle,
      CollectionBlockType.image => l.collectionDetailImageTitle,
      CollectionBlockType.expense => l.collectionDetailExpenseTitle,
      CollectionBlockType.timeline => l.collectionDetailTimelineTitle,
      CollectionBlockType.location => l.collectionDetailLocationTitle,
      CollectionBlockType.reminder => l.collectionDetailReminderTitle,
      CollectionBlockType.progress => l.collectionDetailProgressTitle,
      CollectionBlockType.section => l.collectionDetailSectionTitle,
    };
  }

  String _deleteLabel() {
    final l = context.l10n;
    return switch (block.type) {
      CollectionBlockType.link => l.collectionDetailDeleteLink,
      CollectionBlockType.input => l.collectionDetailRemove,
      CollectionBlockType.folder => l.collectionDetailDeleteFolder,
      CollectionBlockType.section => l.collectionDetailDeleteSection,
      CollectionBlockType.checklist => l.collectionDetailDeleteChecklist,
      CollectionBlockType.reminder => l.collectionDetailDeleteReminder,
      _ => l.collectionDetailDelete,
    };
  }

  String _relativeLabel(DateTime value) {
    final delta = DateTime.now().difference(value);
    if (delta.inMinutes < 1) {
      return 'just now';
    }
    if (delta.inMinutes < 60) {
      return '${delta.inMinutes}m ago';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours}h ago';
    }
    return '${delta.inDays}d ago';
  }

  String _extractDomain(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'website';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.trim().isEmpty) {
      return 'website';
    }
    return uri.host;
  }

  Future<void> _showMore(BuildContext context) async {
    await showAdaptiveModal<void>(
      context: context,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(context.l10n.collectionDetailEdit),
                onTap: () {
                  Navigator.of(context).pop();
                  _edit(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_rounded,
                  color: context.appPalette.danger,
                ),
                title: Text(
                  context.l10n.collectionDetailDelete,
                  style: TextStyle(color: context.appPalette.danger),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
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
                style: TextStyle(color: context.appPalette.danger),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    Navigator.of(context).pop(const CollectionBlockDetailResult(deleted: true));
  }

  Future<void> _edit(BuildContext context) async {
    final page = _editPageByType();
    final updated = await Navigator.of(
      context,
    ).push<CollectionBlockEntity>(MaterialPageRoute(builder: (_) => page));
    if (!context.mounted) {
      return;
    }
    if (updated == null) {
      final cubit = _collectionDetailCubitOrNull(context);
      final stillExists =
          cubit?.state.collection?.blocks.any((item) => item.id == block.id) ??
          true;
      if (!stillExists && context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    Navigator.of(
      context,
    ).pop(CollectionBlockDetailResult(updatedBlock: updated));
  }

  Widget _editPageByType() {
    return switch (block.type) {
      CollectionBlockType.note => AddNoteBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.document => AddDocumentBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.image => AddImageBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.expense => AddExpenseBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.timeline => AddTimelineEventBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.location => AddLocationBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.reminder => AddReminderBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.checklist => AddChecklistBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.link => AddLinkBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.input => AddInputBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.folder => AddFolderBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.section => AddSectionBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
      CollectionBlockType.progress => AddProgressBlockPage(
        collectionId: collectionId,
        parentBlockId: block.parentBlockId,
        initialBlock: block,
      ),
    };
  }
}
