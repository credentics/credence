import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';

enum BundlesListStatus { initial, loading, ready, error }

class BundlesListState {
  const BundlesListState({
    required this.status,
    required this.bundles,
    required this.errorMessage,
  });

  const BundlesListState.initial()
    : status = BundlesListStatus.initial,
      bundles = const <BundleEntity>[],
      errorMessage = null;

  final BundlesListStatus status;
  final List<BundleEntity> bundles;
  final String? errorMessage;

  BundlesListState copyWith({
    BundlesListStatus? status,
    List<BundleEntity>? bundles,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BundlesListState(
      status: status ?? this.status,
      bundles: bundles ?? this.bundles,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
