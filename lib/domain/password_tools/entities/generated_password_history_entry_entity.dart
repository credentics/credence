class GeneratedPasswordHistoryEntryEntity {
  const GeneratedPasswordHistoryEntryEntity({
    required this.id,
    required this.password,
    required this.createdAt,
    required this.length,
    this.score,
  });

  final String id;
  final String password;
  final DateTime createdAt;
  final int length;
  final int? score;
}
