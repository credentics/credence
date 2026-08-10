import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class PasswordHealthFooter extends StatelessWidget {
  const PasswordHealthFooter({
    super.key,
    required this.password,
    required this.isEvaluating,
    required this.report,
  });

  final String password;
  final bool isEvaluating;
  final PasswordHealthReportEntity? report;

  @override
  Widget build(BuildContext context) {
    if (password.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (isEvaluating) {
      return Text(
        context.l10n.passwordHealthChecking,
        style: TextStyle(
          color: context.appPalette.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final currentReport = report;
    if (currentReport == null) {
      return const SizedBox.shrink();
    }

    final status = PasswordHealthDisplayStatus.fromLevel(
      context,
      currentReport.level,
    );
    return Text(
      '${status.label} • ${currentReport.score}/100',
      style: TextStyle(
        color: status.color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

@immutable
class PasswordHealthDisplayStatus {
  const PasswordHealthDisplayStatus({required this.label, required this.color});

  final String label;
  final Color color;

  static PasswordHealthDisplayStatus fromLevel(
    BuildContext context,
    PasswordHealthLevel level,
  ) {
    final l10n = context.l10n;
    return switch (level) {
      PasswordHealthLevel.weak => PasswordHealthDisplayStatus(
        label: l10n.passwordHealthWeak,
        color: context.appPalette.danger,
      ),
      PasswordHealthLevel.fair => PasswordHealthDisplayStatus(
        label: l10n.passwordHealthFair,
        color: context.appPalette.warning,
      ),
      PasswordHealthLevel.strong => PasswordHealthDisplayStatus(
        label: l10n.passwordHealthStrong,
        color: context.appPalette.success,
      ),
      PasswordHealthLevel.excellent => PasswordHealthDisplayStatus(
        label: l10n.passwordHealthExcellent,
        color: context.appPalette.success,
      ),
    };
  }
}
