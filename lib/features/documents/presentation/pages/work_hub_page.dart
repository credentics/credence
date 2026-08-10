import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_vaults.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/work_hub_cubit.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/work_hub_state.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_company_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_company_entry_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/work_payslip_history_page.dart';
import 'package:pass_doc_manager/features/documents/presentation/widgets/work_documents_design.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class WorkHubPage extends StatelessWidget {
  const WorkHubPage({
    super.key,
    GetWorkCompanyVaults? getWorkCompanyVaults,
    this.embeddedDesktop = false,
  }) : _getWorkCompanyVaults = getWorkCompanyVaults;

  final GetWorkCompanyVaults? _getWorkCompanyVaults;
  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    final content = BlocProvider(
      create: (_) =>
          WorkHubCubit(getWorkCompanyVaults: _getWorkCompanyVaults)..load(),
      child: _WorkHubView(embeddedDesktop: embeddedDesktop),
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

class _WorkHubView extends StatelessWidget {
  const _WorkHubView({required this.embeddedDesktop});

  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    final horizontal = embeddedDesktop ? 24.0 : 16.0;
    return BlocBuilder<WorkHubCubit, WorkHubState>(
      builder: (context, state) {
        if ((state.viewStatus == WorkHubViewStatus.initial ||
                state.viewStatus == WorkHubViewStatus.loading) &&
            state.companies.isEmpty) {
          return const Center(child: CupertinoActivityIndicator(radius: 12));
        }

        if (state.viewStatus == WorkHubViewStatus.error &&
            state.companies.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage ?? context.l10n.workHubLoadError,
                  style: TextStyle(
                    fontFamily: workFontBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.appPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: context.read<WorkHubCubit>().load,
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          );
        }

        final visibleCompanies = state.visibleCompanies;
        final l10n = context.l10n;
        final palette = context.appPalette;
        final recentCompanies = state.companies.toList(growable: false)
          ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
        final totalDocuments = state.companies.fold<int>(
          0,
          (total, company) => total + company.documentsCount,
        );
        final lastUpdatedLabel = state.companies.isEmpty
            ? l10n.workHubNoAccessYet
            : _relativeLabel(context, recentCompanies.first.lastUpdatedAt);
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = embeddedDesktop || constraints.maxWidth >= 900;
            return Scaffold(
              backgroundColor: palette.background,
              body: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: embeddedDesktop ? 980 : 620,
                    ),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        12,
                        horizontal,
                        100,
                      ),
                      children: [
                        WorkDesignTopBar(
                          showBack: !isDesktop,
                          onBackTap: () => Navigator.of(context).maybePop(),
                          onSearchTap: null,
                          onAddTap: () => _openCreate(context),
                        ),
                        const SizedBox(height: 20),
                        WorkIntroHeader(
                          kicker: l10n.workHubSubtitle,
                          title: l10n.workHubTitle,
                          subtitle:
                              '${state.companies.length} workspaces · $totalDocuments work documents · ${l10n.workHubUpdatedCompact(lastUpdatedLabel)}.',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: context.read<WorkHubCubit>().setQuery,
                          style: TextStyle(
                            fontFamily: workFontBody,
                            color: palette.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.workHubSearchHint,
                            hintStyle: TextStyle(
                              fontFamily: workFontBody,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: palette.textMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: palette.textMuted,
                              size: 22,
                            ),
                            filled: true,
                            fillColor: palette.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: palette.stroke),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: palette.stroke),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: palette.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        WorkSectionLabel(
                          value: l10n.workCompanyFolderPayslipsTitle,
                        ),
                        const SizedBox(height: 8),
                        _WorkPayslipsEntryCard(
                          companyCount: state.companies.length,
                          onTap: () => _openGlobalPayslips(context),
                        ),
                        if (recentCompanies.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          WorkSectionLabel(value: l10n.workHubFilterRecent),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 146,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recentCompanies.take(6).length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final company = recentCompanies[index];
                                return WorkRecentTile(
                                  title: company.companyName,
                                  meta: _relativeLabel(
                                    context,
                                    company.lastUpdatedAt,
                                  ),
                                  onTap: () => _openCompany(context, company),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        WorkSectionLabel(
                          value:
                              '${l10n.workHubFilterAll} · ${visibleCompanies.length}',
                        ),
                        const SizedBox(height: 8),
                        if (visibleCompanies.isEmpty)
                          _WorkEmptyCard(onAddTap: () => _openCreate(context))
                        else
                          ...visibleCompanies.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: WorkCompanyCard(
                                name: entry.value.companyName,
                                role: _companyRoleLine(entry.value),
                                logoPath: entry.value.companyLogoPath,
                                tint: _companyTint(entry.key),
                                stats: [
                                  l10n.documentFilesCount(
                                    entry.value.documentsCount,
                                  ),
                                  if (entry.value.isPinned)
                                    l10n.workHubFilterPinned,
                                  l10n.workHubUpdatedCompact(
                                    _relativeLabel(
                                      context,
                                      entry.value.lastUpdatedAt,
                                    ),
                                  ),
                                ],
                                onTap: () => _openCompany(context, entry.value),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              floatingActionButton: isDesktop
                  ? null
                  : FloatingActionButton(
                      onPressed: () => _openCreate(context),
                      backgroundColor: context.appPalette.primary,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.add_rounded, size: 30),
                    ),
            );
          },
        );
      },
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final createdId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const WorkCompanyEntryPage()),
    );
    if (!context.mounted || (createdId ?? '').trim().isEmpty) {
      return;
    }
    await context.read<WorkHubCubit>().load();
  }

  Future<void> _openCompany(
    BuildContext context,
    WorkCompanyVaultEntity company,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkCompanyPage(companyId: company.companyId),
      ),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<WorkHubCubit>().load();
  }

  Future<void> _openGlobalPayslips(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => WorkPayslipHistoryPage.global()),
    );
    if (!context.mounted) {
      return;
    }
    await context.read<WorkHubCubit>().load();
  }
}

