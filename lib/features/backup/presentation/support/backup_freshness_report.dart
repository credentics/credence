import 'dart:convert';
import 'dart:math' as math;

import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/data/bundles/datasources/local/bundles_local_data_source.dart';
import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/datasources/local/document_local_data_source.dart';
import 'package:pass_doc_manager/data/notes/datasources/local/secure_notes_local_data_source.dart';
import 'package:pass_doc_manager/data/profile/datasources/local/profile_local_data_source.dart';
import 'package:pass_doc_manager/data/tasks/datasources/local/tasks_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_journal_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace_builder.dart';
import 'package:pass_doc_manager/data/vault_sync/services/vault_sync_operation_builder.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_operation_entity.dart';

class BackupFreshnessReport {
  const BackupFreshnessReport({
    required this.percentage,
    required this.totalCount,
    required this.pendingCount,
    required this.topPendingItems,
    required this.currentContentChecksum,
    required this.currentContentBackedUp,
    required this.currentVaultChecked,
    this.allPendingItems = const <BackupFreshnessItem>[],
    this.remoteHasNewerCopy = false,
  });

  final int percentage;
  final int totalCount;
  final int pendingCount;
  final List<BackupFreshnessItem> topPendingItems;
  final List<BackupFreshnessItem> allPendingItems;
  final String? currentContentChecksum;
  final bool currentContentBackedUp;
  final bool currentVaultChecked;
  final bool remoteHasNewerCopy;
}

class BackupFreshnessItem {
  const BackupFreshnessItem({
    required this.title,
    required this.typeLabel,
    required this.modifiedAt,
    this.detail = '',
  });

  final String title;
  final String typeLabel;
  final DateTime? modifiedAt;
  final String detail;
}

bool backupFreshnessIsMetadataOnly(BackupFreshnessReport? report) {
  if (report == null || report.currentContentBackedUp) return false;
  final items = report.topPendingItems;
  return report.pendingCount == 1 &&
      items.length == 1 &&
      items.first.typeLabel == 'Vault';
}

bool backupFreshnessHasRemoteChanges(BackupFreshnessReport? report) {
  return report?.remoteHasNewerCopy ?? false;
}

List<BackupFreshnessItem> backupFreshnessAllPendingItems(
  BackupFreshnessReport? report,
) {
  if (report == null) return const <BackupFreshnessItem>[];
  return report.allPendingItems.isNotEmpty
      ? report.allPendingItems
      : report.topPendingItems;
}

bool backupFreshnessHasDeletes(BackupFreshnessReport? report) {
  return backupFreshnessAllPendingItems(
    report,
  ).any((item) => item.typeLabel == 'Delete');
}

int backupFreshnessDeleteCount(BackupFreshnessReport? report) {
  return backupFreshnessAllPendingItems(
    report,
  ).where((item) => item.typeLabel == 'Delete').length;
}

