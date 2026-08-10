import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/data/vault_sync/services/vault_sync_operation_builder.dart';

void main() {
  group('VaultSyncOperationBuilder', () {
    test('creates operations from readable workspace', () {
      final builder = VaultSyncOperationBuilder();
      final workspace = _workspace();

      final plan = builder.build(
        workspace: workspace,
        previousContentIndex: const {},
        deviceId: 'device_a',
        latestSequence: 0,
        now: DateTime.utc(2026, 5, 22, 10),
      );

      expect(plan.operations, hasLength(2));
      expect(plan.latestSequence, 2);
      expect(plan.nextContentIndex.keys, contains('node:document:doc_1'));
      expect(plan.nextContentIndex.keys, contains('file:document:doc_1:body'));

      final fileOperation = plan.operations.firstWhere(
        (operation) => operation.entityType == 'file',
      );
      expect(fileOperation.operation, 'create');
      expect(fileOperation.blobs, isEmpty);
      expect(plan.blobFiles, isEmpty);
      expect(
        plan.nextContentIndex.keys,
        isNot(contains('file:.credence/snapshot.json')),
      );
    });

    test('skips unchanged records while preserving sequence', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _workspace(),
        previousContentIndex: const {
          'node:document:doc_1': 'node_hash:metadata_hash',
          'file:document:doc_1:body':
              'v2|path=Documents%2Fpassport.pdf|sha256=file_hash',
        },
        deviceId: 'device_a',
        latestSequence: 8,
        now: DateTime.utc(2026, 5, 22, 10),
      );

      expect(plan.operations, isEmpty);
      expect(plan.latestSequence, 8);
    });

    test('creates tombstones for locally removed indexed entities', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _workspace(nodes: const [], files: const []),
        previousContentIndex: const {
          'node:document:doc_1': 'node_hash:metadata_hash',
        },
        deviceId: 'device_a',
        latestSequence: 3,
        now: DateTime.utc(2026, 5, 22, 10),
      );

      expect(plan.operations, hasLength(1));
      final operation = plan.operations.single;
      expect(operation.operation, 'delete');
      expect(operation.entityType, 'document');
      expect(operation.entityId, 'doc_1');
      expect(operation.tombstone, isNotNull);
      expect(operation.tombstone!.retainUntilIso, '2026-08-20T10:00:00.000Z');
    });

    test('can skip inferred deletions until user confirms them', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _workspace(nodes: const [], files: const []),
        previousContentIndex: const {
          'node:document:doc_1': 'node_hash:metadata_hash',
          'file:document:doc_1:body':
              'v2|path=Documents%2Fpassport.pdf|sha256=file_hash',
        },
        deviceId: 'device_a',
        latestSequence: 3,
        includeDeletes: false,
        now: DateTime.utc(2026, 5, 22, 10),
      );

      expect(plan.operations, isEmpty);
      expect(plan.nextContentIndex, {
        'node:document:doc_1': 'node_hash:metadata_hash',
        'file:document:doc_1:body':
            'v2|path=Documents%2Fpassport.pdf|sha256=file_hash',
      });
      expect(plan.latestSequence, 3);
    });

    test('treats stable file path changes as updates instead of deletes', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _workspace(
          files: const [
            VaultMirrorFile(
              relativePath: 'Documents/passport renamed.pdf',
              contentHash: 'file_hash',
              sizeBytes: 4,
              bytes: [1, 2, 3, 4],
              identityKey: 'document:doc_1:body',
            ),
          ],
        ),
        previousContentIndex: const {
          'node:document:doc_1': 'node_hash:metadata_hash',
          'file:document:doc_1:body':
              'v2|path=Documents%2Fpassport.pdf|sha256=file_hash',
        },
        deviceId: 'device_a',
        latestSequence: 8,
        now: DateTime.utc(2026, 5, 22, 10),
      );

      final fileOperation = plan.operations.singleWhere(
        (operation) => operation.entityType == 'file',
      );
      expect(fileOperation.operation, 'update');
      expect(fileOperation.entityId, 'document:doc_1:body');
      expect(fileOperation.payload['path'], 'Documents/passport renamed.pdf');
      expect(
        plan.operations.where((operation) => operation.operation == 'delete'),
        isEmpty,
      );
    });

    test('migrates legacy path-based file indexes without uploading', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _workspace(),
        previousContentIndex: const {
          'node:document:doc_1': 'node_hash:metadata_hash',
          'file:Documents/passport.pdf': 'file_hash',
        },
        deviceId: 'device_a',
        latestSequence: 8,
        now: DateTime.utc(2026, 5, 22, 10),
      );

      expect(plan.operations, isEmpty);
      expect(
        plan.nextContentIndex,
        containsPair(
          'file:document:doc_1:body',
          'v2|path=Documents%2Fpassport.pdf|sha256=file_hash',
        ),
      );
      expect(
        plan.nextContentIndex,
        isNot(contains('file:Documents/passport.pdf')),
      );
    });

    test('migrates legacy path-based file updates without delete noise', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _workspace(
          files: const [
            VaultMirrorFile(
              relativePath: 'Documents/passport.pdf',
              contentHash: 'new_file_hash',
              sizeBytes: 4,
              bytes: [1, 2, 3, 4],
              identityKey: 'document:doc_1:body',
            ),
          ],
        ),
        previousContentIndex: const {
          'node:document:doc_1': 'node_hash:metadata_hash',
          'file:Documents/passport.pdf': 'file_hash',
        },
        deviceId: 'device_a',
        latestSequence: 8,
        now: DateTime.utc(2026, 5, 22, 10),
      );

      final fileOperation = plan.operations.singleWhere(
        (operation) => operation.entityType == 'file',
      );
      expect(fileOperation.operation, 'update');
      expect(fileOperation.entityId, 'document:doc_1:body');
      expect(fileOperation.payload['path'], 'Documents/passport.pdf');
      expect(
        plan.operations.where((operation) => operation.operation == 'delete'),
        isEmpty,
      );
    });

    test('ignores generated markdown hash drift when record is unchanged', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _workspace(
          nodes: const [
            VaultMirrorNode(
              id: 'doc_1',
              type: 'document',
              displayName: 'Passport',
              path: 'Documents/passport.md',
              order: 0,
              metadata: {'id': 'doc_1', 'title': 'Passport'},
              contentHash: 'new_path_hash',
              metadataHash: 'metadata_hash',
              updatedAtIso: '2026-05-22T10:00:00Z',
            ),
          ],
          files: const [
            VaultMirrorFile(
              relativePath: 'Documents/passport.md',
              contentHash: 'new_markdown_hash',
              sizeBytes: 32,
              bytes: [1, 2, 3, 4],
              identityKey: 'document:doc_1:body',
            ),
          ],
        ),
        previousContentIndex: const {
          'node:document:doc_1': 'old_path_hash:metadata_hash',
          'file:document:doc_1:body':
              'v2|path=Documents%2Fpassport.md|sha256=old_markdown_hash',
        },
        deviceId: 'device_a',
        latestSequence: 8,
        now: DateTime.utc(2026, 5, 22, 10),
      );

      expect(plan.operations, isEmpty);
      expect(
        plan.nextContentIndex['file:document:doc_1:body'],
        'v2|path=Documents%2Fpassport.md|sha256=new_markdown_hash',
      );
    });

    test('uploads generated markdown when record metadata changed', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _workspace(
          nodes: const [
            VaultMirrorNode(
              id: 'doc_1',
              type: 'document',
              displayName: 'Passport',
              path: 'Documents/passport.md',
              order: 0,
              metadata: {'id': 'doc_1', 'title': 'Passport updated'},
              contentHash: 'new_path_hash',
              metadataHash: 'new_metadata_hash',
              updatedAtIso: '2026-05-22T10:00:00Z',
            ),
          ],
          files: const [
            VaultMirrorFile(
              relativePath: 'Documents/passport.md',
              contentHash: 'new_markdown_hash',
              sizeBytes: 32,
              bytes: [1, 2, 3, 4],
              identityKey: 'document:doc_1:body',
            ),
          ],
        ),
        previousContentIndex: const {
          'node:document:doc_1': 'old_path_hash:metadata_hash',
          'file:document:doc_1:body':
              'v2|path=Documents%2Fpassport.md|sha256=old_markdown_hash',
        },
        deviceId: 'device_a',
        latestSequence: 8,
        now: DateTime.utc(2026, 5, 22, 10),
      );

      expect(
        plan.operations.where((operation) => operation.entityType == 'file'),
        hasLength(1),
      );
      expect(
        plan.operations.where(
          (operation) => operation.entityType == 'document',
        ),
        hasLength(1),
      );
    });
  });
}

