import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_preferences_entity.dart';
import 'package:pass_doc_manager/features/home/domain/repositories/home_repository.dart';
import 'package:pass_doc_manager/features/home/presentation/cubit/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required HomeRepository repository})
      : _repository = repository,
        super(const HomeState.initial());

  final HomeRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final results = await Future.wait([
        _repository.getDashboard(),
        _repository.getPreferences(),
      ]);
      emit(state.copyWith(
        status: HomeStatus.loaded,
        dashboard: results[0] as dynamic,
        preferences: results[1] as HomePreferencesEntity,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> dismissReminder(String reminderId) async {
    await _repository.dismissReminder(reminderId);
    await load();
  }

  Future<void> savePreferences(HomePreferencesEntity preferences) async {
    await _repository.savePreferences(preferences);
    await load();
  }

  Future<void> toggleSection(String sectionKey) async {
    final prefs = state.preferences ?? HomePreferencesEntity.defaults;
    final updated = Map<String, bool>.from(prefs.visibleSections);
    updated[sectionKey] = !(updated[sectionKey] ?? true);
    await savePreferences(prefs.copyWith(visibleSections: updated));
  }

  Future<void> updateSectionOrder(List<String> order) async {
    final prefs = state.preferences ?? HomePreferencesEntity.defaults;
    await savePreferences(prefs.copyWith(sectionOrder: order));
  }

  Future<void> updateCardSize(CardSize size) async {
    final prefs = state.preferences ?? HomePreferencesEntity.defaults;
    await savePreferences(prefs.copyWith(cardSize: size));
  }

  Future<void> updateLayoutStyle(LayoutStyle style) async {
    final prefs = state.preferences ?? HomePreferencesEntity.defaults;
    await savePreferences(prefs.copyWith(layoutStyle: style));
  }

  Future<void> toggleSmartRule(String ruleKey) async {
    final prefs = state.preferences ?? HomePreferencesEntity.defaults;
    final updated = Map<String, bool>.from(prefs.smartRules);
    updated[ruleKey] = !(updated[ruleKey] ?? true);
    await savePreferences(prefs.copyWith(smartRules: updated));
  }

  Future<void> toggleCategory(String categoryKey) async {
    final prefs = state.preferences ?? HomePreferencesEntity.defaults;
    final updated = Map<String, bool>.from(prefs.visibleCategories);
    updated[categoryKey] = !(updated[categoryKey] ?? true);
    await savePreferences(prefs.copyWith(visibleCategories: updated));
  }
}
