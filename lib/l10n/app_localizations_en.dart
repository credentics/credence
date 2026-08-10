// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Credence';

  @override
  String get tabHome => 'Home';

  @override
  String get tabCredentials => 'Credentials';

  @override
  String get tabGenerator => 'Generator';

  @override
  String get tabDocuments => 'Documents';

  @override
  String get tabProfile => 'Profile';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get commonErrorLoad => 'Unable to load data. Tap retry to try again.';

  @override
  String get commonViewAll => 'View All';

  @override
  String get commonPasswordCopiedSecurely => 'Password copied securely.';

  @override
  String get commonUnableCopyPassword => 'Unable to copy password.';

  @override
  String get tooltipCopyPassword => 'Copy password';

  @override
  String get tooltipOpenDetails => 'Open details';

  @override
  String get credentialsTitle => 'Credentials';

  @override
  String get credentialsUnableLoadVaultOverview =>
      'Unable to load vault overview.';

  @override
  String get credentialsUnableLoadAccounts => 'Unable to load accounts.';

  @override
  String get credentialsUnableLoadSingle => 'Unable to load credential.';

  @override
  String get credentialsNoAccountsFound => 'No accounts found.';

  @override
  String credentialsNoResultsForQuery(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get credentialsGeneratorCardTitle => 'Password Generator';

  @override
  String get credentialsGeneratorCardSubtitle =>
      'Create secure passwords in one tap';

  @override
  String get credentialsDesktopSubtitle => 'Offline vault, instant access';

  @override
  String get credentialsAdded => 'Credential added.';

  @override
  String get credentialsUnableAdd => 'Unable to add credential.';

  @override
  String get credentialsUpdated => 'Credential updated.';

  @override
  String get credentialsUnableUpdate =>
      'Unable to update credential right now.';

  @override
  String get credentialsSavingLogo => 'Saving logo locally...';

  @override
  String get credentialsNewCredential => 'New Credential';

  @override
  String get credentialsSingleCredential => 'Credential';

  @override
  String get credentialsLogoSavingInProgress =>
      'Logo is still saving locally. Please wait a moment.';

  @override
  String get credentialsRequiredFieldsMissing =>
      'Service, username and password are required.';

  @override
  String get credentialsLookForAnotherIcon => 'Look for another icon';

  @override
  String get credentialsResetIcon => 'Reset icon';

  @override
  String get credentialsCategory => 'Category';

  @override
  String get credentialsSearchEnterServiceOrWebsite =>
      'Enter service name or website first.';

  @override
  String get credentialsNoMatchingIconFound =>
      'No matching company icon found.';

  @override
  String get credentialsSelectSuggestedBrand =>
      'Select a suggested brand to update icon and site.';

  @override
  String get credentialsUnableSearchBrands =>
      'Unable to search brands right now.';

  @override
  String get credentialsLogoPreviewLoadedLocalSaveFailed =>
      'Logo preview loaded, but local save failed for this brand.';

  @override
  String get credentialsUnableSaveLogoLocally => 'Unable to save logo locally.';

  @override
  String get credentialsEmailCopied => 'Email copied.';

  @override
  String get credentialsPasswordCopied => 'Password copied.';

  @override
  String get credentialsNoUrlToCopy => 'No URL to copy.';

  @override
  String get credentialsWebsiteCopied => 'Website URL copied.';

  @override
  String get credentialsAddToFavorites => 'Add to Favorites';

  @override
  String get credentialsAddedToFavorites => 'Added to favorites.';

  @override
  String get credentialsAddToSiriShortcuts => 'Add to Siri Shortcuts';

  @override
  String get credentialsSiriShortcutReady => 'Siri Shortcut action ready.';

  @override
  String get credentialsDelete => 'Delete';

  @override
  String get credentialsDeleteNeedsConfirmation =>
      'Delete action requires confirmation.';

  @override
  String get credentialFieldAccountLabel => 'Account Label';

  @override
  String get credentialFieldEmailUsername => 'Email/Username';

  @override
  String get credentialFieldPassword => 'Password';

  @override
  String get credentialFieldWebsiteUrl => 'URL';

  @override
  String get credentialFieldNotes => 'Notes';

  @override
  String get credentialEditServicePlaceholder => 'GitHub';

  @override
  String get credentialEditAccountPlaceholder => 'Personal Account';

  @override
  String get credentialEditEmailPlaceholder => 'jane.smith@email.com';

  @override
  String get credentialEditUrlPlaceholder => 'https://github.com';

  @override
  String get credentialEditNotesPlaceholder =>
      'Recovery code, security notes, reminders...';

  @override
  String get credentialsSearchHint => 'Search credentials...';

  @override
  String credentialsSearchCountHint(int count) {
    return 'Search $count credentials...';
  }

  @override
  String get homeWelcomeBack => 'Welcome back';

  @override
  String homeGreetingNamed(String name) {
    return 'Hi, $name.';
  }

  @override
  String get homeGreetingFallback => 'Hi.';

  @override
  String get homeOwnerName => 'Vault Owner';

  @override
  String get homeSearchVaultDocuments => 'Search vault, documents...';

  @override
  String get homeActionRequired => 'ACTION REQUIRED';

  @override
  String get homeSecurityCheckRecommended => 'Security check is recommended.';

  @override
  String get homeReviewNow => 'Review now';

  @override
  String get homeAllCredentialsSecure =>
      'All credentials look secure right now.';

  @override
  String get homeFrequentlyUsed => 'Frequently Used';

  @override
  String get homeNoQuickItemsYet => 'No quick items yet.';

  @override
  String get homeRecentItems => 'Recent Items';

  @override
  String get homeRecentActivityPlaceholder =>
      'Your recent activity will show here.';

  @override
  String homeLastUsedWithTime(String username, String time) {
    return '$username • Last used $time';
  }

  @override
  String get homeRelativeJustNow => 'Just now';

  @override
  String homeRelativeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String homeRelativeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get homeRelativeYesterday => 'Yesterday';

  @override
  String homeRelativeDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String homeRelativeWeeksAgo(int weeks) {
    return '${weeks}w ago';
  }

  @override
  String homeRelativeMonthsAgo(int months) {
    return '${months}mo ago';
  }

  @override
  String get securitySettingsTitle => 'Security Settings';

  @override
  String documentsPageComingSoon(String category) {
    return '$category documents page is coming next.';
  }

  @override
  String get desktopLocalDataOnly => 'Data stays local to this device';

  @override
  String get passwordHealthChecking => 'Checking...';

  @override
  String get passwordHealthWeak => 'Weak';

  @override
  String get passwordHealthFair => 'Fair';

  @override
  String get passwordHealthStrong => 'Strong';

  @override
  String get passwordHealthExcellent => 'Excellent';

  @override
  String get profileExportVaultData => 'Export Vault Data';

  @override
  String get profileUnableLoad => 'Unable to load profile right now.';

  @override
  String get profileShareSecureProfileTitle => 'Share Secure Profile';

  @override
  String get profileShareSecureProfileSubtitle =>
      'Generate a temporary encrypted vCard';

  @override
  String get profileAccountDetailsTitle => 'Account Details';

  @override
  String get profileAccountDetailsSection => 'ACCOUNT DETAILS';

  @override
  String get profileRecentActivityTitle => 'Recent Activity';

  @override
  String get profileRecentActivitySection => 'RECENT ACTIVITY';

  @override
  String get profileExporting => 'Exporting...';

  @override
  String get profileExportHint =>
      'Exported data is encrypted and requires your master password to decrypt on another device.';

  @override
  String get profileAddAccountDetailsFirst =>
      'Add account details first before sharing profile.';

  @override
  String get profileExportStatusPreparing => 'Preparing export...';

  @override
  String get profileExportStatusSelectDestination =>
      'Select destination to save archive...';

  @override
  String get profileExportStatusOpeningShareSheet => 'Opening share sheet...';

  @override
  String get profileExportSavedLocally => 'Vault archive saved locally.';

  @override
  String profileExportSavedAt(String path) {
    return 'Vault archive saved: $path';
  }

  @override
  String get profileExportGeneratedAndShared =>
      'Vault archive generated and shared.';

  @override
  String get profileExportStatusFailed => 'Export failed.';

  @override
  String get profileUnableExportVaultData =>
      'Unable to export vault data right now.';

  @override
  String get profileExportPassphraseTitle => 'Export Passphrase';

  @override
  String get profileExportPassphraseHint => 'Enter export passphrase';

  @override
  String get profileExportAction => 'Export';

  @override
  String get profileExportStatusOpeningSaveDialog =>
      'Opening save destination dialog...';

  @override
  String get profileExportSaveArchiveButton => 'Save Vault Archive';

  @override
  String get profileExportStatusSaveDialogTimedOut =>
      'Save dialog timed out on this platform; using local fallback path.';

  @override
  String get profileExportStatusNoSaveLocation =>
      'Save dialog closed without location.';

  @override
  String get profileExportStatusSavingArchive => 'Saving archive file...';

  @override
  String profileExportStatusArchiveSaved(String path) {
    return 'Archive saved to $path';
  }

  @override
  String get profileExportStatusSaveDialogFailed =>
      'Save dialog failed; trying fallback location...';

  @override
  String get profileExportStatusSavedFallback => 'Saved to fallback location.';

  @override
  String profileExportStatusFallbackSaveSuccess(String path) {
    return 'Fallback save success: $path';
  }

  @override
  String get profileExportStatusFallbackSaveFailed => 'Fallback save failed.';

  @override
  String get profileExportArchiveNotFound => 'Archive file not found.';

  @override
  String profileExportShareText(int documents, int credentials, int files) {
    return 'Vault archive ($documents docs, $credentials credentials, $files linked files)';
  }

  @override
  String get profileExportInProgress => 'Export in progress';

  @override
  String get profileFullName => 'Full Name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileNotProvided => 'Not provided';

  @override
  String get profileNoRecentActivityYet => 'No recent activity yet.';

  @override
  String get profileNoActivityYet => 'No activity yet';

  @override
  String get profileNoActivitySubtitle =>
      'Your vault is empty. All your\nsecurity events will appear\nhere.';

  @override
  String profileActivityWithTime(String subtitle, String time) {
    return '$subtitle • $time';
  }

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileUpdatePhoto => 'Update Photo';

  @override
  String get profileTapChangePhoto => 'Tap to change your profile picture';

  @override
  String get profileFirstName => 'First Name';

  @override
  String get profileLastName => 'Last Name';

  @override
  String get profileEmailAddress => 'Email Address';

  @override
  String get profileSecurePhone => 'Secure Phone';

  @override
  String get profileContactInfoSecurityNotice =>
      'Changes to your contact information may require secondary authentication for security purposes. Your vault remains encrypted.';

  @override
  String get profileSaveChanges => 'Save Changes';

  @override
  String get profileChooseFromLibrary => 'Choose from Library';

  @override
  String get profileTakePhoto => 'Take Photo';

  @override
  String get profileRequiredFieldsMessage =>
      'First name, last name and email are required.';

  @override
  String get profileUnableSave => 'Unable to save profile right now.';

  @override
  String get profileShareTitle => 'Share Profile';

  @override
  String get profileShareSubtitle =>
      'Select the information you want to include in your encrypted vCard.';

  @override
  String get profileShareAttributesSection => 'PROFILE ATTRIBUTES';

  @override
  String get profileShareSecurityOptionsSection => 'SECURITY OPTIONS';

  @override
  String get profileShareGenerating => 'Generating...';

  @override
  String get profileShareGenerateSecureLink => 'Generate vCard';

  @override
  String get profileShareQrCode => 'Preview vCard';

  @override
  String get profileShareCopyLink => 'Copy vCard';

  @override
  String profileShareLinkExpires(String date) {
    return 'vCard valid until $date';
  }

  @override
  String get profileSharePoweredByEncryption =>
      'POWERED BY END-TO-END ENCRYPTION';

  @override
  String profileShareHoursLabel(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get profileShareGenerateFirst => 'Generate a vCard first.';

  @override
  String get profileShareLinkCopied => 'vCard copied.';

  @override
  String get profileShareSecureLink => 'vCard';

  @override
  String get profileShareAction => 'Share';

  @override
  String get profileShareOptInTitle => 'Share is opt-in';

  @override
  String get profileShareOptInSubtitle =>
      'Only selected profile fields are included. No credentials, documents, collections, or vault data are shared.';

  @override
  String get profileShareEmptyAttributeValue => 'Not set';

  @override
  String get profilePhoneNumber => 'Phone Number';

  @override
  String get profileHomeAddress => 'Home Address';

  @override
  String get profileSocialLinks => 'Social Links';

  @override
  String profileShareExpirationLabel(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get profileShareLinkExpiration => 'vCard Validity';

  @override
  String get securitySectionBiometrics => 'BIOMETRICS';

  @override
  String get securitySectionVaultSecurity => 'VAULT SECURITY';

  @override
  String get securitySectionPrivacy => 'PRIVACY';

  @override
  String get securitySectionSync => 'SYNC';

  @override
  String get securitySectionAdvanced => 'ADVANCED';

  @override
  String get securityUseFaceId => 'Use FaceID';

  @override
  String get securityUseFaceIdSubtitle => 'Unlock your vault instantly';

  @override
  String get securityAutoLockTimer => 'Auto-lock timer';

  @override
  String get securityScreenshotProtection => 'Screenshot protection';

  @override
  String get securityScreenshotProtectionSubtitle => 'Block capture in app';

  @override
  String get securityAutoBlurFields => 'Auto-blur fields';

  @override
  String get securityClearClipboard => 'Clear clipboard';

  @override
  String get securitySyncStatus => 'Sync status';

  @override
  String get securitySyncTarget => 'Sync target';

  @override
  String get securityChangeMasterPassword => 'Change Master Password';

  @override
  String get securityChangeMasterPasswordHint =>
      'Update your sync passphrase in the encryption section.';

  @override
  String get securityExportData => 'Export Data';

  @override
  String get securityExportHint =>
      'Export is available from the portability flow.';

  @override
  String get securityVersionAndAudit => 'Credence v1.0.0';

  @override
  String get settingsUseAppSupportFolder => 'Use App Support Folder';

  @override
  String minutesLabel(int minutes) {
    return '$minutes minute';
  }

  @override
  String get syncTargetDisabled => 'Disabled';

  @override
  String get syncTargetLocalFolder => 'Local Folder';

  @override
  String get syncTargetDropboxCloud => 'Dropbox Cloud';

  @override
  String get settingsNavVault => 'VAULT';

  @override
  String get settingsNavKeys => 'KEYS';

  @override
  String get settingsNavSharing => 'SHARING';

  @override
  String get settingsNavSettings => 'SETTINGS';

  @override
  String get commonBack => 'Back';

  @override
  String get commonCopied => 'Copied.';

  @override
  String get commonShare => 'Share';

  @override
  String get documentArchived => 'Document archived.';

  @override
  String get documentDeleted => 'Document deleted.';

  @override
  String get documentForceExpire => 'Force expiration';

  @override
  String get documentForceExpireConfirm => 'Force expire';

  @override
  String get documentForceExpireDescription =>
      'This will mark the document as expired by setting its expiry date to yesterday.';

  @override
  String get documentForceExpireTitle => 'Force document expiration?';

  @override
  String get documentForcedExpired => 'Document marked as expired.';

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
  String get documentUnableLoad => 'Unable to load document.';

  @override
  String get documentUnableForceExpire =>
      'Unable to force document expiration right now.';

  @override
  String get documentUnableOpenPreview => 'Unable to open preview.';

  @override
  String get collectionUploadDropHere => 'Drop file here';

  @override
  String get documentPreviewNotAvailable =>
      'Preview is not available for this file type.\nYou can share it to open in another app.';

  @override
  String get documentUnableRemove => 'Unable to remove document right now.';

  @override
  String get documentUnableRenderImagePreview =>
      'Unable to render image preview.';

  @override
  String get documentUnableShareFile => 'Unable to share file right now.';

  @override
  String get documentUpdated => 'Document updated.';

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
  String get documentPreviewUnavailable => 'Preview unavailable';

  @override
  String get documentsUnableLoad => 'Unable to load documents.';

  @override
  String get documentsCategoriesTitle => 'Categories';

  @override
  String get documentsSelectCategory => 'Select category';

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
      zero: 'No documents',
    );
    return '$_temp0';
  }

  @override
  String documentsFilesCompact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
      zero: 'No files',
    );
    return '$_temp0';
  }

  @override
  String documentsAttentionCompact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need attention',
      one: '1 needs attention',
    );
    return '$_temp0';
  }

  @override
  String get documentsSearchHint => 'Search documents, files, notes';

  @override
  String get documentsRecentFilesTitle => 'Recent files';

  @override
  String get documentsCollectionsEntrySubtitle =>
      'Dynamic folders, notes, docs, expenses';

  @override
  String get documentsBundlesEntrySubtitle =>
      'Share packs, applications, exports';

  @override
  String get documentsTasksEntrySubtitle => 'Checklists and reminders';

  @override
  String documentsCountLabel(Object count) {
    return '$count Documents';
  }

  @override
  String documentsFilesCountLabel(int count) {
    return '$count Files';
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
      'Passport, ID, Driver\'s License';

  @override
  String get documentsCategoryWork => 'Work';

  @override
  String get documentsCategorySubtitleWork => 'Contracts, Payslips, Tax IDs';

  @override
  String get documentsCategoryProperty => 'Property';

  @override
  String get documentsCategorySubtitleProperty =>
      'Deeds, Rental Agreements, Utility';

  @override
  String get documentsCategoryAuto => 'Auto';

  @override
  String get documentsCategorySubtitleAuto =>
      'Registration, Insurance, Service';

  @override
  String get documentsCategoryHealth => 'Health';

  @override
  String get documentsCategorySubtitleHealth =>
      'Prescriptions, Medical Records';

  @override
  String get documentsCategoryTravel => 'Travel';

  @override
  String get documentsCategorySubtitleTravel =>
      'Trips, tickets, visas, itineraries';

  @override
  String get documentsCategoryOther => 'Other';

  @override
  String get documentsCategorySubtitleOther =>
      'Notes, invoices, and other files';

  @override
  String get travelTripsLoadError => 'Unable to load trips.';

  @override
  String get travelTripsTitle => 'Trips';

  @override
  String get travelTripsFilterUpcoming => 'Upcoming';

  @override
  String get travelTripsFilterPast => 'Past';

  @override
  String travelTripsStatusInDays(int days) {
    return 'IN $days DAYS';
  }

  @override
  String get travelTripsStatusPlanned => 'PLANNED';

  @override
  String get travelTripsDatesLabel => 'DATES';

  @override
  String travelTripsDocumentsCount(int count) {
    return '$count Documents';
  }

  @override
  String get travelTripsViewDetails => 'View Details';

  @override
  String get travelTripsStartNewTripTitle => 'Start a new trip';

  @override
  String get travelTripsStartNewTripSubtitle => 'BROWSE DESTINATIONS';

  @override
  String get travelTripsEmptyTitle => 'No trips yet';

  @override
  String get travelTripsEmptySubtitle =>
      'Create your first trip and start planning your timeline, expenses, and travel wallet.';

  @override
  String get travelTripsCreateFirstAction => 'Create First Trip';

  @override
  String get travelTripEntryTitle => 'Add New Trip';

  @override
  String get travelTripEditTitle => 'Edit Trip';

  @override
  String get travelTripDetailsSectionTitle => 'Trip Details';

  @override
  String get travelTripNotesTitle => 'Trip Notes';

  @override
  String get travelTripEntrySaveAction => 'Save Trip';

  @override
  String get travelTripEntryTitleField => 'Trip Name';

  @override
  String get travelTripEntryTitleHint => 'e.g. Summer in Tokyo';

  @override
  String get travelTripEntryDestinationField => 'Destination';

  @override
  String get travelTripEntryDestinationHint => 'e.g. Tokyo, Japan';

  @override
  String get travelTripEntryStartDateField => 'Start Date';

  @override
  String get travelTripEntryEndDateField => 'End Date';

  @override
  String get travelTripEntryCoverField => 'Trip Cover Image';

  @override
  String get travelTripEntryCoverHint => 'Select optional cover image';

  @override
  String get travelTripDetailLoadError => 'Unable to load this trip.';

  @override
  String get travelDashboardSectionTitle => 'Trip Dashboard';

  @override
  String get travelDashboardTimelineTitle => 'Timeline';

  @override
  String travelDashboardTimelineCount(int count) {
    return '$count events';
  }

  @override
  String get travelDashboardDestinationsTitle => 'Destinations';

  @override
  String travelDashboardDestinationsCount(int count) {
    return '$count places';
  }

  @override
  String get travelDashboardDocumentsTitle => 'Documents';

  @override
  String travelDashboardDocumentsCount(int count) {
    return '$count files';
  }

  @override
  String get travelDashboardExpensesTitle => 'Expenses';

  @override
  String travelDashboardExpensesSpent(String value) {
    return '$value spent';
  }

  @override
  String get travelDashboardWalletTitle => 'Travel Wallet';

  @override
  String travelDashboardWalletSummary(int count) {
    return '$count documents ready';
  }

  @override
  String get travelDashboardDefaultDestination => 'Your destination';

  @override
  String travelDashboardDaysLeft(int days) {
    return '$days Days Left';
  }

  @override
  String travelDashboardHeroTitle(String destination) {
    return 'Explore $destination';
  }

  @override
  String travelTimelineTitle(String trip) {
    return '$trip Trip Timeline';
  }

  @override
  String get travelTimelineEmptyTitle => 'No timeline events yet';

  @override
  String get travelTimelineEmptySubtitle =>
      'Add your first event to organize transport, stays, dining, and activities.';

  @override
  String get travelTimelineAddEventTitle => 'Add Timeline Event';

  @override
  String get travelTimelineAddAction => 'Add to Timeline';

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
  String get travelTimelineConfirmed => 'CONFIRMED';

  @override
  String travelTimelineDocumentsCount(int count) {
    return '$count Documents';
  }

  @override
  String get travelTimelineOpenMap => 'Open Map';

  @override
  String get travelExpensesTitle => 'Trip Expenses';

  @override
  String get travelExpensesTotalSpentTitle => 'Total Spent';

  @override
  String get travelExpensesRemainingTitle => 'Remaining';

  @override
  String get travelExpensesVsLastTrip => '~ +12% vs last trip';

  @override
  String travelExpensesBudgetLabel(String value) {
    return 'Budget: $value';
  }

  @override
  String get travelExpensesBudgetStatus => 'BUDGET STATUS';

  @override
  String travelExpensesSpentLabel(String value) {
    return '$value spent';
  }

  @override
  String travelExpensesLimitLabel(String value) {
    return '$value limit';
  }

  @override
  String get travelExpensesEmptyTitle => 'No expenses yet';

  @override
  String get travelExpensesEmptySubtitle =>
      'Add the first expense and track your trip budget in real time.';

  @override
  String get travelExpensesAddExpenseTitle => 'Add Expense';

  @override
  String get travelExpensesAddExpenseAction => 'Add Expense';

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
  String get travelBudgetTitle => 'Set Trip Budget';

  @override
  String get travelBudgetSaveAction => 'Save Budget';

  @override
  String travelBudgetAllocated(String value) {
    return 'Allocated: $value';
  }

  @override
  String travelBudgetRemaining(String value) {
    return 'Remaining: $value';
  }

  @override
  String get travelBudgetBreakdownTitle => 'Budget Breakdown';

  @override
  String get travelWalletTitle => 'Travel Wallet';

  @override
  String get travelWalletSectionOther => 'Other Documents';

  @override
  String get travelWalletEmptyTitle => 'No travel documents yet';

  @override
  String get travelWalletEmptySubtitle =>
      'Add tickets, visas, insurance and booking confirmations for quick access.';

  @override
  String get travelWalletAddDocumentAction => 'Add New Document';

  @override
  String get travelWalletUploadNewDocumentOption => 'Upload New Document';

  @override
  String get travelWalletChooseFromMyDocumentsOption =>
      'Choose from My Documents';

  @override
  String get travelWalletAddDocumentTitle => 'Add Travel Document';

  @override
  String get travelWalletSaveAction => 'Save to Wallet';

  @override
  String get travelWalletSelectFile => 'Select File';

  @override
  String get travelWalletPickerEmptyTitle => 'No documents found';

  @override
  String get travelWalletPickerEmptySubtitle =>
      'Upload a new document to your vault first.';

  @override
  String get travelWalletNoExpirationDate => 'No expiration date';

  @override
  String get travelWalletDocumentLinkedSuccess =>
      'Document linked to this trip.';

  @override
  String get propertyHubTitle => 'Property';

  @override
  String get propertyHubFilterAll => 'All';

  @override
  String get propertyHubFilterOwned => 'Owned';

  @override
  String get propertyHubFilterRented => 'Rented';

  @override
  String get propertyHubLoadError => 'Unable to load properties.';

  @override
  String get propertyHubEmptyTitle => 'No properties yet';

  @override
  String get propertyHubEmptySubtitle =>
      'Add your first property to start organizing your vault.';

  @override
  String get propertyHubAddAction => 'Add Property';

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
  String get propertyEntryNameHint => 'e.g. Blue Lagoon Villa';

  @override
  String get propertyEntryNameRequired => 'Property name is required';

  @override
  String get propertyEntryAddressLabel => 'Full Address';

  @override
  String get propertyEntryAddressHint => 'Enter street, city, and zip';

  @override
  String get propertyEntryAddressRequired => 'Full address is required';

  @override
  String get propertyEntryAddressSearching => 'Searching addresses...';

  @override
  String get propertyEntryAddressNotFound =>
      'Could not detect a valid address.';

  @override
  String get propertyEntryAutoDetect => 'Auto-detect Location';

  @override
  String get propertyEntryCategorizationTitle => 'Categorization';

  @override
  String get propertyEntryTypeLabel => 'Property Type';

  @override
  String get propertyEntryOwnershipLabel => 'Ownership Status';

  @override
  String get propertyEntryOwnedLabel => 'Owned';

  @override
  String get propertyEntryRentedLabel => 'Rented';

  @override
  String get propertyEntryCreateAction => 'Create Property Vault';

  @override
  String get propertyEntrySaveAction => 'Save Property';

  @override
  String get propertyEntrySaveFailed =>
      'Unable to save property. Please try again.';

  @override
  String get propertyDetailLoadError => 'Unable to load property details.';

  @override
  String get propertyDetailAssetsTitle => 'Property Assets';

  @override
  String propertyDetailTypeSubtitle(String type) {
    return '$type Property';
  }

  @override
  String get propertyDetailSubtitleFallback => 'Managed Property';

  @override
  String get propertyDetailAssetDocuments => 'Documents';

  @override
  String get propertyDetailAssetContracts => 'Contracts';

  @override
  String get propertyDetailAssetInsurance => 'Insurance';

  @override
  String get propertyDetailAssetPayments => 'Payments';

  @override
  String get propertyDetailAssetMaintenance => 'Maintenance';

  @override
  String get propertyDetailAssetOthers => 'Others';

  @override
  String propertyDetailFilesCount(int count) {
    return '$count files';
  }

  @override
  String propertyDetailRecordsCount(int count) {
    return '$count records';
  }

  @override
  String propertyDetailActiveRequestsCount(int count) {
    return '$count active requests';
  }

  @override
  String propertyDetailLastActivity(String activity, String relative) {
    return 'Last activity: $activity $relative';
  }

  @override
  String get propertyDocumentEntryTitle => 'Add Document';

  @override
  String get propertyDocumentInfoSection => 'Document Information';

  @override
  String get propertyDocumentCategoryLabel => 'Document Category';

  @override
  String get propertyDocumentCategoryHint => 'Select category';

  @override
  String get propertyDocumentCategoryRentPayment => 'Rent Payment';

  @override
  String get propertyDocumentTitleLabel => 'Document Title';

  @override
  String get propertyDocumentTitleHint => 'e.g. Lease Agreement 2024';

  @override
  String get propertyDocumentIssueDateLabel => 'Issue Date';

  @override
  String get propertyDocumentFinancialSection => 'Financial Details (Optional)';

  @override
  String get propertyDocumentAmountPaidLabel => 'Amount Paid';

  @override
  String get propertyDocumentAmountPaidHint => '\$ 0.00';

  @override
  String get propertyDocumentAmountPaidNumericHint => '0.00';

  @override
  String get propertyDocumentPaymentDateLabel => 'Payment Date';

  @override
  String get propertyDocumentSelectFile => 'Select File';

  @override
  String get propertyDocumentUploadHint => 'PDF, JPG or PNG (Max 10MB)';

  @override
  String get propertyDocumentSaveAction => 'Save to Vault';

  @override
  String get propertyDocumentCategoryRequired =>
      'Document category is required.';

  @override
  String get propertyDocumentUploadRequired => 'Select a PDF or image first.';

  @override
  String get propertyDocumentTitleRequired => 'Document title is required.';

  @override
  String get propertyDocumentFileTooLarge => 'File must be 10MB or less.';

  @override
  String get propertyDocumentFileMissing => 'File not found.';

  @override
  String get propertyDocumentSelectFileFailed =>
      'Unable to select file right now.';

  @override
  String get propertyDocumentPersistFailed =>
      'Unable to persist selected file.';

  @override
  String get propertyDocumentSaveFailed =>
      'Unable to save document. Please try again.';

  @override
  String get propertyDocumentSharedCategoryHint =>
      'The selected category and issue date will apply to every file. You can set a title for each document below.';

  @override
  String get propertyDocumentSelectedDocumentsTitle => 'Selected documents';

  @override
  String propertyDocumentSelectedDocumentLabel(int index) {
    return 'Document $index';
  }

  @override
  String get commonLanguageEnglish => 'English';

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
  String get identityStatusExpired => 'Expired';

  @override
  String get identityFilterTooltip => 'Filter';

  @override
  String get identityFilterSheetTitle => 'Filter identity documents';

  @override
  String get identityFilterSheetSubtitle =>
      'Choose which secure IDs appear in the list.';

  @override
  String get identityIntroEyebrow => 'Documents · Identity';

  @override
  String get identityHolderSingular => 'holder';

  @override
  String get identityHolderPlural => 'holders';

  @override
  String get identityNoPrimaryIdentity => 'No primary identity set yet.';

  @override
  String identityPrimaryIdentitySet(String document) {
    return '$document set as primary.';
  }

  @override
  String get identitySearchHint => 'Search by number, country, owner...';

  @override
  String get identityAllHolders => 'All holders';

  @override
  String get identityPrimaryBadge => 'Primary';

  @override
  String identityNoDocumentsForFilter(String filter) {
    return 'No $filter documents';
  }

  @override
  String get identityFilteredEmptyDescription =>
      'Try another view or add a new ID to this section.';

  @override
  String get identityClearSearch => 'Clear search';

  @override
  String get identityFilterAll => 'All';

  @override
  String get identityFilterPersonal => 'Personal';

  @override
  String get identityFilterTravel => 'Travel';

  @override
  String get identityStatusOk => 'OK';

  @override
  String identityStatusDaysLeft(int days) {
    return '$days d';
  }

  @override
  String identityDocumentNumberPrefix(String number) {
    return 'No. $number';
  }

  @override
  String get identityDetailFileMissingTitle => 'File missing';

  @override
  String get identityDetailFileMissingDescription =>
      'The metadata is saved, but the scan file is not available on this device.';

  @override
  String identityDetailPagesCount(int count) {
    return '$count pages';
  }

  @override
  String get identityDetailSectionDocument => 'Document';

  @override
  String get identityDetailSectionHolder => 'Holder';

  @override
  String get identityDetailSectionOtherDetails => 'Other details';

  @override
  String get identityDetailStatusExpiring => 'Expiring';

  @override
  String identityDetailStatusExpiresIn(int days) {
    return 'Expires $days d';
  }

  @override
  String get identityFieldDocumentNumber => 'Document number';

  @override
  String get identityFieldIssuingCountry => 'Issuing country';

  @override
  String get identityFieldExpires => 'Expires';

  @override
  String get identityFieldNationality => 'Nationality';

  @override
  String get identityFieldGivenName => 'Given name';

  @override
  String get identityFieldFamilyName => 'Family name';

  @override
  String get identityFieldDateOfBirth => 'Date of birth';

  @override
  String get identityFieldSex => 'Sex';

  @override
  String get identityFieldHolder => 'Holder';

  @override
  String get identityFieldAgeOver18 => 'Age over 18';

  @override
  String get idEntryAttachmentSection => 'Attachment';

  @override
  String get idEntryAddIdentityDocumentEyebrow => 'Add identity document';

  @override
  String get idEntryEditIdentityDocumentEyebrow => 'Edit identity document';

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
  String get workHubFeaturedSubtitleCompact => 'Access your complete history';

  @override
  String get workHubFeaturedAction => 'See All Payslips';

  @override
  String workHubDocumentsCountCompact(int count) {
    return '$count documents';
  }

  @override
  String workHubUpdatedCompact(String relative) {
    return 'Updated $relative';
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
  String get workCompanyVaultTitle => 'Company Vault';

  @override
  String get workCompanyVaultSubtitle =>
      'Secure access to your professional documents';

  @override
  String get workCompanyStorageUsed => 'STORAGE USED';

  @override
  String get workCompanyLastAccess => 'LAST ACCESS';

  @override
  String get workCompanyFoldersTitle => 'Document Folders';

  @override
  String get workCompanyFolderPayslipsTitle => 'Payslips';

  @override
  String get workCompanyFolderContractsTitle => 'Contracts';

  @override
  String get workCompanyFolderTaxFormsTitle => 'Tax Forms';

  @override
  String get workCompanyFolderOffboardingTitle => 'Offboarding';

  @override
  String get workCompanyFolderBenefitsTitle => 'Benefits';

  @override
  String get workCompanyFolderMilestonesTitle => 'Milestones';

  @override
  String get workCompanyFolderOtherTitle => 'Other Types';

  @override
  String get workCompanyFolderPayslipsSubtitle => 'Monthly earning statements';

  @override
  String get workCompanyFolderContractsSubtitle =>
      'Employment and IP agreements';

  @override
  String get workCompanyFolderTaxFormsSubtitle =>
      'Year-end summaries and tax forms';

  @override
  String get workCompanyFolderOffboardingSubtitle =>
      'Exit documents and procedures';

  @override
  String get workCompanyFolderBenefitsSubtitle =>
      'Insurance and benefit coverage';

  @override
  String get workCompanyFolderMilestonesSubtitle =>
      'Promotions and performance records';

  @override
  String get workCompanyFolderOtherSubtitle =>
      'Additional professional documents';

  @override
  String get workCompanyRecentDocumentsTitle => 'RECENT DOCUMENTS';

  @override
  String workCompanyRecentModified(String relative) {
    return 'Modified $relative';
  }

  @override
  String get workCompanyRecentEmptyTitle => 'No recent documents';

  @override
  String get workCompanyRecentEmptySubtitle =>
      'Documents added to this company vault will appear here.';

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
  String get workEntrySelectCompanyFirst => 'Select a company first.';

  @override
  String get workDocumentEntryTitle => 'Add Document';

  @override
  String get workDocumentEntryCategories => 'WORK CATEGORIES';

  @override
  String get workDocumentEntryTargetVault => 'TARGET VAULT';

  @override
  String get workPayslipAddTitle => 'Add Payslip';

  @override
  String get workPayslipSectionPaymentMonth => 'PAYMENT MONTH';

  @override
  String get workPayslipSectionNetSalary => 'NET SALARY';

  @override
  String get workPayslipOptional => 'Optional';

  @override
  String get workPayslipSectionUploadMethods => 'UPLOAD METHODS';

  @override
  String get workPayslipMethodScanTitle => 'Scan Payslip';

  @override
  String get workPayslipMethodScanSubtitle => 'Powered by AI Extraction';

  @override
  String get workPayslipMethodUploadPdfTitle => 'Upload PDF or Image';

  @override
  String get workPayslipMethodUploadPdfSubtitle =>
      'Pick from files, gallery, or camera';

  @override
  String get workPayslipMethodManualTitle => 'Manual Entry';

  @override
  String get workPayslipMethodManualSubtitle => 'Fill in details yourself';

  @override
  String get workPayslipSectionTargetVault => 'TARGET VAULT';

  @override
  String get workPayslipTargetVaultSubtitle => 'Company Managed Vault';

  @override
  String get workPayslipSelectCompanyPlaceholder => 'Select company';

  @override
  String get workPayslipNoCompanyAvailable => 'No created companies found yet.';

  @override
  String get workPayslipPickCamera => 'Take photo';

  @override
  String get workPayslipUnableSaveFileLocally =>
      'Unable to save selected file locally.';

  @override
  String get workPayslipUnableSelectFile => 'Unable to select file right now.';

  @override
  String get workPayslipSelectFileFirst => 'Select a PDF or image first.';

  @override
  String get workPayslipNetSalaryHint => '0.00';

  @override
  String get workPayslipHistoryTitle => 'Payslips History';

  @override
  String get workPayslipHistoryRecentDocuments => 'RECENT DOCUMENTS';

  @override
  String workPayslipHistoryItemsCount(int count) {
    return '$count items';
  }

  @override
  String get workPayslipHistoryNetPay => 'Net Pay';

  @override
  String get workPayslipHistoryLoadOlder => 'Load Older Payslips';

  @override
  String get workPayslipHistoryAllLoaded => 'All payslips are loaded.';

  @override
  String get workPayslipHistoryNoDataTitle => 'No payslips yet';

  @override
  String get workPayslipHistoryNoDataSubtitle =>
      'Your payslip documents will appear here.';

  @override
  String get workPayslipHistorySearchHint => 'Search payslips...';

  @override
  String get workPayslipHistorySearchButton => 'Search';

  @override
  String get workPayslipHistorySearchApply => 'Apply';

  @override
  String get workPayslipHistorySearchClear => 'Clear';

  @override
  String get workManualEntryAddTitle => 'Add Work Document';

  @override
  String get workManualEntryEditTitle => 'Edit Work Document';

  @override
  String get workManualEntrySectionDocumentDetails => 'Document Details';

  @override
  String get workManualEntryDocumentTypeLabel => 'Document Type';

  @override
  String get workManualEntrySharedTypeHint =>
      'The selected type and vault assignment will apply to every file. Set a title for each document below.';

  @override
  String get workManualEntryAssignVaultLabel => 'Assign to Vault (Employer)';

  @override
  String get workManualEntryDocumentTitleLabel => 'Document Title';

  @override
  String get workManualEntrySectionSelectedDocuments => 'Selected Documents';

  @override
  String get workManualEntryDocumentTitleHint => 'e.g. Payslip April 2026';

  @override
  String workManualEntrySelectedDocumentLabel(int index) {
    return 'Document $index';
  }

  @override
  String get workManualEntrySectionTimeline => 'Timeline';

  @override
  String get workManualEntryEffectiveDateLabel => 'Effective Date';

  @override
  String get workManualEntryExpiryDateLabel => 'Expiry Date';

  @override
  String get workManualEntryDatePlaceholder => 'mm/dd/yyyy';

  @override
  String get workManualEntryOngoingLabel => 'Ongoing / Permanent';

  @override
  String get workManualEntryOngoingHint => 'No fixed expiration date';

  @override
  String get workManualEntrySectionNotes => 'Document Notes';

  @override
  String get workManualEntryLabelFieldLabel => 'Label (Optional)';

  @override
  String get workManualEntryLabelHint =>
      'e.g. March 2026, Q1 Report, Signed copy...';

  @override
  String get workManualEntryNotesFieldLabel =>
      'Contract Terms or Internal Notes';

  @override
  String get workManualEntryNotesHint =>
      'Mention key clauses, salary details, or review highlights...';

  @override
  String get workManualEntryUploadTitle => 'Upload Original File';

  @override
  String get workManualEntryUploadSubtitle =>
      'PDF, Word, Excel, PPT, images & more (Max 10MB)';

  @override
  String get workManualEntryAddButton => 'Add Work Document';

  @override
  String get workManualEntrySelectUploadFirst => 'Upload a PDF or image first.';

  @override
  String get workManualEntryFileTooLarge =>
      'File exceeds 10MB. Select a smaller file.';

  @override
  String get workManualEntryTypeEmploymentContract => 'Employment Contract';

  @override
  String get workManualEntryTypeEmployerCertificate => 'Employer Certificate';

  @override
  String get workManualEntryTypeInternshipAgreement => 'Internship Agreement';

  @override
  String get workManualEntryTypeTaxDeclaration => 'Tax Declaration';

  @override
  String get workManualEntryTypeTaxCertificate => 'Tax Certificate';

  @override
  String get workManualEntryTypeBenefitsEnrollment => 'Benefits Enrollment';

  @override
  String get workManualEntryTypeInsuranceCoverage => 'Insurance Coverage';

  @override
  String get workManualEntryTypeResignationLetter => 'Resignation Letter';

  @override
  String get workManualEntryTypeTerminationNotice => 'Termination Notice';

  @override
  String get workManualEntryTypeFinalSettlement => 'Final Settlement';

  @override
  String get workManualEntryTypeEndOfServiceCert =>
      'End of Service Certificate';

  @override
  String get workManualEntryTypeNonCompete => 'Non-Compete Agreement';

  @override
  String get workManualEntryTypeSalarySlip => 'Salary Slip';

  @override
  String get workManualEntryTypeReferenceLetter => 'Reference Letter';

  @override
  String get workManualEntryTypePerformanceReview => 'Performance Review';

  @override
  String get workManualEntryTypePromotionLetter => 'Promotion Letter';

  @override
  String get workManualEntryTypeTrainingCert => 'Training Certificate';

  @override
  String get workManualEntryTypeQuittance => 'Rent Receipt';

  @override
  String get workManualEntryTypeOther => 'Other Work Document';

  @override
  String workPayslipTitleTemplate(String month) {
    return 'Payslip $month';
  }

  @override
  String get workFolderHistoryContractsAndLegal => 'Contracts & Legal';

  @override
  String workFolderHistoryAllDocuments(int count) {
    return 'ALL DOCUMENTS ($count)';
  }

  @override
  String get workFolderHistorySort => 'Sort';

  @override
  String get workFolderHistorySortNewest => 'Newest';

  @override
  String get workFolderHistorySortOldest => 'Oldest';

  @override
  String get workFolderHistorySortTitle => 'Title A-Z';

  @override
  String workFolderHistoryAdded(String date, String size) {
    return 'Added: $date • $size';
  }

  @override
  String get workFolderHistorySearchTitle => 'Search';

  @override
  String get workFolderHistorySearchHint => 'Search documents...';

  @override
  String get workFolderHistoryNoDocumentsTitle => 'No documents yet';

  @override
  String get workFolderHistoryNoDocumentsSubtitle =>
      'Your folder documents will appear here.';

  @override
  String get collectionDetailFolderTitle => 'Folder Details';

  @override
  String get collectionDetailDocumentTitle => 'Document Details';

  @override
  String get collectionDetailNoteTitle => 'Note Details';

  @override
  String get collectionDetailInputTitle => 'Field Details';

  @override
  String get collectionDetailChecklistTitle => 'Checklist Details';

  @override
  String get collectionDetailLinkTitle => 'Link Details';

  @override
  String get collectionDetailImageTitle => 'Image Details';

  @override
  String get collectionDetailExpenseTitle => 'Expense Details';

  @override
  String get collectionDetailTimelineTitle => 'Event Details';

  @override
  String get collectionDetailLocationTitle => 'Location Details';

  @override
  String get collectionDetailSectionTitle => 'Section Details';

  @override
  String get collectionDetailActions => 'ACTIONS';

  @override
  String get collectionDetailTaskList => 'TASK LIST';

  @override
  String get collectionDetailDescription => 'DESCRIPTION';

  @override
  String get collectionDetailAttachment => 'ATTACHMENT';

  @override
  String get collectionDetailCompletionProgress => 'Completion Progress';

  @override
  String get collectionDetailShareDocument => 'Share Document';

  @override
  String get collectionDetailPreview => 'Preview';

  @override
  String get collectionDetailDownload => 'Download';

  @override
  String get collectionDetailOpenLink => 'Open Link';

  @override
  String get collectionDetailEditImage => 'Edit Image';

  @override
  String get collectionDetailOpenInMaps => 'Open in Maps';

  @override
  String get collectionDetailMovePrintPdf => 'Print PDF';

  @override
  String get collectionDetailMoveToCollection => 'Move to Collection';

  @override
  String get collectionDetailShareLink => 'Share Link';

  @override
  String get collectionDetailShare => 'Share';

  @override
  String get collectionDetailDeleteLink => 'Delete Link';

  @override
  String get collectionDetailDeleteFolder => 'Delete Folder';

  @override
  String get collectionDetailDeleteSection => 'Delete Section';

  @override
  String get collectionDetailDeleteChecklist => 'Delete Checklist';

  @override
  String get collectionDetailRemove => 'Remove';

  @override
  String get collectionDetailDelete => 'Delete';

  @override
  String get collectionDetailEdit => 'Edit';

  @override
  String get collectionDetailRearrange => 'Rearrange';

  @override
  String get collectionDetailDeleteBlockTitle => 'Delete Block';

  @override
  String get collectionDetailDeleteBlockMessage =>
      'This action cannot be undone.';

  @override
  String get collectionDetailCancel => 'Cancel';

  @override
  String get collectionDetailDateNotSet => 'Date not set';

  @override
  String get collectionDetailTimeNotSet => 'Time not set';

  @override
  String get collectionDetailNoLocationSet => 'No location set';

  @override
  String get collectionDetailNoFileAttached => 'No file attached';

  @override
  String get collectionDetailFileNotFound => 'File not found';

  @override
  String collectionDetailTaskCount(int done, int total) {
    return '$done of $total tasks';
  }

  @override
  String get collectionDetailPreviewAvailable => 'PREVIEW AVAILABLE';

  @override
  String collectionDetailItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0';
  }

  @override
  String collectionDetailFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'folders',
      one: 'folder',
    );
    return '$count $_temp0';
  }

  @override
  String collectionDetailReminderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'reminders',
      one: 'reminder',
    );
    return '$count $_temp0';
  }

  @override
  String get collectionEntryDocumentInfo => 'DOCUMENT INFORMATION';

  @override
  String get collectionEntryDetails => 'DETAILS';

  @override
  String get collectionEntrySource => 'SOURCE';

  @override
  String get collectionEntryChange => 'Change';

  @override
  String get collectionEntrySecuritySettings => 'SECURITY SETTINGS';

  @override
  String get collectionEntryChooseIcon => 'CHOOSE ICON';

  @override
  String get collectionEntrySearchIcon => 'Search icon';

  @override
  String get collectionEntryUseEmoji => 'Use emoji';

  @override
  String get collectionEntryPickLocalImage => 'Pick local image';

  @override
  String get collectionEntryLocalImageSelected => 'Local image selected';

  @override
  String get collectionEntryEmojiSelected => 'Emoji selected';

  @override
  String get collectionEntryBlockIconHint =>
      'Search for a symbol, pick a local image, or use an emoji.';

  @override
  String get collectionEntryNoIconsFound => 'No matching icons found.';

  @override
  String get collectionEntryEmojiHint => 'Emoji or short label';

  @override
  String get collectionEntryLocationDetails => 'LOCATION DETAILS';

  @override
  String get collectionEntryLocationSearchSection => 'SEARCH';

  @override
  String get collectionEntryLocationResult => 'RESULT';

  @override
  String get collectionEntryLocationResultMap => 'RESULT · MAP';

  @override
  String get collectionEntryLocationSuggestions => 'SUGGESTIONS';

  @override
  String get collectionEntryLocationLabelField => 'LABEL';

  @override
  String get collectionEntryLocationAddressField => 'ADDRESS';

  @override
  String get collectionEntryLocationLatitude => 'LAT';

  @override
  String get collectionEntryLocationLongitude => 'LONG';

  @override
  String get collectionEntryLocationNoResultSelected =>
      'Select a place to preview the map.';

  @override
  String get collectionEntryLocationMapsHelp =>
      'Open in Maps from the detail page.';

  @override
  String get collectionEntryCurrency => 'CURRENCY';

  @override
  String get collectionEntryDate => 'DATE';

  @override
  String get collectionEntryCategory => 'CATEGORY';

  @override
  String get collectionEntryReceipt => 'RECEIPT';

  @override
  String get collectionEntryCurrentSelection => 'CURRENT SELECTION';

  @override
  String get collectionEntryFolderName => 'Folder Name';

  @override
  String get collectionEntrySectionName => 'Section Name';

  @override
  String get collectionEntryDocumentTitle => 'Document Title';

  @override
  String get collectionEntryEventTitle => 'Event Title';

  @override
  String get collectionEntryEventType => 'Event Type';

  @override
  String get collectionEntryDateTime => 'Date & Time';

  @override
  String get collectionEntryFieldType => 'Field Type';

  @override
  String get collectionEntryPasteOrType => 'Paste or type';

  @override
  String get collectionEntryPreviewFetched => 'PREVIEW · FETCHED';

  @override
  String get collectionEntryPreviewFetching => 'PREVIEW · FETCHING';

  @override
  String get collectionEntryTitleOverride => 'Title · Override';

  @override
  String get collectionEntryInputTypeSection => 'TYPE';

  @override
  String get collectionEntryInputFieldSection => 'FIELD';

  @override
  String get collectionEntryInputPreviewCopy => 'PREVIEW · TAP TO COPY';

  @override
  String get collectionEntryInputCopyAction => 'copy';

  @override
  String get collectionEntryInputCopyHelp =>
      'Tap-to-copy is enabled on Short text, Number, Phone, and URL field types.';

  @override
  String get collectionEntryLabel => 'Label';

  @override
  String get collectionEntryValue => 'Value';

  @override
  String get collectionEntryTitle => 'Title';

  @override
  String get collectionEntryDescription => 'Description';

  @override
  String get collectionEntryDescriptionOptional => 'Description (optional)';

  @override
  String get collectionEntryCollapsedByDefault => 'Collapsed by default';

  @override
  String get collectionEntryUrl => 'URL';

  @override
  String get collectionEntryLocation => 'Location';

  @override
  String get collectionEntryExpiryDate => 'Expiry Date';

  @override
  String get collectionEntryNoteContent => 'Note Content';

  @override
  String get collectionEntryNotes => 'Notes';

  @override
  String get collectionEntryNotesOptional => 'Notes (optional)';

  @override
  String get collectionEntrySecurityLevel => 'Security Level';

  @override
  String get collectionEntryAmount => 'Amount';

  @override
  String get collectionEntryChecklistIdentity => 'Checklist Identity';

  @override
  String get collectionEntryTaskItems => 'Task Items';

  @override
  String get collectionEntrySearchPlace => 'Search for a place';

  @override
  String get collectionEntryHintFolderName => 'e.g. Itinerary';

  @override
  String get collectionEntryHintFolderDesc =>
      'Organize your workspace items in this folder';

  @override
  String get collectionEntryHintSectionName => 'e.g. Important Documents';

  @override
  String get collectionEntryHintSectionDesc =>
      'Describe what this section contains...';

  @override
  String get collectionEntryHintDocTitle => 'e.g. Passport 2024';

  @override
  String get collectionEntryHintDocumentNotes =>
      'Source, context, or notes about this file...';

  @override
  String get collectionEntryHintEventTitle =>
      'e.g. Inventory walk-through with landlord';

  @override
  String get collectionEntryHintLocation => 'e.g. Riverside Park';

  @override
  String get collectionEntryHintLocationLabel =>
      'e.g. Apartment — Rue de Lille';

  @override
  String get collectionEntryHintUrl => 'https://example.com';

  @override
  String get collectionEntryHintAutoTitle => 'Auto-fetching title...';

  @override
  String get collectionEntryHintLinkDesc =>
      'Add a brief description of this link';

  @override
  String get collectionEntryHintFieldLabel => 'e.g. Camera Serial';

  @override
  String get collectionEntryHintFieldValue => 'Enter the field content';

  @override
  String get collectionEntryHintChecklist => 'e.g. European Summer Trip';

  @override
  String get collectionEntryHintNoteContent =>
      'Start typing your secure note...';

  @override
  String get collectionEntryHintEventDesc =>
      'Bring printed inventory · 2 copies';

  @override
  String get collectionEntryHintImageNotes =>
      'Add some context or secure notes...';

  @override
  String get collectionEntryHintImageTitle => 'Give your entry a name';

  @override
  String get collectionEntryHintAddress => '1200 Avenue of the Americas, NY';

  @override
  String get collectionEntryHintTagLabels => 'e.g. Work, Secret Stash';

  @override
  String get collectionEntryHintChecklistItem => 'Checklist item';

  @override
  String get collectionEntryHintAddTask => 'Add another task...';

  @override
  String get collectionEntryHideField => 'Hide field in vault view';

  @override
  String get collectionEntryEnableQuickCopy => 'Enable quick copy';

  @override
  String get collectionEntryNewEntry => 'New Entry';

  @override
  String get collectionEntryNewEntrySubtitle =>
      'Securing your new resource in the vault.';

  @override
  String get collectionEntryPreviewLabel => 'PREVIEW';

  @override
  String get collectionEntryPreviewHint =>
      'The preview will automatically generate once a valid URL is added.';

  @override
  String get collectionEntryLoadingPreview => 'Loading preview...';

  @override
  String get collectionEntrySuggestedTasks => 'Suggested Tasks';

  @override
  String get collectionEntryEncryptedNote =>
      'This note will be encrypted and stored securely in your private vault.';

  @override
  String get collectionEntryValidationTitle =>
      'Please fill the required title field.';

  @override
  String collectionEntryItemsCount(int count) {
    return '$count Items';
  }

  @override
  String get collectionEntryAddFolder => 'Add folder';

  @override
  String get collectionEntryEditFolder => 'Edit folder';

  @override
  String get collectionEntryAddSection => 'Add section';

  @override
  String get collectionEntryEditSection => 'Edit section';

  @override
  String get collectionEntryAddDocument => 'Add Document';

  @override
  String get collectionEntryAddNote => 'Add note';

  @override
  String get collectionEntryEditNote => 'Edit note';

  @override
  String get collectionEntryAddInput => 'Add field';

  @override
  String get collectionEntryAddChecklist => 'New Checklist';

  @override
  String get collectionEntryAddLink => 'Add link';

  @override
  String get collectionEntryEditLink => 'Edit link';

  @override
  String get collectionEntryAddImage => 'Add image';

  @override
  String get collectionEntryAddExpense => 'Add Expense';

  @override
  String get collectionEntryAddEvent => 'Add event';

  @override
  String get collectionEntryEditEvent => 'Edit event';

  @override
  String get collectionEntryAddLocation => 'Add Location';

  @override
  String get collectionEntryEditLocation => 'Edit location';

  @override
  String get collectionEntryReplaceFile => 'Replace';

  @override
  String get collectionEntrySourceFiles => 'Files';

  @override
  String get collectionEntrySourcePhotos => 'Photos';

  @override
  String get collectionEntrySourceScan => 'Scan';

  @override
  String get collectionEntrySaveVault => 'Save to Vault';

  @override
  String get collectionEntrySaveNote => 'Save Note';

  @override
  String get collectionEntrySaveField => 'Save Field';

  @override
  String get collectionEntrySaveChecklist => 'Save Checklist';

  @override
  String get collectionEntrySaveLink => 'Save Link';

  @override
  String get collectionEntrySaveImage => 'Save Image';

  @override
  String get collectionEntrySaveExpense => 'Save Expense';

  @override
  String get collectionEntrySaveEvent => 'Save Event';

  @override
  String get collectionEntryCreateFolder => 'Create Folder';

  @override
  String get collectionEntryCreateSection => 'Create Section';

  @override
  String get collectionEntryUploadDocument => 'Upload Document';

  @override
  String get collectionEntryUploadImage => 'Upload Image';

  @override
  String get collectionEntryUploadReceipt => 'Upload receipt';

  @override
  String get collectionEntryUploadFiles => 'Tap to upload files';

  @override
  String get collectionEntryUploadDefault => 'Upload';

  @override
  String get collectionEntryUploadDocHint =>
      'Drag and drop your file here, or tap to browse';

  @override
  String get collectionEntryUploadImageHint =>
      'Tap to select from gallery or drag and drop';

  @override
  String get collectionEntryUploadReceiptHint => 'PNG, JPG or PDF up to 10MB';

  @override
  String get collectionEntryUploadFileHint => 'PDF, DOCX, or Images up to 10MB';

  @override
  String get collectionEntrySelectFile => 'Select File';

  @override
  String get collectionDashboardKind => 'Collection';

  @override
  String get collectionDashboardDone => 'Done';

  @override
  String get collectionDashboardEmptyState =>
      'No items yet. Tap Add Block to get started.';

  @override
  String get collectionDashboardAddBlock => 'Add Block';

  @override
  String get collectionDashboardCopied => 'Copied';

  @override
  String get collectionDashboardCopy => 'Copy';

  @override
  String get collectionDashboardRearrange => 'Rearrange';

  @override
  String get collectionDashboardRecentlyAdded => 'Recently added';

  @override
  String get collectionDashboardJustNow => 'just now';

  @override
  String get collectionFolderTitle => 'Folder';

  @override
  String get collectionFolderRetry => 'Retry';

  @override
  String get collectionFolderNotFound => 'Folder not found.';

  @override
  String get collectionFolderEmpty => 'This folder is empty.';

  @override
  String get collectionFolderBlocks => 'BLOCKS';

  @override
  String get collectionFolderContents => 'CONTENTS';

  @override
  String get collectionReorderTitle => 'Reorder blocks';

  @override
  String get collectionReorderInstruction =>
      'Drag the handle to reorder · long-press a row for actions.';

  @override
  String get collectionBlockFolder => 'Folder';

  @override
  String get collectionBlockSection => 'Section';

  @override
  String get collectionBlockDocument => 'Document';

  @override
  String get collectionBlockNote => 'Note';

  @override
  String get collectionBlockInput => 'Input';

  @override
  String get collectionBlockChecklist => 'Checklist';

  @override
  String get collectionBlockLink => 'Link';

  @override
  String get collectionBlockImage => 'Image';

  @override
  String get collectionBlockExpense => 'Expense';

  @override
  String get collectionBlockTimeline => 'Timeline';

  @override
  String get collectionBlockLocation => 'Location';

  @override
  String get collectionBlockFolderDesc => 'Organize files';

  @override
  String get collectionBlockSectionDesc => 'Group blocks';

  @override
  String get collectionBlockDocumentDesc => 'Rich text doc';

  @override
  String get collectionBlockNoteDesc => 'Quick thought';

  @override
  String get collectionBlockInputDesc => 'Text field';

  @override
  String get collectionBlockChecklistDesc => 'Task list';

  @override
  String get collectionBlockLinkDesc => 'Web resource';

  @override
  String get collectionBlockImageDesc => 'Upload photo';

  @override
  String get collectionBlockExpenseDesc => 'Track spend';

  @override
  String get collectionBlockTimelineDesc => 'Event log';

  @override
  String get collectionBlockLocationDesc => 'Pin place';

  @override
  String get collectionAddBlockTitle => 'Add a block';

  @override
  String get collectionAddBlockSubtitle =>
      'Choose a component to add to your workspace';

  @override
  String get collectionAddBlockSearch => 'Filter blocks';

  @override
  String get collectionAddBlockStructural => 'Structural';

  @override
  String get collectionAddBlockContent => 'Content';

  @override
  String get collectionAddBlockNoResults => 'No matching blocks';

  @override
  String get collectionCategoryMilestone => 'Milestone';

  @override
  String get collectionCategoryDeadline => 'Deadline';

  @override
  String get collectionCategoryReminder => 'Reminder';

  @override
  String get collectionCategoryIdentity => 'Identity';

  @override
  String get collectionCategoryTravel => 'Travel';

  @override
  String get collectionCategoryFinance => 'Finance';

  @override
  String get collectionCategoryOther => 'Other';

  @override
  String get collectionCategoryPersonal => 'Personal';

  @override
  String get collectionCategoryWork => 'Work';

  @override
  String get collectionCategoryTransport => 'Transport';

  @override
  String get collectionCategoryFood => 'Food';

  @override
  String get collectionCategoryShopping => 'Shopping';

  @override
  String get collectionCategoryRent => 'Rent';

  @override
  String get collectionSecurityStandard => 'Standard';

  @override
  String get collectionSecurityConfidential => 'Confidential';

  @override
  String get collectionSecurityTopSecret => 'Top Secret';

  @override
  String get collectionFieldShortText => 'Short Text';

  @override
  String get collectionFieldNumber => 'Number';

  @override
  String get collectionFieldDate => 'Date';

  @override
  String get collectionFieldPhone => 'Phone';

  @override
  String get collectionBlockReminder => 'Reminder';

  @override
  String get collectionBlockReminderDesc => 'Set alert';

  @override
  String get collectionDetailReminderTitle => 'Reminder Details';

  @override
  String get collectionDetailDeleteReminder => 'Delete Reminder';

  @override
  String get collectionEntryAddReminder => 'Add Reminder';

  @override
  String get collectionEntryEditReminder => 'Edit reminder';

  @override
  String get collectionEntrySaveReminder => 'Save Reminder';

  @override
  String get collectionEntryScheduleReminder => 'Schedule';

  @override
  String get collectionEntryReminderTitle => 'Reminder Title';

  @override
  String get collectionEntryReminderHintTitle => 'e.g. Renew passport';

  @override
  String get collectionEntryReminderNote => 'Note';

  @override
  String get collectionEntryReminderHintNote =>
      'Add a note for this reminder...';

  @override
  String get collectionEntryReminderDateTime => 'Date & Time';

  @override
  String get collectionEntryReminderWhen => 'WHEN';

  @override
  String get collectionEntryReminderRepeat => 'Repeat';

  @override
  String get collectionEntryReminderSystemHelp =>
      'Reminders use the system notifications service. Vault stays locked.';

  @override
  String get collectionEntryIconSection => 'ICON';

  @override
  String get collectionEntryFolderIconHelp =>
      'Changing the folder icon doesn\'t touch the collection\'s icon or its other blocks.';

  @override
  String get collectionEntrySectionIconHelp =>
      'Section icons are independent from folder and collection icons.';

  @override
  String get collectionEntrySectionIconSearchHint => 'utility';

  @override
  String get collectionEntryDeleteFolder => 'Delete folder';

  @override
  String get collectionEntryDefaultState => 'DEFAULT STATE';

  @override
  String get collectionEntryCollapsed => 'Collapsed';

  @override
  String get collectionEntryExpanded => 'Expanded';

  @override
  String get collectionEntryTimelineEvent => 'EVENT';

  @override
  String get collectionEntryTimelineNotes => 'NOTES';

  @override
  String get collectionEntryTimelineWhen => 'WHEN';

  @override
  String get collectionEntryTimelineCategory => 'CATEGORY';

  @override
  String get collectionEntryTimelineCategoryTrip => 'Trip';

  @override
  String get collectionEntryTimelineCategoryAdmin => 'Admin';

  @override
  String get collectionEntryTimelineCategoryProperty => 'Property';

  @override
  String get collectionEntryTimelineCategoryHealth => 'Health';

  @override
  String get collectionEntryTimelineCategoryWork => 'Work';

  @override
  String get collectionEntryTimelineLinked => 'LINKED';

  @override
  String get collectionEntryTimelineLinkedPlaceholder =>
      'Link a collection item';

  @override
  String get collectionEntryTimelineLinkedSheetTitle => 'Linked item';

  @override
  String get collectionEntryTimelineLinkedHint =>
      'e.g. Apartment · Rue de Lille';

  @override
  String get collectionReminderNone => 'None';

  @override
  String get collectionReminderOnce => 'Once';

  @override
  String get collectionReminderDaily => 'Daily';

  @override
  String get collectionReminderWeekly => 'Weekly';

  @override
  String get collectionReminderMonthly => 'Monthly';

  @override
  String get collectionReminderQuarterly => 'Quarterly';

  @override
  String get collectionReminderYearly => 'Yearly';

  @override
  String get collectionReminderScheduled => 'Scheduled';

  @override
  String get backupTitle => 'Backup & Restore';

  @override
  String get backupUnableLoad => 'Unable to load backups right now.';

  @override
  String get backupRetry => 'Retry';

  @override
  String get backupCreating => 'Creating Backup...';

  @override
  String get backupCreateButton => 'Create Backup';

  @override
  String get backupCreateTitle => 'Create Backup';

  @override
  String get backupCreateSubtitle =>
      'Enter a passphrase to encrypt your backup. You will need this passphrase to restore.';

  @override
  String get backupHistorySection => 'BACKUP HISTORY';

  @override
  String get backupRestorePreview => 'Restore Preview';

  @override
  String get backupRestoreWarning =>
      'Your current data will be replaced. An emergency backup will be created first.';

  @override
  String get backupRestoreTitle => 'Restore Backup';

  @override
  String get backupRestoreSubtitle =>
      'Enter the passphrase used when this backup was created.';

  @override
  String get backupDeleteTitle => 'Delete Backup';

  @override
  String get backupNoHistory => 'No backup history';

  @override
  String get backupNoHistorySubtitle =>
      'Your backup history will appear here once you create your first backup.';

  @override
  String get backupNoBackups => 'No backups yet';

  @override
  String get backupNoBackupsSubtitle =>
      'Create your first encrypted backup to protect your data.';

  @override
  String get backupLastBackup => 'Last Backup';

  @override
  String get backupAutoTitle => 'Auto Backup';

  @override
  String get backupAutoSubtitle =>
      'Automatically back up when you open the app';

  @override
  String get backupCloudStorage => 'Cloud Storage';

  @override
  String get backupCloudBackups => 'Cloud Backups';

  @override
  String get backupCloudChecking => 'Checking...';

  @override
  String get backupCloudUnableCheck => 'Unable to check — tap refresh';

  @override
  String get backupCloudRestoreTitle => 'Restore from Cloud';

  @override
  String get backupCloudRestoreWarning =>
      'This will download and restore the backup. Your current data will be replaced.';

  @override
  String get backupInterruptedWarning =>
      'A previous restore was interrupted. Your data may be in an inconsistent state.';

  @override
  String get backupPassphraseHint => 'Passphrase';

  @override
  String get backupAuthCodeHint => 'Paste authorization code here';

  @override
  String get backupAuthFailed => 'Authorization failed or cancelled.';

  @override
  String get backupConnectionFailed => 'Connection failed';

  @override
  String get backupSoon => 'Soon';

  @override
  String get backupConnected => 'Connected';

  @override
  String get backupConnect => 'Connect';

  @override
  String get backupDisconnect => 'Disconnect';

  @override
  String get backupUploadICloud => 'Upload to iCloud';

  @override
  String get backupComingSoon => 'Coming soon';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonRollback => 'Rollback';

  @override
  String get commonActive => 'Active';

  @override
  String get backupDeviceTitle => 'Device Info';

  @override
  String get backupDeviceUnableLoad => 'Unable to load device info.';

  @override
  String get backupDeviceId => 'Device ID';

  @override
  String get backupDevicePlatform => 'Platform';

  @override
  String get backupDeviceAppVersion => 'App Version';

  @override
  String get backupDeviceFirstSeen => 'First Seen';

  @override
  String get backupDeviceActiveWriter => 'Active Backup Writer';

  @override
  String get backupDeviceActiveWriterDesc =>
      'This device is the active backup writer.';

  @override
  String get backupHealthTitle => 'Backup Health';

  @override
  String get backupHealthUnableLoad => 'Unable to load health data.';

  @override
  String get backupHealthChainStatus => 'CHAIN STATUS';

  @override
  String get backupHealthStatus => 'Status';

  @override
  String get backupHealthStatusEmpty => 'Empty';

  @override
  String get backupHealthStatusActive => 'Active';

  @override
  String get backupHealthChainDepth => 'Chain Depth';

  @override
  String get backupHealthBaseDate => 'Base Date';

  @override
  String get backupHealthHeadDate => 'Head Date';

  @override
  String get backupHealthStats => 'BACKUP STATS';

  @override
  String get backupHealthLastBackup => 'Last Backup';

  @override
  String get backupHealthNever => 'Never';

  @override
  String get backupHealthTotalBackups => 'Total Backups';

  @override
  String get backupHealthStorageUsed => 'Storage Used';

  @override
  String get backupHealthEncryption => 'Encryption';

  @override
  String get backupHealthDevice => 'DEVICE';

  @override
  String get backupHealthName => 'Name';

  @override
  String get backupHealthIntegrity => 'INTEGRITY';

  @override
  String get backupHealthChecking => 'Checking...';

  @override
  String get backupHealthRunCheck => 'Run Integrity Check';

  @override
  String get backupHealthRebuildChain => 'Rebuild Chain';

  @override
  String get backupHealthRebuildNotAvailable =>
      'Chain rebuild is not yet available.';

  @override
  String get collectionsTitle => 'Collections';

  @override
  String get collectionsNewCollection => '+ New Collection';

  @override
  String get collectionsCreateTitle => 'Create Collection';

  @override
  String get collectionsChooseStarting => 'Choose a starting point';

  @override
  String get collectionsChooseSubtitle =>
      'Start from scratch or pick a template.\nTap preview to explore before choosing.';

  @override
  String get collectionsRecommendedTemplates => 'RECOMMENDED TEMPLATES';

  @override
  String get collectionsSearchResults => 'SEARCH RESULTS';

  @override
  String get collectionsNoTemplatesFound => 'No templates found';

  @override
  String get collectionsSearchTemplatesHint => 'Search templates...';

  @override
  String get collectionBlockRename => 'Rename';

  @override
  String get collectionBlockDuplicate => 'Duplicate';

  @override
  String get collectionBlockLockWithPin => 'Lock with PIN';

  @override
  String get collectionBlockMove => 'Move to another collection';

  @override
  String get collectionListYours => 'Yours';

  @override
  String get collectionListStartFromTemplate => 'Start from a template';

  @override
  String get collectionBlockDelete => 'Delete';

  @override
  String get collectionBlockRenamed => 'Renamed successfully';

  @override
  String get collectionBlockDuplicated => 'Duplicated successfully';

  @override
  String get collectionBlockDeleted => 'Deleted successfully';

  @override
  String get collectionBlockRenameHint => 'Enter new name';

  @override
  String get collectionBlockProgress => 'Progress';

  @override
  String get collectionBlockProgressDesc =>
      'Track progress toward a goal with a visual bar';

  @override
  String get collectionEntryProgressTitle => 'TITLE';

  @override
  String get collectionEntryProgressHintTitle =>
      'e.g. Payment plan, Savings goal';

  @override
  String get collectionEntryProgressCurrent => 'CURRENT';

  @override
  String collectionEntryProgressCurrentOf(String target) {
    return 'CURRENT · OF $target';
  }

  @override
  String get collectionEntryProgressTarget => 'TARGET';

  @override
  String get collectionEntryProgressDue => 'DUE';

  @override
  String get collectionEntryProgressValues => 'VALUES';

  @override
  String get collectionEntryProgressType => 'TYPE';

  @override
  String get collectionEntryProgressTypeCurrency => 'Currency';

  @override
  String get collectionEntryProgressTypeQuantity => 'Quantity';

  @override
  String get collectionEntryProgressTypeDistance => 'Distance';

  @override
  String get collectionEntryProgressTypeCustom => 'Custom';

  @override
  String get collectionEntryProgressCustomUnit => 'custom';

  @override
  String get collectionEntryProgressCurrency => 'CURRENCY (OPTIONAL)';

  @override
  String get collectionEntryProgressUnit => 'UNIT (OPTIONAL)';

  @override
  String get collectionEntryProgressUnitNone => 'None';

  @override
  String get collectionEntryProgressUnitCustomHint =>
      'Or type a custom unit...';

  @override
  String get collectionEntryProgressHintDesc =>
      'Add notes about this tracker...';

  @override
  String get collectionEntryAddProgress => 'Add Progress';

  @override
  String get collectionEntryEditProgress => 'Edit progress';

  @override
  String get collectionEntrySaveProgress => 'Save Progress';

  @override
  String get collectionDetailProgressTitle => 'Progress';

  @override
  String get collectionsBlankTitle => 'Blank Collection';

  @override
  String get collectionsBlankSubtitle => 'Start with a clean slate';

  @override
  String get collectionsSelected => 'Selected';

  @override
  String get collectionsSelect => 'Select';

  @override
  String get collectionsStep2of3 => 'Step 2 of 3';

  @override
  String get collectionsIncludedBlocks => 'INCLUDED BLOCKS';

  @override
  String get collectionsUseTemplate => 'Use This Template';

  @override
  String get collectionsAccentColor => 'Accent Color';

  @override
  String get collectionsPickColor => 'Pick a Color';

  @override
  String get collectionsNameHint => 'e.g. Summer Destinations';

  @override
  String get collectionsNameRequired => 'Please enter a collection name.';

  @override
  String get collectionsColorHint => '#FF5733';

  @override
  String get settingsExportPassphraseTitle => 'Export Passphrase';

  @override
  String get settingsExportPassphraseHint =>
      'Enter passphrase to encrypt export';

  @override
  String get settingsExportButton => 'Export';

  @override
  String get settingsBackupSubtitle => 'Create and restore encrypted backups';

  @override
  String get settingsExportSubtitle =>
      'Export your vault as a portable archive';

  @override
  String get settingsDataSection => 'DATA';

  @override
  String get navHome => 'Home';

  @override
  String get navCredentials => 'Credentials';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navProfile => 'Profile';

  @override
  String get navVault => 'Vault';

  @override
  String get navDocs => 'Docs';

  @override
  String get navSearch => 'Search';

  @override
  String get navMe => 'Me';

  @override
  String get homeSmartReminders => 'Smart Reminders';

  @override
  String get homeQuickAccess => 'Quick Access';

  @override
  String get homeRecentActivity => 'Recent Activity';

  @override
  String get homeVaultInsights => 'Vault Insights';

  @override
  String get homeEverythingGood => 'Everything looks good';

  @override
  String get homeVaultUpToDate => 'Your vault is secure and up to date';

  @override
  String get homeVaultStatus => 'Vault status';

  @override
  String get homeVaultAtGlance => 'Vault at a glance';

  @override
  String get homeStatusNeedsAttention => 'Needs attention';

  @override
  String get homeHealthy => 'Healthy';

  @override
  String get homeNeedsAttention => 'Needs your attention';

  @override
  String get homeNoAttentionNeeded => 'No attention needed';

  @override
  String get homeNoAttentionSubtitle =>
      'Your vault has no urgent reminders right now.';

  @override
  String get homeAlerts => 'alerts';

  @override
  String get homeItems => 'items';

  @override
  String get homeIssues => 'issues';

  @override
  String get homeOpen => 'open';

  @override
  String get homeOpenTasks => 'open tasks';

  @override
  String get homeBackupLocal => 'Local backup';

  @override
  String get homeLocalOnly => 'Local-first';

  @override
  String get homeQuickOpen => 'Quick open';

  @override
  String get homePinned => 'Pinned';

  @override
  String get homeViewAll => 'View all';

  @override
  String get homeLastUpdated => 'Last updated';

  @override
  String get homeToday => 'Today';

  @override
  String get homeSoonestFirst => 'Soonest first';

  @override
  String get homeRecentEmptyTitle => 'No recent activity yet';

  @override
  String get homeRecentEmptySubtitle =>
      'Items you open or update will appear here.';

  @override
  String get homeSetupEmptyTitle => 'A calm place for your private things.';

  @override
  String get homeSetupEmptySubtitle =>
      'Add your first credential, document, collection, or task to start building your encrypted vault.';

  @override
  String get homeAddFirstItem => 'Add your first item';

  @override
  String get homeUnableDashboard => 'Unable to load dashboard';

  @override
  String get homeUnableDashboardSubtitle =>
      'Something went wrong while loading\nyour home screen.';

  @override
  String get homeTryAgain => 'Try again';

  @override
  String get homePreferencesTitle => 'Home Preferences';

  @override
  String get homeResetDefaults => 'Reset to Defaults';

  @override
  String get homeVisibleSections => 'Visible Sections';

  @override
  String get homeCategories => 'Categories';

  @override
  String get homeSmartRules => 'Smart Rules';

  @override
  String get homeExpiringDocuments => 'Expiring Documents';

  @override
  String get homeMissingAttention => 'Missing / Attention Required';

  @override
  String get homeRecentlyUpdated => 'Recently Updated';

  @override
  String get homeSourceCredential => 'Credential';

  @override
  String get homeSourceDocument => 'Document';

  @override
  String get homeSourceCollection => 'Collection';

  @override
  String get searchTitle => 'Search your vault';

  @override
  String get searchHint => 'Search vault...';

  @override
  String get searchNoResults => 'No results found';

  @override
  String get searchNoResultsSubtitle => 'Try a different search term';

  @override
  String get searchFindAll => 'Find credentials, documents, and collections';

  @override
  String get searchCredentials => 'Credentials';

  @override
  String get searchDocuments => 'Documents';

  @override
  String get searchCollections => 'Collections';

  @override
  String get authEnterPin => 'Enter your PIN';

  @override
  String get authEnterPinSubtitle => 'Enter your 6-digit PIN to unlock';

  @override
  String get authIncorrectPin => 'Incorrect PIN. Try again.';

  @override
  String get authCreatePin => 'Create a PIN';

  @override
  String get authConfirmPin => 'Confirm your PIN';

  @override
  String get authCreatePinSubtitle =>
      'Choose a 6-digit PIN to secure your vault';

  @override
  String get authConfirmPinSubtitle => 'Re-enter the same 6-digit PIN';

  @override
  String get authPinMismatch => 'PINs didn\'t match. Try again.';

  @override
  String get authEnableBiometric => 'Enable Biometric Unlock?';

  @override
  String get authBiometricSubtitle =>
      'Use Face ID or fingerprint to unlock your vault quickly.';

  @override
  String get authBiometricEnable => 'Enable';

  @override
  String get authBiometricSkip => 'Skip';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingTitle1 => 'Your Secure Vault';

  @override
  String get onboardingSubtitle1 =>
      'Store credentials, documents, and collections in one encrypted place. Everything stays on your device.';

  @override
  String get onboardingTitle2 => 'Smart Documents';

  @override
  String get onboardingSubtitle2 =>
      'Scan and organize IDs, contracts, and records with automatic categorization and expiry tracking.';

  @override
  String get onboardingTitle3 => 'Powerful Collections';

  @override
  String get onboardingSubtitle3 =>
      'Plan trips, track projects, manage budgets — with checklists, timelines, expenses, and reminders.';

  @override
  String get onboardingTitle4 => 'Encrypted Backups';

  @override
  String get onboardingSubtitle4 =>
      'Back up to Dropbox or Google Drive with AES-256 encryption. Restore anytime, on any device.';

  @override
  String get editCollection => 'Edit Collection';

  @override
  String get preparingExport => 'Preparing export...';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get settingsLockTimeoutUpdated => 'Lock timeout updated';

  @override
  String get settingsPinUpdatedSuccessfully => 'PIN updated successfully';

  @override
  String get settingsIncorrectPin => 'Incorrect PIN';

  @override
  String get settingsBiometricEnabled => 'Biometric unlock enabled';

  @override
  String get settingsBiometricDisabled => 'Biometric unlock disabled';

  @override
  String get scanTakePhoto => 'Take photo';

  @override
  String get scanChooseFromLibrary => 'Choose from library';

  @override
  String get scanRetake => 'Retake';

  @override
  String get generatorUse => 'Use';

  @override
  String get generatorNavVaults => 'Vaults';

  @override
  String get generatorNavPasswords => 'Passwords';

  @override
  String get generatorNavSecurity => 'Security';

  @override
  String get generatorNavSettings => 'Settings';

  @override
  String get generatorSideMyPasswords => 'My Passwords';

  @override
  String get generatorSideGenerator => 'Generator';

  @override
  String get generatorSideSecurityAudit => 'Security Audit';

  @override
  String get generatorSideHistory => 'History';

  @override
  String get generatorCopy => 'Copy';

  @override
  String get generatorGenerating => 'Generating...';

  @override
  String get generatorRegenerate => 'Regenerate';

  @override
  String get generatorStrengthLabel => 'PASSWORD STRENGTH';

  @override
  String get generatorSearchHint => 'Search entries...';

  @override
  String get generatorRuleUppercaseLetters => 'Uppercase Letters';

  @override
  String get generatorRuleLowercaseLetters => 'Lowercase Letters';

  @override
  String get generatorRuleIncludeNumbers => 'Include Numbers';

  @override
  String get generatorRuleIncludeSymbols => 'Include Symbols';

  @override
  String get generatorMobileRuleUppercase => 'Uppercase (A-Z)';

  @override
  String get generatorMobileRuleLowercase => 'Lowercase (a-z)';

  @override
  String get generatorMobileRuleNumbers => 'Numbers (0-9)';

  @override
  String get generatorMobileRuleSymbols => 'Symbols (!@#\$)';

  @override
  String get generatorMetricEntropy => 'Entropy Score';

  @override
  String get generatorMetricEntropyDesc =>
      'A measure of how unpredictable your password is.';

  @override
  String get generatorMetricCrackTime => 'Crack Time';

  @override
  String get generatorMetricCrackTimeDesc =>
      'Estimated brute-force crack time with modern hardware.';

  @override
  String get generatorMetricEasyToType => 'Easy to Type';

  @override
  String get generatorMetricEasyToTypeDesc =>
      'Balanced distribution for manual typing if needed.';

  @override
  String get collectionFieldTypeShortText => 'Short Text';

  @override
  String get collectionFieldTypeNumber => 'Number';

  @override
  String get collectionFieldTypeDate => 'Date';

  @override
  String get collectionFieldTypePhone => 'Phone';

  @override
  String get collectionEventTypeMilestone => 'Milestone';

  @override
  String get collectionEventTypeDeadline => 'Deadline';

  @override
  String get collectionEventTypeReminder => 'Reminder';

  @override
  String get collectionDocCategoryIdentity => 'Identity';

  @override
  String get collectionDocCategoryTravel => 'Travel';

  @override
  String get collectionDocCategoryFinance => 'Finance';

  @override
  String get collectionDocCategoryPropertyLease => 'Property · Lease';

  @override
  String get collectionDocCategoryOther => 'Other';

  @override
  String get collectionNoteCategoryPersonal => 'Personal';

  @override
  String get collectionNoteCategoryWork => 'Work';

  @override
  String get collectionExpenseCategoryTransport => 'Transport';

  @override
  String get collectionExpenseCategoryFood => 'Food';

  @override
  String get collectionExpenseCategoryShopping => 'Shopping';

  @override
  String get collectionExpenseCategoryRent => 'Rent';

  @override
  String get collectionExpenseCategoryOther => 'Other';

  @override
  String get collectionFileTypeDocuments => 'Documents';

  @override
  String get collectionFileTypeImages => 'Images';

  @override
  String get collectionFileTypeAllFiles => 'All Files';

  @override
  String get collectionEntryTapToEnterAmount => 'Tap to enter amount';

  @override
  String get collectionEntryHintNoteTitle => 'Note Title';

  @override
  String get collectionEntryHintReminderExample => 'Renew passport';

  @override
  String get collectionEntryAddAnotherTask => 'Add another task...';

  @override
  String get collectionEntryAddChecklistItem => 'Add an item';

  @override
  String get collectionEntryChecklistReorder => 'REORDER';

  @override
  String collectionEntryChecklistItemsSummary(int total, int done) {
    return 'ITEMS · $total · $done OF $total DONE';
  }

  @override
  String get collectionEntryUnitFloor => 'Unit / Floor';

  @override
  String get collectionEntryOptional => 'Optional';

  @override
  String get collectionEntryWhatWasThisFor => 'What was this for?';

  @override
  String get collectionTemplateTravelPlannerTitle => 'Travel Planner';

  @override
  String get collectionTemplateTravelPlannerDesc =>
      'Organize flights, hotels, and itineraries';

  @override
  String get collectionTemplateWeddingPlannerTitle => 'Wedding Planner';

  @override
  String get collectionTemplateWeddingPlannerDesc =>
      'Plan your perfect day with vendors, guests, and timelines';

  @override
  String get collectionTemplateBudgetPlannerTitle => 'Budget Planner';

  @override
  String get collectionTemplateBudgetPlannerDesc =>
      'Track income, expenses, and savings goals';

  @override
  String get collectionTemplateEventPlanningTitle => 'Event Planning';

  @override
  String get collectionTemplateEventPlanningDesc =>
      'Plan parties and gatherings with vendors and timelines';

  @override
  String get collectionTemplateProjectPlanningTitle => 'Project Planning';

  @override
  String get collectionTemplateProjectPlanningDesc =>
      'Roadmaps, tasks, and resource allocation';

  @override
  String get collectionTemplateFreelanceTrackerTitle => 'Freelance Tracker';

  @override
  String get collectionTemplateFreelanceTrackerDesc =>
      'Manage clients, invoices, and project deliverables';

  @override
  String get collectionTemplateHomeRenovationTitle => 'Home Renovation';

  @override
  String get collectionTemplateHomeRenovationDesc =>
      'Plan remodels with contractors, budgets, and timelines';

  @override
  String get collectionTemplateStudyPlannerTitle => 'Study Planner';

  @override
  String get collectionTemplateStudyPlannerDesc =>
      'Organize courses, exams, and study sessions';

  @override
  String get collectionTemplateFitnessTrackerTitle => 'Fitness Tracker';

  @override
  String get collectionTemplateFitnessTrackerDesc =>
      'Track workouts, nutrition, and fitness goals';

  @override
  String get collectionTemplateRecipeBookTitle => 'Recipe Book';

  @override
  String get collectionTemplateRecipeBookDesc =>
      'Save favorite recipes and grocery lists';

  @override
  String get collectionTemplateJobSearchTitle => 'Job Search';

  @override
  String get collectionTemplateJobSearchDesc =>
      'Track applications, interviews, and opportunities';

  @override
  String get collectionTemplatePropertyManagementTitle => 'Property Management';

  @override
  String get collectionTemplatePropertyManagementDesc =>
      'Track listings, maintenance, and tenants';

  @override
  String get collectionTemplateMovingChecklistTitle => 'Moving Checklist';

  @override
  String get collectionTemplateMovingChecklistDesc =>
      'Organize packing, utilities, and timelines';

  @override
  String get collectionTemplatePetCareTitle => 'Pet Care';

  @override
  String get collectionTemplatePetCareDesc =>
      'Manage vet visits, vaccinations, and health records';

  @override
  String get collectionTemplateVehicleMaintenanceTitle => 'Vehicle Maintenance';

  @override
  String get collectionTemplateVehicleMaintenanceDesc =>
      'Track service history, expenses, and schedules';

  @override
  String get collectionTemplateDiplomasCertificatesTitle =>
      'Diplomas & Certificates';

  @override
  String get collectionTemplateDiplomasCertificatesDesc =>
      'Organize degrees, transcripts, and professional certifications';

  @override
  String get collectionTemplateBankDocumentsTitle => 'Bank Documents (RIB)';

  @override
  String get collectionTemplateBankDocumentsDesc =>
      'Store RIB, IBAN, account details, and monthly statements';

  @override
  String get collectionTemplateHealthRecordsTitle => 'Health Records';

  @override
  String get collectionTemplateHealthRecordsDesc =>
      'Track vaccinations, allergies, doctor visits, and insurance';

  @override
  String get collectionTemplateTaxDocumentsTitle => 'Tax Documents';

  @override
  String get collectionTemplateTaxDocumentsDesc =>
      'Organize tax returns, receipts, deductions, and filing deadlines';

  @override
  String get collectionTemplateTagPopular => 'Popular';

  @override
  String get collectionTemplateTagNew => 'New';

  @override
  String get collectionTemplatePreview => 'Preview';

  @override
  String collectionTemplateBlocksCount(int count) {
    return '$count blocks';
  }

  @override
  String get workCompanyEditTitle => 'Edit Company';

  @override
  String get workCompanyAddTitle => 'Add New Company';

  @override
  String get workCompanyFieldRole => 'Role';

  @override
  String get workCompanyFieldEntryDate => 'Entry Date';

  @override
  String get workCompanyFieldEndDate => 'End Date (Optional)';

  @override
  String get workCompanyFieldContact => 'Primary Contact';

  @override
  String get workCompanyHintContact => 'Email or phone number';

  @override
  String get workCompanyHintLocation => 'City, Country';

  @override
  String get workCompanyStatusOngoing => 'Ongoing';

  @override
  String get workCompanyStatusFixed => 'Fixed';

  @override
  String get workCompanyPreviewMap => 'PREVIEW MAP';

  @override
  String get workCompanyAutoDetectLogo => 'Auto-detect logo';

  @override
  String get workCompanyUploadManually =>
      'Or upload manually (PNG, JPG up to 5MB)';

  @override
  String get commonTakePhoto => 'Take photo';

  @override
  String get commonChooseFromGallery => 'Choose from gallery';

  @override
  String get commonBrowseFiles => 'Browse files';

  @override
  String get credentialDeleteAction => 'Delete Credential';

  @override
  String get credentialDeleteFailed => 'Failed to delete credential';

  @override
  String get reminderActionRenewal => 'Renewal Needed';

  @override
  String get reminderActionRequired => 'Action Required';

  @override
  String get reminderActionUpload => 'Upload Now';

  @override
  String get reminderActionViewDetails => 'View Details';

  @override
  String get backupNotConnected => 'Not connected';

  @override
  String get backupUploadGoogleDrive => 'Upload All to Google Drive';

  @override
  String get backupUploadDropbox => 'Upload All to Dropbox';

  @override
  String get backupConnecting => 'Connecting...';

  @override
  String get backupAuthorize => 'Authorize';

  @override
  String get settingsHintPinDigits => '6-digit PIN';

  @override
  String get settingsVerify => 'Verify';

  @override
  String get settingsWipeEverything => 'Wipe Everything';

  @override
  String settingsExportFailedWithError(String error) {
    return 'Export failed: $error';
  }

  @override
  String get idCardRescan => 'Rescan';

  @override
  String get settingsThemeTitle => 'Theme';

  @override
  String get settingsThemeSubtitle => 'System, Light, or Dark';

  @override
  String get settingsAutoLockTitle => 'Auto-Lock Timeout';

  @override
  String get settingsAutoLockSubtitle => 'Lock vault after inactivity';

  @override
  String get settingsChangePinTitle => 'Change PIN';

  @override
  String get settingsChangePinSubtitle => 'Update your 6-digit vault PIN';

  @override
  String get settingsBiometricTitle => 'Biometric Unlock';

  @override
  String get settingsBiometricSubtitle => 'Toggle Face ID / fingerprint';

  @override
  String get settingsWipeVaultTitle => 'Wipe Vault';

  @override
  String get settingsWipeVaultSubtitle => 'Permanently delete all data';

  @override
  String get settingsWipeDialogTitle => 'Wipe All Data?';

  @override
  String get settingsWipeDialogContent =>
      'This will permanently delete ALL vault data including credentials, documents, collections, backups, and your PIN. This action cannot be undone.';

  @override
  String get settingsLockImmediately => 'Immediately';

  @override
  String get settingsLockNever => 'Never';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsBiometricEnabledLabel => 'Enabled';

  @override
  String get settingsBiometricEnabledSubtitle =>
      'Unlock with biometrics + PIN fallback';

  @override
  String get settingsBiometricDisabledSubtitle =>
      'Always require your 6-digit PIN';

  @override
  String get travelUnableLoadEvent => 'Unable to load timeline event';

  @override
  String get scanPassportTitle => 'Scan Passport';

  @override
  String get travelHintEventTitle => 'e.g. Flight to Paris';

  @override
  String get travelHintSearchLocation => 'Search location';

  @override
  String get travelFieldDeparture => 'Departure';

  @override
  String get travelFieldArrival => 'Arrival';

  @override
  String get travelFieldAirlineProvider => 'Airline / Provider';

  @override
  String get travelFieldFlightNo => 'Flight No.';

  @override
  String get travelFieldSeat => 'Seat';

  @override
  String get travelFieldTerminal => 'Terminal';

  @override
  String get travelFieldGate => 'Gate';

  @override
  String get travelHintBookingRef => 'e.g. AF12345';

  @override
  String get travelHintHotelName => 'Grand Hyatt Tokyo';

  @override
  String get travelFieldReservationNo => 'Reservation No.';

  @override
  String get travelFieldBookingPlatform => 'Booking Platform';

  @override
  String get travelFieldRoomType => 'Room Type';

  @override
  String get travelFieldGuests => 'Guests';

  @override
  String get travelFieldTotalPrice => 'Total Price';

  @override
  String get travelFieldCuisineType => 'Cuisine type';

  @override
  String get travelFieldEstimatedCost => 'Estimated Cost';

  @override
  String get travelFieldActivityType => 'Activity Type';

  @override
  String get travelFieldOrganizer => 'Organizer';

  @override
  String get travelFieldParticipants => 'Participants';

  @override
  String get travelFieldTicketPrice => 'Ticket Price';

  @override
  String get travelFieldBookingReference => 'Booking Reference';

  @override
  String get travelFieldReservationType => 'Reservation Type';

  @override
  String get travelFieldProvider => 'Provider';

  @override
  String get travelFieldPickupLocation => 'Pickup Location';

  @override
  String get travelFieldReservationNumber => 'Reservation Number';

  @override
  String get travelFieldVehicleDetails => 'Vehicle / Item Details';

  @override
  String get travelFieldPriceDeposit => 'Price / Deposit';

  @override
  String get travelHintNotes =>
      'Add confirmation codes, meeting points or details...';

  @override
  String get travelHintExpenseTitle => 'e.g. Dinner in Tokyo';

  @override
  String get travelHintAdditionalDetails => 'Add additional details here...';

  @override
  String get travelFieldSelectType => 'Select type';

  @override
  String get travelHintDocTitle => 'e.g. Boarding pass NH212';

  @override
  String get commonOptional => 'Optional';

  @override
  String get travelHintBookingNotes =>
      'Add additional notes or booking details';

  @override
  String get propertyTypeApartment => 'Apartment';

  @override
  String get propertyTypeSingleFamily => 'Single Family House';

  @override
  String get propertyTypeCondo => 'Condo';

  @override
  String get propertyTypeTownhouse => 'Townhouse';

  @override
  String get propertyTypeMultiFamily => 'Multi-Family';

  @override
  String get propertyTypePenthouse => 'Penthouse';

  @override
  String get propertyTypeVacationHome => 'Vacation Home';

  @override
  String get propertyTypeLand => 'Land';

  @override
  String get propertyTypeCommercial => 'Commercial';

  @override
  String get settingsImportVaultTitle => 'Import Vault Data';

  @override
  String get settingsImportVaultSubtitle => 'Restore from a .zip export file';

  @override
  String get settingsImportPasswordsTitle => 'Import Passwords';

  @override
  String get settingsImportPasswordsSubtitle =>
      'From Chrome, Safari, 1Password, Bitwarden or LastPass';

  @override
  String get macMenuFile => 'File';

  @override
  String get macMenuEdit => 'Edit';

  @override
  String get macMenuView => 'View';

  @override
  String get macMenuVault => 'Vault';

  @override
  String get macMenuNewCredential => 'New Credential';

  @override
  String get macMenuNewCollection => 'New Collection';

  @override
  String get macMenuImportVault => 'Import Vault...';

  @override
  String get macMenuExportVault => 'Export Vault...';

  @override
  String get macMenuCloseWindow => 'Close Window';

  @override
  String get macMenuCopy => 'Copy';

  @override
  String get macMenuPaste => 'Paste';

  @override
  String get macMenuSelectAll => 'Select All';

  @override
  String get macMenuFind => 'Find...';

  @override
  String get macMenuToggleSidebar => 'Toggle Sidebar';

  @override
  String get macMenuLockVault => 'Lock Vault';

  @override
  String get macMenuSearchVault => 'Search Vault';

  @override
  String get macMenuSettings => 'Settings...';

  @override
  String get dropboxSessionExpiredTitle => 'Dropbox session expired';

  @override
  String get dropboxSessionExpiredMessage =>
      'Your Dropbox connection has expired. Please reconnect to continue syncing your backups.';

  @override
  String get settingsImportPassphraseTitle => 'Enter Export Passphrase';

  @override
  String get settingsImportPassphraseHint => 'Passphrase used during export';

  @override
  String get settingsImportSuccess => 'Vault data imported successfully';

  @override
  String get settingsImportFailed => 'Failed to import vault data';

  @override
  String get settingsImportInvalidFile => 'Invalid or corrupted file';

  @override
  String get settingsImportAction => 'Import';

  @override
  String get lockScreenTooManyAttempts => 'Too many failed attempts';

  @override
  String lockScreenTryAgainIn(String time) {
    return 'Try again in $time';
  }

  @override
  String lockScreenAttemptsRemaining(int count) {
    return '$count attempts remaining before lockout';
  }

  @override
  String get scanIdentityVerification => 'Identity Verification';

  @override
  String get scanAdjustDocument => 'Adjust Document';

  @override
  String get addDocumentTitle => 'Add New Document';

  @override
  String get addDocumentPassportSubtitle => 'Passports and travel IDs';

  @override
  String get addDocumentIdCardSubtitle => 'National ID and identity cards';

  @override
  String get addDocumentDriversLicenseSubtitle => 'Driver\'s licenses';

  @override
  String get addDocumentOtherSubtitle => 'Any other document type';

  @override
  String get addDocumentSelectType => 'SELECT DOCUMENT TYPE';

  @override
  String get addDocumentInfoHint =>
      'Choose a document type to continue to manual entry and smart scan autofill.';

  @override
  String get addDocumentSecurityFooter =>
      'Your documents are encrypted and secure';

  @override
  String get idCardFrontSide => 'Front Side';

  @override
  String get idCardBackSide => 'Back Side';

  @override
  String get credentialEmptyTitle => 'Secure your accounts';

  @override
  String get credentialEmptySubtitle =>
      'Store your passwords and credentials safely, encrypted and offline on your device.';

  @override
  String get credentialEmptyAction => 'Add Credential';

  @override
  String get settingsRevealAuthTitle => 'Password Reveal Protection';

  @override
  String get settingsRevealAuthSubtitle =>
      'Require PIN or biometrics to see passwords';

  @override
  String get settingsRevealAuthEnabled => 'Password reveal protection enabled';

  @override
  String get settingsRevealAuthEnabledDetail =>
      'PIN or biometrics required before revealing any password';

  @override
  String get settingsRevealAuthDisabled =>
      'Password reveal protection disabled';

  @override
  String get settingsRevealAuthDisabledDetail =>
      'Passwords can be revealed freely without additional authentication';

  @override
  String get revealAuthPinTitle => 'Enter PIN to reveal';

  @override
  String get revealAuthPinHint => '6-digit PIN';

  @override
  String get revealAuthFailed => 'Authentication failed';

  @override
  String get secureNotesTitle => 'Secure Notes';

  @override
  String get secureNotesSubtitle => 'Encrypted personal notes';

  @override
  String get secureNotesEmpty => 'No notes yet';

  @override
  String get secureNotesAdd => 'New Note';

  @override
  String get noteEditorTitle => 'Edit Note';

  @override
  String get noteEditorTitleHint => 'Note title';

  @override
  String get noteEditorContentHint => 'Write your note...';

  @override
  String get noteCategoryPersonal => 'Personal';

  @override
  String get noteCategoryFinancial => 'Financial';

  @override
  String get noteCategoryLegal => 'Legal';

  @override
  String get noteCategoryMedical => 'Medical';

  @override
  String get noteDeleted => 'Note deleted';

  @override
  String get noteSaved => 'Note saved';

  @override
  String expiryNotification90Days(String title) {
    return 'Your $title expires in 3 months';
  }

  @override
  String expiryNotification30Days(String title) {
    return 'Your $title expires in 30 days';
  }

  @override
  String expiryNotification7Days(String title) {
    return 'Your $title expires next week';
  }

  @override
  String expiryNotificationExpired(String title) {
    return 'Your $title has expired';
  }

  @override
  String get collectionPinLockTitle => 'Enter Collection PIN';

  @override
  String get collectionPinSetTitle => 'Set Collection PIN';

  @override
  String get collectionPinHint => '4-digit PIN';

  @override
  String get collectionPinIncorrect => 'Incorrect PIN';

  @override
  String get collectionPinEnabled => 'Collection locked';

  @override
  String get collectionPinDisabled => 'Collection unlocked';

  @override
  String get breachWarningBadge => 'Breached';

  @override
  String breachWarningDetail(int count) {
    return '$count times in known breaches';
  }

  @override
  String get credentialFavoriteAdded => 'Added to favorites';

  @override
  String get credentialFavoriteRemoved => 'Removed from favorites';

  @override
  String get backupPreviewDate => 'Date';

  @override
  String get backupPreviewType => 'Type';

  @override
  String get backupPreviewEntities => 'Entities';

  @override
  String get backupPreviewFiles => 'Files';

  @override
  String get backupPreviewSize => 'Size';

  @override
  String get backupPreviewDevice => 'Device';

  @override
  String get backupPreviewEncryption => 'Encryption';

  @override
  String get backupPreviewEncryptionNone => 'None';

  @override
  String get backupRestoring => 'Restoring...';

  @override
  String get backupRestoringMessage =>
      'Please wait while your vault is being restored.';

  @override
  String get backupRestoreComplete => 'Restore Complete';

  @override
  String get backupRestoreCompleteMessage =>
      'Your vault has been successfully restored from the backup.';

  @override
  String backupDeleteConfirmation(String date) {
    return 'Are you sure you want to delete the backup from $date? This action cannot be undone.';
  }

  @override
  String get backupRememberPassphrase => 'Remember passphrase on this device';

  @override
  String get backupCloudProviderLabel => 'CLOUD PROVIDER';

  @override
  String get backupUploading => 'Uploading...';

  @override
  String get backupUploadToICloud => 'Upload to iCloud';

  @override
  String get backupAppleIdAutomatic => 'Uses your Apple ID automatically';

  @override
  String get backupGoogleAuthOpened =>
      'A browser window opened for Google authorization.';

  @override
  String get backupGoogleAuthApprove =>
      'Approve access. After redirect, copy the \"code\" value from the browser URL bar and paste it below.';

  @override
  String get backupICloudComingSoon =>
      'iCloud native integration coming soon. Use Dropbox for now.';

  @override
  String get backupInterruptedRestoreDetected => 'Interrupted Restore Detected';

  @override
  String get backupFrequencyError => 'Failed to update backup frequency.';

  @override
  String get backupDisconnectError => 'Failed to disconnect. Please try again.';

  @override
  String get searchPartialError =>
      'Some results may be missing due to an error.';

  @override
  String get documentShowAll => 'Show all';

  @override
  String get backupErrorLoad => 'Unable to load backups.';

  @override
  String get backupErrorRollback =>
      'Rollback cleanup failed. Please try again.';

  @override
  String get backupErrorCreate => 'Backup failed. Please try again.';

  @override
  String get backupErrorRestore =>
      'Restore failed. Please check your passphrase.';

  @override
  String get backupErrorDelete => 'Unable to delete backup.';

  @override
  String get backupErrorConnectDropbox =>
      'Connect Dropbox in Sync settings first.';

  @override
  String get backupErrorUpload => 'Upload failed. Please try again.';

  @override
  String get backupErrorDropboxNotConnected => 'Dropbox not connected.';

  @override
  String get backupErrorCloudRestore =>
      'Cloud restore failed. Please try again.';

  @override
  String get backupSuccessUpload => 'Uploaded to Dropbox successfully.';

  @override
  String get backupSuccessCloudRestore =>
      'Restored from cloud backup successfully.';

  @override
  String get backupGoogleDriveLabel => 'Google Drive';

  @override
  String get syncErrorLoad => 'Unable to load sync settings.';

  @override
  String get syncErrorSave => 'Unable to save settings.';

  @override
  String get syncErrorRun => 'Unable to run sync.';

  @override
  String get generatorErrorGenerate => 'Unable to generate password.';

  @override
  String get profileErrorLoad => 'Unable to load profile right now.';

  @override
  String get profileErrorShareOptions =>
      'Unable to load sharing options right now.';

  @override
  String get profileErrorVCard => 'Unable to generate vCard right now.';

  @override
  String get documentsErrorLoad => 'Unable to load documents.';

  @override
  String get documentsErrorCompany => 'Unable to load company details.';

  @override
  String get documentsErrorWorkVaults => 'Unable to load work vaults.';

  @override
  String get documentsErrorSecureIds => 'Unable to load secure IDs.';

  @override
  String get documentTimelineTitle => 'Document Timeline';

  @override
  String get documentTimelineEmpty => 'No documents with expiry dates yet.';

  @override
  String get documentTimelineErrorLoad => 'Unable to load expiring documents.';

  @override
  String get documentTimelineNoMatches =>
      'No documents match the selected filter.';

  @override
  String get documentTimelineExpired => 'Expired';

  @override
  String get documentTimelineSoon => 'Expiring Soon';

  @override
  String get documentTimelineSafe => 'Valid';

  @override
  String get documentTimelineFilterAll => 'All';

  @override
  String get documentTimelineFilterExpired => 'Expired';

  @override
  String get documentTimelineFilterCritical => '<30d';

  @override
  String get documentTimelineFilterWarning => '<90d';

  @override
  String get documentTimelineFilterSafe => 'Safe';

  @override
  String documentTimelineDaysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String documentTimelineExpiredDaysAgo(int days) {
    return 'Expired $days days ago';
  }

  @override
  String get documentTimelineExpiresToday => 'Expires today';

  @override
  String get collectionsErrorLoad => 'Unable to load collections right now.';

  @override
  String get collectionsErrorCreate => 'Unable to create collection.';

  @override
  String get collectionsErrorDelete => 'Unable to delete collection.';

  @override
  String get collectionsErrorDetail => 'Unable to load this collection.';

  @override
  String get credentialsErrorLoad => 'Unable to load credentials.';

  @override
  String get credentialsErrorDetail => 'Unable to load credential details.';

  @override
  String get shareTitle => 'Secure Share';

  @override
  String get sharePassphraseHint => 'Passphrase';

  @override
  String get shareTtlLabel => 'Link expires in:';

  @override
  String get shareTtl1Hour => '1 Hour';

  @override
  String get shareTtl1Day => '1 Day';

  @override
  String get shareTtl7Days => '7 Days';

  @override
  String get shareTtlOneTime => 'One-time View';

  @override
  String get shareGenerateLink => 'Generate Link';

  @override
  String get shareCopyLink => 'Link copied to clipboard!';

  @override
  String get shareLinkCopied => 'Share link copied!';

  @override
  String get sharePassphraseReminder =>
      'Important: Share the passphrase separately via a secure channel';

  @override
  String get importTitle => 'Import Credentials';

  @override
  String get importSelectSource => 'Select Import Source';

  @override
  String get importSelectFile => 'Select File';

  @override
  String get importPreview => 'Review Credentials';

  @override
  String get importComplete => 'Import Complete';

  @override
  String importFound(int count) {
    return 'Found $count credentials';
  }

  @override
  String importDuplicates(int count) {
    return '$count duplicates detected';
  }

  @override
  String get importSelectAll => 'Select All';

  @override
  String get importDeselectDuplicates => 'Deselect Duplicates';

  @override
  String get importImportSelected => 'Import Selected';

  @override
  String get importSuccess => 'Import Successful';

  @override
  String importCompleted(int imported, int skipped) {
    return 'Imported $imported credentials, skipped $skipped duplicates';
  }

  @override
  String importErrors(int count) {
    return '$count errors occurred';
  }

  @override
  String get importInstructions1Password =>
      'Export your 1Password vault as CSV. Go to File > Export and choose CSV format.';

  @override
  String get importInstructionsBitwarden =>
      'Export from Bitwarden as JSON. Go to Settings > Export Vault and choose JSON format.';

  @override
  String get importInstructionsChrome =>
      'Export from Chrome Password Manager. Go to Settings > Passwords and export your data as CSV.';

  @override
  String get importInstructionsSafari =>
      'Export from Safari. Go to File > Export Passwords and select the credentials to export.';

  @override
  String get importInstructionsLastPass =>
      'Export from LastPass as CSV. Go to Vault > More Options > Export and choose CSV format.';

  @override
  String get vaultHealthPageTitle => 'Vault Health';

  @override
  String get vaultHealthOut => 'out of 100';

  @override
  String vaultHealthLastChecked(String time) {
    return 'Checked $time';
  }

  @override
  String get vaultHealthGradeExcellent => 'Excellent';

  @override
  String get vaultHealthGradeGood => 'Good';

  @override
  String get vaultHealthGradeFair => 'Fair';

  @override
  String get vaultHealthGradePoor => 'Poor';

  @override
  String get vaultHealthSummaryTitle => 'Summary';

  @override
  String get vaultHealthWeakCount => 'Weak Passwords';

  @override
  String get vaultHealthReusedCount => 'Reused Passwords';

  @override
  String get vaultHealthBreachedCount => 'Breached';

  @override
  String get vaultHealthExpiringCount => 'Expiring Soon';

  @override
  String vaultHealthIssuesTitle(int count) {
    return '$count Issues Found';
  }

  @override
  String get vaultHealthNoIssues => 'No Issues Found';

  @override
  String get vaultHealthAllGood => 'Your vault is in great shape!';

  @override
  String get vaultHealthCritical => 'Critical';

  @override
  String get vaultHealthHigh => 'High';

  @override
  String get vaultHealthMedium => 'Medium';

  @override
  String get vaultHealthLow => 'Low';

  @override
  String get navBundles => 'Bundles';

  @override
  String get bundlesTitle => 'Bundles';

  @override
  String get bundlesEmptyTitle => 'No bundles yet';

  @override
  String get bundlesEmptySubtitle =>
      'Create a bundle to group files and credentials for an application, a trip, or any other purpose.';

  @override
  String get bundlesErrorLoad => 'Unable to load bundles.';

  @override
  String get bundleCreateAction => 'New bundle';

  @override
  String get bundleCreateTitle => 'Create bundle';

  @override
  String get bundleCreateError =>
      'Couldn\'t create the bundle. Please try again.';

  @override
  String get bundleFieldTitle => 'Title';

  @override
  String get bundleFieldTitleHint => 'e.g. France Visa Application';

  @override
  String get bundleFieldTitleRequired => 'Title is required';

  @override
  String get bundleFieldPurpose => 'Purpose (optional)';

  @override
  String get bundleFieldPurposeHint => 'e.g. Schengen visa — Feb 2026';

  @override
  String get bundleFieldDescription => 'Description (optional)';

  @override
  String get bundleFieldDescriptionHint => 'What is this bundle for?';

  @override
  String get bundleStatusDraft => 'Draft';

  @override
  String get bundleStatusReady => 'Ready';

  @override
  String get bundleStatusExported => 'Exported';

  @override
  String get bundleStatusArchived => 'Archived';

  @override
  String bundleItemCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'no items',
    );
    return '$_temp0';
  }

  @override
  String bundleUpdatedAt(Object date) {
    return 'updated $date';
  }

  @override
  String bundleLastExportedAt(Object date) {
    return 'exported $date';
  }

  @override
  String get bundleDeleteTitle => 'Delete bundle?';

  @override
  String bundleDeleteMessage(Object title) {
    return '\"$title\" will be permanently deleted.';
  }

  @override
  String get bundleDeleteConfirm => 'Delete';

  @override
  String get bundleDetailLoadingTitle => 'Bundle';

  @override
  String get bundleDetailErrorLoad => 'Unable to load this bundle.';

  @override
  String get bundleDetailMenuTooltip => 'More';

  @override
  String get bundleActionExport => 'Export / share';

  @override
  String get bundleTemplateSelectedBadge => 'Selected';

  @override
  String get bundleTemplateSectionTitle => 'Start with a template';

  @override
  String get bundleTemplateSectionSubtitle =>
      'Templates prefill the bundle and track required items so you can see what is missing.';

  @override
  String get bundleTemplateBlankTitle => 'Blank bundle';

  @override
  String get bundleTemplateBlankSubtitle =>
      'Start empty and add items manually.';

  @override
  String get bundleTemplatePrefillHint =>
      'Selecting a template prefills the bundle fields and checks your vault for matching items.';

  @override
  String get bundleTemplateFranceVisaTitle => 'France Visa';

  @override
  String get bundleTemplateFranceVisaSummary =>
      'Identity, travel, accommodation, employment, insurance, and financial records.';

  @override
  String get bundleTemplateApartmentRentalTitle => 'Apartment Rental';

  @override
  String get bundleTemplateApartmentRentalSummary =>
      'Identity, income proof, employment, tax, and rent records.';

  @override
  String get bundleTemplateJobOnboardingTitle => 'New Job Onboarding';

  @override
  String get bundleTemplateJobOnboardingSummary =>
      'Contract, identity, bank info, and qualification records.';

  @override
  String get bundleTemplateTravelClaimTitle => 'Travel Claim';

  @override
  String get bundleTemplateTravelClaimSummary =>
      'Bookings, receipts, invoices, and claim support documents.';

  @override
  String get bundleTemplateChecklistTitle => 'Template checklist';

  @override
  String bundleTemplateChecklistSubtitle(int completed, int total) {
    return '$completed of $total required items ready';
  }

  @override
  String get bundleTemplateAddMissingAction => 'Add missing';

  @override
  String get bundleTemplateReadyTitle => 'Ready to export';

  @override
  String get bundleTemplateMissingTitle => 'Missing required items';

  @override
  String get bundleTemplateReadySubtitle => 'All required items are attached.';

  @override
  String bundleTemplateMissingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count required items are missing',
      one: '1 required item is missing',
    );
    return '$_temp0';
  }

  @override
  String get bundleTemplateRequiredLabel => 'Required';

  @override
  String get bundleTemplateCompletedLabel => 'Completed';

  @override
  String get bundleTemplateOptionalLabel => 'Optional';

  @override
  String bundleTemplateMatchedCount(int matched, int minimum) {
    return '$matched of $minimum';
  }

  @override
  String get bundleActionArchive => 'Archive';

  @override
  String get bundleActionUnarchive => 'Unarchive';

  @override
  String get bundleActionDelete => 'Delete bundle';

  @override
  String get bundleSectionItems => 'Items';

  @override
  String get bundleSectionHistory => 'History';

  @override
  String get bundleEmptyItems =>
      'No items yet. Tap \"Add items\" to pick from your vault.';

  @override
  String get bundleAddItems => 'Add items';

  @override
  String get bundleHistoryEmpty => 'No activity yet.';

  @override
  String get bundleEventCreated => 'Bundle created';

  @override
  String get bundleEventRenamed => 'Renamed';

  @override
  String get bundleEventPurposeUpdated => 'Purpose updated';

  @override
  String get bundleEventDescriptionUpdated => 'Description updated';

  @override
  String get bundleEventItemAdded => 'Item added';

  @override
  String get bundleEventItemRemoved => 'Item removed';

  @override
  String get bundleEventItemReordered => 'Items reordered';

  @override
  String get bundleEventStatusChanged => 'Status changed';

  @override
  String get bundleEventExported => 'Exported';

  @override
  String get bundleEventArchived => 'Archived';

  @override
  String get bundleEventRestored => 'Restored';

  @override
  String get bundleAddToTitle => 'Add to bundle';

  @override
  String bundleAddToSubtitle(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pick a bundle for $count items',
      one: 'Pick a bundle for 1 item',
    );
    return '$_temp0';
  }

  @override
  String get bundleAddToNew => 'New';

  @override
  String get bundleAddToEmpty =>
      'You have no bundles yet. Tap \"New\" to create one.';

  @override
  String bundleAddToSnackbar(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items added to bundle.',
      one: '1 item added to bundle.',
    );
    return '$_temp0';
  }

  @override
  String get bundleExportTitle => 'Export bundle';

  @override
  String get bundleExportSectionWhat => 'Bundle';

  @override
  String get bundleExportSectionOptions => 'Options';

  @override
  String get bundleExportEncryptTitle => 'Encrypt archive';

  @override
  String get bundleExportEncryptSubtitle =>
      'Protect the ZIP with a password (AES-256).';

  @override
  String get bundleExportPassphraseLabel => 'Passphrase';

  @override
  String get bundleExportPassphraseHint =>
      'Share this separately with the recipient';

  @override
  String get bundleExportPassphraseRequired => 'Please enter a passphrase.';

  @override
  String get bundleExportRunAction => 'Build archive';

  @override
  String get bundleExportError => 'Export failed. Please try again.';

  @override
  String get bundleExportSuccess => 'Archive ready';

  @override
  String get bundleExportShare => 'Share archive';

  @override
  String bundleSearchPickBanner(Object title) {
    return 'Picking items for \"$title\"';
  }

  @override
  String get bundleSearchPickBannerGeneric => 'Tap items to add to a bundle';

  @override
  String bundleSearchSelectedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get bundleSearchClearSelection => 'Clear';

  @override
  String get bundleSearchAddSelected => 'Add selected';

  @override
  String get bundleSearchAddToBundle => 'Add to bundle';

  @override
  String get bundleTimeJustNow => 'just now';

  @override
  String bundleTimeMinutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String bundleTimeHoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
      one: '1 h ago',
    );
    return '$_temp0';
  }

  @override
  String get bundleTimeYesterday => 'yesterday';

  @override
  String bundleTimeDaysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get bundlePreviewUnavailable =>
      'Preview is not yet available for this item type.';

  @override
  String get navTasks => 'Tasks';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksEmptyTitle => 'No task lists yet';

  @override
  String get tasksEmptySubtitle =>
      'Create a list to track things you need to do — errands, a project, a trip checklist.';

  @override
  String get tasksErrorLoad => 'Unable to load task lists.';

  @override
  String get tasksListCreateAction => 'New list';

  @override
  String get tasksListCreateTitle => 'Create task list';

  @override
  String get tasksListCreateError =>
      'Couldn\'t create the list. Please try again.';

  @override
  String get tasksListFieldTitle => 'Title';

  @override
  String get tasksListFieldTitleHint => 'e.g. Visa application prep';

  @override
  String get tasksListFieldTitleRequired => 'Title is required';

  @override
  String get tasksListFieldDescription => 'Description (optional)';

  @override
  String get tasksListFieldDescriptionHint => 'What is this list for?';

  @override
  String get tasksListPickIcon => 'Icon';

  @override
  String get tasksListPickColor => 'Colour';

  @override
  String get tasksListLoadingTitle => 'Tasks';

  @override
  String get tasksListErrorLoad => 'Unable to load this list.';

  @override
  String get tasksHideArchived => 'Hide archived';

  @override
  String get tasksShowArchived => 'Show archived';

  @override
  String get tasksHideDone => 'Hide completed';

  @override
  String get tasksShowDone => 'Show completed';

  @override
  String tasksOverdueBadge(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdue',
      one: '1 overdue',
    );
    return '$_temp0';
  }

  @override
  String tasksOpenCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open',
      one: '1 open',
      zero: 'no open',
    );
    return '$_temp0';
  }

  @override
  String tasksDoneCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count done',
      one: '1 done',
      zero: '0 done',
    );
    return '$_temp0';
  }

  @override
  String get tasksActionArchive => 'Archive';

  @override
  String get tasksActionUnarchive => 'Unarchive';

  @override
  String get tasksActionDelete => 'Delete';

  @override
  String get tasksActionPin => 'Pin to top';

  @override
  String get tasksActionUnpin => 'Unpin';

  @override
  String get tasksDeleteListTitle => 'Delete list?';

  @override
  String tasksDeleteListMessage(Object title) {
    return '\"$title\" and all its tasks will be permanently deleted.';
  }

  @override
  String get tasksDeleteListConfirm => 'Delete';

  @override
  String get taskCreateAction => 'Add task';

  @override
  String get taskCreateTitle => 'New task';

  @override
  String get taskEditTitle => 'Edit task';

  @override
  String get taskFieldTitle => 'Task';

  @override
  String get taskFieldTitleHint => 'What needs to be done?';

  @override
  String get taskFieldNotes => 'Notes';

  @override
  String get taskFieldNotesHint => 'Details, sub-steps, context…';

  @override
  String get taskFieldPriority => 'Priority';

  @override
  String get taskFieldDue => 'Due date';

  @override
  String get taskFieldDueNone => 'No due date';

  @override
  String get taskFieldDueClear => 'Clear due date';

  @override
  String get taskFieldPin => 'Pin this task';

  @override
  String get taskFieldPinHint => 'Pinned tasks stay at the top of the list.';

  @override
  String get taskFieldLink => 'Linked vault item (optional)';

  @override
  String get taskFieldLinkNone =>
      'Tap to pick a document, credential or bundle';

  @override
  String get taskFieldLinkClear => 'Remove link';

  @override
  String get taskPriorityLow => 'Low';

  @override
  String get taskPriorityMedium => 'Medium';

  @override
  String get taskPriorityHigh => 'High';

  @override
  String get taskDueToday => 'Due today';

  @override
  String get taskDueTomorrow => 'Due tomorrow';

  @override
  String taskDueInDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Due in $count days',
      one: 'Due in 1 day',
    );
    return '$_temp0';
  }

  @override
  String taskDueOverdueBy(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Overdue by $count days',
      one: 'Overdue by 1 day',
    );
    return '$_temp0';
  }

  @override
  String get tasksSectionPinned => 'Pinned';

  @override
  String get tasksSectionOverdue => 'Overdue';

  @override
  String get tasksSectionToday => 'Today';

  @override
  String get tasksSectionUpcoming => 'Upcoming';

  @override
  String get tasksSectionNoDate => 'No due date';

  @override
  String get tasksSectionDone => 'Completed';

  @override
  String get tasksStatOpen => 'Open';

  @override
  String get tasksStatDone => 'Done';

  @override
  String get tasksStatOverdue => 'Overdue';

  @override
  String get tasksDetailEmpty =>
      'No tasks yet. Tap \"Add task\" to create the first one.';

  @override
  String get tasksEnterReorder => 'Reorder';

  @override
  String get tasksExitReorder => 'Done reordering';
}
