import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_event.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_status.dart';
import 'package:pass_doc_manager/domain/bundles/support/bundle_template_catalog.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/delete_bundle.dart';
import 'package:pass_doc_manager/features/bundles/presentation/cubit/bundle_detail_cubit.dart';
import 'package:pass_doc_manager/features/bundles/presentation/cubit/bundle_detail_state.dart';
import 'package:pass_doc_manager/features/bundles/presentation/pages/bundle_export_page.dart';
import 'package:pass_doc_manager/features/bundles/presentation/support/bundle_relative_time.dart';
import 'package:pass_doc_manager/features/bundles/presentation/widgets/add_to_bundle_sheet.dart';
import 'package:pass_doc_manager/features/bundles/presentation/widgets/bundles_reference_ui.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_dashboard_page.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_detail_cubit.dart';
import 'package:pass_doc_manager/features/credentials/presentation/pages/credential_detail_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_detail_page.dart';
import 'package:pass_doc_manager/features/search/presentation/pages/vault_search_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class BundleDetailPage extends StatelessWidget {
  const BundleDetailPage({super.key, required this.bundleId});

  final String bundleId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BundleDetailCubit(bundleId: bundleId)..load(),
      child: const _BundleDetailScaffold(),
    );
  }
}

class _BundleDetailScaffold extends StatelessWidget {
  const _BundleDetailScaffold();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BundleDetailCubit, BundleDetailState>(
      builder: (context, state) {
        switch (state.status) {
          case BundleDetailStatus.initial:
          case BundleDetailStatus.loading:
            return const BundleReferencePage(
              child: Center(child: CircularProgressIndicator()),
            );
          case BundleDetailStatus.error:
            return BundleReferencePage(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    context.l10n.bundleDetailErrorLoad,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appPalette.textSecondary),
                  ),
                ),
              ),
            );
          case BundleDetailStatus.ready:
            final bundle = state.bundle;
            if (bundle == null) {
              return const BundleReferencePage(child: SizedBox.shrink());
            }
            return _BundleDetailContent(bundle: bundle);
        }
      },
    );
  }
}

class _BundleDetailContent extends StatelessWidget {
  const _BundleDetailContent({required this.bundle});

  final BundleEntity bundle;