Future<BackupFreshnessReport> buildBackupFreshnessReport(
  VaultSyncPrefsDto prefs,
) async {
  final workspace = await _buildCurrentWorkspace(prefs);
  final checksum = workspace.contentChecksum.trim().isEmpty
      ? null
      : workspace.contentChecksum.trim();
  final currentChecksum = checksum?.trim() ?? '';
  final lastRemoteChecksum = prefs.lastRemoteChecksum.trim();
  final lastAcceptedLocalChecksum = prefs.lastUploadedChecksum.trim();
  final remoteHasNewerCopy =
      prefs.lastRemoteRevision > prefs.lastObservedRemoteRevision &&
      lastRemoteChecksum.isNotEmpty &&
      lastRemoteChecksum != lastAcceptedLocalChecksum;
  final items = await _readFreshnessItems();
  final totalCount = items.length;
  final remotePendingItem = _remotePendingItem(prefs);
  final lastUploadedAt = DateTime.tryParse(prefs.lastSyncedAtIso ?? '');
  final syncPreview = await _readSyncChangePreview(
    prefs: prefs,
    workspace: workspace,
  );
  final hasTrustedUploadCheckpoint =
      lastUploadedAt != null &&
      (lastRemoteChecksum.isNotEmpty || lastAcceptedLocalChecksum.isNotEmpty);
  final currentBackedUp =
      currentChecksum.isNotEmpty &&
      !remoteHasNewerCopy &&
      (currentChecksum == lastRemoteChecksum ||
          currentChecksum == lastAcceptedLocalChecksum ||
          (hasTrustedUploadCheckpoint && syncPreview?.count == 0));

  if (currentBackedUp) {
    return BackupFreshnessReport(
      percentage: 100,
      totalCount: totalCount,
      pendingCount: 0,
      topPendingItems: const [],
      allPendingItems: const [],
      currentContentChecksum: checksum,
      currentContentBackedUp: true,
      currentVaultChecked: true,
      remoteHasNewerCopy: false,
    );
  }

  if (remoteHasNewerCopy &&
      currentChecksum.isNotEmpty &&
      currentChecksum == lastAcceptedLocalChecksum &&
      syncPreview == null) {
    return BackupFreshnessReport(
      percentage: _coveragePercentage(
        totalCount: totalCount,
        pendingCount: 1,
        hasUploadCheckpoint:
            lastUploadedAt != null &&
            (lastRemoteChecksum.isNotEmpty ||
                lastAcceptedLocalChecksum.isNotEmpty),
      ),
      totalCount: totalCount,
      pendingCount: 1,
      topPendingItems: [remotePendingItem],
      allPendingItems: [remotePendingItem],
      currentContentChecksum: checksum,
      currentContentBackedUp: false,
      currentVaultChecked: true,
      remoteHasNewerCopy: true,
    );
  }
  if (syncPreview != null && syncPreview.count > 0) {
    final pendingItems = remoteHasNewerCopy
        ? [remotePendingItem, ...syncPreview.items]
        : syncPreview.items;
    final pendingCount = syncPreview.count + (remoteHasNewerCopy ? 1 : 0);
    return BackupFreshnessReport(
      percentage: _coveragePercentage(
        totalCount: totalCount,
        pendingCount: pendingCount,
        hasUploadCheckpoint:
            lastUploadedAt != null &&
            (lastRemoteChecksum.isNotEmpty ||
                lastAcceptedLocalChecksum.isNotEmpty),
      ),
      totalCount: totalCount,
      pendingCount: pendingCount,
      topPendingItems: pendingItems.take(5).toList(growable: false),
      allPendingItems: pendingItems,
      currentContentChecksum: checksum,
      currentContentBackedUp: false,
      currentVaultChecked: true,
      remoteHasNewerCopy: remoteHasNewerCopy,
    );
  }
  if (remoteHasNewerCopy) {
    return BackupFreshnessReport(
      percentage: _coveragePercentage(
        totalCount: totalCount,
        pendingCount: 1,
        hasUploadCheckpoint:
            lastUploadedAt != null &&
            (lastRemoteChecksum.isNotEmpty ||
                lastAcceptedLocalChecksum.isNotEmpty),
      ),
      totalCount: totalCount,
      pendingCount: 1,
      topPendingItems: [remotePendingItem],
      allPendingItems: [remotePendingItem],
      currentContentChecksum: checksum,
      currentContentBackedUp: false,
      currentVaultChecked: true,
      remoteHasNewerCopy: true,
    );
  }

  final pending = _pendingItems(items, lastUploadedAt);
  final hasUnknownLocalChange = pending.isEmpty && totalCount > 0;
  final pendingCount = hasUnknownLocalChange ? 1 : pending.length;
  final fallbackPending = hasUnknownLocalChange
      ? [remoteHasNewerCopy ? remotePendingItem : _metadataPendingItem]
      : pending.take(5).toList(growable: false);
  final allPending = hasUnknownLocalChange ? fallbackPending : pending;
  final percentage = _coveragePercentage(
    totalCount: totalCount,
    pendingCount: pendingCount,
    hasUploadCheckpoint:
        lastUploadedAt != null &&
        (lastRemoteChecksum.isNotEmpty || lastAcceptedLocalChecksum.isNotEmpty),
  );

  return BackupFreshnessReport(
    percentage: percentage,
    totalCount: totalCount,
    pendingCount: pendingCount,
    topPendingItems: fallbackPending,
    allPendingItems: allPending,
    currentContentChecksum: checksum,
    currentContentBackedUp: false,
    currentVaultChecked: true,
    remoteHasNewerCopy: remoteHasNewerCopy,
  );
}

const BackupFreshnessItem _metadataPendingItem = BackupFreshnessItem(
  title: 'Backup metadata update',
  typeLabel: 'Vault',
  modifiedAt: null,
);

