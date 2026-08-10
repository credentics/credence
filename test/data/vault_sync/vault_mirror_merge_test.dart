import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_service.dart';

void main() {
  group('mergePrefersIncomingByTimestamp', () {
    const t1 = '2026-01-01T00:00:00Z';
    const t2 = '2026-06-01T00:00:00Z';

    test('strictly newer remote wins', () {
      expect(mergePrefersIncomingByTimestamp(t2, t1), isTrue);
    });

    test('older remote loses to local', () {
      expect(mergePrefersIncomingByTimestamp(t1, t2), isFalse);
    });

    test('equal timestamps keep local (no silent overwrite)', () {
      expect(mergePrefersIncomingByTimestamp(t1, t1), isFalse);
    });

    test('only remote timestamped → remote wins', () {
      expect(mergePrefersIncomingByTimestamp(t1, null), isTrue);
      expect(mergePrefersIncomingByTimestamp(t1, ''), isTrue);
    });

    test('only local timestamped → keep local', () {
      expect(mergePrefersIncomingByTimestamp(null, t1), isFalse);
    });

    test('neither timestamped → keep local (deterministic)', () {
      expect(mergePrefersIncomingByTimestamp(null, null), isFalse);
      expect(mergePrefersIncomingByTimestamp('', ' '), isFalse);
    });

    test('unparseable timestamps are treated as absent', () {
      expect(mergePrefersIncomingByTimestamp('not-a-date', t1), isFalse);
      expect(mergePrefersIncomingByTimestamp(t2, 'not-a-date'), isTrue);
    });
  });

  group('mergeTombstoneWins', () {
    const deleted = '2026-03-01T00:00:00Z';

    test('delete wins when local is older than the deletion', () {
      expect(mergeTombstoneWins(deleted, '2026-01-01T00:00:00Z'), isTrue);
    });

    test('delete wins when local has no timestamp', () {
      expect(mergeTombstoneWins(deleted, null), isTrue);
      expect(mergeTombstoneWins(deleted, ''), isTrue);
    });

    test('local edit strictly newer than the delete survives', () {
      expect(mergeTombstoneWins(deleted, '2026-06-01T00:00:00Z'), isFalse);
    });

    test('equal timestamps → delete wins', () {
      expect(mergeTombstoneWins(deleted, deleted), isTrue);
    });

    test('unparseable deletion timestamp still deletes', () {
      // Can not prove the local edit is newer, so the delete is honored.
      expect(mergeTombstoneWins('garbage', '2026-06-01T00:00:00Z'), isTrue);
    });
  });

  group('parseSnapshotTombstones', () {
    test('groups by entity type and id', () {
      final parsed = parseSnapshotTombstones([
        {
          'entity_type': 'document',
          'entity_id': 'd1',
          'deleted_at_iso': '2026-03-01T00:00:00Z',
        },
        {
          'entity_type': 'collection',
          'entity_id': 'c1',
          'deleted_at_iso': '2026-03-02T00:00:00Z',
        },
      ]);
      expect(parsed['document'], {'d1': '2026-03-01T00:00:00Z'});
      expect(parsed['collection'], {'c1': '2026-03-02T00:00:00Z'});
    });

    test('skips malformed / empty entries and non-lists', () {
      expect(parseSnapshotTombstones(null), isEmpty);
      expect(parseSnapshotTombstones('nope'), isEmpty);
      final parsed = parseSnapshotTombstones([
        {'entity_type': '', 'entity_id': 'x'},
        {'entity_type': 'document', 'entity_id': ''},
        'garbage',
        {'entity_type': 'document', 'entity_id': 'ok'},
      ]);
      expect(parsed, {
        'document': {'ok': ''},
      });
    });
  });
}
