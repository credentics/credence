import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_status.dart';
import 'package:pass_doc_manager/domain/bundles/support/bundle_template_catalog.dart';
import 'package:pass_doc_manager/features/bundles/presentation/cubit/bundles_list_cubit.dart';
import 'package:pass_doc_manager/features/bundles/presentation/cubit/bundles_list_state.dart';
import 'package:pass_doc_manager/features/bundles/presentation/pages/bundle_create_page.dart';
import 'package:pass_doc_manager/features/bundles/presentation/pages/bundle_detail_page.dart';
import 'package:pass_doc_manager/features/bundles/presentation/support/bundle_relative_time.dart';
import 'package:pass_doc_manager/features/bundles/presentation/support/bundle_template_presentation.dart';
import 'package:pass_doc_manager/features/bundles/presentation/widgets/bundles_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class BundlesListPage extends StatelessWidget {
  const BundlesListPage({super.key, this.embeddedDesktop = false});

  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BundlesListCubit()..load(),
      child: _BundlesListScaffold(embeddedDesktop: embeddedDesktop),
    );
  }
}

class _BundlesListScaffold extends StatelessWidget {
  const _BundlesListScaffold({required this.embeddedDesktop});

  final bool embeddedDesktop;

  Future<void> _openCreate(BuildContext context, {String? templateKey}) async {
    final cubit = context.read<BundlesListCubit>();
    final created = await Navigator.of(context).push<BundleEntity>(
      MaterialPageRoute(
        builder: (_) =>
            BundleCreatePage(listCubit: cubit, initialTemplateKey: templateKey),
      ),
    );
    if (!context.mounted || created == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BundleDetailPage(bundleId: created.id)),
    );
  }

  void _openDetail(BuildContext context, BundleEntity bundle) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BundleDetailPage(bundleId: bundle.id),
          ),
        )
        .then((_) {
          if (context.mounted) {
            context.read<BundlesListCubit>().load();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final body = _BundlesListView(
      embeddedDesktop: embeddedDesktop,
      onOpenCreate: _openCreate,
      onOpenDetail: _openDetail,
    );
    if (embeddedDesktop) {
      return body;
    }
    return BundleReferencePage(child: body);
  }
}

class _BundlesListView extends StatefulWidget {
  const _BundlesListView({
    required this.embeddedDesktop,
    required this.onOpenCreate,
    required this.onOpenDetail,
  });

  final bool embeddedDesktop;
  final Future<void> Function(BuildContext context, {String? templateKey})
  onOpenCreate;
  final void Function(BuildContext context, BundleEntity bundle) onOpenDetail;

  @override
  State<_BundlesListView> createState() => _BundlesListViewState();
}

class _BundlesListViewState extends State<_BundlesListView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BundlesListCubit, BundlesListState>(
      builder: (context, state) {
        switch (state.status) {
          case BundlesListStatus.initial:
          case BundlesListStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case BundlesListStatus.error:
            return _ErrorView(
              onRetry: () => context.read<BundlesListCubit>().load(),
            );
          case BundlesListStatus.ready:
            final bundles = _filteredBundles(state.bundles);
            final readyCount = state.bundles
                .where((bundle) => bundle.status == BundleStatus.ready)
                .length;
            return RefreshIndicator(
              onRefresh: () => context.read<BundlesListCubit>().load(),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        BundleRefHeader(
                          title: context.l10n.bundlesTitle,
                          meta:
                              '${state.bundles.length} BUNDLES · $readyCount READY',
                          leading: widget.embeddedDesktop
                              ? null
                              : BundleRefIconButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  tooltip: context.l10n.commonBack,
                                  onTap: () => Navigator.of(context).maybePop(),
                                  size: 42,
                                ),
                          trailing: BundleRefIconButton(
                            icon: Icons.add_rounded,
                            tooltip: context.l10n.bundleCreateAction,
                            onTap: () => widget.onOpenCreate(context),
                            size: 42,
                          ),
                        ),
                        BundleRefSearchField(
                          controller: _searchController,
                          hintText: 'Search bundles, items, files…',
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: _BundleOverviewStrip(bundles: state.bundles),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (state.bundles.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyView(
                        onCreate: (templateKey) => widget.onOpenCreate(
                          context,
                          templateKey: templateKey,
                        ),
                      ),
                    )
                  else if (bundles.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NoFilteredBundles(),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        widget.embeddedDesktop ? 28 : 22,
                        0,
                        widget.embeddedDesktop ? 28 : 22,
                        110,
                      ),
                      sliver: SliverList.separated(
                        itemCount: bundles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final bundle = bundles[index];
                          return _BundleCard(
                            bundle: bundle,
                            onTap: () => widget.onOpenDetail(context, bundle),
                            onDelete: () => _confirmDelete(context, bundle),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
        }
      },
    );
  }

  List<BundleEntity> _filteredBundles(List<BundleEntity> bundles) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return bundles;
    return bundles
        .where((bundle) {
          final template = BundleTemplateCatalog.byKey(bundle.templateKey);
          final haystack = [
            bundle.title,
            bundle.purpose ?? '',
            bundle.description ?? '',
            template?.title ?? '',
            template?.summary ?? '',
            for (final item in bundle.items) item.displayName,
            for (final item in bundle.items) item.subtitle ?? '',
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _confirmDelete(BuildContext context, BundleEntity bundle) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bundleDeleteTitle),
        content: Text(l10n.bundleDeleteMessage(bundle.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.bundleDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<BundlesListCubit>().delete(bundle.id);
  }
}

class _BundleOverviewStrip extends StatelessWidget {
  const _BundleOverviewStrip({required this.bundles});

  final List<BundleEntity> bundles;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    var missing = 0;
    var templated = 0;
    var itemCount = 0;
    for (final bundle in bundles) {
      itemCount += bundle.itemCount;
      if (bundle.templateKey != null) {
        templated++;
      }
      final progress = BundleTemplateCatalog.progressFor(
        templateKey: bundle.templateKey,
        items: bundle.items,
      );
      missing += progress?.totalMissingRequiredUnits ?? 0;
    }
    return BundleMiniStrip(
      metrics: [
        BundleMiniMetric(
          value: '$missing',
          label: 'Missing',
          color: missing == 0 ? palette.success : palette.danger,
        ),
        BundleMiniMetric(
          value: '$itemCount',
          label: 'Items',
          color: palette.success,
        ),
        BundleMiniMetric(value: '$templated', label: 'Templates'),
      ],
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({
    required this.bundle,
    required this.onTap,
    required this.onDelete,
  });

  final BundleEntity bundle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final template = BundleTemplateCatalog.byKey(bundle.templateKey);
    final templateCopy = template == null
        ? null
        : bundleTemplatePresentationCopy(l10n: l10n, template: template);
    final progress = BundleTemplateCatalog.progressFor(
      templateKey: bundle.templateKey,
      items: bundle.items,
    );
    final completed = progress?.completedRequiredCount ?? bundle.itemCount;
    final total = progress?.totalRequiredCount ?? bundle.itemCount;
    final ratio = total == 0 ? 0.0 : completed / total;
    final missing = progress?.totalMissingRequiredUnits ?? 0;
    final statusLabel = _statusLabel(l10n, bundle.status);
    final statusColor = bundleStatusColor(bundle.status, palette);
    final optional = progress?.optionalRequirements.length ?? 0;

    return BundleCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BundleMonoBadge(
                text: bundleTemplateInitials(bundle.templateKey, bundle.title),
                templateKey: bundle.templateKey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: bundleFontDisplay,
                        color: palette.textPrimary,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _purposeLine(
                        bundle: bundle,
                        templateTitle: templateCopy?.title,
                        l10n: l10n,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: bundleFontBody,
                        color: palette.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BundleStatusPill(status: bundle.status, label: statusLabel),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$completed OF $total REQUIRED',
                    style: TextStyle(
                      fontFamily: bundleFontMono,
                      color: palette.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.45,
                    ),
                  ),
                ),
                Text(
                  '${(ratio * 100).round()}%',
                  style: TextStyle(
                    fontFamily: bundleFontMono,
                    color: palette.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            BundleProgressBar(
              progress: ratio,
              color: missing == 0 ? palette.success : palette.warning,
            ),
          ],
          const SizedBox(height: 10),
          BundleMiniStrip(
            metrics: progress == null
                ? [
                    BundleMiniMetric(
                      value: '${bundle.itemCount}',
                      label: 'Items',
                    ),
                    BundleMiniMetric(
                      value: statusLabel,
                      label: 'Status',
                      color: statusColor,
                    ),
                    BundleMiniMetric(
                      value: formatBundleRelative(bundle.updatedAt, l10n),
                      label: 'Updated',
                    ),
                  ]
                : [
                    BundleMiniMetric(
                      value: '$missing',
                      label: 'Missing',
                      color: missing == 0 ? palette.success : palette.danger,
                    ),
                    BundleMiniMetric(value: '$total', label: 'Required'),
                    BundleMiniMetric(value: '$optional', label: 'Optional'),
                  ],
          ),
        ],
      ),
    );
  }

  String _purposeLine({
    required BundleEntity bundle,
    required String? templateTitle,
    required dynamic l10n,
  }) {
    final purpose = bundle.purpose?.trim();
    if (purpose != null && purpose.isNotEmpty) {
      return '$purpose · ${l10n.bundleUpdatedAt(formatBundleRelative(bundle.updatedAt, l10n))}';
    }
    if (templateTitle != null && templateTitle.trim().isNotEmpty) {
      return '$templateTitle · ${l10n.bundleItemCount(bundle.itemCount)}';
    }
    return l10n.bundleItemCount(bundle.itemCount);
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreate});

  final ValueChanged<String?> onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const _BundleEmptyStack(),
          const SizedBox(height: 16),
          Text(
            'One pack, every file.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: bundleFontDisplay,
              color: palette.textPrimary,
              fontSize: 22,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bundlesEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: bundleFontBody,
              color: palette.textSecondary,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          BundlePrimaryButton(
            label: 'Create your first bundle',
            icon: Icons.add_rounded,
            onPressed: () => onCreate(null),
          ),
          const SizedBox(height: 22),
          BundleSectionLabel(
            label: 'Start with a template',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          _TemplateStarterGrid(onCreate: onCreate),
          const SizedBox(height: 18),
          Text(
            'LOCAL · ENCRYPTED · EXPORT KEEPS REAL FILES',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: bundleFontMono,
              color: palette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateStarterGrid extends StatelessWidget {
  const _TemplateStarterGrid({required this.onCreate});

  final ValueChanged<String?> onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.42,
      ),
      itemCount: BundleTemplateCatalog.templates.length,
      itemBuilder: (context, index) {
        final template = BundleTemplateCatalog.templates[index];
        final copy = bundleTemplatePresentationCopy(
          l10n: l10n,
          template: template,
        );
        return _TemplateStarterTile(
          keyValue: template.key,
          title: copy.title,
          subtitle: '${template.requiredCount} REQ',
          onTap: () => onCreate(template.key),
        );
      },
    );
  }
}

class _TemplateStarterTile extends StatelessWidget {
  const _TemplateStarterTile({
    required this.keyValue,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String keyValue;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return BundleCardShell(
      onTap: onTap,
      radius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BundleMonoBadge(
            text: bundleTemplateInitials(keyValue, title),
            templateKey: keyValue,
            size: 36,
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: bundleFontDisplay,
              color: palette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: bundleFontMono,
              color: palette.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleEmptyStack extends StatelessWidget {
  const _BundleEmptyStack();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _EmptyStackCard(
            title: 'Tokyo trip',
            eyebrow: 'FRANCE VISA',
            progress: 0.62,
            color: BundleReferenceColors.rentalStart,
            transform: Matrix4.identity()
              ..translateByDouble(-42.0, 8.0, 0, 1)
              ..rotateZ(-0.12),
          ),
          _EmptyStackCard(
            title: 'Rue de Lille',
            eyebrow: 'APARTMENT RENTAL',
            progress: 1,
            color: palette.primary,
            transform: Matrix4.identity()
              ..translateByDouble(0.0, -7.0, 0, 1)
              ..rotateZ(0.04),
          ),
          _EmptyStackCard(
            title: 'Northwind',
            eyebrow: 'NEW JOB',
            progress: 0.82,
            color: palette.success,
            transform: Matrix4.identity()
              ..translateByDouble(38.0, 12.0, 0, 1)
              ..rotateZ(-0.05),
          ),
        ],
      ),
    );
  }
}

class _EmptyStackCard extends StatelessWidget {
  const _EmptyStackCard({
    required this.title,
    required this.eyebrow,
    required this.progress,
    required this.color,
    required this.transform,
  });

  final String title;
  final String eyebrow;
  final double progress;
  final Color color;
  final Matrix4 transform;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        width: 132,
        height: 92,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Color.lerp(palette.surface, color, 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Color.lerp(palette.stroke, color, 0.22)!),
          boxShadow: [
            BoxShadow(
              color: palette.shadow.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: TextStyle(
                fontFamily: bundleFontMono,
                color: palette.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.75,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: TextStyle(
                fontFamily: bundleFontDisplay,
                color: palette.textPrimary,
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            BundleProgressBar(progress: progress, color: color, height: 3),
          ],
        ),
      ),
    );
  }
}

class _NoFilteredBundles extends StatelessWidget {
  const _NoFilteredBundles();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Center(
      child: Text(
        'No bundles match this search.',
        style: TextStyle(
          fontFamily: bundleFontBody,
          color: palette.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36, color: palette.danger),
            const SizedBox(height: 12),
            Text(
              l10n.bundlesErrorLoad,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
            const SizedBox(height: 12),
            BundlePrimaryButton(
              label: MaterialLocalizations.of(context).continueButtonLabel,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
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