BackupFreshnessItem _remotePendingItem(VaultSyncPrefsDto prefs) {
  final providerLabel = _providerLabelFromPrefs(prefs);
  return BackupFreshnessItem(
    title: '$providerLabel has newer changes',
    typeLabel: 'Remote',
    modifiedAt: DateTime.tryParse(prefs.lastRemoteCheckedAtIso ?? ''),
    detail: 'Synchronize this device to import the latest mirror.',
  );
}

String _providerLabelFromPrefs(VaultSyncPrefsDto prefs) {
  return switch (prefs.selectedCloudProvider.trim()) {
    'google_drive' => 'Google Drive',
    'icloud' => 'iCloud',
    _ => 'Dropbox',
  };
}

Future<VaultMirrorWorkspace> _buildCurrentWorkspace(VaultSyncPrefsDto prefs) {
  final deviceId = prefs.deviceId.trim().isEmpty
      ? 'device_${DateTime.now().microsecondsSinceEpoch}'
      : prefs.deviceId.trim();
  final revision = math.max(1, prefs.lastObservedRemoteRevision + 1);
  return getIt<VaultMirrorWorkspaceBuilder>().build(
    deviceId: deviceId,
    revision: revision,
  );
}

Future<_SyncChangePreview?> _readSyncChangePreview({
  required VaultSyncPrefsDto prefs,
  required VaultMirrorWorkspace workspace,
}) async {
  final journal = getIt<VaultSyncJournalLocalDataSource>();
  final previousIndex = await journal.readContentIndex();
  if (previousIndex.isEmpty) {
    return null;
  }

  final plan = getIt<VaultSyncOperationBuilder>().build(
    workspace: workspace,
    previousContentIndex: previousIndex,
    deviceId: prefs.deviceId.trim().isEmpty ? 'preview' : prefs.deviceId.trim(),
    latestSequence: await journal.readLatestSequence(),
  );
  if (plan.operations.isEmpty) {
    return const _SyncChangePreview(count: 0, items: []);
  }

  final previousByEntity = <String, VaultSyncOperationEntity>{};
  for (final operation in await journal.readOperations()) {
    if (operation.payload.isEmpty) continue;
    previousByEntity['${operation.entityType}:${operation.entityId}'] =
        operation;
  }
  final previousPayloadByEntity = _payloadIndexByEntity(
    await journal.readContentPayloadIndex(),
  );

  var descriptors = plan.operations
      .map((operation) {
        final previous =
            previousByEntity['${operation.entityType}:${operation.entityId}'];
        final previousPayload =
            previous?.payload ??
            previousPayloadByEntity['${operation.entityType}:${operation.entityId}'];
        return _describeOperation(
          operation,
          previous,
          previousPayload: previousPayload,
        );
      })
      .whereType<_SyncChangeDescriptor>()
      .toList(growable: false);
  if (descriptors.isEmpty) {
    return null;
  }

  final touchedCollectionNames = descriptors
      .where(
        (descriptor) =>
            descriptor.collectionName != null && !descriptor.isCollection,
      )
      .map((descriptor) => descriptor.collectionName!)
      .toSet();
  descriptors = descriptors
      .where(
        (descriptor) =>
            !(descriptor.isCollection &&
                descriptor.action == 'Update' &&
                touchedCollectionNames.contains(descriptor.collectionName)),
      )
      .toList(growable: false);
  final deletedCollectionNames = descriptors
      .where(
        (descriptor) =>
            !descriptor.isFile &&
            descriptor.action == 'Delete' &&
            descriptor.collectionName != null,
      )
      .map((descriptor) => descriptor.collectionName!)
      .toSet();
  descriptors = descriptors
      .where(
        (descriptor) =>
            !(descriptor.isFile &&
                descriptor.action == 'Delete' &&
                deletedCollectionNames.contains(descriptor.collectionName)),
      )
      .toList(growable: false);

  final byKey = <String, _SyncChangeDescriptor>{};
  for (final descriptor in descriptors) {
    byKey.putIfAbsent(
      '${descriptor.action}:${descriptor.title}:${descriptor.typeLabel}',
      () => descriptor,
    );
  }
  final collapsed = byKey.values.toList(growable: false)
    ..sort((a, b) {
      final actionOrder = _actionPriority(
        a.action,
      ).compareTo(_actionPriority(b.action));
      if (actionOrder != 0) return actionOrder;
      return a.title.compareTo(b.title);
    });

  return _SyncChangePreview(
    count: collapsed.length,
    items: collapsed
        .map(
          (descriptor) => BackupFreshnessItem(
            title: descriptor.title,
            typeLabel: descriptor.action,
            modifiedAt: descriptor.modifiedAt,
            detail: descriptor.detail,
          ),
        )
        .toList(growable: false),
  );
}