VaultMirrorWorkspace _workspace({
  List<VaultMirrorNode>? nodes,
  List<VaultMirrorFile>? files,
}) {
  return VaultMirrorWorkspace(
    revision: 1,
    deviceId: 'device_a',
    generatedAtIso: '2026-05-22T10:00:00Z',
    directories: const {'Documents', '.credence'},
    files:
        files ??
        const [
          VaultMirrorFile(
            relativePath: 'Documents/passport.pdf',
            contentHash: 'file_hash',
            sizeBytes: 4,
            bytes: [1, 2, 3, 4],
            identityKey: 'document:doc_1:body',
          ),
          VaultMirrorFile(
            relativePath: '.credence/snapshot.json',
            contentHash: 'snapshot_hash',
            sizeBytes: 2,
            bytes: [123, 125],
          ),
        ],
    nodes:
        nodes ??
        const [
          VaultMirrorNode(
            id: 'doc_1',
            type: 'document',
            displayName: 'Passport',
            path: 'Documents/passport.pdf',
            order: 0,
            metadata: {'id': 'doc_1', 'title': 'Passport'},
            contentHash: 'node_hash',
            metadataHash: 'metadata_hash',
            updatedAtIso: '2026-05-22T10:00:00Z',
          ),
        ],
    snapshot: const {},
    manifestText: '{}',
    manifestChecksum: 'manifest_hash',
    contentChecksum: 'content_hash',
  );
}
