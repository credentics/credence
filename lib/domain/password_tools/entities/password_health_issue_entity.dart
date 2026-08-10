enum PasswordHealthIssueCode {
  tooShort,
  lowCharsetDiversity,
  repeatedPattern,
  sequentialPattern,
  containsCommonWord,
  similarToAccountData,
  reusedPassword,
}

class PasswordHealthIssueEntity {
  const PasswordHealthIssueEntity({
    required this.code,
    required this.message,
    required this.penalty,
  });

  final PasswordHealthIssueCode code;
  final String message;
  final int penalty;
}
