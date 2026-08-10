import 'package:pass_doc_manager/domain/vault_import/entities/import_credential_entity.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_source.dart';

enum VaultImportStatus {
  initial,
  sourceSelected,
  filePicked,
  parsing,
  previewing,
  importing,
  complete,
  error,
}

class VaultImportState {
  const VaultImportState({
    required this.status,
    required this.source,
    required this.parsedItems,
    required this.importResult,
    required this.errorMessage,
  });

  const VaultImportState.initial()
    : status = VaultImportStatus.initial,
      source = null,
      parsedItems = const [],
      importResult = null,
      errorMessage = null;

  final VaultImportStatus status;
  final ImportSource? source;
  final List<ImportCredentialEntity> parsedItems;
  final ImportResultEntity? importResult;
  final String? errorMessage;

  VaultImportState copyWith({
    VaultImportStatus? status,
    ImportSource? source,
    List<ImportCredentialEntity>? parsedItems,
    ImportResultEntity? importResult,
    String? errorMessage,
  }) {
    return VaultImportState(
      status: status ?? this.status,
      source: source ?? this.source,
      parsedItems: parsedItems ?? this.parsedItems,
      importResult: importResult ?? this.importResult,
      errorMessage: errorMessage,
    );
  }

  int get selectedCount => parsedItems.where((c) => c.isSelected).length;

  int get duplicateCount => parsedItems.where((c) => c.isDuplicate).length;

  bool get canImport => selectedCount > 0;
}
