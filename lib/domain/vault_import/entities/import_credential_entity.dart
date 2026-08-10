class ImportCredentialEntity {
  const ImportCredentialEntity({
    required this.serviceName,
    required this.username,
    required this.password,
    required this.url,
    required this.notes,
    this.totp,
    this.isDuplicate = false,
    this.isSelected = true,
  });

  final String serviceName;
  final String username;
  final String password;
  final String url;
  final String notes;
  final String? totp;
  final bool isDuplicate;
  final bool isSelected;

  ImportCredentialEntity copyWith({
    String? serviceName,
    String? username,
    String? password,
    String? url,
    String? notes,
    String? totp,
    bool? isDuplicate,
    bool? isSelected,
  }) {
    return ImportCredentialEntity(
      serviceName: serviceName ?? this.serviceName,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      totp: totp ?? this.totp,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
