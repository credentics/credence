import 'package:pass_doc_manager/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_preferences_entity.dart';

abstract class HomeRepository {
  Future<HomeDashboardEntity> getDashboard();
  Future<HomePreferencesEntity> getPreferences();
  Future<void> savePreferences(HomePreferencesEntity preferences);
  Future<void> dismissReminder(String reminderId);
}
