class ImportVaultResultEntity {
  const ImportVaultResultEntity({
    required this.importedDocuments,
    required this.importedPasswords,
    required this.updatedDocuments,
    required this.updatedPasswords,
  });

  final int importedDocuments;
  final int importedPasswords;
  final int updatedDocuments;
  final int updatedPasswords;
}
