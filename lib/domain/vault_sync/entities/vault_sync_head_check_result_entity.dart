import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_head_entity.dart';

class VaultSyncHeadCheckResultEntity {
  const VaultSyncHeadCheckResultEntity({
    required this.success,
    required this.remoteAvailable,
    required this.message,
    this.remoteHead,
    this.providerName,
    this.usedManifestFallback = false,
    this.bytesRead = 0,
    this.elapsedMilliseconds = 0,
  });

  final bool success;
  final bool remoteAvailable;
  final String message;
  final VaultSyncHeadEntity? remoteHead;
  final String? providerName;
  final bool usedManifestFallback;
  final int bytesRead;
  final int elapsedMilliseconds;
}
