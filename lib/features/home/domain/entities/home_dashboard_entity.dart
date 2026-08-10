import 'package:pass_doc_manager/features/home/domain/entities/pinned_item_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/quick_access_item_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/recent_item_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/smart_reminder_entity.dart';

class HomeDashboardEntity {
  const HomeDashboardEntity({
    required this.firstName,
    this.photoPath,
    this.smartReminders = const [],
    this.frequentlyUsed = const [],
    this.quickAccessGroups = const [],
    this.recentItems = const [],
    this.pinnedItems = const [],
    this.insights = const HomeInsights(),
    this.credentialCount = 0,
    this.documentCount = 0,
    this.collectionCount = 0,
    this.taskListCount = 0,
    this.openTaskCount = 0,
    this.overdueTaskCount = 0,
  });

  final String firstName;
  final String? photoPath;
  final List<SmartReminderEntity> smartReminders;
  final List<RecentItemEntity> frequentlyUsed;
  final List<QuickAccessGroupEntity> quickAccessGroups;
  final List<RecentItemEntity> recentItems;
  final List<PinnedItemEntity> pinnedItems;
  final HomeInsights insights;
  final int credentialCount;
  final int documentCount;
  final int collectionCount;
  final int taskListCount;
  final int openTaskCount;
  final int overdueTaskCount;

  int get totalVaultItems =>
      credentialCount + documentCount + collectionCount + taskListCount;
}

class HomeInsights {
  const HomeInsights({
    this.expiringDocuments = 0,
    this.missingFiles = 0,
    this.incompleteChecklists = 0,
    this.securityWarnings = 0,
  });

  final int expiringDocuments;
  final int missingFiles;
  final int incompleteChecklists;
  final int securityWarnings;

  int get totalIssues =>
      expiringDocuments +
      missingFiles +
      incompleteChecklists +
      securityWarnings;
}
