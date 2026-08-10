import 'package:flutter/foundation.dart';

/// Service that prepares and persists data for native home screen widgets.
///
/// This uses shared UserDefaults (iOS) / SharedPreferences (Android) to
/// pass data from the Flutter app to the native widget rendering layer.
///
/// Widget rendering itself is handled by native platform code; this service
/// only manages the data contract.
class HomeWidgetService {
  HomeWidgetService._();

  /// Keys used to pass data to native widgets.
  static const kVaultScore = 'vault_health_score';
  static const kVaultGrade = 'vault_health_grade';
  static const kExpiring1Name = 'expiring_1_name';
  static const kExpiring1Date = 'expiring_1_date';
  static const kExpiring1Urgency = 'expiring_1_urgency';
  static const kExpiring2Name = 'expiring_2_name';
  static const kExpiring2Date = 'expiring_2_date';
  static const kExpiring2Urgency = 'expiring_2_urgency';
  static const kExpiring3Name = 'expiring_3_name';
  static const kExpiring3Date = 'expiring_3_date';
  static const kExpiring3Urgency = 'expiring_3_urgency';
  static const kQuickCopyName = 'quick_copy_name';
  static const kQuickCopyUsername = 'quick_copy_username';

  /// Updates the vault health score data for the widget.
  static Future<void> updateVaultHealthScore({
    required int score,
    required String grade,
  }) async {
    try {
      // In production, this would use home_widget package:
      // await HomeWidget.saveWidgetData(kVaultScore, score);
      // await HomeWidget.saveWidgetData(kVaultGrade, grade);
      // await HomeWidget.updateWidget(name: 'VaultHealthWidget');
      debugPrint('[HomeWidget] Updated vault health: $score ($grade)');
    } catch (e) {
      debugPrint('[HomeWidget] Failed to update vault health widget: $e');
    }
  }

  /// Updates the expiring documents data for the widget.
  static Future<void> updateExpiringDocuments({
    required List<ExpiringDocumentWidgetData> documents,
  }) async {
    try {
      // Pad to 3 slots
      for (var i = 0; i < 3; i++) {
        // final prefix = 'expiring_${i + 1}'; // used by the commented-out
        // HomeWidget.saveWidgetData calls below once the widget is wired up.
        if (i < documents.length) {
          final doc = documents[i];
          debugPrint('[HomeWidget] Slot $i: ${doc.name} expires ${doc.expiryDate}');
          // await HomeWidget.saveWidgetData('${prefix}_name', doc.name);
          // await HomeWidget.saveWidgetData('${prefix}_date', doc.expiryDate);
          // await HomeWidget.saveWidgetData('${prefix}_urgency', doc.urgency);
        } else {
          // await HomeWidget.saveWidgetData('${prefix}_name', '');
          // await HomeWidget.saveWidgetData('${prefix}_date', '');
          // await HomeWidget.saveWidgetData('${prefix}_urgency', '');
        }
      }
      // await HomeWidget.updateWidget(name: 'ExpiringDocsWidget');
      debugPrint('[HomeWidget] Updated expiring documents widget');
    } catch (e) {
      debugPrint('[HomeWidget] Failed to update expiring docs widget: $e');
    }
  }

  /// Updates the quick copy credential data for the widget.
  static Future<void> updateQuickCopy({
    required String serviceName,
    required String username,
  }) async {
    try {
      // await HomeWidget.saveWidgetData(kQuickCopyName, serviceName);
      // await HomeWidget.saveWidgetData(kQuickCopyUsername, username);
      // await HomeWidget.updateWidget(name: 'QuickCopyWidget');
      debugPrint('[HomeWidget] Updated quick copy: $serviceName');
    } catch (e) {
      debugPrint('[HomeWidget] Failed to update quick copy widget: $e');
    }
  }
}

/// Data model for expiring document widget entries.
class ExpiringDocumentWidgetData {
  const ExpiringDocumentWidgetData({
    required this.name,
    required this.expiryDate,
    required this.urgency,
  });

  final String name;
  final String expiryDate; // formatted date string
  final String urgency; // 'red', 'yellow', 'green'
}