_SyncChangeDescriptor? _describeOperation(
  VaultSyncOperationEntity operation,
  VaultSyncOperationEntity? previous, {
  Map<String, dynamic>? previousPayload,
}) {
  var action = _actionLabel(operation.operation);
  if (action == null) return null;

  final payload = operation.payload.isNotEmpty
      ? operation.payload
      : previous?.payload ?? const <String, dynamic>{};
  final path = _operationPath(operation, payload);
  final collectionName = _collectionNameFromPath(path);
  final isCollection = operation.entityType == 'collection';
  final isFile = operation.entityType == 'file';
  final entityName = _entityNoun(operation.entityType, path);
  final displayName = _firstNonEmpty([
    '${payload['display_name'] ?? ''}',
    '${payload['title'] ?? ''}',
    _displayNameFromPath(path),
    entityName,
  ]);
  final modifiedAt = DateTime.tryParse(operation.createdAtIso)?.toLocal();
  final previousFile = _previousFileState(operation, previous, previousPayload);
  if (isFile &&
      action == 'Update' &&
      previousFile.path.isNotEmpty &&
      previousFile.path != path &&
      previousFile.sha256 == '${payload['sha256'] ?? ''}'.trim()) {
    action = 'Rename';
  }

  final title = switch (action) {
    'Rename' => 'Renamed ${entityName.toLowerCase()} to $displayName',
    'Delete' when collectionName != null && !isCollection =>
      'Removed ${entityName.toLowerCase()} from $collectionName',
    'Delete' => 'Removed $displayName',
    'Add' when collectionName != null && !isCollection =>
      'Added ${entityName.toLowerCase()} to $collectionName',
    'Add' => 'Added $displayName',
    'Update' when collectionName != null && !isCollection =>
      'Updated ${entityName.toLowerCase()} in $collectionName',
    'Update' => 'Updated $displayName',
    _ => displayName,
  };
  final detail = _operationDetail(
    operation: operation,
    previousPayload: previousPayload,
    payload: payload,
    action: action,
    entityName: entityName,
    path: path,
    previousFile: previousFile,
  );

  return _SyncChangeDescriptor(
    title: title,
    detail: detail,
    action: action,
    typeLabel: entityName,
    collectionName: collectionName,
    isCollection: isCollection,
    isFile: isFile,
    modifiedAt: modifiedAt,
  );
}

String _operationDetail({
  required VaultSyncOperationEntity operation,
  required Map<String, dynamic>? previousPayload,
  required Map<String, dynamic> payload,
  required String action,
  required String entityName,
  required String path,
  required _FileState previousFile,
}) {
  if (action == 'Add') {
    return '$entityName will be added to the cloud mirror.';
  }
  if (action == 'Delete') {
    return '$entityName will be removed from the cloud mirror if deletions are confirmed.';
  }
  if (operation.entityType == 'file') {
    return _fileOperationDetail(
      action: action,
      path: path,
      payload: payload,
      previousFile: previousFile,
    );
  }

  final changedLabels = _changedPayloadLabels(
    previousPayload,
    operation.payload,
  );
  if (changedLabels.visible.isNotEmpty) {
    return '$entityName changed: ${_formatChangedLabels(changedLabels.visible)}.';
  }
  if (changedLabels.timestampOnly) {
    return 'Only the modified timestamp changed.';
  }

  final previousHashes = _nodeHashes(operation.baseHash);
  final nextHashes = _nodeHashes(operation.contentHash);
  if (previousHashes.metadataHash.isNotEmpty &&
      nextHashes.metadataHash.isNotEmpty &&
      previousHashes.metadataHash != nextHashes.metadataHash) {
    return '$entityName details changed.';
  }
  if (previousHashes.contentHash.isNotEmpty &&
      nextHashes.contentHash.isNotEmpty &&
      previousHashes.contentHash != nextHashes.contentHash) {
    return '$entityName name, folder, or order changed.';
  }
  return '$entityName record changed.';
}

