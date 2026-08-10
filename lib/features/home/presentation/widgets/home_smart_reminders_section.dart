import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/home/domain/entities/smart_reminder_entity.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class HomeSmartRemindersSection extends StatelessWidget {
  const HomeSmartRemindersSection({
    super.key,
    required this.reminders,
    this.onDismiss,
    this.onTap,
  });

  final List<SmartReminderEntity> reminders;
  final ValueChanged<String>? onDismiss;
  final ValueChanged<SmartReminderEntity>? onTap;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) return const SizedBox.shrink();

    final palette = context.appPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, palette),
        const SizedBox(height: 14),
        for (int i = 0; i < reminders.length; i++)
          _TimelineReminderRow(
            reminder: reminders[i],
            isLast: i == reminders.length - 1,
            onDismiss: onDismiss,
            onTap: () => onTap?.call(reminders[i]),
          ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, AppPalette palette) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            size: 15,
            color: Color(0xFFF29918),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.homeSmartReminders,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${reminders.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF29918),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineReminderRow extends StatelessWidget {
  const _TimelineReminderRow({
    required this.reminder,
    required this.isLast,
    this.onDismiss,
    this.onTap,
  });

  final SmartReminderEntity reminder;
  final bool isLast;
  final ValueChanged<String>? onDismiss;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = _actionColor(reminder.action);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail: icon + line
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _actionIcon(reminder.action),
                    size: 18,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: palette.stroke,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Material(
                color: palette.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.stroke),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                reminder.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => onDismiss?.call(reminder.id),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: palette.textMuted.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: palette.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _badge(context, color),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_badgeIcon(reminder.action), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            _badgeLabel(context, reminder.action),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Color _actionColor(ReminderAction action) {
    switch (action) {
      case ReminderAction.renew:
        return const Color(0xFFD97706);
      case ReminderAction.resolve:
        return const Color(0xFFB42318);
      case ReminderAction.uploadNow:
        return const Color(0xFF3B82F6);
      case ReminderAction.viewDetails:
        return const Color(0xFF8B5CF6);
    }
  }

  static IconData _actionIcon(ReminderAction action) {
    switch (action) {
      case ReminderAction.renew:
        return Icons.schedule_rounded;
      case ReminderAction.resolve:
        return Icons.warning_amber_rounded;
      case ReminderAction.uploadNow:
        return Icons.cloud_upload_rounded;
      case ReminderAction.viewDetails:
        return Icons.visibility_rounded;
    }
  }

  static IconData _badgeIcon(ReminderAction action) {
    switch (action) {
      case ReminderAction.renew:
        return Icons.autorenew_rounded;
      case ReminderAction.resolve:
        return Icons.priority_high_rounded;
      case ReminderAction.uploadNow:
        return Icons.upload_rounded;
      case ReminderAction.viewDetails:
        return Icons.open_in_new_rounded;
    }
  }

  static String _badgeLabel(BuildContext context, ReminderAction action) {
    switch (action) {
      case ReminderAction.renew:
        return context.l10n.reminderActionRenewal;
      case ReminderAction.resolve:
        return context.l10n.reminderActionRequired;
      case ReminderAction.uploadNow:
        return context.l10n.reminderActionUpload;
      case ReminderAction.viewDetails:
        return context.l10n.reminderActionViewDetails;
    }
  }
}
