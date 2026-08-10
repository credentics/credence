import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_operation_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_tombstone_entity.dart';

class VaultSyncUploadPlan {
  const VaultSyncUploadPlan({
    required this.operations,
    required this.nextContentIndex,
    required this.nextPayloadIndex,
    required this.blobFiles,
    required this.latestSequence,
  });

  final List<VaultSyncOperationEntity> operations;
  final Map<String, String> nextContentIndex;
  final Map<String, Map<String, dynamic>> nextPayloadIndex;
  final List<VaultMirrorFile> blobFiles;
  final int latestSequence;
}

class VaultSyncOperationBuilder {
  const VaultSyncOperationBuilder({
    this.tombstoneRetention = const Duration(days: 90),
  });

  final Duration tombstoneRetention;

  VaultSyncUploadPlan build({
    required VaultMirrorWorkspace workspace,
    required Map<String, String> previousContentIndex,
    required String deviceId,
    required int latestSequence,
    bool includeDeletes = true,
    DateTime? now,
  }) {
    final createdAt = (now ?? DateTime.now()).toUtc();
    final createdAtIso = createdAt.toIso8601String();
    final retainUntilIso = createdAt.add(tombstoneRetention).toIso8601String();
    final nextIndex = <String, String>{};
    final nextPayloadIndex = <String, Map<String, dynamic>>{};
    final consumedPreviousKeys = <String>{};
    final operations = <VaultSyncOperationEntity>[];
    var sequence = latestSequence;

    bool addOperation({
      required String key,
      required String entityType,
      required String entityId,
      required String contentHash,
      required Map<String, dynamic> payload,
      String? previousKey,
      bool Function(String previousValue, String nextValue)? sameContent,
    }) {
      final resolvedPreviousKey = previousKey ?? key;
      final baseHash = previousContentIndex[resolvedPreviousKey] ?? '';
      if (baseHash.isNotEmpty) {
        consumedPreviousKeys.add(resolvedPreviousKey);
      }
      final unchanged =
          sameContent?.call(baseHash, contentHash) ?? baseHash == contentHash;
      if (unchanged) {
        nextIndex[key] = contentHash;
        nextPayloadIndex[key] = Map<String, dynamic>.from(payload);
        return false;
      }
      sequence += 1;
      operations.add(
        VaultSyncOperationEntity(
          opId: 'op_${deviceId}_$sequence',
          deviceId: deviceId,
          sequence: sequence,
          entityType: entityType,
          entityId: entityId,
          operation: baseHash.isEmpty ? 'create' : 'update',
          baseHash: baseHash,
          contentHash: contentHash,
          createdAtIso: createdAtIso,
          payload: payload,
        ),
      );
      nextIndex[key] = contentHash;
      nextPayloadIndex[key] = Map<String, dynamic>.from(payload);
      return true;
    }

    final nodeUnchangedByKey = <String, bool>{};
    final nodeKeyById = <String, String>{};

    for (final node in workspace.nodes) {
      final key = 'node:${node.type}:${node.id}';
      final contentHash = '${node.contentHash}:${node.metadataHash}';
      nodeKeyById[node.id] = key;
      final changed = addOperation(
        key: key,
        entityType: node.type,
        entityId: node.id,
        contentHash: contentHash,
        payload: node.toMap(),
        sameContent: _sameNodeIndexValue,
      );
      nodeUnchangedByKey[key] = !changed;
    }

    for (final file in workspace.files.where(_isUserVisibleFile)) {
      final identity = _fileIdentity(file);
      final key = 'file:$identity';
      final indexValue = _fileIndexValue(file);
      final previousKey = _previousFileKey(
        file: file,
        identityKey: key,
        previousContentIndex: previousContentIndex,
      );
      final relatedNodeKey = _relatedNodeKeyForGeneratedFile(
        identity,
        nodeKeyById,
      );
      final relatedNodeUnchanged =
          relatedNodeKey != null &&
          (nodeUnchangedByKey[relatedNodeKey] ?? false);
      addOperation(
        key: key,
        entityType: 'file',
        entityId: identity,
        contentHash: indexValue,
        payload: {
          'path': file.relativePath,
          'sha256': file.contentHash,
          'size_bytes': file.sizeBytes,
          'identity_key': identity,
        },
        previousKey: previousKey,
        sameContent: (previousValue, nextValue) {
          if (_sameFileIndexValue(
            previousValue,
            nextValue,
            allowPathlessPrevious: previousKey != key,
          )) {
            return true;
          }
          return _isGeneratedMirrorFile(file) &&
              relatedNodeUnchanged &&
              previousValue.trim().isNotEmpty;
        },
      );
    }

    for (final key in previousContentIndex.keys) {
      if (!nextIndex.containsKey(key) && !consumedPreviousKeys.contains(key)) {
        continue;
      }
      consumedPreviousKeys.add(key);
    }

    if (includeDeletes) {
      final removedKeys =
          previousContentIndex.keys
              .where((key) => !consumedPreviousKeys.contains(key))
              .toList(growable: false)
            ..sort();
      for (final key in removedKeys) {
        final parsed = _parseIndexKey(key);
        if (parsed == null) {
          continue;
        }
        sequence += 1;
        final baseHash = previousContentIndex[key] ?? '';
        final previousFilePath = parsed.entityType == 'file'
            ? _previousFilePath(
                key: key,
                entityId: parsed.entityId,
                indexValue: baseHash,
              )
            : '';
        final tombstone = VaultSyncTombstoneEntity(
          tombstoneId: 'ts_${deviceId}_$sequence',
          deviceId: deviceId,
          entityType: parsed.entityType,
          entityId: parsed.entityId,
          deletedAtIso: createdAtIso,
          baseHash: baseHash,
          retainUntilIso: retainUntilIso,
        );
        operations.add(
          VaultSyncOperationEntity(
            opId: 'op_${deviceId}_$sequence',
            deviceId: deviceId,
            sequence: sequence,
            entityType: parsed.entityType,
            entityId: parsed.entityId,
            operation: 'delete',
            baseHash: baseHash,
            contentHash: '',
            createdAtIso: createdAtIso,
            payload: previousFilePath.isEmpty
                ? const <String, dynamic>{}
                : {'path': previousFilePath},
            tombstone: tombstone,
          ),
        );
      }
    } else {
      for (final key in previousContentIndex.keys) {
        if (consumedPreviousKeys.contains(key) || nextIndex.containsKey(key)) {
          continue;
        }
        nextIndex[key] = previousContentIndex[key] ?? '';
      }
    }

    return VaultSyncUploadPlan(
      operations: operations,
      nextContentIndex: nextIndex,
      nextPayloadIndex: nextPayloadIndex,
      blobFiles: const <VaultMirrorFile>[],
      latestSequence: sequence,
    );
  }