  Future<void> _previewItem(BuildContext context, BundleItemRef item) async {
    switch (item.type) {
      case BundleItemType.credential:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) =>
                  CredentialDetailCubit()..load(credentialId: item.refId),
              child: CredentialDetailPage(),
            ),
          ),
        );
      case BundleItemType.document:
      case BundleItemType.identityCard:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DocumentDetailPage(documentId: item.refId),
          ),
        );
      case BundleItemType.collection:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CollectionDashboardPage(collectionId: item.refId),
          ),
        );
      case BundleItemType.note:
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.bundlePreviewUnavailable)),
        );
    }
  }

  Future<void> _addItems(BuildContext context) async {
    final cubit = context.read<BundleDetailCubit>();
    final picks = await Navigator.of(context).push<List<BundleItemCandidate>>(
      MaterialPageRoute(
        builder: (_) => VaultSearchPage(
          pickMode: true,
          existingBundle: bundle,
          autoFocus: true,
        ),
      ),
    );
    if (picks == null || picks.isEmpty) return;
    final now = DateTime.now();
    for (final pick in picks) {
      await cubit.addItem(
        BundleItemRef(
          id: '',
          type: pick.type,
          refId: pick.refId,
          displayName: pick.displayName,
          subtitle: pick.subtitle,
          addedAt: now,
        ),
      );
    }
  }

  Future<void> _openExport(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BundleExportPage(bundle: bundle)));
    if (!context.mounted) return;
    await context.read<BundleDetailCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final progress = BundleTemplateCatalog.progressFor(
      templateKey: bundle.templateKey,
      items: bundle.items,
    );
    final missing = progress?.totalMissingRequiredUnits ?? 0;
    final completed = progress?.completedRequiredCount ?? bundle.itemCount;
    final total = progress?.totalRequiredCount ?? bundle.itemCount;
    final headerMeta = progress == null
        ? '${bundle.itemCount} ITEMS'
        : '$completed OF $total · $missing MISSING';

    return BundleReferencePage(
      child: RefreshIndicator(
        onRefresh: () => context.read<BundleDetailCubit>().refresh(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BundleRefHeader(
                    title: bundle.title,
                    meta: headerMeta,
                    leading: BundleRefIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                      size: 42,
                    ),
                    trailing: BundleRefIconButton(
                      icon: Icons.more_horiz_rounded,
                      tooltip: l10n.bundleDetailMenuTooltip,
                      onTap: () => _openActionsMenu(context, bundle),
                      size: 42,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                    child: Row(
                      children: [
                        BundleStatusPill(
                          status: bundle.status,
                          label: _statusLabel(l10n, bundle.status),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _detailMetaLine(bundle, l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: bundleFontMono,
                              color: palette.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (progress != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: _TemplateCompletionPanel(
                        progress: progress,
                        onAddItems: () => _addItems(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  BundleSectionLabel(
                    label: '${l10n.bundleSectionItems} · ${bundle.itemCount}',
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
              sliver: SliverList.list(
                children: [
                  if (bundle.items.isEmpty)
                    _EmptyItemsState(onAddItems: () => _addItems(context))
                  else ...[
                    for (final group in _groupItems(bundle.items)) ...[
                      _BundleItemGroup(
                        group: group,
                        onTap: (item) => _previewItem(context, item),
                        onRemove: (item) => context
                            .read<BundleDetailCubit>()
                            .removeItem(item.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                  BundleDashedButton(
                    label: l10n.bundleAddItems,
                    onTap: () => _addItems(context),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => _BundleHistoryPage(
                                  bundleTitle: bundle.title,
                                  events: bundle.history,
                                ),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: palette.textSecondary,
                              side: BorderSide(color: palette.stroke),
                              textStyle: const TextStyle(
                                fontFamily: bundleFontBody,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10n.bundleSectionHistory),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BundlePrimaryButton(
                          height: 40,
                          label:
                              '${l10n.bundleActionExport.replaceAll(' / share', '')} · ${bundle.itemCount}',
                          icon: Icons.ios_share_rounded,
                          onPressed: bundle.isEmpty
                              ? null
                              : () => _openExport(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openActionsMenu(
    BuildContext context,
    BundleEntity bundle,
  ) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final palette = sheetContext.appPalette;
        final cubit = context.read<BundleDetailCubit>();
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.stroke),
            ),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share_rounded),
                  title: Text(l10n.bundleActionExport),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _openExport(context);
                  },
                ),
                if (bundle.status != BundleStatus.archived)
                  ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: Text(l10n.bundleActionArchive),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await cubit.setStatus(BundleStatus.archived);
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.unarchive_outlined),
                    title: Text(l10n.bundleActionUnarchive),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await cubit.setStatus(BundleStatus.draft);
                    },
                  ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                  title: Text(
                    l10n.bundleActionDelete,
                    style: TextStyle(
                      color: Theme.of(sheetContext).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    if (!context.mounted) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(l10n.bundleDeleteTitle),
                        content: Text(l10n.bundleDeleteMessage(bundle.title)),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text(
                              MaterialLocalizations.of(
                                dialogContext,
                              ).cancelButtonLabel,
                            ),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(
                                dialogContext,
                              ).colorScheme.error,
                            ),
                            child: Text(l10n.bundleDeleteConfirm),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    await getIt<DeleteBundle>()(
                      DeleteBundleParams(bundleId: bundle.id),
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).maybePop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TemplateCompletionPanel extends StatelessWidget {
  const _TemplateCompletionPanel({
    required this.progress,
    required this.onAddItems,
  });

  final BundleTemplateProgress progress;
  final VoidCallback onAddItems;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final completed = progress.completedRequiredCount;
    final total = progress.totalRequiredCount;
    final ratio = total == 0 ? 0.0 : completed / total;
    return BundleCardShell(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.bundleTemplateChecklistTitle,
                  style: TextStyle(
                    fontFamily: bundleFontDisplay,
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Text(
                '$completed / $total · ${(ratio * 100).round()}%',
                style: TextStyle(
                  fontFamily: bundleFontMono,
                  color: palette.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          BundleProgressBar(
            progress: ratio,
            height: 6,
            color: progress.isReady ? palette.success : palette.warning,
          ),
          const SizedBox(height: 8),
          for (final requirementProgress in progress.requirements.take(6))
            _TemplateRequirementLine(
              progress: requirementProgress,
              onAddItems: onAddItems,
            ),
        ],
      ),
    );
  }
}

class _TemplateRequirementLine extends StatelessWidget {
  const _TemplateRequirementLine({
    required this.progress,
    required this.onAddItems,
  });

  final BundleTemplateRequirementProgress progress;
  final VoidCallback onAddItems;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final met = progress.isSatisfied;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.stroke.withValues(alpha: 0.65)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? palette.success : Colors.transparent,
              border: Border.all(
                color: met
                    ? palette.success
                    : palette.danger.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: met
                ? Icon(Icons.check_rounded, size: 14, color: palette.surface)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.requirement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: bundleFontBody,
                    color: met ? palette.textMuted : palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  met
                      ? '${progress.matchedCount} matched'
                      : '${progress.missingCount} missing',
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: met ? palette.success : palette.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          if (!met)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAddItems,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: 0.26),
                  ),
                ),
                child: Text(
                  l10nSafeAdd(context),
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: palette.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: palette.textMuted,
              size: 18,
            ),
        ],
      ),
    );
  }

  String l10nSafeAdd(BuildContext context) => 'ADD';
}

class _BundleItemGroup extends StatelessWidget {
  const _BundleItemGroup({
    required this.group,
    required this.onTap,
    required this.onRemove,
  });

  final _BundleItemGroupData group;
  final ValueChanged<BundleItemRef> onTap;
  final ValueChanged<BundleItemRef> onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return BundleCardShell(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${group.label} · ${group.items.length}',
                    style: TextStyle(
                      fontFamily: bundleFontMono,
                      color: palette.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.85,
                    ),
                  ),
                ),
                Text(
                  '${group.items.length} ITEMS',
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: palette.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.55,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < group.items.length; i++) ...[
            _BundleItemRow(
              item: group.items[i],
              onTap: () => onTap(group.items[i]),
              onRemove: () => onRemove(group.items[i]),
            ),
            if (i < group.items.length - 1)
              Divider(height: 1, color: palette.stroke.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );
  }
}

class _BundleItemRow extends StatelessWidget {
  const _BundleItemRow({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  final BundleItemRef item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final accent = _typeColor(item.type, palette);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(item.type), size: 16, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: bundleFontBody,
                      color: palette.textPrimary,
                      fontSize: 13.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _sourceLine(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: bundleFontMono,
                      color: palette.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: palette.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState({required this.onAddItems});

  final VoidCallback onAddItems;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return BundleCardShell(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: palette.textMuted, size: 30),
          const SizedBox(height: 10),
          Text(
            context.l10n.bundleEmptyItems,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: bundleFontBody,
              color: palette.textSecondary,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          BundleDashedButton(
            label: context.l10n.bundleAddItems,
            onTap: onAddItems,
          ),
        ],
      ),
    );
  }
}

class _BundleHistoryPage extends StatelessWidget {
  const _BundleHistoryPage({required this.bundleTitle, required this.events});

  final String bundleTitle;
  final List<BundleEvent> events;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final sorted = events.reversed.toList(growable: false);
    return BundleReferencePage(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BundleRefHeader(
                  title: context.l10n.bundleSectionHistory,
                  meta:
                      '${bundleTitle.toUpperCase()} · ${events.length} EVENTS',
                  leading: BundleRefIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                    size: 42,
                  ),
                  trailing: const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                  child: Text(
                    'Every change to this bundle is logged locally. Nothing leaves your device.',
                    style: TextStyle(
                      fontFamily: bundleFontBody,
                      color: palette.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 80),
            sliver: SliverList.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (context, index) => _TimelineRow(
                event: sorted[index],
                isLast: index == sorted.length - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final BundleEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final accent = _eventColor(event.kind, palette);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color:
                        event.kind == BundleEventKind.created ||
                            event.kind == BundleEventKind.exported
                        ? accent
                        : palette.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: palette.strokeStrong,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _eventLabel(context, event.kind),
                          style: TextStyle(
                            fontFamily: bundleFontBody,
                            color: palette.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        formatBundleRelative(event.at, context.l10n),
                        style: TextStyle(
                          fontFamily: bundleFontMono,
                          color: palette.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (event.detail != null &&
                      event.detail!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      event.detail!,
                      style: TextStyle(
                        fontFamily: bundleFontBody,
                        color: palette.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<_BundleItemGroupData> _groupItems(List<BundleItemRef> items) {
  final grouped = <BundleItemType, List<BundleItemRef>>{};
  for (final item in items) {
    grouped.putIfAbsent(item.type, () => <BundleItemRef>[]).add(item);
  }
  return BundleItemType.values
      .where((type) => grouped[type]?.isNotEmpty ?? false)
      .map(
        (type) => _BundleItemGroupData(
          type: type,
          label: _typeLabel(type).toUpperCase(),
          items: grouped[type]!,
        ),
      )
      .toList(growable: false);
}

class _BundleItemGroupData {
  const _BundleItemGroupData({
    required this.type,
    required this.label,
    required this.items,
  });

  final BundleItemType type;
  final String label;
  final List<BundleItemRef> items;
}

String _detailMetaLine(BundleEntity bundle, dynamic l10n) {
  final parts = <String>[
    if (bundle.purpose != null && bundle.purpose!.trim().isNotEmpty)
      bundle.purpose!.trim().toUpperCase(),
    l10n
        .bundleUpdatedAt(formatBundleRelative(bundle.updatedAt, l10n))
        .toUpperCase(),
  ];
  return parts.join(' · ');
}

String _sourceLine(BundleItemRef item) {
  final subtitle = item.subtitle?.trim();
  final type = _typeLabel(item.type).toUpperCase();
  if (subtitle == null || subtitle.isEmpty) return type;
  return '$type › $subtitle';
}

String _typeLabel(BundleItemType type) {
  switch (type) {
    case BundleItemType.credential:
      return 'Credentials';
    case BundleItemType.document:
      return 'Documents';
    case BundleItemType.note:
      return 'Notes';
    case BundleItemType.identityCard:
      return 'Identity';
    case BundleItemType.collection:
      return 'Collections';
  }
}

IconData _typeIcon(BundleItemType type) {
  switch (type) {
    case BundleItemType.credential:
      return Icons.key_rounded;
    case BundleItemType.document:
      return Icons.description_rounded;
    case BundleItemType.note:
      return Icons.sticky_note_2_rounded;
    case BundleItemType.identityCard:
      return Icons.badge_rounded;
    case BundleItemType.collection:
      return Icons.folder_rounded;
  }
}

Color _typeColor(BundleItemType type, AppPalette palette) {
  switch (type) {
    case BundleItemType.credential:
      return palette.primaryAccent;
    case BundleItemType.document:
      return palette.primary;
    case BundleItemType.note:
      return palette.warning;
    case BundleItemType.identityCard:
      return palette.danger;
    case BundleItemType.collection:
      return palette.success;
  }
}

String _statusLabel(dynamic l10n, BundleStatus status) {
  switch (status) {
    case BundleStatus.draft:
      return l10n.bundleStatusDraft;
    case BundleStatus.ready:
      return l10n.bundleStatusReady;
    case BundleStatus.exported:
      return l10n.bundleStatusExported;
    case BundleStatus.archived:
      return l10n.bundleStatusArchived;
  }
}

String _eventLabel(BuildContext context, BundleEventKind kind) {
  final l10n = context.l10n;
  switch (kind) {
    case BundleEventKind.created:
      return l10n.bundleEventCreated;
    case BundleEventKind.renamed:
      return l10n.bundleEventRenamed;
    case BundleEventKind.purposeUpdated:
      return l10n.bundleEventPurposeUpdated;
    case BundleEventKind.descriptionUpdated:
      return l10n.bundleEventDescriptionUpdated;
    case BundleEventKind.itemAdded:
      return l10n.bundleEventItemAdded;
    case BundleEventKind.itemRemoved:
      return l10n.bundleEventItemRemoved;
    case BundleEventKind.itemReordered:
      return l10n.bundleEventItemReordered;
    case BundleEventKind.statusChanged:
      return l10n.bundleEventStatusChanged;
    case BundleEventKind.exported:
      return l10n.bundleEventExported;
    case BundleEventKind.archived:
      return l10n.bundleEventArchived;
    case BundleEventKind.restored:
      return l10n.bundleEventRestored;
  }
}

Color _eventColor(BundleEventKind kind, AppPalette palette) {
  switch (kind) {
    case BundleEventKind.itemAdded:
    case BundleEventKind.restored:
      return palette.success;
    case BundleEventKind.itemRemoved:
    case BundleEventKind.archived:
      return palette.danger;
    case BundleEventKind.exported:
      return palette.primary;
    case BundleEventKind.statusChanged:
      return palette.warning;
    case BundleEventKind.created:
    case BundleEventKind.renamed:
    case BundleEventKind.purposeUpdated:
    case BundleEventKind.descriptionUpdated:
    case BundleEventKind.itemReordered:
      return palette.textPrimary;
  }
}
