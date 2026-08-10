enum SecureShareStatus {
  initial,
  loading,
  success,
  error,
}

class SecureShareState {
  const SecureShareState({
    this.status = SecureShareStatus.initial,
    this.shareLink,
    this.expiresAt,
    this.errorMessage,
    this.selectedFields = const {},
    this.passphrase = '',
    this.generatedPassphrase = '',
  });

  final SecureShareStatus status;
  final String? shareLink;
  final DateTime? expiresAt;
  final String? errorMessage;
  final Set<String> selectedFields;
  final String passphrase;
  final String generatedPassphrase;

  SecureShareState copyWith({
    SecureShareStatus? status,
    String? shareLink,
    DateTime? expiresAt,
    String? errorMessage,
    Set<String>? selectedFields,
    String? passphrase,
    String? generatedPassphrase,
  }) {
    return SecureShareState(
      status: status ?? this.status,
      shareLink: shareLink ?? this.shareLink,
      expiresAt: expiresAt ?? this.expiresAt,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedFields: selectedFields ?? this.selectedFields,
      passphrase: passphrase ?? this.passphrase,
      generatedPassphrase: generatedPassphrase ?? this.generatedPassphrase,
    );
  }
}
