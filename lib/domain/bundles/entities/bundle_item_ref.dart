import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';

/// A reference to a vault item that has been added to a bundle.
///
/// Stores only a pointer to the live vault entity plus a snapshot of its
/// display data (title/subtitle) captured at add-time so the bundle UI is
/// resilient to downstream renames/deletions. The underlying item is
/// resolved live while the bundle is in `draft` / `ready` status, and
/// frozen into the export archive on share.
class BundleItemRef {
  const BundleItemRef({
    required this.id,
    required this.type,
    required this.refId,
    required this.displayName,
    required this.addedAt,
    this.subtitle,
  });

  /// Unique id within the bundle (not the underlying vault entity).
  final String id;

  final BundleItemType type;

  /// Id of the underlying vault entity (credential id, document id, …).
  final String refId;

  /// Snapshot of the item's name at add-time, shown in the bundle UI
  /// even if the source entity is later renamed or removed.
  final String displayName;

  final String? subtitle;

  final DateTime addedAt;

  BundleItemRef copyWith({
    String? id,
    BundleItemType? type,
    String? refId,
    String? displayName,
    String? subtitle,
    bool clearSubtitle = false,
    DateTime? addedAt,
  }) {
    return BundleItemRef(
      id: id ?? this.id,
      type: type ?? this.type,
      refId: refId ?? this.refId,
      displayName: displayName ?? this.displayName,
      subtitle: clearSubtitle ? null : (subtitle ?? this.subtitle),
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
