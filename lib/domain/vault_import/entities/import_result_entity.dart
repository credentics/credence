class ImportResultEntity {
  const ImportResultEntity({
    required this.totalParsed,
    required this.imported,
    required this.skippedDuplicates,
    required this.errors,
    required this.errorMessages,
  });

  final int totalParsed;
  final int imported;
  final int skippedDuplicates;
  final int errors;
  final List<String> errorMessages;
}
