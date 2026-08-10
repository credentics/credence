import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';

enum BundleDetailStatus { initial, loading, ready, error }

class BundleDetailState {
  const BundleDetailState({
    required this.status,
    required this.bundle,
    required this.errorMessage,
  });

  const BundleDetailState.initial()
    : status = BundleDetailStatus.initial,
      bundle = null,
      errorMessage = null;

  final BundleDetailStatus status;
  final BundleEntity? bundle;
  final String? errorMessage;

  BundleDetailState copyWith({
    BundleDetailStatus? status,
    BundleEntity? bundle,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BundleDetailState(
      status: status ?? this.status,
      bundle: bundle ?? this.bundle,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
