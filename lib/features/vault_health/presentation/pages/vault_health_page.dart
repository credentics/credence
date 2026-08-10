import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/vault_error_state.dart';
import 'package:pass_doc_manager/app/presentation/widgets/credence_ui.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_issue_entity.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_issue_severity.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_issue_type.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_report_entity.dart';
import 'package:pass_doc_manager/features/vault_health/presentation/cubit/vault_health_cubit.dart';
import 'package:pass_doc_manager/features/vault_health/presentation/cubit/vault_health_state.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

const _healthFontDisplay = 'Manrope';
const _healthFontBody = 'Manrope';
const _healthFontMono = 'JetBrains Mono';

class VaultHealthPage extends StatefulWidget {
  const VaultHealthPage({
    super.key,
    this.onNavigateToCredential,
    this.onNavigateToDocument,
  });

  final void Function(BuildContext context, String credentialId)?
  onNavigateToCredential;
  final void Function(BuildContext context, String documentId)?
  onNavigateToDocument;

  @override
  State<VaultHealthPage> createState() => _VaultHealthPageState();
}

class _VaultHealthPageState extends State<VaultHealthPage> {
  final Set<VaultHealthIssueType> _expandedTypes = {};

  @override
  void initState() {
    super.initState();
    context.read<VaultHealthCubit>().evaluateHealth();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<VaultHealthCubit, VaultHealthState>(
          builder: (context, state) {
            if (state.status == VaultHealthStatus.loading &&
                state.healthReport == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == VaultHealthStatus.error &&
                state.healthReport == null) {
              return VaultErrorState(
                icon: Icons.health_and_safety_outlined,
                message: state.errorMessage ?? context.l10n.commonErrorGeneric,
                onRetry: () =>
                    context.read<VaultHealthCubit>().evaluateHealth(),
              );
            }

            final report = state.healthReport;
            if (report == null) return const SizedBox.shrink();

            return RefreshIndicator(
              onRefresh: () => context.read<VaultHealthCubit>().refresh(),
              color: palette.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _HealthTopBar(report: report)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HealthScoreOverview(report: report),
                              const SizedBox(height: 16),
                              _PrioritySummary(report: report),
                              const SizedBox(height: 18),
                              CredenceSectionLabel(
                                label: 'Coverage',
                                padding: EdgeInsets.zero,
                                trailing: _LastCheckedLabel(
                                  checkedAt: report.checkedAt,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _HealthMetricGrid(report: report),
                              const SizedBox(height: 22),
                              CredenceSectionLabel(
                                label: 'Action plan',
                                padding: EdgeInsets.zero,
                                trailing: Text(
                                  _issueCountLabel(report.issues.length),
                                  style: TextStyle(
                                    fontFamily: _healthFontMono,
                                    color: palette.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildActionPlan(context, report),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionPlan(
    BuildContext context,
    VaultHealthReportEntity report,
  ) {
    final groups = _issueGroups(report);
    if (groups.isEmpty) {
      return const _AllClearCard();
    }

    return Column(
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          _IssueGroupCard(
            group: groups[i],
            isExpanded: _expandedTypes.contains(groups[i].type),
            onToggleExpanded: () {
              setState(() {
                if (_expandedTypes.contains(groups[i].type)) {
                  _expandedTypes.remove(groups[i].type);
                } else {
                  _expandedTypes.add(groups[i].type);
                }
              });
            },
            onIssueTap: (issue) => _openIssue(context, issue),
          ),
          if (i < groups.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _openIssue(BuildContext context, VaultHealthIssueEntity issue) {
    final itemId = issue.itemId;
    if (itemId == null || itemId.trim().isEmpty) return;
    if (issue.type == VaultHealthIssueType.expiringDocument ||
        issue.type == VaultHealthIssueType.expiredDocument) {
      widget.onNavigateToDocument?.call(context, itemId);
      return;
    }
    widget.onNavigateToCredential?.call(context, itemId);
  }
}

class _HealthTopBar extends StatelessWidget {
  const _HealthTopBar({required this.report});

  final VaultHealthReportEntity report;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Row(
        children: [
          CredenceIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              context.l10n.vaultHealthPageTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _healthFontDisplay,
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.35,
              ),
            ),
          ),
          CredenceIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: () => context.read<VaultHealthCubit>().refresh(),
          ),
        ],
      ),
    );
  }
}

class _HealthScoreOverview extends StatelessWidget {
  const _HealthScoreOverview({required this.report});

  final VaultHealthReportEntity report;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final scoreColor = _scoreColor(palette, report.overallScore);
    final issueCount = report.issues.length;

    return CredenceCard(
      backgroundColor: scoreColor.withValues(alpha: 0.08),
      borderColor: scoreColor.withValues(alpha: 0.22),
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScoreRing(score: report.overallScore, color: scoreColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _scoreHeadline(report.overallScore),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _healthFontDisplay,
                        color: palette.textPrimary,
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.55,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      issueCount == 0
                          ? 'No action required right now.'
                          : _prioritySentence(report),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _healthFontBody,
                        color: palette.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: 'Credentials',
                  value: '${report.totalCredentials}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewStat(label: 'Issues', value: '$issueCount'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewStat(
                  label: 'Critical',
                  value:
                      '${_countSeverity(report, VaultHealthIssueSeverity.critical)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return SizedBox(
      width: 98,
      height: 98,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 98,
            height: 98,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: palette.surface.withValues(alpha: 0.9),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontFamily: _healthFontDisplay,
                  color: palette.textPrimary,
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SCORE',
                style: TextStyle(
                  fontFamily: _healthFontMono,
                  color: palette.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.75)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _healthFontDisplay,
              color: palette.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _healthFontMono,
              color: palette.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.75,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrioritySummary extends StatelessWidget {
  const _PrioritySummary({required this.report});

  final VaultHealthReportEntity report;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final urgentCount =
        _countSeverity(report, VaultHealthIssueSeverity.critical) +
        _countSeverity(report, VaultHealthIssueSeverity.high);

    return CredenceCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      radius: 18,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: urgentCount == 0
                  ? palette.success.withValues(alpha: 0.12)
                  : palette.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              urgentCount == 0
                  ? Icons.verified_user_rounded
                  : Icons.priority_high_rounded,
              color: urgentCount == 0 ? palette.success : palette.warning,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgentCount == 0 ? 'No urgent action' : 'Fix first',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _healthFontDisplay,
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  urgentCount == 0
                      ? 'Keep passwords unique and review expiring documents.'
                      : _firstPriorityText(report),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _healthFontBody,
                    color: palette.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CountPill(
            label: urgentCount == 0 ? 'Clear' : '$urgentCount urgent',
            color: urgentCount == 0 ? palette.success : palette.warning,
          ),
        ],
      ),
    );
  }
}

class _HealthMetricGrid extends StatelessWidget {
  const _HealthMetricGrid({required this.report});

  final VaultHealthReportEntity report;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final metrics = [
      _MetricData(
        icon: Icons.warning_rounded,
        label: 'Breached',
        value: report.breachedCount,
        color: palette.danger,
      ),
      _MetricData(
        icon: Icons.key_rounded,
        label: 'Weak',
        value: report.weakPasswordCount,
        color: palette.warning,
      ),
      _MetricData(
        icon: Icons.content_copy_rounded,
        label: 'Reused',
        value: report.reusedPasswordCount,
        color: palette.warning,
      ),
      _MetricData(
        icon: Icons.shield_outlined,
        label: 'No MFA',
        value: report.noMfaCount,
        color: palette.primary,
      ),
      _MetricData(
        icon: Icons.event_busy_rounded,
        label: 'Expired',
        value: report.expiredDocuments,
        color: palette.danger,
      ),
      _MetricData(
        icon: Icons.schedule_rounded,
        label: '30 days',
        value: report.expiringDocuments30,
        color: palette.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = constraints.maxWidth >= 540 ? 6 : 3;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _HealthMetricTile(data: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;
}

class _HealthMetricTile extends StatelessWidget {
  const _HealthMetricTile({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = data.value == 0 ? palette.success : data.color;
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: color, size: 17),
          const Spacer(),
          Text(
            '${data.value}',
            style: TextStyle(
              fontFamily: _healthFontDisplay,
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            data.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: _healthFontMono,
              color: palette.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueGroupCard extends StatelessWidget {
  const _IssueGroupCard({
    required this.group,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onIssueTap,
  });

  final _IssueGroup group;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<VaultHealthIssueEntity> onIssueTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = _severityColor(palette, group.severity);
    final visibleIssues = isExpanded
        ? group.issues
        : group.issues.take(3).toList(growable: false);

    return CredenceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      radius: 18,
      borderColor: color.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_groupIcon(group.type), color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _groupTitle(group.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _healthFontDisplay,
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _groupDetail(group.type),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _healthFontBody,
                        color: palette.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _CountPill(label: '${group.issues.length}', color: color),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: palette.stroke),
          const SizedBox(height: 2),
          for (var i = 0; i < visibleIssues.length; i++) ...[
            _IssueMiniRow(issue: visibleIssues[i], onTap: onIssueTap),
            if (i < visibleIssues.length - 1)
              Divider(height: 1, color: palette.stroke),
          ],
          if (group.issues.length > 3) ...[
            Divider(height: 1, color: palette.stroke),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onToggleExpanded,
                style: TextButton.styleFrom(
                  foregroundColor: palette.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isExpanded
                      ? 'Show less'
                      : 'Show ${group.issues.length - 3} more',
                  style: const TextStyle(
                    fontFamily: _healthFontDisplay,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IssueMiniRow extends StatelessWidget {
  const _IssueMiniRow({required this.issue, required this.onTap});

  final VaultHealthIssueEntity issue;
  final ValueChanged<VaultHealthIssueEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final canOpen = issue.itemId != null && issue.itemId!.trim().isNotEmpty;
    return InkWell(
      onTap: canOpen ? () => onTap(issue) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _severityColor(palette, issue.severity),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.itemName?.trim().isNotEmpty == true
                        ? issue.itemName!.trim()
                        : issue.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _healthFontDisplay,
                      color: palette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _rowActionText(issue.type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _healthFontBody,
                      color: palette.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (canOpen) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: palette.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: _healthFontMono,
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.65,
        ),
      ),
    );
  }
}

class _LastCheckedLabel extends StatelessWidget {
  const _LastCheckedLabel({required this.checkedAt});

  final DateTime checkedAt;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Text(
      _checkedAtLabel(checkedAt),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: _healthFontMono,
        color: palette.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _AllClearCard extends StatelessWidget {
  const _AllClearCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return CredenceCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      backgroundColor: palette.success.withValues(alpha: 0.08),
      borderColor: palette.success.withValues(alpha: 0.22),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.check_rounded, color: palette.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vault looks healthy',
                  style: TextStyle(
                    fontFamily: _healthFontDisplay,
                    color: palette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'No password, MFA, or document expiry issues were found.',
                  style: TextStyle(
                    fontFamily: _healthFontBody,
                    color: palette.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueGroup {
  const _IssueGroup({
    required this.type,
    required this.severity,
    required this.issues,
  });

  final VaultHealthIssueType type;
  final VaultHealthIssueSeverity severity;
  final List<VaultHealthIssueEntity> issues;
}

List<_IssueGroup> _issueGroups(VaultHealthReportEntity report) {
  final byType = <VaultHealthIssueType, List<VaultHealthIssueEntity>>{};
  for (final issue in report.issues) {
    byType.putIfAbsent(issue.type, () => []).add(issue);
  }

  final groups = byType.entries
      .map(
        (entry) => _IssueGroup(
          type: entry.key,
          severity: _highestSeverity(entry.value),
          issues: entry.value,
        ),
      )
      .toList();

  groups.sort((a, b) {
    final severity = _severityRank(
      a.severity,
    ).compareTo(_severityRank(b.severity));
    if (severity != 0) return severity;
    return _typeRank(a.type).compareTo(_typeRank(b.type));
  });

  return groups;
}

VaultHealthIssueSeverity _highestSeverity(List<VaultHealthIssueEntity> issues) {
  var current = VaultHealthIssueSeverity.low;
  for (final issue in issues) {
    if (_severityRank(issue.severity) < _severityRank(current)) {
      current = issue.severity;
    }
  }
  return current;
}

int _severityRank(VaultHealthIssueSeverity severity) {
  return switch (severity) {
    VaultHealthIssueSeverity.critical => 0,
    VaultHealthIssueSeverity.high => 1,
    VaultHealthIssueSeverity.medium => 2,
    VaultHealthIssueSeverity.low => 3,
  };
}

int _typeRank(VaultHealthIssueType type) {
  return switch (type) {
    VaultHealthIssueType.breachedCredential => 0,
    VaultHealthIssueType.expiredDocument => 1,
    VaultHealthIssueType.weakPassword => 2,
    VaultHealthIssueType.reusedPassword => 3,
    VaultHealthIssueType.expiringDocument => 4,
    VaultHealthIssueType.noMfa => 5,
  };
}

int _countSeverity(
  VaultHealthReportEntity report,
  VaultHealthIssueSeverity severity,
) {
  return report.issues.where((issue) => issue.severity == severity).length;
}

Color _scoreColor(AppPalette palette, int score) {
  if (score >= 80) return palette.success;
  if (score >= 60) return palette.primary;
  if (score >= 40) return palette.warning;
  return palette.danger;
}

Color _severityColor(AppPalette palette, VaultHealthIssueSeverity severity) {
  return switch (severity) {
    VaultHealthIssueSeverity.critical => palette.danger,
    VaultHealthIssueSeverity.high => palette.warning,
    VaultHealthIssueSeverity.medium => palette.primary,
    VaultHealthIssueSeverity.low => palette.textSecondary,
  };
}

String _scoreHeadline(int score) {
  if (score >= 80) return 'Strong vault';
  if (score >= 60) return 'Mostly healthy';
  if (score >= 40) return 'Needs review';
  return 'Needs attention';
}

String _prioritySentence(VaultHealthReportEntity report) {
  final critical = _countSeverity(report, VaultHealthIssueSeverity.critical);
  final high = _countSeverity(report, VaultHealthIssueSeverity.high);
  if (critical > 0) {
    return 'Start with $critical critical ${critical == 1 ? 'issue' : 'issues'}, then clean up high-risk passwords.';
  }
  if (high > 0) {
    return 'Start with $high high-risk ${high == 1 ? 'issue' : 'issues'} before medium cleanup.';
  }
  return 'Only medium or low-risk cleanup remains.';
}

String _firstPriorityText(VaultHealthReportEntity report) {
  if (report.breachedCount > 0) {
    return 'Change breached passwords before anything else.';
  }
  if (report.expiredDocuments > 0) {
    return 'Renew expired documents before they block travel or admin tasks.';
  }
  if (report.weakPasswordCount > 0) {
    return 'Update weak passwords with stronger unique ones.';
  }
  if (report.reusedPasswordCount > 0) {
    return 'Replace reused passwords so one leak cannot unlock many accounts.';
  }
  return 'Review the grouped action plan below.';
}

String _groupTitle(VaultHealthIssueType type) {
  return switch (type) {
    VaultHealthIssueType.breachedCredential => 'Change breached passwords',
    VaultHealthIssueType.expiredDocument => 'Renew expired documents',
    VaultHealthIssueType.weakPassword => 'Update weak passwords',
    VaultHealthIssueType.reusedPassword => 'Replace reused passwords',
    VaultHealthIssueType.expiringDocument => 'Renew documents soon',
    VaultHealthIssueType.noMfa => 'Add MFA recovery codes',
  };
}

String _groupDetail(VaultHealthIssueType type) {
  return switch (type) {
    VaultHealthIssueType.breachedCredential =>
      'These passwords have appeared in known breaches.',
    VaultHealthIssueType.expiredDocument =>
      'Expired documents should be renewed or archived.',
    VaultHealthIssueType.weakPassword =>
      'Use stronger unique passwords for these accounts.',
    VaultHealthIssueType.reusedPassword =>
      'Give each account a different password.',
    VaultHealthIssueType.expiringDocument =>
      'Renew or prepare replacements before expiry.',
    VaultHealthIssueType.noMfa =>
      'Store recovery codes so MFA does not lock you out.',
  };
}

String _rowActionText(VaultHealthIssueType type) {
  return switch (type) {
    VaultHealthIssueType.breachedCredential => 'Open and change password',
    VaultHealthIssueType.expiredDocument => 'Open document details',
    VaultHealthIssueType.weakPassword => 'Open and strengthen password',
    VaultHealthIssueType.reusedPassword => 'Open and make unique',
    VaultHealthIssueType.expiringDocument => 'Open renewal details',
    VaultHealthIssueType.noMfa => 'Open and add recovery codes',
  };
}

IconData _groupIcon(VaultHealthIssueType type) {
  return switch (type) {
    VaultHealthIssueType.breachedCredential => Icons.warning_rounded,
    VaultHealthIssueType.expiredDocument => Icons.event_busy_rounded,
    VaultHealthIssueType.weakPassword => Icons.key_rounded,
    VaultHealthIssueType.reusedPassword => Icons.content_copy_rounded,
    VaultHealthIssueType.expiringDocument => Icons.schedule_rounded,
    VaultHealthIssueType.noMfa => Icons.shield_outlined,
  };
}

String _checkedAtLabel(DateTime checkedAt) {
  final local = checkedAt.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (sameDay) return 'CHECKED ${DateFormat('HH:mm').format(local)}';
  return 'CHECKED ${DateFormat('MMM d').format(local).toUpperCase()}';
}

String _issueCountLabel(int count) {
  if (count == 0) return 'NO ISSUES';
  if (count == 1) return '1 ISSUE';
  return '$count ISSUES';
}
