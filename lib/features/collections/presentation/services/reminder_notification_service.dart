import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pass_doc_manager/features/settings/data/notification_settings_store.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum ReminderNotificationKind {
  collection,
  documentExpiry,
  taskDueTodayDigest,
  taskOverdue,
}

class ReminderNotificationService {
  ReminderNotificationService._();

  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Notification tapped - payload contains collectionId:blockId
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleReminder({
    required String id,
    required String title,
    String? body,
    required DateTime scheduledAt,
    String? repeatInterval,
    ReminderNotificationKind kind = ReminderNotificationKind.collection,
  }) async {
    NotificationSettingsPrefs prefs = NotificationSettingsPrefs.defaults;
    try {
      prefs = await NotificationSettingsStore.instance.read();
      if (!_isEnabled(kind, prefs)) return;
    } catch (error) {
      debugPrint('Failed to read notification settings: $error');
    }

    await init();
    final notificationId = id.hashCode.abs() % 2147483647;

    final tzScheduled = tz.TZDateTime.from(scheduledAt, tz.local);
    if (tzScheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    final quiet = prefs.isInsideQuietHours(scheduledAt.toLocal());
    final channel = _channelFor(kind);
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: quiet ? Importance.low : Importance.high,
      priority: quiet ? Priority.low : Priority.high,
      playSound: !quiet,
      enableVibration: !quiet,
      silent: quiet,
    );
    final darwinDetails = DarwinNotificationDetails(
      presentSound: !quiet,
      interruptionLevel: quiet
          ? InterruptionLevel.passive
          : InterruptionLevel.active,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final matchInterval = _matchDateTimeComponents(repeatInterval);

    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: tzScheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchInterval,
    );
  }

  Future<void> cancelReminder(String id) async {
    await init();
    final notificationId = id.hashCode.abs() % 2147483647;
    await _plugin.cancel(id: notificationId);
  }

  DateTimeComponents? _matchDateTimeComponents(String? repeatInterval) {
    return switch (repeatInterval) {
      'daily' => DateTimeComponents.time,
      'weekly' => DateTimeComponents.dayOfWeekAndTime,
      'monthly' => DateTimeComponents.dayOfMonthAndTime,
      'yearly' => DateTimeComponents.dateAndTime,
      _ => null,
    };
  }

  bool _isEnabled(
    ReminderNotificationKind kind,
    NotificationSettingsPrefs prefs,
  ) {
    return switch (kind) {
      ReminderNotificationKind.collection => prefs.collectionRemindersEnabled,
      ReminderNotificationKind.documentExpiry => prefs.expiryAlertsEnabled,
      ReminderNotificationKind.taskDueTodayDigest =>
        prefs.dueTodayDigestEnabled,
      ReminderNotificationKind.taskOverdue => prefs.overdueAlertsEnabled,
    };
  }

  ({String id, String name, String description}) _channelFor(
    ReminderNotificationKind kind,
  ) {
    return switch (kind) {
      ReminderNotificationKind.collection => (
        id: 'collection_reminders',
        name: 'Collection Reminders',
        description: 'Reminders from your collections',
      ),
      ReminderNotificationKind.documentExpiry => (
        id: 'document_expiry',
        name: 'Document Expiry',
        description: 'Expiry reminders for documents',
      ),
      ReminderNotificationKind.taskDueTodayDigest => (
        id: 'task_digest',
        name: 'Task Digest',
        description: 'Daily digest for tasks due today',
      ),
      ReminderNotificationKind.taskOverdue => (
        id: 'task_overdue',
        name: 'Overdue Tasks',
        description: 'Daily reminders for overdue tasks',
      ),
    };
  }
}
