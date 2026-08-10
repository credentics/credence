import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_manifest_dto.dart';

class VaultSyncRemoteBundleDto {
  const VaultSyncRemoteBundleDto({
    required this.manifest,
    required this.encryptedPayload,
  });

  final VaultSyncManifestDto manifest;
  final List<int> encryptedPayload;
}