String _fileOperationDetail({
  required String action,
  required String path,
  required Map<String, dynamic> payload,
  required _FileState previousFile,
}) {
  final nextSha = '${payload['sha256'] ?? ''}'.trim();
  final nextSize = _asInt(payload['size_bytes']);
  final sizeLabel = nextSize > 0 ? ' (${_formatBytes(nextSize)})' : '';
  if (action == 'Rename') {
    final previousPath = previousFile.path;
    if (previousPath.isNotEmpty) {
      return 'Path changed from ${_displayNameFromPath(previousPath)} to ${_displayNameFromPath(path)}.';
    }
    return 'File name or folder changed.';
  }
  if (previousFile.sha256.isNotEmpty &&
      nextSha.isNotEmpty &&
      previousFile.sha256 != nextSha) {
    return 'File contents changed$sizeLabel.';
  }
  if (path.isNotEmpty) {
    return 'File metadata changed at $path.';
  }
  return 'File metadata changed.';
}

_ChangedLabels _changedPayloadLabels(
  Map<String, dynamic>? previousPayload,
  Map<String, dynamic> nextPayload,
) {
  if (previousPayload == null || previousPayload.isEmpty) {
    return const _ChangedLabels(visible: [], timestampOnly: false);
  }
  final previous = _flattenComparablePayload(previousPayload);
  final next = _flattenComparablePayload(nextPayload);
  final allKeys = {...previous.keys, ...next.keys};
  final visible = <String>{};
  var timestampChanged = false;
  for (final key in allKeys) {
    if (_stableJson(previous[key]) == _stableJson(next[key])) {
      continue;
    }
    if (_isTimestampField(key)) {
      timestampChanged = true;
      continue;
    }
    visible.add(_fieldLabel(key));
  }
  return _ChangedLabels(
    visible: visible.toList(growable: false)..sort(),
    timestampOnly: visible.isEmpty && timestampChanged,
  );
}

Map<String, Object?> _flattenComparablePayload(Map<String, dynamic> payload) {
  final result = <String, Object?>{};
  final metadataRaw = payload['metadata'];
  for (final key in const ['display_name', 'path', 'parent_id', 'order']) {
    if (payload.containsKey(key)) {
      result[key] = payload[key];
    }
  }
  if (metadataRaw is Map) {
    final metadata = Map<String, dynamic>.from(metadataRaw);
    for (final entry in metadata.entries) {
      result['metadata.${entry.key}'] = entry.value;
    }
    return result;
  }
  for (final entry in payload.entries) {
    result[entry.key] = entry.value;
  }
  return result;
}

String _formatChangedLabels(List<String> labels) {
  if (labels.isEmpty) return 'details';
  final visible = labels.take(3).toList(growable: false);
  final suffix = labels.length > visible.length
      ? ' + ${labels.length - visible.length} more'
      : '';
  return '${visible.join(', ')}$suffix';
}

String _fieldLabel(String rawKey) {
  final key = rawKey.startsWith('metadata.')
      ? rawKey.substring('metadata.'.length)
      : rawKey;
  final normalized = key.trim();
  if (_isSecretField(normalized)) return 'Secret value';
  return switch (normalized) {
    'display_name' => 'Name',
    'path' => 'Path',
    'parent_id' || 'parentBlockId' => 'Parent',
    'order' || 'position' => 'Order',
    'serviceName' => 'Service',
    'accountLabel' => 'Label',
    'username' || 'email' => 'Username',
    'url' || 'website' => 'URL',
    'notes' || 'note' => 'Notes',
    'categoryKey' || 'category' => 'Category',
    'collectionIds' || 'collectionId' => 'Collection',
    'title' || 'name' => 'Name',
    'iconEmoji' => 'Icon',
    'iconImagePath' => 'Icon image',
    'coverImageUrl' => 'Cover image',
    'color' || 'accentColor' => 'Color',
    'blocks' => 'Collection items',
    'fields' || 'structuredFields' => 'Fields',
    'fileName' || 'filePath' || 'imageUrl' => 'File',
    'mimeType' || 'fileType' => 'File type',
    'status' => 'Status',
    'dueDateIso' || 'expiryDateIso' => 'Date',
    'items' || 'tasks' => 'Items',
    'firstName' => 'First name',
    'lastName' => 'Last name',
    'phone' => 'Phone',
    'address' => 'Address',
    'photoPath' => 'Photo',
    'socialLinks' => 'Social links',
    _ => _prettyPathSegment(normalized.replaceAll(RegExp(r'[_-]+'), ' ')),
  };
}

