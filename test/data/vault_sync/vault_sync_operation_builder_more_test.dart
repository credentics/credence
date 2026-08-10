import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/data/vault_sync/services/vault_sync_operation_builder.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 1, 1);

  group('VaultSyncOperationBuilder.build additional behaviors', () {
    test('1. brand-new node emits a create op with a stable opId', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _nodeOnlyWorkspace(),
        previousContentIndex: const {},
        deviceId: 'device_a',
        latestSequence: 0,
        now: fixedNow,
      );

      expect(plan.operations, hasLength(1));
      final operation = plan.operations.single;
      expect(operation.operation, 'create');
      expect(operation.entityType, 'document');
      expect(operation.entityId, 'doc_1');
      expect(operation.baseHash, '');
      // opId is op_<deviceId>_<seq>, sequence starting at latestSequence + 1.
      expect(operation.opId, 'op_device_a_1');
      expect(operation.sequence, 1);
      expect(plan.nextContentIndex.keys, contains('node:document:doc_1'));
      expect(
        plan.nextContentIndex['node:document:doc_1'],
        'node_hash:metadata_hash',
      );
      expect(plan.latestSequence, 1);
    });

    test('2. unchanged node emits no op but is retained in nextContentIndex', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _nodeOnlyWorkspace(),
        previousContentIndex: const {
          'node:document:doc_1': 'node_hash:metadata_hash',
        },
        deviceId: 'device_a',
        latestSequence: 5,
        now: fixedNow,
      );

      expect(plan.operations, isEmpty);
      expect(plan.latestSequence, 5);
      expect(
        plan.nextContentIndex,
        containsPair('node:document:doc_1', 'node_hash:metadata_hash'),
      );
    });

    test('3. changed node emits an update op carrying the previous hash as baseHash', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _nodeOnlyWorkspace(
          contentHash: 'new_content_hash',
          metadataHash: 'new_metadata_hash',
        ),
        previousContentIndex: const {
          'node:document:doc_1': 'old_content_hash:old_metadata_hash',
        },
        deviceId: 'device_a',
        latestSequence: 10,
        now: fixedNow,
      );

      expect(plan.operations, hasLength(1));
      final operation = plan.operations.single;
      expect(operation.operation, 'update');
      expect(operation.entityType, 'document');
      expect(operation.entityId, 'doc_1');
      expect(operation.baseHash, 'old_content_hash:old_metadata_hash');
      expect(operation.contentHash, 'new_content_hash:new_metadata_hash');
      expect(operation.opId, 'op_device_a_11');
      expect(plan.latestSequence, 11);
    });

    test('4. removed node with includeDeletes:true emits a delete with a deterministic tombstone', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _emptyWorkspace(),
        previousContentIndex: const {
          'node:document:doc_1': 'node_hash:metadata_hash',
        },
        deviceId: 'device_a',
        latestSequence: 4,
        now: fixedNow,
      );

      expect(plan.operations, hasLength(1));
      final operation = plan.operations.single;
      expect(operation.operation, 'delete');
      expect(operation.entityType, 'document');
      expect(operation.entityId, 'doc_1');
      expect(operation.baseHash, 'node_hash:metadata_hash');
      expect(operation.contentHash, '');

      final tombstone = operation.tombstone;
      expect(tombstone, isNotNull);
      expect(tombstone!.entityType, 'document');
      expect(tombstone.entityId, 'doc_1');
      // deletedAtIso comes from `now`.
      expect(tombstone.deletedAtIso, '2026-01-01T00:00:00.000Z');
      // retainUntilIso = now + 90d (default tombstoneRetention).
      expect(tombstone.retainUntilIso, '2026-04-01T00:00:00.000Z');
      expect(tombstone.baseHash, 'node_hash:metadata_hash');
      expect(plan.latestSequence, 5);
    });

    test('5. includeDeletes:false emits no delete and carries the removed key forward', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _emptyWorkspace(),
        previousContentIndex: const {
          'node:document:doc_1': 'node_hash:metadata_hash',
        },
        deviceId: 'device_a',
        latestSequence: 4,
        includeDeletes: false,
        now: fixedNow,
      );

      expect(plan.operations, isEmpty);
      expect(plan.latestSequence, 4);
      expect(
        plan.nextContentIndex,
        containsPair('node:document:doc_1', 'node_hash:metadata_hash'),
      );
    });

    test('6. opId sequence numbering increments deterministically from latestSequence', () {
      final builder = VaultSyncOperationBuilder();
      final plan = builder.build(
        workspace: _multiNodeWorkspace(),
        previousContentIndex: const {},
        deviceId: 'device_b',
        latestSequence: 7,
        now: fixedNow,
      );

      expect(plan.operations, hasLength(3));
      final sequences = plan.operations.map((op) => op.sequence).toList();
      expect(sequences, [8, 9, 10]);
      final opIds = plan.operations.map((op) => op.opId).toList();
      expect(opIds, [
        'op_device_b_8',
        'op_device_b_9',
        'op_device_b_10',
      ]);
      // Deterministic timestamps from the fixed `now`.
      for (final operation in plan.operations) {
        expect(operation.createdAtIso, '2026-01-01T00:00:00.000Z');
      }
      expect(plan.latestSequence, 10);
    });

    test('7. contentIndexFor / contentPayloadIndexFor use the node:<type>:<id> scheme', () {
      final builder = VaultSyncOperationBuilder();
      final workspace = _nodeOnlyWorkspace(withFile: true);

      final contentIndex = builder.contentIndexFor(workspace);
      expect(contentIndex.keys, contains('node:document:doc_1'));
      expect(contentIndex['node:document:doc_1'], 'node_hash:metadata_hash');
      // File identity uses its identityKey → file:<type>:<id>:<part>.
      expect(contentIndex.keys, contains('file:document:doc_1:body'));

      final payloadIndex = builder.contentPayloadIndexFor(workspace);
      expect(payloadIndex.keys, contains('node:document:doc_1'));
      expect(payloadIndex['node:document:doc_1'], isA<Map<String, dynamic>>());
      expect(payloadIndex['node:document:doc_1']!['id'], 'doc_1');
      expect(payloadIndex.keys, contains('file:document:doc_1:body'));
      expect(
        payloadIndex['file:document:doc_1:body']!['identity_key'],
        'document:doc_1:body',
      );
    });
  });
}

