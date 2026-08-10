import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_credential_entity.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_source.dart';
import 'package:pass_doc_manager/domain/vault_import/usecases/execute_import.dart';
import 'package:pass_doc_manager/domain/vault_import/usecases/parse_import_file.dart';
import 'package:pass_doc_manager/features/vault_import/presentation/cubit/vault_import_state.dart';

class VaultImportCubit extends Cubit<VaultImportState> {
  VaultImportCubit({
    ParseImportFile? parseImportFile,
    ExecuteImport? executeImport,
  })  : _parseImportFile = parseImportFile ?? ParseImportFile(),
        _executeImport =
            executeImport ?? ExecuteImport(getIt<CredentialLocalDataSource>()),
        super(const VaultImportState.initial());

  final ParseImportFile _parseImportFile;
  final ExecuteImport _executeImport;

  void selectSource(ImportSource source) {
    emit(
      state.copyWith(
        status: VaultImportStatus.sourceSelected,
        source: source,
      ),
    );
  }

  Future<void> parseFile({
    required String fileContent,
  }) async {
    emit(state.copyWith(status: VaultImportStatus.parsing));

    try {
      final parsed = _parseImportFile(
        source: state.source!,
        fileContent: fileContent,
      );

      if (parsed.isEmpty) {
        emit(
          state.copyWith(
            status: VaultImportStatus.error,
            errorMessage: 'No credentials found in file',
          ),
        );
        return;
      }

      // Detect duplicates by checking existing credentials
      final detectedDuplicates = await _detectDuplicates(parsed);

      emit(
        state.copyWith(
          status: VaultImportStatus.previewing,
          parsedItems: detectedDuplicates,
        ),
      );
    } catch (e) {
      debugPrint('[VaultImport] Failed to parse file: $e');
      emit(
        state.copyWith(
          status: VaultImportStatus.error,
          errorMessage: 'Failed to parse file. Invalid format.',
        ),
      );
    }
  }

  void toggleItemSelection(int index) {
    if (index < 0 || index >= state.parsedItems.length) {
      return;
    }

    final updated = List<ImportCredentialEntity>.from(state.parsedItems);
    final item = updated[index];
    updated[index] = item.copyWith(isSelected: !item.isSelected);

    emit(state.copyWith(parsedItems: updated));
  }

  void selectAll() {
    final updated = state.parsedItems
        .map((item) => item.copyWith(isSelected: true))
        .toList(growable: false);

    emit(state.copyWith(parsedItems: updated));
  }

  void deselectAll() {
    final updated = state.parsedItems
        .map((item) => item.copyWith(isSelected: false))
        .toList(growable: false);
    emit(state.copyWith(parsedItems: updated));
  }

  void deselectDuplicates() {
    final updated = state.parsedItems
        .map((item) {
          if (item.isDuplicate) {
            return item.copyWith(isSelected: false);
          }
          return item;
        })
        .toList(growable: false);

    emit(state.copyWith(parsedItems: updated));
  }

  Future<void> executeImport() async {
    emit(state.copyWith(status: VaultImportStatus.importing));

    try {
      final result = await _executeImport(
        credentials: state.parsedItems,
      );

      emit(
        state.copyWith(
          status: VaultImportStatus.complete,
          importResult: result,
        ),
      );
    } catch (e) {
      debugPrint('[VaultImport] Failed to execute import: $e');
      emit(
        state.copyWith(
          status: VaultImportStatus.error,
          errorMessage: 'Failed to import credentials. Please try again.',
        ),
      );
    }
  }

  void reset() {
    emit(const VaultImportState.initial());
  }

  Future<List<ImportCredentialEntity>> _detectDuplicates(
    List<ImportCredentialEntity> parsed,
  ) async {
    try {
      final dataSource = getIt<CredentialLocalDataSource>();
      final existing = await dataSource.getCredentialSummaries();

      return parsed
          .map((credential) {
            final isDuplicate = existing.any(
              (e) =>
                  e.displayName.toLowerCase() ==
                      credential.serviceName.toLowerCase() &&
                  e.username.toLowerCase() == credential.username.toLowerCase(),
            );

            return credential.copyWith(
              isDuplicate: isDuplicate,
              isSelected: false, // All deselected by default
            );
          })
          .toList(growable: false);
    } catch (e) {
      // If duplicate detection fails, return items without marking duplicates
      return parsed;
    }
  }
}
