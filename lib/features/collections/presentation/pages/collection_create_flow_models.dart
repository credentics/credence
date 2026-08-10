class CollectionCreateDraft {
  const CollectionCreateDraft({
    required this.name,
    required this.iconKey,
    this.iconEmoji,
    this.iconImagePath,
    required this.accentColorHex,
  });

  final String name;
  final String iconKey;
  final String? iconEmoji;
  final String? iconImagePath;
  final String accentColorHex;

  CollectionCreateDraft copyWith({
    String? name,
    String? iconKey,
    String? iconEmoji,
    bool clearIconEmoji = false,
    String? iconImagePath,
    bool clearIconImagePath = false,
    String? accentColorHex,
  }) {
    return CollectionCreateDraft(
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      iconEmoji: clearIconEmoji ? null : (iconEmoji ?? this.iconEmoji),
      iconImagePath: clearIconImagePath
          ? null
          : (iconImagePath ?? this.iconImagePath),
      accentColorHex: accentColorHex ?? this.accentColorHex,
    );
  }
}
