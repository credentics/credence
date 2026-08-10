import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/documents/usecases/archive_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/delete_document.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_identity_documents.dart';
import 'package:pass_doc_manager/domain/documents/usecases/set_primary_identity_document.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/identity_documents_state.dart';

class IdentityDocumentsCubit extends Cubit<IdentityDocumentsState> {
  IdentityDocumentsCubit({
    GetIdentityDocuments? getIdentityDocuments,
    DeleteDocument? deleteDocument,
    ArchiveDocument? archiveDocument,
    SetPrimaryIdentityDocument? setPrimaryIdentityDocument,
  }) : _getIdentityDocuments = getIdentityDocuments ?? getIt(),
       _deleteDocument = deleteDocument ?? getIt(),
       _archiveDocument = archiveDocument ?? getIt(),
       _setPrimaryIdentityDocument = setPrimaryIdentityDocument ?? getIt(),
       super(const IdentityDocumentsState.initial());

  final GetIdentityDocuments _getIdentityDocuments;
  final DeleteDocument _deleteDocument;
  final ArchiveDocument _archiveDocument;
  final SetPrimaryIdentityDocument _setPrimaryIdentityDocument;

  Future<void> load() async {
    emit(
      state.copyWith(
        viewStatus: IdentityDocumentsViewStatus.loading,
        clearError: true,
      ),
    );

    try {
      final items = await _getIdentityDocuments(
        const GetIdentityDocumentsParams(),
      );
      emit(
        state.copyWith(
          viewStatus: IdentityDocumentsViewStatus.ready,
          items: items,
          clearError: true,
        ),
      );
    } catch (_) {
      debugPrint('[IdentityDocuments] Failed to load secure IDs');
      emit(
        state.copyWith(
          viewStatus: IdentityDocumentsViewStatus.error,
          errorMessage: null, // UI uses l10n.documentsErrorSecureIds
        ),
      );
    }
  }

  void setFilter(IdentityDocumentsFilter filter) {
    if (filter == state.filter) {
      return;
    }
    emit(state.copyWith(filter: filter));
  }

  Future<bool> deleteById(String documentId) async {
    try {
      await _deleteDocument(DeleteDocumentParams(documentId: documentId));
      _removeItemFromState(documentId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> archiveById(String documentId) async {
    try {
      await _archiveDocument(ArchiveDocumentParams(documentId: documentId));
      _removeItemFromState(documentId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setPrimaryById(String documentId) async {
    try {
      await _setPrimaryIdentityDocument(
        SetPrimaryIdentityDocumentParams(documentId: documentId),
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _removeItemFromState(String documentId) {
    final nextItems = state.items
        .where((item) => item.id != documentId)
        .toList(growable: false);
    emit(state.copyWith(items: nextItems));
  }
}
