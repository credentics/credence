import 'package:pass_doc_manager/domain/bundles/entities/bundle_event.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_status.dart';

/// A curated, purpose-built collection of vault items (e.g. a visa packet,
/// a rental application). Items are stored as references while the bundle
/// is being edited; on export the referenced content is snapshotted into
/// an archive that no longer depends on the live vault.
class BundleEntity {
  const BundleEntity({
    required this.id,
    required this.title,
    required this.purpose,
    required this.description,
    required this.templateKey,
    required this.status,
    required this.items,
    required this.history,
    required this.createdAt,
    required this.updatedAt,
    required this.lastExportedAt,
    required this.lastExportPath,
  });

  final String id;
  final String title;
  final String? purpose;
  final String? description;
  final String? templateKey;
  final BundleStatus status;
  final List<BundleItemRef> items;
  final List<BundleEvent> history;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastExportedAt;
  final String? lastExportPath;

  int get itemCount => items.length;

  bool get isEmpty => items.isEmpty;

  int countByType(BundleItemType type) {
    return items.where((item) => item.type == type).length;
  }

  bool containsRef({required BundleItemType type, required String refId}) {
    for (final item in items) {
      if (item.type == type && item.refId == refId) {
        return true;
      }
    }
    return false;
  }

  BundleEntity copyWith({
    String? id,
    String? title,
    String? purpose,
    bool clearPurpose = false,
    String? description,
    bool clearDescription = false,
    String? templateKey,
    bool clearTemplateKey = false,
    BundleStatus? status,
    List<BundleItemRef>? items,
    List<BundleEvent>? history,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastExportedAt,
    bool clearLastExportedAt = false,
    String? lastExportPath,
    bool clearLastExportPath = false,
  }) {
    return BundleEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      purpose: clearPurpose ? null : (purpose ?? this.purpose),
      description: clearDescription ? null : (description ?? this.description),
      templateKey: clearTemplateKey ? null : (templateKey ?? this.templateKey),
      status: status ?? this.status,
      items: items ?? this.items,
      history: history ?? this.history,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastExportedAt: clearLastExportedAt
          ? null
          : (lastExportedAt ?? this.lastExportedAt),
      lastExportPath: clearLastExportPath
          ? null
          : (lastExportPath ?? this.lastExportPath),
    );
  }
}
