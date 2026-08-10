import 'package:pass_doc_manager/domain/credentials/entities/credential_detail_entity.dart';

enum CredentialDetailStatus { initial, loading, loaded, error }

class CredentialDetailState {
  const CredentialDetailState({
    required this.status,
    required this.detail,
    required this.errorMessage,
  });

  const CredentialDetailState.initial()
    : status = CredentialDetailStatus.initial,
      detail = null,
      errorMessage = null;

  final CredentialDetailStatus status;
  final CredentialDetailEntity? detail;
  final String? errorMessage;

  CredentialDetailState copyWith({
    CredentialDetailStatus? status,
    CredentialDetailEntity? detail,
    String? errorMessage,
  }) {
    return CredentialDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      errorMessage: errorMessage,
    );
  }
}
