class GeneratedPasswordHistoryEntryDto {
  const GeneratedPasswordHistoryEntryDto({
    required this.id,
    required this.password,
    required this.createdAtIso,
    required this.length,
    this.score,
  });

  final String id;
  final String password;
  final String createdAtIso;
  final int length;
  final int? score;

  factory GeneratedPasswordHistoryEntryDto.fromMap(Map<String, dynamic> map) {
    return GeneratedPasswordHistoryEntryDto(
      id: map['id'] as String? ?? '',
      password: map['password'] as String? ?? '',
      createdAtIso: map['createdAtIso'] as String? ?? '',
      length: map['length'] as int? ?? 0,
      score: map['score'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'password': password,
      'createdAtIso': createdAtIso,
      'length': length,
      'score': score,
    };
  }
}
