import 'package:flutter/foundation.dart';
import 'package:pass_doc_manager/data/documents/datasources/local/document_local_data_source.dart';
import 'package:pass_doc_manager/features/collections/presentation/services/reminder_notification_service.dart';
import 'package:pass_doc_manager/features/settings/data/notification_settings_store.dart';

/// Schedules local notifications for documents approaching their expiry date.
///
/// Call [scheduleExpiryNotifications] on app startup (after unlock) to scan all
/// documents and schedule the lead times selected in notification settings.
class DocumentExpiryService {
  DocumentExpiryService({required DocumentLocalDataSource documentDataSource})
    : _documentDataSource = documentDataSource;

  static const _supportedLeadDays = <int>[30, 14, 7, 3, 1];
  static const _legacyLeadDays = <int>[90, 0];

  final DocumentLocalDataSource _documentDataSource;

  Future<void> scheduleExpiryNotifications() async {
    try {
      final prefs = await NotificationSettingsStore.instance.read();
      final documents = await _documentDataSource.getDocuments();
      final now = DateTime.now();
      final notificationService = ReminderNotificationService.instance;
      final leadDays = prefs.leadDays.toList()..sort((a, b) => b.compareTo(a));

      for (final doc in documents) {
        if (doc.expiryAtIso.trim().isEmpty) continue;
        final expiry = DateTime.tryParse(doc.expiryAtIso);
        if (expiry == null) continue;

        for (final day in {..._supportedLeadDays, ..._legacyLeadDays}) {
          await notificationService.cancelReminder('expiry_${day}_${doc.id}');
        }

        if (!prefs.expiryAlertsEnabled || expiry.isBefore(now)) continue;

        for (final day in leadDays) {
          final scheduledAt = expiry.subtract(Duration(days: day));
          if (scheduledAt.isBefore(now)) continue;
          await notificationService.scheduleReminder(
            id: 'expiry_${day}_${doc.id}',
            title: 'Document Expiry Reminder',
            body: _expiryBody(doc.title, day),
            scheduledAt: scheduledAt,
            kind: ReminderNotificationKind.documentExpiry,
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[DocumentExpiryService] Failed to schedule notifications: $e',
      );
    }
  }

  String _expiryBody(String title, int leadDays) {
    if (leadDays == 1) return 'Your $title expires tomorrow';
    return 'Your $title expires in $leadDays days';
  }
}
