import 'package:pass_doc_manager/domain/profile/entities/generated_profile_share_link_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_share_options_entity.dart';

enum ProfileShareStatus { initial, loading, ready, saving, error }

class ProfileShareState {
  const ProfileShareState({
    required this.status,
    required this.options,
    required this.generatedLink,
    required this.errorMessage,
  });

  const ProfileShareState.initial()
    : status = ProfileShareStatus.initial,
      options = ProfileShareOptionsEntity.defaults,
      generatedLink = null,
      errorMessage = null;

  final ProfileShareStatus status;
  final ProfileShareOptionsEntity options;
  final GeneratedProfileShareLinkEntity? generatedLink;
  final String? errorMessage;

  bool get isBusy =>
      status == ProfileShareStatus.loading ||
      status == ProfileShareStatus.saving;

  ProfileShareState copyWith({
    ProfileShareStatus? status,
    ProfileShareOptionsEntity? options,
    GeneratedProfileShareLinkEntity? generatedLink,
    String? errorMessage,
    bool clearGeneratedLink = false,
    bool clearError = false,
  }) {
    return ProfileShareState(
      status: status ?? this.status,
      options: options ?? this.options,
      generatedLink: clearGeneratedLink
          ? null
          : (generatedLink ?? this.generatedLink),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
