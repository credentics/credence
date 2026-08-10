enum CollectionBlockType {
  folder,
  section,
  document,
  note,
  input,
  checklist,
  link,
  image,
  expense,
  timeline,
  location,
  reminder,
  progress,
}

extension CollectionBlockTypeX on CollectionBlockType {
  String get key {
    return switch (this) {
      CollectionBlockType.folder => 'folder',
      CollectionBlockType.section => 'section',
      CollectionBlockType.document => 'document',
      CollectionBlockType.note => 'note',
      CollectionBlockType.input => 'input',
      CollectionBlockType.checklist => 'checklist',
      CollectionBlockType.link => 'link',
      CollectionBlockType.image => 'image',
      CollectionBlockType.expense => 'expense',
      CollectionBlockType.timeline => 'timeline',
      CollectionBlockType.location => 'location',
      CollectionBlockType.reminder => 'reminder',
      CollectionBlockType.progress => 'progress',
    };
  }

  String get label {
    return switch (this) {
      CollectionBlockType.folder => 'Folder',
      CollectionBlockType.section => 'Section',
      CollectionBlockType.document => 'Document',
      CollectionBlockType.note => 'Note',
      CollectionBlockType.input => 'Input',
      CollectionBlockType.checklist => 'Checklist',
      CollectionBlockType.link => 'Link',
      CollectionBlockType.image => 'Image',
      CollectionBlockType.expense => 'Expense',
      CollectionBlockType.timeline => 'Timeline',
      CollectionBlockType.location => 'Location',
      CollectionBlockType.reminder => 'Reminder',
      CollectionBlockType.progress => 'Progress',
    };
  }

  static CollectionBlockType fromKey(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'folder' => CollectionBlockType.folder,
      'section' => CollectionBlockType.section,
      'document' => CollectionBlockType.document,
      'note' => CollectionBlockType.note,
      'input' => CollectionBlockType.input,
      'checklist' => CollectionBlockType.checklist,
      'link' => CollectionBlockType.link,
      'image' => CollectionBlockType.image,
      'expense' => CollectionBlockType.expense,
      'timeline' => CollectionBlockType.timeline,
      'location' => CollectionBlockType.location,
      'reminder' => CollectionBlockType.reminder,
      'progress' => CollectionBlockType.progress,
      _ => CollectionBlockType.note,
    };
  }
}
