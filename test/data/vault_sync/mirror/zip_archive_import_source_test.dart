import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_source.dart';

/// The zip-backed source lets a Credence-Vault-*.zip export restore through the
/// same VaultMirrorImportService as the cloud mirror. It must read entries by
/// their mirror-relative path and fail loudly when one is missing (so a
/// truncated archive can't be silently half-restored).
void main() {
  Archive archiveWith(Map<String, List<int>> entries) {
    final archive = Archive();
    entries.forEach((name, bytes) {
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    return archive;
  }

  test('reads a text entry (manifest) by its mirror-relative path', () async {
    final source = ZipArchiveVaultMirrorImportSource(
      archiveWith({
        '.credence/manifest.json': utf8.encode('{"revision":3}'),
      }),
    );
    expect(
      await source.readText('.credence/manifest.json'),
      '{"revision":3}',
    );
  });

  test('streams a binary asset entry', () async {
    final source = ZipArchiveVaultMirrorImportSource(
      archiveWith({
        '.credence/assets/collections/a/icon.png': [1, 2, 3, 4],
      }),
    );
    final bytes = <int>[];
    await for (final chunk in source.openRead(
      '.credence/assets/collections/a/icon.png',
    )) {
      bytes.addAll(chunk);
    }
    expect(bytes, [1, 2, 3, 4]);
  });

  test('normalizes backslashes to forward slashes', () async {
    final source = ZipArchiveVaultMirrorImportSource(
      archiveWith({'.credence/snapshot.json': utf8.encode('{}')}),
    );
    expect(await source.readText(r'.credence\snapshot.json'), '{}');
  });

  test('throws for a missing entry rather than returning empty', () {
    final source = ZipArchiveVaultMirrorImportSource(archiveWith({}));
    expect(
      () => source.openRead('.credence/manifest.json'),
      throwsA(isA<StateError>()),
    );
    expectLater(
      source.readText('.credence/manifest.json'),
      throwsA(isA<StateError>()),
    );
  });
}
