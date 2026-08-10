import 'package:pass_doc_manager/domain/vault_portability/entities/portable_data_scope.dart';

typedef ExportVaultWithFilesProgressCallback =
    void Function(String message, double? progress);

class ExportVaultWithFilesRequestEntity {
  const ExportVaultWithFilesRequestEntity({
    required this.scope,
    required this.passphrase,
    this.onProgress,
    this.categoryKeys = const <String>[],
    this.collectionIds = const <String>[],
    this.includeCredentials = true,
    this.includeCollections = true,
  });

  final PortableDataScope scope;
  final String passphrase;
  final ExportVaultWithFilesProgressCallback? onProgress;
  final List<String> categoryKeys;
  final List<String> collectionIds;
  final bool includeCredentials;
  final bool includeCollections;
}
