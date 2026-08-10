import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/presentation/widgets/vault_error_state.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_expiry_item_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_expiring_documents.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/document_timeline_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/document_timeline_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_detail_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class DocumentExpiryTimelinePage extends StatelessWidget {
  const DocumentExpiryTimelinePage({
    super.key,
    GetExpiringDocuments? getExpiringDocuments,
  }) : _getExpiringDocuments = getExpiringDocuments;

  final GetExpiringDocuments? _getExpiringDocuments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        title: context.l10n.documentTimelineTitle,
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: BlocProvider(
        create: (_) =>
            DocumentTimelineCubit(getExpiringDocuments: _getExpiringDocuments)
              ..load(),
        child: const _DocumentTimelineView(),
      ),
    );
  }
}

class _DocumentTimelineView extends StatefulWidget {
  const _DocumentTimelineView();

  @override
  State<_DocumentTimelineView> createState() => _DocumentTimelineViewState();
}

class _DocumentTimelineViewState extends State<_DocumentTimelineView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DocumentTimelineCubit>().load(),
      child: BlocBuilder<DocumentTimelineCubit, DocumentTimelineState>(
        builder: (context, state) {
          final palette = context.appPalette;

          if (state.status == DocumentTimelineStatus.loading &&
              state.documents.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 12));
          }

          if (state.status == DocumentTimelineStatus.error &&
              state.documents.isEmpty) {
            return VaultErrorState(
              icon: Icons.calendar_month_rounded,
              message: state.errorMessage ??
                  context.l10n.documentTimelineErrorLoad,
              onRetry: () =>
                  context.read<DocumentTimelineCubit>().load(),
            );
          }

          if (state.documents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 64,
                      color: palette.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.documentTimelineEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Summary counts
              SliverToBoxAdapter(
                child: _SummaryCounts(state: state),
              ),
              // Filter chips
              SliverToBoxAdapter(
                child: _FilterChips(state: state),
              ),
              // Timeline content
              SliverToBoxAdapter(
                child: _TimelineContent(
                  state: state,
                  palette: palette,
                  onDocumentTap: (documentId) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DocumentDetailPage(documentId: documentId),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCounts extends StatelessWidget {
  const _SummaryCounts({required this.state});

  final DocumentTimelineState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _CountItem(
            label: context.l10n.documentTimelineExpired,
            count: state.expiredCount,
            color: palette.danger,
          ),
          const SizedBox(width: 12),
          _CountItem(
            label: context.l10n.documentTimelineSoon,
            count: state.criticalCount,
            color: palette.danger,
          ),
          const SizedBox(width: 12),
          _CountItem(
            label: context.l10n.documentTimelineSafe,
            count: state.safeCount,
            color: palette.success,
          ),
        ],
      ),
    );
  }
}

class _CountItem extends StatelessWidget {
  const _CountItem({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.state});

