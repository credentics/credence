import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/bundles/datasources/local/bundles_local_data_source.dart';
import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';
import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/datasources/local/document_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/dtos/document_record_dto.dart';
import 'package:pass_doc_manager/data/notes/datasources/local/secure_notes_local_data_source.dart';
import 'package:pass_doc_manager/data/notes/dtos/secure_note_dto.dart';
import 'package:pass_doc_manager/data/profile/datasources/local/profile_local_data_source.dart';
import 'package:pass_doc_manager/data/profile/dtos/profile_record_dto.dart';
import 'package:pass_doc_manager/data/tasks/datasources/local/tasks_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/local_folder_mirror_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_service.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace_builder.dart';

import '../../../support/hive_test_harness.dart';

/// End-to-end proof that vault records survive a full mirror cycle:
/// seed real (encrypted-Hive-backed) data sources → build the mirror workspace
/// → write it to disk → wipe the vault → restore from the mirror → the records
/// come back byte-for-byte.
///
/// This is the test that would have caught the `.vaultic → .credence`
/// metadata-dir regression (manifest at the wrong path → restore throws) and
/// any record-dropping export bug (fewer records back than went in).
void main() {
  late HiveTestHarness harness;

  setUp(() async => harness = await HiveTestHarness.start());
  tearDown(() async => harness.stop());

  test('records survive build → write → wipe → restore', () async {
    final documents = await DocumentLocalDataSource.create();
    final collections = await CollectionsLocalDataSource.create();
    final bundles = await BundlesLocalDataSource.create();
    final tasks = await TasksLocalDataSource.create();
    final credentials = await CredentialLocalDataSource.create();
    final profile = await ProfileLocalDataSource.create();
    // Secure notes live in sqflite (not Hive); the ffi factory isn't wired for
    // `flutter test`, so stand in an empty in-memory notes source. This
    // round-trip doesn't seed notes — documents, collections, and profile are
    // enough to exercise the manifest/snapshot/restore path.
    final notes = _EmptySecureNotes();

    VaultMirrorWorkspaceBuilder builder() => VaultMirrorWorkspaceBuilder(
      documentLocalDataSource: documents,
      collectionsLocalDataSource: collections,
      bundlesLocalDataSource: bundles,
      tasksLocalDataSource: tasks,
      credentialLocalDataSource: credentials,
      profileLocalDataSource: profile,
      secureNotesLocalDataSource: notes,
    );
    VaultMirrorImportService importService() => VaultMirrorImportService(
      documentLocalDataSource: documents,
      collectionsLocalDataSource: collections,
      bundlesLocalDataSource: bundles,
      tasksLocalDataSource: tasks,
      credentialLocalDataSource: credentials,
      profileLocalDataSource: profile,
      secureNotesLocalDataSource: notes,
    );

    // ---- seed the source vault ----
    final sourceDocs = [
      _doc(id: 'doc-passport', title: 'Passport', category: 'identity'),
      _doc(id: 'doc-lease', title: 'Apartment Lease', category: 'property'),
    ];
    await documents.replaceDocuments(sourceDocs);

    final sourceCollections = [_collection(id: 'col-trip', name: 'Japan Trip')];
    await collections.saveCollections(sourceCollections);

    final sourceProfile = _profile();
    await profile.writeProfile(sourceProfile);

    // ---- build the mirror workspace and materialize it on disk ----
    final workspace = await builder().build(
      deviceId: 'round-trip-device',
      revision: 1,
    );
    final mirrorDir = '${harness.directory.path}/mirror_out';
    await const LocalFolderMirrorDataSource().writeWorkspace(
      folderPath: mirrorDir,
      workspace: workspace,
    );

    // ---- wipe the local vault so the restore has to repopulate it ----
    await documents.replaceDocuments(const []);
    await collections.saveCollections(const []);
    await profile.writeProfile(_emptyProfile());
    expect(await documents.getDocuments(), isEmpty);
    expect(await collections.getCollections(), isEmpty);

    // ---- restore from the mirror ----
    final result = await importService().importFromSource(
      source: LocalFolderVaultMirrorImportSource(folderPath: mirrorDir),
      mode: VaultMirrorImportMode.replace,
    );
    expect(result.warningMessage, isNull, reason: 'no data should be lost');

    // ---- the vault is back, field-for-field ----
    // Compare against the source after one storage canonicalization cycle
    // (fromMap(toMap())) so benign normalization — e.g. an empty date string
    // stored as null — is not mistaken for data loss. Any dropped or mutated
    // field still fails.
    expect(
      _byId(await documents.getDocuments(), (d) => d.id, (d) => d.toMap()),
      _byId(
        [for (final d in sourceDocs) DocumentRecordDto.fromMap(d.toMap())],
        (d) => d.id,
        (d) => d.toMap(),
      ),
    );
    expect(
      _byId(await collections.getCollections(), (c) => c.id, (c) => c.toMap()),
      _byId(
        [
          for (final c in sourceCollections)
            CollectionRecordDto.fromMap(c.toMap()),
        ],
        (c) => c.id,
        (c) => c.toMap(),
      ),
    );
    expect(
      (await profile.readProfile()).toMap(),
      ProfileRecordDto.fromMap(sourceProfile.toMap()).toMap(),
    );
  });
}

Map<String, Map<String, dynamic>> _byId<T>(
  Iterable<T> items,
  String Function(T) id,
  Map<String, dynamic> Function(T) toMap,
) => {for (final item in items) id(item): toMap(item)};

DocumentRecordDto _doc({
  required String id,
  required String title,
  required String category,
}) => DocumentRecordDto(
  id: id,
  title: title,
  fileName: '$id.pdf',
  categoryKey: category,
  updatedAtIso: '2026-02-01T10:00:00.000Z',
  documentType: 'reference',
  identityGroupKey: '',
  identifierLabel: 'Reference',
  identifierValue: id.toUpperCase(),
  expiryAtIso: '',
  requiresAttention: false,
  structuredFields: [
    {'label': 'Document Title', 'value': title},
    {'label': 'Notes', 'value': 'Seeded for the round-trip test.'},
  ],
);

CollectionRecordDto _collection({required String id, required String name}) =>
    CollectionRecordDto(
      id: id,
      name: name,
      subtitle: 'Round-trip fixture',
      iconKey: 'folder',
      accentColorHex: '#3B6D11',
      startDateIso: '',
      endDateIso: '',
      coverImageUrl: '',
      updatedAtIso: '2026-02-01T10:00:00.000Z',
      blocks: const [],
    );

ProfileRecordDto _profile() => const ProfileRecordDto(
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: 'ada@example.com',
  phone: '+1 555 0100',
  address: '1 Analytical Engine Way',
  socialLinks: 'https://example.com/ada',
  photoPath: '',
  updatedAtIso: '2026-02-01T10:00:00.000Z',
);

ProfileRecordDto _emptyProfile() => const ProfileRecordDto(
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  address: '',
  socialLinks: '',
  photoPath: '',
  updatedAtIso: '',
);

/// An in-memory stand-in for the sqflite-backed secure notes source, so the
/// round-trip runs under `flutter test` without the sqflite ffi factory. The
/// builder only reads notes and the import (replace mode) only writes them;
/// both are no-ops here because this fixture carries no notes.
class _EmptySecureNotes extends SecureNotesLocalDataSource {
  @override
  Future<List<SecureNoteDetailDto>> getAllNoteDetails() async => const [];

  @override
  Future<void> replaceNoteSnapshots(
    List<Map<String, dynamic>> snapshots,
  ) async {}
}
