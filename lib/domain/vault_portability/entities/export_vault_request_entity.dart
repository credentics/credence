import 'package:pass_doc_manager/domain/vault_portability/entities/portable_data_scope.dart';

class ExportVaultRequestEntity {
  const ExportVaultRequestEntity({
    required this.scope,
    required this.passphrase,
    this.categoryKeys = const <String>[],
    this.collectionIds = const <String>[],
    this.includeCredentials = true,
    this.includeCollections = true,
  });

  final PortableDataScope scope;
  final String passphrase;
  final List<String> categoryKeys;
  final List<String> collectionIds;
  final bool includeCredentials;
  final bool includeCollections;
}
