enum TaskPriority {
  low,
  medium,
  high;

  String get storageKey {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
    }
  }

  static TaskPriority fromStorageKey(String? key) {
    switch (key) {
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      case 'low':
      default:
        return TaskPriority.low;
    }
  }
}
