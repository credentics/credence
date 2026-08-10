import 'package:flutter/material.dart';
import 'package:pass_doc_manager/domain/bundles/support/bundle_template_catalog.dart';
import 'package:pass_doc_manager/l10n/app_localizations.dart';

class BundleTemplatePresentationCopy {
  const BundleTemplatePresentationCopy({
    required this.title,
    required this.summary,
    required this.recommendedTitle,
    required this.recommendedPurpose,
    required this.recommendedDescription,
    required this.icon,
  });

  final String title;
  final String summary;
  final String recommendedTitle;
  final String recommendedPurpose;
  final String recommendedDescription;
  final IconData icon;
}

BundleTemplatePresentationCopy bundleTemplatePresentationCopy({
  required AppLocalizations l10n,
  required BundleTemplateDefinition template,
}) {
  switch (template.key) {
    case 'france_visa':
      return BundleTemplatePresentationCopy(
        title: l10n.bundleTemplateFranceVisaTitle,
        summary: l10n.bundleTemplateFranceVisaSummary,
        recommendedTitle: l10n.bundleTemplateFranceVisaTitle,
        recommendedPurpose: l10n.bundleTemplateFranceVisaTitle,
        recommendedDescription: l10n.bundleTemplateFranceVisaSummary,
        icon: Icons.travel_explore_rounded,
      );
    case 'apartment_rental':
      return BundleTemplatePresentationCopy(
        title: l10n.bundleTemplateApartmentRentalTitle,
        summary: l10n.bundleTemplateApartmentRentalSummary,
        recommendedTitle: l10n.bundleTemplateApartmentRentalTitle,
        recommendedPurpose: l10n.bundleTemplateApartmentRentalTitle,
        recommendedDescription: l10n.bundleTemplateApartmentRentalSummary,
        icon: Icons.home_work_rounded,
      );
    case 'job_onboarding':
      return BundleTemplatePresentationCopy(
        title: l10n.bundleTemplateJobOnboardingTitle,
        summary: l10n.bundleTemplateJobOnboardingSummary,
        recommendedTitle: l10n.bundleTemplateJobOnboardingTitle,
        recommendedPurpose: l10n.bundleTemplateJobOnboardingTitle,
        recommendedDescription: l10n.bundleTemplateJobOnboardingSummary,
        icon: Icons.badge_rounded,
      );
    case 'travel_claim':
      return BundleTemplatePresentationCopy(
        title: l10n.bundleTemplateTravelClaimTitle,
        summary: l10n.bundleTemplateTravelClaimSummary,
        recommendedTitle: l10n.bundleTemplateTravelClaimTitle,
        recommendedPurpose: l10n.bundleTemplateTravelClaimTitle,
        recommendedDescription: l10n.bundleTemplateTravelClaimSummary,
        icon: Icons.receipt_long_rounded,
      );
    default:
      return BundleTemplatePresentationCopy(
        title: template.title,
        summary: template.summary,
        recommendedTitle: template.defaultBundleTitle,
        recommendedPurpose: template.defaultPurpose,
        recommendedDescription: template.defaultDescription,
        icon: Icons.folder_zip_rounded,
      );
  }
}
