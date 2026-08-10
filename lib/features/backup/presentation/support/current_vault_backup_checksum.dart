import 'dart:math' as math;

import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace_builder.dart';

Future<String?> currentVaultBackupChecksum(VaultSyncPrefsDto prefs) async {
  final deviceId = prefs.deviceId.trim().isEmpty
      ? 'device_${DateTime.now().microsecondsSinceEpoch}'
      : prefs.deviceId.trim();
  final revision = math.max(1, prefs.lastObservedRemoteRevision + 1);
  final workspace = await getIt<VaultMirrorWorkspaceBuilder>().build(
    deviceId: deviceId,
    revision: revision,
  );
  final checksum = workspace.contentChecksum.trim();
  return checksum.isEmpty ? null : checksum;
}
