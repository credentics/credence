import 'package:pass_doc_manager/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_preferences_entity.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState {
  const HomeState({
    this.status = HomeStatus.initial,
    this.dashboard,
    this.preferences,
    this.errorMessage,
  });

  const HomeState.initial() : this();

  final HomeStatus status;
  final HomeDashboardEntity? dashboard;
  final HomePreferencesEntity? preferences;
  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    HomeDashboardEntity? dashboard,
    HomePreferencesEntity? preferences,
    String? errorMessage,
  }) =>
      HomeState(
        status: status ?? this.status,
        dashboard: dashboard ?? this.dashboard,
        preferences: preferences ?? this.preferences,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
