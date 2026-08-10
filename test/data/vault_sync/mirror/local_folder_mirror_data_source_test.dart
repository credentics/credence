import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/local_folder_mirror_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_head_entity.dart';

/// The local-folder mirror is the third reader behind the same readHead
/// contract as Dropbox and Google Drive. This pins the same scenarios against
/// the filesystem so the three sources cannot silently diverge: prefer
/// head.json, fall back to the manifest, and report null when neither exists.
void main() {
  late Directory dir;
  const source = LocalFolderMirrorDataSource();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('local_mirror_head_test');
  });
  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<void> writeMirrorFile(String relativePath, String contents) async {
    final file = File('${dir.path}/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
  }

  test('reads head.json when present', () async {
    const head = VaultSyncHeadEntity(
      revision: 7,
      deviceId: 'device-a',
      manifestHash: 'checksum-7',
      generatedAtIso: '2026-02-01T00:00:00.000Z',
      provider: 'local',
      fileCount: 3,
      directoryCount: 2,
    );
    await writeMirrorFile(VaultMirrorWorkspace.headPath, head.toJsonText());

    final result = await source.readHead(folderPath: dir.path);

    expect(result, isNotNull);
    expect(result!.revision, 7);
    expect(result.deviceId, 'device-a');
  });

  test('falls back to manifest.json when head.json is absent', () async {
    await writeMirrorFile(
      VaultMirrorWorkspace.manifestPath,
      '{"revision":5,"device_id":"device-b","content_checksum":"cc-5",'
      '"files":[],"directories":[]}',
    );

    final result = await source.readHead(folderPath: dir.path);

    expect(result, isNotNull);
    expect(result!.revision, 5, reason: 'derived from the manifest fallback');
    expect(result.manifestHash, 'cc-5');
  });

  test('returns null when neither head nor manifest exist', () async {
    expect(await source.readHead(folderPath: dir.path), isNull);
  });

  test('returns null for a folder that does not exist', () async {
    expect(
      await source.readHead(folderPath: '${dir.path}/nope'),
      isNull,
    );
  });
}
