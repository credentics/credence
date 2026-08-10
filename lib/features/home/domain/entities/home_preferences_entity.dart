class HomePreferencesEntity {
  const HomePreferencesEntity({
    this.visibleSections = const {
      'reminders': true,
      'frequentlyUsed': true,
      'quickAccess': true,
      'secureNotes': true,
      'recentItems': true,
      'insights': true,
    },
    this.sectionOrder = const [
      'reminders',
      'frequentlyUsed',
      'quickAccess',
      'secureNotes',
      'recentItems',
      'insights',
    ],
    this.quickAccessCategories = const [
      'ids',
      'work',
      'documents',
      'cards',
      'collections',
      'tasks',
    ],
    this.visibleCategories = const {
      'ids': true,
      'work': true,
      'documents': true,
      'cards': true,
      'collections': true,
      'tasks': true,
    },
    this.pinnedItemIds = const [],
    this.smartRules = const {
      'showExpiring': true,
      'showMissing': true,
      'showRecentlyUpdated': true,
    },
    this.cardSize = CardSize.comfortable,
    this.layoutStyle = LayoutStyle.horizontal,
    this.showPreviews = true,
  });

  final Map<String, bool> visibleSections;
  final List<String> sectionOrder;
  final List<String> quickAccessCategories;
  final Map<String, bool> visibleCategories;
  final List<String> pinnedItemIds;
  final Map<String, bool> smartRules;
  final CardSize cardSize;
  final LayoutStyle layoutStyle;
  final bool showPreviews;

  bool isSectionVisible(String key) => visibleSections[key] ?? true;
  bool isCategoryVisible(String key) => visibleCategories[key] ?? true;

  HomePreferencesEntity copyWith({
    Map<String, bool>? visibleSections,
    List<String>? sectionOrder,
    List<String>? quickAccessCategories,
    Map<String, bool>? visibleCategories,
    List<String>? pinnedItemIds,
    Map<String, bool>? smartRules,
    CardSize? cardSize,
    LayoutStyle? layoutStyle,
    bool? showPreviews,
  }) =>
      HomePreferencesEntity(
        visibleSections: visibleSections ?? this.visibleSections,
        sectionOrder: sectionOrder ?? this.sectionOrder,
        quickAccessCategories:
            quickAccessCategories ?? this.quickAccessCategories,
        visibleCategories: visibleCategories ?? this.visibleCategories,
        pinnedItemIds: pinnedItemIds ?? this.pinnedItemIds,
        smartRules: smartRules ?? this.smartRules,
        cardSize: cardSize ?? this.cardSize,
        layoutStyle: layoutStyle ?? this.layoutStyle,
        showPreviews: showPreviews ?? this.showPreviews,
      );

  static const HomePreferencesEntity defaults = HomePreferencesEntity();
}

enum CardSize { compact, comfortable }

enum LayoutStyle { grid, horizontal }