class _WorkPayslipsEntryCard extends StatelessWidget {
  const _WorkPayslipsEntryCard({
    required this.companyCount,
    required this.onTap,
  });

  final int companyCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.appPalette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: workTintBackground(context, WorkTint.blush),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: workTintForeground(context, WorkTint.blush),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.workHubFeaturedAction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: workFontDisplay,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.workHubFeaturedSubtitleCompact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: workFontBody,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      l10n
                          .workHubCompaniesCountBadge(companyCount)
                          .toUpperCase(),
                      style: TextStyle(
                        fontFamily: workFontMono,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: palette.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkEmptyCard extends StatelessWidget {
  const _WorkEmptyCard({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.workHubEmptyTitle,
            style: TextStyle(
              fontFamily: workFontDisplay,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.workHubEmptySubtitle,
            style: TextStyle(
              fontFamily: workFontBody,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
              height: 1.32,
            ),
          ),
          SizedBox(height: 12),
          FilledButton(
            onPressed: onAddTap,
            style: FilledButton.styleFrom(
              backgroundColor: context.appPalette.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              l10n.workHubAddFirstCompanyAction,
              style: const TextStyle(
                fontFamily: workFontBody,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeLabel(BuildContext context, DateTime value) {
  final now = DateTime.now();
  final localValue = value.isUtc ? value.toLocal() : value;
  final delta = now.difference(localValue);
  if (delta.isNegative || delta.inMinutes < 1) {
    return context.l10n.documentsRelativeJustNow;
  }
  if (delta.inMinutes < 60) {
    return context.l10n.homeRelativeMinutesAgo(delta.inMinutes);
  }
  if (delta.inHours < 24) {
    return context.l10n.homeRelativeHoursAgo(delta.inHours);
  }
  if (delta.inDays == 1) {
    return context.l10n.documentsRelativeYesterday;
  }
  if (delta.inDays < 7) {
    return context.l10n.homeRelativeDaysAgo(delta.inDays);
  }
  if (delta.inDays < 30) {
    final weeks = (delta.inDays / 7).floor().clamp(1, 4);
    return context.l10n.homeRelativeWeeksAgo(weeks);
  }
  if (delta.inDays < 365) {
    final months = (delta.inDays / 30).floor().clamp(1, 12);
    return context.l10n.homeRelativeMonthsAgo(months);
  }
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(localeTag).format(localValue);
}

String _companyRoleLine(WorkCompanyVaultEntity company) {
  final role = company.roleLabel.trim();
  final address = company.addressLabel.trim();
  final startedAt = company.startedAt;
  final parts = <String>[
    if (role.isNotEmpty) role,
    if (address.isNotEmpty) address,
    if (startedAt != null) '${startedAt.year}',
  ];
  if (parts.isEmpty) {
    return company.contactLabel.trim().isEmpty
        ? company.companyName
        : company.contactLabel.trim();
  }
  return parts.join(' · ');
}

WorkTint _companyTint(int index) {
  const values = <WorkTint>[
    WorkTint.lavender,
    WorkTint.blush,
    WorkTint.mint,
    WorkTint.blue,
    WorkTint.peach,
    WorkTint.sand,
  ];
  return values[index % values.length];
}
