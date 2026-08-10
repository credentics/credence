/// Optional pointer from a task to a vault item (document, credential,
/// bundle, or collection). Stores only the type + id plus a snapshot of
/// the display name so the UI keeps reading even if the underlying item
/// is renamed or removed.
class TaskLinkedRef {
  const TaskLinkedRef({
    required this.type,
    required this.refId,
    required this.displayNameSnapshot,
  });

  /// `document` | `credential` | `bundle` | `collection`.
  final String type;
  final String refId;
  final String displayNameSnapshot;

  TaskLinkedRef copyWith({
    String? type,
    String? refId,
    String? displayNameSnapshot,
  }) {
    return TaskLinkedRef(
      type: type ?? this.type,
      refId: refId ?? this.refId,
      displayNameSnapshot: displayNameSnapshot ?? this.displayNameSnapshot,
    );
  }
}
