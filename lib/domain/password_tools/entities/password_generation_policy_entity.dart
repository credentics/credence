class PasswordGenerationPolicyEntity {
  const PasswordGenerationPolicyEntity({
    this.length = 20,
    this.includeLowercase = true,
    this.includeUppercase = true,
    this.includeNumbers = true,
    this.includeSymbols = true,
    this.excludeAmbiguous = true,
  });

  final int length;
  final bool includeLowercase;
  final bool includeUppercase;
  final bool includeNumbers;
  final bool includeSymbols;
  final bool excludeAmbiguous;
}