bool _isSecretField(String key) {
  final lower = key.toLowerCase();
  return lower.contains('password') ||
      lower.contains('secret') ||
      lower.contains('token') ||
      lower.contains('pin') ||
      lower.contains('recovery') ||
      lower.contains('credential');
}

bool _isTimestampField(String key) {
  final lower = key.toLowerCase();
  return lower.contains('updatedat') ||
      lower.contains('createdat') ||
      lower.contains('modifiedat') ||
      lower.contains('lastused') ||
      lower.contains('upload') ||
      lower.contains('securityupdate');
}

String _stableJson(Object? value) {
  return jsonEncode(_stableComparableValue(value));
}

Object? _stableComparableValue(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort((a, b) => '${a.key}'.compareTo('${b.key}'));
    return {
      for (final entry in entries)
        '${entry.key}': _stableComparableValue(entry.value),
    };
  }
  if (value is Iterable) {
    return value.map(_stableComparableValue).toList(growable: false);
  }
  return value;
}

_NodeHashes _nodeHashes(String value) {
  final separator = value.lastIndexOf(':');
  if (separator < 0) {
    return _NodeHashes(contentHash: value.trim(), metadataHash: '');
  }
  return _NodeHashes(
    contentHash: value.substring(0, separator).trim(),
    metadataHash: value.substring(separator + 1).trim(),
  );
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String? _actionLabel(String operation) {
  return switch (operation.trim().toLowerCase()) {
    'create' => 'Add',
    'update' => 'Update',
    'delete' => 'Delete',
    _ => null,
  };
}

int _actionPriority(String action) {
  return switch (action) {
    'Delete' => 0,
    'Rename' => 1,
    'Add' => 1,
    'Update' => 2,
    _ => 3,
  };
}

_FileState _previousFileState(
  VaultSyncOperationEntity operation,
  VaultSyncOperationEntity? previous,
  Map<String, dynamic>? previousPayload,
) {
  final fromBase = _parseFileState(operation.baseHash);
  if (fromBase.path.isNotEmpty || fromBase.sha256.isNotEmpty) {
    return fromBase;
  }
  final payload =
      previous?.payload ?? previousPayload ?? const <String, dynamic>{};
  return _FileState(
    path: '${payload['path'] ?? ''}'.trim(),
    sha256: '${payload['sha256'] ?? ''}'.trim(),
  );
}

_FileState _parseFileState(String value) {
  if (!value.startsWith('v2|')) {
    return _FileState(path: '', sha256: value.trim());
  }
  final parts = value.substring(3).split('|');
  var path = '';
  var sha256 = '';
  for (final part in parts) {
    final separator = part.indexOf('=');
    if (separator <= 0) continue;
    final key = part.substring(0, separator);
    final rawValue = part.substring(separator + 1);
    if (key == 'path') {
      path = Uri.decodeComponent(rawValue);
    } else if (key == 'sha256') {
      sha256 = rawValue;
    }
  }
  return _FileState(path: path, sha256: sha256);
}

String _operationPath(
  VaultSyncOperationEntity operation,
  Map<String, dynamic> payload,
) {
  final payloadPath = '${payload['path'] ?? ''}'.trim();
  if (payloadPath.isNotEmpty) {
    return payloadPath;
  }
  if (operation.entityType == 'file') {
    return operation.entityId.trim();
  }
  return '';
}

Map<String, Map<String, dynamic>> _payloadIndexByEntity(
  Map<String, Map<String, dynamic>> payloadIndex,
) {
  final result = <String, Map<String, dynamic>>{};
  for (final entry in payloadIndex.entries) {
    final parsed = _parsePayloadIndexKey(entry.key);
    if (parsed == null) continue;
    result['${parsed.entityType}:${parsed.entityId}'] = entry.value;
  }
  return result;
}

_ParsedPayloadIndexKey? _parsePayloadIndexKey(String key) {
  final parts = key.split(':');
  if (parts.length < 3) {
    if (parts.length == 2 && parts.first == 'file') {
      return _ParsedPayloadIndexKey(entityType: 'file', entityId: parts.last);
    }
    return null;
  }
  if (parts.first == 'node') {
    return _ParsedPayloadIndexKey(
      entityType: parts[1],
      entityId: parts.sublist(2).join(':'),
    );
  }
  if (parts.first == 'file') {
    return _ParsedPayloadIndexKey(
      entityType: 'file',
      entityId: parts.sublist(1).join(':'),
    );
  }
  return null;
}

String? _collectionNameFromPath(String path) {
  final parts = path
      .replaceAll('\\', '/')
      .split('/')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length < 2 || parts.first != 'Collections') {
    return null;
  }
  return _prettyPathSegment(parts[1]);
}