VaultMirrorWorkspace _nodeOnlyWorkspace({
  String contentHash = 'node_hash',
  String metadataHash = 'metadata_hash',
  bool withFile = false,
}) {
  return _workspace(
    nodes: [
      VaultMirrorNode(
        id: 'doc_1',
        type: 'document',
        displayName: 'Passport',
        path: 'Documents/passport.pdf',
        order: 0,
        metadata: const {'id': 'doc_1', 'title': 'Passport'},
        contentHash: contentHash,
        metadataHash: metadataHash,
        updatedAtIso: '2026-01-01T00:00:00Z',
      ),
    ],
    files: withFile
        ? const [
            VaultMirrorFile(
              relativePath: 'Documents/passport.pdf',
              contentHash: 'file_hash',
              sizeBytes: 4,
              bytes: [1, 2, 3, 4],
              identityKey: 'document:doc_1:body',
            ),
          ]
        : const [],
  );
}

VaultMirrorWorkspace _multiNodeWorkspace() {
  return _workspace(
    nodes: const [
      VaultMirrorNode(
        id: 'doc_1',
        type: 'document',
        displayName: 'Passport',
        path: 'Documents/passport.pdf',
        order: 0,
        metadata: {'id': 'doc_1', 'title': 'Passport'},
        contentHash: 'node_hash_1',
        metadataHash: 'metadata_hash_1',
        updatedAtIso: '2026-01-01T00:00:00Z',
      ),
      VaultMirrorNode(
        id: 'doc_2',
        type: 'document',
        displayName: 'License',
        path: 'Documents/license.pdf',
        order: 1,
        metadata: {'id': 'doc_2', 'title': 'License'},
        contentHash: 'node_hash_2',
        metadataHash: 'metadata_hash_2',
        updatedAtIso: '2026-01-01T00:00:00Z',
      ),
    ],
    files: const [
      VaultMirrorFile(
        relativePath: 'Documents/passport.pdf',
        contentHash: 'file_hash_1',
        sizeBytes: 4,
        bytes: [1, 2, 3, 4],
        identityKey: 'document:doc_1:body',
      ),
    ],
  );
}

VaultMirrorWorkspace _emptyWorkspace() {
  return _workspace(nodes: const [], files: const []);
}

VaultMirrorWorkspace _workspace({
  required List<VaultMirrorNode> nodes,
  required List<VaultMirrorFile> files,
}) {
  return VaultMirrorWorkspace(
    revision: 1,
    deviceId: 'device_a',
    generatedAtIso: '2026-01-01T00:00:00Z',
    directories: const {'Documents', '.credence'},
    files: files,
    nodes: nodes,
    snapshot: const {},
    manifestText: '{}',
    manifestChecksum: 'manifest_hash',
    contentChecksum: 'content_hash',
  );
}
