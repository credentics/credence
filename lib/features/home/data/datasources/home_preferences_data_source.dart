import 'dart:convert';

import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_preferences_entity.dart';

class HomePreferencesDataSource {
  HomePreferencesDataSource._({required dynamic box}) : _box = box;

  static const _boxName = 'credence_home_prefs_v1';
  static const _prefsKey = 'home_preferences';
  static const _dismissedKey = 'dismissed_reminders';

  final dynamic _box;

  static Future<HomePreferencesDataSource> create() async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(_boxName);
    return HomePreferencesDataSource._(box: box);
  }

  Future<HomePreferencesEntity> getPreferences() async {
    final raw = _box.get(_prefsKey) as String?;
    if (raw == null) return HomePreferencesEntity.defaults;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _fromMap(map);
    } catch (_) {
      return HomePreferencesEntity.defaults;
    }
  }

  Future<void> savePreferences(HomePreferencesEntity prefs) async {
    await _box.put(_prefsKey, jsonEncode(_toMap(prefs)));
  }

  Future<Set<String>> getDismissedReminderIds() async {
    final raw = _box.get(_dismissedKey);
    if (raw is List) {
      return Set<String>.from(raw.whereType<String>());
    }
    return <String>{};
  }

  Future<void> dismissReminder(String reminderId) async {
    final current = await getDismissedReminderIds();
    current.add(reminderId);
    await _box.put(_dismissedKey, current.toList(growable: false));
  }

  Map<String, dynamic> _toMap(HomePreferencesEntity prefs) => {
    'visible_sections': prefs.visibleSections,
    'section_order': prefs.sectionOrder,
    'quick_access_categories': prefs.quickAccessCategories,
    'visible_categories': prefs.visibleCategories,
    'pinned_item_ids': prefs.pinnedItemIds,
    'smart_rules': prefs.smartRules,
    'card_size': prefs.cardSize.name,
    'layout_style': prefs.layoutStyle.name,
    'show_previews': prefs.showPreviews,
  };

  HomePreferencesEntity _fromMap(Map<String, dynamic> map) {
    return HomePreferencesEntity(
      visibleSections: _castBoolMap(map['visible_sections']),
      sectionOrder: _castStringList(map['section_order']),
      quickAccessCategories: _castStringList(map['quick_access_categories']),
      visibleCategories: _castBoolMap(map['visible_categories'],
          fallback: HomePreferencesEntity.defaults.visibleCategories),
      pinnedItemIds: _castStringList(map['pinned_item_ids']),
      smartRules: _castBoolMap(map['smart_rules']),
      cardSize: CardSize.values.firstWhere(
        (e) => e.name == map['card_size'],
        orElse: () => CardSize.comfortable,
      ),
      layoutStyle: LayoutStyle.values.firstWhere(
        (e) => e.name == map['layout_style'],
        orElse: () => LayoutStyle.horizontal,
      ),
      showPreviews: map['show_previews'] as bool? ?? true,
    );
  }

  Map<String, bool> _castBoolMap(dynamic raw, {Map<String, bool>? fallback}) {
    if (raw is Map) {
      return Map<String, bool>.from(
        raw.map((k, v) => MapEntry(k.toString(), v == true)),
      );
    }
    return fallback ?? HomePreferencesEntity.defaults.visibleSections;
  }

  List<String> _castStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }
}
