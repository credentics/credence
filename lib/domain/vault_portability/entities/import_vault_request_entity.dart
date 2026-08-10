import 'package:pass_doc_manager/domain/vault_portability/entities/import_merge_strategy.dart';

class ImportVaultRequestEntity {
  const ImportVaultRequestEntity({
    required this.encryptedPayload,
    required this.passphrase,
    required this.strategy,
  });

  final List<int> encryptedPayload;
  final String passphrase;
  final ImportMergeStrategy strategy;
}
