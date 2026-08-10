import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';

/// The mirror's hidden metadata directory is `.credence`, and the classifiers
/// that decide what a restore surfaces (reserved metadata vs. user-visible
/// content/assets) key off it. This pins that contract.
void main() {
  group('metadata dir constants', () {
    test('the metadata dir is .credence', () {
      expect(VaultMirrorWorkspace.metadataDir, '.credence');
      expect(VaultMirrorWorkspace.manifestPath, '.credence/manifest.json');
      expect(VaultMirrorWorkspace.headPath, '.credence/head.json');
      expect(VaultMirrorWorkspace.snapshotPath, '.credence/snapshot.json');
      expect(VaultMirrorWorkspace.syncDir, '.credence/sync');
    });
  });

  group('isReservedMetadataFile', () {
    test('is true for manifest/head/snapshot', () {
      for (final path in const [
        '.credence/manifest.json',
        '.credence/head.json',
        '.credence/snapshot.json',
      ]) {
        expect(
          VaultMirrorWorkspace.isReservedMetadataFile(path),
          isTrue,
          reason: path,
        );
      }
    });

    test('is false for assets and user content', () {
      for (final path in const [
        '.credence/assets/collections/a/icon.png',
        'Documents/Identity/passport.pdf',
        'Collections/Trip/photo.jpg',
      ]) {
        expect(
          VaultMirrorWorkspace.isReservedMetadataFile(path),
          isFalse,
          reason: path,
        );
      }
    });
  });

  group('isInternalMetadataPath / isUserVisibleMirrorPath', () {
    test('metadata files and the sync tree are internal', () {
      for (final path in const [
        '.credence/manifest.json',
        '.credence/sync/head.json',
        '.credence/snapshot.json',
      ]) {
        expect(
          VaultMirrorWorkspace.isInternalMetadataPath(path),
          isTrue,
          reason: path,
        );
        expect(VaultMirrorWorkspace.isUserVisibleMirrorPath(path), isFalse);
      }
    });

    test('assets and content are user-visible', () {
      for (final path in const [
        '.credence/assets/collections/a/icon.png',
        'Documents/Work/acme/payslip.pdf',
        'Profile/photo.jpg',
      ]) {
        expect(
          VaultMirrorWorkspace.isUserVisibleMirrorPath(path),
          isTrue,
          reason: path,
        );
      }
    });
  });
}
