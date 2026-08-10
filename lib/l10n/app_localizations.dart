import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Credence'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabCredentials.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get tabCredentials;

  /// No description provided for @tabGenerator.
  ///
  /// In en, this message translates to:
  /// **'Generator'**
  String get tabGenerator;

  /// No description provided for @tabDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get tabDocuments;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get commonSaving;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonErrorGeneric;

  /// No description provided for @commonErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data. Tap retry to try again.'**
  String get commonErrorLoad;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get commonViewAll;

  /// No description provided for @commonPasswordCopiedSecurely.
  ///
  /// In en, this message translates to:
  /// **'Password copied securely.'**
  String get commonPasswordCopiedSecurely;

  /// No description provided for @commonUnableCopyPassword.
  ///
  /// In en, this message translates to:
  /// **'Unable to copy password.'**
  String get commonUnableCopyPassword;

  /// No description provided for @tooltipCopyPassword.
  ///
  /// In en, this message translates to:
  /// **'Copy password'**
  String get tooltipCopyPassword;

  /// No description provided for @tooltipOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get tooltipOpenDetails;

  /// No description provided for @credentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get credentialsTitle;

  /// No description provided for @credentialsUnableLoadVaultOverview.
  ///
  /// In en, this message translates to:
  /// **'Unable to load vault overview.'**
  String get credentialsUnableLoadVaultOverview;

  /// No description provided for @credentialsUnableLoadAccounts.
  ///
  /// In en, this message translates to:
  /// **'Unable to load accounts.'**
  String get credentialsUnableLoadAccounts;

  /// No description provided for @credentialsUnableLoadSingle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load credential.'**
  String get credentialsUnableLoadSingle;

  /// No description provided for @credentialsNoAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No accounts found.'**
  String get credentialsNoAccountsFound;

  /// No description provided for @credentialsNoResultsForQuery.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String credentialsNoResultsForQuery(String query);

  /// No description provided for @credentialsGeneratorCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Generator'**
  String get credentialsGeneratorCardTitle;

  /// No description provided for @credentialsGeneratorCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create secure passwords in one tap'**
  String get credentialsGeneratorCardSubtitle;

  /// No description provided for @credentialsDesktopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline vault, instant access'**
  String get credentialsDesktopSubtitle;

  /// No description provided for @credentialsAdded.
  ///
  /// In en, this message translates to:
  /// **'Credential added.'**
  String get credentialsAdded;

  /// No description provided for @credentialsUnableAdd.
  ///
  /// In en, this message translates to:
  /// **'Unable to add credential.'**
  String get credentialsUnableAdd;

  /// No description provided for @credentialsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Credential updated.'**
  String get credentialsUpdated;

  /// No description provided for @credentialsUnableUpdate.
  ///
  /// In en, this message translates to:
  /// **'Unable to update credential right now.'**
  String get credentialsUnableUpdate;

  /// No description provided for @credentialsSavingLogo.
  ///
  /// In en, this message translates to:
  /// **'Saving logo locally...'**
  String get credentialsSavingLogo;

  /// No description provided for @credentialsNewCredential.
  ///
  /// In en, this message translates to:
  /// **'New Credential'**
  String get credentialsNewCredential;

  /// No description provided for @credentialsSingleCredential.
  ///
  /// In en, this message translates to:
  /// **'Credential'**
  String get credentialsSingleCredential;

  /// No description provided for @credentialsLogoSavingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Logo is still saving locally. Please wait a moment.'**
  String get credentialsLogoSavingInProgress;

  /// No description provided for @credentialsRequiredFieldsMissing.
  ///
  /// In en, this message translates to:
  /// **'Service, username and password are required.'**
  String get credentialsRequiredFieldsMissing;

  /// No description provided for @credentialsLookForAnotherIcon.
  ///
  /// In en, this message translates to:
  /// **'Look for another icon'**
  String get credentialsLookForAnotherIcon;

  /// No description provided for @credentialsResetIcon.
  ///
  /// In en, this message translates to:
  /// **'Reset icon'**
  String get credentialsResetIcon;

  /// No description provided for @credentialsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get credentialsCategory;

  /// No description provided for @credentialsSearchEnterServiceOrWebsite.
  ///
  /// In en, this message translates to:
  /// **'Enter service name or website first.'**
  String get credentialsSearchEnterServiceOrWebsite;

  /// No description provided for @credentialsNoMatchingIconFound.
  ///
  /// In en, this message translates to:
  /// **'No matching company icon found.'**
  String get credentialsNoMatchingIconFound;

  /// No description provided for @credentialsSelectSuggestedBrand.
  ///
  /// In en, this message translates to:
  /// **'Select a suggested brand to update icon and site.'**
  String get credentialsSelectSuggestedBrand;

  /// No description provided for @credentialsUnableSearchBrands.
  ///
  /// In en, this message translates to:
  /// **'Unable to search brands right now.'**
  String get credentialsUnableSearchBrands;

  /// No description provided for @credentialsLogoPreviewLoadedLocalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Logo preview loaded, but local save failed for this brand.'**
  String get credentialsLogoPreviewLoadedLocalSaveFailed;

  /// No description provided for @credentialsUnableSaveLogoLocally.
  ///
  /// In en, this message translates to:
  /// **'Unable to save logo locally.'**
  String get credentialsUnableSaveLogoLocally;

  /// No description provided for @credentialsEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Email copied.'**
  String get credentialsEmailCopied;

  /// No description provided for @credentialsPasswordCopied.
  ///
  /// In en, this message translates to:
  /// **'Password copied.'**
  String get credentialsPasswordCopied;

  /// No description provided for @credentialsNoUrlToCopy.
  ///
  /// In en, this message translates to:
  /// **'No URL to copy.'**
  String get credentialsNoUrlToCopy;

  /// No description provided for @credentialsWebsiteCopied.
  ///
  /// In en, this message translates to:
  /// **'Website URL copied.'**
  String get credentialsWebsiteCopied;

  /// No description provided for @credentialsAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get credentialsAddToFavorites;

  /// No description provided for @credentialsAddedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites.'**
  String get credentialsAddedToFavorites;

  /// No description provided for @credentialsAddToSiriShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Add to Siri Shortcuts'**
  String get credentialsAddToSiriShortcuts;

  /// No description provided for @credentialsSiriShortcutReady.
  ///
  /// In en, this message translates to:
  /// **'Siri Shortcut action ready.'**
  String get credentialsSiriShortcutReady;

  /// No description provided for @credentialsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get credentialsDelete;

  /// No description provided for @credentialsDeleteNeedsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete action requires confirmation.'**
  String get credentialsDeleteNeedsConfirmation;

  /// No description provided for @credentialFieldAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Label'**
  String get credentialFieldAccountLabel;

  /// No description provided for @credentialFieldEmailUsername.
  ///
  /// In en, this message translates to:
  /// **'Email/Username'**
  String get credentialFieldEmailUsername;

  /// No description provided for @credentialFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get credentialFieldPassword;

  /// No description provided for @credentialFieldWebsiteUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get credentialFieldWebsiteUrl;

  /// No description provided for @credentialFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get credentialFieldNotes;

  /// No description provided for @credentialEditServicePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get credentialEditServicePlaceholder;

  /// No description provided for @credentialEditAccountPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Personal Account'**
  String get credentialEditAccountPlaceholder;

  /// No description provided for @credentialEditEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'jane.smith@email.com'**
  String get credentialEditEmailPlaceholder;

  /// No description provided for @credentialEditUrlPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'https://github.com'**
  String get credentialEditUrlPlaceholder;

  /// No description provided for @credentialEditNotesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Recovery code, security notes, reminders...'**
  String get credentialEditNotesPlaceholder;

  /// No description provided for @credentialsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search credentials...'**
  String get credentialsSearchHint;

  /// No description provided for @credentialsSearchCountHint.
  ///
  /// In en, this message translates to:
  /// **'Search {count} credentials...'**
  String credentialsSearchCountHint(int count);

  /// No description provided for @homeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get homeWelcomeBack;

  /// No description provided for @homeGreetingNamed.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}.'**
  String homeGreetingNamed(String name);

  /// No description provided for @homeGreetingFallback.
  ///
  /// In en, this message translates to:
  /// **'Hi.'**
  String get homeGreetingFallback;

  /// No description provided for @homeOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Vault Owner'**
  String get homeOwnerName;

  /// No description provided for @homeSearchVaultDocuments.
  ///
  /// In en, this message translates to:
  /// **'Search vault, documents...'**
  String get homeSearchVaultDocuments;

  /// No description provided for @homeActionRequired.
  ///
  /// In en, this message translates to:
  /// **'ACTION REQUIRED'**
  String get homeActionRequired;

  /// No description provided for @homeSecurityCheckRecommended.
  ///
  /// In en, this message translates to:
  /// **'Security check is recommended.'**
  String get homeSecurityCheckRecommended;

  /// No description provided for @homeReviewNow.
  ///
  /// In en, this message translates to:
  /// **'Review now'**
  String get homeReviewNow;

  /// No description provided for @homeAllCredentialsSecure.
  ///
  /// In en, this message translates to:
  /// **'All credentials look secure right now.'**
  String get homeAllCredentialsSecure;

  /// No description provided for @homeFrequentlyUsed.
  ///
  /// In en, this message translates to:
  /// **'Frequently Used'**
  String get homeFrequentlyUsed;

  /// No description provided for @homeNoQuickItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No quick items yet.'**
  String get homeNoQuickItemsYet;

  /// No description provided for @homeRecentItems.
  ///
  /// In en, this message translates to:
  /// **'Recent Items'**
  String get homeRecentItems;

  /// No description provided for @homeRecentActivityPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your recent activity will show here.'**
  String get homeRecentActivityPlaceholder;

  /// No description provided for @homeLastUsedWithTime.
  ///
  /// In en, this message translates to:
  /// **'{username} • Last used {time}'**
  String homeLastUsedWithTime(String username, String time);

  /// No description provided for @homeRelativeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get homeRelativeJustNow;

  /// No description provided for @homeRelativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String homeRelativeMinutesAgo(int minutes);

  /// No description provided for @homeRelativeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String homeRelativeHoursAgo(int hours);

  /// No description provided for @homeRelativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get homeRelativeYesterday;

  /// No description provided for @homeRelativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String homeRelativeDaysAgo(int days);

  /// No description provided for @homeRelativeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w ago'**
  String homeRelativeWeeksAgo(int weeks);

  /// No description provided for @homeRelativeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months}mo ago'**
  String homeRelativeMonthsAgo(int months);

  /// No description provided for @securitySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettingsTitle;

  /// No description provided for @documentsPageComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{category} documents page is coming next.'**
  String documentsPageComingSoon(String category);

  /// No description provided for @desktopLocalDataOnly.
  ///
  /// In en, this message translates to:
  /// **'Data stays local to this device'**
  String get desktopLocalDataOnly;

  /// No description provided for @passwordHealthChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get passwordHealthChecking;

  /// No description provided for @passwordHealthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordHealthWeak;

  /// No description provided for @passwordHealthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordHealthFair;

  /// No description provided for @passwordHealthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordHealthStrong;

  /// No description provided for @passwordHealthExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get passwordHealthExcellent;

  /// No description provided for @profileExportVaultData.
  ///
  /// In en, this message translates to:
  /// **'Export Vault Data'**
  String get profileExportVaultData;

  /// No description provided for @profileUnableLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load profile right now.'**
  String get profileUnableLoad;

  /// No description provided for @profileShareSecureProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Secure Profile'**
  String get profileShareSecureProfileTitle;

  /// No description provided for @profileShareSecureProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a temporary encrypted vCard'**
  String get profileShareSecureProfileSubtitle;

  /// No description provided for @profileAccountDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get profileAccountDetailsTitle;

  /// No description provided for @profileAccountDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT DETAILS'**
  String get profileAccountDetailsSection;

  /// No description provided for @profileRecentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get profileRecentActivityTitle;

  /// No description provided for @profileRecentActivitySection.
  ///
  /// In en, this message translates to:
  /// **'RECENT ACTIVITY'**
  String get profileRecentActivitySection;

  /// No description provided for @profileExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get profileExporting;

  /// No description provided for @profileExportHint.
  ///
  /// In en, this message translates to:
  /// **'Exported data is encrypted and requires your master password to decrypt on another device.'**
  String get profileExportHint;

  /// No description provided for @profileAddAccountDetailsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add account details first before sharing profile.'**
  String get profileAddAccountDetailsFirst;

  /// No description provided for @profileExportStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing export...'**
  String get profileExportStatusPreparing;

  /// No description provided for @profileExportStatusSelectDestination.
  ///
  /// In en, this message translates to:
  /// **'Select destination to save archive...'**
  String get profileExportStatusSelectDestination;

  /// No description provided for @profileExportStatusOpeningShareSheet.
  ///
  /// In en, this message translates to:
  /// **'Opening share sheet...'**
  String get profileExportStatusOpeningShareSheet;

  /// No description provided for @profileExportSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Vault archive saved locally.'**
  String get profileExportSavedLocally;

  /// No description provided for @profileExportSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Vault archive saved: {path}'**
  String profileExportSavedAt(String path);

  /// No description provided for @profileExportGeneratedAndShared.
  ///
  /// In en, this message translates to:
  /// **'Vault archive generated and shared.'**
  String get profileExportGeneratedAndShared;

  /// No description provided for @profileExportStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed.'**
  String get profileExportStatusFailed;

  /// No description provided for @profileUnableExportVaultData.
  ///
  /// In en, this message translates to:
  /// **'Unable to export vault data right now.'**
  String get profileUnableExportVaultData;

  /// No description provided for @profileExportPassphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Passphrase'**
  String get profileExportPassphraseTitle;

  /// No description provided for @profileExportPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Enter export passphrase'**
  String get profileExportPassphraseHint;

  /// No description provided for @profileExportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get profileExportAction;

  /// No description provided for @profileExportStatusOpeningSaveDialog.
  ///
  /// In en, this message translates to:
  /// **'Opening save destination dialog...'**
  String get profileExportStatusOpeningSaveDialog;

  /// No description provided for @profileExportSaveArchiveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Vault Archive'**
  String get profileExportSaveArchiveButton;

  /// No description provided for @profileExportStatusSaveDialogTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Save dialog timed out on this platform; using local fallback path.'**
  String get profileExportStatusSaveDialogTimedOut;

  /// No description provided for @profileExportStatusNoSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save dialog closed without location.'**
  String get profileExportStatusNoSaveLocation;

  /// No description provided for @profileExportStatusSavingArchive.
  ///
  /// In en, this message translates to:
  /// **'Saving archive file...'**
  String get profileExportStatusSavingArchive;

  /// No description provided for @profileExportStatusArchiveSaved.
  ///
  /// In en, this message translates to:
  /// **'Archive saved to {path}'**
  String profileExportStatusArchiveSaved(String path);

  /// No description provided for @profileExportStatusSaveDialogFailed.
  ///
  /// In en, this message translates to:
  /// **'Save dialog failed; trying fallback location...'**
  String get profileExportStatusSaveDialogFailed;

  /// No description provided for @profileExportStatusSavedFallback.
  ///
  /// In en, this message translates to:
  /// **'Saved to fallback location.'**
  String get profileExportStatusSavedFallback;

  /// No description provided for @profileExportStatusFallbackSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Fallback save success: {path}'**
  String profileExportStatusFallbackSaveSuccess(String path);

  /// No description provided for @profileExportStatusFallbackSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Fallback save failed.'**
  String get profileExportStatusFallbackSaveFailed;

  /// No description provided for @profileExportArchiveNotFound.
  ///
  /// In en, this message translates to:
  /// **'Archive file not found.'**
  String get profileExportArchiveNotFound;

  /// No description provided for @profileExportShareText.
  ///
  /// In en, this message translates to:
  /// **'Vault archive ({documents} docs, {credentials} credentials, {files} linked files)'**
  String profileExportShareText(int documents, int credentials, int files);

  /// No description provided for @profileExportInProgress.
  ///
  /// In en, this message translates to:
  /// **'Export in progress'**
  String get profileExportInProgress;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profileNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get profileNotProvided;

  /// No description provided for @profileNoRecentActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet.'**
  String get profileNoRecentActivityYet;

  /// No description provided for @profileNoActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get profileNoActivityYet;

  /// No description provided for @profileNoActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your vault is empty. All your\nsecurity events will appear\nhere.'**
  String get profileNoActivitySubtitle;

  /// No description provided for @profileActivityWithTime.
  ///
  /// In en, this message translates to:
  /// **'{subtitle} • {time}'**
  String profileActivityWithTime(String subtitle, String time);

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// No description provided for @profileUpdatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Update Photo'**
  String get profileUpdatePhoto;

  /// No description provided for @profileTapChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change your profile picture'**
  String get profileTapChangePhoto;

  /// No description provided for @profileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get profileFirstName;

  /// No description provided for @profileLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get profileLastName;

  /// No description provided for @profileEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get profileEmailAddress;

  /// No description provided for @profileSecurePhone.
  ///
  /// In en, this message translates to:
  /// **'Secure Phone'**
  String get profileSecurePhone;

  /// No description provided for @profileContactInfoSecurityNotice.
  ///
  /// In en, this message translates to:
  /// **'Changes to your contact information may require secondary authentication for security purposes. Your vault remains encrypted.'**
  String get profileContactInfoSecurityNotice;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveChanges;

  /// No description provided for @profileChooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from Library'**
  String get profileChooseFromLibrary;

  /// No description provided for @profileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get profileTakePhoto;

  /// No description provided for @profileRequiredFieldsMessage.
  ///
  /// In en, this message translates to:
  /// **'First name, last name and email are required.'**
  String get profileRequiredFieldsMessage;

  /// No description provided for @profileUnableSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save profile right now.'**
  String get profileUnableSave;

  /// No description provided for @profileShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get profileShareTitle;

  /// No description provided for @profileShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the information you want to include in your encrypted vCard.'**
  String get profileShareSubtitle;

  /// No description provided for @profileShareAttributesSection.
  ///
  /// In en, this message translates to:
  /// **'PROFILE ATTRIBUTES'**
  String get profileShareAttributesSection;

  /// No description provided for @profileShareSecurityOptionsSection.
  ///
  /// In en, this message translates to:
  /// **'SECURITY OPTIONS'**
  String get profileShareSecurityOptionsSection;

  /// No description provided for @profileShareGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get profileShareGenerating;

  /// No description provided for @profileShareGenerateSecureLink.
  ///
  /// In en, this message translates to:
  /// **'Generate vCard'**
  String get profileShareGenerateSecureLink;

  /// No description provided for @profileShareQrCode.
  ///
  /// In en, this message translates to:
  /// **'Preview vCard'**
  String get profileShareQrCode;

  /// No description provided for @profileShareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy vCard'**
  String get profileShareCopyLink;

  /// No description provided for @profileShareLinkExpires.
  ///
  /// In en, this message translates to:
  /// **'vCard valid until {date}'**
  String profileShareLinkExpires(String date);

  /// No description provided for @profileSharePoweredByEncryption.
  ///
  /// In en, this message translates to:
  /// **'POWERED BY END-TO-END ENCRYPTION'**
  String get profileSharePoweredByEncryption;

  /// No description provided for @profileShareHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String profileShareHoursLabel(int hours);

  /// No description provided for @profileShareGenerateFirst.
  ///
  /// In en, this message translates to:
  /// **'Generate a vCard first.'**
  String get profileShareGenerateFirst;

  /// No description provided for @profileShareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'vCard copied.'**
  String get profileShareLinkCopied;

  /// No description provided for @profileShareSecureLink.
  ///
  /// In en, this message translates to:
  /// **'vCard'**
  String get profileShareSecureLink;

  /// No description provided for @profileShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get profileShareAction;

  /// No description provided for @profileShareOptInTitle.
  ///
  /// In en, this message translates to:
  /// **'Share is opt-in'**
  String get profileShareOptInTitle;

  /// No description provided for @profileShareOptInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only selected profile fields are included. No credentials, documents, collections, or vault data are shared.'**
  String get profileShareOptInSubtitle;

  /// No description provided for @profileShareEmptyAttributeValue.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileShareEmptyAttributeValue;

  /// No description provided for @profilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profilePhoneNumber;

  /// No description provided for @profileHomeAddress.
  ///
  /// In en, this message translates to:
  /// **'Home Address'**
  String get profileHomeAddress;

  /// No description provided for @profileSocialLinks.
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get profileSocialLinks;

  /// No description provided for @profileShareExpirationLabel.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1{1 hour} other{{hours} hours}}'**
  String profileShareExpirationLabel(int hours);

  /// No description provided for @profileShareLinkExpiration.
  ///
  /// In en, this message translates to:
  /// **'vCard Validity'**
  String get profileShareLinkExpiration;

  /// No description provided for @securitySectionBiometrics.
  ///
  /// In en, this message translates to:
  /// **'BIOMETRICS'**
  String get securitySectionBiometrics;

  /// No description provided for @securitySectionVaultSecurity.
  ///
  /// In en, this message translates to:
  /// **'VAULT SECURITY'**
  String get securitySectionVaultSecurity;

  /// No description provided for @securitySectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get securitySectionPrivacy;

  /// No description provided for @securitySectionSync.
  ///
  /// In en, this message translates to:
  /// **'SYNC'**
  String get securitySectionSync;

  /// No description provided for @securitySectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'ADVANCED'**
  String get securitySectionAdvanced;

  /// No description provided for @securityUseFaceId.
  ///
  /// In en, this message translates to:
  /// **'Use FaceID'**
  String get securityUseFaceId;

  /// No description provided for @securityUseFaceIdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock your vault instantly'**
  String get securityUseFaceIdSubtitle;

  /// No description provided for @securityAutoLockTimer.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock timer'**
  String get securityAutoLockTimer;

  /// No description provided for @securityScreenshotProtection.
  ///
  /// In en, this message translates to:
  /// **'Screenshot protection'**
  String get securityScreenshotProtection;

  /// No description provided for @securityScreenshotProtectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Block capture in app'**
  String get securityScreenshotProtectionSubtitle;

  /// No description provided for @securityAutoBlurFields.
  ///
  /// In en, this message translates to:
  /// **'Auto-blur fields'**
  String get securityAutoBlurFields;

  /// No description provided for @securityClearClipboard.
  ///
  /// In en, this message translates to:
  /// **'Clear clipboard'**
  String get securityClearClipboard;

  /// No description provided for @securitySyncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get securitySyncStatus;

  /// No description provided for @securitySyncTarget.
  ///
  /// In en, this message translates to:
  /// **'Sync target'**
  String get securitySyncTarget;

  /// No description provided for @securityChangeMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Change Master Password'**
  String get securityChangeMasterPassword;

  /// No description provided for @securityChangeMasterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Update your sync passphrase in the encryption section.'**
  String get securityChangeMasterPasswordHint;

  /// No description provided for @securityExportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get securityExportData;

  /// No description provided for @securityExportHint.
  ///
  /// In en, this message translates to:
  /// **'Export is available from the portability flow.'**
  String get securityExportHint;

  /// No description provided for @securityVersionAndAudit.
  ///
  /// In en, this message translates to:
  /// **'Credence v1.0.0'**
  String get securityVersionAndAudit;

  /// No description provided for @settingsUseAppSupportFolder.
  ///
  /// In en, this message translates to:
  /// **'Use App Support Folder'**
  String get settingsUseAppSupportFolder;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minute'**
  String minutesLabel(int minutes);

  /// No description provided for @syncTargetDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get syncTargetDisabled;

  /// No description provided for @syncTargetLocalFolder.
  ///
  /// In en, this message translates to:
  /// **'Local Folder'**
  String get syncTargetLocalFolder;

  /// No description provided for @syncTargetDropboxCloud.
  ///
  /// In en, this message translates to:
  /// **'Dropbox Cloud'**
  String get syncTargetDropboxCloud;

  /// No description provided for @settingsNavVault.
  ///
  /// In en, this message translates to:
  /// **'VAULT'**
  String get settingsNavVault;

  /// No description provided for @settingsNavKeys.
  ///
  /// In en, this message translates to:
  /// **'KEYS'**
  String get settingsNavKeys;

  /// No description provided for @settingsNavSharing.
  ///
  /// In en, this message translates to:
  /// **'SHARING'**
  String get settingsNavSharing;

  /// No description provided for @settingsNavSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsNavSettings;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get commonCopied;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @documentArchived.
  ///
  /// In en, this message translates to:
  /// **'Document archived.'**
  String get documentArchived;

  /// No description provided for @documentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted.'**
  String get documentDeleted;

  /// No description provided for @documentForceExpire.
  ///
  /// In en, this message translates to:
  /// **'Force expiration'**
  String get documentForceExpire;

  /// No description provided for @documentForceExpireConfirm.
  ///
  /// In en, this message translates to:
  /// **'Force expire'**
  String get documentForceExpireConfirm;

  /// No description provided for @documentForceExpireDescription.
  ///
  /// In en, this message translates to:
  /// **'This will mark the document as expired by setting its expiry date to yesterday.'**
  String get documentForceExpireDescription;

  /// No description provided for @documentForceExpireTitle.
  ///
  /// In en, this message translates to:
  /// **'Force document expiration?'**
  String get documentForceExpireTitle;

  /// No description provided for @documentForcedExpired.
  ///
  /// In en, this message translates to:
  /// **'Document marked as expired.'**
  String get documentForcedExpired;

  /// No description provided for @documentFileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'File unavailable.'**
  String get documentFileUnavailable;

  /// No description provided for @documentFileUnavailableOnDevice.
  ///
  /// In en, this message translates to:
  /// **'File unavailable on this device.'**
  String get documentFileUnavailableOnDevice;

  /// No description provided for @documentFileUnavailableOrEmpty.
  ///
  /// In en, this message translates to:
  /// **'File unavailable or empty.'**
  String get documentFileUnavailableOrEmpty;

  /// No description provided for @documentPdfPreview.
  ///
  /// In en, this message translates to:
  /// **'PDF Preview'**
  String get documentPdfPreview;

  /// No description provided for @documentPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get documentPreview;

  /// No description provided for @documentPrimaryIdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mark this ID for quick access.'**
  String get documentPrimaryIdSubtitle;

  /// No description provided for @documentPrimaryIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Primary ID'**
  String get documentPrimaryIdTitle;

  /// No description provided for @documentPrimaryRemoved.
  ///
  /// In en, this message translates to:
  /// **'Primary ID removed.'**
  String get documentPrimaryRemoved;

  /// No description provided for @documentPrimarySet.
  ///
  /// In en, this message translates to:
  /// **'Primary ID set.'**
  String get documentPrimarySet;

  /// No description provided for @documentPrimaryUnableUpdate.
  ///
  /// In en, this message translates to:
  /// **'Unable to update primary ID.'**
  String get documentPrimaryUnableUpdate;

  /// No description provided for @documentRemoveArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive document'**
  String get documentRemoveArchive;

  /// No description provided for @documentRemoveArchiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide it from active items without deleting files.'**
  String get documentRemoveArchiveSubtitle;

  /// No description provided for @documentRemoveDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get documentRemoveDelete;

  /// No description provided for @documentRemoveDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove document and linked files from this device.'**
  String get documentRemoveDeleteSubtitle;

  /// No description provided for @documentRemoveDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose what to do with this document.'**
  String get documentRemoveDescription;

  /// No description provided for @documentRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {title}?'**
  String documentRemoveTitle(Object title);

  /// No description provided for @documentShareErrorFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found.'**
  String get documentShareErrorFileNotFound;

  /// No description provided for @documentShareErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied while sharing.'**
  String get documentShareErrorPermissionDenied;

  /// No description provided for @documentShareErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sharing is unavailable on this build.'**
  String get documentShareErrorUnavailable;

  /// No description provided for @documentSharingUnavailableBuild.
  ///
  /// In en, this message translates to:
  /// **'Sharing is unavailable on this build.'**
  String get documentSharingUnavailableBuild;

  /// No description provided for @documentStructuredInformation.
  ///
  /// In en, this message translates to:
  /// **'STRUCTURED INFORMATION'**
  String get documentStructuredInformation;

  /// No description provided for @documentUnableLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load document.'**
  String get documentUnableLoad;

  /// No description provided for @documentUnableForceExpire.
  ///
  /// In en, this message translates to:
  /// **'Unable to force document expiration right now.'**
  String get documentUnableForceExpire;

  /// No description provided for @documentUnableOpenPreview.
  ///
  /// In en, this message translates to:
  /// **'Unable to open preview.'**
  String get documentUnableOpenPreview;

  /// No description provided for @collectionUploadDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop file here'**
  String get collectionUploadDropHere;

  /// No description provided for @documentPreviewNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Preview is not available for this file type.\nYou can share it to open in another app.'**
  String get documentPreviewNotAvailable;

  /// No description provided for @documentUnableRemove.
  ///
  /// In en, this message translates to:
  /// **'Unable to remove document right now.'**
  String get documentUnableRemove;

  /// No description provided for @documentUnableRenderImagePreview.
  ///
  /// In en, this message translates to:
  /// **'Unable to render image preview.'**
  String get documentUnableRenderImagePreview;

  /// No description provided for @documentUnableShareFile.
  ///
  /// In en, this message translates to:
  /// **'Unable to share file right now.'**
  String get documentUnableShareFile;

  /// No description provided for @documentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Document updated.'**
  String get documentUpdated;

  /// No description provided for @idEntryBackSide.
  ///
  /// In en, this message translates to:
  /// **'Back Side'**
  String get idEntryBackSide;

  /// No description provided for @idEntryBackSideCapturedNotice.
  ///
  /// In en, this message translates to:
  /// **'Back side captured.'**
  String get idEntryBackSideCapturedNotice;

  /// No description provided for @idEntryCameraLibraryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera or library is unavailable on this device.'**
  String get idEntryCameraLibraryUnavailable;

  /// No description provided for @idEntryCameraMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Camera capture is available on mobile only.'**
  String get idEntryCameraMobileOnly;

  /// No description provided for @idEntryCaptureAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'{side} already added'**
  String idEntryCaptureAlreadyAdded(Object side);

  /// No description provided for @idEntryCaptureClearImageFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Capture a clear image using your camera.'**
  String get idEntryCaptureClearImageFromCamera;

  /// No description provided for @idEntryCapturePreviewOrReplaceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Would you like to preview it or replace it?'**
  String get idEntryCapturePreviewOrReplaceQuestion;

  /// No description provided for @idEntryChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get idEntryChooseFile;

  /// No description provided for @idEntryChooseImageSource.
  ///
  /// In en, this message translates to:
  /// **'Choose Image Source'**
  String get idEntryChooseImageSource;

  /// No description provided for @idEntryChooseImageSourceReplace.
  ///
  /// In en, this message translates to:
  /// **'Select a new source to replace this image.'**
  String get idEntryChooseImageSourceReplace;

  /// No description provided for @idEntryClearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear label'**
  String get idEntryClearLabel;

  /// No description provided for @idEntryCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get idEntryCountry;

  /// No description provided for @idEntryCountryExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. United States'**
  String get idEntryCountryExample;

  /// No description provided for @idEntryDateFormatShort.
  ///
  /// In en, this message translates to:
  /// **'MM/DD/YYYY'**
  String get idEntryDateFormatShort;

  /// No description provided for @idEntryDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get idEntryDateOfBirth;

  /// No description provided for @idEntryDesktopAutofillNotice.
  ///
  /// In en, this message translates to:
  /// **'Desktop supports upload only. OCR autofill runs on mobile.'**
  String get idEntryDesktopAutofillNotice;

  /// No description provided for @idEntryDetectedTypeVerifyFields.
  ///
  /// In en, this message translates to:
  /// **'Detected: {detectedType}. Please verify all fields.'**
  String idEntryDetectedTypeVerifyFields(Object detectedType);

  /// No description provided for @idEntryDetectedTypeWithConfidence.
  ///
  /// In en, this message translates to:
  /// **'Detected: {detectedType} ({confidence}%) from {side}.'**
  String idEntryDetectedTypeWithConfidence(
    Object confidence,
    Object detectedType,
    Object side,
  );

  /// No description provided for @idEntryDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get idEntryDocument;

  /// No description provided for @idEntryDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get idEntryDocumentType;

  /// No description provided for @idEntryDocumentTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select document type'**
  String get idEntryDocumentTypeHint;

  /// No description provided for @idEntryDropImageFileHint.
  ///
  /// In en, this message translates to:
  /// **'Drop image files here.'**
  String get idEntryDropImageFileHint;

  /// No description provided for @idEntryDropSupportedFile.
  ///
  /// In en, this message translates to:
  /// **'Only image files and PDFs are supported.'**
  String get idEntryDropSupportedFile;

  /// No description provided for @idEntryEnterCountry.
  ///
  /// In en, this message translates to:
  /// **'Enter country...'**
  String get idEntryEnterCountry;

  /// No description provided for @idEntryEnterCountryName.
  ///
  /// In en, this message translates to:
  /// **'Enter country name'**
  String get idEntryEnterCountryName;

  /// No description provided for @idEntryEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name...'**
  String get idEntryEnterFullName;

  /// No description provided for @idEntryEnterPassportNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter passport number...'**
  String get idEntryEnterPassportNumber;

  /// No description provided for @idEntryExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get idEntryExpiryDate;

  /// No description provided for @idEntryFrontImagePreviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Uploaded front image is used for OCR and preview.'**
  String get idEntryFrontImagePreviewNotice;

  /// No description provided for @idEntryFrontSide.
  ///
  /// In en, this message translates to:
  /// **'Front Side'**
  String get idEntryFrontSide;

  /// No description provided for @idEntryFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get idEntryFullName;

  /// No description provided for @idEntryFullNameAsPassport.
  ///
  /// In en, this message translates to:
  /// **'Full Name (as in passport)'**
  String get idEntryFullNameAsPassport;

  /// No description provided for @idEntryHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get idEntryHelp;

  /// No description provided for @idEntryIdCard.
  ///
  /// In en, this message translates to:
  /// **'ID Card'**
  String get idEntryIdCard;

  /// No description provided for @idEntryImageUsedForOcrAndPreview.
  ///
  /// In en, this message translates to:
  /// **'This image will be used for OCR and preview.'**
  String get idEntryImageUsedForOcrAndPreview;

  /// No description provided for @idEntryIssuingCountry.
  ///
  /// In en, this message translates to:
  /// **'Issuing Country'**
  String get idEntryIssuingCountry;

  /// No description provided for @idEntryManualDocumentEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Document Entry'**
  String get idEntryManualDocumentEntry;

  /// No description provided for @idEntryNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get idEntryNationality;

  /// No description provided for @idEntryNoReadableTextDetected.
  ///
  /// In en, this message translates to:
  /// **'No readable text detected.'**
  String get idEntryNoReadableTextDetected;

  /// No description provided for @idEntryNoValidReferenceFileAdded.
  ///
  /// In en, this message translates to:
  /// **'No valid reference file added.'**
  String get idEntryNoValidReferenceFileAdded;

  /// No description provided for @idEntryOcrMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'OCR autofill is available on mobile only.'**
  String get idEntryOcrMobileOnly;

  /// No description provided for @idEntryOpenCurrentImageFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Open current image in full screen.'**
  String get idEntryOpenCurrentImageFullscreen;

  /// No description provided for @idEntryOtherDocument.
  ///
  /// In en, this message translates to:
  /// **'Other Document'**
  String get idEntryOtherDocument;

  /// No description provided for @idEntryPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get idEntryPassport;

  /// No description provided for @idEntryPassportNumber.
  ///
  /// In en, this message translates to:
  /// **'Passport Number'**
  String get idEntryPassportNumber;

  /// No description provided for @idEntryPhotoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get idEntryPhotoLibrary;

  /// No description provided for @idEntryPhotoLibraryMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Photo library is available on mobile only.'**
  String get idEntryPhotoLibraryMobileOnly;

  /// No description provided for @idEntryPickImageOrPdf.
  ///
  /// In en, this message translates to:
  /// **'Pick an image or PDF.'**
  String get idEntryPickImageOrPdf;

  /// No description provided for @idEntryPreviewImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview image is unavailable.'**
  String get idEntryPreviewImageUnavailable;

  /// No description provided for @idEntryPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview • {title}'**
  String idEntryPreviewTitle(Object title);

  /// No description provided for @idEntryReferenceAttachmentAdded.
  ///
  /// In en, this message translates to:
  /// **'Reference attachment added.'**
  String get idEntryReferenceAttachmentAdded;

  /// No description provided for @idEntryReferenceAttachmentChooseSource.
  ///
  /// In en, this message translates to:
  /// **'Choose reference source'**
  String get idEntryReferenceAttachmentChooseSource;

  /// No description provided for @idEntryReferenceAttachmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference Attachment'**
  String get idEntryReferenceAttachmentTitle;

  /// No description provided for @idEntryReferenceAttachmentsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} reference attachments added.'**
  String idEntryReferenceAttachmentsAdded(Object count);

  /// No description provided for @idEntryReferenceLabelCleared.
  ///
  /// In en, this message translates to:
  /// **'Reference label cleared.'**
  String get idEntryReferenceLabelCleared;

  /// No description provided for @idEntryReferenceLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Optional label (e.g. Front, High quality)'**
  String get idEntryReferenceLabelHint;

  /// No description provided for @idEntryReferenceLabelSaved.
  ///
  /// In en, this message translates to:
  /// **'Reference label saved.'**
  String get idEntryReferenceLabelSaved;

  /// No description provided for @idEntryReferenceLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference label'**
  String get idEntryReferenceLabelTitle;

  /// No description provided for @idEntryReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get idEntryReplace;

  /// No description provided for @idEntryRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get idEntryRequired;

  /// No description provided for @idEntryResidencePermit.
  ///
  /// In en, this message translates to:
  /// **'Residence Permit'**
  String get idEntryResidencePermit;

  /// No description provided for @idEntrySelectClearImageFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select a clear image from gallery.'**
  String get idEntrySelectClearImageFromGallery;

  /// No description provided for @idEntrySelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get idEntrySelectDate;

  /// No description provided for @idEntrySelectHolderRelation.
  ///
  /// In en, this message translates to:
  /// **'Select holder relation'**
  String get idEntrySelectHolderRelation;

  /// No description provided for @idEntrySelectImageFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select image from gallery.'**
  String get idEntrySelectImageFromGallery;

  /// No description provided for @idEntrySelectedFilesAlreadyAttached.
  ///
  /// In en, this message translates to:
  /// **'Selected files are already attached.'**
  String get idEntrySelectedFilesAlreadyAttached;

  /// No description provided for @idEntryTakeReferencePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take reference photo'**
  String get idEntryTakeReferencePhoto;

  /// No description provided for @idEntryThisOptionMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'This option is available on mobile only.'**
  String get idEntryThisOptionMobileOnly;

  /// No description provided for @idEntryUnableAccessCameraLibrary.
  ///
  /// In en, this message translates to:
  /// **'Unable to access camera or library.'**
  String get idEntryUnableAccessCameraLibrary;

  /// No description provided for @idEntryUnableAccessSelectedPath.
  ///
  /// In en, this message translates to:
  /// **'Unable to access selected path.'**
  String get idEntryUnableAccessSelectedPath;

  /// No description provided for @idEntryUnableLoadPreviewImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to load preview image.'**
  String get idEntryUnableLoadPreviewImage;

  /// No description provided for @idEntryUnableProcessImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to process image right now.'**
  String get idEntryUnableProcessImage;

  /// No description provided for @idEntryUnableReadSelectedImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to read selected image.'**
  String get idEntryUnableReadSelectedImage;

  /// No description provided for @idEntryUnableSaveDocument.
  ///
  /// In en, this message translates to:
  /// **'Unable to save right now.'**
  String get idEntryUnableSaveDocument;

  /// No description provided for @idEntryUnableSaveSelectedImageLocally.
  ///
  /// In en, this message translates to:
  /// **'Unable to save selected image locally.'**
  String get idEntryUnableSaveSelectedImageLocally;

  /// No description provided for @idEntryUnableSelectReferenceAttachment.
  ///
  /// In en, this message translates to:
  /// **'Unable to select reference attachment right now.'**
  String get idEntryUnableSelectReferenceAttachment;

  /// No description provided for @idEntryUseCameraAutoCrop.
  ///
  /// In en, this message translates to:
  /// **'Use camera to capture a clear image.'**
  String get idEntryUseCameraAutoCrop;

  /// No description provided for @idEntryUseImageForOcr.
  ///
  /// In en, this message translates to:
  /// **'Image selected. OCR is processing.'**
  String get idEntryUseImageForOcr;

  /// No description provided for @identityRelationDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get identityRelationDaughter;

  /// No description provided for @identityRelationFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get identityRelationFamily;

  /// No description provided for @identityRelationHusband.
  ///
  /// In en, this message translates to:
  /// **'Husband'**
  String get identityRelationHusband;

  /// No description provided for @identityRelationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get identityRelationOther;

  /// No description provided for @identityRelationOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get identityRelationOwner;

  /// No description provided for @identityRelationParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get identityRelationParent;

  /// No description provided for @identityRelationSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get identityRelationSon;

  /// No description provided for @identityRelationWife.
  ///
  /// In en, this message translates to:
  /// **'Wife'**
  String get identityRelationWife;

  /// No description provided for @passportAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Passport'**
  String get passportAddTitle;

  /// No description provided for @passportAiVerified.
  ///
  /// In en, this message translates to:
  /// **'AI Verified'**
  String get passportAiVerified;

  /// No description provided for @passportDesktopUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload an image on desktop; OCR autofill runs on mobile.'**
  String get passportDesktopUploadHint;

  /// No description provided for @passportDetailsExtracted.
  ///
  /// In en, this message translates to:
  /// **'Passport details extracted.'**
  String get passportDetailsExtracted;

  /// No description provided for @passportDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Passport Details'**
  String get passportDetailsTitle;

  /// No description provided for @passportDetectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Scan confidence: {confidence}%'**
  String passportDetectedStatus(Object confidence);

  /// No description provided for @passportDetectedTypeStatus.
  ///
  /// In en, this message translates to:
  /// **'Detected {detectedType} • confidence {confidence}%'**
  String passportDetectedTypeStatus(Object confidence, Object detectedType);

  /// No description provided for @passportDetectedTypeVerify.
  ///
  /// In en, this message translates to:
  /// **'Detected {detectedType}. Please verify passport fields.'**
  String passportDetectedTypeVerify(Object detectedType);

  /// No description provided for @passportEncryptedStorage.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted storage'**
  String get passportEncryptedStorage;

  /// No description provided for @passportExtractionFailed.
  ///
  /// In en, this message translates to:
  /// **'Extraction Failed'**
  String get passportExtractionFailed;

  /// No description provided for @passportExtractionFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'We could not automatically scan your document. Enter details manually below.'**
  String get passportExtractionFailedDescription;

  /// No description provided for @passportRetryScan.
  ///
  /// In en, this message translates to:
  /// **'Retry Scan'**
  String get passportRetryScan;

  /// No description provided for @passportReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Passport'**
  String get passportReviewTitle;

  /// No description provided for @passportSaveToSecureVault.
  ///
  /// In en, this message translates to:
  /// **'Save to Secure Vault'**
  String get passportSaveToSecureVault;

  /// No description provided for @passportSaveToVault.
  ///
  /// In en, this message translates to:
  /// **'Save to Vault'**
  String get passportSaveToVault;

  /// No description provided for @passportScanStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Scan cancelled.'**
  String get passportScanStatusCancelled;

  /// No description provided for @passportScanStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed.'**
  String get passportScanStatusFailed;

  /// No description provided for @passportScanStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'No scan yet.'**
  String get passportScanStatusIdle;

  /// No description provided for @passportScanStatusNoText.
  ///
  /// In en, this message translates to:
  /// **'No text detected.'**
  String get passportScanStatusNoText;

  /// No description provided for @passportScanStatusScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get passportScanStatusScanning;

  /// No description provided for @passportScannerMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Scanner is available on mobile only.'**
  String get passportScannerMobileOnly;

  /// No description provided for @passportScannerUnavailableDevice.
  ///
  /// In en, this message translates to:
  /// **'Scanner is unavailable on this device.'**
  String get passportScannerUnavailableDevice;

  /// No description provided for @passportSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get passportSelectFile;

  /// No description provided for @passportTapToEnlarge.
  ///
  /// In en, this message translates to:
  /// **'TAP TO ENLARGE'**
  String get passportTapToEnlarge;

  /// No description provided for @passportUnableSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save passport right now.'**
  String get passportUnableSave;

  /// No description provided for @passportUnableScan.
  ///
  /// In en, this message translates to:
  /// **'Unable to scan right now.'**
  String get passportUnableScan;

  /// No description provided for @passportUploadDocumentImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Document Image'**
  String get passportUploadDocumentImage;

  /// No description provided for @settingsConfigureTargetSection.
  ///
  /// In en, this message translates to:
  /// **'CONFIGURE TARGET'**
  String get settingsConfigureTargetSection;

  /// No description provided for @settingsEncryptionSection.
  ///
  /// In en, this message translates to:
  /// **'ENCRYPTION'**
  String get settingsEncryptionSection;

  /// No description provided for @settingsResetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get settingsResetToDefaults;

  /// No description provided for @settingsSyncTargetSection.
  ///
  /// In en, this message translates to:
  /// **'SYNC TARGET'**
  String get settingsSyncTargetSection;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @documentDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date added: {dateText}'**
  String documentDateAdded(Object dateText);

  /// No description provided for @idEntryTapChooseOrDrag.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose or drag a file.'**
  String get idEntryTapChooseOrDrag;

  /// No description provided for @idEntryTapCaptureOrUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture or upload.'**
  String get idEntryTapCaptureOrUpload;

  /// No description provided for @idEntryUploadFrontSide.
  ///
  /// In en, this message translates to:
  /// **'Upload Front Side'**
  String get idEntryUploadFrontSide;

  /// No description provided for @idEntryUploadBackSide.
  ///
  /// In en, this message translates to:
  /// **'Upload Back Side'**
  String get idEntryUploadBackSide;

  /// No description provided for @idEntryCaptureSideCaptured.
  ///
  /// In en, this message translates to:
  /// **'{side} captured'**
  String idEntryCaptureSideCaptured(Object side);

  /// No description provided for @idEntryDropImageHere.
  ///
  /// In en, this message translates to:
  /// **'Drop image here'**
  String get idEntryDropImageHere;

  /// No description provided for @idEntryPreviewImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview Image'**
  String get idEntryPreviewImageTitle;

  /// No description provided for @idEntryPreviewImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Uploaded images are used for OCR. You can also use the front image as preview in details.'**
  String get idEntryPreviewImageDescription;

  /// No description provided for @idEntryUseFrontImageInDetails.
  ///
  /// In en, this message translates to:
  /// **'Use uploaded front image in details'**
  String get idEntryUseFrontImageInDetails;

  /// No description provided for @idEntryPreviewUsesFrontImage.
  ///
  /// In en, this message translates to:
  /// **'Preview will use the uploaded front image.'**
  String get idEntryPreviewUsesFrontImage;

  /// No description provided for @idEntryPreviewDisabledNotice.
  ///
  /// In en, this message translates to:
  /// **'Preview is disabled.'**
  String get idEntryPreviewDisabledNotice;

  /// No description provided for @idEntryUploadFrontFirst.
  ///
  /// In en, this message translates to:
  /// **'Upload front side first to enable preview image.'**
  String get idEntryUploadFrontFirst;

  /// No description provided for @idEntryReferenceAttachmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference Attachments'**
  String get idEntryReferenceAttachmentsTitle;

  /// No description provided for @idEntryDropFilesNow.
  ///
  /// In en, this message translates to:
  /// **'Drop files now'**
  String get idEntryDropFilesNow;

  /// No description provided for @idEntryReferenceAttachmentDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional: add high-quality reference image(s) or PDF for future verification.'**
  String get idEntryReferenceAttachmentDescription;

  /// No description provided for @idEntryReferenceFilesAttached.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) attached'**
  String idEntryReferenceFilesAttached(Object count);

  /// No description provided for @idEntryAddReferenceImagePdf.
  ///
  /// In en, this message translates to:
  /// **'Add reference image/PDF'**
  String get idEntryAddReferenceImagePdf;

  /// No description provided for @idEntryEditLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get idEntryEditLabel;

  /// No description provided for @idEntryAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Add label'**
  String get idEntryAddLabel;

  /// No description provided for @idEntryMultipleFilesHint.
  ///
  /// In en, this message translates to:
  /// **'You can attach multiple files.'**
  String get idEntryMultipleFilesHint;

  /// No description provided for @idEntryClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get idEntryClearAll;

  /// No description provided for @idEntryDateFormatHint.
  ///
  /// In en, this message translates to:
  /// **'MM/DD/YYYY'**
  String get idEntryDateFormatHint;

  /// No description provided for @idEntrySelectExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Select expiry date'**
  String get idEntrySelectExpiryDate;

  /// No description provided for @idEntryDocumentHolder.
  ///
  /// In en, this message translates to:
  /// **'Document Holder'**
  String get idEntryDocumentHolder;

  /// No description provided for @idEntryAsShownOnDocument.
  ///
  /// In en, this message translates to:
  /// **'As shown on document'**
  String get idEntryAsShownOnDocument;

  /// No description provided for @idEntryNameFromDocument.
  ///
  /// In en, this message translates to:
  /// **'Name from document'**
  String get idEntryNameFromDocument;

  /// No description provided for @idEntryIssuingAuthority.
  ///
  /// In en, this message translates to:
  /// **'Issuing Authority'**
  String get idEntryIssuingAuthority;

  /// No description provided for @idEntryAuthorityDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department / Authority'**
  String get idEntryAuthorityDepartment;

  /// No description provided for @idEntryOptionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional notes'**
  String get idEntryOptionalNotes;

  /// No description provided for @idEntryIdDocuments.
  ///
  /// In en, this message translates to:
  /// **'ID Documents'**
  String get idEntryIdDocuments;

  /// No description provided for @idEntryDriversLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get idEntryDriversLicense;

  /// No description provided for @idEntryDocumentImages.
  ///
  /// In en, this message translates to:
  /// **'Document Images'**
  String get idEntryDocumentImages;

  /// No description provided for @idEntryPassportUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload your passport image.'**
  String get idEntryPassportUploadSubtitle;

  /// No description provided for @idEntryIdentityUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload front and back of your ID.'**
  String get idEntryIdentityUploadSubtitle;

  /// No description provided for @idEntryResidencePermitUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload front and back of your residence permit.'**
  String get idEntryResidencePermitUploadSubtitle;

  /// No description provided for @idEntryDriversLicenseUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload front and back of your driver\'s license.'**
  String get idEntryDriversLicenseUploadSubtitle;

  /// No description provided for @idEntryDocumentUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload document image(s).'**
  String get idEntryDocumentUploadSubtitle;

  /// No description provided for @idEntryPassportInformation.
  ///
  /// In en, this message translates to:
  /// **'Passport Information'**
  String get idEntryPassportInformation;

  /// No description provided for @idEntryIdInformation.
  ///
  /// In en, this message translates to:
  /// **'ID Information'**
  String get idEntryIdInformation;

  /// No description provided for @idEntryResidencePermitInformation.
  ///
  /// In en, this message translates to:
  /// **'Residence Permit Information'**
  String get idEntryResidencePermitInformation;

  /// No description provided for @idEntryDriversLicenseInformation.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License Information'**
  String get idEntryDriversLicenseInformation;

  /// No description provided for @idEntryDocumentInformation.
  ///
  /// In en, this message translates to:
  /// **'Document Information'**
  String get idEntryDocumentInformation;

  /// No description provided for @idEntryIdNumber.
  ///
  /// In en, this message translates to:
  /// **'ID Number'**
  String get idEntryIdNumber;

  /// No description provided for @idEntryPermitNumber.
  ///
  /// In en, this message translates to:
  /// **'Permit Number'**
  String get idEntryPermitNumber;

  /// No description provided for @idEntryLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get idEntryLicenseNumber;

  /// No description provided for @idEntryDocumentId.
  ///
  /// In en, this message translates to:
  /// **'Document ID'**
  String get idEntryDocumentId;

  /// No description provided for @idEntryEnterIdentificationNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter identification number'**
  String get idEntryEnterIdentificationNumber;

  /// No description provided for @idEntryEnterPermitNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter permit number'**
  String get idEntryEnterPermitNumber;

  /// No description provided for @idEntryReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get idEntryReference;

  /// No description provided for @settingsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsHeaderTitle;

  /// No description provided for @settingsHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your offline security and synchronization preferences.'**
  String get settingsHeaderSubtitle;

  /// No description provided for @settingsViewDocumentation.
  ///
  /// In en, this message translates to:
  /// **'View Documentation'**
  String get settingsViewDocumentation;

  /// No description provided for @settingsSyncStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'SYNC STATUS'**
  String get settingsSyncStatusLabel;

  /// No description provided for @settingsSyncTargetDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep data on this device only'**
  String get settingsSyncTargetDisabledSubtitle;

  /// No description provided for @settingsSyncTargetLocalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync to file system or NAS'**
  String get settingsSyncTargetLocalSubtitle;

  /// No description provided for @settingsSyncTargetDropboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure end-to-end cloud sync'**
  String get settingsSyncTargetDropboxSubtitle;

  /// No description provided for @settingsLocalStoragePath.
  ///
  /// In en, this message translates to:
  /// **'Local Storage Path'**
  String get settingsLocalStoragePath;

  /// No description provided for @settingsLocalStoragePathHint.
  ///
  /// In en, this message translates to:
  /// **'Choose local backup folder path'**
  String get settingsLocalStoragePathHint;

  /// No description provided for @settingsDropboxCredentials.
  ///
  /// In en, this message translates to:
  /// **'Dropbox Credentials'**
  String get settingsDropboxCredentials;

  /// No description provided for @settingsDropboxTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Dropbox access token'**
  String get settingsDropboxTokenHint;

  /// No description provided for @settingsDropboxDirectoryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Dropbox folder path'**
  String get settingsDropboxDirectoryHint;

  /// No description provided for @settingsSyncDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Sync target is disabled. Data stays local.'**
  String get settingsSyncDisabledHint;

  /// No description provided for @settingsEncryptionDescription.
  ///
  /// In en, this message translates to:
  /// **'All data is AES-256 encrypted before sync. Only your passphrase can unlock it.'**
  String get settingsEncryptionDescription;

  /// No description provided for @settingsSyncPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Sync Passphrase'**
  String get settingsSyncPassphrase;

  /// No description provided for @settingsSyncPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Enter sync passphrase'**
  String get settingsSyncPassphraseHint;

  /// No description provided for @settingsPendingChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Changes'**
  String get settingsPendingChangesTitle;

  /// No description provided for @settingsPendingChangesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes to your synchronization settings.'**
  String get settingsPendingChangesSubtitle;

  /// No description provided for @settingsSyncNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Sync Needs Attention'**
  String get settingsSyncNeedsAttention;

  /// No description provided for @settingsSyncEncryptedReady.
  ///
  /// In en, this message translates to:
  /// **'Encrypted & Ready'**
  String get settingsSyncEncryptedReady;

  /// No description provided for @settingsSyncReadyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready to Start'**
  String get settingsSyncReadyToStart;

  /// No description provided for @settingsSyncReadyToSync.
  ///
  /// In en, this message translates to:
  /// **'Ready to Sync'**
  String get settingsSyncReadyToSync;

  /// No description provided for @settingsLastSyncedNever.
  ///
  /// In en, this message translates to:
  /// **'Last synced: never'**
  String get settingsLastSyncedNever;

  /// No description provided for @settingsLastSyncedRelative.
  ///
  /// In en, this message translates to:
  /// **'Last synced {relative}'**
  String settingsLastSyncedRelative(Object relative);

  /// No description provided for @settingsRelativeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get settingsRelativeJustNow;

  /// No description provided for @settingsRelativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String settingsRelativeMinutesAgo(Object minutes);

  /// No description provided for @settingsRelativeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String settingsRelativeHoursAgo(Object hours);

  /// No description provided for @settingsRelativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String settingsRelativeDaysAgo(Object days);

  /// No description provided for @settingsSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get settingsSyncing;

  /// No description provided for @settingsSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get settingsSyncNow;

  /// No description provided for @settingsSaveAllSettings.
  ///
  /// In en, this message translates to:
  /// **'Save All Settings'**
  String get settingsSaveAllSettings;

  /// No description provided for @documentReferenceFiles.
  ///
  /// In en, this message translates to:
  /// **'REFERENCE FILES'**
  String get documentReferenceFiles;

  /// No description provided for @documentFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String documentFilesCount(Object count);

  /// No description provided for @documentPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable'**
  String get documentPreviewUnavailable;

  /// No description provided for @documentsUnableLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load documents.'**
  String get documentsUnableLoad;

  /// No description provided for @documentsCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get documentsCategoriesTitle;

  /// No description provided for @documentsSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get documentsSelectCategory;

  /// No description provided for @documentsRecentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get documentsRecentActivityTitle;

  /// No description provided for @documentsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get documentsSeeAll;

  /// No description provided for @documentsLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents Library'**
  String get documentsLibraryTitle;

  /// No description provided for @documentsLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your secure files offline.'**
  String get documentsLibrarySubtitle;

  /// No description provided for @documentsHeaderCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{No documents} =1{1 document} other{{count} documents}}'**
  String documentsHeaderCount(int count);

  /// No description provided for @documentsFilesCompact.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{No files} =1{1 file} other{{count} files}}'**
  String documentsFilesCompact(int count);

  /// No description provided for @documentsAttentionCompact.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 needs attention} other{{count} need attention}}'**
  String documentsAttentionCompact(int count);

  /// No description provided for @documentsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search documents, files, notes'**
  String get documentsSearchHint;

  /// No description provided for @documentsRecentFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get documentsRecentFilesTitle;

  /// No description provided for @documentsCollectionsEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dynamic folders, notes, docs, expenses'**
  String get documentsCollectionsEntrySubtitle;

  /// No description provided for @documentsBundlesEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share packs, applications, exports'**
  String get documentsBundlesEntrySubtitle;

  /// No description provided for @documentsTasksEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checklists and reminders'**
  String get documentsTasksEntrySubtitle;

  /// No description provided for @documentsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Documents'**
  String documentsCountLabel(Object count);

  /// No description provided for @documentsFilesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Files'**
  String documentsFilesCountLabel(int count);

  /// No description provided for @documentsUpdatedWithCategory.
  ///
  /// In en, this message translates to:
  /// **'Updated {relative} • {category}'**
  String documentsUpdatedWithCategory(Object category, Object relative);

  /// No description provided for @documentsNoRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet.'**
  String get documentsNoRecentActivity;

  /// No description provided for @documentsRelativeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get documentsRelativeJustNow;

  /// No description provided for @documentsRelativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get documentsRelativeYesterday;

  /// No description provided for @documentsCategoryIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get documentsCategoryIdentity;

  /// No description provided for @documentsCategorySubtitleIdentity.
  ///
  /// In en, this message translates to:
  /// **'Passport, ID, Driver\'s License'**
  String get documentsCategorySubtitleIdentity;

  /// No description provided for @documentsCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get documentsCategoryWork;

  /// No description provided for @documentsCategorySubtitleWork.
  ///
  /// In en, this message translates to:
  /// **'Contracts, Payslips, Tax IDs'**
  String get documentsCategorySubtitleWork;

  /// No description provided for @documentsCategoryProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get documentsCategoryProperty;

  /// No description provided for @documentsCategorySubtitleProperty.
  ///
  /// In en, this message translates to:
  /// **'Deeds, Rental Agreements, Utility'**
  String get documentsCategorySubtitleProperty;

  /// No description provided for @documentsCategoryAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get documentsCategoryAuto;

  /// No description provided for @documentsCategorySubtitleAuto.
  ///
  /// In en, this message translates to:
  /// **'Registration, Insurance, Service'**
  String get documentsCategorySubtitleAuto;

  /// No description provided for @documentsCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get documentsCategoryHealth;

  /// No description provided for @documentsCategorySubtitleHealth.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions, Medical Records'**
  String get documentsCategorySubtitleHealth;

  /// No description provided for @documentsCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get documentsCategoryTravel;

  /// No description provided for @documentsCategorySubtitleTravel.
  ///
  /// In en, this message translates to:
  /// **'Trips, tickets, visas, itineraries'**
  String get documentsCategorySubtitleTravel;

  /// No description provided for @documentsCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get documentsCategoryOther;

  /// No description provided for @documentsCategorySubtitleOther.
  ///
  /// In en, this message translates to:
  /// **'Notes, invoices, and other files'**
  String get documentsCategorySubtitleOther;

  /// No description provided for @travelTripsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load trips.'**
  String get travelTripsLoadError;

  /// No description provided for @travelTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get travelTripsTitle;

  /// No description provided for @travelTripsFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get travelTripsFilterUpcoming;

  /// No description provided for @travelTripsFilterPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get travelTripsFilterPast;

  /// No description provided for @travelTripsStatusInDays.
  ///
  /// In en, this message translates to:
  /// **'IN {days} DAYS'**
  String travelTripsStatusInDays(int days);

  /// No description provided for @travelTripsStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'PLANNED'**
  String get travelTripsStatusPlanned;

  /// No description provided for @travelTripsDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'DATES'**
  String get travelTripsDatesLabel;

  /// No description provided for @travelTripsDocumentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Documents'**
  String travelTripsDocumentsCount(int count);

  /// No description provided for @travelTripsViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get travelTripsViewDetails;

  /// No description provided for @travelTripsStartNewTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new trip'**
  String get travelTripsStartNewTripTitle;

  /// No description provided for @travelTripsStartNewTripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'BROWSE DESTINATIONS'**
  String get travelTripsStartNewTripSubtitle;

  /// No description provided for @travelTripsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get travelTripsEmptyTitle;

  /// No description provided for @travelTripsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first trip and start planning your timeline, expenses, and travel wallet.'**
  String get travelTripsEmptySubtitle;

  /// No description provided for @travelTripsCreateFirstAction.
  ///
  /// In en, this message translates to:
  /// **'Create First Trip'**
  String get travelTripsCreateFirstAction;

  /// No description provided for @travelTripEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Trip'**
  String get travelTripEntryTitle;

  /// No description provided for @travelTripEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Trip'**
  String get travelTripEditTitle;

  /// No description provided for @travelTripDetailsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get travelTripDetailsSectionTitle;

  /// No description provided for @travelTripNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Notes'**
  String get travelTripNotesTitle;

  /// No description provided for @travelTripEntrySaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save Trip'**
  String get travelTripEntrySaveAction;

  /// No description provided for @travelTripEntryTitleField.
  ///
  /// In en, this message translates to:
  /// **'Trip Name'**
  String get travelTripEntryTitleField;

  /// No description provided for @travelTripEntryTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Summer in Tokyo'**
  String get travelTripEntryTitleHint;

  /// No description provided for @travelTripEntryDestinationField.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get travelTripEntryDestinationField;

  /// No description provided for @travelTripEntryDestinationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tokyo, Japan'**
  String get travelTripEntryDestinationHint;

  /// No description provided for @travelTripEntryStartDateField.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get travelTripEntryStartDateField;

  /// No description provided for @travelTripEntryEndDateField.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get travelTripEntryEndDateField;

  /// No description provided for @travelTripEntryCoverField.
  ///
  /// In en, this message translates to:
  /// **'Trip Cover Image'**
  String get travelTripEntryCoverField;

  /// No description provided for @travelTripEntryCoverHint.
  ///
  /// In en, this message translates to:
  /// **'Select optional cover image'**
  String get travelTripEntryCoverHint;

  /// No description provided for @travelTripDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load this trip.'**
  String get travelTripDetailLoadError;

  /// No description provided for @travelDashboardSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Dashboard'**
  String get travelDashboardSectionTitle;

  /// No description provided for @travelDashboardTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get travelDashboardTimelineTitle;

  /// No description provided for @travelDashboardTimelineCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String travelDashboardTimelineCount(int count);

  /// No description provided for @travelDashboardDestinationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Destinations'**
  String get travelDashboardDestinationsTitle;

  /// No description provided for @travelDashboardDestinationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} places'**
  String travelDashboardDestinationsCount(int count);

  /// No description provided for @travelDashboardDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get travelDashboardDocumentsTitle;

  /// No description provided for @travelDashboardDocumentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String travelDashboardDocumentsCount(int count);

  /// No description provided for @travelDashboardExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get travelDashboardExpensesTitle;

  /// No description provided for @travelDashboardExpensesSpent.
  ///
  /// In en, this message translates to:
  /// **'{value} spent'**
  String travelDashboardExpensesSpent(String value);

  /// No description provided for @travelDashboardWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Wallet'**
  String get travelDashboardWalletTitle;

  /// No description provided for @travelDashboardWalletSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} documents ready'**
  String travelDashboardWalletSummary(int count);

  /// No description provided for @travelDashboardDefaultDestination.
  ///
  /// In en, this message translates to:
  /// **'Your destination'**
  String get travelDashboardDefaultDestination;

  /// No description provided for @travelDashboardDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} Days Left'**
  String travelDashboardDaysLeft(int days);

  /// No description provided for @travelDashboardHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore {destination}'**
  String travelDashboardHeroTitle(String destination);

  /// No description provided for @travelTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'{trip} Trip Timeline'**
  String travelTimelineTitle(String trip);

  /// No description provided for @travelTimelineEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No timeline events yet'**
  String get travelTimelineEmptyTitle;

  /// No description provided for @travelTimelineEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first event to organize transport, stays, dining, and activities.'**
  String get travelTimelineEmptySubtitle;

  /// No description provided for @travelTimelineAddEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Timeline Event'**
  String get travelTimelineAddEventTitle;

  /// No description provided for @travelTimelineAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add to Timeline'**
  String get travelTimelineAddAction;

  /// No description provided for @travelTimelineCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travelTimelineCategoryTravel;

  /// No description provided for @travelTimelineCategoryStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get travelTimelineCategoryStay;

  /// No description provided for @travelTimelineCategoryDining.
  ///
  /// In en, this message translates to:
  /// **'Dining'**
  String get travelTimelineCategoryDining;

  /// No description provided for @travelTimelineCategoryActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get travelTimelineCategoryActivity;

  /// No description provided for @travelTimelineCategoryReservation.
  ///
  /// In en, this message translates to:
  /// **'Reservation'**
  String get travelTimelineCategoryReservation;

  /// No description provided for @travelTimelineConfirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get travelTimelineConfirmed;

  /// No description provided for @travelTimelineDocumentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Documents'**
  String travelTimelineDocumentsCount(int count);

  /// No description provided for @travelTimelineOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open Map'**
  String get travelTimelineOpenMap;

  /// No description provided for @travelExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Expenses'**
  String get travelExpensesTitle;

  /// No description provided for @travelExpensesTotalSpentTitle.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get travelExpensesTotalSpentTitle;

  /// No description provided for @travelExpensesRemainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get travelExpensesRemainingTitle;

  /// No description provided for @travelExpensesVsLastTrip.
  ///
  /// In en, this message translates to:
  /// **'~ +12% vs last trip'**
  String get travelExpensesVsLastTrip;

  /// No description provided for @travelExpensesBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget: {value}'**
  String travelExpensesBudgetLabel(String value);

  /// No description provided for @travelExpensesBudgetStatus.
  ///
  /// In en, this message translates to:
  /// **'BUDGET STATUS'**
  String get travelExpensesBudgetStatus;

  /// No description provided for @travelExpensesSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} spent'**
  String travelExpensesSpentLabel(String value);

  /// No description provided for @travelExpensesLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} limit'**
  String travelExpensesLimitLabel(String value);

  /// No description provided for @travelExpensesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get travelExpensesEmptyTitle;

  /// No description provided for @travelExpensesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add the first expense and track your trip budget in real time.'**
  String get travelExpensesEmptySubtitle;

  /// No description provided for @travelExpensesAddExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get travelExpensesAddExpenseTitle;

  /// No description provided for @travelExpensesAddExpenseAction.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get travelExpensesAddExpenseAction;

  /// No description provided for @travelExpensesCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get travelExpensesCategoryFood;

  /// No description provided for @travelExpensesCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get travelExpensesCategoryTransport;

  /// No description provided for @travelExpensesCategoryActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get travelExpensesCategoryActivities;

  /// No description provided for @travelExpensesCategoryAccommodation.
  ///
  /// In en, this message translates to:
  /// **'Lodging'**
  String get travelExpensesCategoryAccommodation;

  /// No description provided for @travelExpensesCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get travelExpensesCategoryShopping;

  /// No description provided for @travelExpensesCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get travelExpensesCategoryOther;

  /// No description provided for @travelBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Trip Budget'**
  String get travelBudgetTitle;

  /// No description provided for @travelBudgetSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save Budget'**
  String get travelBudgetSaveAction;

  /// No description provided for @travelBudgetAllocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated: {value}'**
  String travelBudgetAllocated(String value);

  /// No description provided for @travelBudgetRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {value}'**
  String travelBudgetRemaining(String value);

  /// No description provided for @travelBudgetBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Breakdown'**
  String get travelBudgetBreakdownTitle;

  /// No description provided for @travelWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Wallet'**
  String get travelWalletTitle;

  /// No description provided for @travelWalletSectionOther.
  ///
  /// In en, this message translates to:
  /// **'Other Documents'**
  String get travelWalletSectionOther;

  /// No description provided for @travelWalletEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No travel documents yet'**
  String get travelWalletEmptyTitle;

  /// No description provided for @travelWalletEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add tickets, visas, insurance and booking confirmations for quick access.'**
  String get travelWalletEmptySubtitle;

  /// No description provided for @travelWalletAddDocumentAction.
  ///
  /// In en, this message translates to:
  /// **'Add New Document'**
  String get travelWalletAddDocumentAction;

  /// No description provided for @travelWalletUploadNewDocumentOption.
  ///
  /// In en, this message translates to:
  /// **'Upload New Document'**
  String get travelWalletUploadNewDocumentOption;

  /// No description provided for @travelWalletChooseFromMyDocumentsOption.
  ///
  /// In en, this message translates to:
  /// **'Choose from My Documents'**
  String get travelWalletChooseFromMyDocumentsOption;

  /// No description provided for @travelWalletAddDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Travel Document'**
  String get travelWalletAddDocumentTitle;

  /// No description provided for @travelWalletSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save to Wallet'**
  String get travelWalletSaveAction;

  /// No description provided for @travelWalletSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get travelWalletSelectFile;

  /// No description provided for @travelWalletPickerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get travelWalletPickerEmptyTitle;

  /// No description provided for @travelWalletPickerEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a new document to your vault first.'**
  String get travelWalletPickerEmptySubtitle;

  /// No description provided for @travelWalletNoExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'No expiration date'**
  String get travelWalletNoExpirationDate;

  /// No description provided for @travelWalletDocumentLinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Document linked to this trip.'**
  String get travelWalletDocumentLinkedSuccess;

  /// No description provided for @propertyHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get propertyHubTitle;

  /// No description provided for @propertyHubFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get propertyHubFilterAll;

  /// No description provided for @propertyHubFilterOwned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get propertyHubFilterOwned;

  /// No description provided for @propertyHubFilterRented.
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get propertyHubFilterRented;

  /// No description provided for @propertyHubLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load properties.'**
  String get propertyHubLoadError;

  /// No description provided for @propertyHubEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No properties yet'**
  String get propertyHubEmptyTitle;

  /// No description provided for @propertyHubEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first property to start organizing your vault.'**
  String get propertyHubEmptySubtitle;

  /// No description provided for @propertyHubAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get propertyHubAddAction;

  /// No description provided for @propertyEntryAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Property'**
  String get propertyEntryAddTitle;

  /// No description provided for @propertyEntryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Property'**
  String get propertyEntryEditTitle;

  /// No description provided for @propertyEntryCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Property Details'**
  String get propertyEntryCardTitle;

  /// No description provided for @propertyEntryCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provide the basic identification for your new listing.'**
  String get propertyEntryCardSubtitle;

  /// No description provided for @propertyEntryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Property Name/Nickname'**
  String get propertyEntryNameLabel;

  /// No description provided for @propertyEntryNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Blue Lagoon Villa'**
  String get propertyEntryNameHint;

  /// No description provided for @propertyEntryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Property name is required'**
  String get propertyEntryNameRequired;

  /// No description provided for @propertyEntryAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get propertyEntryAddressLabel;

  /// No description provided for @propertyEntryAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter street, city, and zip'**
  String get propertyEntryAddressHint;

  /// No description provided for @propertyEntryAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Full address is required'**
  String get propertyEntryAddressRequired;

  /// No description provided for @propertyEntryAddressSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching addresses...'**
  String get propertyEntryAddressSearching;

  /// No description provided for @propertyEntryAddressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not detect a valid address.'**
  String get propertyEntryAddressNotFound;

  /// No description provided for @propertyEntryAutoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect Location'**
  String get propertyEntryAutoDetect;

  /// No description provided for @propertyEntryCategorizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Categorization'**
  String get propertyEntryCategorizationTitle;

  /// No description provided for @propertyEntryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get propertyEntryTypeLabel;

  /// No description provided for @propertyEntryOwnershipLabel.
  ///
  /// In en, this message translates to:
  /// **'Ownership Status'**
  String get propertyEntryOwnershipLabel;

  /// No description provided for @propertyEntryOwnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get propertyEntryOwnedLabel;

  /// No description provided for @propertyEntryRentedLabel.
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get propertyEntryRentedLabel;

  /// No description provided for @propertyEntryCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create Property Vault'**
  String get propertyEntryCreateAction;

  /// No description provided for @propertyEntrySaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save Property'**
  String get propertyEntrySaveAction;

  /// No description provided for @propertyEntrySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save property. Please try again.'**
  String get propertyEntrySaveFailed;

  /// No description provided for @propertyDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load property details.'**
  String get propertyDetailLoadError;

  /// No description provided for @propertyDetailAssetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Property Assets'**
  String get propertyDetailAssetsTitle;

  /// No description provided for @propertyDetailTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{type} Property'**
  String propertyDetailTypeSubtitle(String type);

  /// No description provided for @propertyDetailSubtitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Managed Property'**
  String get propertyDetailSubtitleFallback;

  /// No description provided for @propertyDetailAssetDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get propertyDetailAssetDocuments;

  /// No description provided for @propertyDetailAssetContracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get propertyDetailAssetContracts;

  /// No description provided for @propertyDetailAssetInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get propertyDetailAssetInsurance;

  /// No description provided for @propertyDetailAssetPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get propertyDetailAssetPayments;

  /// No description provided for @propertyDetailAssetMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get propertyDetailAssetMaintenance;

  /// No description provided for @propertyDetailAssetOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get propertyDetailAssetOthers;

  /// No description provided for @propertyDetailFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String propertyDetailFilesCount(int count);

  /// No description provided for @propertyDetailRecordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String propertyDetailRecordsCount(int count);

  /// No description provided for @propertyDetailActiveRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active requests'**
  String propertyDetailActiveRequestsCount(int count);

  /// No description provided for @propertyDetailLastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last activity: {activity} {relative}'**
  String propertyDetailLastActivity(String activity, String relative);

  /// No description provided for @propertyDocumentEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get propertyDocumentEntryTitle;

  /// No description provided for @propertyDocumentInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Document Information'**
  String get propertyDocumentInfoSection;

  /// No description provided for @propertyDocumentCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Document Category'**
  String get propertyDocumentCategoryLabel;

  /// No description provided for @propertyDocumentCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get propertyDocumentCategoryHint;

  /// No description provided for @propertyDocumentCategoryRentPayment.
  ///
  /// In en, this message translates to:
  /// **'Rent Payment'**
  String get propertyDocumentCategoryRentPayment;

  /// No description provided for @propertyDocumentTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Document Title'**
  String get propertyDocumentTitleLabel;

  /// No description provided for @propertyDocumentTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lease Agreement 2024'**
  String get propertyDocumentTitleHint;

  /// No description provided for @propertyDocumentIssueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get propertyDocumentIssueDateLabel;

  /// No description provided for @propertyDocumentFinancialSection.
  ///
  /// In en, this message translates to:
  /// **'Financial Details (Optional)'**
  String get propertyDocumentFinancialSection;

  /// No description provided for @propertyDocumentAmountPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get propertyDocumentAmountPaidLabel;

  /// No description provided for @propertyDocumentAmountPaidHint.
  ///
  /// In en, this message translates to:
  /// **'\$ 0.00'**
  String get propertyDocumentAmountPaidHint;

  /// No description provided for @propertyDocumentAmountPaidNumericHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get propertyDocumentAmountPaidNumericHint;

  /// No description provided for @propertyDocumentPaymentDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get propertyDocumentPaymentDateLabel;

  /// No description provided for @propertyDocumentSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get propertyDocumentSelectFile;

  /// No description provided for @propertyDocumentUploadHint.
  ///
  /// In en, this message translates to:
  /// **'PDF, JPG or PNG (Max 10MB)'**
  String get propertyDocumentUploadHint;

  /// No description provided for @propertyDocumentSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save to Vault'**
  String get propertyDocumentSaveAction;

  /// No description provided for @propertyDocumentCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Document category is required.'**
  String get propertyDocumentCategoryRequired;

  /// No description provided for @propertyDocumentUploadRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a PDF or image first.'**
  String get propertyDocumentUploadRequired;

  /// No description provided for @propertyDocumentTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Document title is required.'**
  String get propertyDocumentTitleRequired;

  /// No description provided for @propertyDocumentFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File must be 10MB or less.'**
  String get propertyDocumentFileTooLarge;

  /// No description provided for @propertyDocumentFileMissing.
  ///
  /// In en, this message translates to:
  /// **'File not found.'**
  String get propertyDocumentFileMissing;

  /// No description provided for @propertyDocumentSelectFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to select file right now.'**
  String get propertyDocumentSelectFileFailed;

  /// No description provided for @propertyDocumentPersistFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to persist selected file.'**
  String get propertyDocumentPersistFailed;

  /// No description provided for @propertyDocumentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save document. Please try again.'**
  String get propertyDocumentSaveFailed;

  /// No description provided for @propertyDocumentSharedCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'The selected category and issue date will apply to every file. You can set a title for each document below.'**
  String get propertyDocumentSharedCategoryHint;

  /// No description provided for @propertyDocumentSelectedDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected documents'**
  String get propertyDocumentSelectedDocumentsTitle;

  /// No description provided for @propertyDocumentSelectedDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Document {index}'**
  String propertyDocumentSelectedDocumentLabel(int index);

  /// No description provided for @commonLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get commonLanguageEnglish;

  /// No description provided for @identityUnableLoadSecureIds.
  ///
  /// In en, this message translates to:
  /// **'Unable to load secure IDs.'**
  String get identityUnableLoadSecureIds;

  /// No description provided for @identityYourDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Documents'**
  String get identityYourDocumentsTitle;

  /// No description provided for @identitySecureIdsStored.
  ///
  /// In en, this message translates to:
  /// **'{count} secure IDs stored'**
  String identitySecureIdsStored(Object count);

  /// No description provided for @identityAllIdentities.
  ///
  /// In en, this message translates to:
  /// **'All identities'**
  String get identityAllIdentities;

  /// No description provided for @documentsArchived.
  ///
  /// In en, this message translates to:
  /// **'Document archived.'**
  String get documentsArchived;

  /// No description provided for @documentsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted.'**
  String get documentsDeleted;

  /// No description provided for @documentsUnableRemove.
  ///
  /// In en, this message translates to:
  /// **'Unable to remove document.'**
  String get documentsUnableRemove;

  /// No description provided for @identityVaultIdentityFallback.
  ///
  /// In en, this message translates to:
  /// **'Vault Identity'**
  String get identityVaultIdentityFallback;

  /// No description provided for @identityIssuedBy.
  ///
  /// In en, this message translates to:
  /// **'Issued by {country}'**
  String identityIssuedBy(Object country);

  /// No description provided for @identityExpiryShort.
  ///
  /// In en, this message translates to:
  /// **'Exp. {date}'**
  String identityExpiryShort(Object date);

  /// No description provided for @identityAddedDate.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String identityAddedDate(Object date);

  /// No description provided for @identityNoIdsYet.
  ///
  /// In en, this message translates to:
  /// **'No IDs yet'**
  String get identityNoIdsYet;

  /// No description provided for @identityAddFirstDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first ID document to start building your secure identity vault.'**
  String get identityAddFirstDescription;

  /// No description provided for @identityAddFirstId.
  ///
  /// In en, this message translates to:
  /// **'Add First ID'**
  String get identityAddFirstId;

  /// No description provided for @identityStatusValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get identityStatusValid;

  /// No description provided for @identityStatusExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get identityStatusExpiringSoon;

  /// No description provided for @identityStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get identityStatusExpired;

  /// No description provided for @identityFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get identityFilterTooltip;

  /// No description provided for @identityFilterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter identity documents'**
  String get identityFilterSheetTitle;

  /// No description provided for @identityFilterSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which secure IDs appear in the list.'**
  String get identityFilterSheetSubtitle;

  /// No description provided for @identityIntroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Documents · Identity'**
  String get identityIntroEyebrow;

  /// No description provided for @identityHolderSingular.
  ///
  /// In en, this message translates to:
  /// **'holder'**
  String get identityHolderSingular;

  /// No description provided for @identityHolderPlural.
  ///
  /// In en, this message translates to:
  /// **'holders'**
  String get identityHolderPlural;

  /// No description provided for @identityNoPrimaryIdentity.
  ///
  /// In en, this message translates to:
  /// **'No primary identity set yet.'**
  String get identityNoPrimaryIdentity;

  /// No description provided for @identityPrimaryIdentitySet.
  ///
  /// In en, this message translates to:
  /// **'{document} set as primary.'**
  String identityPrimaryIdentitySet(String document);

  /// No description provided for @identitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by number, country, owner...'**
  String get identitySearchHint;

  /// No description provided for @identityAllHolders.
  ///
  /// In en, this message translates to:
  /// **'All holders'**
  String get identityAllHolders;

  /// No description provided for @identityPrimaryBadge.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get identityPrimaryBadge;

  /// No description provided for @identityNoDocumentsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No {filter} documents'**
  String identityNoDocumentsForFilter(String filter);

  /// No description provided for @identityFilteredEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Try another view or add a new ID to this section.'**
  String get identityFilteredEmptyDescription;

  /// No description provided for @identityClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get identityClearSearch;

  /// No description provided for @identityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get identityFilterAll;

  /// No description provided for @identityFilterPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get identityFilterPersonal;

  /// No description provided for @identityFilterTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get identityFilterTravel;

  /// No description provided for @identityStatusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get identityStatusOk;

  /// No description provided for @identityStatusDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String identityStatusDaysLeft(int days);

  /// No description provided for @identityDocumentNumberPrefix.
  ///
  /// In en, this message translates to:
  /// **'No. {number}'**
  String identityDocumentNumberPrefix(String number);

  /// No description provided for @identityDetailFileMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'File missing'**
  String get identityDetailFileMissingTitle;

  /// No description provided for @identityDetailFileMissingDescription.
  ///
  /// In en, this message translates to:
  /// **'The metadata is saved, but the scan file is not available on this device.'**
  String get identityDetailFileMissingDescription;

  /// No description provided for @identityDetailPagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String identityDetailPagesCount(int count);

  /// No description provided for @identityDetailSectionDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get identityDetailSectionDocument;

  /// No description provided for @identityDetailSectionHolder.
  ///
  /// In en, this message translates to:
  /// **'Holder'**
  String get identityDetailSectionHolder;

  /// No description provided for @identityDetailSectionOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'Other details'**
  String get identityDetailSectionOtherDetails;

  /// No description provided for @identityDetailStatusExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get identityDetailStatusExpiring;

  /// No description provided for @identityDetailStatusExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires {days} d'**
  String identityDetailStatusExpiresIn(int days);

  /// No description provided for @identityFieldDocumentNumber.
  ///
  /// In en, this message translates to:
  /// **'Document number'**
  String get identityFieldDocumentNumber;

  /// No description provided for @identityFieldIssuingCountry.
  ///
  /// In en, this message translates to:
  /// **'Issuing country'**
  String get identityFieldIssuingCountry;

  /// No description provided for @identityFieldExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get identityFieldExpires;

  /// No description provided for @identityFieldNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get identityFieldNationality;

  /// No description provided for @identityFieldGivenName.
  ///
  /// In en, this message translates to:
  /// **'Given name'**
  String get identityFieldGivenName;

  /// No description provided for @identityFieldFamilyName.
  ///
  /// In en, this message translates to:
  /// **'Family name'**
  String get identityFieldFamilyName;

  /// No description provided for @identityFieldDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get identityFieldDateOfBirth;

  /// No description provided for @identityFieldSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get identityFieldSex;

  /// No description provided for @identityFieldHolder.
  ///
  /// In en, this message translates to:
  /// **'Holder'**
  String get identityFieldHolder;

  /// No description provided for @identityFieldAgeOver18.
  ///
  /// In en, this message translates to:
  /// **'Age over 18'**
  String get identityFieldAgeOver18;

  /// No description provided for @idEntryAttachmentSection.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get idEntryAttachmentSection;

  /// No description provided for @idEntryAddIdentityDocumentEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Add identity document'**
  String get idEntryAddIdentityDocumentEyebrow;

  /// No description provided for @idEntryEditIdentityDocumentEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Edit identity document'**
  String get idEntryEditIdentityDocumentEyebrow;

  /// No description provided for @commonManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get commonManage;

  /// No description provided for @workHubLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load work vaults.'**
  String get workHubLoadError;

  /// No description provided for @workHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Hub'**
  String get workHubTitle;

  /// No description provided for @workHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure document vault'**
  String get workHubSubtitle;

  /// No description provided for @workHubSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search companies or contracts'**
  String get workHubSearchHint;

  /// No description provided for @workHubFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Companies'**
  String get workHubFilterAll;

  /// No description provided for @workHubFilterRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get workHubFilterRecent;

  /// No description provided for @workHubFilterPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get workHubFilterPinned;

  /// No description provided for @workHubVaultSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Secure Vaults'**
  String get workHubVaultSectionTitle;

  /// No description provided for @workHubCompaniesCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} Companies'**
  String workHubCompaniesCountBadge(int count);

  /// No description provided for @workHubFeaturedLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW FEATURE'**
  String get workHubFeaturedLabel;

  /// No description provided for @workHubFeaturedTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Payslips'**
  String get workHubFeaturedTitle;

  /// No description provided for @workHubFeaturedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Securely access and manage your entire earnings history across all associated companies.'**
  String get workHubFeaturedSubtitle;

  /// No description provided for @workHubFeaturedSubtitleCompact.
  ///
  /// In en, this message translates to:
  /// **'Access your complete history'**
  String get workHubFeaturedSubtitleCompact;

  /// No description provided for @workHubFeaturedAction.
  ///
  /// In en, this message translates to:
  /// **'See All Payslips'**
  String get workHubFeaturedAction;

  /// No description provided for @workHubDocumentsCountCompact.
  ///
  /// In en, this message translates to:
  /// **'{count} documents'**
  String workHubDocumentsCountCompact(int count);

  /// No description provided for @workHubUpdatedCompact.
  ///
  /// In en, this message translates to:
  /// **'Updated {relative}'**
  String workHubUpdatedCompact(String relative);

  /// No description provided for @workHubCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} Documents • Last updated {relative}'**
  String workHubCompanySubtitle(int count, String relative);

  /// No description provided for @workHubEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No work vaults yet'**
  String get workHubEmptyTitle;

  /// No description provided for @workHubEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first company record to start organizing work contracts, payslips, and tax forms.'**
  String get workHubEmptySubtitle;

  /// No description provided for @workHubAddFirstCompanyAction.
  ///
  /// In en, this message translates to:
  /// **'Add First Company'**
  String get workHubAddFirstCompanyAction;

  /// No description provided for @workHubNoAccessYet.
  ///
  /// In en, this message translates to:
  /// **'No access yet'**
  String get workHubNoAccessYet;

  /// No description provided for @workCompanyTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Work Company'**
  String get workCompanyTitleFallback;

  /// No description provided for @workCompanyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load company details.'**
  String get workCompanyLoadError;

  /// No description provided for @workCompanyVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Vault'**
  String get workCompanyVaultTitle;

  /// No description provided for @workCompanyVaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Secure access to your professional documents'**
  String get workCompanyVaultSubtitle;

  /// No description provided for @workCompanyStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'STORAGE USED'**
  String get workCompanyStorageUsed;

  /// No description provided for @workCompanyLastAccess.
  ///
  /// In en, this message translates to:
  /// **'LAST ACCESS'**
  String get workCompanyLastAccess;

  /// No description provided for @workCompanyFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Folders'**
  String get workCompanyFoldersTitle;

  /// No description provided for @workCompanyFolderPayslipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payslips'**
  String get workCompanyFolderPayslipsTitle;

  /// No description provided for @workCompanyFolderContractsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get workCompanyFolderContractsTitle;

  /// No description provided for @workCompanyFolderTaxFormsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax Forms'**
  String get workCompanyFolderTaxFormsTitle;

  /// No description provided for @workCompanyFolderOffboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Offboarding'**
  String get workCompanyFolderOffboardingTitle;

  /// No description provided for @workCompanyFolderBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get workCompanyFolderBenefitsTitle;

  /// No description provided for @workCompanyFolderMilestonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get workCompanyFolderMilestonesTitle;

  /// No description provided for @workCompanyFolderOtherTitle.
  ///
  /// In en, this message translates to:
  /// **'Other Types'**
  String get workCompanyFolderOtherTitle;

  /// No description provided for @workCompanyFolderPayslipsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly earning statements'**
  String get workCompanyFolderPayslipsSubtitle;

  /// No description provided for @workCompanyFolderContractsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Employment and IP agreements'**
  String get workCompanyFolderContractsSubtitle;

  /// No description provided for @workCompanyFolderTaxFormsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Year-end summaries and tax forms'**
  String get workCompanyFolderTaxFormsSubtitle;

  /// No description provided for @workCompanyFolderOffboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exit documents and procedures'**
  String get workCompanyFolderOffboardingSubtitle;

  /// No description provided for @workCompanyFolderBenefitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Insurance and benefit coverage'**
  String get workCompanyFolderBenefitsSubtitle;

  /// No description provided for @workCompanyFolderMilestonesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Promotions and performance records'**
  String get workCompanyFolderMilestonesSubtitle;

  /// No description provided for @workCompanyFolderOtherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Additional professional documents'**
  String get workCompanyFolderOtherSubtitle;

  /// No description provided for @workCompanyRecentDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'RECENT DOCUMENTS'**
  String get workCompanyRecentDocumentsTitle;

  /// No description provided for @workCompanyRecentModified.
  ///
  /// In en, this message translates to:
  /// **'Modified {relative}'**
  String workCompanyRecentModified(String relative);

  /// No description provided for @workCompanyRecentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent documents'**
  String get workCompanyRecentEmptyTitle;

  /// No description provided for @workCompanyRecentEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Documents added to this company vault will appear here.'**
  String get workCompanyRecentEmptySubtitle;

  /// No description provided for @workEntryAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Work Record'**
  String get workEntryAddTitle;

  /// No description provided for @workEntryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Work Record'**
  String get workEntryEditTitle;

  /// No description provided for @workEntrySectionCompany.
  ///
  /// In en, this message translates to:
  /// **'COMPANY DETAILS'**
  String get workEntrySectionCompany;

  /// No description provided for @workEntryCompanyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get workEntryCompanyNameLabel;

  /// No description provided for @workEntryCompanyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Stripe Inc.'**
  String get workEntryCompanyNameHint;

  /// No description provided for @workEntryFolderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Folder Type'**
  String get workEntryFolderTypeLabel;

  /// No description provided for @workEntryRecordTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Record Title'**
  String get workEntryRecordTitleLabel;

  /// No description provided for @workEntryRecordTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. December Earnings'**
  String get workEntryRecordTitleHint;

  /// No description provided for @workEntryEmployeeIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get workEntryEmployeeIdLabel;

  /// No description provided for @workEntryEmployeeIdHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 882910'**
  String get workEntryEmployeeIdHint;

  /// No description provided for @workEntryRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get workEntryRoleLabel;

  /// No description provided for @workEntryRoleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sr. Engineer'**
  String get workEntryRoleHint;

  /// No description provided for @workEntryLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get workEntryLocationLabel;

  /// No description provided for @workEntryLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. San Francisco'**
  String get workEntryLocationHint;

  /// No description provided for @workEntryNetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Amount'**
  String get workEntryNetAmountLabel;

  /// No description provided for @workEntryNetAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \$4,250.00'**
  String get workEntryNetAmountHint;

  /// No description provided for @workEntryStatementDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Statement Date'**
  String get workEntryStatementDateLabel;

  /// No description provided for @workEntryStatementDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get workEntryStatementDateHint;

  /// No description provided for @workEntryNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get workEntryNotesLabel;

  /// No description provided for @workEntryNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional notes...'**
  String get workEntryNotesHint;

  /// No description provided for @workEntryPinCompany.
  ///
  /// In en, this message translates to:
  /// **'Pin this company'**
  String get workEntryPinCompany;

  /// No description provided for @workEntryPinCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'Pinned companies appear in quick filters.'**
  String get workEntryPinCompanyHint;

  /// No description provided for @workStatementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payroll Vault'**
  String get workStatementsSubtitle;

  /// No description provided for @workStatementsAllYears.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get workStatementsAllYears;

  /// No description provided for @workStatementsRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'RECENT STATEMENTS'**
  String get workStatementsRecentTitle;

  /// No description provided for @workStatementsArchivedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} archived'**
  String workStatementsArchivedCount(int count);

  /// No description provided for @workStatementsStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get workStatementsStatusVerified;

  /// No description provided for @workStatementsNetTakeHome.
  ///
  /// In en, this message translates to:
  /// **'NET TAKE-HOME'**
  String get workStatementsNetTakeHome;

  /// No description provided for @workStatementsArchiveOnly.
  ///
  /// In en, this message translates to:
  /// **'Archive only'**
  String get workStatementsArchiveOnly;

  /// No description provided for @workStatementsViewSlip.
  ///
  /// In en, this message translates to:
  /// **'View Statement'**
  String get workStatementsViewSlip;

  /// No description provided for @workStatementsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No statements found'**
  String get workStatementsEmptyTitle;

  /// No description provided for @workStatementsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different year or add a new work record.'**
  String get workStatementsEmptySubtitle;

  /// No description provided for @workEntrySelectCompanyFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a company first.'**
  String get workEntrySelectCompanyFirst;

  /// No description provided for @workDocumentEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get workDocumentEntryTitle;

  /// No description provided for @workDocumentEntryCategories.
  ///
  /// In en, this message translates to:
  /// **'WORK CATEGORIES'**
  String get workDocumentEntryCategories;

  /// No description provided for @workDocumentEntryTargetVault.
  ///
  /// In en, this message translates to:
  /// **'TARGET VAULT'**
  String get workDocumentEntryTargetVault;

  /// No description provided for @workPayslipAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Payslip'**
  String get workPayslipAddTitle;

  /// No description provided for @workPayslipSectionPaymentMonth.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT MONTH'**
  String get workPayslipSectionPaymentMonth;

  /// No description provided for @workPayslipSectionNetSalary.
  ///
  /// In en, this message translates to:
  /// **'NET SALARY'**
  String get workPayslipSectionNetSalary;

  /// No description provided for @workPayslipOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get workPayslipOptional;

  /// No description provided for @workPayslipSectionUploadMethods.
  ///
  /// In en, this message translates to:
  /// **'UPLOAD METHODS'**
  String get workPayslipSectionUploadMethods;

  /// No description provided for @workPayslipMethodScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Payslip'**
  String get workPayslipMethodScanTitle;

  /// No description provided for @workPayslipMethodScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Powered by AI Extraction'**
  String get workPayslipMethodScanSubtitle;

  /// No description provided for @workPayslipMethodUploadPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF or Image'**
  String get workPayslipMethodUploadPdfTitle;

  /// No description provided for @workPayslipMethodUploadPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick from files, gallery, or camera'**
  String get workPayslipMethodUploadPdfSubtitle;

  /// No description provided for @workPayslipMethodManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get workPayslipMethodManualTitle;

  /// No description provided for @workPayslipMethodManualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in details yourself'**
  String get workPayslipMethodManualSubtitle;

  /// No description provided for @workPayslipSectionTargetVault.
  ///
  /// In en, this message translates to:
  /// **'TARGET VAULT'**
  String get workPayslipSectionTargetVault;

  /// No description provided for @workPayslipTargetVaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Company Managed Vault'**
  String get workPayslipTargetVaultSubtitle;

  /// No description provided for @workPayslipSelectCompanyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select company'**
  String get workPayslipSelectCompanyPlaceholder;

  /// No description provided for @workPayslipNoCompanyAvailable.
  ///
  /// In en, this message translates to:
  /// **'No created companies found yet.'**
  String get workPayslipNoCompanyAvailable;

  /// No description provided for @workPayslipPickCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get workPayslipPickCamera;

  /// No description provided for @workPayslipUnableSaveFileLocally.
  ///
  /// In en, this message translates to:
  /// **'Unable to save selected file locally.'**
  String get workPayslipUnableSaveFileLocally;

  /// No description provided for @workPayslipUnableSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Unable to select file right now.'**
  String get workPayslipUnableSelectFile;

  /// No description provided for @workPayslipSelectFileFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a PDF or image first.'**
  String get workPayslipSelectFileFirst;

  /// No description provided for @workPayslipNetSalaryHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get workPayslipNetSalaryHint;

  /// No description provided for @workPayslipHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payslips History'**
  String get workPayslipHistoryTitle;

  /// No description provided for @workPayslipHistoryRecentDocuments.
  ///
  /// In en, this message translates to:
  /// **'RECENT DOCUMENTS'**
  String get workPayslipHistoryRecentDocuments;

  /// No description provided for @workPayslipHistoryItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String workPayslipHistoryItemsCount(int count);

  /// No description provided for @workPayslipHistoryNetPay.
  ///
  /// In en, this message translates to:
  /// **'Net Pay'**
  String get workPayslipHistoryNetPay;

  /// No description provided for @workPayslipHistoryLoadOlder.
  ///
  /// In en, this message translates to:
  /// **'Load Older Payslips'**
  String get workPayslipHistoryLoadOlder;

  /// No description provided for @workPayslipHistoryAllLoaded.
  ///
  /// In en, this message translates to:
  /// **'All payslips are loaded.'**
  String get workPayslipHistoryAllLoaded;

  /// No description provided for @workPayslipHistoryNoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No payslips yet'**
  String get workPayslipHistoryNoDataTitle;

  /// No description provided for @workPayslipHistoryNoDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your payslip documents will appear here.'**
  String get workPayslipHistoryNoDataSubtitle;

  /// No description provided for @workPayslipHistorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search payslips...'**
  String get workPayslipHistorySearchHint;

  /// No description provided for @workPayslipHistorySearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get workPayslipHistorySearchButton;

  /// No description provided for @workPayslipHistorySearchApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get workPayslipHistorySearchApply;

  /// No description provided for @workPayslipHistorySearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get workPayslipHistorySearchClear;

  /// No description provided for @workManualEntryAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Work Document'**
  String get workManualEntryAddTitle;

  /// No description provided for @workManualEntryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Work Document'**
  String get workManualEntryEditTitle;

  /// No description provided for @workManualEntrySectionDocumentDetails.
  ///
  /// In en, this message translates to:
  /// **'Document Details'**
  String get workManualEntrySectionDocumentDetails;

  /// No description provided for @workManualEntryDocumentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get workManualEntryDocumentTypeLabel;

  /// No description provided for @workManualEntrySharedTypeHint.
  ///
  /// In en, this message translates to:
  /// **'The selected type and vault assignment will apply to every file. Set a title for each document below.'**
  String get workManualEntrySharedTypeHint;

  /// No description provided for @workManualEntryAssignVaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign to Vault (Employer)'**
  String get workManualEntryAssignVaultLabel;

  /// No description provided for @workManualEntryDocumentTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Document Title'**
  String get workManualEntryDocumentTitleLabel;

  /// No description provided for @workManualEntrySectionSelectedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Selected Documents'**
  String get workManualEntrySectionSelectedDocuments;

  /// No description provided for @workManualEntryDocumentTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Payslip April 2026'**
  String get workManualEntryDocumentTitleHint;

  /// No description provided for @workManualEntrySelectedDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Document {index}'**
  String workManualEntrySelectedDocumentLabel(int index);

  /// No description provided for @workManualEntrySectionTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get workManualEntrySectionTimeline;

  /// No description provided for @workManualEntryEffectiveDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective Date'**
  String get workManualEntryEffectiveDateLabel;

  /// No description provided for @workManualEntryExpiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get workManualEntryExpiryDateLabel;

  /// No description provided for @workManualEntryDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'mm/dd/yyyy'**
  String get workManualEntryDatePlaceholder;

  /// No description provided for @workManualEntryOngoingLabel.
  ///
  /// In en, this message translates to:
  /// **'Ongoing / Permanent'**
  String get workManualEntryOngoingLabel;

  /// No description provided for @workManualEntryOngoingHint.
  ///
  /// In en, this message translates to:
  /// **'No fixed expiration date'**
  String get workManualEntryOngoingHint;

  /// No description provided for @workManualEntrySectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Document Notes'**
  String get workManualEntrySectionNotes;

  /// No description provided for @workManualEntryLabelFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Label (Optional)'**
  String get workManualEntryLabelFieldLabel;

  /// No description provided for @workManualEntryLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. March 2026, Q1 Report, Signed copy...'**
  String get workManualEntryLabelHint;

  /// No description provided for @workManualEntryNotesFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Contract Terms or Internal Notes'**
  String get workManualEntryNotesFieldLabel;

  /// No description provided for @workManualEntryNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Mention key clauses, salary details, or review highlights...'**
  String get workManualEntryNotesHint;

  /// No description provided for @workManualEntryUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Original File'**
  String get workManualEntryUploadTitle;

  /// No description provided for @workManualEntryUploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PDF, Word, Excel, PPT, images & more (Max 10MB)'**
  String get workManualEntryUploadSubtitle;

  /// No description provided for @workManualEntryAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add Work Document'**
  String get workManualEntryAddButton;

  /// No description provided for @workManualEntrySelectUploadFirst.
  ///
  /// In en, this message translates to:
  /// **'Upload a PDF or image first.'**
  String get workManualEntrySelectUploadFirst;

  /// No description provided for @workManualEntryFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File exceeds 10MB. Select a smaller file.'**
  String get workManualEntryFileTooLarge;

  /// No description provided for @workManualEntryTypeEmploymentContract.
  ///
  /// In en, this message translates to:
  /// **'Employment Contract'**
  String get workManualEntryTypeEmploymentContract;

  /// No description provided for @workManualEntryTypeEmployerCertificate.
  ///
  /// In en, this message translates to:
  /// **'Employer Certificate'**
  String get workManualEntryTypeEmployerCertificate;

  /// No description provided for @workManualEntryTypeInternshipAgreement.
  ///
  /// In en, this message translates to:
  /// **'Internship Agreement'**
  String get workManualEntryTypeInternshipAgreement;

  /// No description provided for @workManualEntryTypeTaxDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Tax Declaration'**
  String get workManualEntryTypeTaxDeclaration;

  /// No description provided for @workManualEntryTypeTaxCertificate.
  ///
  /// In en, this message translates to:
  /// **'Tax Certificate'**
  String get workManualEntryTypeTaxCertificate;

  /// No description provided for @workManualEntryTypeBenefitsEnrollment.
  ///
  /// In en, this message translates to:
  /// **'Benefits Enrollment'**
  String get workManualEntryTypeBenefitsEnrollment;

  /// No description provided for @workManualEntryTypeInsuranceCoverage.
  ///
  /// In en, this message translates to:
  /// **'Insurance Coverage'**
  String get workManualEntryTypeInsuranceCoverage;

  /// No description provided for @workManualEntryTypeResignationLetter.
  ///
  /// In en, this message translates to:
  /// **'Resignation Letter'**
  String get workManualEntryTypeResignationLetter;

  /// No description provided for @workManualEntryTypeTerminationNotice.
  ///
  /// In en, this message translates to:
  /// **'Termination Notice'**
  String get workManualEntryTypeTerminationNotice;

  /// No description provided for @workManualEntryTypeFinalSettlement.
  ///
  /// In en, this message translates to:
  /// **'Final Settlement'**
  String get workManualEntryTypeFinalSettlement;

  /// No description provided for @workManualEntryTypeEndOfServiceCert.
  ///
  /// In en, this message translates to:
  /// **'End of Service Certificate'**
  String get workManualEntryTypeEndOfServiceCert;

  /// No description provided for @workManualEntryTypeNonCompete.
  ///
  /// In en, this message translates to:
  /// **'Non-Compete Agreement'**
  String get workManualEntryTypeNonCompete;

  /// No description provided for @workManualEntryTypeSalarySlip.
  ///
  /// In en, this message translates to:
  /// **'Salary Slip'**
  String get workManualEntryTypeSalarySlip;

  /// No description provided for @workManualEntryTypeReferenceLetter.
  ///
  /// In en, this message translates to:
  /// **'Reference Letter'**
  String get workManualEntryTypeReferenceLetter;

  /// No description provided for @workManualEntryTypePerformanceReview.
  ///
  /// In en, this message translates to:
  /// **'Performance Review'**
  String get workManualEntryTypePerformanceReview;

  /// No description provided for @workManualEntryTypePromotionLetter.
  ///
  /// In en, this message translates to:
  /// **'Promotion Letter'**
  String get workManualEntryTypePromotionLetter;

  /// No description provided for @workManualEntryTypeTrainingCert.
  ///
  /// In en, this message translates to:
  /// **'Training Certificate'**
  String get workManualEntryTypeTrainingCert;

  /// No description provided for @workManualEntryTypeQuittance.
  ///
  /// In en, this message translates to:
  /// **'Rent Receipt'**
  String get workManualEntryTypeQuittance;

  /// No description provided for @workManualEntryTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other Work Document'**
  String get workManualEntryTypeOther;

  /// No description provided for @workPayslipTitleTemplate.
  ///
  /// In en, this message translates to:
  /// **'Payslip {month}'**
  String workPayslipTitleTemplate(String month);

  /// No description provided for @workFolderHistoryContractsAndLegal.
  ///
  /// In en, this message translates to:
  /// **'Contracts & Legal'**
  String get workFolderHistoryContractsAndLegal;

  /// No description provided for @workFolderHistoryAllDocuments.
  ///
  /// In en, this message translates to:
  /// **'ALL DOCUMENTS ({count})'**
  String workFolderHistoryAllDocuments(int count);

  /// No description provided for @workFolderHistorySort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get workFolderHistorySort;

  /// No description provided for @workFolderHistorySortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get workFolderHistorySortNewest;

  /// No description provided for @workFolderHistorySortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get workFolderHistorySortOldest;

  /// No description provided for @workFolderHistorySortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title A-Z'**
  String get workFolderHistorySortTitle;

  /// No description provided for @workFolderHistoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Added: {date} • {size}'**
  String workFolderHistoryAdded(String date, String size);

  /// No description provided for @workFolderHistorySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get workFolderHistorySearchTitle;

  /// No description provided for @workFolderHistorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search documents...'**
  String get workFolderHistorySearchHint;

  /// No description provided for @workFolderHistoryNoDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get workFolderHistoryNoDocumentsTitle;

  /// No description provided for @workFolderHistoryNoDocumentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your folder documents will appear here.'**
  String get workFolderHistoryNoDocumentsSubtitle;

  /// No description provided for @collectionDetailFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder Details'**
  String get collectionDetailFolderTitle;

  /// No description provided for @collectionDetailDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Details'**
  String get collectionDetailDocumentTitle;

  /// No description provided for @collectionDetailNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note Details'**
  String get collectionDetailNoteTitle;

  /// No description provided for @collectionDetailInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Field Details'**
  String get collectionDetailInputTitle;

  /// No description provided for @collectionDetailChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist Details'**
  String get collectionDetailChecklistTitle;

  /// No description provided for @collectionDetailLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Link Details'**
  String get collectionDetailLinkTitle;

  /// No description provided for @collectionDetailImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Image Details'**
  String get collectionDetailImageTitle;

  /// No description provided for @collectionDetailExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get collectionDetailExpenseTitle;

  /// No description provided for @collectionDetailTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get collectionDetailTimelineTitle;

  /// No description provided for @collectionDetailLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get collectionDetailLocationTitle;

  /// No description provided for @collectionDetailSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Section Details'**
  String get collectionDetailSectionTitle;

  /// No description provided for @collectionDetailActions.
  ///
  /// In en, this message translates to:
  /// **'ACTIONS'**
  String get collectionDetailActions;

  /// No description provided for @collectionDetailTaskList.
  ///
  /// In en, this message translates to:
  /// **'TASK LIST'**
  String get collectionDetailTaskList;

  /// No description provided for @collectionDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get collectionDetailDescription;

  /// No description provided for @collectionDetailAttachment.
  ///
  /// In en, this message translates to:
  /// **'ATTACHMENT'**
  String get collectionDetailAttachment;

  /// No description provided for @collectionDetailCompletionProgress.
  ///
  /// In en, this message translates to:
  /// **'Completion Progress'**
  String get collectionDetailCompletionProgress;

  /// No description provided for @collectionDetailShareDocument.
  ///
  /// In en, this message translates to:
  /// **'Share Document'**
  String get collectionDetailShareDocument;

  /// No description provided for @collectionDetailPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get collectionDetailPreview;

  /// No description provided for @collectionDetailDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get collectionDetailDownload;

  /// No description provided for @collectionDetailOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get collectionDetailOpenLink;

  /// No description provided for @collectionDetailEditImage.
  ///
  /// In en, this message translates to:
  /// **'Edit Image'**
  String get collectionDetailEditImage;

  /// No description provided for @collectionDetailOpenInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get collectionDetailOpenInMaps;

  /// No description provided for @collectionDetailMovePrintPdf.
  ///
  /// In en, this message translates to:
  /// **'Print PDF'**
  String get collectionDetailMovePrintPdf;

  /// No description provided for @collectionDetailMoveToCollection.
  ///
  /// In en, this message translates to:
  /// **'Move to Collection'**
  String get collectionDetailMoveToCollection;

  /// No description provided for @collectionDetailShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get collectionDetailShareLink;

  /// No description provided for @collectionDetailShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get collectionDetailShare;

  /// No description provided for @collectionDetailDeleteLink.
  ///
  /// In en, this message translates to:
  /// **'Delete Link'**
  String get collectionDetailDeleteLink;

  /// No description provided for @collectionDetailDeleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete Folder'**
  String get collectionDetailDeleteFolder;

  /// No description provided for @collectionDetailDeleteSection.
  ///
  /// In en, this message translates to:
  /// **'Delete Section'**
  String get collectionDetailDeleteSection;

  /// No description provided for @collectionDetailDeleteChecklist.
  ///
  /// In en, this message translates to:
  /// **'Delete Checklist'**
  String get collectionDetailDeleteChecklist;

  /// No description provided for @collectionDetailRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get collectionDetailRemove;

  /// No description provided for @collectionDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get collectionDetailDelete;

  /// No description provided for @collectionDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get collectionDetailEdit;

  /// No description provided for @collectionDetailRearrange.
  ///
  /// In en, this message translates to:
  /// **'Rearrange'**
  String get collectionDetailRearrange;

  /// No description provided for @collectionDetailDeleteBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Block'**
  String get collectionDetailDeleteBlockTitle;

  /// No description provided for @collectionDetailDeleteBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get collectionDetailDeleteBlockMessage;

  /// No description provided for @collectionDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get collectionDetailCancel;

  /// No description provided for @collectionDetailDateNotSet.
  ///
  /// In en, this message translates to:
  /// **'Date not set'**
  String get collectionDetailDateNotSet;

  /// No description provided for @collectionDetailTimeNotSet.
  ///
  /// In en, this message translates to:
  /// **'Time not set'**
  String get collectionDetailTimeNotSet;

  /// No description provided for @collectionDetailNoLocationSet.
  ///
  /// In en, this message translates to:
  /// **'No location set'**
  String get collectionDetailNoLocationSet;

  /// No description provided for @collectionDetailNoFileAttached.
  ///
  /// In en, this message translates to:
  /// **'No file attached'**
  String get collectionDetailNoFileAttached;

  /// No description provided for @collectionDetailFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get collectionDetailFileNotFound;

  /// No description provided for @collectionDetailTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} tasks'**
  String collectionDetailTaskCount(int done, int total);

  /// No description provided for @collectionDetailPreviewAvailable.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW AVAILABLE'**
  String get collectionDetailPreviewAvailable;

  /// No description provided for @collectionDetailItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{item} other{items}}'**
  String collectionDetailItemCount(int count);

  /// No description provided for @collectionDetailFolderCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{folder} other{folders}}'**
  String collectionDetailFolderCount(int count);

  /// No description provided for @collectionDetailReminderCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{reminder} other{reminders}}'**
  String collectionDetailReminderCount(int count);

  /// No description provided for @collectionEntryDocumentInfo.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT INFORMATION'**
  String get collectionEntryDocumentInfo;

  /// No description provided for @collectionEntryDetails.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get collectionEntryDetails;

  /// No description provided for @collectionEntrySource.
  ///
  /// In en, this message translates to:
  /// **'SOURCE'**
  String get collectionEntrySource;

  /// No description provided for @collectionEntryChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get collectionEntryChange;

  /// No description provided for @collectionEntrySecuritySettings.
  ///
  /// In en, this message translates to:
  /// **'SECURITY SETTINGS'**
  String get collectionEntrySecuritySettings;

  /// No description provided for @collectionEntryChooseIcon.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE ICON'**
  String get collectionEntryChooseIcon;

  /// No description provided for @collectionEntrySearchIcon.
  ///
  /// In en, this message translates to:
  /// **'Search icon'**
  String get collectionEntrySearchIcon;

  /// No description provided for @collectionEntryUseEmoji.
  ///
  /// In en, this message translates to:
  /// **'Use emoji'**
  String get collectionEntryUseEmoji;

  /// No description provided for @collectionEntryPickLocalImage.
  ///
  /// In en, this message translates to:
  /// **'Pick local image'**
  String get collectionEntryPickLocalImage;

  /// No description provided for @collectionEntryLocalImageSelected.
  ///
  /// In en, this message translates to:
  /// **'Local image selected'**
  String get collectionEntryLocalImageSelected;

  /// No description provided for @collectionEntryEmojiSelected.
  ///
  /// In en, this message translates to:
  /// **'Emoji selected'**
  String get collectionEntryEmojiSelected;

  /// No description provided for @collectionEntryBlockIconHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a symbol, pick a local image, or use an emoji.'**
  String get collectionEntryBlockIconHint;

  /// No description provided for @collectionEntryNoIconsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching icons found.'**
  String get collectionEntryNoIconsFound;

  /// No description provided for @collectionEntryEmojiHint.
  ///
  /// In en, this message translates to:
  /// **'Emoji or short label'**
  String get collectionEntryEmojiHint;

  /// No description provided for @collectionEntryLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'LOCATION DETAILS'**
  String get collectionEntryLocationDetails;

  /// No description provided for @collectionEntryLocationSearchSection.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get collectionEntryLocationSearchSection;

  /// No description provided for @collectionEntryLocationResult.
  ///
  /// In en, this message translates to:
  /// **'RESULT'**
  String get collectionEntryLocationResult;

  /// No description provided for @collectionEntryLocationResultMap.
  ///
  /// In en, this message translates to:
  /// **'RESULT · MAP'**
  String get collectionEntryLocationResultMap;

  /// No description provided for @collectionEntryLocationSuggestions.
  ///
  /// In en, this message translates to:
  /// **'SUGGESTIONS'**
  String get collectionEntryLocationSuggestions;

  /// No description provided for @collectionEntryLocationLabelField.
  ///
  /// In en, this message translates to:
  /// **'LABEL'**
  String get collectionEntryLocationLabelField;

  /// No description provided for @collectionEntryLocationAddressField.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get collectionEntryLocationAddressField;

  /// No description provided for @collectionEntryLocationLatitude.
  ///
  /// In en, this message translates to:
  /// **'LAT'**
  String get collectionEntryLocationLatitude;

  /// No description provided for @collectionEntryLocationLongitude.
  ///
  /// In en, this message translates to:
  /// **'LONG'**
  String get collectionEntryLocationLongitude;

  /// No description provided for @collectionEntryLocationNoResultSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a place to preview the map.'**
  String get collectionEntryLocationNoResultSelected;

  /// No description provided for @collectionEntryLocationMapsHelp.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps from the detail page.'**
  String get collectionEntryLocationMapsHelp;

  /// No description provided for @collectionEntryCurrency.
  ///
  /// In en, this message translates to:
  /// **'CURRENCY'**
  String get collectionEntryCurrency;

  /// No description provided for @collectionEntryDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get collectionEntryDate;

  /// No description provided for @collectionEntryCategory.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get collectionEntryCategory;

  /// No description provided for @collectionEntryReceipt.
  ///
  /// In en, this message translates to:
  /// **'RECEIPT'**
  String get collectionEntryReceipt;

  /// No description provided for @collectionEntryCurrentSelection.
  ///
  /// In en, this message translates to:
  /// **'CURRENT SELECTION'**
  String get collectionEntryCurrentSelection;

  /// No description provided for @collectionEntryFolderName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get collectionEntryFolderName;

  /// No description provided for @collectionEntrySectionName.
  ///
  /// In en, this message translates to:
  /// **'Section Name'**
  String get collectionEntrySectionName;

  /// No description provided for @collectionEntryDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Title'**
  String get collectionEntryDocumentTitle;

  /// No description provided for @collectionEntryEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get collectionEntryEventTitle;

  /// No description provided for @collectionEntryEventType.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get collectionEntryEventType;

  /// No description provided for @collectionEntryDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get collectionEntryDateTime;

  /// No description provided for @collectionEntryFieldType.
  ///
  /// In en, this message translates to:
  /// **'Field Type'**
  String get collectionEntryFieldType;

  /// No description provided for @collectionEntryPasteOrType.
  ///
  /// In en, this message translates to:
  /// **'Paste or type'**
  String get collectionEntryPasteOrType;

  /// No description provided for @collectionEntryPreviewFetched.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW · FETCHED'**
  String get collectionEntryPreviewFetched;

  /// No description provided for @collectionEntryPreviewFetching.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW · FETCHING'**
  String get collectionEntryPreviewFetching;

  /// No description provided for @collectionEntryTitleOverride.
  ///
  /// In en, this message translates to:
  /// **'Title · Override'**
  String get collectionEntryTitleOverride;

  /// No description provided for @collectionEntryInputTypeSection.
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get collectionEntryInputTypeSection;

  /// No description provided for @collectionEntryInputFieldSection.
  ///
  /// In en, this message translates to:
  /// **'FIELD'**
  String get collectionEntryInputFieldSection;

  /// No description provided for @collectionEntryInputPreviewCopy.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW · TAP TO COPY'**
  String get collectionEntryInputPreviewCopy;

  /// No description provided for @collectionEntryInputCopyAction.
  ///
  /// In en, this message translates to:
  /// **'copy'**
  String get collectionEntryInputCopyAction;

  /// No description provided for @collectionEntryInputCopyHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap-to-copy is enabled on Short text, Number, Phone, and URL field types.'**
  String get collectionEntryInputCopyHelp;

  /// No description provided for @collectionEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get collectionEntryLabel;

  /// No description provided for @collectionEntryValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get collectionEntryValue;

  /// No description provided for @collectionEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get collectionEntryTitle;

  /// No description provided for @collectionEntryDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get collectionEntryDescription;

  /// No description provided for @collectionEntryDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get collectionEntryDescriptionOptional;

  /// No description provided for @collectionEntryCollapsedByDefault.
  ///
  /// In en, this message translates to:
  /// **'Collapsed by default'**
  String get collectionEntryCollapsedByDefault;

  /// No description provided for @collectionEntryUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get collectionEntryUrl;

  /// No description provided for @collectionEntryLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get collectionEntryLocation;

  /// No description provided for @collectionEntryExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get collectionEntryExpiryDate;

  /// No description provided for @collectionEntryNoteContent.
  ///
  /// In en, this message translates to:
  /// **'Note Content'**
  String get collectionEntryNoteContent;

  /// No description provided for @collectionEntryNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get collectionEntryNotes;

  /// No description provided for @collectionEntryNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get collectionEntryNotesOptional;

  /// No description provided for @collectionEntrySecurityLevel.
  ///
  /// In en, this message translates to:
  /// **'Security Level'**
  String get collectionEntrySecurityLevel;

  /// No description provided for @collectionEntryAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get collectionEntryAmount;

  /// No description provided for @collectionEntryChecklistIdentity.
  ///
  /// In en, this message translates to:
  /// **'Checklist Identity'**
  String get collectionEntryChecklistIdentity;

  /// No description provided for @collectionEntryTaskItems.
  ///
  /// In en, this message translates to:
  /// **'Task Items'**
  String get collectionEntryTaskItems;

  /// No description provided for @collectionEntrySearchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get collectionEntrySearchPlace;

  /// No description provided for @collectionEntryHintFolderName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Itinerary'**
  String get collectionEntryHintFolderName;

  /// No description provided for @collectionEntryHintFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize your workspace items in this folder'**
  String get collectionEntryHintFolderDesc;

  /// No description provided for @collectionEntryHintSectionName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Important Documents'**
  String get collectionEntryHintSectionName;

  /// No description provided for @collectionEntryHintSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Describe what this section contains...'**
  String get collectionEntryHintSectionDesc;

  /// No description provided for @collectionEntryHintDocTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Passport 2024'**
  String get collectionEntryHintDocTitle;

  /// No description provided for @collectionEntryHintDocumentNotes.
  ///
  /// In en, this message translates to:
  /// **'Source, context, or notes about this file...'**
  String get collectionEntryHintDocumentNotes;

  /// No description provided for @collectionEntryHintEventTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Inventory walk-through with landlord'**
  String get collectionEntryHintEventTitle;

  /// No description provided for @collectionEntryHintLocation.
  ///
  /// In en, this message translates to:
  /// **'e.g. Riverside Park'**
  String get collectionEntryHintLocation;

  /// No description provided for @collectionEntryHintLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'e.g. Apartment — Rue de Lille'**
  String get collectionEntryHintLocationLabel;

  /// No description provided for @collectionEntryHintUrl.
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get collectionEntryHintUrl;

  /// No description provided for @collectionEntryHintAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-fetching title...'**
  String get collectionEntryHintAutoTitle;

  /// No description provided for @collectionEntryHintLinkDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a brief description of this link'**
  String get collectionEntryHintLinkDesc;

  /// No description provided for @collectionEntryHintFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'e.g. Camera Serial'**
  String get collectionEntryHintFieldLabel;

  /// No description provided for @collectionEntryHintFieldValue.
  ///
  /// In en, this message translates to:
  /// **'Enter the field content'**
  String get collectionEntryHintFieldValue;

  /// No description provided for @collectionEntryHintChecklist.
  ///
  /// In en, this message translates to:
  /// **'e.g. European Summer Trip'**
  String get collectionEntryHintChecklist;

  /// No description provided for @collectionEntryHintNoteContent.
  ///
  /// In en, this message translates to:
  /// **'Start typing your secure note...'**
  String get collectionEntryHintNoteContent;

  /// No description provided for @collectionEntryHintEventDesc.
  ///
  /// In en, this message translates to:
  /// **'Bring printed inventory · 2 copies'**
  String get collectionEntryHintEventDesc;

  /// No description provided for @collectionEntryHintImageNotes.
  ///
  /// In en, this message translates to:
  /// **'Add some context or secure notes...'**
  String get collectionEntryHintImageNotes;

  /// No description provided for @collectionEntryHintImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Give your entry a name'**
  String get collectionEntryHintImageTitle;

  /// No description provided for @collectionEntryHintAddress.
  ///
  /// In en, this message translates to:
  /// **'1200 Avenue of the Americas, NY'**
  String get collectionEntryHintAddress;

  /// No description provided for @collectionEntryHintTagLabels.
  ///
  /// In en, this message translates to:
  /// **'e.g. Work, Secret Stash'**
  String get collectionEntryHintTagLabels;

  /// No description provided for @collectionEntryHintChecklistItem.
  ///
  /// In en, this message translates to:
  /// **'Checklist item'**
  String get collectionEntryHintChecklistItem;

  /// No description provided for @collectionEntryHintAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add another task...'**
  String get collectionEntryHintAddTask;

  /// No description provided for @collectionEntryHideField.
  ///
  /// In en, this message translates to:
  /// **'Hide field in vault view'**
  String get collectionEntryHideField;

  /// No description provided for @collectionEntryEnableQuickCopy.
  ///
  /// In en, this message translates to:
  /// **'Enable quick copy'**
  String get collectionEntryEnableQuickCopy;

  /// No description provided for @collectionEntryNewEntry.
  ///
  /// In en, this message translates to:
  /// **'New Entry'**
  String get collectionEntryNewEntry;

  /// No description provided for @collectionEntryNewEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Securing your new resource in the vault.'**
  String get collectionEntryNewEntrySubtitle;

  /// No description provided for @collectionEntryPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get collectionEntryPreviewLabel;

  /// No description provided for @collectionEntryPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'The preview will automatically generate once a valid URL is added.'**
  String get collectionEntryPreviewHint;

  /// No description provided for @collectionEntryLoadingPreview.
  ///
  /// In en, this message translates to:
  /// **'Loading preview...'**
  String get collectionEntryLoadingPreview;

  /// No description provided for @collectionEntrySuggestedTasks.
  ///
  /// In en, this message translates to:
  /// **'Suggested Tasks'**
  String get collectionEntrySuggestedTasks;

  /// No description provided for @collectionEntryEncryptedNote.
  ///
  /// In en, this message translates to:
  /// **'This note will be encrypted and stored securely in your private vault.'**
  String get collectionEntryEncryptedNote;

  /// No description provided for @collectionEntryValidationTitle.
  ///
  /// In en, this message translates to:
  /// **'Please fill the required title field.'**
  String get collectionEntryValidationTitle;

  /// No description provided for @collectionEntryItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Items'**
  String collectionEntryItemsCount(int count);

  /// No description provided for @collectionEntryAddFolder.
  ///
  /// In en, this message translates to:
  /// **'Add folder'**
  String get collectionEntryAddFolder;

  /// No description provided for @collectionEntryEditFolder.
  ///
  /// In en, this message translates to:
  /// **'Edit folder'**
  String get collectionEntryEditFolder;

  /// No description provided for @collectionEntryAddSection.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get collectionEntryAddSection;

  /// No description provided for @collectionEntryEditSection.
  ///
  /// In en, this message translates to:
  /// **'Edit section'**
  String get collectionEntryEditSection;

  /// No description provided for @collectionEntryAddDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get collectionEntryAddDocument;

  /// No description provided for @collectionEntryAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get collectionEntryAddNote;

  /// No description provided for @collectionEntryEditNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get collectionEntryEditNote;

  /// No description provided for @collectionEntryAddInput.
  ///
  /// In en, this message translates to:
  /// **'Add field'**
  String get collectionEntryAddInput;

  /// No description provided for @collectionEntryAddChecklist.
  ///
  /// In en, this message translates to:
  /// **'New Checklist'**
  String get collectionEntryAddChecklist;

  /// No description provided for @collectionEntryAddLink.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get collectionEntryAddLink;

  /// No description provided for @collectionEntryEditLink.
  ///
  /// In en, this message translates to:
  /// **'Edit link'**
  String get collectionEntryEditLink;

  /// No description provided for @collectionEntryAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get collectionEntryAddImage;

  /// No description provided for @collectionEntryAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get collectionEntryAddExpense;

  /// No description provided for @collectionEntryAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get collectionEntryAddEvent;

  /// No description provided for @collectionEntryEditEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get collectionEntryEditEvent;

  /// No description provided for @collectionEntryAddLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get collectionEntryAddLocation;

  /// No description provided for @collectionEntryEditLocation.
  ///
  /// In en, this message translates to:
  /// **'Edit location'**
  String get collectionEntryEditLocation;

  /// No description provided for @collectionEntryReplaceFile.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get collectionEntryReplaceFile;

  /// No description provided for @collectionEntrySourceFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get collectionEntrySourceFiles;

  /// No description provided for @collectionEntrySourcePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get collectionEntrySourcePhotos;

  /// No description provided for @collectionEntrySourceScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get collectionEntrySourceScan;

  /// No description provided for @collectionEntrySaveVault.
  ///
  /// In en, this message translates to:
  /// **'Save to Vault'**
  String get collectionEntrySaveVault;

  /// No description provided for @collectionEntrySaveNote.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get collectionEntrySaveNote;

  /// No description provided for @collectionEntrySaveField.
  ///
  /// In en, this message translates to:
  /// **'Save Field'**
  String get collectionEntrySaveField;

  /// No description provided for @collectionEntrySaveChecklist.
  ///
  /// In en, this message translates to:
  /// **'Save Checklist'**
  String get collectionEntrySaveChecklist;

  /// No description provided for @collectionEntrySaveLink.
  ///
  /// In en, this message translates to:
  /// **'Save Link'**
  String get collectionEntrySaveLink;

  /// No description provided for @collectionEntrySaveImage.
  ///
  /// In en, this message translates to:
  /// **'Save Image'**
  String get collectionEntrySaveImage;

  /// No description provided for @collectionEntrySaveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get collectionEntrySaveExpense;

  /// No description provided for @collectionEntrySaveEvent.
  ///
  /// In en, this message translates to:
  /// **'Save Event'**
  String get collectionEntrySaveEvent;

  /// No description provided for @collectionEntryCreateFolder.
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get collectionEntryCreateFolder;

  /// No description provided for @collectionEntryCreateSection.
  ///
  /// In en, this message translates to:
  /// **'Create Section'**
  String get collectionEntryCreateSection;

  /// No description provided for @collectionEntryUploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get collectionEntryUploadDocument;

  /// No description provided for @collectionEntryUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get collectionEntryUploadImage;

  /// No description provided for @collectionEntryUploadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload receipt'**
  String get collectionEntryUploadReceipt;

  /// No description provided for @collectionEntryUploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload files'**
  String get collectionEntryUploadFiles;

  /// No description provided for @collectionEntryUploadDefault.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get collectionEntryUploadDefault;

  /// No description provided for @collectionEntryUploadDocHint.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop your file here, or tap to browse'**
  String get collectionEntryUploadDocHint;

  /// No description provided for @collectionEntryUploadImageHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to select from gallery or drag and drop'**
  String get collectionEntryUploadImageHint;

  /// No description provided for @collectionEntryUploadReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG or PDF up to 10MB'**
  String get collectionEntryUploadReceiptHint;

  /// No description provided for @collectionEntryUploadFileHint.
  ///
  /// In en, this message translates to:
  /// **'PDF, DOCX, or Images up to 10MB'**
  String get collectionEntryUploadFileHint;

  /// No description provided for @collectionEntrySelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get collectionEntrySelectFile;

  /// No description provided for @collectionDashboardKind.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collectionDashboardKind;

  /// No description provided for @collectionDashboardDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get collectionDashboardDone;

  /// No description provided for @collectionDashboardEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Tap Add Block to get started.'**
  String get collectionDashboardEmptyState;

  /// No description provided for @collectionDashboardAddBlock.
  ///
  /// In en, this message translates to:
  /// **'Add Block'**
  String get collectionDashboardAddBlock;

  /// No description provided for @collectionDashboardCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get collectionDashboardCopied;

  /// No description provided for @collectionDashboardCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get collectionDashboardCopy;

  /// No description provided for @collectionDashboardRearrange.
  ///
  /// In en, this message translates to:
  /// **'Rearrange'**
  String get collectionDashboardRearrange;

  /// No description provided for @collectionDashboardRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get collectionDashboardRecentlyAdded;

  /// No description provided for @collectionDashboardJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get collectionDashboardJustNow;

  /// No description provided for @collectionFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get collectionFolderTitle;

  /// No description provided for @collectionFolderRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get collectionFolderRetry;

  /// No description provided for @collectionFolderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Folder not found.'**
  String get collectionFolderNotFound;

  /// No description provided for @collectionFolderEmpty.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty.'**
  String get collectionFolderEmpty;

  /// No description provided for @collectionFolderBlocks.
  ///
  /// In en, this message translates to:
  /// **'BLOCKS'**
  String get collectionFolderBlocks;

  /// No description provided for @collectionFolderContents.
  ///
  /// In en, this message translates to:
  /// **'CONTENTS'**
  String get collectionFolderContents;

  /// No description provided for @collectionReorderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reorder blocks'**
  String get collectionReorderTitle;

  /// No description provided for @collectionReorderInstruction.
  ///
  /// In en, this message translates to:
  /// **'Drag the handle to reorder · long-press a row for actions.'**
  String get collectionReorderInstruction;

  /// No description provided for @collectionBlockFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get collectionBlockFolder;

  /// No description provided for @collectionBlockSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get collectionBlockSection;

  /// No description provided for @collectionBlockDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get collectionBlockDocument;

  /// No description provided for @collectionBlockNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get collectionBlockNote;

  /// No description provided for @collectionBlockInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get collectionBlockInput;

  /// No description provided for @collectionBlockChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get collectionBlockChecklist;

  /// No description provided for @collectionBlockLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get collectionBlockLink;

  /// No description provided for @collectionBlockImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get collectionBlockImage;

  /// No description provided for @collectionBlockExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get collectionBlockExpense;

  /// No description provided for @collectionBlockTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get collectionBlockTimeline;

  /// No description provided for @collectionBlockLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get collectionBlockLocation;

  /// No description provided for @collectionBlockFolderDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize files'**
  String get collectionBlockFolderDesc;

  /// No description provided for @collectionBlockSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Group blocks'**
  String get collectionBlockSectionDesc;

  /// No description provided for @collectionBlockDocumentDesc.
  ///
  /// In en, this message translates to:
  /// **'Rich text doc'**
  String get collectionBlockDocumentDesc;

  /// No description provided for @collectionBlockNoteDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick thought'**
  String get collectionBlockNoteDesc;

  /// No description provided for @collectionBlockInputDesc.
  ///
  /// In en, this message translates to:
  /// **'Text field'**
  String get collectionBlockInputDesc;

  /// No description provided for @collectionBlockChecklistDesc.
  ///
  /// In en, this message translates to:
  /// **'Task list'**
  String get collectionBlockChecklistDesc;

  /// No description provided for @collectionBlockLinkDesc.
  ///
  /// In en, this message translates to:
  /// **'Web resource'**
  String get collectionBlockLinkDesc;

  /// No description provided for @collectionBlockImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get collectionBlockImageDesc;

  /// No description provided for @collectionBlockExpenseDesc.
  ///
  /// In en, this message translates to:
  /// **'Track spend'**
  String get collectionBlockExpenseDesc;

  /// No description provided for @collectionBlockTimelineDesc.
  ///
  /// In en, this message translates to:
  /// **'Event log'**
  String get collectionBlockTimelineDesc;

  /// No description provided for @collectionBlockLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Pin place'**
  String get collectionBlockLocationDesc;

  /// No description provided for @collectionAddBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a block'**
  String get collectionAddBlockTitle;

  /// No description provided for @collectionAddBlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a component to add to your workspace'**
  String get collectionAddBlockSubtitle;

  /// No description provided for @collectionAddBlockSearch.
  ///
  /// In en, this message translates to:
  /// **'Filter blocks'**
  String get collectionAddBlockSearch;

  /// No description provided for @collectionAddBlockStructural.
  ///
  /// In en, this message translates to:
  /// **'Structural'**
  String get collectionAddBlockStructural;

  /// No description provided for @collectionAddBlockContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get collectionAddBlockContent;

  /// No description provided for @collectionAddBlockNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching blocks'**
  String get collectionAddBlockNoResults;

  /// No description provided for @collectionCategoryMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get collectionCategoryMilestone;

  /// No description provided for @collectionCategoryDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get collectionCategoryDeadline;

  /// No description provided for @collectionCategoryReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get collectionCategoryReminder;

  /// No description provided for @collectionCategoryIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get collectionCategoryIdentity;

  /// No description provided for @collectionCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get collectionCategoryTravel;

  /// No description provided for @collectionCategoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get collectionCategoryFinance;

  /// No description provided for @collectionCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get collectionCategoryOther;

  /// No description provided for @collectionCategoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get collectionCategoryPersonal;

  /// No description provided for @collectionCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get collectionCategoryWork;

  /// No description provided for @collectionCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get collectionCategoryTransport;

  /// No description provided for @collectionCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get collectionCategoryFood;

  /// No description provided for @collectionCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get collectionCategoryShopping;

  /// No description provided for @collectionCategoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get collectionCategoryRent;

  /// No description provided for @collectionSecurityStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get collectionSecurityStandard;

  /// No description provided for @collectionSecurityConfidential.
  ///
  /// In en, this message translates to:
  /// **'Confidential'**
  String get collectionSecurityConfidential;

  /// No description provided for @collectionSecurityTopSecret.
  ///
  /// In en, this message translates to:
  /// **'Top Secret'**
  String get collectionSecurityTopSecret;

  /// No description provided for @collectionFieldShortText.
  ///
  /// In en, this message translates to:
  /// **'Short Text'**
  String get collectionFieldShortText;

  /// No description provided for @collectionFieldNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get collectionFieldNumber;

  /// No description provided for @collectionFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get collectionFieldDate;

  /// No description provided for @collectionFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get collectionFieldPhone;

  /// No description provided for @collectionBlockReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get collectionBlockReminder;

  /// No description provided for @collectionBlockReminderDesc.
  ///
  /// In en, this message translates to:
  /// **'Set alert'**
  String get collectionBlockReminderDesc;

  /// No description provided for @collectionDetailReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Details'**
  String get collectionDetailReminderTitle;

  /// No description provided for @collectionDetailDeleteReminder.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get collectionDetailDeleteReminder;

  /// No description provided for @collectionEntryAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get collectionEntryAddReminder;

  /// No description provided for @collectionEntryEditReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get collectionEntryEditReminder;

  /// No description provided for @collectionEntrySaveReminder.
  ///
  /// In en, this message translates to:
  /// **'Save Reminder'**
  String get collectionEntrySaveReminder;

  /// No description provided for @collectionEntryScheduleReminder.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get collectionEntryScheduleReminder;

  /// No description provided for @collectionEntryReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder Title'**
  String get collectionEntryReminderTitle;

  /// No description provided for @collectionEntryReminderHintTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Renew passport'**
  String get collectionEntryReminderHintTitle;

  /// No description provided for @collectionEntryReminderNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get collectionEntryReminderNote;

  /// No description provided for @collectionEntryReminderHintNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note for this reminder...'**
  String get collectionEntryReminderHintNote;

  /// No description provided for @collectionEntryReminderDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get collectionEntryReminderDateTime;

  /// No description provided for @collectionEntryReminderWhen.
  ///
  /// In en, this message translates to:
  /// **'WHEN'**
  String get collectionEntryReminderWhen;

  /// No description provided for @collectionEntryReminderRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get collectionEntryReminderRepeat;

  /// No description provided for @collectionEntryReminderSystemHelp.
  ///
  /// In en, this message translates to:
  /// **'Reminders use the system notifications service. Vault stays locked.'**
  String get collectionEntryReminderSystemHelp;

  /// No description provided for @collectionEntryIconSection.
  ///
  /// In en, this message translates to:
  /// **'ICON'**
  String get collectionEntryIconSection;

  /// No description provided for @collectionEntryFolderIconHelp.
  ///
  /// In en, this message translates to:
  /// **'Changing the folder icon doesn\'t touch the collection\'s icon or its other blocks.'**
  String get collectionEntryFolderIconHelp;

  /// No description provided for @collectionEntrySectionIconHelp.
  ///
  /// In en, this message translates to:
  /// **'Section icons are independent from folder and collection icons.'**
  String get collectionEntrySectionIconHelp;

  /// No description provided for @collectionEntrySectionIconSearchHint.
  ///
  /// In en, this message translates to:
  /// **'utility'**
  String get collectionEntrySectionIconSearchHint;

  /// No description provided for @collectionEntryDeleteFolder.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get collectionEntryDeleteFolder;

  /// No description provided for @collectionEntryDefaultState.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT STATE'**
  String get collectionEntryDefaultState;

  /// No description provided for @collectionEntryCollapsed.
  ///
  /// In en, this message translates to:
  /// **'Collapsed'**
  String get collectionEntryCollapsed;

  /// No description provided for @collectionEntryExpanded.
  ///
  /// In en, this message translates to:
  /// **'Expanded'**
  String get collectionEntryExpanded;

  /// No description provided for @collectionEntryTimelineEvent.
  ///
  /// In en, this message translates to:
  /// **'EVENT'**
  String get collectionEntryTimelineEvent;

  /// No description provided for @collectionEntryTimelineNotes.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get collectionEntryTimelineNotes;

  /// No description provided for @collectionEntryTimelineWhen.
  ///
  /// In en, this message translates to:
  /// **'WHEN'**
  String get collectionEntryTimelineWhen;

  /// No description provided for @collectionEntryTimelineCategory.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get collectionEntryTimelineCategory;

  /// No description provided for @collectionEntryTimelineCategoryTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get collectionEntryTimelineCategoryTrip;

  /// No description provided for @collectionEntryTimelineCategoryAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get collectionEntryTimelineCategoryAdmin;

  /// No description provided for @collectionEntryTimelineCategoryProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get collectionEntryTimelineCategoryProperty;

  /// No description provided for @collectionEntryTimelineCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get collectionEntryTimelineCategoryHealth;

  /// No description provided for @collectionEntryTimelineCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get collectionEntryTimelineCategoryWork;

  /// No description provided for @collectionEntryTimelineLinked.
  ///
  /// In en, this message translates to:
  /// **'LINKED'**
  String get collectionEntryTimelineLinked;

  /// No description provided for @collectionEntryTimelineLinkedPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Link a collection item'**
  String get collectionEntryTimelineLinkedPlaceholder;

  /// No description provided for @collectionEntryTimelineLinkedSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Linked item'**
  String get collectionEntryTimelineLinkedSheetTitle;

  /// No description provided for @collectionEntryTimelineLinkedHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Apartment · Rue de Lille'**
  String get collectionEntryTimelineLinkedHint;

  /// No description provided for @collectionReminderNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get collectionReminderNone;

  /// No description provided for @collectionReminderOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get collectionReminderOnce;

  /// No description provided for @collectionReminderDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get collectionReminderDaily;

  /// No description provided for @collectionReminderWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get collectionReminderWeekly;

  /// No description provided for @collectionReminderMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get collectionReminderMonthly;

  /// No description provided for @collectionReminderQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get collectionReminderQuarterly;

  /// No description provided for @collectionReminderYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get collectionReminderYearly;

  /// No description provided for @collectionReminderScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get collectionReminderScheduled;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupTitle;

  /// No description provided for @backupUnableLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load backups right now.'**
  String get backupUnableLoad;

  /// No description provided for @backupRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get backupRetry;

  /// No description provided for @backupCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating Backup...'**
  String get backupCreating;

  /// No description provided for @backupCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get backupCreateButton;

  /// No description provided for @backupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get backupCreateTitle;

  /// No description provided for @backupCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a passphrase to encrypt your backup. You will need this passphrase to restore.'**
  String get backupCreateSubtitle;

  /// No description provided for @backupHistorySection.
  ///
  /// In en, this message translates to:
  /// **'BACKUP HISTORY'**
  String get backupHistorySection;

  /// No description provided for @backupRestorePreview.
  ///
  /// In en, this message translates to:
  /// **'Restore Preview'**
  String get backupRestorePreview;

  /// No description provided for @backupRestoreWarning.
  ///
  /// In en, this message translates to:
  /// **'Your current data will be replaced. An emergency backup will be created first.'**
  String get backupRestoreWarning;

  /// No description provided for @backupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get backupRestoreTitle;

  /// No description provided for @backupRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the passphrase used when this backup was created.'**
  String get backupRestoreSubtitle;

  /// No description provided for @backupDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get backupDeleteTitle;

  /// No description provided for @backupNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No backup history'**
  String get backupNoHistory;

  /// No description provided for @backupNoHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your backup history will appear here once you create your first backup.'**
  String get backupNoHistorySubtitle;

  /// No description provided for @backupNoBackups.
  ///
  /// In en, this message translates to:
  /// **'No backups yet'**
  String get backupNoBackups;

  /// No description provided for @backupNoBackupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first encrypted backup to protect your data.'**
  String get backupNoBackupsSubtitle;

  /// No description provided for @backupLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last Backup'**
  String get backupLastBackup;

  /// No description provided for @backupAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get backupAutoTitle;

  /// No description provided for @backupAutoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically back up when you open the app'**
  String get backupAutoSubtitle;

  /// No description provided for @backupCloudStorage.
  ///
  /// In en, this message translates to:
  /// **'Cloud Storage'**
  String get backupCloudStorage;

  /// No description provided for @backupCloudBackups.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backups'**
  String get backupCloudBackups;

  /// No description provided for @backupCloudChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get backupCloudChecking;

  /// No description provided for @backupCloudUnableCheck.
  ///
  /// In en, this message translates to:
  /// **'Unable to check — tap refresh'**
  String get backupCloudUnableCheck;

  /// No description provided for @backupCloudRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from Cloud'**
  String get backupCloudRestoreTitle;

  /// No description provided for @backupCloudRestoreWarning.
  ///
  /// In en, this message translates to:
  /// **'This will download and restore the backup. Your current data will be replaced.'**
  String get backupCloudRestoreWarning;

  /// No description provided for @backupInterruptedWarning.
  ///
  /// In en, this message translates to:
  /// **'A previous restore was interrupted. Your data may be in an inconsistent state.'**
  String get backupInterruptedWarning;

  /// No description provided for @backupPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get backupPassphraseHint;

  /// No description provided for @backupAuthCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Paste authorization code here'**
  String get backupAuthCodeHint;

  /// No description provided for @backupAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authorization failed or cancelled.'**
  String get backupAuthFailed;

  /// No description provided for @backupConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get backupConnectionFailed;

  /// No description provided for @backupSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get backupSoon;

  /// No description provided for @backupConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get backupConnected;

  /// No description provided for @backupConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get backupConnect;

  /// No description provided for @backupDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get backupDisconnect;

  /// No description provided for @backupUploadICloud.
  ///
  /// In en, this message translates to:
  /// **'Upload to iCloud'**
  String get backupUploadICloud;

  /// No description provided for @backupComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get backupComingSoon;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get commonRestore;

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// No description provided for @commonRollback.
  ///
  /// In en, this message translates to:
  /// **'Rollback'**
  String get commonRollback;

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @backupDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get backupDeviceTitle;

  /// No description provided for @backupDeviceUnableLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load device info.'**
  String get backupDeviceUnableLoad;

  /// No description provided for @backupDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get backupDeviceId;

  /// No description provided for @backupDevicePlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get backupDevicePlatform;

  /// No description provided for @backupDeviceAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get backupDeviceAppVersion;

  /// No description provided for @backupDeviceFirstSeen.
  ///
  /// In en, this message translates to:
  /// **'First Seen'**
  String get backupDeviceFirstSeen;

  /// No description provided for @backupDeviceActiveWriter.
  ///
  /// In en, this message translates to:
  /// **'Active Backup Writer'**
  String get backupDeviceActiveWriter;

  /// No description provided for @backupDeviceActiveWriterDesc.
  ///
  /// In en, this message translates to:
  /// **'This device is the active backup writer.'**
  String get backupDeviceActiveWriterDesc;

  /// No description provided for @backupHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Health'**
  String get backupHealthTitle;

  /// No description provided for @backupHealthUnableLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load health data.'**
  String get backupHealthUnableLoad;

  /// No description provided for @backupHealthChainStatus.
  ///
  /// In en, this message translates to:
  /// **'CHAIN STATUS'**
  String get backupHealthChainStatus;

  /// No description provided for @backupHealthStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get backupHealthStatus;

  /// No description provided for @backupHealthStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get backupHealthStatusEmpty;

  /// No description provided for @backupHealthStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get backupHealthStatusActive;

  /// No description provided for @backupHealthChainDepth.
  ///
  /// In en, this message translates to:
  /// **'Chain Depth'**
  String get backupHealthChainDepth;

  /// No description provided for @backupHealthBaseDate.
  ///
  /// In en, this message translates to:
  /// **'Base Date'**
  String get backupHealthBaseDate;

  /// No description provided for @backupHealthHeadDate.
  ///
  /// In en, this message translates to:
  /// **'Head Date'**
  String get backupHealthHeadDate;

  /// No description provided for @backupHealthStats.
  ///
  /// In en, this message translates to:
  /// **'BACKUP STATS'**
  String get backupHealthStats;

  /// No description provided for @backupHealthLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last Backup'**
  String get backupHealthLastBackup;

  /// No description provided for @backupHealthNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get backupHealthNever;

  /// No description provided for @backupHealthTotalBackups.
  ///
  /// In en, this message translates to:
  /// **'Total Backups'**
  String get backupHealthTotalBackups;

  /// No description provided for @backupHealthStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage Used'**
  String get backupHealthStorageUsed;

  /// No description provided for @backupHealthEncryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get backupHealthEncryption;

  /// No description provided for @backupHealthDevice.
  ///
  /// In en, this message translates to:
  /// **'DEVICE'**
  String get backupHealthDevice;

  /// No description provided for @backupHealthName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get backupHealthName;

  /// No description provided for @backupHealthIntegrity.
  ///
  /// In en, this message translates to:
  /// **'INTEGRITY'**
  String get backupHealthIntegrity;

  /// No description provided for @backupHealthChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get backupHealthChecking;

  /// No description provided for @backupHealthRunCheck.
  ///
  /// In en, this message translates to:
  /// **'Run Integrity Check'**
  String get backupHealthRunCheck;

  /// No description provided for @backupHealthRebuildChain.
  ///
  /// In en, this message translates to:
  /// **'Rebuild Chain'**
  String get backupHealthRebuildChain;

  /// No description provided for @backupHealthRebuildNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Chain rebuild is not yet available.'**
  String get backupHealthRebuildNotAvailable;

  /// No description provided for @collectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collectionsTitle;

  /// No description provided for @collectionsNewCollection.
  ///
  /// In en, this message translates to:
  /// **'+ New Collection'**
  String get collectionsNewCollection;

  /// No description provided for @collectionsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Collection'**
  String get collectionsCreateTitle;

  /// No description provided for @collectionsChooseStarting.
  ///
  /// In en, this message translates to:
  /// **'Choose a starting point'**
  String get collectionsChooseStarting;

  /// No description provided for @collectionsChooseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start from scratch or pick a template.\nTap preview to explore before choosing.'**
  String get collectionsChooseSubtitle;

  /// No description provided for @collectionsRecommendedTemplates.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED TEMPLATES'**
  String get collectionsRecommendedTemplates;

  /// No description provided for @collectionsSearchResults.
  ///
  /// In en, this message translates to:
  /// **'SEARCH RESULTS'**
  String get collectionsSearchResults;

  /// No description provided for @collectionsNoTemplatesFound.
  ///
  /// In en, this message translates to:
  /// **'No templates found'**
  String get collectionsNoTemplatesFound;

  /// No description provided for @collectionsSearchTemplatesHint.
  ///
  /// In en, this message translates to:
  /// **'Search templates...'**
  String get collectionsSearchTemplatesHint;

  /// No description provided for @collectionBlockRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get collectionBlockRename;

  /// No description provided for @collectionBlockDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get collectionBlockDuplicate;

  /// No description provided for @collectionBlockLockWithPin.
  ///
  /// In en, this message translates to:
  /// **'Lock with PIN'**
  String get collectionBlockLockWithPin;

  /// No description provided for @collectionBlockMove.
  ///
  /// In en, this message translates to:
  /// **'Move to another collection'**
  String get collectionBlockMove;

  /// No description provided for @collectionListYours.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get collectionListYours;

  /// No description provided for @collectionListStartFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'Start from a template'**
  String get collectionListStartFromTemplate;

  /// No description provided for @collectionBlockDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get collectionBlockDelete;

  /// No description provided for @collectionBlockRenamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed successfully'**
  String get collectionBlockRenamed;

  /// No description provided for @collectionBlockDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Duplicated successfully'**
  String get collectionBlockDuplicated;

  /// No description provided for @collectionBlockDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get collectionBlockDeleted;

  /// No description provided for @collectionBlockRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get collectionBlockRenameHint;

  /// No description provided for @collectionBlockProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get collectionBlockProgress;

  /// No description provided for @collectionBlockProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Track progress toward a goal with a visual bar'**
  String get collectionBlockProgressDesc;

  /// No description provided for @collectionEntryProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'TITLE'**
  String get collectionEntryProgressTitle;

  /// No description provided for @collectionEntryProgressHintTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Payment plan, Savings goal'**
  String get collectionEntryProgressHintTitle;

  /// No description provided for @collectionEntryProgressCurrent.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get collectionEntryProgressCurrent;

  /// No description provided for @collectionEntryProgressCurrentOf.
  ///
  /// In en, this message translates to:
  /// **'CURRENT · OF {target}'**
  String collectionEntryProgressCurrentOf(String target);

  /// No description provided for @collectionEntryProgressTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get collectionEntryProgressTarget;

  /// No description provided for @collectionEntryProgressDue.
  ///
  /// In en, this message translates to:
  /// **'DUE'**
  String get collectionEntryProgressDue;

  /// No description provided for @collectionEntryProgressValues.
  ///
  /// In en, this message translates to:
  /// **'VALUES'**
  String get collectionEntryProgressValues;

  /// No description provided for @collectionEntryProgressType.
  ///
  /// In en, this message translates to:
  /// **'TYPE'**
  String get collectionEntryProgressType;

  /// No description provided for @collectionEntryProgressTypeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get collectionEntryProgressTypeCurrency;

  /// No description provided for @collectionEntryProgressTypeQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get collectionEntryProgressTypeQuantity;

  /// No description provided for @collectionEntryProgressTypeDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get collectionEntryProgressTypeDistance;

  /// No description provided for @collectionEntryProgressTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get collectionEntryProgressTypeCustom;

  /// No description provided for @collectionEntryProgressCustomUnit.
  ///
  /// In en, this message translates to:
  /// **'custom'**
  String get collectionEntryProgressCustomUnit;

  /// No description provided for @collectionEntryProgressCurrency.
  ///
  /// In en, this message translates to:
  /// **'CURRENCY (OPTIONAL)'**
  String get collectionEntryProgressCurrency;

  /// No description provided for @collectionEntryProgressUnit.
  ///
  /// In en, this message translates to:
  /// **'UNIT (OPTIONAL)'**
  String get collectionEntryProgressUnit;

  /// No description provided for @collectionEntryProgressUnitNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get collectionEntryProgressUnitNone;

  /// No description provided for @collectionEntryProgressUnitCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Or type a custom unit...'**
  String get collectionEntryProgressUnitCustomHint;

  /// No description provided for @collectionEntryProgressHintDesc.
  ///
  /// In en, this message translates to:
  /// **'Add notes about this tracker...'**
  String get collectionEntryProgressHintDesc;

  /// No description provided for @collectionEntryAddProgress.
  ///
  /// In en, this message translates to:
  /// **'Add Progress'**
  String get collectionEntryAddProgress;

  /// No description provided for @collectionEntryEditProgress.
  ///
  /// In en, this message translates to:
  /// **'Edit progress'**
  String get collectionEntryEditProgress;

  /// No description provided for @collectionEntrySaveProgress.
  ///
  /// In en, this message translates to:
  /// **'Save Progress'**
  String get collectionEntrySaveProgress;

  /// No description provided for @collectionDetailProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get collectionDetailProgressTitle;

  /// No description provided for @collectionsBlankTitle.
  ///
  /// In en, this message translates to:
  /// **'Blank Collection'**
  String get collectionsBlankTitle;

  /// No description provided for @collectionsBlankSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a clean slate'**
  String get collectionsBlankSubtitle;

  /// No description provided for @collectionsSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get collectionsSelected;

  /// No description provided for @collectionsSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get collectionsSelect;

  /// No description provided for @collectionsStep2of3.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3'**
  String get collectionsStep2of3;

  /// No description provided for @collectionsIncludedBlocks.
  ///
  /// In en, this message translates to:
  /// **'INCLUDED BLOCKS'**
  String get collectionsIncludedBlocks;

  /// No description provided for @collectionsUseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use This Template'**
  String get collectionsUseTemplate;

  /// No description provided for @collectionsAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get collectionsAccentColor;

  /// No description provided for @collectionsPickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a Color'**
  String get collectionsPickColor;

  /// No description provided for @collectionsNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Summer Destinations'**
  String get collectionsNameHint;

  /// No description provided for @collectionsNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a collection name.'**
  String get collectionsNameRequired;

  /// No description provided for @collectionsColorHint.
  ///
  /// In en, this message translates to:
  /// **'#FF5733'**
  String get collectionsColorHint;

  /// No description provided for @settingsExportPassphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Passphrase'**
  String get settingsExportPassphraseTitle;

  /// No description provided for @settingsExportPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Enter passphrase to encrypt export'**
  String get settingsExportPassphraseHint;

  /// No description provided for @settingsExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settingsExportButton;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and restore encrypted backups'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export your vault as a portable archive'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsDataSection.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get settingsDataSection;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCredentials.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get navCredentials;

  /// No description provided for @navDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get navDocuments;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navVault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get navVault;

  /// No description provided for @navDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get navDocs;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navMe;

  /// No description provided for @homeSmartReminders.
  ///
  /// In en, this message translates to:
  /// **'Smart Reminders'**
  String get homeSmartReminders;

  /// No description provided for @homeQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get homeQuickAccess;

  /// No description provided for @homeRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get homeRecentActivity;

  /// No description provided for @homeVaultInsights.
  ///
  /// In en, this message translates to:
  /// **'Vault Insights'**
  String get homeVaultInsights;

  /// No description provided for @homeEverythingGood.
  ///
  /// In en, this message translates to:
  /// **'Everything looks good'**
  String get homeEverythingGood;

  /// No description provided for @homeVaultUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Your vault is secure and up to date'**
  String get homeVaultUpToDate;

  /// No description provided for @homeVaultStatus.
  ///
  /// In en, this message translates to:
  /// **'Vault status'**
  String get homeVaultStatus;

  /// No description provided for @homeVaultAtGlance.
  ///
  /// In en, this message translates to:
  /// **'Vault at a glance'**
  String get homeVaultAtGlance;

  /// No description provided for @homeStatusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get homeStatusNeedsAttention;

  /// No description provided for @homeHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get homeHealthy;

  /// No description provided for @homeNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs your attention'**
  String get homeNeedsAttention;

  /// No description provided for @homeNoAttentionNeeded.
  ///
  /// In en, this message translates to:
  /// **'No attention needed'**
  String get homeNoAttentionNeeded;

  /// No description provided for @homeNoAttentionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your vault has no urgent reminders right now.'**
  String get homeNoAttentionSubtitle;

  /// No description provided for @homeAlerts.
  ///
  /// In en, this message translates to:
  /// **'alerts'**
  String get homeAlerts;

  /// No description provided for @homeItems.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get homeItems;

  /// No description provided for @homeIssues.
  ///
  /// In en, this message translates to:
  /// **'issues'**
  String get homeIssues;

  /// No description provided for @homeOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get homeOpen;

  /// No description provided for @homeOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'open tasks'**
  String get homeOpenTasks;

  /// No description provided for @homeBackupLocal.
  ///
  /// In en, this message translates to:
  /// **'Local backup'**
  String get homeBackupLocal;

  /// No description provided for @homeLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Local-first'**
  String get homeLocalOnly;

  /// No description provided for @homeQuickOpen.
  ///
  /// In en, this message translates to:
  /// **'Quick open'**
  String get homeQuickOpen;

  /// No description provided for @homePinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get homePinned;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

  /// No description provided for @homeLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get homeLastUpdated;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeSoonestFirst.
  ///
  /// In en, this message translates to:
  /// **'Soonest first'**
  String get homeSoonestFirst;

  /// No description provided for @homeRecentEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet'**
  String get homeRecentEmptyTitle;

  /// No description provided for @homeRecentEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Items you open or update will appear here.'**
  String get homeRecentEmptySubtitle;

  /// No description provided for @homeSetupEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'A calm place for your private things.'**
  String get homeSetupEmptyTitle;

  /// No description provided for @homeSetupEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first credential, document, collection, or task to start building your encrypted vault.'**
  String get homeSetupEmptySubtitle;

  /// No description provided for @homeAddFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add your first item'**
  String get homeAddFirstItem;

  /// No description provided for @homeUnableDashboard.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dashboard'**
  String get homeUnableDashboard;

  /// No description provided for @homeUnableDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading\nyour home screen.'**
  String get homeUnableDashboardSubtitle;

  /// No description provided for @homeTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get homeTryAgain;

  /// No description provided for @homePreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Preferences'**
  String get homePreferencesTitle;

  /// No description provided for @homeResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get homeResetDefaults;

  /// No description provided for @homeVisibleSections.
  ///
  /// In en, this message translates to:
  /// **'Visible Sections'**
  String get homeVisibleSections;

  /// No description provided for @homeCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get homeCategories;

  /// No description provided for @homeSmartRules.
  ///
  /// In en, this message translates to:
  /// **'Smart Rules'**
  String get homeSmartRules;

  /// No description provided for @homeExpiringDocuments.
  ///
  /// In en, this message translates to:
  /// **'Expiring Documents'**
  String get homeExpiringDocuments;

  /// No description provided for @homeMissingAttention.
  ///
  /// In en, this message translates to:
  /// **'Missing / Attention Required'**
  String get homeMissingAttention;

  /// No description provided for @homeRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently Updated'**
  String get homeRecentlyUpdated;

  /// No description provided for @homeSourceCredential.
  ///
  /// In en, this message translates to:
  /// **'Credential'**
  String get homeSourceCredential;

  /// No description provided for @homeSourceDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get homeSourceDocument;

  /// No description provided for @homeSourceCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get homeSourceCollection;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search your vault'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search vault...'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResults;

  /// No description provided for @searchNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get searchNoResultsSubtitle;

  /// No description provided for @searchFindAll.
  ///
  /// In en, this message translates to:
  /// **'Find credentials, documents, and collections'**
  String get searchFindAll;

  /// No description provided for @searchCredentials.
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get searchCredentials;

  /// No description provided for @searchDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get searchDocuments;

  /// No description provided for @searchCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get searchCollections;

  /// No description provided for @authEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get authEnterPin;

  /// No description provided for @authEnterPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your 6-digit PIN to unlock'**
  String get authEnterPinSubtitle;

  /// No description provided for @authIncorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Try again.'**
  String get authIncorrectPin;

  /// No description provided for @authCreatePin.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN'**
  String get authCreatePin;

  /// No description provided for @authConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get authConfirmPin;

  /// No description provided for @authCreatePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a 6-digit PIN to secure your vault'**
  String get authCreatePinSubtitle;

  /// No description provided for @authConfirmPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-enter the same 6-digit PIN'**
  String get authConfirmPinSubtitle;

  /// No description provided for @authPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs didn\'t match. Try again.'**
  String get authPinMismatch;

  /// No description provided for @authEnableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Unlock?'**
  String get authEnableBiometric;

  /// No description provided for @authBiometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID or fingerprint to unlock your vault quickly.'**
  String get authBiometricSubtitle;

  /// No description provided for @authBiometricEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get authBiometricEnable;

  /// No description provided for @authBiometricSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get authBiometricSkip;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Your Secure Vault'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Store credentials, documents, and collections in one encrypted place. Everything stays on your device.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Smart Documents'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Scan and organize IDs, contracts, and records with automatic categorization and expiry tracking.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Powerful Collections'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Plan trips, track projects, manage budgets — with checklists, timelines, expenses, and reminders.'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Backups'**
  String get onboardingTitle4;

  /// No description provided for @onboardingSubtitle4.
  ///
  /// In en, this message translates to:
  /// **'Back up to Dropbox or Google Drive with AES-256 encryption. Restore anytime, on any device.'**
  String get onboardingSubtitle4;

  /// No description provided for @editCollection.
  ///
  /// In en, this message translates to:
  /// **'Edit Collection'**
  String get editCollection;

  /// No description provided for @preparingExport.
  ///
  /// In en, this message translates to:
  /// **'Preparing export...'**
  String get preparingExport;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @settingsLockTimeoutUpdated.
  ///
  /// In en, this message translates to:
  /// **'Lock timeout updated'**
  String get settingsLockTimeoutUpdated;

  /// No description provided for @settingsPinUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN updated successfully'**
  String get settingsPinUpdatedSuccessfully;

  /// No description provided for @settingsIncorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get settingsIncorrectPin;

  /// No description provided for @settingsBiometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock enabled'**
  String get settingsBiometricEnabled;

  /// No description provided for @settingsBiometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock disabled'**
  String get settingsBiometricDisabled;

  /// No description provided for @scanTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanTakePhoto;

  /// No description provided for @scanChooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get scanChooseFromLibrary;

  /// No description provided for @scanRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get scanRetake;

  /// No description provided for @generatorUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get generatorUse;

  /// No description provided for @generatorNavVaults.
  ///
  /// In en, this message translates to:
  /// **'Vaults'**
  String get generatorNavVaults;

  /// No description provided for @generatorNavPasswords.
  ///
  /// In en, this message translates to:
  /// **'Passwords'**
  String get generatorNavPasswords;

  /// No description provided for @generatorNavSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get generatorNavSecurity;

  /// No description provided for @generatorNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get generatorNavSettings;

  /// No description provided for @generatorSideMyPasswords.
  ///
  /// In en, this message translates to:
  /// **'My Passwords'**
  String get generatorSideMyPasswords;

  /// No description provided for @generatorSideGenerator.
  ///
  /// In en, this message translates to:
  /// **'Generator'**
  String get generatorSideGenerator;

  /// No description provided for @generatorSideSecurityAudit.
  ///
  /// In en, this message translates to:
  /// **'Security Audit'**
  String get generatorSideSecurityAudit;

  /// No description provided for @generatorSideHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get generatorSideHistory;

  /// No description provided for @generatorCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get generatorCopy;

  /// No description provided for @generatorGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generatorGenerating;

  /// No description provided for @generatorRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get generatorRegenerate;

  /// No description provided for @generatorStrengthLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD STRENGTH'**
  String get generatorStrengthLabel;

  /// No description provided for @generatorSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search entries...'**
  String get generatorSearchHint;

  /// No description provided for @generatorRuleUppercaseLetters.
  ///
  /// In en, this message translates to:
  /// **'Uppercase Letters'**
  String get generatorRuleUppercaseLetters;

  /// No description provided for @generatorRuleLowercaseLetters.
  ///
  /// In en, this message translates to:
  /// **'Lowercase Letters'**
  String get generatorRuleLowercaseLetters;

  /// No description provided for @generatorRuleIncludeNumbers.
  ///
  /// In en, this message translates to:
  /// **'Include Numbers'**
  String get generatorRuleIncludeNumbers;

  /// No description provided for @generatorRuleIncludeSymbols.
  ///
  /// In en, this message translates to:
  /// **'Include Symbols'**
  String get generatorRuleIncludeSymbols;

  /// No description provided for @generatorMobileRuleUppercase.
  ///
  /// In en, this message translates to:
  /// **'Uppercase (A-Z)'**
  String get generatorMobileRuleUppercase;

  /// No description provided for @generatorMobileRuleLowercase.
  ///
  /// In en, this message translates to:
  /// **'Lowercase (a-z)'**
  String get generatorMobileRuleLowercase;

  /// No description provided for @generatorMobileRuleNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers (0-9)'**
  String get generatorMobileRuleNumbers;

  /// No description provided for @generatorMobileRuleSymbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols (!@#\$)'**
  String get generatorMobileRuleSymbols;

  /// No description provided for @generatorMetricEntropy.
  ///
  /// In en, this message translates to:
  /// **'Entropy Score'**
  String get generatorMetricEntropy;

  /// No description provided for @generatorMetricEntropyDesc.
  ///
  /// In en, this message translates to:
  /// **'A measure of how unpredictable your password is.'**
  String get generatorMetricEntropyDesc;

  /// No description provided for @generatorMetricCrackTime.
  ///
  /// In en, this message translates to:
  /// **'Crack Time'**
  String get generatorMetricCrackTime;

  /// No description provided for @generatorMetricCrackTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Estimated brute-force crack time with modern hardware.'**
  String get generatorMetricCrackTimeDesc;

  /// No description provided for @generatorMetricEasyToType.
  ///
  /// In en, this message translates to:
  /// **'Easy to Type'**
  String get generatorMetricEasyToType;

  /// No description provided for @generatorMetricEasyToTypeDesc.
  ///
  /// In en, this message translates to:
  /// **'Balanced distribution for manual typing if needed.'**
  String get generatorMetricEasyToTypeDesc;

  /// No description provided for @collectionFieldTypeShortText.
  ///
  /// In en, this message translates to:
  /// **'Short Text'**
  String get collectionFieldTypeShortText;

  /// No description provided for @collectionFieldTypeNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get collectionFieldTypeNumber;

  /// No description provided for @collectionFieldTypeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get collectionFieldTypeDate;

  /// No description provided for @collectionFieldTypePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get collectionFieldTypePhone;

  /// No description provided for @collectionEventTypeMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get collectionEventTypeMilestone;

  /// No description provided for @collectionEventTypeDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get collectionEventTypeDeadline;

  /// No description provided for @collectionEventTypeReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get collectionEventTypeReminder;

  /// No description provided for @collectionDocCategoryIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get collectionDocCategoryIdentity;

  /// No description provided for @collectionDocCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get collectionDocCategoryTravel;

  /// No description provided for @collectionDocCategoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get collectionDocCategoryFinance;

  /// No description provided for @collectionDocCategoryPropertyLease.
  ///
  /// In en, this message translates to:
  /// **'Property · Lease'**
  String get collectionDocCategoryPropertyLease;

  /// No description provided for @collectionDocCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get collectionDocCategoryOther;

  /// No description provided for @collectionNoteCategoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get collectionNoteCategoryPersonal;

  /// No description provided for @collectionNoteCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get collectionNoteCategoryWork;

  /// No description provided for @collectionExpenseCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get collectionExpenseCategoryTransport;

  /// No description provided for @collectionExpenseCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get collectionExpenseCategoryFood;

  /// No description provided for @collectionExpenseCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get collectionExpenseCategoryShopping;

  /// No description provided for @collectionExpenseCategoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get collectionExpenseCategoryRent;

  /// No description provided for @collectionExpenseCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get collectionExpenseCategoryOther;

  /// No description provided for @collectionFileTypeDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get collectionFileTypeDocuments;

  /// No description provided for @collectionFileTypeImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get collectionFileTypeImages;

  /// No description provided for @collectionFileTypeAllFiles.
  ///
  /// In en, this message translates to:
  /// **'All Files'**
  String get collectionFileTypeAllFiles;

  /// No description provided for @collectionEntryTapToEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Tap to enter amount'**
  String get collectionEntryTapToEnterAmount;

  /// No description provided for @collectionEntryHintNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note Title'**
  String get collectionEntryHintNoteTitle;

  /// No description provided for @collectionEntryHintReminderExample.
  ///
  /// In en, this message translates to:
  /// **'Renew passport'**
  String get collectionEntryHintReminderExample;

  /// No description provided for @collectionEntryAddAnotherTask.
  ///
  /// In en, this message translates to:
  /// **'Add another task...'**
  String get collectionEntryAddAnotherTask;

  /// No description provided for @collectionEntryAddChecklistItem.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get collectionEntryAddChecklistItem;

  /// No description provided for @collectionEntryChecklistReorder.
  ///
  /// In en, this message translates to:
  /// **'REORDER'**
  String get collectionEntryChecklistReorder;

  /// No description provided for @collectionEntryChecklistItemsSummary.
  ///
  /// In en, this message translates to:
  /// **'ITEMS · {total} · {done} OF {total} DONE'**
  String collectionEntryChecklistItemsSummary(int total, int done);

  /// No description provided for @collectionEntryUnitFloor.
  ///
  /// In en, this message translates to:
  /// **'Unit / Floor'**
  String get collectionEntryUnitFloor;

  /// No description provided for @collectionEntryOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get collectionEntryOptional;

  /// No description provided for @collectionEntryWhatWasThisFor.
  ///
  /// In en, this message translates to:
  /// **'What was this for?'**
  String get collectionEntryWhatWasThisFor;

  /// No description provided for @collectionTemplateTravelPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Planner'**
  String get collectionTemplateTravelPlannerTitle;

  /// No description provided for @collectionTemplateTravelPlannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize flights, hotels, and itineraries'**
  String get collectionTemplateTravelPlannerDesc;

  /// No description provided for @collectionTemplateWeddingPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Wedding Planner'**
  String get collectionTemplateWeddingPlannerTitle;

  /// No description provided for @collectionTemplateWeddingPlannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Plan your perfect day with vendors, guests, and timelines'**
  String get collectionTemplateWeddingPlannerDesc;

  /// No description provided for @collectionTemplateBudgetPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Planner'**
  String get collectionTemplateBudgetPlannerTitle;

  /// No description provided for @collectionTemplateBudgetPlannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Track income, expenses, and savings goals'**
  String get collectionTemplateBudgetPlannerDesc;

  /// No description provided for @collectionTemplateEventPlanningTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Planning'**
  String get collectionTemplateEventPlanningTitle;

  /// No description provided for @collectionTemplateEventPlanningDesc.
  ///
  /// In en, this message translates to:
  /// **'Plan parties and gatherings with vendors and timelines'**
  String get collectionTemplateEventPlanningDesc;

  /// No description provided for @collectionTemplateProjectPlanningTitle.
  ///
  /// In en, this message translates to:
  /// **'Project Planning'**
  String get collectionTemplateProjectPlanningTitle;

  /// No description provided for @collectionTemplateProjectPlanningDesc.
  ///
  /// In en, this message translates to:
  /// **'Roadmaps, tasks, and resource allocation'**
  String get collectionTemplateProjectPlanningDesc;

  /// No description provided for @collectionTemplateFreelanceTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Freelance Tracker'**
  String get collectionTemplateFreelanceTrackerTitle;

  /// No description provided for @collectionTemplateFreelanceTrackerDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage clients, invoices, and project deliverables'**
  String get collectionTemplateFreelanceTrackerDesc;

  /// No description provided for @collectionTemplateHomeRenovationTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Renovation'**
  String get collectionTemplateHomeRenovationTitle;

  /// No description provided for @collectionTemplateHomeRenovationDesc.
  ///
  /// In en, this message translates to:
  /// **'Plan remodels with contractors, budgets, and timelines'**
  String get collectionTemplateHomeRenovationDesc;

  /// No description provided for @collectionTemplateStudyPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Planner'**
  String get collectionTemplateStudyPlannerTitle;

  /// No description provided for @collectionTemplateStudyPlannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize courses, exams, and study sessions'**
  String get collectionTemplateStudyPlannerDesc;

  /// No description provided for @collectionTemplateFitnessTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Fitness Tracker'**
  String get collectionTemplateFitnessTrackerTitle;

  /// No description provided for @collectionTemplateFitnessTrackerDesc.
  ///
  /// In en, this message translates to:
  /// **'Track workouts, nutrition, and fitness goals'**
  String get collectionTemplateFitnessTrackerDesc;

  /// No description provided for @collectionTemplateRecipeBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe Book'**
  String get collectionTemplateRecipeBookTitle;

  /// No description provided for @collectionTemplateRecipeBookDesc.
  ///
  /// In en, this message translates to:
  /// **'Save favorite recipes and grocery lists'**
  String get collectionTemplateRecipeBookDesc;

  /// No description provided for @collectionTemplateJobSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Search'**
  String get collectionTemplateJobSearchTitle;

  /// No description provided for @collectionTemplateJobSearchDesc.
  ///
  /// In en, this message translates to:
  /// **'Track applications, interviews, and opportunities'**
  String get collectionTemplateJobSearchDesc;

  /// No description provided for @collectionTemplatePropertyManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Property Management'**
  String get collectionTemplatePropertyManagementTitle;

  /// No description provided for @collectionTemplatePropertyManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Track listings, maintenance, and tenants'**
  String get collectionTemplatePropertyManagementDesc;

  /// No description provided for @collectionTemplateMovingChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Moving Checklist'**
  String get collectionTemplateMovingChecklistTitle;

  /// No description provided for @collectionTemplateMovingChecklistDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize packing, utilities, and timelines'**
  String get collectionTemplateMovingChecklistDesc;

  /// No description provided for @collectionTemplatePetCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet Care'**
  String get collectionTemplatePetCareTitle;

  /// No description provided for @collectionTemplatePetCareDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage vet visits, vaccinations, and health records'**
  String get collectionTemplatePetCareDesc;

  /// No description provided for @collectionTemplateVehicleMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Maintenance'**
  String get collectionTemplateVehicleMaintenanceTitle;

  /// No description provided for @collectionTemplateVehicleMaintenanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Track service history, expenses, and schedules'**
  String get collectionTemplateVehicleMaintenanceDesc;

  /// No description provided for @collectionTemplateDiplomasCertificatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Diplomas & Certificates'**
  String get collectionTemplateDiplomasCertificatesTitle;

  /// No description provided for @collectionTemplateDiplomasCertificatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize degrees, transcripts, and professional certifications'**
  String get collectionTemplateDiplomasCertificatesDesc;

  /// No description provided for @collectionTemplateBankDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Documents (RIB)'**
  String get collectionTemplateBankDocumentsTitle;

  /// No description provided for @collectionTemplateBankDocumentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Store RIB, IBAN, account details, and monthly statements'**
  String get collectionTemplateBankDocumentsDesc;

  /// No description provided for @collectionTemplateHealthRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Records'**
  String get collectionTemplateHealthRecordsTitle;

  /// No description provided for @collectionTemplateHealthRecordsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track vaccinations, allergies, doctor visits, and insurance'**
  String get collectionTemplateHealthRecordsDesc;

  /// No description provided for @collectionTemplateTaxDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax Documents'**
  String get collectionTemplateTaxDocumentsTitle;

  /// No description provided for @collectionTemplateTaxDocumentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Organize tax returns, receipts, deductions, and filing deadlines'**
  String get collectionTemplateTaxDocumentsDesc;

  /// No description provided for @collectionTemplateTagPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get collectionTemplateTagPopular;

  /// No description provided for @collectionTemplateTagNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get collectionTemplateTagNew;

  /// No description provided for @collectionTemplatePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get collectionTemplatePreview;

  /// No description provided for @collectionTemplateBlocksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} blocks'**
  String collectionTemplateBlocksCount(int count);

  /// No description provided for @workCompanyEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Company'**
  String get workCompanyEditTitle;

  /// No description provided for @workCompanyAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Company'**
  String get workCompanyAddTitle;

  /// No description provided for @workCompanyFieldRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get workCompanyFieldRole;

  /// No description provided for @workCompanyFieldEntryDate.
  ///
  /// In en, this message translates to:
  /// **'Entry Date'**
  String get workCompanyFieldEntryDate;

  /// No description provided for @workCompanyFieldEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date (Optional)'**
  String get workCompanyFieldEndDate;

  /// No description provided for @workCompanyFieldContact.
  ///
  /// In en, this message translates to:
  /// **'Primary Contact'**
  String get workCompanyFieldContact;

  /// No description provided for @workCompanyHintContact.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number'**
  String get workCompanyHintContact;

  /// No description provided for @workCompanyHintLocation.
  ///
  /// In en, this message translates to:
  /// **'City, Country'**
  String get workCompanyHintLocation;

  /// No description provided for @workCompanyStatusOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get workCompanyStatusOngoing;

  /// No description provided for @workCompanyStatusFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get workCompanyStatusFixed;

  /// No description provided for @workCompanyPreviewMap.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW MAP'**
  String get workCompanyPreviewMap;

  /// No description provided for @workCompanyAutoDetectLogo.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect logo'**
  String get workCompanyAutoDetectLogo;

  /// No description provided for @workCompanyUploadManually.
  ///
  /// In en, this message translates to:
  /// **'Or upload manually (PNG, JPG up to 5MB)'**
  String get workCompanyUploadManually;

  /// No description provided for @commonTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get commonTakePhoto;

  /// No description provided for @commonChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get commonChooseFromGallery;

  /// No description provided for @commonBrowseFiles.
  ///
  /// In en, this message translates to:
  /// **'Browse files'**
  String get commonBrowseFiles;

  /// No description provided for @credentialDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Credential'**
  String get credentialDeleteAction;

  /// No description provided for @credentialDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete credential'**
  String get credentialDeleteFailed;

  /// No description provided for @reminderActionRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renewal Needed'**
  String get reminderActionRenewal;

  /// No description provided for @reminderActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get reminderActionRequired;

  /// No description provided for @reminderActionUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload Now'**
  String get reminderActionUpload;

  /// No description provided for @reminderActionViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get reminderActionViewDetails;

  /// No description provided for @backupNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get backupNotConnected;

  /// No description provided for @backupUploadGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Upload All to Google Drive'**
  String get backupUploadGoogleDrive;

  /// No description provided for @backupUploadDropbox.
  ///
  /// In en, this message translates to:
  /// **'Upload All to Dropbox'**
  String get backupUploadDropbox;

  /// No description provided for @backupConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get backupConnecting;

  /// No description provided for @backupAuthorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get backupAuthorize;

  /// No description provided for @settingsHintPinDigits.
  ///
  /// In en, this message translates to:
  /// **'6-digit PIN'**
  String get settingsHintPinDigits;

  /// No description provided for @settingsVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get settingsVerify;

  /// No description provided for @settingsWipeEverything.
  ///
  /// In en, this message translates to:
  /// **'Wipe Everything'**
  String get settingsWipeEverything;

  /// No description provided for @settingsExportFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String settingsExportFailedWithError(String error);

  /// No description provided for @idCardRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get idCardRescan;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System, Light, or Dark'**
  String get settingsThemeSubtitle;

  /// No description provided for @settingsAutoLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-Lock Timeout'**
  String get settingsAutoLockTitle;

  /// No description provided for @settingsAutoLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock vault after inactivity'**
  String get settingsAutoLockSubtitle;

  /// No description provided for @settingsChangePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settingsChangePinTitle;

  /// No description provided for @settingsChangePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your 6-digit vault PIN'**
  String get settingsChangePinSubtitle;

  /// No description provided for @settingsBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get settingsBiometricTitle;

  /// No description provided for @settingsBiometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Toggle Face ID / fingerprint'**
  String get settingsBiometricSubtitle;

  /// No description provided for @settingsWipeVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Wipe Vault'**
  String get settingsWipeVaultTitle;

  /// No description provided for @settingsWipeVaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete all data'**
  String get settingsWipeVaultSubtitle;

  /// No description provided for @settingsWipeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Wipe All Data?'**
  String get settingsWipeDialogTitle;

  /// No description provided for @settingsWipeDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL vault data including credentials, documents, collections, backups, and your PIN. This action cannot be undone.'**
  String get settingsWipeDialogContent;

  /// No description provided for @settingsLockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get settingsLockImmediately;

  /// No description provided for @settingsLockNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get settingsLockNever;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsBiometricEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsBiometricEnabledLabel;

  /// No description provided for @settingsBiometricEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics + PIN fallback'**
  String get settingsBiometricEnabledSubtitle;

  /// No description provided for @settingsBiometricDisabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always require your 6-digit PIN'**
  String get settingsBiometricDisabledSubtitle;

  /// No description provided for @travelUnableLoadEvent.
  ///
  /// In en, this message translates to:
  /// **'Unable to load timeline event'**
  String get travelUnableLoadEvent;

  /// No description provided for @scanPassportTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Passport'**
  String get scanPassportTitle;

  /// No description provided for @travelHintEventTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flight to Paris'**
  String get travelHintEventTitle;

  /// No description provided for @travelHintSearchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get travelHintSearchLocation;

  /// No description provided for @travelFieldDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get travelFieldDeparture;

  /// No description provided for @travelFieldArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get travelFieldArrival;

  /// No description provided for @travelFieldAirlineProvider.
  ///
  /// In en, this message translates to:
  /// **'Airline / Provider'**
  String get travelFieldAirlineProvider;

  /// No description provided for @travelFieldFlightNo.
  ///
  /// In en, this message translates to:
  /// **'Flight No.'**
  String get travelFieldFlightNo;

  /// No description provided for @travelFieldSeat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get travelFieldSeat;

  /// No description provided for @travelFieldTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get travelFieldTerminal;

  /// No description provided for @travelFieldGate.
  ///
  /// In en, this message translates to:
  /// **'Gate'**
  String get travelFieldGate;

  /// No description provided for @travelHintBookingRef.
  ///
  /// In en, this message translates to:
  /// **'e.g. AF12345'**
  String get travelHintBookingRef;

  /// No description provided for @travelHintHotelName.
  ///
  /// In en, this message translates to:
  /// **'Grand Hyatt Tokyo'**
  String get travelHintHotelName;

  /// No description provided for @travelFieldReservationNo.
  ///
  /// In en, this message translates to:
  /// **'Reservation No.'**
  String get travelFieldReservationNo;

  /// No description provided for @travelFieldBookingPlatform.
  ///
  /// In en, this message translates to:
  /// **'Booking Platform'**
  String get travelFieldBookingPlatform;

  /// No description provided for @travelFieldRoomType.
  ///
  /// In en, this message translates to:
  /// **'Room Type'**
  String get travelFieldRoomType;

  /// No description provided for @travelFieldGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get travelFieldGuests;

  /// No description provided for @travelFieldTotalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get travelFieldTotalPrice;

  /// No description provided for @travelFieldCuisineType.
  ///
  /// In en, this message translates to:
  /// **'Cuisine type'**
  String get travelFieldCuisineType;

  /// No description provided for @travelFieldEstimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost'**
  String get travelFieldEstimatedCost;

  /// No description provided for @travelFieldActivityType.
  ///
  /// In en, this message translates to:
  /// **'Activity Type'**
  String get travelFieldActivityType;

  /// No description provided for @travelFieldOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get travelFieldOrganizer;

  /// No description provided for @travelFieldParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get travelFieldParticipants;

  /// No description provided for @travelFieldTicketPrice.
  ///
  /// In en, this message translates to:
  /// **'Ticket Price'**
  String get travelFieldTicketPrice;

  /// No description provided for @travelFieldBookingReference.
  ///
  /// In en, this message translates to:
  /// **'Booking Reference'**
  String get travelFieldBookingReference;

  /// No description provided for @travelFieldReservationType.
  ///
  /// In en, this message translates to:
  /// **'Reservation Type'**
  String get travelFieldReservationType;

  /// No description provided for @travelFieldProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get travelFieldProvider;

  /// No description provided for @travelFieldPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get travelFieldPickupLocation;

  /// No description provided for @travelFieldReservationNumber.
  ///
  /// In en, this message translates to:
  /// **'Reservation Number'**
  String get travelFieldReservationNumber;

  /// No description provided for @travelFieldVehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle / Item Details'**
  String get travelFieldVehicleDetails;

  /// No description provided for @travelFieldPriceDeposit.
  ///
  /// In en, this message translates to:
  /// **'Price / Deposit'**
  String get travelFieldPriceDeposit;

  /// No description provided for @travelHintNotes.
  ///
  /// In en, this message translates to:
  /// **'Add confirmation codes, meeting points or details...'**
  String get travelHintNotes;

  /// No description provided for @travelHintExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dinner in Tokyo'**
  String get travelHintExpenseTitle;

  /// No description provided for @travelHintAdditionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Add additional details here...'**
  String get travelHintAdditionalDetails;

  /// No description provided for @travelFieldSelectType.
  ///
  /// In en, this message translates to:
  /// **'Select type'**
  String get travelFieldSelectType;

  /// No description provided for @travelHintDocTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g. Boarding pass NH212'**
  String get travelHintDocTitle;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @travelHintBookingNotes.
  ///
  /// In en, this message translates to:
  /// **'Add additional notes or booking details'**
  String get travelHintBookingNotes;

  /// No description provided for @propertyTypeApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get propertyTypeApartment;

  /// No description provided for @propertyTypeSingleFamily.
  ///
  /// In en, this message translates to:
  /// **'Single Family House'**
  String get propertyTypeSingleFamily;

  /// No description provided for @propertyTypeCondo.
  ///
  /// In en, this message translates to:
  /// **'Condo'**
  String get propertyTypeCondo;

  /// No description provided for @propertyTypeTownhouse.
  ///
  /// In en, this message translates to:
  /// **'Townhouse'**
  String get propertyTypeTownhouse;

  /// No description provided for @propertyTypeMultiFamily.
  ///
  /// In en, this message translates to:
  /// **'Multi-Family'**
  String get propertyTypeMultiFamily;

  /// No description provided for @propertyTypePenthouse.
  ///
  /// In en, this message translates to:
  /// **'Penthouse'**
  String get propertyTypePenthouse;

  /// No description provided for @propertyTypeVacationHome.
  ///
  /// In en, this message translates to:
  /// **'Vacation Home'**
  String get propertyTypeVacationHome;

  /// No description provided for @propertyTypeLand.
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get propertyTypeLand;

  /// No description provided for @propertyTypeCommercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get propertyTypeCommercial;

  /// No description provided for @settingsImportVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Vault Data'**
  String get settingsImportVaultTitle;

  /// No description provided for @settingsImportVaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from a .zip export file'**
  String get settingsImportVaultSubtitle;

  /// No description provided for @settingsImportPasswordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Passwords'**
  String get settingsImportPasswordsTitle;

  /// No description provided for @settingsImportPasswordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From Chrome, Safari, 1Password, Bitwarden or LastPass'**
  String get settingsImportPasswordsSubtitle;

  /// No description provided for @macMenuFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get macMenuFile;

  /// No description provided for @macMenuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get macMenuEdit;

  /// No description provided for @macMenuView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get macMenuView;

  /// No description provided for @macMenuVault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get macMenuVault;

  /// No description provided for @macMenuNewCredential.
  ///
  /// In en, this message translates to:
  /// **'New Credential'**
  String get macMenuNewCredential;

  /// No description provided for @macMenuNewCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get macMenuNewCollection;

  /// No description provided for @macMenuImportVault.
  ///
  /// In en, this message translates to:
  /// **'Import Vault...'**
  String get macMenuImportVault;

  /// No description provided for @macMenuExportVault.
  ///
  /// In en, this message translates to:
  /// **'Export Vault...'**
  String get macMenuExportVault;

  /// No description provided for @macMenuCloseWindow.
  ///
  /// In en, this message translates to:
  /// **'Close Window'**
  String get macMenuCloseWindow;

  /// No description provided for @macMenuCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get macMenuCopy;

  /// No description provided for @macMenuPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get macMenuPaste;

  /// No description provided for @macMenuSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get macMenuSelectAll;

  /// No description provided for @macMenuFind.
  ///
  /// In en, this message translates to:
  /// **'Find...'**
  String get macMenuFind;

  /// No description provided for @macMenuToggleSidebar.
  ///
  /// In en, this message translates to:
  /// **'Toggle Sidebar'**
  String get macMenuToggleSidebar;

  /// No description provided for @macMenuLockVault.
  ///
  /// In en, this message translates to:
  /// **'Lock Vault'**
  String get macMenuLockVault;

  /// No description provided for @macMenuSearchVault.
  ///
  /// In en, this message translates to:
  /// **'Search Vault'**
  String get macMenuSearchVault;

  /// No description provided for @macMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings...'**
  String get macMenuSettings;

  /// No description provided for @dropboxSessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Dropbox session expired'**
  String get dropboxSessionExpiredTitle;

  /// No description provided for @dropboxSessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Dropbox connection has expired. Please reconnect to continue syncing your backups.'**
  String get dropboxSessionExpiredMessage;

  /// No description provided for @settingsImportPassphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Export Passphrase'**
  String get settingsImportPassphraseTitle;

  /// No description provided for @settingsImportPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Passphrase used during export'**
  String get settingsImportPassphraseHint;

  /// No description provided for @settingsImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Vault data imported successfully'**
  String get settingsImportSuccess;

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import vault data'**
  String get settingsImportFailed;

  /// No description provided for @settingsImportInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid or corrupted file'**
  String get settingsImportInvalidFile;

  /// No description provided for @settingsImportAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settingsImportAction;

  /// No description provided for @lockScreenTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts'**
  String get lockScreenTooManyAttempts;

  /// No description provided for @lockScreenTryAgainIn.
  ///
  /// In en, this message translates to:
  /// **'Try again in {time}'**
  String lockScreenTryAgainIn(String time);

  /// No description provided for @lockScreenAttemptsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} attempts remaining before lockout'**
  String lockScreenAttemptsRemaining(int count);

  /// No description provided for @scanIdentityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get scanIdentityVerification;

  /// No description provided for @scanAdjustDocument.
  ///
  /// In en, this message translates to:
  /// **'Adjust Document'**
  String get scanAdjustDocument;

  /// No description provided for @addDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Document'**
  String get addDocumentTitle;

  /// No description provided for @addDocumentPassportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Passports and travel IDs'**
  String get addDocumentPassportSubtitle;

  /// No description provided for @addDocumentIdCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'National ID and identity cards'**
  String get addDocumentIdCardSubtitle;

  /// No description provided for @addDocumentDriversLicenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s licenses'**
  String get addDocumentDriversLicenseSubtitle;

  /// No description provided for @addDocumentOtherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Any other document type'**
  String get addDocumentOtherSubtitle;

  /// No description provided for @addDocumentSelectType.
  ///
  /// In en, this message translates to:
  /// **'SELECT DOCUMENT TYPE'**
  String get addDocumentSelectType;

  /// No description provided for @addDocumentInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a document type to continue to manual entry and smart scan autofill.'**
  String get addDocumentInfoHint;

  /// No description provided for @addDocumentSecurityFooter.
  ///
  /// In en, this message translates to:
  /// **'Your documents are encrypted and secure'**
  String get addDocumentSecurityFooter;

  /// No description provided for @idCardFrontSide.
  ///
  /// In en, this message translates to:
  /// **'Front Side'**
  String get idCardFrontSide;

  /// No description provided for @idCardBackSide.
  ///
  /// In en, this message translates to:
  /// **'Back Side'**
  String get idCardBackSide;

  /// No description provided for @credentialEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your accounts'**
  String get credentialEmptyTitle;

  /// No description provided for @credentialEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Store your passwords and credentials safely, encrypted and offline on your device.'**
  String get credentialEmptySubtitle;

  /// No description provided for @credentialEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Add Credential'**
  String get credentialEmptyAction;

  /// No description provided for @settingsRevealAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reveal Protection'**
  String get settingsRevealAuthTitle;

  /// No description provided for @settingsRevealAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require PIN or biometrics to see passwords'**
  String get settingsRevealAuthSubtitle;

  /// No description provided for @settingsRevealAuthEnabled.
  ///
  /// In en, this message translates to:
  /// **'Password reveal protection enabled'**
  String get settingsRevealAuthEnabled;

  /// No description provided for @settingsRevealAuthEnabledDetail.
  ///
  /// In en, this message translates to:
  /// **'PIN or biometrics required before revealing any password'**
  String get settingsRevealAuthEnabledDetail;

  /// No description provided for @settingsRevealAuthDisabled.
  ///
  /// In en, this message translates to:
  /// **'Password reveal protection disabled'**
  String get settingsRevealAuthDisabled;

  /// No description provided for @settingsRevealAuthDisabledDetail.
  ///
  /// In en, this message translates to:
  /// **'Passwords can be revealed freely without additional authentication'**
  String get settingsRevealAuthDisabledDetail;

  /// No description provided for @revealAuthPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to reveal'**
  String get revealAuthPinTitle;

  /// No description provided for @revealAuthPinHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit PIN'**
  String get revealAuthPinHint;

  /// No description provided for @revealAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get revealAuthFailed;

  /// No description provided for @secureNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Notes'**
  String get secureNotesTitle;

  /// No description provided for @secureNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted personal notes'**
  String get secureNotesSubtitle;

  /// No description provided for @secureNotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get secureNotesEmpty;

  /// No description provided for @secureNotesAdd.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get secureNotesAdd;

  /// No description provided for @noteEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get noteEditorTitle;

  /// No description provided for @noteEditorTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Note title'**
  String get noteEditorTitleHint;

  /// No description provided for @noteEditorContentHint.
  ///
  /// In en, this message translates to:
  /// **'Write your note...'**
  String get noteEditorContentHint;

  /// No description provided for @noteCategoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get noteCategoryPersonal;

  /// No description provided for @noteCategoryFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get noteCategoryFinancial;

  /// No description provided for @noteCategoryLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get noteCategoryLegal;

  /// No description provided for @noteCategoryMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get noteCategoryMedical;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @expiryNotification90Days.
  ///
  /// In en, this message translates to:
  /// **'Your {title} expires in 3 months'**
  String expiryNotification90Days(String title);

  /// No description provided for @expiryNotification30Days.
  ///
  /// In en, this message translates to:
  /// **'Your {title} expires in 30 days'**
  String expiryNotification30Days(String title);

  /// No description provided for @expiryNotification7Days.
  ///
  /// In en, this message translates to:
  /// **'Your {title} expires next week'**
  String expiryNotification7Days(String title);

  /// No description provided for @expiryNotificationExpired.
  ///
  /// In en, this message translates to:
  /// **'Your {title} has expired'**
  String expiryNotificationExpired(String title);

  /// No description provided for @collectionPinLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Collection PIN'**
  String get collectionPinLockTitle;

  /// No description provided for @collectionPinSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Collection PIN'**
  String get collectionPinSetTitle;

  /// No description provided for @collectionPinHint.
  ///
  /// In en, this message translates to:
  /// **'4-digit PIN'**
  String get collectionPinHint;

  /// No description provided for @collectionPinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get collectionPinIncorrect;

  /// No description provided for @collectionPinEnabled.
  ///
  /// In en, this message translates to:
  /// **'Collection locked'**
  String get collectionPinEnabled;

  /// No description provided for @collectionPinDisabled.
  ///
  /// In en, this message translates to:
  /// **'Collection unlocked'**
  String get collectionPinDisabled;

  /// No description provided for @breachWarningBadge.
  ///
  /// In en, this message translates to:
  /// **'Breached'**
  String get breachWarningBadge;

  /// No description provided for @breachWarningDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} times in known breaches'**
  String breachWarningDetail(int count);

  /// No description provided for @credentialFavoriteAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get credentialFavoriteAdded;

  /// No description provided for @credentialFavoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get credentialFavoriteRemoved;

  /// No description provided for @backupPreviewDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get backupPreviewDate;

  /// No description provided for @backupPreviewType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get backupPreviewType;

  /// No description provided for @backupPreviewEntities.
  ///
  /// In en, this message translates to:
  /// **'Entities'**
  String get backupPreviewEntities;

  /// No description provided for @backupPreviewFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get backupPreviewFiles;

  /// No description provided for @backupPreviewSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get backupPreviewSize;

  /// No description provided for @backupPreviewDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get backupPreviewDevice;

  /// No description provided for @backupPreviewEncryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get backupPreviewEncryption;

  /// No description provided for @backupPreviewEncryptionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get backupPreviewEncryptionNone;

  /// No description provided for @backupRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get backupRestoring;

  /// No description provided for @backupRestoringMessage.
  ///
  /// In en, this message translates to:
  /// **'Please wait while your vault is being restored.'**
  String get backupRestoringMessage;

  /// No description provided for @backupRestoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore Complete'**
  String get backupRestoreComplete;

  /// No description provided for @backupRestoreCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Your vault has been successfully restored from the backup.'**
  String get backupRestoreCompleteMessage;

  /// No description provided for @backupDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the backup from {date}? This action cannot be undone.'**
  String backupDeleteConfirmation(String date);

  /// No description provided for @backupRememberPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Remember passphrase on this device'**
  String get backupRememberPassphrase;

  /// No description provided for @backupCloudProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'CLOUD PROVIDER'**
  String get backupCloudProviderLabel;

  /// No description provided for @backupUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get backupUploading;

  /// No description provided for @backupUploadToICloud.
  ///
  /// In en, this message translates to:
  /// **'Upload to iCloud'**
  String get backupUploadToICloud;

  /// No description provided for @backupAppleIdAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Uses your Apple ID automatically'**
  String get backupAppleIdAutomatic;

  /// No description provided for @backupGoogleAuthOpened.
  ///
  /// In en, this message translates to:
  /// **'A browser window opened for Google authorization.'**
  String get backupGoogleAuthOpened;

  /// No description provided for @backupGoogleAuthApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve access. After redirect, copy the \"code\" value from the browser URL bar and paste it below.'**
  String get backupGoogleAuthApprove;

  /// No description provided for @backupICloudComingSoon.
  ///
  /// In en, this message translates to:
  /// **'iCloud native integration coming soon. Use Dropbox for now.'**
  String get backupICloudComingSoon;

  /// No description provided for @backupInterruptedRestoreDetected.
  ///
  /// In en, this message translates to:
  /// **'Interrupted Restore Detected'**
  String get backupInterruptedRestoreDetected;

  /// No description provided for @backupFrequencyError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update backup frequency.'**
  String get backupFrequencyError;

  /// No description provided for @backupDisconnectError.
  ///
  /// In en, this message translates to:
  /// **'Failed to disconnect. Please try again.'**
  String get backupDisconnectError;

  /// No description provided for @searchPartialError.
  ///
  /// In en, this message translates to:
  /// **'Some results may be missing due to an error.'**
  String get searchPartialError;

  /// No description provided for @documentShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get documentShowAll;

  /// No description provided for @backupErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load backups.'**
  String get backupErrorLoad;

  /// No description provided for @backupErrorRollback.
  ///
  /// In en, this message translates to:
  /// **'Rollback cleanup failed. Please try again.'**
  String get backupErrorRollback;

  /// No description provided for @backupErrorCreate.
  ///
  /// In en, this message translates to:
  /// **'Backup failed. Please try again.'**
  String get backupErrorCreate;

  /// No description provided for @backupErrorRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore failed. Please check your passphrase.'**
  String get backupErrorRestore;

  /// No description provided for @backupErrorDelete.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete backup.'**
  String get backupErrorDelete;

  /// No description provided for @backupErrorConnectDropbox.
  ///
  /// In en, this message translates to:
  /// **'Connect Dropbox in Sync settings first.'**
  String get backupErrorConnectDropbox;

  /// No description provided for @backupErrorUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get backupErrorUpload;

  /// No description provided for @backupErrorDropboxNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Dropbox not connected.'**
  String get backupErrorDropboxNotConnected;

  /// No description provided for @backupErrorCloudRestore.
  ///
  /// In en, this message translates to:
  /// **'Cloud restore failed. Please try again.'**
  String get backupErrorCloudRestore;

  /// No description provided for @backupSuccessUpload.
  ///
  /// In en, this message translates to:
  /// **'Uploaded to Dropbox successfully.'**
  String get backupSuccessUpload;

  /// No description provided for @backupSuccessCloudRestore.
  ///
  /// In en, this message translates to:
  /// **'Restored from cloud backup successfully.'**
  String get backupSuccessCloudRestore;

  /// No description provided for @backupGoogleDriveLabel.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get backupGoogleDriveLabel;

  /// No description provided for @syncErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load sync settings.'**
  String get syncErrorLoad;

  /// No description provided for @syncErrorSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save settings.'**
  String get syncErrorSave;

  /// No description provided for @syncErrorRun.
  ///
  /// In en, this message translates to:
  /// **'Unable to run sync.'**
  String get syncErrorRun;

  /// No description provided for @generatorErrorGenerate.
  ///
  /// In en, this message translates to:
  /// **'Unable to generate password.'**
  String get generatorErrorGenerate;

  /// No description provided for @profileErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load profile right now.'**
  String get profileErrorLoad;

  /// No description provided for @profileErrorShareOptions.
  ///
  /// In en, this message translates to:
  /// **'Unable to load sharing options right now.'**
  String get profileErrorShareOptions;

  /// No description provided for @profileErrorVCard.
  ///
  /// In en, this message translates to:
  /// **'Unable to generate vCard right now.'**
  String get profileErrorVCard;

  /// No description provided for @documentsErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load documents.'**
  String get documentsErrorLoad;

  /// No description provided for @documentsErrorCompany.
  ///
  /// In en, this message translates to:
  /// **'Unable to load company details.'**
  String get documentsErrorCompany;

  /// No description provided for @documentsErrorWorkVaults.
  ///
  /// In en, this message translates to:
  /// **'Unable to load work vaults.'**
  String get documentsErrorWorkVaults;

  /// No description provided for @documentsErrorSecureIds.
  ///
  /// In en, this message translates to:
  /// **'Unable to load secure IDs.'**
  String get documentsErrorSecureIds;

  /// No description provided for @documentTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Timeline'**
  String get documentTimelineTitle;

  /// No description provided for @documentTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents with expiry dates yet.'**
  String get documentTimelineEmpty;

  /// No description provided for @documentTimelineErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load expiring documents.'**
  String get documentTimelineErrorLoad;

  /// No description provided for @documentTimelineNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No documents match the selected filter.'**
  String get documentTimelineNoMatches;

  /// No description provided for @documentTimelineExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get documentTimelineExpired;

  /// No description provided for @documentTimelineSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get documentTimelineSoon;

  /// No description provided for @documentTimelineSafe.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get documentTimelineSafe;

  /// No description provided for @documentTimelineFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get documentTimelineFilterAll;

  /// No description provided for @documentTimelineFilterExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get documentTimelineFilterExpired;

  /// No description provided for @documentTimelineFilterCritical.
  ///
  /// In en, this message translates to:
  /// **'<30d'**
  String get documentTimelineFilterCritical;

  /// No description provided for @documentTimelineFilterWarning.
  ///
  /// In en, this message translates to:
  /// **'<90d'**
  String get documentTimelineFilterWarning;

  /// No description provided for @documentTimelineFilterSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get documentTimelineFilterSafe;

  /// No description provided for @documentTimelineDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String documentTimelineDaysRemaining(int days);

  /// No description provided for @documentTimelineExpiredDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Expired {days} days ago'**
  String documentTimelineExpiredDaysAgo(int days);

  /// No description provided for @documentTimelineExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get documentTimelineExpiresToday;

  /// No description provided for @collectionsErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load collections right now.'**
  String get collectionsErrorLoad;

  /// No description provided for @collectionsErrorCreate.
  ///
  /// In en, this message translates to:
  /// **'Unable to create collection.'**
  String get collectionsErrorCreate;

  /// No description provided for @collectionsErrorDelete.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete collection.'**
  String get collectionsErrorDelete;

  /// No description provided for @collectionsErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'Unable to load this collection.'**
  String get collectionsErrorDetail;

  /// No description provided for @credentialsErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load credentials.'**
  String get credentialsErrorLoad;

  /// No description provided for @credentialsErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'Unable to load credential details.'**
  String get credentialsErrorDetail;

  /// No description provided for @shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Share'**
  String get shareTitle;

  /// No description provided for @sharePassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get sharePassphraseHint;

  /// No description provided for @shareTtlLabel.
  ///
  /// In en, this message translates to:
  /// **'Link expires in:'**
  String get shareTtlLabel;

  /// No description provided for @shareTtl1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 Hour'**
  String get shareTtl1Hour;

  /// No description provided for @shareTtl1Day.
  ///
  /// In en, this message translates to:
  /// **'1 Day'**
  String get shareTtl1Day;

  /// No description provided for @shareTtl7Days.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get shareTtl7Days;

  /// No description provided for @shareTtlOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time View'**
  String get shareTtlOneTime;

  /// No description provided for @shareGenerateLink.
  ///
  /// In en, this message translates to:
  /// **'Generate Link'**
  String get shareGenerateLink;

  /// No description provided for @shareCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard!'**
  String get shareCopyLink;

  /// No description provided for @shareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Share link copied!'**
  String get shareLinkCopied;

  /// No description provided for @sharePassphraseReminder.
  ///
  /// In en, this message translates to:
  /// **'Important: Share the passphrase separately via a secure channel'**
  String get sharePassphraseReminder;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Credentials'**
  String get importTitle;

  /// No description provided for @importSelectSource.
  ///
  /// In en, this message translates to:
  /// **'Select Import Source'**
  String get importSelectSource;

  /// No description provided for @importSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get importSelectFile;

  /// No description provided for @importPreview.
  ///
  /// In en, this message translates to:
  /// **'Review Credentials'**
  String get importPreview;

  /// No description provided for @importComplete.
  ///
  /// In en, this message translates to:
  /// **'Import Complete'**
  String get importComplete;

  /// No description provided for @importFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count} credentials'**
  String importFound(int count);

  /// No description provided for @importDuplicates.
  ///
  /// In en, this message translates to:
  /// **'{count} duplicates detected'**
  String importDuplicates(int count);

  /// No description provided for @importSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get importSelectAll;

  /// No description provided for @importDeselectDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Deselect Duplicates'**
  String get importDeselectDuplicates;

  /// No description provided for @importImportSelected.
  ///
  /// In en, this message translates to:
  /// **'Import Selected'**
  String get importImportSelected;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import Successful'**
  String get importSuccess;

  /// No description provided for @importCompleted.
  ///
  /// In en, this message translates to:
  /// **'Imported {imported} credentials, skipped {skipped} duplicates'**
  String importCompleted(int imported, int skipped);

  /// No description provided for @importErrors.
  ///
  /// In en, this message translates to:
  /// **'{count} errors occurred'**
  String importErrors(int count);

  /// No description provided for @importInstructions1Password.
  ///
  /// In en, this message translates to:
  /// **'Export your 1Password vault as CSV. Go to File > Export and choose CSV format.'**
  String get importInstructions1Password;

  /// No description provided for @importInstructionsBitwarden.
  ///
  /// In en, this message translates to:
  /// **'Export from Bitwarden as JSON. Go to Settings > Export Vault and choose JSON format.'**
  String get importInstructionsBitwarden;

  /// No description provided for @importInstructionsChrome.
  ///
  /// In en, this message translates to:
  /// **'Export from Chrome Password Manager. Go to Settings > Passwords and export your data as CSV.'**
  String get importInstructionsChrome;

  /// No description provided for @importInstructionsSafari.
  ///
  /// In en, this message translates to:
  /// **'Export from Safari. Go to File > Export Passwords and select the credentials to export.'**
  String get importInstructionsSafari;

  /// No description provided for @importInstructionsLastPass.
  ///
  /// In en, this message translates to:
  /// **'Export from LastPass as CSV. Go to Vault > More Options > Export and choose CSV format.'**
  String get importInstructionsLastPass;

  /// No description provided for @vaultHealthPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault Health'**
  String get vaultHealthPageTitle;

  /// No description provided for @vaultHealthOut.
  ///
  /// In en, this message translates to:
  /// **'out of 100'**
  String get vaultHealthOut;

  /// No description provided for @vaultHealthLastChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked {time}'**
  String vaultHealthLastChecked(String time);

  /// No description provided for @vaultHealthGradeExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get vaultHealthGradeExcellent;

  /// No description provided for @vaultHealthGradeGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get vaultHealthGradeGood;

  /// No description provided for @vaultHealthGradeFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get vaultHealthGradeFair;

  /// No description provided for @vaultHealthGradePoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get vaultHealthGradePoor;

  /// No description provided for @vaultHealthSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get vaultHealthSummaryTitle;

  /// No description provided for @vaultHealthWeakCount.
  ///
  /// In en, this message translates to:
  /// **'Weak Passwords'**
  String get vaultHealthWeakCount;

  /// No description provided for @vaultHealthReusedCount.
  ///
  /// In en, this message translates to:
  /// **'Reused Passwords'**
  String get vaultHealthReusedCount;

  /// No description provided for @vaultHealthBreachedCount.
  ///
  /// In en, this message translates to:
  /// **'Breached'**
  String get vaultHealthBreachedCount;

  /// No description provided for @vaultHealthExpiringCount.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get vaultHealthExpiringCount;

  /// No description provided for @vaultHealthIssuesTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} Issues Found'**
  String vaultHealthIssuesTitle(int count);

  /// No description provided for @vaultHealthNoIssues.
  ///
  /// In en, this message translates to:
  /// **'No Issues Found'**
  String get vaultHealthNoIssues;

  /// No description provided for @vaultHealthAllGood.
  ///
  /// In en, this message translates to:
  /// **'Your vault is in great shape!'**
  String get vaultHealthAllGood;

  /// No description provided for @vaultHealthCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get vaultHealthCritical;

  /// No description provided for @vaultHealthHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get vaultHealthHigh;

  /// No description provided for @vaultHealthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get vaultHealthMedium;

  /// No description provided for @vaultHealthLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get vaultHealthLow;

  /// No description provided for @navBundles.
  ///
  /// In en, this message translates to:
  /// **'Bundles'**
  String get navBundles;

  /// No description provided for @bundlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Bundles'**
  String get bundlesTitle;

  /// No description provided for @bundlesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bundles yet'**
  String get bundlesEmptyTitle;

  /// No description provided for @bundlesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a bundle to group files and credentials for an application, a trip, or any other purpose.'**
  String get bundlesEmptySubtitle;

  /// No description provided for @bundlesErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load bundles.'**
  String get bundlesErrorLoad;

  /// No description provided for @bundleCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New bundle'**
  String get bundleCreateAction;

  /// No description provided for @bundleCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create bundle'**
  String get bundleCreateTitle;

  /// No description provided for @bundleCreateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the bundle. Please try again.'**
  String get bundleCreateError;

  /// No description provided for @bundleFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get bundleFieldTitle;

  /// No description provided for @bundleFieldTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. France Visa Application'**
  String get bundleFieldTitleHint;

  /// No description provided for @bundleFieldTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get bundleFieldTitleRequired;

  /// No description provided for @bundleFieldPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose (optional)'**
  String get bundleFieldPurpose;

  /// No description provided for @bundleFieldPurposeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Schengen visa — Feb 2026'**
  String get bundleFieldPurposeHint;

  /// No description provided for @bundleFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get bundleFieldDescription;

  /// No description provided for @bundleFieldDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this bundle for?'**
  String get bundleFieldDescriptionHint;

  /// No description provided for @bundleStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get bundleStatusDraft;

  /// No description provided for @bundleStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get bundleStatusReady;

  /// No description provided for @bundleStatusExported.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get bundleStatusExported;

  /// No description provided for @bundleStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get bundleStatusArchived;

  /// No description provided for @bundleItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{no items} =1{1 item} other{{count} items}}'**
  String bundleItemCount(num count);

  /// No description provided for @bundleUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'updated {date}'**
  String bundleUpdatedAt(Object date);

  /// No description provided for @bundleLastExportedAt.
  ///
  /// In en, this message translates to:
  /// **'exported {date}'**
  String bundleLastExportedAt(Object date);

  /// No description provided for @bundleDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete bundle?'**
  String get bundleDeleteTitle;

  /// No description provided for @bundleDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be permanently deleted.'**
  String bundleDeleteMessage(Object title);

  /// No description provided for @bundleDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get bundleDeleteConfirm;

  /// No description provided for @bundleDetailLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Bundle'**
  String get bundleDetailLoadingTitle;

  /// No description provided for @bundleDetailErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load this bundle.'**
  String get bundleDetailErrorLoad;

  /// No description provided for @bundleDetailMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get bundleDetailMenuTooltip;

  /// No description provided for @bundleActionExport.
  ///
  /// In en, this message translates to:
  /// **'Export / share'**
  String get bundleActionExport;

  /// No description provided for @bundleTemplateSelectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get bundleTemplateSelectedBadge;

  /// No description provided for @bundleTemplateSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a template'**
  String get bundleTemplateSectionTitle;

  /// No description provided for @bundleTemplateSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Templates prefill the bundle and track required items so you can see what is missing.'**
  String get bundleTemplateSectionSubtitle;

  /// No description provided for @bundleTemplateBlankTitle.
  ///
  /// In en, this message translates to:
  /// **'Blank bundle'**
  String get bundleTemplateBlankTitle;

  /// No description provided for @bundleTemplateBlankSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start empty and add items manually.'**
  String get bundleTemplateBlankSubtitle;

  /// No description provided for @bundleTemplatePrefillHint.
  ///
  /// In en, this message translates to:
  /// **'Selecting a template prefills the bundle fields and checks your vault for matching items.'**
  String get bundleTemplatePrefillHint;

  /// No description provided for @bundleTemplateFranceVisaTitle.
  ///
  /// In en, this message translates to:
  /// **'France Visa'**
  String get bundleTemplateFranceVisaTitle;

  /// No description provided for @bundleTemplateFranceVisaSummary.
  ///
  /// In en, this message translates to:
  /// **'Identity, travel, accommodation, employment, insurance, and financial records.'**
  String get bundleTemplateFranceVisaSummary;

  /// No description provided for @bundleTemplateApartmentRentalTitle.
  ///
  /// In en, this message translates to:
  /// **'Apartment Rental'**
  String get bundleTemplateApartmentRentalTitle;

  /// No description provided for @bundleTemplateApartmentRentalSummary.
  ///
  /// In en, this message translates to:
  /// **'Identity, income proof, employment, tax, and rent records.'**
  String get bundleTemplateApartmentRentalSummary;

  /// No description provided for @bundleTemplateJobOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'New Job Onboarding'**
  String get bundleTemplateJobOnboardingTitle;

  /// No description provided for @bundleTemplateJobOnboardingSummary.
  ///
  /// In en, this message translates to:
  /// **'Contract, identity, bank info, and qualification records.'**
  String get bundleTemplateJobOnboardingSummary;

  /// No description provided for @bundleTemplateTravelClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Claim'**
  String get bundleTemplateTravelClaimTitle;

  /// No description provided for @bundleTemplateTravelClaimSummary.
  ///
  /// In en, this message translates to:
  /// **'Bookings, receipts, invoices, and claim support documents.'**
  String get bundleTemplateTravelClaimSummary;

  /// No description provided for @bundleTemplateChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Template checklist'**
  String get bundleTemplateChecklistTitle;

  /// No description provided for @bundleTemplateChecklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} required items ready'**
  String bundleTemplateChecklistSubtitle(int completed, int total);

  /// No description provided for @bundleTemplateAddMissingAction.
  ///
  /// In en, this message translates to:
  /// **'Add missing'**
  String get bundleTemplateAddMissingAction;

  /// No description provided for @bundleTemplateReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to export'**
  String get bundleTemplateReadyTitle;

  /// No description provided for @bundleTemplateMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing required items'**
  String get bundleTemplateMissingTitle;

  /// No description provided for @bundleTemplateReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All required items are attached.'**
  String get bundleTemplateReadySubtitle;

  /// No description provided for @bundleTemplateMissingCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 required item is missing} other{{count} required items are missing}}'**
  String bundleTemplateMissingCount(int count);

  /// No description provided for @bundleTemplateRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get bundleTemplateRequiredLabel;

  /// No description provided for @bundleTemplateCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bundleTemplateCompletedLabel;

  /// No description provided for @bundleTemplateOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get bundleTemplateOptionalLabel;

  /// No description provided for @bundleTemplateMatchedCount.
  ///
  /// In en, this message translates to:
  /// **'{matched} of {minimum}'**
  String bundleTemplateMatchedCount(int matched, int minimum);

  /// No description provided for @bundleActionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get bundleActionArchive;

  /// No description provided for @bundleActionUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get bundleActionUnarchive;

  /// No description provided for @bundleActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete bundle'**
  String get bundleActionDelete;

  /// No description provided for @bundleSectionItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get bundleSectionItems;

  /// No description provided for @bundleSectionHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get bundleSectionHistory;

  /// No description provided for @bundleEmptyItems.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Tap \"Add items\" to pick from your vault.'**
  String get bundleEmptyItems;

  /// No description provided for @bundleAddItems.
  ///
  /// In en, this message translates to:
  /// **'Add items'**
  String get bundleAddItems;

  /// No description provided for @bundleHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get bundleHistoryEmpty;

  /// No description provided for @bundleEventCreated.
  ///
  /// In en, this message translates to:
  /// **'Bundle created'**
  String get bundleEventCreated;

  /// No description provided for @bundleEventRenamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get bundleEventRenamed;

  /// No description provided for @bundleEventPurposeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Purpose updated'**
  String get bundleEventPurposeUpdated;

  /// No description provided for @bundleEventDescriptionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Description updated'**
  String get bundleEventDescriptionUpdated;

  /// No description provided for @bundleEventItemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added'**
  String get bundleEventItemAdded;

  /// No description provided for @bundleEventItemRemoved.
  ///
  /// In en, this message translates to:
  /// **'Item removed'**
  String get bundleEventItemRemoved;

  /// No description provided for @bundleEventItemReordered.
  ///
  /// In en, this message translates to:
  /// **'Items reordered'**
  String get bundleEventItemReordered;

  /// No description provided for @bundleEventStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get bundleEventStatusChanged;

  /// No description provided for @bundleEventExported.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get bundleEventExported;

  /// No description provided for @bundleEventArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get bundleEventArchived;

  /// No description provided for @bundleEventRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get bundleEventRestored;

  /// No description provided for @bundleAddToTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to bundle'**
  String get bundleAddToTitle;

  /// No description provided for @bundleAddToSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{Pick a bundle for 1 item} other{Pick a bundle for {count} items}}'**
  String bundleAddToSubtitle(num count);

  /// No description provided for @bundleAddToNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get bundleAddToNew;

  /// No description provided for @bundleAddToEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no bundles yet. Tap \"New\" to create one.'**
  String get bundleAddToEmpty;

  /// No description provided for @bundleAddToSnackbar.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 item added to bundle.} other{{count} items added to bundle.}}'**
  String bundleAddToSnackbar(num count);

  /// No description provided for @bundleExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export bundle'**
  String get bundleExportTitle;

  /// No description provided for @bundleExportSectionWhat.
  ///
  /// In en, this message translates to:
  /// **'Bundle'**
  String get bundleExportSectionWhat;

  /// No description provided for @bundleExportSectionOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get bundleExportSectionOptions;

  /// No description provided for @bundleExportEncryptTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypt archive'**
  String get bundleExportEncryptTitle;

  /// No description provided for @bundleExportEncryptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect the ZIP with a password (AES-256).'**
  String get bundleExportEncryptSubtitle;

  /// No description provided for @bundleExportPassphraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get bundleExportPassphraseLabel;

  /// No description provided for @bundleExportPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Share this separately with the recipient'**
  String get bundleExportPassphraseHint;

  /// No description provided for @bundleExportPassphraseRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a passphrase.'**
  String get bundleExportPassphraseRequired;

  /// No description provided for @bundleExportRunAction.
  ///
  /// In en, this message translates to:
  /// **'Build archive'**
  String get bundleExportRunAction;

  /// No description provided for @bundleExportError.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get bundleExportError;

  /// No description provided for @bundleExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Archive ready'**
  String get bundleExportSuccess;

  /// No description provided for @bundleExportShare.
  ///
  /// In en, this message translates to:
  /// **'Share archive'**
  String get bundleExportShare;

  /// No description provided for @bundleSearchPickBanner.
  ///
  /// In en, this message translates to:
  /// **'Picking items for \"{title}\"'**
  String bundleSearchPickBanner(Object title);

  /// No description provided for @bundleSearchPickBannerGeneric.
  ///
  /// In en, this message translates to:
  /// **'Tap items to add to a bundle'**
  String get bundleSearchPickBannerGeneric;

  /// No description provided for @bundleSearchSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 selected} other{{count} selected}}'**
  String bundleSearchSelectedCount(num count);

  /// No description provided for @bundleSearchClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get bundleSearchClearSelection;

  /// No description provided for @bundleSearchAddSelected.
  ///
  /// In en, this message translates to:
  /// **'Add selected'**
  String get bundleSearchAddSelected;

  /// No description provided for @bundleSearchAddToBundle.
  ///
  /// In en, this message translates to:
  /// **'Add to bundle'**
  String get bundleSearchAddToBundle;

  /// No description provided for @bundleTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get bundleTimeJustNow;

  /// No description provided for @bundleTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 min ago} other{{count} min ago}}'**
  String bundleTimeMinutesAgo(num count);

  /// No description provided for @bundleTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 h ago} other{{count} h ago}}'**
  String bundleTimeHoursAgo(num count);

  /// No description provided for @bundleTimeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get bundleTimeYesterday;

  /// No description provided for @bundleTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 day ago} other{{count} days ago}}'**
  String bundleTimeDaysAgo(num count);

  /// No description provided for @bundlePreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview is not yet available for this item type.'**
  String get bundlePreviewUnavailable;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @tasksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No task lists yet'**
  String get tasksEmptyTitle;

  /// No description provided for @tasksEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a list to track things you need to do — errands, a project, a trip checklist.'**
  String get tasksEmptySubtitle;

  /// No description provided for @tasksErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load task lists.'**
  String get tasksErrorLoad;

  /// No description provided for @tasksListCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get tasksListCreateAction;

  /// No description provided for @tasksListCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create task list'**
  String get tasksListCreateTitle;

  /// No description provided for @tasksListCreateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the list. Please try again.'**
  String get tasksListCreateError;

  /// No description provided for @tasksListFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get tasksListFieldTitle;

  /// No description provided for @tasksListFieldTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Visa application prep'**
  String get tasksListFieldTitleHint;

  /// No description provided for @tasksListFieldTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get tasksListFieldTitleRequired;

  /// No description provided for @tasksListFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get tasksListFieldDescription;

  /// No description provided for @tasksListFieldDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this list for?'**
  String get tasksListFieldDescriptionHint;

  /// No description provided for @tasksListPickIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get tasksListPickIcon;

  /// No description provided for @tasksListPickColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get tasksListPickColor;

  /// No description provided for @tasksListLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksListLoadingTitle;

  /// No description provided for @tasksListErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load this list.'**
  String get tasksListErrorLoad;

  /// No description provided for @tasksHideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide archived'**
  String get tasksHideArchived;

  /// No description provided for @tasksShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get tasksShowArchived;

  /// No description provided for @tasksHideDone.
  ///
  /// In en, this message translates to:
  /// **'Hide completed'**
  String get tasksHideDone;

  /// No description provided for @tasksShowDone.
  ///
  /// In en, this message translates to:
  /// **'Show completed'**
  String get tasksShowDone;

  /// No description provided for @tasksOverdueBadge.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 overdue} other{{count} overdue}}'**
  String tasksOverdueBadge(num count);

  /// No description provided for @tasksOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{no open} =1{1 open} other{{count} open}}'**
  String tasksOpenCount(num count);

  /// No description provided for @tasksDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{0 done} =1{1 done} other{{count} done}}'**
  String tasksDoneCount(num count);

  /// No description provided for @tasksActionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get tasksActionArchive;

  /// No description provided for @tasksActionUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get tasksActionUnarchive;

  /// No description provided for @tasksActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tasksActionDelete;

  /// No description provided for @tasksActionPin.
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get tasksActionPin;

  /// No description provided for @tasksActionUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get tasksActionUnpin;

  /// No description provided for @tasksDeleteListTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete list?'**
  String get tasksDeleteListTitle;

  /// No description provided for @tasksDeleteListMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and all its tasks will be permanently deleted.'**
  String tasksDeleteListMessage(Object title);

  /// No description provided for @tasksDeleteListConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tasksDeleteListConfirm;

  /// No description provided for @taskCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get taskCreateAction;

  /// No description provided for @taskCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskCreateTitle;

  /// No description provided for @taskEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskEditTitle;

  /// No description provided for @taskFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskFieldTitle;

  /// No description provided for @taskFieldTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get taskFieldTitleHint;

  /// No description provided for @taskFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get taskFieldNotes;

  /// No description provided for @taskFieldNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Details, sub-steps, context…'**
  String get taskFieldNotesHint;

  /// No description provided for @taskFieldPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskFieldPriority;

  /// No description provided for @taskFieldDue.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get taskFieldDue;

  /// No description provided for @taskFieldDueNone.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get taskFieldDueNone;

  /// No description provided for @taskFieldDueClear.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get taskFieldDueClear;

  /// No description provided for @taskFieldPin.
  ///
  /// In en, this message translates to:
  /// **'Pin this task'**
  String get taskFieldPin;

  /// No description provided for @taskFieldPinHint.
  ///
  /// In en, this message translates to:
  /// **'Pinned tasks stay at the top of the list.'**
  String get taskFieldPinHint;

  /// No description provided for @taskFieldLink.
  ///
  /// In en, this message translates to:
  /// **'Linked vault item (optional)'**
  String get taskFieldLink;

  /// No description provided for @taskFieldLinkNone.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick a document, credential or bundle'**
  String get taskFieldLinkNone;

  /// No description provided for @taskFieldLinkClear.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get taskFieldLinkClear;

  /// No description provided for @taskPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get taskPriorityLow;

  /// No description provided for @taskPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get taskPriorityMedium;

  /// No description provided for @taskPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get taskPriorityHigh;

  /// No description provided for @taskDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get taskDueToday;

  /// No description provided for @taskDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get taskDueTomorrow;

  /// No description provided for @taskDueInDays.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{Due in 1 day} other{Due in {count} days}}'**
  String taskDueInDays(num count);

  /// No description provided for @taskDueOverdueBy.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{Overdue by 1 day} other{Overdue by {count} days}}'**
  String taskDueOverdueBy(num count);

  /// No description provided for @tasksSectionPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get tasksSectionPinned;

  /// No description provided for @tasksSectionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tasksSectionOverdue;

  /// No description provided for @tasksSectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tasksSectionToday;

  /// No description provided for @tasksSectionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tasksSectionUpcoming;

  /// No description provided for @tasksSectionNoDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get tasksSectionNoDate;

  /// No description provided for @tasksSectionDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tasksSectionDone;

  /// No description provided for @tasksStatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get tasksStatOpen;

  /// No description provided for @tasksStatDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tasksStatDone;

  /// No description provided for @tasksStatOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tasksStatOverdue;

  /// No description provided for @tasksDetailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet. Tap \"Add task\" to create the first one.'**
  String get tasksDetailEmpty;

  /// No description provided for @tasksEnterReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get tasksEnterReorder;

  /// No description provided for @tasksExitReorder.
  ///
  /// In en, this message translates to:
  /// **'Done reordering'**
  String get tasksExitReorder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