String _displayNameFromPath(String path) {
  final parts = path
      .replaceAll('\\', '/')
      .split('/')
      .where((part) => part.trim().isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return '';
  final last = parts.last.split('.').first;
  return _prettyPathSegment(last);
}

String _entityNoun(String entityType, String path) {
  final cleanType = entityType.trim().toLowerCase();
  if (cleanType == 'file') {
    return _fileNoun(path);
  }
  return switch (cleanType) {
    'credential' => 'Password',
    'task_list' => 'Task list',
    'secure_note' => 'Note',
    'collection' => 'Collection',
    'bundle' => 'Bundle',
    'profile' => 'Profile',
    'document' => 'Document',
    'image' => 'Image',
    'link' => 'Link',
    'note' => 'Note',
    'input' => 'Input',
    'checklist' => 'Checklist',
    _ => _prettyPathSegment(cleanType.replaceAll('_', ' ')),
  };
}

String _fileNoun(String path) {
  final normalized = path.replaceAll('\\', '/');
  if (normalized.startsWith('Collections/')) return 'File';
  if (normalized.startsWith('Documents/')) return 'Document';
  if (normalized.startsWith('Credentials/')) return 'Password file';
  if (normalized.startsWith('Secure Notes/')) return 'Note file';
  if (normalized.startsWith('${VaultMirrorWorkspace.metadataDir}/assets/')) {
    return 'Asset';
  }
  return 'File';
}

String _prettyPathSegment(String value) {
  final words = value
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return value.trim();
  return words
      .map(
        (word) => word.length <= 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class _SyncChangePreview {
  const _SyncChangePreview({required this.count, required this.items});

  final int count;
  final List<BackupFreshnessItem> items;
}

class _SyncChangeDescriptor {
  const _SyncChangeDescriptor({
    required this.title,
    required this.detail,
    required this.action,
    required this.typeLabel,
    required this.isCollection,
    required this.isFile,
    required this.modifiedAt,
    this.collectionName,
  });

  final String title;
  final String detail;
  final String action;
  final String typeLabel;
  final String? collectionName;
  final bool isCollection;
  final bool isFile;
  final DateTime? modifiedAt;
}

class _FileState {
  const _FileState({required this.path, required this.sha256});

  final String path;
  final String sha256;
}

class _ChangedLabels {
  const _ChangedLabels({required this.visible, required this.timestampOnly});

  final List<String> visible;
  final bool timestampOnly;
}

class _NodeHashes {
  const _NodeHashes({required this.contentHash, required this.metadataHash});

  final String contentHash;
  final String metadataHash;
}

class _ParsedPayloadIndexKey {
  const _ParsedPayloadIndexKey({
    required this.entityType,
    required this.entityId,
  });

  final String entityType;
  final String entityId;
}

Future<List<BackupFreshnessItem>> _readFreshnessItems() async {
  final items = <BackupFreshnessItem>[];

  final credentials = await getIt<CredentialLocalDataSource>()
      .readCredentialRows();
  for (final row in credentials) {
    final title = _firstNonEmpty([
      '${row['serviceName'] ?? ''}',
      '${row['displayName'] ?? ''}',
      'Credential',
    ]);
    items.add(
      BackupFreshnessItem(
        title: title,
        typeLabel: 'Password',
        modifiedAt: _latestDate([
          row['updatedAtIso'],
          row['createdAtIso'],
          row['lastUsedAtIso'],
          row['lastSecurityUpdate'],
        ]),
      ),
    );
  }

  final documents = await getIt<DocumentLocalDataSource>().getDocuments();
  for (final document in documents) {
    items.add(
      BackupFreshnessItem(
        title: document.title.trim().isEmpty ? 'Document' : document.title,
        typeLabel: 'Document',
        modifiedAt: _latestDate([
          document.updatedAtIso,
          document.uploadDateIso,
        ]),
      ),
    );
  }

  final notes = await getIt<SecureNotesLocalDataSource>().getNotes();
  for (final note in notes) {
    items.add(
      BackupFreshnessItem(
        title: note.title.trim().isEmpty ? 'Secure note' : note.title,
        typeLabel: 'Note',
        modifiedAt: _latestDate([note.updatedAtIso, note.createdAtIso]),
      ),
    );
  }

  final taskLists = await getIt<TasksLocalDataSource>().getTaskLists();
  for (final list in taskLists) {
    items.add(
      BackupFreshnessItem(
        title: list.title.trim().isEmpty ? 'Task list' : list.title,
        typeLabel: 'Tasks',
        modifiedAt: _latestDate([list.updatedAtIso, list.createdAtIso]),
      ),
    );
  }

  final collections = await getIt<CollectionsLocalDataSource>()
      .getCollections();
  for (final collection in collections) {
    items.add(
      BackupFreshnessItem(
        title: collection.name.trim().isEmpty ? 'Collection' : collection.name,
        typeLabel: 'Collection',
        modifiedAt: _latestDate([collection.updatedAtIso]),
      ),
    );
  }

  final bundles = await getIt<BundlesLocalDataSource>().getBundles();
  for (final bundle in bundles) {
    items.add(
      BackupFreshnessItem(
        title: bundle.title.trim().isEmpty ? 'Bundle' : bundle.title,
        typeLabel: 'Bundle',
        modifiedAt: _latestDate([bundle.updatedAtIso, bundle.createdAtIso]),
      ),
    );
  }

  final profile = await getIt<ProfileLocalDataSource>().readProfile();
  if (_profileHasContent(profile.toMap())) {
    items.add(
      BackupFreshnessItem(
        title: 'Profile',
        typeLabel: 'Settings',
        modifiedAt: _latestDate([profile.updatedAtIso]),
      ),
    );
  }

  return items;
}

List<BackupFreshnessItem> _pendingItems(
  List<BackupFreshnessItem> items,
  DateTime? lastUploadedAt,
) {
  if (lastUploadedAt == null) {
    return _newestItems(items);
  }
  final pending = items
      .where((item) {
        final modifiedAt = item.modifiedAt;
        return modifiedAt != null && modifiedAt.isAfter(lastUploadedAt);
      })
      .toList(growable: false);
  return _newestItems(pending);
}

List<BackupFreshnessItem> _newestItems(List<BackupFreshnessItem> items) {
  return items.toList(growable: false)..sort((a, b) {
    final aMillis = a.modifiedAt?.millisecondsSinceEpoch ?? 0;
    final bMillis = b.modifiedAt?.millisecondsSinceEpoch ?? 0;
    final byDate = bMillis.compareTo(aMillis);
    if (byDate != 0) return byDate;
    return a.title.compareTo(b.title);
  });
}

int _coveragePercentage({
  required int totalCount,
  required int pendingCount,
  required bool hasUploadCheckpoint,
}) {
  if (totalCount <= 0) return hasUploadCheckpoint ? 100 : 0;
  if (!hasUploadCheckpoint) return 0;
  final backedUp = math.max(0, totalCount - pendingCount);
  return math.min(99, ((backedUp / totalCount) * 100).round());
}

DateTime? _latestDate(Iterable<Object?> values) {
  DateTime? latest;
  for (final value in values) {
    final parsed = _parseDate(value);
    if (parsed == null) continue;
    final local = parsed.toLocal();
    if (latest == null || local.isAfter(latest)) {
      latest = local;
    }
  }
  return latest;
}

DateTime? _parseDate(Object? value) {
  final text = '${value ?? ''}'.trim();
  if (text.isEmpty) return null;
  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;
  final parts = RegExp(
    r'^([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})$',
  ).firstMatch(text);
  if (parts == null) return null;
  final month = _monthNumber(parts.group(1)!);
  final day = int.tryParse(parts.group(2)!);
  final year = int.tryParse(parts.group(3)!);
  if (month == null || day == null || year == null) return null;
  return DateTime(year, month, day);
}

int? _monthNumber(String value) {
  const months = {
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
  };
  return months[value.toLowerCase()];
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return values.isEmpty ? 'Item' : values.last;
}

bool _profileHasContent(Map<String, dynamic> profile) {
  return profile.entries.any((entry) {
    if (entry.key == 'updatedAtIso') return false;
    return '${entry.value ?? ''}'.trim().isNotEmpty;
  });
}
