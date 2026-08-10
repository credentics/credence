enum BundleStatus {
  draft,
  ready,
  exported,
  archived;

  String get storageKey {
    switch (this) {
      case BundleStatus.draft:
        return 'draft';
      case BundleStatus.ready:
        return 'ready';
      case BundleStatus.exported:
        return 'exported';
      case BundleStatus.archived:
        return 'archived';
    }
  }

  static BundleStatus fromStorageKey(String? key) {
    switch (key) {
      case 'ready':
        return BundleStatus.ready;
      case 'exported':
        return BundleStatus.exported;
      case 'archived':
        return BundleStatus.archived;
      case 'draft':
      default:
        return BundleStatus.draft;
    }
  }
}
