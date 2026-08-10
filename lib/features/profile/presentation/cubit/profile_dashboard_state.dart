import 'package:pass_doc_manager/domain/profile/entities/profile_activity_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_entity.dart';

enum ProfileDashboardStatus { initial, loading, ready, error }

class ProfileDashboardState {
  const ProfileDashboardState({
    required this.status,
    required this.profile,
    required this.activities,
    required this.errorMessage,
  });

  const ProfileDashboardState.initial()
    : status = ProfileDashboardStatus.initial,
      profile = null,
      activities = const <ProfileActivityEntity>[],
      errorMessage = null;

  final ProfileDashboardStatus status;
  final ProfileEntity? profile;
  final List<ProfileActivityEntity> activities;
  final String? errorMessage;

  ProfileDashboardState copyWith({
    ProfileDashboardStatus? status,
    ProfileEntity? profile,
    List<ProfileActivityEntity>? activities,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileDashboardState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      activities: activities ?? this.activities,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