  Map<String, String> contentIndexFor(VaultMirrorWorkspace workspace) {
    final index = <String, String>{};
    for (final node in workspace.nodes) {
      index['node:${node.type}:${node.id}'] =
          '${node.contentHash}:${node.metadataHash}';
    }
    for (final file in workspace.files.where(_isUserVisibleFile)) {
      index['file:${_fileIdentity(file)}'] = _fileIndexValue(file);
    }
    return index;
  }

  Map<String, Map<String, dynamic>> contentPayloadIndexFor(
    VaultMirrorWorkspace workspace,
  ) {
    final index = <String, Map<String, dynamic>>{};
    for (final node in workspace.nodes) {
      index['node:${node.type}:${node.id}'] = node.toMap();
    }
    for (final file in workspace.files.where(_isUserVisibleFile)) {
      final identity = _fileIdentity(file);
      index['file:$identity'] = {
        'path': file.relativePath,
        'sha256': file.contentHash,
        'size_bytes': file.sizeBytes,
        'identity_key': identity,
      };
    }
    return index;
  }

  String _fileIdentity(VaultMirrorFile file) {
    final identity = file.identityKey?.trim() ?? '';
    return identity.isNotEmpty ? identity : 'path:${file.relativePath}';
  }

  String _fileIndexValue(VaultMirrorFile file) {
    return 'v2|path=${Uri.encodeComponent(file.relativePath)}|sha256=${file.contentHash}';
  }

  String _previousFileKey({
    required VaultMirrorFile file,
    required String identityKey,
    required Map<String, String> previousContentIndex,
  }) {
    if (previousContentIndex.containsKey(identityKey)) {
      return identityKey;
    }
    final legacyPathKey = 'file:${file.relativePath}';
    if (previousContentIndex.containsKey(legacyPathKey)) {
      return legacyPathKey;
    }
    final pathIdentityKey = 'file:path:${file.relativePath}';
    if (previousContentIndex.containsKey(pathIdentityKey)) {
      return pathIdentityKey;
    }
    return identityKey;
  }

