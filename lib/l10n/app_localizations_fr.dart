// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Credence';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabCredentials => 'Identifiants';

  @override
  String get tabGenerator => 'Générateur';

  @override
  String get tabDocuments => 'Documents';

  @override
  String get tabProfile => 'Profil';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonSaving => 'Enregistrement...';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonErrorGeneric =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get commonErrorLoad =>
      'Impossible de charger les données. Appuyez sur réessayer.';

  @override
  String get commonViewAll => 'Voir tout';

  @override
  String get commonPasswordCopiedSecurely =>
      'Mot de passe copié en toute sécurité.';

  @override
  String get commonUnableCopyPassword =>
      'Impossible de copier le mot de passe.';

  @override
  String get tooltipCopyPassword => 'Copier le mot de passe';

  @override
  String get tooltipOpenDetails => 'Ouvrir les détails';

  @override
  String get credentialsTitle => 'Identifiants';

  @override
  String get credentialsUnableLoadVaultOverview =>
      'Impossible de charger la vue d\'ensemble du coffre.';

  @override
  String get credentialsUnableLoadAccounts =>
      'Impossible de charger les comptes.';

  @override
  String get credentialsUnableLoadSingle =>
      'Impossible de charger l\'identifiant.';

  @override
  String get credentialsNoAccountsFound => 'Aucun compte trouvé.';

  @override
  String credentialsNoResultsForQuery(String query) {
    return 'Aucun résultat pour \"$query\"';
  }

  @override
  String get credentialsGeneratorCardTitle => 'Générateur de mots de passe';

  @override
  String get credentialsGeneratorCardSubtitle =>
      'Créez des mots de passe sûrs en un clic';

  @override
  String get credentialsDesktopSubtitle =>
      'Coffre hors ligne, accès instantané';

  @override
  String get credentialsAdded => 'Identifiant ajouté.';

  @override
  String get credentialsUnableAdd => 'Impossible d\'ajouter l\'identifiant.';

  @override
  String get credentialsUpdated => 'Identifiant mis à jour.';

  @override
  String get credentialsUnableUpdate =>
      'Impossible de mettre à jour l\'identifiant pour le moment.';

  @override
  String get credentialsSavingLogo => 'Enregistrement du logo en local...';

  @override
  String get credentialsNewCredential => 'Nouvel identifiant';

  @override
  String get credentialsSingleCredential => 'Identifiant';

  @override
  String get credentialsLogoSavingInProgress =>
      'Le logo est encore en cours d\'enregistrement local. Veuillez patienter.';

  @override
  String get credentialsRequiredFieldsMissing =>
      'Le service, l\'identifiant et le mot de passe sont requis.';

  @override
  String get credentialsLookForAnotherIcon => 'Chercher une autre icône';

  @override
  String get credentialsResetIcon => 'Réinitialiser l\'icône';

  @override
  String get credentialsCategory => 'Catégorie';

  @override
  String get credentialsSearchEnterServiceOrWebsite =>
      'Saisissez d\'abord un service ou un site web.';

  @override
  String get credentialsNoMatchingIconFound =>
      'Aucune icône d\'entreprise correspondante trouvée.';

  @override
  String get credentialsSelectSuggestedBrand =>
      'Sélectionnez une marque suggérée pour mettre à jour l\'icône et le site.';

  @override
  String get credentialsUnableSearchBrands =>
      'Impossible de rechercher les marques pour le moment.';

  @override
  String get credentialsLogoPreviewLoadedLocalSaveFailed =>
      'Aperçu du logo chargé, mais l\'enregistrement local a échoué pour cette marque.';

  @override
  String get credentialsUnableSaveLogoLocally =>
      'Impossible d\'enregistrer le logo en local.';

  @override
  String get credentialsEmailCopied => 'E-mail copié.';

  @override
  String get credentialsPasswordCopied => 'Mot de passe copié.';

  @override
  String get credentialsNoUrlToCopy => 'Aucune URL à copier.';

  @override
  String get credentialsWebsiteCopied => 'URL du site copiée.';

  @override
  String get credentialsAddToFavorites => 'Ajouter aux favoris';

  @override
  String get credentialsAddedToFavorites => 'Ajouté aux favoris.';

  @override
  String get credentialsAddToSiriShortcuts => 'Ajouter aux raccourcis Siri';

  @override
  String get credentialsSiriShortcutReady => 'Action raccourci Siri prête.';

  @override
  String get credentialsDelete => 'Supprimer';

  @override
  String get credentialsDeleteNeedsConfirmation =>
      'La suppression nécessite une confirmation.';

  @override
  String get credentialFieldAccountLabel => 'Libellé du compte';

  @override
  String get credentialFieldEmailUsername => 'E-mail/Nom d\'utilisateur';

  @override
  String get credentialFieldPassword => 'Mot de passe';

  @override
  String get credentialFieldWebsiteUrl => 'URL';

  @override
  String get credentialFieldNotes => 'Notes';

  @override
  String get credentialEditServicePlaceholder => 'GitHub';

  @override
  String get credentialEditAccountPlaceholder => 'Compte personnel';

  @override
  String get credentialEditEmailPlaceholder => 'jane.smith@email.com';

  @override
  String get credentialEditUrlPlaceholder => 'https://github.com';

  @override
  String get credentialEditNotesPlaceholder =>
      'Code de récupération, notes de sécurité, rappels...';

  @override
  String get credentialsSearchHint => 'Rechercher des identifiants...';

  @override
  String credentialsSearchCountHint(int count) {
    return 'Rechercher dans $count identifiants...';
  }

  @override
  String get homeWelcomeBack => 'Bon retour';

  @override
  String homeGreetingNamed(String name) {
    return 'Bonjour, $name.';
  }

  @override
  String get homeGreetingFallback => 'Bonjour.';

  @override
  String get homeOwnerName => 'Propriétaire du coffre';

  @override
  String get homeSearchVaultDocuments =>
      'Rechercher dans le coffre, documents...';

  @override
  String get homeActionRequired => 'ACTION REQUISE';

  @override
  String get homeSecurityCheckRecommended =>
      'Un contrôle de sécurité est recommandé.';

  @override
  String get homeReviewNow => 'Vérifier';

  @override
  String get homeAllCredentialsSecure =>
      'Tous les identifiants semblent sécurisés.';

  @override
  String get homeFrequentlyUsed => 'Fréquemment utilisés';

  @override
  String get homeNoQuickItemsYet => 'Aucun élément rapide pour le moment.';

  @override
  String get homeRecentItems => 'Éléments récents';

  @override
  String get homeRecentActivityPlaceholder =>
      'Votre activité récente apparaîtra ici.';

  @override
  String homeLastUsedWithTime(String username, String time) {
    return '$username • Dernière utilisation $time';
  }

  @override
  String get homeRelativeJustNow => 'À l\'instant';

  @override
  String homeRelativeMinutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String homeRelativeHoursAgo(int hours) {
    return 'il y a $hours h';
  }

  @override
  String get homeRelativeYesterday => 'Hier';

  @override
  String homeRelativeDaysAgo(int days) {
    return 'il y a $days j';
  }

  @override
  String homeRelativeWeeksAgo(int weeks) {
    return 'il y a $weeks sem';
  }

  @override
  String homeRelativeMonthsAgo(int months) {
    return 'il y a $months mois';
  }

  @override
  String get securitySettingsTitle => 'Paramètres de sécurité';

  @override
  String documentsPageComingSoon(String category) {
    return 'La page documents pour $category arrive bientôt.';
  }

  @override
  String get desktopLocalDataOnly =>
      'Les données restent locales sur cet appareil';

  @override
  String get passwordHealthChecking => 'Vérification...';

  @override
  String get passwordHealthWeak => 'Faible';

  @override
  String get passwordHealthFair => 'Moyen';

  @override
  String get passwordHealthStrong => 'Fort';

  @override
  String get passwordHealthExcellent => 'Excellent';

  @override
  String get profileExportVaultData => 'Exporter les données du coffre';

  @override
  String get profileUnableLoad =>
      'Impossible de charger le profil pour le moment.';

  @override
  String get profileShareSecureProfileTitle => 'Partager le profil sécurisé';

  @override
  String get profileShareSecureProfileSubtitle =>
      'Générer une vCard chiffrée temporaire';

  @override
  String get profileAccountDetailsTitle => 'Détails du compte';

  @override
  String get profileAccountDetailsSection => 'DÉTAILS DU COMPTE';

  @override
  String get profileRecentActivityTitle => 'Activité récente';

  @override
  String get profileRecentActivitySection => 'ACTIVITÉ RÉCENTE';

  @override
  String get profileExporting => 'Export en cours...';

  @override
  String get profileExportHint =>
      'Les données exportées sont chiffrées et nécessitent votre mot de passe maître pour être déchiffrées sur un autre appareil.';

  @override
  String get profileAddAccountDetailsFirst =>
      'Ajoutez d\'abord vos informations de compte avant de partager le profil.';

  @override
  String get profileExportStatusPreparing => 'Préparation de l\'export...';

  @override
  String get profileExportStatusSelectDestination =>
      'Sélectionnez une destination pour enregistrer l\'archive...';

  @override
  String get profileExportStatusOpeningShareSheet =>
      'Ouverture de la feuille de partage...';

  @override
  String get profileExportSavedLocally =>
      'Archive du coffre enregistrée localement.';

  @override
  String profileExportSavedAt(String path) {
    return 'Archive du coffre enregistrée : $path';
  }

  @override
  String get profileExportGeneratedAndShared =>
      'Archive du coffre générée et partagée.';

  @override
  String get profileExportStatusFailed => 'Échec de l\'export.';

  @override
  String get profileUnableExportVaultData =>
      'Impossible d\'exporter les données du coffre pour le moment.';

  @override
  String get profileExportPassphraseTitle => 'Phrase secrète d\'export';

  @override
  String get profileExportPassphraseHint =>
      'Saisissez la phrase secrète d\'export';

  @override
  String get profileExportAction => 'Exporter';

  @override
  String get profileExportStatusOpeningSaveDialog =>
      'Ouverture de la boîte de dialogue d\'enregistrement...';

  @override
  String get profileExportSaveArchiveButton =>
      'Enregistrer l\'archive du coffre';

  @override
  String get profileExportStatusSaveDialogTimedOut =>
      'La boîte d\'enregistrement a expiré sur cette plateforme ; utilisation du chemin local de secours.';

  @override
  String get profileExportStatusNoSaveLocation =>
      'Boîte d\'enregistrement fermée sans emplacement.';

  @override
  String get profileExportStatusSavingArchive =>
      'Enregistrement du fichier d\'archive...';

  @override
  String profileExportStatusArchiveSaved(String path) {
    return 'Archive enregistrée dans $path';
  }

  @override
  String get profileExportStatusSaveDialogFailed =>
      'Échec de la boîte d\'enregistrement ; tentative de l\'emplacement de secours...';

  @override
  String get profileExportStatusSavedFallback =>
      'Enregistré dans l\'emplacement de secours.';

  @override
  String profileExportStatusFallbackSaveSuccess(String path) {
    return 'Enregistrement de secours réussi : $path';
  }

  @override
  String get profileExportStatusFallbackSaveFailed =>
      'Échec de l\'enregistrement de secours.';

  @override
  String get profileExportArchiveNotFound => 'Fichier d\'archive introuvable.';

  @override
  String profileExportShareText(int documents, int credentials, int files) {
    return 'Archive du coffre ($documents docs, $credentials identifiants, $files fichiers liés)';
  }

  @override
  String get profileExportInProgress => 'Export en cours';

  @override
  String get profileFullName => 'Nom complet';

  @override
  String get profileEmail => 'E-mail';

  @override
  String get profilePhone => 'Téléphone';

  @override
  String get profileNotProvided => 'Non renseigné';

  @override
  String get profileNoRecentActivityYet => 'Aucune activité récente.';

  @override
  String get profileNoActivityYet => 'Pas encore d\'activité';

  @override
  String get profileNoActivitySubtitle =>
      'Votre coffre est vide. Tous vos\névénements de sécurité apparaîtront\nici.';

  @override
  String profileActivityWithTime(String subtitle, String time) {
    return '$subtitle • $time';
  }

  @override
  String get profileEditTitle => 'Modifier le profil';

  @override
  String get profileUpdatePhoto => 'Mettre à jour la photo';

  @override
  String get profileTapChangePhoto => 'Touchez pour changer la photo de profil';

  @override
  String get profileFirstName => 'Prénom';

  @override
  String get profileLastName => 'Nom';

  @override
  String get profileEmailAddress => 'Adresse e-mail';

  @override
  String get profileSecurePhone => 'Téléphone sécurisé';

  @override
  String get profileContactInfoSecurityNotice =>
      'Les modifications de vos informations de contact peuvent nécessiter une authentification secondaire pour des raisons de sécurité. Votre coffre reste chiffré.';

  @override
  String get profileSaveChanges => 'Enregistrer les changements';

  @override
  String get profileChooseFromLibrary => 'Choisir depuis la bibliothèque';

  @override
  String get profileTakePhoto => 'Prendre une photo';

  @override
  String get profileRequiredFieldsMessage =>
      'Le prénom, le nom et l\'e-mail sont requis.';

  @override
  String get profileUnableSave =>
      'Impossible d\'enregistrer le profil pour le moment.';

  @override
  String get profileShareTitle => 'Partager le profil';

  @override
  String get profileShareSubtitle =>
      'Sélectionnez les informations à inclure dans votre vCard chiffrée.';

  @override
  String get profileShareAttributesSection => 'ATTRIBUTS DU PROFIL';

  @override
  String get profileShareSecurityOptionsSection => 'OPTIONS DE SÉCURITÉ';

  @override
  String get profileShareGenerating => 'Génération...';

  @override
  String get profileShareGenerateSecureLink => 'Générer la vCard';

  @override
  String get profileShareQrCode => 'Aperçu vCard';

  @override
  String get profileShareCopyLink => 'Copier la vCard';

  @override
  String profileShareLinkExpires(String date) {
    return 'vCard valide jusqu\'au $date';
  }

  @override
  String get profileSharePoweredByEncryption =>
      'PROPULSÉ PAR LE CHIFFREMENT DE BOUT EN BOUT';

  @override
  String profileShareHoursLabel(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String get profileShareGenerateFirst => 'Générez d\'abord une vCard.';

  @override
  String get profileShareLinkCopied => 'vCard copiée.';

  @override
  String get profileShareSecureLink => 'vCard';

  @override
  String get profileShareAction => 'Partager';

  @override
  String get profileShareOptInTitle => 'Le partage est volontaire';

  @override
  String get profileShareOptInSubtitle =>
      'Seuls les champs sélectionnés sont inclus. Aucun identifiant, document, collection ou donnée du coffre n\'est partagé.';

  @override
  String get profileShareEmptyAttributeValue => 'Non renseigné';

  @override
  String get profilePhoneNumber => 'Numéro de téléphone';

  @override
  String get profileHomeAddress => 'Adresse personnelle';

  @override
  String get profileSocialLinks => 'Liens sociaux';

  @override
  String profileShareExpirationLabel(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String get profileShareLinkExpiration => 'Validité de la vCard';

  @override
  String get securitySectionBiometrics => 'BIOMÉTRIE';

  @override
  String get securitySectionVaultSecurity => 'SÉCURITÉ DU COFFRE';

  @override
  String get securitySectionPrivacy => 'CONFIDENTIALITÉ';

  @override
  String get securitySectionSync => 'SYNCHRO';

  @override
  String get securitySectionAdvanced => 'AVANCÉ';

  @override
  String get securityUseFaceId => 'Utiliser FaceID';

  @override
  String get securityUseFaceIdSubtitle =>
      'Déverrouillez votre coffre instantanément';

  @override
  String get securityAutoLockTimer => 'Verrouillage auto';

  @override
  String get securityScreenshotProtection => 'Protection des captures';

  @override
  String get securityScreenshotProtectionSubtitle =>
      'Bloquer la capture dans l\'app';

  @override
  String get securityAutoBlurFields => 'Flou auto des champs';

  @override
  String get securityClearClipboard => 'Vider le presse-papiers';

  @override
  String get securitySyncStatus => 'État de synchro';

  @override
  String get securitySyncTarget => 'Destination de synchro';

  @override
  String get securityChangeMasterPassword => 'Changer le mot de passe maître';

  @override
  String get securityChangeMasterPasswordHint =>
      'Mettez à jour votre phrase secrète dans la section chiffrement.';

  @override
  String get securityExportData => 'Exporter les données';

  @override
  String get securityExportHint =>
      'L\'export est disponible dans le flux de portabilité.';

  @override
  String get securityVersionAndAudit => 'Credence v1.0.0';

  @override
  String get settingsUseAppSupportFolder => 'Utiliser le dossier App Support';

  @override
  String minutesLabel(int minutes) {
    return '$minutes minute';
  }

  @override
  String get syncTargetDisabled => 'Désactivé';

  @override
  String get syncTargetLocalFolder => 'Dossier local';

  @override
  String get syncTargetDropboxCloud => 'Cloud Dropbox';

  @override
  String get settingsNavVault => 'COFFRE';

  @override
  String get settingsNavKeys => 'CLÉS';

  @override
  String get settingsNavSharing => 'PARTAGE';

  @override
  String get settingsNavSettings => 'RÉGLAGES';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonCopied => 'Copié.';

  @override
  String get commonShare => 'Partager';

  @override
  String get documentArchived => 'Document archivé.';

  @override
  String get documentDeleted => 'Document supprimé.';

  @override
  String get documentForceExpire => 'Forcer l\'expiration';

  @override
  String get documentForceExpireConfirm => 'Forcer';

  @override
  String get documentForceExpireDescription =>
      'Cela marquera le document comme expiré en définissant sa date d\'expiration à hier.';

  @override
  String get documentForceExpireTitle => 'Forcer l\'expiration du document ?';

  @override
  String get documentForcedExpired => 'Document marqué comme expiré.';

  @override
  String get documentFileUnavailable => 'File unavailable.';

  @override
  String get documentFileUnavailableOnDevice =>
      'File unavailable on this device.';

  @override
  String get documentFileUnavailableOrEmpty => 'File unavailable or empty.';

  @override
  String get documentPdfPreview => 'PDF Preview';

  @override
  String get documentPreview => 'Preview';

  @override
  String get documentPrimaryIdSubtitle => 'Mark this ID for quick access.';

  @override
  String get documentPrimaryIdTitle => 'Primary ID';

  @override
  String get documentPrimaryRemoved => 'Primary ID removed.';

  @override
  String get documentPrimarySet => 'Primary ID set.';

  @override
  String get documentPrimaryUnableUpdate => 'Unable to update primary ID.';

  @override
  String get documentRemoveArchive => 'Archive document';

  @override
  String get documentRemoveArchiveSubtitle =>
      'Hide it from active items without deleting files.';

  @override
  String get documentRemoveDelete => 'Delete document';

  @override
  String get documentRemoveDeleteSubtitle =>
      'Remove document and linked files from this device.';

  @override
  String get documentRemoveDescription =>
      'Choose what to do with this document.';

  @override
  String documentRemoveTitle(Object title) {
    return 'Remove $title?';
  }

  @override
  String get documentShareErrorFileNotFound => 'File not found.';

  @override
  String get documentShareErrorPermissionDenied =>
      'Permission denied while sharing.';

  @override
  String get documentShareErrorUnavailable =>
      'Sharing is unavailable on this build.';

  @override
  String get documentSharingUnavailableBuild =>
      'Sharing is unavailable on this build.';

  @override
  String get documentStructuredInformation => 'STRUCTURED INFORMATION';

  @override
  String get documentUnableLoad => 'Impossible de charger le document.';

  @override
  String get documentUnableForceExpire =>
      'Impossible de forcer l\'expiration du document pour le moment.';

  @override
  String get documentUnableOpenPreview => 'Impossible d\'ouvrir l\'aperçu.';

  @override
  String get collectionUploadDropHere => 'Déposer le fichier ici';

  @override
  String get documentPreviewNotAvailable =>
      'L\'aperçu n\'est pas disponible pour ce type de fichier.\nVous pouvez le partager pour l\'ouvrir dans une autre app.';

  @override
  String get documentUnableRemove =>
      'Impossible de supprimer le document pour le moment.';

  @override
  String get documentUnableRenderImagePreview =>
      'Unable to render image preview.';

  @override
  String get documentUnableShareFile =>
      'Impossible de partager le fichier pour le moment.';

  @override
  String get documentUpdated => 'Document mis à jour.';

  @override
  String get idEntryBackSide => 'Back Side';

  @override
  String get idEntryBackSideCapturedNotice => 'Back side captured.';

  @override
  String get idEntryCameraLibraryUnavailable =>
      'Camera or library is unavailable on this device.';

  @override
  String get idEntryCameraMobileOnly =>
      'Camera capture is available on mobile only.';

  @override
  String idEntryCaptureAlreadyAdded(Object side) {
    return '$side already added';
  }

  @override
  String get idEntryCaptureClearImageFromCamera =>
      'Capture a clear image using your camera.';

  @override
  String get idEntryCapturePreviewOrReplaceQuestion =>
      'Would you like to preview it or replace it?';

  @override
  String get idEntryChooseFile => 'Choose File';

  @override
  String get idEntryChooseImageSource => 'Choose Image Source';

  @override
  String get idEntryChooseImageSourceReplace =>
      'Select a new source to replace this image.';

  @override
  String get idEntryClearLabel => 'Clear label';

  @override
  String get idEntryCountry => 'Country';

  @override
  String get idEntryCountryExample => 'e.g. United States';

  @override
  String get idEntryDateFormatShort => 'MM/DD/YYYY';

  @override
  String get idEntryDateOfBirth => 'Date of Birth';

  @override
  String get idEntryDesktopAutofillNotice =>
      'Desktop supports upload only. OCR autofill runs on mobile.';

  @override
  String idEntryDetectedTypeVerifyFields(Object detectedType) {
    return 'Detected: $detectedType. Please verify all fields.';
  }

  @override
  String idEntryDetectedTypeWithConfidence(
    Object confidence,
    Object detectedType,
    Object side,
  ) {
    return 'Detected: $detectedType ($confidence%) from $side.';
  }

  @override
  String get idEntryDocument => 'Document';

  @override
  String get idEntryDocumentType => 'Document Type';

  @override
  String get idEntryDocumentTypeHint => 'Select document type';

  @override
  String get idEntryDropImageFileHint => 'Drop image files here.';

  @override
  String get idEntryDropSupportedFile =>
      'Only image files and PDFs are supported.';

  @override
  String get idEntryEnterCountry => 'Enter country...';

  @override
  String get idEntryEnterCountryName => 'Enter country name';

  @override
  String get idEntryEnterFullName => 'Enter full name...';

  @override
  String get idEntryEnterPassportNumber => 'Enter passport number...';

  @override
  String get idEntryExpiryDate => 'Expiry Date';

  @override
  String get idEntryFrontImagePreviewNotice =>
      'Uploaded front image is used for OCR and preview.';

  @override
  String get idEntryFrontSide => 'Front Side';

  @override
  String get idEntryFullName => 'Full Name';

  @override
  String get idEntryFullNameAsPassport => 'Full Name (as in passport)';

  @override
  String get idEntryHelp => 'Help';

  @override
  String get idEntryIdCard => 'ID Card';

  @override
  String get idEntryImageUsedForOcrAndPreview =>
      'This image will be used for OCR and preview.';

  @override
  String get idEntryIssuingCountry => 'Issuing Country';

  @override
  String get idEntryManualDocumentEntry => 'Manual Document Entry';

  @override
  String get idEntryNationality => 'Nationality';

  @override
  String get idEntryNoReadableTextDetected => 'No readable text detected.';

  @override
  String get idEntryNoValidReferenceFileAdded =>
      'No valid reference file added.';

  @override
  String get idEntryOcrMobileOnly =>
      'OCR autofill is available on mobile only.';

  @override
  String get idEntryOpenCurrentImageFullscreen =>
      'Open current image in full screen.';

  @override
  String get idEntryOtherDocument => 'Other Document';

  @override
  String get idEntryPassport => 'Passport';

  @override
  String get idEntryPassportNumber => 'Passport Number';

  @override
  String get idEntryPhotoLibrary => 'Photo Library';

  @override
  String get idEntryPhotoLibraryMobileOnly =>
      'Photo library is available on mobile only.';

  @override
  String get idEntryPickImageOrPdf => 'Pick an image or PDF.';

  @override
  String get idEntryPreviewImageUnavailable => 'Preview image is unavailable.';

  @override
  String idEntryPreviewTitle(Object title) {
    return 'Preview • $title';
  }

  @override
  String get idEntryReferenceAttachmentAdded => 'Reference attachment added.';

  @override
  String get idEntryReferenceAttachmentChooseSource =>
      'Choose reference source';

  @override
  String get idEntryReferenceAttachmentTitle => 'Reference Attachment';

  @override
  String idEntryReferenceAttachmentsAdded(Object count) {
    return '$count reference attachments added.';
  }

  @override
  String get idEntryReferenceLabelCleared => 'Reference label cleared.';

  @override
  String get idEntryReferenceLabelHint =>
      'Optional label (e.g. Front, High quality)';

  @override
  String get idEntryReferenceLabelSaved => 'Reference label saved.';

  @override
  String get idEntryReferenceLabelTitle => 'Reference label';

  @override
  String get idEntryReplace => 'Replace';

  @override
  String get idEntryRequired => 'Required';

  @override
  String get idEntryResidencePermit => 'Residence Permit';

  @override
  String get idEntrySelectClearImageFromGallery =>
      'Select a clear image from gallery.';

  @override
  String get idEntrySelectDate => 'Select date';

  @override
  String get idEntrySelectHolderRelation => 'Select holder relation';

  @override
  String get idEntrySelectImageFromGallery => 'Select image from gallery.';

  @override
  String get idEntrySelectedFilesAlreadyAttached =>
      'Selected files are already attached.';

  @override
  String get idEntryTakeReferencePhoto => 'Take reference photo';

  @override
  String get idEntryThisOptionMobileOnly =>
      'This option is available on mobile only.';

  @override
  String get idEntryUnableAccessCameraLibrary =>
      'Unable to access camera or library.';

  @override
  String get idEntryUnableAccessSelectedPath =>
      'Unable to access selected path.';

  @override
  String get idEntryUnableLoadPreviewImage => 'Unable to load preview image.';

  @override
  String get idEntryUnableProcessImage => 'Unable to process image right now.';

  @override
  String get idEntryUnableReadSelectedImage => 'Unable to read selected image.';

  @override
  String get idEntryUnableSaveDocument => 'Unable to save right now.';

  @override
  String get idEntryUnableSaveSelectedImageLocally =>
      'Unable to save selected image locally.';

  @override
  String get idEntryUnableSelectReferenceAttachment =>
      'Unable to select reference attachment right now.';

  @override
  String get idEntryUseCameraAutoCrop => 'Use camera to capture a clear image.';

  @override
  String get idEntryUseImageForOcr => 'Image selected. OCR is processing.';

  @override
  String get identityRelationDaughter => 'Daughter';

  @override
  String get identityRelationFamily => 'Family';

  @override
  String get identityRelationHusband => 'Husband';

  @override
  String get identityRelationOther => 'Other';

  @override
  String get identityRelationOwner => 'Owner';

  @override
  String get identityRelationParent => 'Parent';

  @override
  String get identityRelationSon => 'Son';

  @override
  String get identityRelationWife => 'Wife';

  @override
  String get passportAddTitle => 'Add Passport';

  @override
  String get passportAiVerified => 'AI Verified';

  @override
  String get passportDesktopUploadHint =>
      'Upload an image on desktop; OCR autofill runs on mobile.';

  @override
  String get passportDetailsExtracted => 'Passport details extracted.';

  @override
  String get passportDetailsTitle => 'Passport Details';

  @override
  String passportDetectedStatus(Object confidence) {
    return 'Scan confidence: $confidence%';
  }

  @override
  String passportDetectedTypeStatus(Object confidence, Object detectedType) {
    return 'Detected $detectedType • confidence $confidence%';
  }

  @override
  String passportDetectedTypeVerify(Object detectedType) {
    return 'Detected $detectedType. Please verify passport fields.';
  }

  @override
  String get passportEncryptedStorage => 'End-to-end encrypted storage';

  @override
  String get passportExtractionFailed => 'Extraction Failed';

  @override
  String get passportExtractionFailedDescription =>
      'We could not automatically scan your document. Enter details manually below.';

  @override
  String get passportRetryScan => 'Retry Scan';

  @override
  String get passportReviewTitle => 'Review Passport';

  @override
  String get passportSaveToSecureVault => 'Save to Secure Vault';

  @override
  String get passportSaveToVault => 'Save to Vault';

  @override
  String get passportScanStatusCancelled => 'Scan cancelled.';

  @override
  String get passportScanStatusFailed => 'Scan failed.';

  @override
  String get passportScanStatusIdle => 'No scan yet.';

  @override
  String get passportScanStatusNoText => 'No text detected.';

  @override
  String get passportScanStatusScanning => 'Scanning...';

  @override
  String get passportScannerMobileOnly =>
      'Scanner is available on mobile only.';

  @override
  String get passportScannerUnavailableDevice =>
      'Scanner is unavailable on this device.';

  @override
  String get passportSelectFile => 'Select File';

  @override
  String get passportTapToEnlarge => 'TAP TO ENLARGE';

  @override
  String get passportUnableSave => 'Unable to save passport right now.';

  @override
  String get passportUnableScan => 'Unable to scan right now.';

  @override
  String get passportUploadDocumentImage => 'Upload Document Image';

  @override
  String get settingsConfigureTargetSection => 'CONFIGURE TARGET';

  @override
  String get settingsEncryptionSection => 'ENCRYPTION';

  @override
  String get settingsResetToDefaults => 'Reset to Defaults';

  @override
  String get settingsSyncTargetSection => 'SYNC TARGET';

  @override
  String get commonMore => 'More';

  @override
  String get commonRemove => 'Remove';

  @override
  String documentDateAdded(Object dateText) {
    return 'Date added: $dateText';
  }

  @override
  String get idEntryTapChooseOrDrag => 'Tap to choose or drag a file.';

  @override
  String get idEntryTapCaptureOrUpload => 'Tap to capture or upload.';

  @override
  String get idEntryUploadFrontSide => 'Upload Front Side';

  @override
  String get idEntryUploadBackSide => 'Upload Back Side';

  @override
  String idEntryCaptureSideCaptured(Object side) {
    return '$side captured';
  }

  @override
  String get idEntryDropImageHere => 'Drop image here';

  @override
  String get idEntryPreviewImageTitle => 'Preview Image';

  @override
  String get idEntryPreviewImageDescription =>
      'Uploaded images are used for OCR. You can also use the front image as preview in details.';

  @override
  String get idEntryUseFrontImageInDetails =>
      'Use uploaded front image in details';

  @override
  String get idEntryPreviewUsesFrontImage =>
      'Preview will use the uploaded front image.';

  @override
  String get idEntryPreviewDisabledNotice => 'Preview is disabled.';

  @override
  String get idEntryUploadFrontFirst =>
      'Upload front side first to enable preview image.';

  @override
  String get idEntryReferenceAttachmentsTitle => 'Reference Attachments';

  @override
  String get idEntryDropFilesNow => 'Drop files now';

  @override
  String get idEntryReferenceAttachmentDescription =>
      'Optional: add high-quality reference image(s) or PDF for future verification.';

  @override
  String idEntryReferenceFilesAttached(Object count) {
    return '$count file(s) attached';
  }

  @override
  String get idEntryAddReferenceImagePdf => 'Add reference image/PDF';

  @override
  String get idEntryEditLabel => 'Edit label';

  @override
  String get idEntryAddLabel => 'Add label';

  @override
  String get idEntryMultipleFilesHint => 'You can attach multiple files.';

  @override
  String get idEntryClearAll => 'Clear all';

  @override
  String get idEntryDateFormatHint => 'MM/DD/YYYY';

  @override
  String get idEntrySelectExpiryDate => 'Select expiry date';

  @override
  String get idEntryDocumentHolder => 'Document Holder';

  @override
  String get idEntryAsShownOnDocument => 'As shown on document';

  @override
  String get idEntryNameFromDocument => 'Name from document';

  @override
  String get idEntryIssuingAuthority => 'Issuing Authority';

  @override
  String get idEntryAuthorityDepartment => 'Department / Authority';

  @override
  String get idEntryOptionalNotes => 'Optional notes';

  @override
  String get idEntryIdDocuments => 'ID Documents';

  @override
  String get idEntryDriversLicense => 'Driver\'s License';

  @override
  String get idEntryDocumentImages => 'Document Images';

  @override
  String get idEntryPassportUploadSubtitle => 'Upload your passport image.';

  @override
  String get idEntryIdentityUploadSubtitle =>
      'Upload front and back of your ID.';

  @override
  String get idEntryResidencePermitUploadSubtitle =>
      'Upload front and back of your residence permit.';

  @override
  String get idEntryDriversLicenseUploadSubtitle =>
      'Upload front and back of your driver\'s license.';

  @override
  String get idEntryDocumentUploadSubtitle => 'Upload document image(s).';

  @override
  String get idEntryPassportInformation => 'Passport Information';

  @override
  String get idEntryIdInformation => 'ID Information';

  @override
  String get idEntryResidencePermitInformation =>
      'Residence Permit Information';

  @override
  String get idEntryDriversLicenseInformation =>
      'Driver\'s License Information';

  @override
  String get idEntryDocumentInformation => 'Document Information';

  @override
  String get idEntryIdNumber => 'ID Number';

  @override
  String get idEntryPermitNumber => 'Permit Number';

  @override
  String get idEntryLicenseNumber => 'License Number';

  @override
  String get idEntryDocumentId => 'Document ID';

  @override
  String get idEntryEnterIdentificationNumber => 'Enter identification number';

  @override
  String get idEntryEnterPermitNumber => 'Enter permit number';

  @override
  String get idEntryReference => 'Reference';

  @override
  String get settingsHeaderTitle => 'Settings';

  @override
  String get settingsHeaderSubtitle =>
      'Manage your offline security and synchronization preferences.';

  @override
  String get settingsViewDocumentation => 'View Documentation';

  @override
  String get settingsSyncStatusLabel => 'SYNC STATUS';

  @override
  String get settingsSyncTargetDisabledSubtitle =>
      'Keep data on this device only';

  @override
  String get settingsSyncTargetLocalSubtitle => 'Sync to file system or NAS';

  @override
  String get settingsSyncTargetDropboxSubtitle =>
      'Secure end-to-end cloud sync';

  @override
  String get settingsLocalStoragePath => 'Local Storage Path';

  @override
  String get settingsLocalStoragePathHint => 'Choose local backup folder path';

  @override
  String get settingsDropboxCredentials => 'Dropbox Credentials';

  @override
  String get settingsDropboxTokenHint => 'Enter Dropbox access token';

  @override
  String get settingsDropboxDirectoryHint => 'Enter Dropbox folder path';

  @override
  String get settingsSyncDisabledHint =>
      'Sync target is disabled. Data stays local.';

  @override
  String get settingsEncryptionDescription =>
      'All data is AES-256 encrypted before sync. Only your passphrase can unlock it.';

  @override
  String get settingsSyncPassphrase => 'Sync Passphrase';

  @override
  String get settingsSyncPassphraseHint => 'Enter sync passphrase';

  @override
  String get settingsPendingChangesTitle => 'Pending Changes';

  @override
  String get settingsPendingChangesSubtitle =>
      'You have unsaved changes to your synchronization settings.';

  @override
  String get settingsSyncNeedsAttention => 'Sync Needs Attention';

  @override
  String get settingsSyncEncryptedReady => 'Encrypted & Ready';

  @override
  String get settingsSyncReadyToStart => 'Ready to Start';

  @override
  String get settingsSyncReadyToSync => 'Ready to Sync';

  @override
  String get settingsLastSyncedNever => 'Last synced: never';

  @override
  String settingsLastSyncedRelative(Object relative) {
    return 'Last synced $relative';
  }

  @override
  String get settingsRelativeJustNow => 'just now';

  @override
  String settingsRelativeMinutesAgo(Object minutes) {
    return '$minutes minutes ago';
  }

  @override
  String settingsRelativeHoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String settingsRelativeDaysAgo(Object days) {
    return '$days days ago';
  }

  @override
  String get settingsSyncing => 'Syncing...';

  @override
  String get settingsSyncNow => 'Sync Now';

  @override
  String get settingsSaveAllSettings => 'Save All Settings';

  @override
  String get documentReferenceFiles => 'REFERENCE FILES';

  @override
  String documentFilesCount(Object count) {
    return '$count files';
  }

  @override
  String get documentPreviewUnavailable => 'Aperçu indisponible';

  @override
  String get documentsUnableLoad => 'Unable to load documents.';

  @override
  String get documentsCategoriesTitle => 'Categories';

  @override
  String get documentsSelectCategory => 'Selectionner la categorie';

  @override
  String get documentsRecentActivityTitle => 'Recent Activity';

  @override
  String get documentsSeeAll => 'See all';

  @override
  String get documentsLibraryTitle => 'Documents Library';

  @override
  String get documentsLibrarySubtitle => 'Manage your secure files offline.';

  @override
  String documentsHeaderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
      zero: 'Aucun document',
    );
    return '$_temp0';
  }

  @override
  String documentsFilesCompact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers',
      one: '1 fichier',
      zero: 'Aucun fichier',
    );
    return '$_temp0';
  }

  @override
  String documentsAttentionCompact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count a verifier',
      one: '1 a verifier',
    );
    return '$_temp0';
  }

  @override
  String get documentsSearchHint => 'Rechercher documents, fichiers, notes';

  @override
  String get documentsRecentFilesTitle => 'Fichiers recents';

  @override
  String get documentsCollectionsEntrySubtitle =>
      'Dossiers dynamiques, notes, docs, depenses';

  @override
  String get documentsBundlesEntrySubtitle =>
      'Packs de partage, dossiers, exports';

  @override
  String get documentsTasksEntrySubtitle => 'Checklists et rappels';

  @override
  String documentsCountLabel(Object count) {
    return '$count Documents';
  }

  @override
  String documentsFilesCountLabel(int count) {
    return '$count fichiers';
  }

  @override
  String documentsUpdatedWithCategory(Object category, Object relative) {
    return 'Updated $relative • $category';
  }

  @override
  String get documentsNoRecentActivity => 'No recent activity yet.';

  @override
  String get documentsRelativeJustNow => 'Just now';

  @override
  String get documentsRelativeYesterday => 'Yesterday';

  @override
  String get documentsCategoryIdentity => 'Identity';

  @override
  String get documentsCategorySubtitleIdentity =>
      'Passeport, ID, permis de conduire';

  @override
  String get documentsCategoryWork => 'Work';

  @override
  String get documentsCategorySubtitleWork => 'Contrats, fiches de paie, taxes';

  @override
  String get documentsCategoryProperty => 'Property';

  @override
  String get documentsCategorySubtitleProperty =>
      'Titres, baux, services publics';

  @override
  String get documentsCategoryAuto => 'Auto';

  @override
  String get documentsCategorySubtitleAuto =>
      'Immatriculation, assurance, service';

  @override
  String get documentsCategoryHealth => 'Health';

  @override
  String get documentsCategorySubtitleHealth =>
      'Ordonnances, dossiers medicaux';

  @override
  String get documentsCategoryTravel => 'Voyage';

  @override
  String get documentsCategorySubtitleTravel =>
      'Voyages, billets, visas, itineraires';

  @override
  String get documentsCategoryOther => 'Other';

  @override
  String get documentsCategorySubtitleOther =>
      'Notes, factures et autres fichiers';

  @override
  String get travelTripsLoadError => 'Impossible de charger les voyages.';

  @override
  String get travelTripsTitle => 'Trips';

  @override
  String get travelTripsFilterUpcoming => 'Upcoming';

  @override
  String get travelTripsFilterPast => 'Past';

  @override
  String travelTripsStatusInDays(int days) {
    return 'DANS $days JOURS';
  }

  @override
  String get travelTripsStatusPlanned => 'PLANIFIE';

  @override
  String get travelTripsDatesLabel => 'DATES';

  @override
  String travelTripsDocumentsCount(int count) {
    return '$count Documents';
  }

  @override
  String get travelTripsViewDetails => 'Voir details';

  @override
  String get travelTripsStartNewTripTitle => 'Commencer un nouveau voyage';

  @override
  String get travelTripsStartNewTripSubtitle => 'PARCOURIR LES DESTINATIONS';

  @override
  String get travelTripsEmptyTitle => 'Aucun voyage';

  @override
  String get travelTripsEmptySubtitle =>
      'Creez votre premier voyage pour planifier le timeline, les depenses et le travel wallet.';

  @override
  String get travelTripsCreateFirstAction => 'Creer le premier voyage';

  @override
  String get travelTripEntryTitle => 'Ajouter un voyage';

  @override
  String get travelTripEditTitle => 'Modifier le voyage';

  @override
  String get travelTripDetailsSectionTitle => 'Détails du voyage';

  @override
  String get travelTripNotesTitle => 'Notes du voyage';

  @override
  String get travelTripEntrySaveAction => 'Enregistrer';

  @override
  String get travelTripEntryTitleField => 'Nom du voyage';

  @override
  String get travelTripEntryTitleHint => 'ex. Summer in Tokyo';

  @override
  String get travelTripEntryDestinationField => 'Destination';

  @override
  String get travelTripEntryDestinationHint => 'ex. Tokyo, Japan';

  @override
  String get travelTripEntryStartDateField => 'Date de debut';

  @override
  String get travelTripEntryEndDateField => 'Date de fin';

  @override
  String get travelTripEntryCoverField => 'Image de couverture';

  @override
  String get travelTripEntryCoverHint => 'Selectionner une image optionnelle';

  @override
  String get travelTripDetailLoadError => 'Impossible de charger ce voyage.';

  @override
  String get travelDashboardSectionTitle => 'Trip Dashboard';

  @override
  String get travelDashboardTimelineTitle => 'Timeline';

  @override
  String travelDashboardTimelineCount(int count) {
    return '$count evenements';
  }

  @override
  String get travelDashboardDestinationsTitle => 'Destinations';

  @override
  String travelDashboardDestinationsCount(int count) {
    return '$count lieux';
  }

  @override
  String get travelDashboardDocumentsTitle => 'Documents';

  @override
  String travelDashboardDocumentsCount(int count) {
    return '$count fichiers';
  }

  @override
  String get travelDashboardExpensesTitle => 'Depenses';

  @override
  String travelDashboardExpensesSpent(String value) {
    return '$value depenses';
  }

  @override
  String get travelDashboardWalletTitle => 'Travel Wallet';

  @override
  String travelDashboardWalletSummary(int count) {
    return '$count documents prets';
  }

  @override
  String get travelDashboardDefaultDestination => 'Votre destination';

  @override
  String travelDashboardDaysLeft(int days) {
    return '$days jours restants';
  }

  @override
  String travelDashboardHeroTitle(String destination) {
    return 'Explorer $destination';
  }

  @override
  String travelTimelineTitle(String trip) {
    return 'Timeline $trip';
  }

  @override
  String get travelTimelineEmptyTitle => 'Aucun evenement';

  @override
  String get travelTimelineEmptySubtitle =>
      'Ajoutez votre premier evenement pour organiser transport, sejour, dining et activites.';

  @override
  String get travelTimelineAddEventTitle => 'Ajouter un evenement';

  @override
  String get travelTimelineAddAction => 'Ajouter au timeline';

  @override
  String get travelTimelineCategoryTravel => 'Travel';

  @override
  String get travelTimelineCategoryStay => 'Stay';

  @override
  String get travelTimelineCategoryDining => 'Dining';

  @override
  String get travelTimelineCategoryActivity => 'Activity';

  @override
  String get travelTimelineCategoryReservation => 'Reservation';

  @override
  String get travelTimelineConfirmed => 'CONFIRME';

  @override
  String travelTimelineDocumentsCount(int count) {
    return '$count Documents';
  }

  @override
  String get travelTimelineOpenMap => 'Ouvrir la carte';

  @override
  String get travelExpensesTitle => 'Depenses du voyage';

  @override
  String get travelExpensesTotalSpentTitle => 'Total depense';

  @override
  String get travelExpensesRemainingTitle => 'Restant';

  @override
  String get travelExpensesVsLastTrip => '~ +12% vs dernier voyage';

  @override
  String travelExpensesBudgetLabel(String value) {
    return 'Budget: $value';
  }

  @override
  String get travelExpensesBudgetStatus => 'STATUT BUDGET';

  @override
  String travelExpensesSpentLabel(String value) {
    return '$value depense';
  }

  @override
  String travelExpensesLimitLabel(String value) {
    return '$value limite';
  }

  @override
  String get travelExpensesEmptyTitle => 'Aucune depense';

  @override
  String get travelExpensesEmptySubtitle =>
      'Ajoutez la premiere depense pour suivre votre budget voyage.';

  @override
  String get travelExpensesAddExpenseTitle => 'Ajouter une depense';

  @override
  String get travelExpensesAddExpenseAction => 'Ajouter depense';

  @override
  String get travelExpensesCategoryFood => 'Food';

  @override
  String get travelExpensesCategoryTransport => 'Transport';

  @override
  String get travelExpensesCategoryActivities => 'Activities';

  @override
  String get travelExpensesCategoryAccommodation => 'Lodging';

  @override
  String get travelExpensesCategoryShopping => 'Shopping';

  @override
  String get travelExpensesCategoryOther => 'Other';

  @override
  String get travelBudgetTitle => 'Definir le budget voyage';

  @override
  String get travelBudgetSaveAction => 'Enregistrer budget';

  @override
  String travelBudgetAllocated(String value) {
    return 'Alloue: $value';
  }

  @override
  String travelBudgetRemaining(String value) {
    return 'Restant: $value';
  }

  @override
  String get travelBudgetBreakdownTitle => 'Repartition du budget';

  @override
  String get travelWalletTitle => 'Travel Wallet';

  @override
  String get travelWalletSectionOther => 'Autres documents';

  @override
  String get travelWalletEmptyTitle => 'Aucun document voyage';

  @override
  String get travelWalletEmptySubtitle =>
      'Ajoutez billets, visas, assurance et confirmations pour un acces rapide.';

  @override
  String get travelWalletAddDocumentAction => 'Ajouter un document';

  @override
  String get travelWalletUploadNewDocumentOption =>
      'Televerser un nouveau document';

  @override
  String get travelWalletChooseFromMyDocumentsOption =>
      'Choisir depuis mes documents';

  @override
  String get travelWalletAddDocumentTitle => 'Ajouter document voyage';

  @override
  String get travelWalletSaveAction => 'Sauvegarder dans wallet';

  @override
  String get travelWalletSelectFile => 'Selectionner fichier';

  @override
  String get travelWalletPickerEmptyTitle => 'Aucun document trouve';

  @override
  String get travelWalletPickerEmptySubtitle =>
      'Ajoutez d\'abord un document dans votre coffre.';

  @override
  String get travelWalletNoExpirationDate => 'Aucune date d\'expiration';

  @override
  String get travelWalletDocumentLinkedSuccess => 'Document lie a ce voyage.';

  @override
  String get propertyHubTitle => 'Property';

  @override
  String get propertyHubFilterAll => 'Tous';

  @override
  String get propertyHubFilterOwned => 'Possede';

  @override
  String get propertyHubFilterRented => 'Loue';

  @override
  String get propertyHubLoadError => 'Impossible de charger les proprietes.';

  @override
  String get propertyHubEmptyTitle => 'Aucune propriete';

  @override
  String get propertyHubEmptySubtitle =>
      'Ajoutez votre premiere propriete pour commencer a organiser votre coffre.';

  @override
  String get propertyHubAddAction => 'Ajouter une propriete';

  @override
  String get propertyEntryAddTitle => 'Add New Property';

  @override
  String get propertyEntryEditTitle => 'Edit Property';

  @override
  String get propertyEntryCardTitle => 'Property Details';

  @override
  String get propertyEntryCardSubtitle =>
      'Provide the basic identification for your new listing.';

  @override
  String get propertyEntryNameLabel => 'Property Name/Nickname';

  @override
  String get propertyEntryNameHint => 'ex. Blue Lagoon Villa';

  @override
  String get propertyEntryNameRequired => 'Le nom de la propriete est requis';

  @override
  String get propertyEntryAddressLabel => 'Adresse complete';

  @override
  String get propertyEntryAddressHint => 'Entrez rue, ville, et code postal';

  @override
  String get propertyEntryAddressRequired => 'L\'adresse complete est requise';

  @override
  String get propertyEntryAddressSearching => 'Recherche d\'adresses...';

  @override
  String get propertyEntryAddressNotFound => 'Aucune adresse valide detectee.';

  @override
  String get propertyEntryAutoDetect => 'Detection automatique';

  @override
  String get propertyEntryCategorizationTitle => 'Categorisation';

  @override
  String get propertyEntryTypeLabel => 'Type de propriete';

  @override
  String get propertyEntryOwnershipLabel => 'Statut de propriete';

  @override
  String get propertyEntryOwnedLabel => 'Possede';

  @override
  String get propertyEntryRentedLabel => 'Loue';

  @override
  String get propertyEntryCreateAction => 'Creer le coffre propriete';

  @override
  String get propertyEntrySaveAction => 'Enregistrer la propriete';

  @override
  String get propertyEntrySaveFailed =>
      'Impossible d\'enregistrer la propriete. Veuillez reessayer.';

  @override
  String get propertyDetailLoadError =>
      'Impossible de charger les details du bien.';

  @override
  String get propertyDetailAssetsTitle => 'Ressources du bien';

  @override
  String propertyDetailTypeSubtitle(String type) {
    return 'Bien $type';
  }

  @override
  String get propertyDetailSubtitleFallback => 'Bien gere';

  @override
  String get propertyDetailAssetDocuments => 'Documents';

  @override
  String get propertyDetailAssetContracts => 'Contrats';

  @override
  String get propertyDetailAssetInsurance => 'Assurance';

  @override
  String get propertyDetailAssetPayments => 'Paiements';

  @override
  String get propertyDetailAssetMaintenance => 'Maintenance';

  @override
  String get propertyDetailAssetOthers => 'Autres';

  @override
  String propertyDetailFilesCount(int count) {
    return '$count fichiers';
  }

  @override
  String propertyDetailRecordsCount(int count) {
    return '$count enregistrements';
  }

  @override
  String propertyDetailActiveRequestsCount(int count) {
    return '$count demandes actives';
  }

  @override
  String propertyDetailLastActivity(String activity, String relative) {
    return 'Derniere activite : $activity $relative';
  }

  @override
  String get propertyDocumentEntryTitle => 'Ajouter un document';

  @override
  String get propertyDocumentInfoSection => 'Informations du document';

  @override
  String get propertyDocumentCategoryLabel => 'Categorie du document';

  @override
  String get propertyDocumentCategoryHint => 'Selectionner une categorie';

  @override
  String get propertyDocumentCategoryRentPayment => 'Paiement de loyer';

  @override
  String get propertyDocumentTitleLabel => 'Titre du document';

  @override
  String get propertyDocumentTitleHint => 'ex. Contrat de location 2024';

  @override
  String get propertyDocumentIssueDateLabel => 'Date d\'emission';

  @override
  String get propertyDocumentFinancialSection =>
      'Details financiers (Optionnel)';

  @override
  String get propertyDocumentAmountPaidLabel => 'Montant paye';

  @override
  String get propertyDocumentAmountPaidHint => '\$ 0.00';

  @override
  String get propertyDocumentAmountPaidNumericHint => '0.00';

  @override
  String get propertyDocumentPaymentDateLabel => 'Date de paiement';

  @override
  String get propertyDocumentSelectFile => 'Selectionner un fichier';

  @override
  String get propertyDocumentUploadHint => 'PDF, JPG ou PNG (Max 10MB)';

  @override
  String get propertyDocumentSaveAction => 'Enregistrer dans le coffre';

  @override
  String get propertyDocumentCategoryRequired =>
      'La categorie du document est requise.';

  @override
  String get propertyDocumentUploadRequired =>
      'Selectionnez d\'abord un PDF ou une image.';

  @override
  String get propertyDocumentTitleRequired =>
      'Le titre du document est requis.';

  @override
  String get propertyDocumentFileTooLarge =>
      'Le fichier doit faire 10MB maximum.';

  @override
  String get propertyDocumentFileMissing => 'Fichier introuvable.';

  @override
  String get propertyDocumentSelectFileFailed =>
      'Impossible de selectionner un fichier pour le moment.';

  @override
  String get propertyDocumentPersistFailed =>
      'Impossible de sauvegarder le fichier selectionne.';

  @override
  String get propertyDocumentSaveFailed =>
      'Impossible d\'enregistrer le document. Veuillez reessayer.';

  @override
  String get propertyDocumentSharedCategoryHint =>
      'La categorie et la date selectionnees seront appliquees a tous les fichiers. Vous pouvez definir un titre pour chaque document ci-dessous.';

  @override
  String get propertyDocumentSelectedDocumentsTitle => 'Documents selectionnes';

  @override
  String propertyDocumentSelectedDocumentLabel(int index) {
    return 'Document $index';
  }

  @override
  String get commonLanguageEnglish => 'Anglais';

  @override
  String get identityUnableLoadSecureIds => 'Unable to load secure IDs.';

  @override
  String get identityYourDocumentsTitle => 'Your Documents';

  @override
  String identitySecureIdsStored(Object count) {
    return '$count secure IDs stored';
  }

  @override
  String get identityAllIdentities => 'All identities';

  @override
  String get documentsArchived => 'Document archived.';

  @override
  String get documentsDeleted => 'Document deleted.';

  @override
  String get documentsUnableRemove => 'Unable to remove document.';

  @override
  String get identityVaultIdentityFallback => 'Vault Identity';

  @override
  String identityIssuedBy(Object country) {
    return 'Issued by $country';
  }

  @override
  String identityExpiryShort(Object date) {
    return 'Exp. $date';
  }

  @override
  String identityAddedDate(Object date) {
    return 'Added $date';
  }

  @override
  String get identityNoIdsYet => 'No IDs yet';

  @override
  String get identityAddFirstDescription =>
      'Add your first ID document to start building your secure identity vault.';

  @override
  String get identityAddFirstId => 'Add First ID';

  @override
  String get identityStatusValid => 'Valid';

  @override
  String get identityStatusExpiringSoon => 'Expiring Soon';

  @override
  String get identityStatusExpired => 'Expire';

  @override
  String get identityFilterTooltip => 'Filtrer';

  @override
  String get identityFilterSheetTitle => 'Filtrer les documents d\'identite';

  @override
  String get identityFilterSheetSubtitle =>
      'Choisissez les identites securisees a afficher.';

  @override
  String get identityIntroEyebrow => 'Documents · Identite';

  @override
  String get identityHolderSingular => 'titulaire';

  @override
  String get identityHolderPlural => 'titulaires';

  @override
  String get identityNoPrimaryIdentity => 'Aucune identite principale definie.';

  @override
  String identityPrimaryIdentitySet(String document) {
    return '$document defini comme principal.';
  }

  @override
  String get identitySearchHint => 'Rechercher par numero, pays, titulaire...';

  @override
  String get identityAllHolders => 'Tous les titulaires';

  @override
  String get identityPrimaryBadge => 'Principal';

  @override
  String identityNoDocumentsForFilter(String filter) {
    return 'Aucun document $filter';
  }

  @override
  String get identityFilteredEmptyDescription =>
      'Essayez une autre vue ou ajoutez une nouvelle piece d\'identite.';

  @override
  String get identityClearSearch => 'Effacer la recherche';

  @override
  String get identityFilterAll => 'Tout';

  @override
  String get identityFilterPersonal => 'Personnel';

  @override
  String get identityFilterTravel => 'Voyage';

  @override
  String get identityStatusOk => 'OK';

  @override
  String identityStatusDaysLeft(int days) {
    return '$days j';
  }

  @override
  String identityDocumentNumberPrefix(String number) {
    return 'No. $number';
  }

  @override
  String get identityDetailFileMissingTitle => 'Fichier manquant';

  @override
  String get identityDetailFileMissingDescription =>
      'Les metadonnees sont enregistrees, mais le scan n\'est pas disponible sur cet appareil.';

  @override
  String identityDetailPagesCount(int count) {
    return '$count pages';
  }

  @override
  String get identityDetailSectionDocument => 'Document';

  @override
  String get identityDetailSectionHolder => 'Titulaire';

  @override
  String get identityDetailSectionOtherDetails => 'Autres details';

  @override
  String get identityDetailStatusExpiring => 'Expire bientot';

  @override
  String identityDetailStatusExpiresIn(int days) {
    return 'Expire dans $days j';
  }

  @override
  String get identityFieldDocumentNumber => 'Numero du document';

  @override
  String get identityFieldIssuingCountry => 'Pays emetteur';

  @override
  String get identityFieldExpires => 'Expire';

  @override
  String get identityFieldNationality => 'Nationalite';

  @override
  String get identityFieldGivenName => 'Prenom';

  @override
  String get identityFieldFamilyName => 'Nom';

  @override
  String get identityFieldDateOfBirth => 'Date de naissance';

  @override
  String get identityFieldSex => 'Sexe';

  @override
  String get identityFieldHolder => 'Titulaire';

  @override
  String get identityFieldAgeOver18 => 'Age superieur a 18 ans';

  @override
  String get idEntryAttachmentSection => 'Piece jointe';

  @override
  String get idEntryAddIdentityDocumentEyebrow =>
      'Ajouter un document d\'identite';

  @override
  String get idEntryEditIdentityDocumentEyebrow =>
      'Modifier le document d\'identite';

  @override
  String get commonManage => 'Manage';

  @override
  String get workHubLoadError => 'Unable to load work vaults.';

  @override
  String get workHubTitle => 'Work Hub';

  @override
  String get workHubSubtitle => 'Secure document vault';

  @override
  String get workHubSearchHint => 'Search companies or contracts';

  @override
  String get workHubFilterAll => 'All Companies';

  @override
  String get workHubFilterRecent => 'Recent';

  @override
  String get workHubFilterPinned => 'Pinned';

  @override
  String get workHubVaultSectionTitle => 'Your Secure Vaults';

  @override
  String workHubCompaniesCountBadge(int count) {
    return '$count Companies';
  }

  @override
  String get workHubFeaturedLabel => 'NEW FEATURE';

  @override
  String get workHubFeaturedTitle => 'Global Payslips';

  @override
  String get workHubFeaturedSubtitle =>
      'Securely access and manage your entire earnings history across all associated companies.';

  @override
  String get workHubFeaturedSubtitleCompact =>
      'Accedez a votre historique complet';

  @override
  String get workHubFeaturedAction => 'See All Payslips';

  @override
  String workHubDocumentsCountCompact(int count) {
    return '$count documents';
  }

  @override
  String workHubUpdatedCompact(String relative) {
    return 'Mis a jour $relative';
  }

  @override
  String workHubCompanySubtitle(int count, String relative) {
    return '$count Documents • Last updated $relative';
  }

  @override
  String get workHubEmptyTitle => 'No work vaults yet';

  @override
  String get workHubEmptySubtitle =>
      'Add your first company record to start organizing work contracts, payslips, and tax forms.';

  @override
  String get workHubAddFirstCompanyAction => 'Add First Company';

  @override
  String get workHubNoAccessYet => 'No access yet';

  @override
  String get workCompanyTitleFallback => 'Work Company';

  @override
  String get workCompanyLoadError => 'Unable to load company details.';

  @override
  String get workCompanyVaultTitle => 'Coffre entreprise';

  @override
  String get workCompanyVaultSubtitle =>
      'Acces securise a vos documents professionnels';

  @override
  String get workCompanyStorageUsed => 'STORAGE USED';

  @override
  String get workCompanyLastAccess => 'LAST ACCESS';

  @override
  String get workCompanyFoldersTitle => 'Document Folders';

  @override
  String get workCompanyFolderPayslipsTitle => 'Fiches de paie';

  @override
  String get workCompanyFolderContractsTitle => 'Contrats';

  @override
  String get workCompanyFolderTaxFormsTitle => 'Documents fiscaux';

  @override
  String get workCompanyFolderOffboardingTitle => 'Sortie';

  @override
  String get workCompanyFolderBenefitsTitle => 'Avantages';

  @override
  String get workCompanyFolderMilestonesTitle => 'Etapes';

  @override
  String get workCompanyFolderOtherTitle => 'Autres types';

  @override
  String get workCompanyFolderPayslipsSubtitle =>
      'Releves mensuels de remuneration';

  @override
  String get workCompanyFolderContractsSubtitle =>
      'Contrats de travail et accords IP';

  @override
  String get workCompanyFolderTaxFormsSubtitle =>
      'Syntheses annuelles et formulaires fiscaux';

  @override
  String get workCompanyFolderOffboardingSubtitle =>
      'Documents et procedures de sortie';

  @override
  String get workCompanyFolderBenefitsSubtitle =>
      'Couverture assurance et avantages';

  @override
  String get workCompanyFolderMilestonesSubtitle => 'Promotions et evaluations';

  @override
  String get workCompanyFolderOtherSubtitle =>
      'Documents professionnels supplementaires';

  @override
  String get workCompanyRecentDocumentsTitle => 'DOCUMENTS RECENTS';

  @override
  String workCompanyRecentModified(String relative) {
    return 'Modifie $relative';
  }

  @override
  String get workCompanyRecentEmptyTitle => 'Aucun document recent';

  @override
  String get workCompanyRecentEmptySubtitle =>
      'Les documents ajoutes a ce coffre entreprise apparaitront ici.';

  @override
  String get workEntryAddTitle => 'Add Work Record';

  @override
  String get workEntryEditTitle => 'Edit Work Record';

  @override
  String get workEntrySectionCompany => 'COMPANY DETAILS';

  @override
  String get workEntryCompanyNameLabel => 'Company Name';

  @override
  String get workEntryCompanyNameHint => 'e.g. Stripe Inc.';

  @override
  String get workEntryFolderTypeLabel => 'Folder Type';

  @override
  String get workEntryRecordTitleLabel => 'Record Title';

  @override
  String get workEntryRecordTitleHint => 'e.g. December Earnings';

  @override
  String get workEntryEmployeeIdLabel => 'Employee ID';

  @override
  String get workEntryEmployeeIdHint => 'e.g. 882910';

  @override
  String get workEntryRoleLabel => 'Role';

  @override
  String get workEntryRoleHint => 'e.g. Sr. Engineer';

  @override
  String get workEntryLocationLabel => 'Location';

  @override
  String get workEntryLocationHint => 'e.g. San Francisco';

  @override
  String get workEntryNetAmountLabel => 'Net Amount';

  @override
  String get workEntryNetAmountHint => 'e.g. \$4,250.00';

  @override
  String get workEntryStatementDateLabel => 'Statement Date';

  @override
  String get workEntryStatementDateHint => 'Select date';

  @override
  String get workEntryNotesLabel => 'Notes';

  @override
  String get workEntryNotesHint => 'Optional notes...';

  @override
  String get workEntryPinCompany => 'Pin this company';

  @override
  String get workEntryPinCompanyHint =>
      'Pinned companies appear in quick filters.';

  @override
  String get workStatementsSubtitle => 'Payroll Vault';

  @override
  String get workStatementsAllYears => 'All';

  @override
  String get workStatementsRecentTitle => 'RECENT STATEMENTS';

  @override
  String workStatementsArchivedCount(int count) {
    return '$count archived';
  }

  @override
  String get workStatementsStatusVerified => 'Verified';

  @override
  String get workStatementsNetTakeHome => 'NET TAKE-HOME';

  @override
  String get workStatementsArchiveOnly => 'Archive only';

  @override
  String get workStatementsViewSlip => 'View Statement';

  @override
  String get workStatementsEmptyTitle => 'No statements found';

  @override
  String get workStatementsEmptySubtitle =>
      'Try a different year or add a new work record.';

  @override
  String get workEntrySelectCompanyFirst =>
      'Sélectionnez d\'abord une entreprise.';

  @override
  String get workDocumentEntryTitle => 'Ajouter un document';

  @override
  String get workDocumentEntryCategories => 'CATÉGORIES TRAVAIL';

  @override
  String get workDocumentEntryTargetVault => 'COFFRE CIBLE';

  @override
  String get workPayslipAddTitle => 'Ajouter une fiche de paie';

  @override
  String get workPayslipSectionPaymentMonth => 'MOIS DE PAIEMENT';

  @override
  String get workPayslipSectionNetSalary => 'SALAIRE NET';

  @override
  String get workPayslipOptional => 'Optionnel';

  @override
  String get workPayslipSectionUploadMethods => 'MÉTHODES D\'IMPORT';

  @override
  String get workPayslipMethodScanTitle => 'Scanner la fiche de paie';

  @override
  String get workPayslipMethodScanSubtitle => 'Propulsé par l\'extraction IA';

  @override
  String get workPayslipMethodUploadPdfTitle => 'Importer un PDF ou une image';

  @override
  String get workPayslipMethodUploadPdfSubtitle =>
      'Choisir depuis fichiers, galerie ou camera';

  @override
  String get workPayslipMethodManualTitle => 'Saisie manuelle';

  @override
  String get workPayslipMethodManualSubtitle =>
      'Renseigner les détails manuellement';

  @override
  String get workPayslipSectionTargetVault => 'COFFRE CIBLE';

  @override
  String get workPayslipTargetVaultSubtitle => 'Coffre entreprise géré';

  @override
  String get workPayslipSelectCompanyPlaceholder => 'Choisir une entreprise';

  @override
  String get workPayslipNoCompanyAvailable =>
      'Aucune entreprise creee pour le moment.';

  @override
  String get workPayslipPickCamera => 'Prendre une photo';

  @override
  String get workPayslipUnableSaveFileLocally =>
      'Impossible d\'enregistrer localement le fichier selectionne.';

  @override
  String get workPayslipUnableSelectFile =>
      'Impossible de selectionner un fichier pour l\'instant.';

  @override
  String get workPayslipSelectFileFirst =>
      'Selectionnez d\'abord un PDF ou une image.';

  @override
  String get workPayslipNetSalaryHint => '0.00';

  @override
  String get workPayslipHistoryTitle => 'Historique des fiches de paie';

  @override
  String get workPayslipHistoryRecentDocuments => 'DOCUMENTS RECENTS';

  @override
  String workPayslipHistoryItemsCount(int count) {
    return '$count elements';
  }

  @override
  String get workPayslipHistoryNetPay => 'Net a payer';

  @override
  String get workPayslipHistoryLoadOlder => 'Charger les fiches plus anciennes';

  @override
  String get workPayslipHistoryAllLoaded =>
      'Toutes les fiches de paie sont chargees.';

  @override
  String get workPayslipHistoryNoDataTitle => 'Aucune fiche de paie';

  @override
  String get workPayslipHistoryNoDataSubtitle =>
      'Vos fiches de paie apparaitront ici.';

  @override
  String get workPayslipHistorySearchHint => 'Rechercher des fiches de paie...';

  @override
  String get workPayslipHistorySearchButton => 'Rechercher';

  @override
  String get workPayslipHistorySearchApply => 'Appliquer';

  @override
  String get workPayslipHistorySearchClear => 'Effacer';

  @override
  String get workManualEntryAddTitle => 'Ajouter un document de travail';

  @override
  String get workManualEntryEditTitle => 'Modifier le document de travail';

  @override
  String get workManualEntrySectionDocumentDetails => 'Details du document';

  @override
  String get workManualEntryDocumentTypeLabel => 'Type de document';

  @override
  String get workManualEntrySharedTypeHint =>
      'Le type selectionne et l\'assignation au coffre seront appliques a tous les fichiers. Definissez un titre pour chaque document ci-dessous.';

  @override
  String get workManualEntryAssignVaultLabel =>
      'Assigner au coffre (employeur)';

  @override
  String get workManualEntryDocumentTitleLabel => 'Titre du document';

  @override
  String get workManualEntrySectionSelectedDocuments =>
      'Documents selectionnes';

  @override
  String get workManualEntryDocumentTitleHint => 'ex. Fiche de paie avril 2026';

  @override
  String workManualEntrySelectedDocumentLabel(int index) {
    return 'Document $index';
  }

  @override
  String get workManualEntrySectionTimeline => 'Chronologie';

  @override
  String get workManualEntryEffectiveDateLabel => 'Date d\'effet';

  @override
  String get workManualEntryExpiryDateLabel => 'Date d\'expiration';

  @override
  String get workManualEntryDatePlaceholder => 'mm/jj/aaaa';

  @override
  String get workManualEntryOngoingLabel => 'En cours / Permanent';

  @override
  String get workManualEntryOngoingHint => 'Pas de date d\'expiration fixe';

  @override
  String get workManualEntrySectionNotes => 'Notes du document';

  @override
  String get workManualEntryLabelFieldLabel => 'Libellé (Optionnel)';

  @override
  String get workManualEntryLabelHint =>
      'ex. Mars 2026, Rapport T1, Copie signée...';

  @override
  String get workManualEntryNotesFieldLabel =>
      'Conditions du contrat ou notes internes';

  @override
  String get workManualEntryNotesHint =>
      'Mentionnez les clauses importantes, details salariaux ou points de revue...';

  @override
  String get workManualEntryUploadTitle => 'Importer le fichier original';

  @override
  String get workManualEntryUploadSubtitle =>
      'PDF, Word, Excel, PPT, images & plus (max 10 Mo)';

  @override
  String get workManualEntryAddButton => 'Ajouter le document de travail';

  @override
  String get workManualEntrySelectUploadFirst =>
      'Importez d\'abord un PDF ou une image.';

  @override
  String get workManualEntryFileTooLarge =>
      'Le fichier depasse 10 Mo. Choisissez un fichier plus petit.';

  @override
  String get workManualEntryTypeEmploymentContract => 'Contrat de travail';

  @override
  String get workManualEntryTypeEmployerCertificate => 'Attestation employeur';

  @override
  String get workManualEntryTypeInternshipAgreement => 'Convention de stage';

  @override
  String get workManualEntryTypeTaxDeclaration => 'Declaration fiscale';

  @override
  String get workManualEntryTypeTaxCertificate => 'Certificat fiscal';

  @override
  String get workManualEntryTypeBenefitsEnrollment => 'Adhesion aux avantages';

  @override
  String get workManualEntryTypeInsuranceCoverage => 'Couverture assurance';

  @override
  String get workManualEntryTypeResignationLetter => 'Lettre de démission';

  @override
  String get workManualEntryTypeTerminationNotice => 'Avis de fin de contrat';

  @override
  String get workManualEntryTypeFinalSettlement => 'Solde de tout compte';

  @override
  String get workManualEntryTypeEndOfServiceCert =>
      'Certificat de fin de service';

  @override
  String get workManualEntryTypeNonCompete => 'Clause de non-concurrence';

  @override
  String get workManualEntryTypeSalarySlip => 'Bulletin de salaire';

  @override
  String get workManualEntryTypeReferenceLetter => 'Lettre de recommandation';

  @override
  String get workManualEntryTypePerformanceReview =>
      'Évaluation de performance';

  @override
  String get workManualEntryTypePromotionLetter => 'Lettre de promotion';

  @override
  String get workManualEntryTypeTrainingCert => 'Certificat de formation';

  @override
  String get workManualEntryTypeQuittance => 'Quittance de loyer';

  @override
  String get workManualEntryTypeOther => 'Autre document de travail';

  @override
  String workPayslipTitleTemplate(String month) {
    return 'Fiche de paie $month';
  }

  @override
  String get workFolderHistoryContractsAndLegal => 'Contrats et legal';

  @override
  String workFolderHistoryAllDocuments(int count) {
    return 'TOUS LES DOCUMENTS ($count)';
  }

  @override
  String get workFolderHistorySort => 'Trier';

  @override
  String get workFolderHistorySortNewest => 'Plus recents';

  @override
  String get workFolderHistorySortOldest => 'Plus anciens';

  @override
  String get workFolderHistorySortTitle => 'Titre A-Z';

  @override
  String workFolderHistoryAdded(String date, String size) {
    return 'Ajoute: $date • $size';
  }

  @override
  String get workFolderHistorySearchTitle => 'Rechercher';

  @override
  String get workFolderHistorySearchHint => 'Rechercher des documents...';

  @override
  String get workFolderHistoryNoDocumentsTitle => 'Aucun document';

  @override
  String get workFolderHistoryNoDocumentsSubtitle =>
      'Les documents de ce dossier apparaitront ici.';

  @override
  String get collectionDetailFolderTitle => 'Détails du dossier';

  @override
  String get collectionDetailDocumentTitle => 'Détails du document';

  @override
  String get collectionDetailNoteTitle => 'Détails de la note';

  @override
  String get collectionDetailInputTitle => 'Détails du champ';

  @override
  String get collectionDetailChecklistTitle => 'Détails de la checklist';

  @override
  String get collectionDetailLinkTitle => 'Détails du lien';

  @override
  String get collectionDetailImageTitle => 'Détails de l\'image';

  @override
  String get collectionDetailExpenseTitle => 'Détails de la dépense';

  @override
  String get collectionDetailTimelineTitle => 'Détails de l\'événement';

  @override
  String get collectionDetailLocationTitle => 'Détails du lieu';

  @override
  String get collectionDetailSectionTitle => 'Détails de la section';

  @override
  String get collectionDetailActions => 'ACTIONS';

  @override
  String get collectionDetailTaskList => 'LISTE DES TÂCHES';

  @override
  String get collectionDetailDescription => 'DESCRIPTION';

  @override
  String get collectionDetailAttachment => 'PIÈCE JOINTE';

  @override
  String get collectionDetailCompletionProgress => 'Progression';

  @override
  String get collectionDetailShareDocument => 'Partager le document';

  @override
  String get collectionDetailPreview => 'Aperçu';

  @override
  String get collectionDetailDownload => 'Télécharger';

  @override
  String get collectionDetailOpenLink => 'Ouvrir le lien';

  @override
  String get collectionDetailEditImage => 'Modifier l\'image';

  @override
  String get collectionDetailOpenInMaps => 'Ouvrir dans Plans';

  @override
  String get collectionDetailMovePrintPdf => 'Imprimer le PDF';

  @override
  String get collectionDetailMoveToCollection => 'Déplacer vers une collection';

  @override
  String get collectionDetailShareLink => 'Partager le lien';

  @override
  String get collectionDetailShare => 'Partager';

  @override
  String get collectionDetailDeleteLink => 'Supprimer le lien';

  @override
  String get collectionDetailDeleteFolder => 'Supprimer le dossier';

  @override
  String get collectionDetailDeleteSection => 'Supprimer la section';

  @override
  String get collectionDetailDeleteChecklist => 'Supprimer la checklist';

  @override
  String get collectionDetailRemove => 'Retirer';

  @override
  String get collectionDetailDelete => 'Supprimer';

  @override
  String get collectionDetailEdit => 'Modifier';

  @override
  String get collectionDetailRearrange => 'Réorganiser';

  @override
  String get collectionDetailDeleteBlockTitle => 'Supprimer le bloc';

  @override
  String get collectionDetailDeleteBlockMessage =>
      'Cette action est irréversible.';

  @override
  String get collectionDetailCancel => 'Annuler';

  @override
  String get collectionDetailDateNotSet => 'Date non définie';

  @override
  String get collectionDetailTimeNotSet => 'Heure non définie';

  @override
  String get collectionDetailNoLocationSet => 'Aucun lieu défini';

  @override
  String get collectionDetailNoFileAttached => 'Aucun fichier joint';

  @override
  String get collectionDetailFileNotFound => 'Fichier introuvable';

  @override
  String collectionDetailTaskCount(int done, int total) {
    return '$done sur $total tâches';
  }

  @override
  String get collectionDetailPreviewAvailable => 'APERÇU DISPONIBLE';

  @override
  String collectionDetailItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'éléments',
      one: 'élément',
    );
    return '$count $_temp0';
  }

  @override
  String collectionDetailFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dossiers',
      one: 'dossier',
    );
    return '$count $_temp0';
  }

  @override
  String collectionDetailReminderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rappels',
      one: 'rappel',
    );
    return '$count $_temp0';
  }

  @override
  String get collectionEntryDocumentInfo => 'INFORMATIONS DU DOCUMENT';

  @override
  String get collectionEntryDetails => 'DÉTAILS';

  @override
  String get collectionEntrySource => 'SOURCE';

  @override
  String get collectionEntryChange => 'Changer';

  @override
  String get collectionEntrySecuritySettings => 'PARAMÈTRES DE SÉCURITÉ';

  @override
  String get collectionEntryChooseIcon => 'CHOISIR UNE ICÔNE';

  @override
  String get collectionEntrySearchIcon => 'Rechercher une icône';

  @override
  String get collectionEntryUseEmoji => 'Utiliser un emoji';

  @override
  String get collectionEntryPickLocalImage => 'Choisir une image locale';

  @override
  String get collectionEntryLocalImageSelected => 'Image locale selectionnee';

  @override
  String get collectionEntryEmojiSelected => 'Emoji selectionne';

  @override
  String get collectionEntryBlockIconHint =>
      'Recherchez un symbole, choisissez une image locale ou utilisez un emoji.';

  @override
  String get collectionEntryNoIconsFound => 'Aucune icone correspondante.';

  @override
  String get collectionEntryEmojiHint => 'Emoji ou libelle court';

  @override
  String get collectionEntryLocationDetails => 'DÉTAILS DU LIEU';

  @override
  String get collectionEntryLocationSearchSection => 'RECHERCHE';

  @override
  String get collectionEntryLocationResult => 'RÉSULTAT';

  @override
  String get collectionEntryLocationResultMap => 'RÉSULTAT · CARTE';

  @override
  String get collectionEntryLocationSuggestions => 'SUGGESTIONS';

  @override
  String get collectionEntryLocationLabelField => 'LIBELLÉ';

  @override
  String get collectionEntryLocationAddressField => 'ADRESSE';

  @override
  String get collectionEntryLocationLatitude => 'LAT';

  @override
  String get collectionEntryLocationLongitude => 'LONG';

  @override
  String get collectionEntryLocationNoResultSelected =>
      'Sélectionnez un lieu pour prévisualiser la carte.';

  @override
  String get collectionEntryLocationMapsHelp =>
      'Ouvrez dans Plans depuis la page de détail.';

  @override
  String get collectionEntryCurrency => 'DEVISE';

  @override
  String get collectionEntryDate => 'DATE';

  @override
  String get collectionEntryCategory => 'CATÉGORIE';

  @override
  String get collectionEntryReceipt => 'REÇU';

  @override
  String get collectionEntryCurrentSelection => 'SÉLECTION ACTUELLE';

  @override
  String get collectionEntryFolderName => 'Nom du dossier';

  @override
  String get collectionEntrySectionName => 'Nom de la section';

  @override
  String get collectionEntryDocumentTitle => 'Titre du document';

  @override
  String get collectionEntryEventTitle => 'Titre de l\'événement';

  @override
  String get collectionEntryEventType => 'Type d\'événement';

  @override
  String get collectionEntryDateTime => 'Date et heure';

  @override
  String get collectionEntryFieldType => 'Type de champ';

  @override
  String get collectionEntryPasteOrType => 'Coller ou saisir';

  @override
  String get collectionEntryPreviewFetched => 'APERÇU · RÉCUPÉRÉ';

  @override
  String get collectionEntryPreviewFetching => 'APERÇU · RÉCUPÉRATION';

  @override
  String get collectionEntryTitleOverride => 'Titre · Remplacement';

  @override
  String get collectionEntryInputTypeSection => 'TYPE';

  @override
  String get collectionEntryInputFieldSection => 'CHAMP';

  @override
  String get collectionEntryInputPreviewCopy => 'APERÇU · TOUCHER POUR COPIER';

  @override
  String get collectionEntryInputCopyAction => 'copier';

  @override
  String get collectionEntryInputCopyHelp =>
      'La copie au toucher est disponible pour les types texte court, nombre, téléphone et URL.';

  @override
  String get collectionEntryLabel => 'Libellé';

  @override
  String get collectionEntryValue => 'Valeur';

  @override
  String get collectionEntryTitle => 'Titre';

  @override
  String get collectionEntryDescription => 'Description';

  @override
  String get collectionEntryDescriptionOptional => 'Description (optionnel)';

  @override
  String get collectionEntryCollapsedByDefault => 'Repliée par défaut';

  @override
  String get collectionEntryUrl => 'URL';

  @override
  String get collectionEntryLocation => 'Lieu';

  @override
  String get collectionEntryExpiryDate => 'Date d\'expiration';

  @override
  String get collectionEntryNoteContent => 'Contenu de la note';

  @override
  String get collectionEntryNotes => 'Notes';

  @override
  String get collectionEntryNotesOptional => 'Notes (optionnel)';

  @override
  String get collectionEntrySecurityLevel => 'Niveau de sécurité';

  @override
  String get collectionEntryAmount => 'Montant';

  @override
  String get collectionEntryChecklistIdentity => 'Identité de la checklist';

  @override
  String get collectionEntryTaskItems => 'Éléments de tâche';

  @override
  String get collectionEntrySearchPlace => 'Rechercher un lieu';

  @override
  String get collectionEntryHintFolderName => 'ex. Itinéraire';

  @override
  String get collectionEntryHintFolderDesc =>
      'Organisez les éléments de votre espace de travail';

  @override
  String get collectionEntryHintSectionName => 'ex. Documents importants';

  @override
  String get collectionEntryHintSectionDesc =>
      'Décrivez le contenu de cette section...';

  @override
  String get collectionEntryHintDocTitle => 'ex. Passeport 2024';

  @override
  String get collectionEntryHintDocumentNotes =>
      'Source, contexte ou notes sur ce fichier...';

  @override
  String get collectionEntryHintEventTitle =>
      'ex. État des lieux avec le propriétaire';

  @override
  String get collectionEntryHintLocation => 'ex. Parc Riverside';

  @override
  String get collectionEntryHintLocationLabel =>
      'ex. Appartement — Rue de Lille';

  @override
  String get collectionEntryHintUrl => 'https://example.com';

  @override
  String get collectionEntryHintAutoTitle =>
      'Récupération automatique du titre...';

  @override
  String get collectionEntryHintLinkDesc =>
      'Ajoutez une brève description du lien';

  @override
  String get collectionEntryHintFieldLabel => 'ex. Numéro de série';

  @override
  String get collectionEntryHintFieldValue => 'Saisissez le contenu du champ';

  @override
  String get collectionEntryHintChecklist => 'ex. Voyage d\'été en Europe';

  @override
  String get collectionEntryHintNoteContent =>
      'Commencez à saisir votre note sécurisée...';

  @override
  String get collectionEntryHintEventDesc =>
      'Apporter l\'inventaire imprimé · 2 copies';

  @override
  String get collectionEntryHintImageNotes =>
      'Ajoutez du contexte ou des notes sécurisées...';

  @override
  String get collectionEntryHintImageTitle => 'Donnez un nom à votre entrée';

  @override
  String get collectionEntryHintAddress => '1200 Avenue of the Americas, NY';

  @override
  String get collectionEntryHintTagLabels => 'ex. Travail, Réserve secrète';

  @override
  String get collectionEntryHintChecklistItem => 'Élément de la checklist';

  @override
  String get collectionEntryHintAddTask => 'Ajouter une autre tâche...';

  @override
  String get collectionEntryHideField => 'Masquer le champ dans la vue coffre';

  @override
  String get collectionEntryEnableQuickCopy => 'Activer la copie rapide';

  @override
  String get collectionEntryNewEntry => 'Nouvelle entrée';

  @override
  String get collectionEntryNewEntrySubtitle =>
      'Sécurisation de votre nouvelle ressource dans le coffre.';

  @override
  String get collectionEntryPreviewLabel => 'APERÇU';

  @override
  String get collectionEntryPreviewHint =>
      'L\'aperçu sera généré automatiquement lorsqu\'une URL valide sera ajoutée.';

  @override
  String get collectionEntryLoadingPreview => 'Chargement de l\'aperçu...';

  @override
  String get collectionEntrySuggestedTasks => 'Tâches suggérées';

  @override
  String get collectionEntryEncryptedNote =>
      'Cette note sera chiffrée et stockée en toute sécurité dans votre coffre privé.';

  @override
  String get collectionEntryValidationTitle =>
      'Veuillez remplir le champ titre requis.';

  @override
  String collectionEntryItemsCount(int count) {
    return '$count éléments';
  }

  @override
  String get collectionEntryAddFolder => 'Ajouter un dossier';

  @override
  String get collectionEntryEditFolder => 'Modifier le dossier';

  @override
  String get collectionEntryAddSection => 'Ajouter une section';

  @override
  String get collectionEntryEditSection => 'Modifier la section';

  @override
  String get collectionEntryAddDocument => 'Ajouter un document';

  @override
  String get collectionEntryAddNote => 'Ajouter une note';

  @override
  String get collectionEntryEditNote => 'Modifier la note';

  @override
  String get collectionEntryAddInput => 'Ajouter un champ';

  @override
  String get collectionEntryAddChecklist => 'Nouvelle checklist';

  @override
  String get collectionEntryAddLink => 'Ajouter un lien';

  @override
  String get collectionEntryEditLink => 'Modifier le lien';

  @override
  String get collectionEntryAddImage => 'Ajouter une image';

  @override
  String get collectionEntryAddExpense => 'Ajouter une dépense';

  @override
  String get collectionEntryAddEvent => 'Ajouter un événement';

  @override
  String get collectionEntryEditEvent => 'Modifier l\'événement';

  @override
  String get collectionEntryAddLocation => 'Ajouter un lieu';

  @override
  String get collectionEntryEditLocation => 'Modifier le lieu';

  @override
  String get collectionEntryReplaceFile => 'Remplacer';

  @override
  String get collectionEntrySourceFiles => 'Fichiers';

  @override
  String get collectionEntrySourcePhotos => 'Photos';

  @override
  String get collectionEntrySourceScan => 'Scanner';

  @override
  String get collectionEntrySaveVault => 'Enregistrer au coffre';

  @override
  String get collectionEntrySaveNote => 'Enregistrer la note';

  @override
  String get collectionEntrySaveField => 'Enregistrer le champ';

  @override
  String get collectionEntrySaveChecklist => 'Enregistrer la checklist';

  @override
  String get collectionEntrySaveLink => 'Enregistrer le lien';

  @override
  String get collectionEntrySaveImage => 'Enregistrer l\'image';

  @override
  String get collectionEntrySaveExpense => 'Enregistrer la dépense';

  @override
  String get collectionEntrySaveEvent => 'Enregistrer l\'événement';

  @override
  String get collectionEntryCreateFolder => 'Créer le dossier';

  @override
  String get collectionEntryCreateSection => 'Créer la section';

  @override
  String get collectionEntryUploadDocument => 'Télécharger un document';

  @override
  String get collectionEntryUploadImage => 'Télécharger une image';

  @override
  String get collectionEntryUploadReceipt => 'Télécharger un reçu';

  @override
  String get collectionEntryUploadFiles => 'Appuyez pour télécharger';

  @override
  String get collectionEntryUploadDefault => 'Télécharger';

  @override
  String get collectionEntryUploadDocHint =>
      'Glissez-déposez votre fichier ici ou appuyez pour parcourir';

  @override
  String get collectionEntryUploadImageHint =>
      'Appuyez pour sélectionner depuis la galerie';

  @override
  String get collectionEntryUploadReceiptHint =>
      'PNG, JPG ou PDF jusqu\'à 10 Mo';

  @override
  String get collectionEntryUploadFileHint =>
      'PDF, DOCX ou images jusqu\'à 10 Mo';

  @override
  String get collectionEntrySelectFile => 'Sélectionner un fichier';

  @override
  String get collectionDashboardKind => 'Collection';

  @override
  String get collectionDashboardDone => 'Terminé';

  @override
  String get collectionDashboardEmptyState =>
      'Aucun élément. Appuyez sur Ajouter un bloc pour commencer.';

  @override
  String get collectionDashboardAddBlock => 'Ajouter un bloc';

  @override
  String get collectionDashboardCopied => 'Copié';

  @override
  String get collectionDashboardCopy => 'Copier';

  @override
  String get collectionDashboardRearrange => 'Réorganiser';

  @override
  String get collectionDashboardRecentlyAdded => 'Ajoutés récemment';

  @override
  String get collectionDashboardJustNow => 'à l\'instant';

  @override
  String get collectionFolderTitle => 'Dossier';

  @override
  String get collectionFolderRetry => 'Réessayer';

  @override
  String get collectionFolderNotFound => 'Dossier introuvable.';

  @override
  String get collectionFolderEmpty => 'Ce dossier est vide.';

  @override
  String get collectionFolderBlocks => 'BLOCS';

  @override
  String get collectionFolderContents => 'CONTENU';

  @override
  String get collectionReorderTitle => 'Réorganiser les blocs';

  @override
  String get collectionReorderInstruction =>
      'Faites glisser la poignée pour réorganiser · appui long pour les actions.';

  @override
  String get collectionBlockFolder => 'Dossier';

  @override
  String get collectionBlockSection => 'Section';

  @override
  String get collectionBlockDocument => 'Document';

  @override
  String get collectionBlockNote => 'Note';

  @override
  String get collectionBlockInput => 'Champ';

  @override
  String get collectionBlockChecklist => 'Checklist';

  @override
  String get collectionBlockLink => 'Lien';

  @override
  String get collectionBlockImage => 'Image';

  @override
  String get collectionBlockExpense => 'Dépense';

  @override
  String get collectionBlockTimeline => 'Événement';

  @override
  String get collectionBlockLocation => 'Lieu';

  @override
  String get collectionBlockFolderDesc => 'Organiser les fichiers';

  @override
  String get collectionBlockSectionDesc => 'Grouper les blocs';

  @override
  String get collectionBlockDocumentDesc => 'Document texte';

  @override
  String get collectionBlockNoteDesc => 'Note rapide';

  @override
  String get collectionBlockInputDesc => 'Champ de texte';

  @override
  String get collectionBlockChecklistDesc => 'Liste de tâches';

  @override
  String get collectionBlockLinkDesc => 'Ressource web';

  @override
  String get collectionBlockImageDesc => 'Ajouter une photo';

  @override
  String get collectionBlockExpenseDesc => 'Suivre les dépenses';

  @override
  String get collectionBlockTimelineDesc => 'Journal d\'événement';

  @override
  String get collectionBlockLocationDesc => 'Épingler un lieu';

  @override
  String get collectionAddBlockTitle => 'Ajouter un bloc';

  @override
  String get collectionAddBlockSubtitle =>
      'Choisissez un composant à ajouter à votre espace';

  @override
  String get collectionAddBlockSearch => 'Filtrer les blocs';

  @override
  String get collectionAddBlockStructural => 'Structure';

  @override
  String get collectionAddBlockContent => 'Contenu';

  @override
  String get collectionAddBlockNoResults => 'Aucun bloc correspondant';

  @override
  String get collectionCategoryMilestone => 'Jalon';

  @override
  String get collectionCategoryDeadline => 'Échéance';

  @override
  String get collectionCategoryReminder => 'Rappel';

  @override
  String get collectionCategoryIdentity => 'Identité';

  @override
  String get collectionCategoryTravel => 'Voyage';

  @override
  String get collectionCategoryFinance => 'Finance';

  @override
  String get collectionCategoryOther => 'Autre';

  @override
  String get collectionCategoryPersonal => 'Personnel';

  @override
  String get collectionCategoryWork => 'Travail';

  @override
  String get collectionCategoryTransport => 'Transport';

  @override
  String get collectionCategoryFood => 'Alimentation';

  @override
  String get collectionCategoryShopping => 'Shopping';

  @override
  String get collectionCategoryRent => 'Loyer';

  @override
  String get collectionSecurityStandard => 'Standard';

  @override
  String get collectionSecurityConfidential => 'Confidentiel';

  @override
  String get collectionSecurityTopSecret => 'Top Secret';

  @override
  String get collectionFieldShortText => 'Texte court';

  @override
  String get collectionFieldNumber => 'Nombre';

  @override
  String get collectionFieldDate => 'Date';

  @override
  String get collectionFieldPhone => 'Téléphone';

  @override
  String get collectionBlockReminder => 'Rappel';

  @override
  String get collectionBlockReminderDesc => 'Définir une alerte';

  @override
  String get collectionDetailReminderTitle => 'Détails du rappel';

  @override
  String get collectionDetailDeleteReminder => 'Supprimer le rappel';

  @override
  String get collectionEntryAddReminder => 'Ajouter un rappel';

  @override
  String get collectionEntryEditReminder => 'Modifier le rappel';

  @override
  String get collectionEntrySaveReminder => 'Enregistrer le rappel';

  @override
  String get collectionEntryScheduleReminder => 'Planifier';

  @override
  String get collectionEntryReminderTitle => 'Titre du rappel';

  @override
  String get collectionEntryReminderHintTitle => 'ex. Renouveler le passeport';

  @override
  String get collectionEntryReminderNote => 'Note';

  @override
  String get collectionEntryReminderHintNote =>
      'Ajoutez une note pour ce rappel...';

  @override
  String get collectionEntryReminderDateTime => 'Date et heure';

  @override
  String get collectionEntryReminderWhen => 'QUAND';

  @override
  String get collectionEntryReminderRepeat => 'Répétition';

  @override
  String get collectionEntryReminderSystemHelp =>
      'Les rappels utilisent le service de notifications système. Le coffre reste verrouillé.';

  @override
  String get collectionEntryIconSection => 'ICÔNE';

  @override
  String get collectionEntryFolderIconHelp =>
      'Changer l\'icône du dossier ne touche pas l\'icône de la collection ni ses autres blocs.';

  @override
  String get collectionEntrySectionIconHelp =>
      'Les icônes de section sont indépendantes des dossiers et des collections.';

  @override
  String get collectionEntrySectionIconSearchHint => 'services';

  @override
  String get collectionEntryDeleteFolder => 'Supprimer le dossier';

  @override
  String get collectionEntryDefaultState => 'ÉTAT PAR DÉFAUT';

  @override
  String get collectionEntryCollapsed => 'Repliée';

  @override
  String get collectionEntryExpanded => 'Dépliée';

  @override
  String get collectionEntryTimelineEvent => 'ÉVÉNEMENT';

  @override
  String get collectionEntryTimelineNotes => 'NOTES';

  @override
  String get collectionEntryTimelineWhen => 'QUAND';

  @override
  String get collectionEntryTimelineCategory => 'CATÉGORIE';

  @override
  String get collectionEntryTimelineCategoryTrip => 'Voyage';

  @override
  String get collectionEntryTimelineCategoryAdmin => 'Admin';

  @override
  String get collectionEntryTimelineCategoryProperty => 'Propriété';

  @override
  String get collectionEntryTimelineCategoryHealth => 'Santé';

  @override
  String get collectionEntryTimelineCategoryWork => 'Travail';

  @override
  String get collectionEntryTimelineLinked => 'LIÉ';

  @override
  String get collectionEntryTimelineLinkedPlaceholder =>
      'Lier un élément de collection';

  @override
  String get collectionEntryTimelineLinkedSheetTitle => 'Élément lié';

  @override
  String get collectionEntryTimelineLinkedHint =>
      'ex. Appartement · Rue de Lille';

  @override
  String get collectionReminderNone => 'Aucune';

  @override
  String get collectionReminderOnce => 'Une fois';

  @override
  String get collectionReminderDaily => 'Quotidien';

  @override
  String get collectionReminderWeekly => 'Hebdomadaire';

  @override
  String get collectionReminderMonthly => 'Mensuel';

  @override
  String get collectionReminderQuarterly => 'Trimestriel';

  @override
  String get collectionReminderYearly => 'Annuel';

  @override
  String get collectionReminderScheduled => 'Programmé';

  @override
  String get backupTitle => 'Sauvegarde & Restauration';

  @override
  String get backupUnableLoad =>
      'Impossible de charger les sauvegardes pour le moment.';

  @override
  String get backupRetry => 'Réessayer';

  @override
  String get backupCreating => 'Création de la sauvegarde...';

  @override
  String get backupCreateButton => 'Créer une sauvegarde';

  @override
  String get backupCreateTitle => 'Créer une sauvegarde';

  @override
  String get backupCreateSubtitle =>
      'Saisissez une phrase secrète pour chiffrer votre sauvegarde. Vous en aurez besoin pour la restaurer.';

  @override
  String get backupHistorySection => 'HISTORIQUE DES SAUVEGARDES';

  @override
  String get backupRestorePreview => 'Aperçu de la restauration';

  @override
  String get backupRestoreWarning =>
      'Vos données actuelles seront remplacées. Une sauvegarde d\'urgence sera créée au préalable.';

  @override
  String get backupRestoreTitle => 'Restaurer la sauvegarde';

  @override
  String get backupRestoreSubtitle =>
      'Saisissez la phrase secrète utilisée lors de la création de cette sauvegarde.';

  @override
  String get backupDeleteTitle => 'Supprimer la sauvegarde';

  @override
  String get backupNoHistory => 'Aucun historique de sauvegarde';

  @override
  String get backupNoHistorySubtitle =>
      'Votre historique de sauvegardes apparaîtra ici après votre première sauvegarde.';

  @override
  String get backupNoBackups => 'Aucune sauvegarde';

  @override
  String get backupNoBackupsSubtitle =>
      'Créez votre première sauvegarde chiffrée pour protéger vos données.';

  @override
  String get backupLastBackup => 'Dernière sauvegarde';

  @override
  String get backupAutoTitle => 'Sauvegarde automatique';

  @override
  String get backupAutoSubtitle =>
      'Sauvegarder automatiquement à l\'ouverture de l\'application';

  @override
  String get backupCloudStorage => 'Stockage cloud';

  @override
  String get backupCloudBackups => 'Sauvegardes cloud';

  @override
  String get backupCloudChecking => 'Vérification...';

  @override
  String get backupCloudUnableCheck =>
      'Vérification impossible — appuyez pour actualiser';

  @override
  String get backupCloudRestoreTitle => 'Restaurer depuis le cloud';

  @override
  String get backupCloudRestoreWarning =>
      'La sauvegarde sera téléchargée et restaurée. Vos données actuelles seront remplacées.';

  @override
  String get backupInterruptedWarning =>
      'Une restauration précédente a été interrompue. Vos données pourraient être incohérentes.';

  @override
  String get backupPassphraseHint => 'Phrase secrète';

  @override
  String get backupAuthCodeHint => 'Collez le code d\'autorisation ici';

  @override
  String get backupAuthFailed => 'Autorisation échouée ou annulée.';

  @override
  String get backupConnectionFailed => 'Échec de la connexion';

  @override
  String get backupSoon => 'Bientôt';

  @override
  String get backupConnected => 'Connecté';

  @override
  String get backupConnect => 'Connecter';

  @override
  String get backupDisconnect => 'Déconnecter';

  @override
  String get backupUploadICloud => 'Envoyer vers iCloud';

  @override
  String get backupComingSoon => 'Bientôt disponible';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonRestore => 'Restaurer';

  @override
  String get commonDismiss => 'Fermer';

  @override
  String get commonRollback => 'Revenir en arrière';

  @override
  String get commonActive => 'Actif';

  @override
  String get backupDeviceTitle => 'Infos sur l\'appareil';

  @override
  String get backupDeviceUnableLoad =>
      'Impossible de charger les infos de l\'appareil.';

  @override
  String get backupDeviceId => 'Identifiant de l\'appareil';

  @override
  String get backupDevicePlatform => 'Plateforme';

  @override
  String get backupDeviceAppVersion => 'Version de l\'application';

  @override
  String get backupDeviceFirstSeen => 'Première connexion';

  @override
  String get backupDeviceActiveWriter => 'Rédacteur de sauvegarde actif';

  @override
  String get backupDeviceActiveWriterDesc =>
      'Cet appareil est le rédacteur de sauvegarde actif.';

  @override
  String get backupHealthTitle => 'Santé de la sauvegarde';

  @override
  String get backupHealthUnableLoad =>
      'Impossible de charger les données de santé.';

  @override
  String get backupHealthChainStatus => 'ÉTAT DE LA CHAÎNE';

  @override
  String get backupHealthStatus => 'État';

  @override
  String get backupHealthStatusEmpty => 'Vide';

  @override
  String get backupHealthStatusActive => 'Active';

  @override
  String get backupHealthChainDepth => 'Profondeur de la chaîne';

  @override
  String get backupHealthBaseDate => 'Date de base';

  @override
  String get backupHealthHeadDate => 'Date de tête';

  @override
  String get backupHealthStats => 'STATISTIQUES DE SAUVEGARDE';

  @override
  String get backupHealthLastBackup => 'Dernière sauvegarde';

  @override
  String get backupHealthNever => 'Jamais';

  @override
  String get backupHealthTotalBackups => 'Total des sauvegardes';

  @override
  String get backupHealthStorageUsed => 'Stockage utilisé';

  @override
  String get backupHealthEncryption => 'Chiffrement';

  @override
  String get backupHealthDevice => 'APPAREIL';

  @override
  String get backupHealthName => 'Nom';

  @override
  String get backupHealthIntegrity => 'INTÉGRITÉ';

  @override
  String get backupHealthChecking => 'Vérification...';

  @override
  String get backupHealthRunCheck => 'Lancer la vérification d\'intégrité';

  @override
  String get backupHealthRebuildChain => 'Reconstruire la chaîne';

  @override
  String get backupHealthRebuildNotAvailable =>
      'La reconstruction de la chaîne n\'est pas encore disponible.';

  @override
  String get collectionsTitle => 'Collections';

  @override
  String get collectionsNewCollection => '+ Nouvelle collection';

  @override
  String get collectionsCreateTitle => 'Créer une collection';

  @override
  String get collectionsChooseStarting => 'Choisir un point de départ';

  @override
  String get collectionsChooseSubtitle =>
      'Partez de zéro ou choisissez un modèle.\nAppuyez sur aperçu pour explorer avant de choisir.';

  @override
  String get collectionsRecommendedTemplates => 'MODÈLES RECOMMANDÉS';

  @override
  String get collectionsSearchResults => 'RÉSULTATS DE RECHERCHE';

  @override
  String get collectionsNoTemplatesFound => 'Aucun modèle trouvé';

  @override
  String get collectionsSearchTemplatesHint => 'Rechercher des modèles...';

  @override
  String get collectionBlockRename => 'Renommer';

  @override
  String get collectionBlockDuplicate => 'Dupliquer';

  @override
  String get collectionBlockLockWithPin => 'Verrouiller avec un PIN';

  @override
  String get collectionBlockMove => 'Déplacer vers une autre collection';

  @override
  String get collectionListYours => 'Vos collections';

  @override
  String get collectionListStartFromTemplate => 'Commencer avec un modèle';

  @override
  String get collectionBlockDelete => 'Supprimer';

  @override
  String get collectionBlockRenamed => 'Renommé avec succès';

  @override
  String get collectionBlockDuplicated => 'Dupliqué avec succès';

  @override
  String get collectionBlockDeleted => 'Supprimé avec succès';

  @override
  String get collectionBlockRenameHint => 'Entrer un nouveau nom';

  @override
  String get collectionBlockProgress => 'Progression';

  @override
  String get collectionBlockProgressDesc =>
      'Suivre la progression vers un objectif avec une barre visuelle';

  @override
  String get collectionEntryProgressTitle => 'TITRE';

  @override
  String get collectionEntryProgressHintTitle =>
      'ex. Plan de paiement, Objectif d\'épargne';

  @override
  String get collectionEntryProgressCurrent => 'ACTUEL';

  @override
  String collectionEntryProgressCurrentOf(String target) {
    return 'ACTUEL · SUR $target';
  }

  @override
  String get collectionEntryProgressTarget => 'OBJECTIF';

  @override
  String get collectionEntryProgressDue => 'ÉCHÉANCE';

  @override
  String get collectionEntryProgressValues => 'VALEURS';

  @override
  String get collectionEntryProgressType => 'TYPE';

  @override
  String get collectionEntryProgressTypeCurrency => 'Devise';

  @override
  String get collectionEntryProgressTypeQuantity => 'Quantité';

  @override
  String get collectionEntryProgressTypeDistance => 'Distance';

  @override
  String get collectionEntryProgressTypeCustom => 'Personnalisé';

  @override
  String get collectionEntryProgressCustomUnit => 'personnalisé';

  @override
  String get collectionEntryProgressCurrency => 'DEVISE (OPTIONNEL)';

  @override
  String get collectionEntryProgressUnit => 'UNITÉ (OPTIONNEL)';

  @override
  String get collectionEntryProgressUnitNone => 'Aucune';

  @override
  String get collectionEntryProgressUnitCustomHint =>
      'Ou saisir une unité personnalisée...';

  @override
  String get collectionEntryProgressHintDesc =>
      'Ajouter des notes sur ce suivi...';

  @override
  String get collectionEntryAddProgress => 'Ajouter une progression';

  @override
  String get collectionEntryEditProgress => 'Modifier la progression';

  @override
  String get collectionEntrySaveProgress => 'Enregistrer la progression';

  @override
  String get collectionDetailProgressTitle => 'Progression';

  @override
  String get collectionsBlankTitle => 'Collection vierge';

  @override
  String get collectionsBlankSubtitle => 'Commencer avec une page blanche';

  @override
  String get collectionsSelected => 'Sélectionné';

  @override
  String get collectionsSelect => 'Sélectionner';

  @override
  String get collectionsStep2of3 => 'Étape 2 sur 3';

  @override
  String get collectionsIncludedBlocks => 'BLOCS INCLUS';

  @override
  String get collectionsUseTemplate => 'Utiliser ce modèle';

  @override
  String get collectionsAccentColor => 'Couleur d\'accentuation';

  @override
  String get collectionsPickColor => 'Choisir une couleur';

  @override
  String get collectionsNameHint => 'ex. Destinations d\'été';

  @override
  String get collectionsNameRequired => 'Veuillez saisir un nom de collection.';

  @override
  String get collectionsColorHint => '#FF5733';

  @override
  String get settingsExportPassphraseTitle => 'Phrase secrète d\'export';

  @override
  String get settingsExportPassphraseHint =>
      'Saisissez une phrase secrète pour chiffrer l\'export';

  @override
  String get settingsExportButton => 'Exporter';

  @override
  String get settingsBackupSubtitle =>
      'Créer et restaurer des sauvegardes chiffrées';

  @override
  String get settingsExportSubtitle =>
      'Exporter votre coffre sous forme d\'archive portable';

  @override
  String get settingsDataSection => 'DONNÉES';

  @override
  String get navHome => 'Accueil';

  @override
  String get navCredentials => 'Identifiants';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navProfile => 'Profil';

  @override
  String get navVault => 'Coffre';

  @override
  String get navDocs => 'Docs';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navMe => 'Moi';

  @override
  String get homeSmartReminders => 'Rappels intelligents';

  @override
  String get homeQuickAccess => 'Accès rapide';

  @override
  String get homeRecentActivity => 'Activité récente';

  @override
  String get homeVaultInsights => 'Aperçu du coffre';

  @override
  String get homeEverythingGood => 'Tout est en ordre';

  @override
  String get homeVaultUpToDate => 'Votre coffre est sécurisé et à jour';

  @override
  String get homeVaultStatus => 'Statut du coffre';

  @override
  String get homeVaultAtGlance => 'Coffre en un coup d\'œil';

  @override
  String get homeStatusNeedsAttention => 'À vérifier';

  @override
  String get homeHealthy => 'Sain';

  @override
  String get homeNeedsAttention => 'Demande votre attention';

  @override
  String get homeNoAttentionNeeded => 'Aucune attention requise';

  @override
  String get homeNoAttentionSubtitle =>
      'Votre coffre n\'a aucun rappel urgent pour le moment.';

  @override
  String get homeAlerts => 'alertes';

  @override
  String get homeItems => 'éléments';

  @override
  String get homeIssues => 'problèmes';

  @override
  String get homeOpen => 'ouverts';

  @override
  String get homeOpenTasks => 'tâches ouvertes';

  @override
  String get homeBackupLocal => 'Sauvegarde locale';

  @override
  String get homeLocalOnly => 'Local d\'abord';

  @override
  String get homeQuickOpen => 'Ouverture rapide';

  @override
  String get homePinned => 'Épinglés';

  @override
  String get homeViewAll => 'Tout voir';

  @override
  String get homeLastUpdated => 'Mis à jour';

  @override
  String get homeToday => 'Aujourd\'hui';

  @override
  String get homeSoonestFirst => 'Plus proche d\'abord';

  @override
  String get homeRecentEmptyTitle => 'Aucune activité récente';

  @override
  String get homeRecentEmptySubtitle =>
      'Les éléments ouverts ou modifiés apparaîtront ici.';

  @override
  String get homeSetupEmptyTitle => 'Un espace calme pour vos éléments privés.';

  @override
  String get homeSetupEmptySubtitle =>
      'Ajoutez votre premier identifiant, document, collection ou tâche pour commencer à construire votre coffre chiffré.';

  @override
  String get homeAddFirstItem => 'Ajouter le premier élément';

  @override
  String get homeUnableDashboard => 'Impossible de charger le tableau de bord';

  @override
  String get homeUnableDashboardSubtitle =>
      'Un problème est survenu lors du\nchargement de l\'écran d\'accueil.';

  @override
  String get homeTryAgain => 'Réessayer';

  @override
  String get homePreferencesTitle => 'Préférences d\'accueil';

  @override
  String get homeResetDefaults => 'Réinitialiser';

  @override
  String get homeVisibleSections => 'Sections visibles';

  @override
  String get homeCategories => 'Catégories';

  @override
  String get homeSmartRules => 'Règles intelligentes';

  @override
  String get homeExpiringDocuments => 'Documents expirants';

  @override
  String get homeMissingAttention => 'Manquant / Action requise';

  @override
  String get homeRecentlyUpdated => 'Récemment mis à jour';

  @override
  String get homeSourceCredential => 'Identifiant';

  @override
  String get homeSourceDocument => 'Document';

  @override
  String get homeSourceCollection => 'Collection';

  @override
  String get searchTitle => 'Rechercher dans votre coffre';

  @override
  String get searchHint => 'Rechercher...';

  @override
  String get searchNoResults => 'Aucun résultat';

  @override
  String get searchNoResultsSubtitle => 'Essayez un autre terme';

  @override
  String get searchFindAll => 'Trouvez identifiants, documents et collections';

  @override
  String get searchCredentials => 'Identifiants';

  @override
  String get searchDocuments => 'Documents';

  @override
  String get searchCollections => 'Collections';

  @override
  String get authEnterPin => 'Saisissez votre code PIN';

  @override
  String get authEnterPinSubtitle => 'Saisissez votre code PIN à 6 chiffres';

  @override
  String get authIncorrectPin => 'Code PIN incorrect. Réessayez.';

  @override
  String get authCreatePin => 'Créer un code PIN';

  @override
  String get authConfirmPin => 'Confirmez votre code PIN';

  @override
  String get authCreatePinSubtitle =>
      'Choisissez un code PIN à 6 chiffres pour sécuriser votre coffre';

  @override
  String get authConfirmPinSubtitle => 'Saisissez à nouveau le même code PIN';

  @override
  String get authPinMismatch =>
      'Les codes PIN ne correspondent pas. Réessayez.';

  @override
  String get authEnableBiometric => 'Activer le déverrouillage biométrique ?';

  @override
  String get authBiometricSubtitle =>
      'Utilisez Face ID ou l\'empreinte digitale pour déverrouiller votre coffre.';

  @override
  String get authBiometricEnable => 'Activer';

  @override
  String get authBiometricSkip => 'Passer';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboardingTitle1 => 'Votre coffre sécurisé';

  @override
  String get onboardingSubtitle1 =>
      'Stockez identifiants, documents et collections dans un espace chiffré. Tout reste sur votre appareil.';

  @override
  String get onboardingTitle2 => 'Documents intelligents';

  @override
  String get onboardingSubtitle2 =>
      'Numérisez et organisez vos pièces d\'identité, contrats et dossiers avec catégorisation automatique.';

  @override
  String get onboardingTitle3 => 'Collections puissantes';

  @override
  String get onboardingSubtitle3 =>
      'Planifiez vos voyages, suivez vos projets, gérez vos budgets — avec listes, chronologies et rappels.';

  @override
  String get onboardingTitle4 => 'Sauvegardes chiffrées';

  @override
  String get onboardingSubtitle4 =>
      'Sauvegardez sur Dropbox ou Google Drive avec chiffrement AES-256. Restaurez à tout moment.';

  @override
  String get editCollection => 'Modifier la collection';

  @override
  String get preparingExport => 'Préparation de l\'export...';

  @override
  String get exportFailed => 'Échec de l\'export';

  @override
  String get settingsLockTimeoutUpdated => 'Délai de verrouillage mis à jour';

  @override
  String get settingsPinUpdatedSuccessfully => 'PIN mis à jour avec succès';

  @override
  String get settingsIncorrectPin => 'PIN incorrect';

  @override
  String get settingsBiometricEnabled => 'Déverrouillage biométrique activé';

  @override
  String get settingsBiometricDisabled =>
      'Déverrouillage biométrique désactivé';

  @override
  String get scanTakePhoto => 'Prendre une photo';

  @override
  String get scanChooseFromLibrary => 'Choisir depuis la bibliothèque';

  @override
  String get scanRetake => 'Reprendre';

  @override
  String get generatorUse => 'Utiliser';

  @override
  String get generatorNavVaults => 'Coffres';

  @override
  String get generatorNavPasswords => 'Mots de passe';

  @override
  String get generatorNavSecurity => 'Sécurité';

  @override
  String get generatorNavSettings => 'Paramètres';

  @override
  String get generatorSideMyPasswords => 'Mes mots de passe';

  @override
  String get generatorSideGenerator => 'Générateur';

  @override
  String get generatorSideSecurityAudit => 'Audit de sécurité';

  @override
  String get generatorSideHistory => 'Historique';

  @override
  String get generatorCopy => 'Copier';

  @override
  String get generatorGenerating => 'Génération...';

  @override
  String get generatorRegenerate => 'Régénérer';

  @override
  String get generatorStrengthLabel => 'FORCE DU MOT DE PASSE';

  @override
  String get generatorSearchHint => 'Rechercher...';

  @override
  String get generatorRuleUppercaseLetters => 'Lettres majuscules';

  @override
  String get generatorRuleLowercaseLetters => 'Lettres minuscules';

  @override
  String get generatorRuleIncludeNumbers => 'Inclure les chiffres';

  @override
  String get generatorRuleIncludeSymbols => 'Inclure les symboles';

  @override
  String get generatorMobileRuleUppercase => 'Majuscules (A-Z)';

  @override
  String get generatorMobileRuleLowercase => 'Minuscules (a-z)';

  @override
  String get generatorMobileRuleNumbers => 'Chiffres (0-9)';

  @override
  String get generatorMobileRuleSymbols => 'Symboles (!@#\$)';

  @override
  String get generatorMetricEntropy => 'Score d’entropie';

  @override
  String get generatorMetricEntropyDesc =>
      'Mesure de l’imprévisibilité de votre mot de passe.';

  @override
  String get generatorMetricCrackTime => 'Temps de cassage';

  @override
  String get generatorMetricCrackTimeDesc =>
      'Temps estimé de cassage par force brute.';

  @override
  String get generatorMetricEasyToType => 'Facile à saisir';

  @override
  String get generatorMetricEasyToTypeDesc =>
      'Distribution équilibrée pour la saisie manuelle.';

  @override
  String get collectionFieldTypeShortText => 'Texte court';

  @override
  String get collectionFieldTypeNumber => 'Nombre';

  @override
  String get collectionFieldTypeDate => 'Date';

  @override
  String get collectionFieldTypePhone => 'Téléphone';

  @override
  String get collectionEventTypeMilestone => 'Jalon';

  @override
  String get collectionEventTypeDeadline => 'Échéance';

  @override
  String get collectionEventTypeReminder => 'Rappel';

  @override
  String get collectionDocCategoryIdentity => 'Identité';

  @override
  String get collectionDocCategoryTravel => 'Voyage';

  @override
  String get collectionDocCategoryFinance => 'Finance';

  @override
  String get collectionDocCategoryPropertyLease => 'Propriété · Bail';

  @override
  String get collectionDocCategoryOther => 'Autre';

  @override
  String get collectionNoteCategoryPersonal => 'Personnel';

  @override
  String get collectionNoteCategoryWork => 'Professionnel';

  @override
  String get collectionExpenseCategoryTransport => 'Transport';

  @override
  String get collectionExpenseCategoryFood => 'Nourriture';

  @override
  String get collectionExpenseCategoryShopping => 'Achats';

  @override
  String get collectionExpenseCategoryRent => 'Loyer';

  @override
  String get collectionExpenseCategoryOther => 'Autre';

  @override
  String get collectionFileTypeDocuments => 'Documents';

  @override
  String get collectionFileTypeImages => 'Images';

  @override
  String get collectionFileTypeAllFiles => 'Tous les fichiers';

  @override
  String get collectionEntryTapToEnterAmount =>
      'Appuyez pour entrer le montant';

  @override
  String get collectionEntryHintNoteTitle => 'Titre de la note';

  @override
  String get collectionEntryHintReminderExample => 'Renouveler le passeport';

  @override
  String get collectionEntryAddAnotherTask => 'Ajouter une autre tâche...';

  @override
  String get collectionEntryAddChecklistItem => 'Ajouter un élément';

  @override
  String get collectionEntryChecklistReorder => 'RÉORGANISER';

  @override
  String collectionEntryChecklistItemsSummary(int total, int done) {
    return 'ÉLÉMENTS · $total · $done SUR $total TERMINÉS';
  }

  @override
  String get collectionEntryUnitFloor => 'Unité / Étage';

  @override
  String get collectionEntryOptional => 'Facultatif';

  @override
  String get collectionEntryWhatWasThisFor => 'C\'était pour quoi ?';

  @override
  String get collectionTemplateTravelPlannerTitle => 'Planificateur de voyage';

  @override
  String get collectionTemplateTravelPlannerDesc =>
      'Organisez les vols, hôtels et itinéraires';

  @override
  String get collectionTemplateWeddingPlannerTitle =>
      'Planificateur de mariage';

  @override
  String get collectionTemplateWeddingPlannerDesc =>
      'Planifiez votre jour parfait';

  @override
  String get collectionTemplateBudgetPlannerTitle => 'Planificateur de budget';

  @override
  String get collectionTemplateBudgetPlannerDesc =>
      'Suivez revenus, dépenses et objectifs d\'épargne';

  @override
  String get collectionTemplateEventPlanningTitle =>
      'Planification d\'événements';

  @override
  String get collectionTemplateEventPlanningDesc =>
      'Planifiez les fêtes et réunions';

  @override
  String get collectionTemplateProjectPlanningTitle =>
      'Planification de projet';

  @override
  String get collectionTemplateProjectPlanningDesc =>
      'Feuilles de route, tâches et ressources';

  @override
  String get collectionTemplateFreelanceTrackerTitle => 'Suivi freelance';

  @override
  String get collectionTemplateFreelanceTrackerDesc =>
      'Gérez clients, factures et livrables';

  @override
  String get collectionTemplateHomeRenovationTitle => 'Rénovation maison';

  @override
  String get collectionTemplateHomeRenovationDesc =>
      'Planifiez avec entrepreneurs et budgets';

  @override
  String get collectionTemplateStudyPlannerTitle => 'Planificateur d\'études';

  @override
  String get collectionTemplateStudyPlannerDesc =>
      'Organisez cours, examens et sessions';

  @override
  String get collectionTemplateFitnessTrackerTitle => 'Suivi fitness';

  @override
  String get collectionTemplateFitnessTrackerDesc =>
      'Suivez entraînements et objectifs';

  @override
  String get collectionTemplateRecipeBookTitle => 'Livre de recettes';

  @override
  String get collectionTemplateRecipeBookDesc =>
      'Enregistrez recettes et listes';

  @override
  String get collectionTemplateJobSearchTitle => 'Recherche d\'emploi';

  @override
  String get collectionTemplateJobSearchDesc =>
      'Suivez candidatures et entretiens';

  @override
  String get collectionTemplatePropertyManagementTitle => 'Gestion immobilière';

  @override
  String get collectionTemplatePropertyManagementDesc =>
      'Suivez annonces et locataires';

  @override
  String get collectionTemplateMovingChecklistTitle => 'Liste de déménagement';

  @override
  String get collectionTemplateMovingChecklistDesc =>
      'Organisez emballage, services et calendrier';

  @override
  String get collectionTemplatePetCareTitle => 'Soins animaux';

  @override
  String get collectionTemplatePetCareDesc =>
      'Gérez visites vétérinaires, vaccinations et dossiers de santé';

  @override
  String get collectionTemplateVehicleMaintenanceTitle => 'Entretien véhicule';

  @override
  String get collectionTemplateVehicleMaintenanceDesc =>
      'Suivez l\'historique d\'entretien, dépenses et plannings';

  @override
  String get collectionTemplateDiplomasCertificatesTitle =>
      'Diplômes et certificats';

  @override
  String get collectionTemplateDiplomasCertificatesDesc =>
      'Organisez diplômes, relevés et certifications professionnelles';

  @override
  String get collectionTemplateBankDocumentsTitle =>
      'Documents bancaires (RIB)';

  @override
  String get collectionTemplateBankDocumentsDesc =>
      'Stockez RIB, IBAN, détails de compte et relevés mensuels';

  @override
  String get collectionTemplateHealthRecordsTitle => 'Dossiers médicaux';

  @override
  String get collectionTemplateHealthRecordsDesc =>
      'Suivez vaccinations, allergies, visites médicales et assurance';

  @override
  String get collectionTemplateTaxDocumentsTitle => 'Documents fiscaux';

  @override
  String get collectionTemplateTaxDocumentsDesc =>
      'Organisez déclarations fiscales, reçus et déductions';

  @override
  String get collectionTemplateTagPopular => 'Populaire';

  @override
  String get collectionTemplateTagNew => 'Nouveau';

  @override
  String get collectionTemplatePreview => 'Aperçu';

  @override
  String collectionTemplateBlocksCount(int count) {
    return '$count blocs';
  }

  @override
  String get workCompanyEditTitle => 'Modifier l\'entreprise';

  @override
  String get workCompanyAddTitle => 'Ajouter une entreprise';

  @override
  String get workCompanyFieldRole => 'Rôle';

  @override
  String get workCompanyFieldEntryDate => 'Date d\'entrée';

  @override
  String get workCompanyFieldEndDate => 'Date de fin (Optionnel)';

  @override
  String get workCompanyFieldContact => 'Contact principal';

  @override
  String get workCompanyHintContact => 'E-mail ou numéro de téléphone';

  @override
  String get workCompanyHintLocation => 'Ville, Pays';

  @override
  String get workCompanyStatusOngoing => 'En cours';

  @override
  String get workCompanyStatusFixed => 'Fixe';

  @override
  String get workCompanyPreviewMap => 'APERÇU CARTE';

  @override
  String get workCompanyAutoDetectLogo => 'Détecter le logo';

  @override
  String get workCompanyUploadManually =>
      'Ou télécharger manuellement (PNG, JPG jusqu\'à 5 Mo)';

  @override
  String get commonTakePhoto => 'Prendre une photo';

  @override
  String get commonChooseFromGallery => 'Choisir dans la galerie';

  @override
  String get commonBrowseFiles => 'Parcourir les fichiers';

  @override
  String get credentialDeleteAction => 'Supprimer l\'identifiant';

  @override
  String get credentialDeleteFailed => 'Échec de la suppression';

  @override
  String get reminderActionRenewal => 'Renouvellement nécessaire';

  @override
  String get reminderActionRequired => 'Action requise';

  @override
  String get reminderActionUpload => 'Télécharger maintenant';

  @override
  String get reminderActionViewDetails => 'Voir les détails';

  @override
  String get backupNotConnected => 'Non connecté';

  @override
  String get backupUploadGoogleDrive => 'Tout télécharger vers Google Drive';

  @override
  String get backupUploadDropbox => 'Tout télécharger vers Dropbox';

  @override
  String get backupConnecting => 'Connexion...';

  @override
  String get backupAuthorize => 'Autoriser';

  @override
  String get settingsHintPinDigits => 'Code PIN à 6 chiffres';

  @override
  String get settingsVerify => 'Vérifier';

  @override
  String get settingsWipeEverything => 'Tout effacer';

  @override
  String settingsExportFailedWithError(String error) {
    return 'Échec de l\'exportation : $error';
  }

  @override
  String get idCardRescan => 'Réanalyser';

  @override
  String get settingsThemeTitle => 'Thème';

  @override
  String get settingsThemeSubtitle => 'Système, Clair ou Sombre';

  @override
  String get settingsAutoLockTitle => 'Verrouillage automatique';

  @override
  String get settingsAutoLockSubtitle => 'Verrouiller après inactivité';

  @override
  String get settingsChangePinTitle => 'Changer le PIN';

  @override
  String get settingsChangePinSubtitle =>
      'Mettre à jour votre code PIN à 6 chiffres';

  @override
  String get settingsBiometricTitle => 'Déverrouillage biométrique';

  @override
  String get settingsBiometricSubtitle =>
      'Activer Face ID / empreinte digitale';

  @override
  String get settingsWipeVaultTitle => 'Effacer le coffre';

  @override
  String get settingsWipeVaultSubtitle =>
      'Supprimer définitivement toutes les données';

  @override
  String get settingsWipeDialogTitle => 'Effacer toutes les données ?';

  @override
  String get settingsWipeDialogContent =>
      'Cela supprimera définitivement TOUTES les données du coffre, y compris les identifiants, documents, collections, sauvegardes et votre PIN. Cette action est irréversible.';

  @override
  String get settingsLockImmediately => 'Immédiatement';

  @override
  String get settingsLockNever => 'Jamais';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsBiometricEnabledLabel => 'Activé';

  @override
  String get settingsBiometricEnabledSubtitle =>
      'Déverrouiller avec la biométrie + PIN en secours';

  @override
  String get settingsBiometricDisabledSubtitle =>
      'Toujours exiger votre code PIN à 6 chiffres';

  @override
  String get travelUnableLoadEvent => 'Impossible de charger l\'événement';

  @override
  String get scanPassportTitle => 'Scanner le passeport';

  @override
  String get travelHintEventTitle => 'ex. Vol pour Paris';

  @override
  String get travelHintSearchLocation => 'Rechercher un lieu';

  @override
  String get travelFieldDeparture => 'Départ';

  @override
  String get travelFieldArrival => 'Arrivée';

  @override
  String get travelFieldAirlineProvider => 'Compagnie / Fournisseur';

  @override
  String get travelFieldFlightNo => 'N° de vol';

  @override
  String get travelFieldSeat => 'Siège';

  @override
  String get travelFieldTerminal => 'Terminal';

  @override
  String get travelFieldGate => 'Porte';

  @override
  String get travelHintBookingRef => 'ex. AF12345';

  @override
  String get travelHintHotelName => 'ex. Grand Hyatt Tokyo';

  @override
  String get travelFieldReservationNo => 'N° de réservation';

  @override
  String get travelFieldBookingPlatform => 'Plateforme de réservation';

  @override
  String get travelFieldRoomType => 'Type de chambre';

  @override
  String get travelFieldGuests => 'Invités';

  @override
  String get travelFieldTotalPrice => 'Prix total';

  @override
  String get travelFieldCuisineType => 'Type de cuisine';

  @override
  String get travelFieldEstimatedCost => 'Coût estimé';

  @override
  String get travelFieldActivityType => 'Type d\'activité';

  @override
  String get travelFieldOrganizer => 'Organisateur';

  @override
  String get travelFieldParticipants => 'Participants';

  @override
  String get travelFieldTicketPrice => 'Prix du billet';

  @override
  String get travelFieldBookingReference => 'Référence de réservation';

  @override
  String get travelFieldReservationType => 'Type de réservation';

  @override
  String get travelFieldProvider => 'Fournisseur';

  @override
  String get travelFieldPickupLocation => 'Lieu de prise en charge';

  @override
  String get travelFieldReservationNumber => 'Numéro de réservation';

  @override
  String get travelFieldVehicleDetails => 'Détails du véhicule / article';

  @override
  String get travelFieldPriceDeposit => 'Prix / Dépôt';

  @override
  String get travelHintNotes =>
      'Ajouter les codes de confirmation, points de rencontre ou détails...';

  @override
  String get travelHintExpenseTitle => 'ex. Dîner à Tokyo';

  @override
  String get travelHintAdditionalDetails =>
      'Ajoutez des détails supplémentaires ici...';

  @override
  String get travelFieldSelectType => 'Sélectionner le type';

  @override
  String get travelHintDocTitle => 'ex. Carte d\'embarquement NH212';

  @override
  String get commonOptional => 'Optionnel';

  @override
  String get travelHintBookingNotes =>
      'Ajoutez des notes ou détails de réservation';

  @override
  String get propertyTypeApartment => 'Appartement';

  @override
  String get propertyTypeSingleFamily => 'Maison individuelle';

  @override
  String get propertyTypeCondo => 'Copropriété';

  @override
  String get propertyTypeTownhouse => 'Maison de ville';

  @override
  String get propertyTypeMultiFamily => 'Immeuble collectif';

  @override
  String get propertyTypePenthouse => 'Penthouse';

  @override
  String get propertyTypeVacationHome => 'Maison de vacances';

  @override
  String get propertyTypeLand => 'Terrain';

  @override
  String get propertyTypeCommercial => 'Commercial';

  @override
  String get settingsImportVaultTitle => 'Importer les données du coffre';

  @override
  String get settingsImportVaultSubtitle =>
      'Restaurer depuis un fichier .zip exporté';

  @override
  String get settingsImportPasswordsTitle => 'Importer des mots de passe';

  @override
  String get settingsImportPasswordsSubtitle =>
      'Depuis Chrome, Safari, 1Password, Bitwarden ou LastPass';

  @override
  String get macMenuFile => 'Fichier';

  @override
  String get macMenuEdit => 'Édition';

  @override
  String get macMenuView => 'Affichage';

  @override
  String get macMenuVault => 'Coffre';

  @override
  String get macMenuNewCredential => 'Nouvel identifiant';

  @override
  String get macMenuNewCollection => 'Nouvelle collection';

  @override
  String get macMenuImportVault => 'Importer le coffre...';

  @override
  String get macMenuExportVault => 'Exporter le coffre...';

  @override
  String get macMenuCloseWindow => 'Fermer la fenêtre';

  @override
  String get macMenuCopy => 'Copier';

  @override
  String get macMenuPaste => 'Coller';

  @override
  String get macMenuSelectAll => 'Tout sélectionner';

  @override
  String get macMenuFind => 'Rechercher...';

  @override
  String get macMenuToggleSidebar => 'Afficher/masquer la barre latérale';

  @override
  String get macMenuLockVault => 'Verrouiller le coffre';

  @override
  String get macMenuSearchVault => 'Rechercher dans le coffre';

  @override
  String get macMenuSettings => 'Paramètres...';

  @override
  String get dropboxSessionExpiredTitle => 'Session Dropbox expirée';

  @override
  String get dropboxSessionExpiredMessage =>
      'Votre connexion Dropbox a expiré. Veuillez vous reconnecter pour continuer à synchroniser vos sauvegardes.';

  @override
  String get settingsImportPassphraseTitle =>
      'Entrer le mot de passe d\'export';

  @override
  String get settingsImportPassphraseHint =>
      'Mot de passe utilisé lors de l\'export';

  @override
  String get settingsImportSuccess => 'Données du coffre importées avec succès';

  @override
  String get settingsImportFailed => 'Échec de l\'importation des données';

  @override
  String get settingsImportInvalidFile => 'Fichier invalide ou corrompu';

  @override
  String get settingsImportAction => 'Importer';

  @override
  String get lockScreenTooManyAttempts => 'Trop de tentatives échouées';

  @override
  String lockScreenTryAgainIn(String time) {
    return 'Réessayez dans $time';
  }

  @override
  String lockScreenAttemptsRemaining(int count) {
    return '$count tentatives restantes avant verrouillage';
  }

  @override
  String get scanIdentityVerification => 'Vérification d\'identité';

  @override
  String get scanAdjustDocument => 'Ajuster le document';

  @override
  String get addDocumentTitle => 'Ajouter un document';

  @override
  String get addDocumentPassportSubtitle => 'Passeports et documents de voyage';

  @override
  String get addDocumentIdCardSubtitle => 'Carte d\'identité nationale';

  @override
  String get addDocumentDriversLicenseSubtitle => 'Permis de conduire';

  @override
  String get addDocumentOtherSubtitle => 'Tout autre type de document';

  @override
  String get addDocumentSelectType => 'SÉLECTIONNER LE TYPE DE DOCUMENT';

  @override
  String get addDocumentInfoHint =>
      'Choisissez un type de document pour continuer vers la saisie manuelle et le remplissage automatique.';

  @override
  String get addDocumentSecurityFooter =>
      'Vos documents sont chiffrés et sécurisés';

  @override
  String get idCardFrontSide => 'Recto';

  @override
  String get idCardBackSide => 'Verso';

  @override
  String get credentialEmptyTitle => 'Sécurisez vos comptes';

  @override
  String get credentialEmptySubtitle =>
      'Stockez vos mots de passe et identifiants en toute sécurité, chiffrés et hors ligne sur votre appareil.';

  @override
  String get credentialEmptyAction => 'Ajouter un identifiant';

  @override
  String get settingsRevealAuthTitle => 'Protection de l\'affichage';

  @override
  String get settingsRevealAuthSubtitle =>
      'Exiger le PIN ou la biométrie pour voir les mots de passe';

  @override
  String get settingsRevealAuthEnabled => 'Protection de l\'affichage activée';

  @override
  String get settingsRevealAuthEnabledDetail =>
      'PIN ou biométrie requis avant d\'afficher un mot de passe';

  @override
  String get settingsRevealAuthDisabled =>
      'Protection de l\'affichage désactivée';

  @override
  String get settingsRevealAuthDisabledDetail =>
      'Les mots de passe peuvent être affichés librement sans authentification';

  @override
  String get revealAuthPinTitle => 'Entrez le PIN pour révéler';

  @override
  String get revealAuthPinHint => 'Code PIN à 6 chiffres';

  @override
  String get revealAuthFailed => 'Échec de l\'authentification';

  @override
  String get secureNotesTitle => 'Notes sécurisées';

  @override
  String get secureNotesSubtitle => 'Notes personnelles chiffrées';

  @override
  String get secureNotesEmpty => 'Aucune note';

  @override
  String get secureNotesAdd => 'Nouvelle note';

  @override
  String get noteEditorTitle => 'Modifier la note';

  @override
  String get noteEditorTitleHint => 'Titre de la note';

  @override
  String get noteEditorContentHint => 'Écrivez votre note...';

  @override
  String get noteCategoryPersonal => 'Personnel';

  @override
  String get noteCategoryFinancial => 'Financier';

  @override
  String get noteCategoryLegal => 'Juridique';

  @override
  String get noteCategoryMedical => 'Médical';

  @override
  String get noteDeleted => 'Note supprimée';

  @override
  String get noteSaved => 'Note enregistrée';

  @override
  String expiryNotification90Days(String title) {
    return 'Votre $title expire dans 3 mois';
  }

  @override
  String expiryNotification30Days(String title) {
    return 'Votre $title expire dans 30 jours';
  }

  @override
  String expiryNotification7Days(String title) {
    return 'Votre $title expire la semaine prochaine';
  }

  @override
  String expiryNotificationExpired(String title) {
    return 'Votre $title a expiré';
  }

  @override
  String get collectionPinLockTitle => 'Entrez le PIN de la collection';

  @override
  String get collectionPinSetTitle => 'Définir le PIN de la collection';

  @override
  String get collectionPinHint => 'Code PIN à 4 chiffres';

  @override
  String get collectionPinIncorrect => 'PIN incorrect';

  @override
  String get collectionPinEnabled => 'Collection verrouillée';

  @override
  String get collectionPinDisabled => 'Collection déverrouillée';

  @override
  String get breachWarningBadge => 'Compromis';

  @override
  String breachWarningDetail(int count) {
    return '$count fois dans des fuites connues';
  }

  @override
  String get credentialFavoriteAdded => 'Ajouté aux favoris';

  @override
  String get credentialFavoriteRemoved => 'Retiré des favoris';

  @override
  String get backupPreviewDate => 'Date';

  @override
  String get backupPreviewType => 'Type';

  @override
  String get backupPreviewEntities => 'Entités';

  @override
  String get backupPreviewFiles => 'Fichiers';

  @override
  String get backupPreviewSize => 'Taille';

  @override
  String get backupPreviewDevice => 'Appareil';

  @override
  String get backupPreviewEncryption => 'Chiffrement';

  @override
  String get backupPreviewEncryptionNone => 'Aucun';

  @override
  String get backupRestoring => 'Restauration...';

  @override
  String get backupRestoringMessage =>
      'Veuillez patienter pendant la restauration de votre coffre.';

  @override
  String get backupRestoreComplete => 'Restauration terminée';

  @override
  String get backupRestoreCompleteMessage =>
      'Votre coffre a été restauré avec succès depuis la sauvegarde.';

  @override
  String backupDeleteConfirmation(String date) {
    return 'Êtes-vous sûr de vouloir supprimer la sauvegarde du $date ? Cette action est irréversible.';
  }

  @override
  String get backupRememberPassphrase =>
      'Mémoriser la phrase secrète sur cet appareil';

  @override
  String get backupCloudProviderLabel => 'FOURNISSEUR CLOUD';

  @override
  String get backupUploading => 'Envoi en cours...';

  @override
  String get backupUploadToICloud => 'Envoyer vers iCloud';

  @override
  String get backupAppleIdAutomatic =>
      'Utilise votre identifiant Apple automatiquement';

  @override
  String get backupGoogleAuthOpened =>
      'Une fenêtre de navigateur s\'est ouverte pour l\'autorisation Google.';

  @override
  String get backupGoogleAuthApprove =>
      'Approuvez l\'accès. Après la redirection, copiez la valeur \"code\" de la barre d\'adresse et collez-la ci-dessous.';

  @override
  String get backupICloudComingSoon =>
      'L\'intégration native iCloud arrive bientôt. Utilisez Dropbox pour le moment.';

  @override
  String get backupInterruptedRestoreDetected =>
      'Restauration interrompue détectée';

  @override
  String get backupFrequencyError =>
      'Impossible de mettre à jour la fréquence de sauvegarde.';

  @override
  String get backupDisconnectError =>
      'La déconnexion a échoué. Veuillez réessayer.';

  @override
  String get searchPartialError =>
      'Certains résultats peuvent être manquants en raison d\'une erreur.';

  @override
  String get documentShowAll => 'Tout afficher';

  @override
  String get backupErrorLoad => 'Impossible de charger les sauvegardes.';

  @override
  String get backupErrorRollback =>
      'Le nettoyage du rollback a échoué. Veuillez réessayer.';

  @override
  String get backupErrorCreate => 'La sauvegarde a échoué. Veuillez réessayer.';

  @override
  String get backupErrorRestore =>
      'La restauration a échoué. Vérifiez votre phrase secrète.';

  @override
  String get backupErrorDelete => 'Impossible de supprimer la sauvegarde.';

  @override
  String get backupErrorConnectDropbox =>
      'Connectez Dropbox dans les paramètres de synchronisation.';

  @override
  String get backupErrorUpload => 'L\'envoi a échoué. Veuillez réessayer.';

  @override
  String get backupErrorDropboxNotConnected => 'Dropbox n\'est pas connecté.';

  @override
  String get backupErrorCloudRestore =>
      'La restauration cloud a échoué. Veuillez réessayer.';

  @override
  String get backupSuccessUpload => 'Envoyé vers Dropbox avec succès.';

  @override
  String get backupSuccessCloudRestore =>
      'Restauré depuis la sauvegarde cloud avec succès.';

  @override
  String get backupGoogleDriveLabel => 'Google Drive';

  @override
  String get syncErrorLoad =>
      'Impossible de charger les paramètres de synchronisation.';

  @override
  String get syncErrorSave => 'Impossible d\'enregistrer les paramètres.';

  @override
  String get syncErrorRun => 'Impossible de lancer la synchronisation.';

  @override
  String get generatorErrorGenerate => 'Impossible de générer le mot de passe.';

  @override
  String get profileErrorLoad =>
      'Impossible de charger le profil pour le moment.';

  @override
  String get profileErrorShareOptions =>
      'Impossible de charger les options de partage.';

  @override
  String get profileErrorVCard =>
      'Impossible de générer la vCard pour le moment.';

  @override
  String get documentsErrorLoad => 'Impossible de charger les documents.';

  @override
  String get documentsErrorCompany =>
      'Impossible de charger les détails de l\'entreprise.';

  @override
  String get documentsErrorWorkVaults =>
      'Impossible de charger les coffres professionnels.';

  @override
  String get documentsErrorSecureIds =>
      'Impossible de charger les pièces d\'identité.';

  @override
  String get documentTimelineTitle => 'Chronologie des Documents';

  @override
  String get documentTimelineEmpty =>
      'Aucun document avec date d\'expiration pour le moment.';

  @override
  String get documentTimelineErrorLoad =>
      'Impossible de charger les documents arrivant à expiration.';

  @override
  String get documentTimelineNoMatches =>
      'Aucun document ne correspond au filtre sélectionné.';

  @override
  String get documentTimelineExpired => 'Expiré';

  @override
  String get documentTimelineSoon => 'Expire Bientôt';

  @override
  String get documentTimelineSafe => 'Valide';

  @override
  String get documentTimelineFilterAll => 'Tous';

  @override
  String get documentTimelineFilterExpired => 'Expiré';

  @override
  String get documentTimelineFilterCritical => '<30j';

  @override
  String get documentTimelineFilterWarning => '<90j';

  @override
  String get documentTimelineFilterSafe => 'Sûr';

  @override
  String documentTimelineDaysRemaining(int days) {
    return '$days jours restants';
  }

  @override
  String documentTimelineExpiredDaysAgo(int days) {
    return 'Expiré il y a $days jours';
  }

  @override
  String get documentTimelineExpiresToday => 'Expire aujourd\'hui';

  @override
  String get collectionsErrorLoad => 'Impossible de charger les collections.';

  @override
  String get collectionsErrorCreate => 'Impossible de créer la collection.';

  @override
  String get collectionsErrorDelete => 'Impossible de supprimer la collection.';

  @override
  String get collectionsErrorDetail =>
      'Impossible de charger cette collection.';

  @override
  String get credentialsErrorLoad => 'Impossible de charger les identifiants.';

  @override
  String get credentialsErrorDetail =>
      'Impossible de charger les détails de l\'identifiant.';

  @override
  String get shareTitle => 'Partage Sécurisé';

  @override
  String get sharePassphraseHint => 'Phrase de passe';

  @override
  String get shareTtlLabel => 'Le lien expire dans :';

  @override
  String get shareTtl1Hour => '1 Heure';

  @override
  String get shareTtl1Day => '1 Jour';

  @override
  String get shareTtl7Days => '7 Jours';

  @override
  String get shareTtlOneTime => 'Affichage Unique';

  @override
  String get shareGenerateLink => 'Générer le lien';

  @override
  String get shareCopyLink => 'Lien copié dans le presse-papiers !';

  @override
  String get shareLinkCopied => 'Lien de partage copié !';

  @override
  String get sharePassphraseReminder =>
      'Important : Partagez la phrase de passe séparément via un canal sécurisé';

  @override
  String get importTitle => 'Importer des identifiants';

  @override
  String get importSelectSource => 'Sélectionner la source d\'importation';

  @override
  String get importSelectFile => 'Sélectionner un fichier';

  @override
  String get importPreview => 'Vérifier les identifiants';

  @override
  String get importComplete => 'Importation terminée';

  @override
  String importFound(int count) {
    return '$count identifiants trouvés';
  }

  @override
  String importDuplicates(int count) {
    return '$count doublons détectés';
  }

  @override
  String get importSelectAll => 'Tout sélectionner';

  @override
  String get importDeselectDuplicates => 'Désélectionner les doublons';

  @override
  String get importImportSelected => 'Importer la sélection';

  @override
  String get importSuccess => 'Importation réussie';

  @override
  String importCompleted(int imported, int skipped) {
    return '$imported identifiants importés, $skipped doublons ignorés';
  }

  @override
  String importErrors(int count) {
    return '$count erreurs se sont produites';
  }

  @override
  String get importInstructions1Password =>
      'Exportez votre coffre 1Password en CSV. Allez dans Fichier > Exporter et choisissez le format CSV.';

  @override
  String get importInstructionsBitwarden =>
      'Exportez depuis Bitwarden en JSON. Allez dans Paramètres > Exporter le coffre et choisissez le format JSON.';

  @override
  String get importInstructionsChrome =>
      'Exportez depuis le gestionnaire de mots de passe Chrome. Allez dans Paramètres > Mots de passe et exportez vos données en CSV.';

  @override
  String get importInstructionsSafari =>
      'Exportez depuis Safari. Allez dans Fichier > Exporter les mots de passe et sélectionnez les identifiants à exporter.';

  @override
  String get importInstructionsLastPass =>
      'Exportez depuis LastPass en CSV. Allez dans Coffre > Plus d\'options > Exporter et choisissez le format CSV.';

  @override
  String get vaultHealthPageTitle => 'Santé du Coffre';

  @override
  String get vaultHealthOut => 'sur 100';

  @override
  String vaultHealthLastChecked(String time) {
    return 'Vérifié $time';
  }

  @override
  String get vaultHealthGradeExcellent => 'Excellent';

  @override
  String get vaultHealthGradeGood => 'Bon';

  @override
  String get vaultHealthGradeFair => 'Acceptable';

  @override
  String get vaultHealthGradePoor => 'Faible';

  @override
  String get vaultHealthSummaryTitle => 'Résumé';

  @override
  String get vaultHealthWeakCount => 'Mots de passe faibles';

  @override
  String get vaultHealthReusedCount => 'Mots de passe réutilisés';

  @override
  String get vaultHealthBreachedCount => 'Compromis';

  @override
  String get vaultHealthExpiringCount => 'Expire bientôt';

  @override
  String vaultHealthIssuesTitle(int count) {
    return '$count Problèmes détectés';
  }

  @override
  String get vaultHealthNoIssues => 'Aucun Problème Détecté';

  @override
  String get vaultHealthAllGood => 'Votre coffre est en excellent état!';

  @override
  String get vaultHealthCritical => 'Critique';

  @override
  String get vaultHealthHigh => 'Élevé';

  @override
  String get vaultHealthMedium => 'Moyen';

  @override
  String get vaultHealthLow => 'Faible';

  @override
  String get navBundles => 'Dossiers';

  @override
  String get bundlesTitle => 'Dossiers';

  @override
  String get bundlesEmptyTitle => 'Aucun dossier pour l\'instant';

  @override
  String get bundlesEmptySubtitle =>
      'Créez un dossier pour regrouper des fichiers et identifiants pour une demande, un voyage ou tout autre usage.';

  @override
  String get bundlesErrorLoad => 'Impossible de charger les dossiers.';

  @override
  String get bundleCreateAction => 'Nouveau dossier';

  @override
  String get bundleCreateTitle => 'Créer un dossier';

  @override
  String get bundleCreateError =>
      'Impossible de créer le dossier. Veuillez réessayer.';

  @override
  String get bundleFieldTitle => 'Titre';

  @override
  String get bundleFieldTitleHint => 'ex. Demande de visa France';

  @override
  String get bundleFieldTitleRequired => 'Le titre est requis';

  @override
  String get bundleFieldPurpose => 'Objet (optionnel)';

  @override
  String get bundleFieldPurposeHint => 'ex. Visa Schengen — fév. 2026';

  @override
  String get bundleFieldDescription => 'Description (optionnelle)';

  @override
  String get bundleFieldDescriptionHint => 'À quoi sert ce dossier ?';

  @override
  String get bundleStatusDraft => 'Brouillon';

  @override
  String get bundleStatusReady => 'Prêt';

  @override
  String get bundleStatusExported => 'Exporté';

  @override
  String get bundleStatusArchived => 'Archivé';

  @override
  String bundleItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
      zero: 'aucun élément',
    );
    return '$_temp0';
  }

  @override
  String bundleUpdatedAt(Object date) {
    return 'modifié $date';
  }

  @override
  String bundleLastExportedAt(Object date) {
    return 'exporté $date';
  }

  @override
  String get bundleDeleteTitle => 'Supprimer le dossier ?';

  @override
  String bundleDeleteMessage(Object title) {
    return '« $title » sera définitivement supprimé.';
  }

  @override
  String get bundleDeleteConfirm => 'Supprimer';

  @override
  String get bundleDetailLoadingTitle => 'Dossier';

  @override
  String get bundleDetailErrorLoad => 'Impossible de charger ce dossier.';

  @override
  String get bundleDetailMenuTooltip => 'Plus';

  @override
  String get bundleActionExport => 'Exporter / partager';

  @override
  String get bundleTemplateSelectedBadge => 'Selectionne';

  @override
  String get bundleTemplateSectionTitle => 'Commencer avec un modele';

  @override
  String get bundleTemplateSectionSubtitle =>
      'Les modeles pre-remplissent le dossier et suivent les elements requis pour voir ce qui manque.';

  @override
  String get bundleTemplateBlankTitle => 'Dossier vide';

  @override
  String get bundleTemplateBlankSubtitle =>
      'Commencer vide et ajouter les elements manuellement.';

  @override
  String get bundleTemplatePrefillHint =>
      'Choisir un modele pre-remplit les champs du dossier et cherche les elements correspondants dans le coffre.';

  @override
  String get bundleTemplateFranceVisaTitle => 'Visa France';

  @override
  String get bundleTemplateFranceVisaSummary =>
      'Identite, voyage, logement, emploi, assurance et justificatifs financiers.';

  @override
  String get bundleTemplateApartmentRentalTitle => 'Location d\'appartement';

  @override
  String get bundleTemplateApartmentRentalSummary =>
      'Identite, revenus, emploi, impots et quittances de loyer.';

  @override
  String get bundleTemplateJobOnboardingTitle => 'Arrivee nouveau poste';

  @override
  String get bundleTemplateJobOnboardingSummary =>
      'Contrat, identite, coordonnees bancaires et diplomes.';

  @override
  String get bundleTemplateTravelClaimTitle => 'Note de frais voyage';

  @override
  String get bundleTemplateTravelClaimSummary =>
      'Reservations, recus, factures et justificatifs de remboursement.';

  @override
  String get bundleTemplateChecklistTitle => 'Checklist du modele';

  @override
  String bundleTemplateChecklistSubtitle(int completed, int total) {
    return '$completed sur $total elements requis prets';
  }

  @override
  String get bundleTemplateAddMissingAction => 'Ajouter manquants';

  @override
  String get bundleTemplateReadyTitle => 'Pret a exporter';

  @override
  String get bundleTemplateMissingTitle => 'Elements requis manquants';

  @override
  String get bundleTemplateReadySubtitle =>
      'Tous les elements requis sont ajoutes.';

  @override
  String bundleTemplateMissingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elements requis manquent',
      one: '1 element requis manque',
    );
    return '$_temp0';
  }

  @override
  String get bundleTemplateRequiredLabel => 'Requis';

  @override
  String get bundleTemplateCompletedLabel => 'Completes';

  @override
  String get bundleTemplateOptionalLabel => 'Optionnels';

  @override
  String bundleTemplateMatchedCount(int matched, int minimum) {
    return '$matched sur $minimum';
  }

  @override
  String get bundleActionArchive => 'Archiver';

  @override
  String get bundleActionUnarchive => 'Désarchiver';

  @override
  String get bundleActionDelete => 'Supprimer le dossier';

  @override
  String get bundleSectionItems => 'Éléments';

  @override
  String get bundleSectionHistory => 'Historique';

  @override
  String get bundleEmptyItems =>
      'Aucun élément. Touchez « Ajouter des éléments » pour choisir dans votre coffre.';

  @override
  String get bundleAddItems => 'Ajouter des éléments';

  @override
  String get bundleHistoryEmpty => 'Aucune activité pour l\'instant.';

  @override
  String get bundleEventCreated => 'Dossier créé';

  @override
  String get bundleEventRenamed => 'Renommé';

  @override
  String get bundleEventPurposeUpdated => 'Objet mis à jour';

  @override
  String get bundleEventDescriptionUpdated => 'Description mise à jour';

  @override
  String get bundleEventItemAdded => 'Élément ajouté';

  @override
  String get bundleEventItemRemoved => 'Élément retiré';

  @override
  String get bundleEventItemReordered => 'Éléments réorganisés';

  @override
  String get bundleEventStatusChanged => 'Statut modifié';

  @override
  String get bundleEventExported => 'Exporté';

  @override
  String get bundleEventArchived => 'Archivé';

  @override
  String get bundleEventRestored => 'Restauré';

  @override
  String get bundleAddToTitle => 'Ajouter à un dossier';

  @override
  String bundleAddToSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Choisissez un dossier pour $count éléments',
      one: 'Choisissez un dossier pour 1 élément',
    );
    return '$_temp0';
  }

  @override
  String get bundleAddToNew => 'Nouveau';

  @override
  String get bundleAddToEmpty =>
      'Vous n\'avez aucun dossier. Touchez « Nouveau » pour en créer un.';

  @override
  String bundleAddToSnackbar(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments ajoutés au dossier.',
      one: '1 élément ajouté au dossier.',
    );
    return '$_temp0';
  }

  @override
  String get bundleExportTitle => 'Exporter le dossier';

  @override
  String get bundleExportSectionWhat => 'Dossier';

  @override
  String get bundleExportSectionOptions => 'Options';

  @override
  String get bundleExportEncryptTitle => 'Chiffrer l\'archive';

  @override
  String get bundleExportEncryptSubtitle =>
      'Protéger le ZIP par un mot de passe (AES-256).';

  @override
  String get bundleExportPassphraseLabel => 'Phrase secrète';

  @override
  String get bundleExportPassphraseHint =>
      'Transmettez-la au destinataire séparément';

  @override
  String get bundleExportPassphraseRequired =>
      'Veuillez saisir une phrase secrète.';

  @override
  String get bundleExportRunAction => 'Créer l\'archive';

  @override
  String get bundleExportError => 'Échec de l\'export. Veuillez réessayer.';

  @override
  String get bundleExportSuccess => 'Archive prête';

  @override
  String get bundleExportShare => 'Partager l\'archive';

  @override
  String bundleSearchPickBanner(Object title) {
    return 'Sélection d\'éléments pour « $title »';
  }

  @override
  String get bundleSearchPickBannerGeneric =>
      'Touchez des éléments à ajouter à un dossier';

  @override
  String bundleSearchSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '1 sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get bundleSearchClearSelection => 'Effacer';

  @override
  String get bundleSearchAddSelected => 'Ajouter la sélection';

  @override
  String get bundleSearchAddToBundle => 'Ajouter à un dossier';

  @override
  String get bundleTimeJustNow => 'à l\'instant';

  @override
  String bundleTimeMinutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count min',
      one: 'il y a 1 min',
    );
    return '$_temp0';
  }

  @override
  String bundleTimeHoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count h',
      one: 'il y a 1 h',
    );
    return '$_temp0';
  }

  @override
  String get bundleTimeYesterday => 'hier';

  @override
  String bundleTimeDaysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get bundlePreviewUnavailable =>
      'L\'aperçu n\'est pas encore disponible pour ce type d\'élément.';

  @override
  String get navTasks => 'Tâches';

  @override
  String get tasksTitle => 'Tâches';

  @override
  String get tasksEmptyTitle => 'Aucune liste pour l\'instant';

  @override
  String get tasksEmptySubtitle =>
      'Créez une liste pour suivre ce que vous devez faire — courses, projet, checklist de voyage.';

  @override
  String get tasksErrorLoad => 'Impossible de charger les listes de tâches.';

  @override
  String get tasksListCreateAction => 'Nouvelle liste';

  @override
  String get tasksListCreateTitle => 'Créer une liste de tâches';

  @override
  String get tasksListCreateError =>
      'Impossible de créer la liste. Veuillez réessayer.';

  @override
  String get tasksListFieldTitle => 'Titre';

  @override
  String get tasksListFieldTitleHint => 'ex. Préparation demande de visa';

  @override
  String get tasksListFieldTitleRequired => 'Le titre est requis';

  @override
  String get tasksListFieldDescription => 'Description (optionnelle)';

  @override
  String get tasksListFieldDescriptionHint => 'À quoi sert cette liste ?';

  @override
  String get tasksListPickIcon => 'Icône';

  @override
  String get tasksListPickColor => 'Couleur';

  @override
  String get tasksListLoadingTitle => 'Tâches';

  @override
  String get tasksListErrorLoad => 'Impossible de charger cette liste.';

  @override
  String get tasksHideArchived => 'Masquer archivées';

  @override
  String get tasksShowArchived => 'Afficher archivées';

  @override
  String get tasksHideDone => 'Masquer terminées';

  @override
  String get tasksShowDone => 'Afficher terminées';

  @override
  String tasksOverdueBadge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en retard',
      one: '1 en retard',
    );
    return '$_temp0';
  }

  @override
  String tasksOpenCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ouvertes',
      one: '1 ouverte',
      zero: 'aucune ouverte',
    );
    return '$_temp0';
  }

  @override
  String tasksDoneCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terminées',
      one: '1 terminée',
      zero: '0 terminée',
    );
    return '$_temp0';
  }

  @override
  String get tasksActionArchive => 'Archiver';

  @override
  String get tasksActionUnarchive => 'Désarchiver';

  @override
  String get tasksActionDelete => 'Supprimer';

  @override
  String get tasksActionPin => 'Épingler en haut';

  @override
  String get tasksActionUnpin => 'Désépingler';

  @override
  String get tasksDeleteListTitle => 'Supprimer la liste ?';

  @override
  String tasksDeleteListMessage(Object title) {
    return '« $title » et toutes ses tâches seront définitivement supprimées.';
  }

  @override
  String get tasksDeleteListConfirm => 'Supprimer';

  @override
  String get taskCreateAction => 'Ajouter une tâche';

  @override
  String get taskCreateTitle => 'Nouvelle tâche';

  @override
  String get taskEditTitle => 'Modifier la tâche';

  @override
  String get taskFieldTitle => 'Tâche';

  @override
  String get taskFieldTitleHint => 'Que faut-il faire ?';

  @override
  String get taskFieldNotes => 'Notes';

  @override
  String get taskFieldNotesHint => 'Détails, sous-étapes, contexte…';

  @override
  String get taskFieldPriority => 'Priorité';

  @override
  String get taskFieldDue => 'Échéance';

  @override
  String get taskFieldDueNone => 'Aucune échéance';

  @override
  String get taskFieldDueClear => 'Retirer l\'échéance';

  @override
  String get taskFieldPin => 'Épingler cette tâche';

  @override
  String get taskFieldPinHint =>
      'Les tâches épinglées restent en haut de la liste.';

  @override
  String get taskFieldLink => 'Élément lié (optionnel)';

  @override
  String get taskFieldLinkNone =>
      'Touchez pour lier un document, un identifiant ou un dossier';

  @override
  String get taskFieldLinkClear => 'Retirer le lien';

  @override
  String get taskPriorityLow => 'Basse';

  @override
  String get taskPriorityMedium => 'Moyenne';

  @override
  String get taskPriorityHigh => 'Haute';

  @override
  String get taskDueToday => 'À faire aujourd\'hui';

  @override
  String get taskDueTomorrow => 'À faire demain';

  @override
  String taskDueInDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dans $count jours',
      one: 'Dans 1 jour',
    );
    return '$_temp0';
  }

  @override
  String taskDueOverdueBy(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En retard de $count jours',
      one: 'En retard de 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get tasksSectionPinned => 'Épinglées';

  @override
  String get tasksSectionOverdue => 'En retard';

  @override
  String get tasksSectionToday => 'Aujourd\'hui';

  @override
  String get tasksSectionUpcoming => 'À venir';

  @override
  String get tasksSectionNoDate => 'Sans échéance';

  @override
  String get tasksSectionDone => 'Terminées';

  @override
  String get tasksStatOpen => 'Ouvertes';

  @override
  String get tasksStatDone => 'Terminées';

  @override
  String get tasksStatOverdue => 'En retard';

  @override
  String get tasksDetailEmpty =>
      'Aucune tâche. Touchez « Ajouter une tâche » pour créer la première.';

  @override
  String get tasksEnterReorder => 'Réorganiser';

  @override
  String get tasksExitReorder => 'Terminer la réorganisation';
}
