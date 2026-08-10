enum BundleItemType {
  credential,
  document,
  note,
  identityCard,
  collection;

  String get storageKey {
    switch (this) {
      case BundleItemType.credential:
        return 'credential';
      case BundleItemType.document:
        return 'document';
      case BundleItemType.note:
        return 'note';
      case BundleItemType.identityCard:
        return 'identity_card';
      case BundleItemType.collection:
        return 'collection';
    }
  }

  /// Returns null for unknown keys so callers can drop unrecognised items.
  static BundleItemType? fromStorageKey(String? key) {
    switch (key) {
      case 'credential':
        return BundleItemType.credential;
      case 'document':
        return BundleItemType.document;
      case 'note':
        return BundleItemType.note;
      case 'identity_card':
        return BundleItemType.identityCard;
      case 'collection':
        return BundleItemType.collection;
      default:
        return null;
    }
  }

  /// True when the underlying vault item owns actual file artefacts that
  /// must be copied into the export. False items are rendered as `.txt`.
  bool get isFileBacked {
    switch (this) {
      case BundleItemType.document:
        return true;
      case BundleItemType.credential:
      case BundleItemType.note:
      case BundleItemType.identityCard:
      case BundleItemType.collection:
        return false;
    }
  }
}