  bool _sameFileIndexValue(
    String previousValue,
    String nextValue, {
    required bool allowPathlessPrevious,
  }) {
    if (previousValue == nextValue) {
      return true;
    }
    final previous = _parseFileIndexValue(previousValue);
    final next = _parseFileIndexValue(nextValue);
    return previous.sha256.isNotEmpty &&
        previous.sha256 == next.sha256 &&
        (previous.path == next.path ||
            (allowPathlessPrevious && previous.path.isEmpty));
  }

  bool _sameNodeIndexValue(String previousValue, String nextValue) {
    if (previousValue == nextValue) {
      return true;
    }
    final previousMetadataHash = _nodeMetadataHash(previousValue);
    final nextMetadataHash = _nodeMetadataHash(nextValue);
    return previousMetadataHash.isNotEmpty &&
        previousMetadataHash == nextMetadataHash;
  }

  String _nodeMetadataHash(String value) {
    final separator = value.lastIndexOf(':');
    if (separator < 0 || separator == value.length - 1) {
      return '';
    }
    return value.substring(separator + 1).trim();
  }

  String? _relatedNodeKeyForGeneratedFile(
    String identity,
    Map<String, String> nodeKeyById,
  ) {
    final parts = identity.split(':');
    if (parts.length < 3) {
      return null;
    }

    final type = parts[0];
    final id = parts[1];
    if (type == 'document' && parts.last == 'body') {
      return 'node:document:$id';
    }
    if (type == 'credential' && parts.last == 'body') {
      return 'node:credential:$id';
    }
    if (type == 'secure_note' && parts.last == 'body') {
      return 'node:secure_note:$id';
    }
    if (type == 'task_list' && parts.last == 'body') {
      return 'node:task_list:$id';
    }
    if (type == 'bundle' && parts.last == 'body') {
      return 'node:bundle:$id';
    }
    if (type == 'profile' && id == 'profile' && parts.last == 'body') {
      return 'node:profile:profile';
    }
    if (type == 'collection_block' && parts.last == 'content') {
      return nodeKeyById[id];
    }
    return null;
  }

  bool _isGeneratedMirrorFile(VaultMirrorFile file) {
    if (!file.isInline) {
      return false;
    }
    final path = file.relativePath.trim().toLowerCase();
    return path.endsWith('.md') || path.endsWith('.url');
  }

  bool _isUserVisibleFile(VaultMirrorFile file) {
    final path = file.relativePath.trim();
    if (path.isEmpty) {
      return false;
    }
    return VaultMirrorWorkspace.isUserVisibleMirrorPath(path);
  }

  _ParsedIndexKey? _parseIndexKey(String key) {
    final parts = key.split(':');
    if (parts.length < 3) {
      if (parts.length == 2 && parts.first == 'file') {
        return _ParsedIndexKey(entityType: 'file', entityId: parts.last);
      }
      return null;
    }
    if (parts.first == 'node') {
      return _ParsedIndexKey(
        entityType: parts[1],
        entityId: parts.sublist(2).join(':'),
      );
    }
    if (parts.first == 'file') {
      return _ParsedIndexKey(
        entityType: 'file',
        entityId: parts.sublist(1).join(':'),
      );
    }
    return null;
  }

  String _previousFilePath({
    required String key,
    required String entityId,
    required String indexValue,
  }) {
    final parsed = _parseFileIndexValue(indexValue);
    if (parsed.path.isNotEmpty) {
      return parsed.path;
    }
    if (entityId.startsWith('path:')) {
      return entityId.substring(5);
    }
    if (entityId.contains('/')) {
      return entityId;
    }
    if (key.startsWith('file:')) {
      final legacy = key.substring(5);
      if (legacy.contains('/')) {
        return legacy;
      }
    }
    return '';
  }

  _FileIndexValue _parseFileIndexValue(String value) {
    if (!value.startsWith('v2|')) {
      return _FileIndexValue(path: '', sha256: value);
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
    return _FileIndexValue(path: path, sha256: sha256);
  }
}

class _FileIndexValue {
  const _FileIndexValue({required this.path, required this.sha256});

  final String path;
  final String sha256;
}

class _ParsedIndexKey {
  const _ParsedIndexKey({required this.entityType, required this.entityId});

  final String entityType;
  final String entityId;
}
