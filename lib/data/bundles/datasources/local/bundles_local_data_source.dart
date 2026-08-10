import 'package:hive/hive.dart';
import 'package:pass_doc_manager/data/bundles/dtos/bundle_record_dto.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';

class BundlesLocalDataSource {
  BundlesLocalDataSource._({required Box<dynamic> box}) : _box = box;

  static const _boxName = 'credence_bundles_v1';
  static const _stateKey = 'bundles_state';

  final Box<dynamic> _box;

  static Future<BundlesLocalDataSource> create() async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(_boxName);
    return BundlesLocalDataSource._(box: box);
  }

  Future<List<BundleRecordDto>> getBundles() async {
    final normalized = _normalizeState(_box.get(_stateKey));
    final List<dynamic> rawList = normalized['items'] as List<dynamic>;
    return rawList
        .whereType<Map>()
        .map(
          (map) => BundleRecordDto.fromMap(Map<String, dynamic>.from(map)),
        )
        .where((dto) => dto.id.trim().isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAtIso.compareTo(a.updatedAtIso));
  }

  Future<void> saveBundles(List<BundleRecordDto> bundles) async {
    await _box.put(_stateKey, {
      'items': bundles.map((item) => item.toMap()).toList(growable: false),
    });
  }

  final Set<String> _generatedBundleIds = {};

  String nextBundleId() {
    final existing = _existingBundleIds()..addAll(_generatedBundleIds);
    var idx = existing.length + 1;
    var candidate = 'bundle_$idx';
    while (existing.contains(candidate)) {
      idx += 1;
      candidate = 'bundle_$idx';
    }
    _generatedBundleIds.add(candidate);
    return candidate;
  }

  final Set<String> _generatedItemIds = {};

  String nextItemId() {
    final existing = _existingItemIds()..addAll(_generatedItemIds);
    var idx = existing.length + 1;
    var candidate = 'bundle_item_$idx';
    while (existing.contains(candidate)) {
      idx += 1;
      candidate = 'bundle_item_$idx';
    }
    _generatedItemIds.add(candidate);
    return candidate;
  }

  final Set<String> _generatedEventIds = {};

  String nextEventId() {
    final existing = _existingEventIds()..addAll(_generatedEventIds);
    var idx = existing.length + 1;
    var candidate = 'bundle_event_$idx';
    while (existing.contains(candidate)) {
      idx += 1;
      candidate = 'bundle_event_$idx';
    }
    _generatedEventIds.add(candidate);
    return candidate;
  }

  Set<String> _existingBundleIds() {
    final normalized = _normalizeState(_box.get(_stateKey));
    final List<dynamic> rawList = normalized['items'] as List<dynamic>;
    return rawList
        .whereType<Map>()
        .map((map) => '${map['id']}'.trim())
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
        .toSet();
  }

  Set<String> _existingItemIds() {
    final normalized = _normalizeState(_box.get(_stateKey));
    final List<dynamic> rawBundles = normalized['items'] as List<dynamic>;
    final ids = <String>{};
    for (final rawBundle in rawBundles.whereType<Map>()) {
      final itemsRaw = rawBundle['items'];
      if (itemsRaw is! List) continue;
      for (final rawItem in itemsRaw.whereType<Map>()) {
        final id = '${rawItem['id']}'.trim();
        if (id.isEmpty || id.toLowerCase() == 'null') continue;
        ids.add(id);
      }
    }
    return ids;
  }

  Set<String> _existingEventIds() {
    final normalized = _normalizeState(_box.get(_stateKey));
    final List<dynamic> rawBundles = normalized['items'] as List<dynamic>;
    final ids = <String>{};
    for (final rawBundle in rawBundles.whereType<Map>()) {
      final eventsRaw = rawBundle['history'];
      if (eventsRaw is! List) continue;
      for (final rawEvent in eventsRaw.whereType<Map>()) {
        final id = '${rawEvent['id']}'.trim();
        if (id.isEmpty || id.toLowerCase() == 'null') continue;
        ids.add(id);
      }
    }
    return ids;
  }

  Map<String, dynamic> _normalizeState(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final items = raw['items'];
      return {'items': items is List ? items : <dynamic>[]};
    }
    if (raw is Map) {
      final casted = Map<String, dynamic>.from(raw);
      final items = casted['items'];
      return {'items': items is List ? items : <dynamic>[]};
    }
    return {'items': <dynamic>[]};
  }
}
