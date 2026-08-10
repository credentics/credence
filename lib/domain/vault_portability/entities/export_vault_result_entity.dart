import 'package:pass_doc_manager/domain/vault_portability/entities/portable_data_scope.dart';

class ExportVaultResultEntity {
  const ExportVaultResultEntity({
    required this.bundleId,
    required this.exportedAtIso,
    required this.scope,
    required this.documentCount,
    required this.passwordCount,
    required this.encryptedPayload,
  });

  final String bundleId;
  final String exportedAtIso;
  final PortableDataScope scope;
  final int documentCount;
  final int passwordCount;
  final List<int> encryptedPayload;
}
