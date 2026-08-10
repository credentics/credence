class ProfileActivityRecordDto {
  const ProfileActivityRecordDto({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.occurredAtIso,
    required this.highlighted,
  });

  final String id;
  final String title;
  final String subtitle;
  final String occurredAtIso;
  final bool highlighted;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'occurredAtIso': occurredAtIso,
      'highlighted': highlighted,
    };
  }

  factory ProfileActivityRecordDto.fromMap(Map<String, dynamic> map) {
    return ProfileActivityRecordDto(
      id: (map['id'] as String? ?? '').trim(),
      title: (map['title'] as String? ?? '').trim(),
      subtitle: (map['subtitle'] as String? ?? '').trim(),
      occurredAtIso: (map['occurredAtIso'] as String? ?? '').trim(),
      highlighted: map['highlighted'] == true,
    );
  }
}
