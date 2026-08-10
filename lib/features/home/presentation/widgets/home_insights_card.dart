import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class HomeInsightsCard extends StatelessWidget {
  const HomeInsightsCard({super.key, required this.insights});

  final HomeInsights insights;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    if (insights.totalIssues == 0) {
      return _allGoodCard(context, palette);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.dangerSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 19,
                  color: palette.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.homeVaultInsights,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.dangerSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${insights.totalIssues} issue${insights.totalIssues == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (insights.expiringDocuments > 0)
            _insightRow(
              Icons.schedule_rounded,
              const Color(0xFFFFF3E0),
              palette.warning,
              '${insights.expiringDocuments} document${insights.expiringDocuments == 1 ? '' : 's'} expiring soon',
              palette,
            ),
          if (insights.missingFiles > 0)
            _insightRow(
              Icons.warning_amber_rounded,
              const Color(0xFFFFF3E0),
              const Color(0xFFF29918),
              '${insights.missingFiles} document${insights.missingFiles == 1 ? '' : 's'} need${insights.missingFiles == 1 ? 's' : ''} attention',
              palette,
            ),
          if (insights.incompleteChecklists > 0)
            _insightRow(
              Icons.checklist_rounded,
              const Color(0xFFF3EFFF),
              const Color(0xFF8B5CF6),
              '${insights.incompleteChecklists} incomplete checklist${insights.incompleteChecklists == 1 ? '' : 's'}',
              palette,
            ),
          if (insights.securityWarnings > 0)
            _insightRow(
              Icons.lock_open_rounded,
              palette.dangerSoft,
              palette.danger,
              '${insights.securityWarnings} credential${insights.securityWarnings == 1 ? '' : 's'} with security warnings',
              palette,
            ),
        ],
      ),
    );
  }

  Widget _insightRow(
    IconData icon,
    Color iconBg,
    Color iconColor,
    String text,
    AppPalette palette,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _allGoodCard(BuildContext context, AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F8F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 22,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeEverythingGood,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.homeVaultUpToDate,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
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
