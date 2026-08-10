import 'package:pass_doc_manager/domain/documents/entities/property_detail_entity.dart';

enum PropertyDetailViewStatus { initial, loading, ready, error }

class PropertyDetailState {
  const PropertyDetailState({
    required this.viewStatus,
    required this.detail,
    required this.errorMessage,
  });

  const PropertyDetailState.initial()
    : viewStatus = PropertyDetailViewStatus.initial,
      detail = null,
      errorMessage = null;

  final PropertyDetailViewStatus viewStatus;
  final PropertyDetailEntity? detail;
  final String? errorMessage;

  PropertyDetailState copyWith({
    PropertyDetailViewStatus? viewStatus,
    PropertyDetailEntity? detail,
    bool clearDetail = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PropertyDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      detail: clearDetail ? null : (detail ?? this.detail),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
