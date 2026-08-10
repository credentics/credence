import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_expiring_documents.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_document_library_overview.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/document_library_state.dart';

class DocumentLibraryCubit extends Cubit<DocumentLibraryState> {
  DocumentLibraryCubit({
    GetDocumentLibraryOverview? getOverview,
    GetExpiringDocuments? getExpiringDocuments,
  }) : _getOverview = getOverview ?? getIt(),
       _getExpiringDocuments =
           getExpiringDocuments ??
           (getIt.isRegistered<GetExpiringDocuments>()
               ? getIt<GetExpiringDocuments>()
               : null),
       super(const DocumentLibraryState.initial());

  final GetDocumentLibraryOverview _getOverview;
  final GetExpiringDocuments? _getExpiringDocuments;

  Future<void> load() async {
    emit(
      state.copyWith(
        viewStatus: DocumentLibraryViewStatus.loading,
        clearError: true,
      ),
    );

    try {
      final overview = await _getOverview(
        const GetDocumentLibraryOverviewParams(),
      );
      final expiringDocuments =
          await _getExpiringDocuments?.call(
            const GetExpiringDocumentsParams(monthsAhead: 12),
          ) ??
          const <Never>[];
      emit(
        state.copyWith(
          viewStatus: DocumentLibraryViewStatus.ready,
          overview: overview,
          expiringDocuments: expiringDocuments,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      dev.log(
        'DocumentLibraryCubit.load() failed',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('[DocumentLibrary] Failed to load documents');
      emit(
        state.copyWith(
          viewStatus: DocumentLibraryViewStatus.error,
          errorMessage: null, // UI uses l10n.documentsErrorLoad
        ),
      );
    }
  }
}
