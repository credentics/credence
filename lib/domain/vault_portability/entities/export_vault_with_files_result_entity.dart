import 'package:pass_doc_manager/domain/vault_portability/entities/portable_data_scope.dart';

class ExportVaultWithFilesResultEntity {
  const ExportVaultWithFilesResultEntity({
    required this.bundleId,
    required this.exportedAtIso,
    required this.scope,
    required this.documentCount,
    required this.passwordCount,
    required this.fileCount,
    required this.archiveFileName,
    required this.archiveFilePath,
  });

  final String bundleId;
  final String exportedAtIso;
  final PortableDataScope scope;
  final int documentCount;
  final int passwordCount;
  final int fileCount;
  final String archiveFileName;
  final String archiveFilePath;
}
