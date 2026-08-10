import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_expiring_documents.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/document_timeline_state.dart';

class DocumentTimelineCubit extends Cubit<DocumentTimelineState> {
  DocumentTimelineCubit({GetExpiringDocuments? getExpiringDocuments})
    : _getExpiringDocuments =
          getExpiringDocuments ?? getIt(),
      super(const DocumentTimelineState.initial());

  final GetExpiringDocuments _getExpiringDocuments;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: DocumentTimelineStatus.loading,
        clearError: true,
      ),
    );

    try {
      final documents = await _getExpiringDocuments(
        const GetExpiringDocumentsParams(monthsAhead: 12),
      );
      emit(
        state.copyWith(
          status: DocumentTimelineStatus.loaded,
          documents: documents,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      dev.log(
        'DocumentTimelineCubit.load() failed',
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint('[DocumentTimeline] Failed to load expiring documents');
      emit(
        state.copyWith(
          status: DocumentTimelineStatus.error,
          errorMessage: null,
        ),
      );
    }
  }

  Future<void> selectFilter(ExpiryFilter filter) async {
    emit(state.copyWith(selectedFilter: filter));
  }
}

enum ExpiryFilter { all, expired, critical, warning, safe }
