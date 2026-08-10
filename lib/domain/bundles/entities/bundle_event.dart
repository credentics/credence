enum BundleEventKind {
  created,
  renamed,
  purposeUpdated,
  descriptionUpdated,
  itemAdded,
  itemRemoved,
  itemReordered,
  statusChanged,
  exported,
  archived,
  restored;

  String get storageKey {
    switch (this) {
      case BundleEventKind.created:
        return 'created';
      case BundleEventKind.renamed:
        return 'renamed';
      case BundleEventKind.purposeUpdated:
        return 'purpose_updated';
      case BundleEventKind.descriptionUpdated:
        return 'description_updated';
      case BundleEventKind.itemAdded:
        return 'item_added';
      case BundleEventKind.itemRemoved:
        return 'item_removed';
      case BundleEventKind.itemReordered:
        return 'item_reordered';
      case BundleEventKind.statusChanged:
        return 'status_changed';
      case BundleEventKind.exported:
        return 'exported';
      case BundleEventKind.archived:
        return 'archived';
      case BundleEventKind.restored:
        return 'restored';
    }
  }

  /// Returns null for unknown keys so callers can drop unrecognised events.
  static BundleEventKind? fromStorageKey(String? key) {
    switch (key) {
      case 'created':
        return BundleEventKind.created;
      case 'renamed':
        return BundleEventKind.renamed;
      case 'purpose_updated':
        return BundleEventKind.purposeUpdated;
      case 'description_updated':
        return BundleEventKind.descriptionUpdated;
      case 'item_added':
        return BundleEventKind.itemAdded;
      case 'item_removed':
        return BundleEventKind.itemRemoved;
      case 'item_reordered':
        return BundleEventKind.itemReordered;
      case 'status_changed':
        return BundleEventKind.statusChanged;
      case 'exported':
        return BundleEventKind.exported;
      case 'archived':
        return BundleEventKind.archived;
      case 'restored':
        return BundleEventKind.restored;
      default:
        return null;
    }
  }
}

class BundleEvent {
  const BundleEvent({
    required this.id,
    required this.kind,
    required this.at,
    this.detail,
  });

  final String id;
  final BundleEventKind kind;
  final DateTime at;
  final String? detail;

  BundleEvent copyWith({
    String? id,
    BundleEventKind? kind,
    DateTime? at,
    String? detail,
    bool clearDetail = false,
  }) {
    return BundleEvent(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      at: at ?? this.at,
      detail: clearDetail ? null : (detail ?? this.detail),
    );
  }
}
