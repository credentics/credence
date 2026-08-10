import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/domain/profile/usecases/get_profile_dashboard.dart';
import 'package:pass_doc_manager/features/profile/presentation/cubit/profile_dashboard_state.dart';

class ProfileDashboardCubit extends Cubit<ProfileDashboardState> {
  ProfileDashboardCubit({required GetProfileDashboard getProfileDashboard})
    : _getProfileDashboard = getProfileDashboard,
      super(const ProfileDashboardState.initial());

  final GetProfileDashboard _getProfileDashboard;

  Future<void> load() async {
    emit(
      state.copyWith(status: ProfileDashboardStatus.loading, clearError: true),
    );

    try {
      final dashboard = await _getProfileDashboard(
        const GetProfileDashboardParams(),
      );
      emit(
        state.copyWith(
          status: ProfileDashboardStatus.ready,
          profile: dashboard.profile,
          activities: dashboard.activities,
          clearError: true,
        ),
      );
    } catch (_) {
      debugPrint('[ProfileDashboard] Failed to load profile');
      emit(
        state.copyWith(
          status: ProfileDashboardStatus.error,
          errorMessage: null, // UI uses l10n.profileErrorLoad
        ),
      );
    }
  }
}
