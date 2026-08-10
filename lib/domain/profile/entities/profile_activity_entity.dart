class ProfileActivityEntity {
  const ProfileActivityEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
    this.highlighted = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime occurredAt;
  final bool highlighted;
}
