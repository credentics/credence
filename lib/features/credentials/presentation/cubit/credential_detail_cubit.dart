import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/credentials/usecases/get_credential_detail.dart';
import 'package:pass_doc_manager/features/credentials/presentation/cubit/credential_detail_state.dart';

class CredentialDetailCubit extends Cubit<CredentialDetailState> {
  CredentialDetailCubit({GetCredentialDetail? getCredentialDetail})
    : _getCredentialDetail = getCredentialDetail ?? getIt(),
      super(const CredentialDetailState.initial());

  final GetCredentialDetail _getCredentialDetail;

  Future<void> load({required String credentialId}) async {
    emit(state.copyWith(status: CredentialDetailStatus.loading));

    try {
      final detail = await _getCredentialDetail(credentialId: credentialId);
      emit(
        state.copyWith(
          status: CredentialDetailStatus.loaded,
          detail: detail,
          errorMessage: null,
        ),
      );
    } catch (_) {
      debugPrint('[CredentialDetail] Failed to load credential details');
      emit(
        state.copyWith(
          status: CredentialDetailStatus.error,
          errorMessage: null, // UI uses l10n.credentialsErrorDetail
        ),
      );
    }
  }
}
