import 'dart:convert';

import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';

class NotificationSettingsPrefs {
  const NotificationSettingsPrefs({
    required this.expiryAlertsEnabled,
    required this.leadDays,
    required this.collectionRemindersEnabled,
    required this.lockScreenWidgetEnabled,
    required this.dueTodayDigestEnabled,
    required this.overdueAlertsEnabled,
    required this.quietStartMinutes,
    required this.quietEndMinutes,
  });

  static const defaults = NotificationSettingsPrefs(
    expiryAlertsEnabled: true,
    leadDays: <int>{30, 14, 7, 1},
    collectionRemindersEnabled: true,
    lockScreenWidgetEnabled: true,
    dueTodayDigestEnabled: true,
    overdueAlertsEnabled: true,
    quietStartMinutes: 22 * 60,
    quietEndMinutes: 8 * 60,
  );

  final bool expiryAlertsEnabled;
  final Set<int> leadDays;
  final bool collectionRemindersEnabled;
  final bool lockScreenWidgetEnabled;
  final bool dueTodayDigestEnabled;
  final bool overdueAlertsEnabled;
  final int quietStartMinutes;
  final int quietEndMinutes;

  NotificationSettingsPrefs copyWith({
    bool? expiryAlertsEnabled,
    Set<int>? leadDays,
    bool? collectionRemindersEnabled,
    bool? lockScreenWidgetEnabled,
    bool? dueTodayDigestEnabled,
    bool? overdueAlertsEnabled,
    int? quietStartMinutes,
    int? quietEndMinutes,
  }) {
    return NotificationSettingsPrefs(
      expiryAlertsEnabled: expiryAlertsEnabled ?? this.expiryAlertsEnabled,
      leadDays: leadDays ?? this.leadDays,
      collectionRemindersEnabled:
          collectionRemindersEnabled ?? this.collectionRemindersEnabled,
      lockScreenWidgetEnabled:
          lockScreenWidgetEnabled ?? this.lockScreenWidgetEnabled,
      dueTodayDigestEnabled:
          dueTodayDigestEnabled ?? this.dueTodayDigestEnabled,
      overdueAlertsEnabled: overdueAlertsEnabled ?? this.overdueAlertsEnabled,
      quietStartMinutes: quietStartMinutes ?? this.quietStartMinutes,
      quietEndMinutes: quietEndMinutes ?? this.quietEndMinutes,
    );
  }

  bool isInsideQuietHours(DateTime localTime) {
    final minuteOfDay = localTime.hour * 60 + localTime.minute;
    if (quietStartMinutes == quietEndMinutes) return false;
    if (quietStartMinutes < quietEndMinutes) {
      return minuteOfDay >= quietStartMinutes && minuteOfDay < quietEndMinutes;
    }
    return minuteOfDay >= quietStartMinutes || minuteOfDay < quietEndMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'expiry_alerts_enabled': expiryAlertsEnabled,
      'lead_days': _sortedLeadDays(),
      'collection_reminders_enabled': collectionRemindersEnabled,
      'lock_screen_widget_enabled': lockScreenWidgetEnabled,
      'due_today_digest_enabled': dueTodayDigestEnabled,
      'overdue_alerts_enabled': overdueAlertsEnabled,
      'quiet_start_minutes': quietStartMinutes,
      'quiet_end_minutes': quietEndMinutes,
    };
  }

  factory NotificationSettingsPrefs.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsPrefs(
      expiryAlertsEnabled:
          map['expiry_alerts_enabled'] as bool? ?? defaults.expiryAlertsEnabled,
      leadDays: _readLeadDays(map['lead_days']),
      collectionRemindersEnabled:
          map['collection_reminders_enabled'] as bool? ??
          defaults.collectionRemindersEnabled,
      lockScreenWidgetEnabled:
          map['lock_screen_widget_enabled'] as bool? ??
          defaults.lockScreenWidgetEnabled,
      dueTodayDigestEnabled:
          map['due_today_digest_enabled'] as bool? ??
          defaults.dueTodayDigestEnabled,
      overdueAlertsEnabled:
          map['overdue_alerts_enabled'] as bool? ??
          defaults.overdueAlertsEnabled,
      quietStartMinutes: _readMinute(
        map['quiet_start_minutes'],
        defaults.quietStartMinutes,
      ),
      quietEndMinutes: _readMinute(
        map['quiet_end_minutes'],
        defaults.quietEndMinutes,
      ),
    );
  }

  List<int> _sortedLeadDays() {
    final days = leadDays.toList()..sort((a, b) => b.compareTo(a));
    return days;
  }

  static Set<int> _readLeadDays(dynamic raw) {
    const allowed = <int>{1, 3, 7, 14, 30};
    if (raw is Iterable) {
      final days = raw
          .map((value) => value is int ? value : int.tryParse('$value'))
          .whereType<int>()
          .where(allowed.contains)
          .toSet();
      return days.isEmpty ? defaults.leadDays : days;
    }
    return defaults.leadDays;
  }

  static int _readMinute(dynamic raw, int fallback) {
    final value = raw is int ? raw : int.tryParse('$raw');
    if (value == null || value < 0 || value >= 24 * 60) return fallback;
    return value;
  }
}

class NotificationSettingsStore {
  NotificationSettingsStore._();

  static final NotificationSettingsStore instance =
      NotificationSettingsStore._();

  static const _boxName = 'credence_notification_settings_v1';
  static const _prefsKey = 'notification_settings';

  dynamic _box;

  Future<NotificationSettingsPrefs> read() async {
    final box = await _openBox();
    final raw = box.get(_prefsKey);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return NotificationSettingsPrefs.fromMap(decoded);
      } catch (_) {
        return NotificationSettingsPrefs.defaults;
      }
    }
    if (raw is Map) {
      return NotificationSettingsPrefs.fromMap(Map<String, dynamic>.from(raw));
    }
    return NotificationSettingsPrefs.defaults;
  }

  Future<void> write(NotificationSettingsPrefs prefs) async {
    final box = await _openBox();
    await box.put(_prefsKey, jsonEncode(prefs.toMap()));
  }

  Future<dynamic> _openBox() async {
    return _box ??= await EncryptedHiveBoxFactory.openEncryptedBox(_boxName);
  }
}
