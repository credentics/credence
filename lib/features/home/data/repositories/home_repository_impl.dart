import 'package:pass_doc_manager/core/utils/document_display_resolver.dart';
import 'package:pass_doc_manager/core/constants/internal_collection_ids.dart';
import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/datasources/local/document_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/dtos/document_record_dto.dart';
import 'package:pass_doc_manager/data/profile/datasources/local/profile_local_data_source.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';
import 'package:pass_doc_manager/features/home/data/datasources/home_preferences_data_source.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_preferences_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/pinned_item_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/quick_access_item_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/recent_item_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/smart_reminder_entity.dart';
import 'package:pass_doc_manager/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({
    required this.profileDataSource,
    required this.credentialDataSource,
    required this.documentDataSource,
    required this.collectionsDataSource,
    required this.preferencesDataSource,
    required this.taskRepository,
  });

  final ProfileLocalDataSource profileDataSource;
  final CredentialLocalDataSource credentialDataSource;
  final DocumentLocalDataSource documentDataSource;
  final CollectionsLocalDataSource collectionsDataSource;
  final HomePreferencesDataSource preferencesDataSource;
  final TaskRepository taskRepository;

  @override
  Future<HomeDashboardEntity> getDashboard() async {
    final prefs = await preferencesDataSource.getPreferences();
    final dismissedIds = await preferencesDataSource.getDismissedReminderIds();

    final results = await Future.wait([
      profileDataSource.readProfile(),
      credentialDataSource.getCredentialSummaries(),
      documentDataSource.getDocuments(),
      collectionsDataSource.getCollections(),
      taskRepository.getTaskLists().catchError(
        (Object _) => const <TaskListEntity>[],
      ),
    ]);

    final profile = results[0] as dynamic;
    final credentials = results[1] as List;
    final documents = results[2] as List;
    final collections = (results[3] as List)
        .where((collection) => collection.id != internalSecureNotesCollectionId)
        .toList(growable: false);
    final taskLists = (results[4] as List<TaskListEntity>)
        .where((list) => !list.isArchived)
        .toList(growable: false);
    final activeDocuments = documents
        .where((doc) => !((doc as dynamic).isArchived as bool))
        .toList(growable: false);

    return HomeDashboardEntity(
      firstName: (profile.firstName as String?) ?? '',
      photoPath: _nonEmpty(profile.photoPath as String?),
      smartReminders: _buildReminders(
        documents: documents,
        collections: collections,
        dismissedIds: dismissedIds,
        prefs: prefs,
      ),
      frequentlyUsed: _buildFrequentlyUsed(
        credentials: credentials,
        documents: documents,
      ),
      quickAccessGroups: _buildQuickAccessGroups(
        credentials: credentials,
        documents: documents,
        collections: collections,
        taskLists: taskLists,
        prefs: prefs,
      ),
      recentItems: _buildRecentItems(
        credentials: credentials,
        documents: documents,
        collections: collections,
        prefs: prefs,
      ),
      pinnedItems: _buildPinnedItems(
        credentials: credentials,
        documents: documents,
        prefs: prefs,
      ),
      insights: _buildInsights(
        documents: documents,
        credentials: credentials,
        collections: collections,
      ),
      credentialCount: credentials.length,
      documentCount: activeDocuments.length,
      collectionCount: collections.length,
      taskListCount: taskLists.length,
      openTaskCount: taskLists.fold<int>(
        0,
        (total, list) => total + list.openCount,
      ),
      overdueTaskCount: taskLists.fold<int>(
        0,
        (total, list) => total + list.overdueCount,
      ),
    );
  }

  @override
  Future<HomePreferencesEntity> getPreferences() {
    return preferencesDataSource.getPreferences();
  }

  @override
  Future<void> savePreferences(HomePreferencesEntity preferences) {
    return preferencesDataSource.savePreferences(preferences);
  }

  @override
  Future<void> dismissReminder(String reminderId) {
    return preferencesDataSource.dismissReminder(reminderId);
  }

  // ── Smart Reminders ──

  List<SmartReminderEntity> _buildReminders({
    required List documents,
    required List collections,
    required Set<String> dismissedIds,
    required HomePreferencesEntity prefs,
  }) {
    // One reminder per source item — pick the highest priority.
    // Priority: expired > expiring > attention required.
    final docReminders = <String, SmartReminderEntity>{};
    final showExpiring = prefs.smartRules['showExpiring'] ?? true;
    final showMissing = prefs.smartRules['showMissing'] ?? true;
    final now = DateTime.now().toUtc();

    for (final doc in documents) {
      final docId = doc.id as String;
      final docTitle = doc.title as String;
      final docType = _formatDocumentType(doc.documentType as String);
      final categoryKey = doc.categoryKey as String;

      final expiryIso = doc.expiryAtIso as String;
      final expiry = expiryIso.isNotEmpty ? DateTime.tryParse(expiryIso) : null;
      final daysUntil = expiry?.difference(now).inDays;

      if (showExpiring && daysUntil != null && daysUntil < 0) {
        final daysAgo = -daysUntil;
        docReminders[docId] = SmartReminderEntity(
          id: 'doc_$docId',
          title: docType,
          subtitle:
              '$docTitle — expired $daysAgo day${daysAgo == 1 ? '' : 's'} ago',
          categoryKey: categoryKey,
          sourceType: ReminderSourceType.document,
          sourceId: docId,
          action: ReminderAction.renew,
          relevantAt: expiry,
        );
      } else if (showExpiring && daysUntil != null && daysUntil <= 30) {
        docReminders[docId] = SmartReminderEntity(
          id: 'doc_$docId',
          title: docType,
          subtitle:
              '$docTitle — expires in $daysUntil day${daysUntil == 1 ? '' : 's'}',
          categoryKey: categoryKey,
          sourceType: ReminderSourceType.document,
          sourceId: docId,
          action: ReminderAction.renew,
          relevantAt: expiry,
        );
      } else if (showMissing && (doc.requiresAttention as bool)) {
        docReminders[docId] = SmartReminderEntity(
          id: 'doc_$docId',
          title: docType,
          subtitle: '$docTitle — action required',
          categoryKey: categoryKey,
          sourceType: ReminderSourceType.document,
          sourceId: docId,
          action: ReminderAction.resolve,
        );
      }
    }

    final reminders = <SmartReminderEntity>[...docReminders.values];

    for (final collection in collections) {
      final blocks = collection.blocks as List;
      for (final block in blocks) {
        final typeKey = block.typeKey as String;

        // Reminder blocks with future event
        if (typeKey == 'reminder') {
          final eventIso = block.eventAtIso as String?;
          if (eventIso == null || eventIso.isEmpty) continue;
          final eventAt = DateTime.tryParse(eventIso);
          if (eventAt == null || !eventAt.isAfter(now)) continue;
          final daysUntil = eventAt.difference(now).inDays;
          reminders.add(
            SmartReminderEntity(
              id: 'col_r_${block.id}',
              title: block.title as String,
              subtitle:
                  '${collection.name} — in $daysUntil day${daysUntil == 1 ? '' : 's'}',
              categoryKey: 'collection',
              sourceType: ReminderSourceType.collection,
              sourceId: collection.id as String,
              action: ReminderAction.viewDetails,
              relevantAt: eventAt,
            ),
          );
        }

        // Timeline events upcoming within 7 days
        if (typeKey == 'timeline') {
          final eventIso = block.eventAtIso as String?;
          if (eventIso == null || eventIso.isEmpty) continue;
          final eventAt = DateTime.tryParse(eventIso);
          if (eventAt == null) continue;
          final daysUntil = eventAt.difference(now).inDays;
          if (daysUntil < 0 || daysUntil > 7) continue;
          reminders.add(
            SmartReminderEntity(
              id: 'col_t_${block.id}',
              title: block.title as String,
              subtitle: daysUntil == 0
                  ? '${collection.name} — today'
                  : '${collection.name} — in $daysUntil day${daysUntil == 1 ? '' : 's'}',
              categoryKey: 'collection',
              sourceType: ReminderSourceType.collection,
              sourceId: collection.id as String,
              action: ReminderAction.viewDetails,
              relevantAt: eventAt,
            ),
          );
        }
      }
    }

    final visible = reminders
        .where((r) => !dismissedIds.contains(r.id))
        .toList(growable: false);
    visible.sort((a, b) => _compareSmartReminders(a, b, now));
    return visible;
  }

  int _compareSmartReminders(
    SmartReminderEntity a,
    SmartReminderEntity b,
    DateTime now,
  ) {
    final bucketA = _reminderBucket(a, now);
    final bucketB = _reminderBucket(b, now);
    if (bucketA != bucketB) {
      return bucketA.compareTo(bucketB);
    }

    final aAt = a.relevantAt;
    final bAt = b.relevantAt;
    if (aAt != null && bAt != null) {
      if (bucketA == 0) {
        final comparePast = bAt.compareTo(aAt);
        if (comparePast != 0) {
          return comparePast;
        }
      } else {
        final compareFuture = aAt.compareTo(bAt);
        if (compareFuture != 0) {
          return compareFuture;
        }
      }
    }

    final actionCompare = a.action.index.compareTo(b.action.index);
    if (actionCompare != 0) {
      return actionCompare;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  int _reminderBucket(SmartReminderEntity reminder, DateTime now) {
    final relevantAt = reminder.relevantAt;
    if (relevantAt == null) {
      return 2;
    }
    if (relevantAt.isBefore(now)) {
      return 0;
    }
    return 1;
  }

  // ── Frequently Used ──

  List<RecentItemEntity> _buildFrequentlyUsed({
    required List credentials,
    required List documents,
  }) {
    final items = <RecentItemEntity>[];

    for (final cred in credentials) {
      final lastUsed = cred.lastUsedAtIso as String?;
      if (lastUsed == null || lastUsed.isEmpty) continue;
      final dt = DateTime.tryParse(lastUsed);
      if (dt == null) continue;
      items.add(
        RecentItemEntity(
          id: 'freq_cred_${cred.id}',
          title: cred.displayName as String,
          subtitle: cred.username as String,
          sourceType: RecentItemSourceType.credential,
          sourceId: cred.id as String,
          modifiedAt: dt,
          previewImagePath: cred.logoPath as String?,
        ),
      );
    }

    for (final doc in documents) {
      if (doc.isFavorite as bool) {
        final dt = DateTime.tryParse(doc.updatedAtIso as String);
        items.add(
          RecentItemEntity(
            id: 'freq_doc_${doc.id}',
            title: doc.title as String,
            subtitle: doc.categoryKey as String,
            sourceType: RecentItemSourceType.document,
            sourceId: doc.id as String,
            modifiedAt: dt ?? DateTime.now(),
          ),
        );
      }
    }

    items.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return items.take(8).toList(growable: false);
  }

  // ── Quick Access ──

  List<QuickAccessGroupEntity> _buildQuickAccessGroups({
    required List credentials,
    required List documents,
    required List collections,
    required List<TaskListEntity> taskLists,
    required HomePreferencesEntity prefs,
  }) {
    final groups = <QuickAccessGroupEntity>[];
    final categoryMap = <String, List<QuickAccessItemEntity>>{};

    for (final list in taskLists) {
      final parts = <String>[];
      if (list.openCount > 0) parts.add('${list.openCount} open');
      if (list.overdueCount > 0) parts.add('${list.overdueCount} overdue');
      if (list.doneCount > 0) parts.add('${list.doneCount} done');
      (categoryMap['tasks'] ??= []).add(
        QuickAccessItemEntity(
          id: 'qa_task_${list.id}',
          title: list.title,
          subtitle: parts.isEmpty ? 'Empty' : parts.join(' \u00b7 '),
          sourceType: 'task_list',
          sourceId: list.id,
          iconKey: 'task_list_${list.iconKey}',
        ),
      );
    }

    for (final doc in documents) {
      if (doc.isArchived as bool) continue;
      final dto = doc as DocumentRecordDto;
      final groupKey = _documentCategoryToGroupKey(dto.categoryKey);
      final spec = DocumentDisplayResolver.resolve(dto);
      (categoryMap[groupKey] ??= []).add(
        QuickAccessItemEntity(
          id: 'qa_doc_${dto.id}',
          title: spec.title.isEmpty ? dto.fileName : spec.title,
          subtitle: spec.subtitle,
          sourceType: 'document',
          sourceId: dto.id,
          iconKey: spec.iconKey,
          dateLabel: spec.dateLabel,
        ),
      );
    }

    for (final cred in credentials) {
      final category = cred.categoryKey as String;
      final groupKey = _credentialCategoryToGroupKey(category);
      (categoryMap[groupKey] ??= []).add(
        QuickAccessItemEntity(
          id: 'qa_cred_${cred.id}',
          title: cred.displayName as String,
          subtitle: cred.username as String,
          sourceType: 'credential',
          sourceId: cred.id as String,
          logoPath: cred.logoPath as String?,
          iconKey: 'credential',
        ),
      );
    }

    for (final collection in collections) {
      (categoryMap['collections'] ??= []).add(
        QuickAccessItemEntity(
          id: 'qa_col_${collection.id}',
          title: collection.name as String,
          subtitle: '${(collection.blocks as List).length} items',
          sourceType: 'collection',
          sourceId: collection.id as String,
          iconKey: 'collection',
        ),
      );
    }

    for (final key in prefs.quickAccessCategories) {
      if (!prefs.isCategoryVisible(key)) continue;
      final items = categoryMap[key];
      if (items == null || items.isEmpty) continue;

      // Aggregate leaf rows that share the same resolver aggregateKey. The
      // resolver only provides keys for document types where grouping is
      // meaningful (work by company+folder, travel by trip, property by
      // name) — everything else falls through unchanged.
      final aggregated = _aggregateDocumentItems(
        items,
        documents.cast<DocumentRecordDto>(),
      );
      groups.add(
        QuickAccessGroupEntity(
          categoryKey: key,
          categoryLabel: _groupLabel(key),
          items: aggregated.take(4).toList(growable: false),
        ),
      );
    }

    return groups;
  }

  List<QuickAccessItemEntity> _aggregateDocumentItems(
    List<QuickAccessItemEntity> items,
    List<DocumentRecordDto> allDocuments,
  ) {
    if (items.isEmpty) return items;

    // Index resolver specs by document id for the leaf items we care about.
    final specs = <String, DocumentDisplaySpec>{};
    for (final doc in allDocuments) {
      specs[doc.id] = DocumentDisplayResolver.resolve(doc);
    }

    final buckets = <String, List<QuickAccessItemEntity>>{};
    final bucketOrder = <String>[];
    final bucketSpecs = <String, DocumentDisplaySpec>{};
    final result = <QuickAccessItemEntity>[];

    for (final item in items) {
      if (item.sourceType != 'document') {
        result.add(item);
        continue;
      }
      final spec = specs[item.sourceId];
      final key = spec?.aggregateKey;
      if (key == null) {
        result.add(item);
        continue;
      }
      if (!buckets.containsKey(key)) {
        bucketOrder.add(key);
        bucketSpecs[key] = spec!;
      }
      (buckets[key] ??= []).add(item);
    }

    for (final key in bucketOrder) {
      final bucket = buckets[key]!;
      if (bucket.length < 2) {
        result.addAll(bucket);
        continue;
      }
      final spec = bucketSpecs[key]!;
      final label = spec.aggregateLabel?.trim();
      final hint = spec.aggregateHint?.trim();
      final parent = QuickAccessItemEntity(
        id: 'qa_agg_$key',
        title: (label == null || label.isEmpty) ? bucket.first.title : label,
        subtitle: (hint == null || hint.isEmpty)
            ? '${bucket.length} items'
            : '$hint \u2022 ${bucket.length}',
        sourceType: 'aggregate',
        sourceId: key,
        iconKey: spec.aggregateIconKey ?? spec.iconKey,
        children: bucket,
      );
      result.add(parent);
    }

    return result;
  }

  String _documentCategoryToGroupKey(String categoryKey) {
    switch (categoryKey) {
      case 'identity':
      case 'government':
        return 'ids';
      case 'finance':
      case 'banking':
      case 'insurance':
        return 'cards';
      case 'work':
      case 'employment':
        return 'work';
      default:
        return 'documents';
    }
  }

  String _credentialCategoryToGroupKey(String categoryKey) {
    switch (categoryKey) {
      case 'financial':
      case 'banking':
        return 'cards';
      case 'work':
      case 'professional':
        return 'work';
      default:
        return 'documents';
    }
  }

  String _groupLabel(String key) {
    switch (key) {
      case 'ids':
        return 'IDs';
      case 'work':
        return 'Work';
      case 'documents':
        return 'Documents';
      case 'cards':
        return 'Cards';
      case 'collections':
        return 'Collections';
      case 'tasks':
        return 'Tasks';
      default:
        return key;
    }
  }

  // ── Recent Items ──

  List<RecentItemEntity> _buildRecentItems({
    required List credentials,
    required List documents,
    required List collections,
    required HomePreferencesEntity prefs,
  }) {
    if (!(prefs.smartRules['showRecentlyUpdated'] ?? true)) {
      return const [];
    }

    final items = <RecentItemEntity>[];

    for (final cred in credentials) {
      final iso = (cred.lastUsedAtIso as String?) ?? '';
      final dt = DateTime.tryParse(iso);
      items.add(
        RecentItemEntity(
          id: 'recent_cred_${cred.id}',
          title: cred.displayName as String,
          subtitle: cred.username as String,
          sourceType: RecentItemSourceType.credential,
          sourceId: cred.id as String,
          modifiedAt: dt ?? DateTime.now(),
          previewImagePath: cred.logoPath as String?,
        ),
      );
    }

    for (final doc in documents) {
      if (doc.isArchived as bool) continue;
      final dt = DateTime.tryParse(doc.updatedAtIso as String);
      items.add(
        RecentItemEntity(
          id: 'recent_doc_${doc.id}',
          title: doc.title as String,
          subtitle: doc.categoryKey as String,
          sourceType: RecentItemSourceType.document,
          sourceId: doc.id as String,
          modifiedAt: dt ?? DateTime.now(),
        ),
      );
    }

    for (final collection in collections) {
      final dt = DateTime.tryParse(collection.updatedAtIso as String);
      items.add(
        RecentItemEntity(
          id: 'recent_col_${collection.id}',
          title: collection.name as String,
          subtitle: '${(collection.blocks as List).length} items',
          sourceType: RecentItemSourceType.collection,
          sourceId: collection.id as String,
          modifiedAt: dt ?? DateTime.now(),
        ),
      );
    }

    items.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return items.take(8).toList(growable: false);
  }

  // ── Pinned Items ──

  List<PinnedItemEntity> _buildPinnedItems({
    required List credentials,
    required List documents,
    required HomePreferencesEntity prefs,
  }) {
    if (prefs.pinnedItemIds.isEmpty) return const [];

    final pinned = <PinnedItemEntity>[];

    for (final pinnedId in prefs.pinnedItemIds) {
      for (final cred in credentials) {
        if ((cred.id as String) == pinnedId) {
          pinned.add(
            PinnedItemEntity(
              sourceType: 'credential',
              sourceId: cred.id as String,
              title: cred.displayName as String,
              subtitle: cred.username as String,
              logoPath: cred.logoPath as String?,
            ),
          );
        }
      }
      for (final doc in documents) {
        if ((doc.id as String) == pinnedId) {
          pinned.add(
            PinnedItemEntity(
              sourceType: 'document',
              sourceId: doc.id as String,
              title: doc.title as String,
              subtitle: doc.categoryKey as String,
            ),
          );
        }
      }
    }

    return pinned;
  }

  // ── Insights ──

  HomeInsights _buildInsights({
    required List documents,
    required List credentials,
    required List collections,
  }) {
    int expiringDocs = 0;
    int missingFiles = 0;
    int incompleteChecklists = 0;
    int securityWarnings = 0;

    for (final doc in documents) {
      final expiryIso = doc.expiryAtIso as String;
      if (expiryIso.isNotEmpty) {
        final expiry = DateTime.tryParse(expiryIso);
        if (expiry != null) {
          final daysUntil = expiry.difference(DateTime.now().toUtc()).inDays;
          if (daysUntil <= 30 && daysUntil >= 0) expiringDocs++;
        }
      }
      if (doc.requiresAttention as bool) missingFiles++;
    }

    for (final cred in credentials) {
      if (cred.hasWarning as bool) securityWarnings++;
    }

    for (final collection in collections) {
      for (final block in (collection.blocks as List)) {
        if ((block.typeKey as String) == 'checklist') {
          final items = block.checklistItems as List;
          final allDone = items.every((item) => item.isDone as bool);
          if (!allDone) incompleteChecklists++;
        }
      }
    }

    return HomeInsights(
      expiringDocuments: expiringDocs,
      missingFiles: missingFiles,
      incompleteChecklists: incompleteChecklists,
      securityWarnings: securityWarnings,
    );
  }

  String? _nonEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  String _formatDocumentType(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Document';
    return trimmed
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