  final DocumentTimelineState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: context.l10n.documentTimelineFilterAll,
              isSelected: state.selectedFilter == ExpiryFilter.all,
              onTap: () => context
                  .read<DocumentTimelineCubit>()
                  .selectFilter(ExpiryFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: context.l10n.documentTimelineFilterExpired,
              isSelected: state.selectedFilter == ExpiryFilter.expired,
              onTap: () => context
                  .read<DocumentTimelineCubit>()
                  .selectFilter(ExpiryFilter.expired),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: context.l10n.documentTimelineFilterCritical,
              isSelected: state.selectedFilter == ExpiryFilter.critical,
              onTap: () => context
                  .read<DocumentTimelineCubit>()
                  .selectFilter(ExpiryFilter.critical),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: context.l10n.documentTimelineFilterWarning,
              isSelected: state.selectedFilter == ExpiryFilter.warning,
              onTap: () => context
                  .read<DocumentTimelineCubit>()
                  .selectFilter(ExpiryFilter.warning),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: context.l10n.documentTimelineFilterSafe,
              isSelected: state.selectedFilter == ExpiryFilter.safe,
              onTap: () => context
                  .read<DocumentTimelineCubit>()
                  .selectFilter(ExpiryFilter.safe),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? palette.primary
                : palette.surface,
            border: Border.all(
              color: isSelected
                  ? palette.primary
                  : palette.stroke,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineContent extends StatelessWidget {
  const _TimelineContent({
    required this.state,
    required this.palette,
    required this.onDocumentTap,
  });

  final DocumentTimelineState state;
  final AppPalette palette;
  final Function(String documentId) onDocumentTap;

  @override
  Widget build(BuildContext context) {
    final filteredDocs = state.filteredDocuments;

    if (filteredDocs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            context.l10n.documentTimelineNoMatches,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Group documents by month
    final groupedByMonth = <String, List<DocumentExpiryItemEntity>>{};
    for (final doc in filteredDocs) {
      final monthKey = _getMonthKey(doc.expiryDate);
      groupedByMonth
          .putIfAbsent(monthKey, () => <DocumentExpiryItemEntity>[])
          .add(doc);
    }

    // Sort months
    final sortedMonths = groupedByMonth.keys.toList()
      ..sort((a, b) {
        final aDate = _parseMonthKey(a);
        final bDate = _parseMonthKey(b);
        return aDate.compareTo(bDate);
      });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedMonths.map((monthKey) {
          final monthDocs = groupedByMonth[monthKey]!;
          return _MonthSection(
            monthKey: monthKey,
            documents: monthDocs,
            palette: palette,
            onDocumentTap: onDocumentTap,
          );
        }).toList(),
      ),
    );
  }

  String _getMonthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  DateTime _parseMonthKey(String key) {
    return DateTime.parse('$key-01');
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.monthKey,
    required this.documents,
    required this.palette,
    required this.onDocumentTap,
  });

  final String monthKey;
  final List<DocumentExpiryItemEntity> documents;
  final AppPalette palette;
  final Function(String documentId) onDocumentTap;

  @override
  Widget build(BuildContext context) {
    final monthDate = DateTime.parse('$monthKey-01');
    final monthLabel = DateFormat('MMMM yyyy').format(monthDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
          child: Text(
            monthLabel,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...documents.map((doc) {
          return _DocumentCard(
            document: doc,
            palette: palette,
            onTap: () => onDocumentTap(doc.documentId),
          );
        }).toList(),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.palette,
    required this.onTap,
  });

  final DocumentExpiryItemEntity document;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _getUrgencyColor();
    final formattedDate =
        DateFormat('MMM d, yyyy').format(document.expiryDate);
    final daysText = _getDaysText(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border.all(color: palette.stroke),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      _getUrgencyIcon(),
                      color: urgencyColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              document.documentType,
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    daysText,
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Color _getUrgencyColor() {
    switch (document.urgency) {
      case ExpiryUrgency.expired:
      case ExpiryUrgency.critical:
        return palette.danger;
      case ExpiryUrgency.warning:
        return palette.warning;
      case ExpiryUrgency.safe:
        return palette.success;
    }
  }

  IconData _getUrgencyIcon() {
    switch (document.urgency) {
      case ExpiryUrgency.expired:
        return Icons.warning_amber_rounded;
      case ExpiryUrgency.critical:
        return Icons.schedule_rounded;
      case ExpiryUrgency.warning:
        return Icons.info_rounded;
      case ExpiryUrgency.safe:
        return Icons.check_circle_rounded;
    }
  }

  String _getDaysText(BuildContext context) {
    final days = document.daysRemaining ?? 0;

    if (days < 0) {
      return context.l10n.documentTimelineExpiredDaysAgo(days.abs());
    } else if (days == 0) {
      return context.l10n.documentTimelineExpiresToday;
    } else {
      return context.l10n.documentTimelineDaysRemaining(days);
    }
  }
}
