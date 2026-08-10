import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';

class BundleTemplateDefinition {
  const BundleTemplateDefinition({
    required this.key,
    required this.title,
    required this.summary,
    required this.defaultBundleTitle,
    required this.defaultPurpose,
    required this.defaultDescription,
    required this.requirements,
  });

  final String key;
  final String title;
  final String summary;
  final String defaultBundleTitle;
  final String defaultPurpose;
  final String defaultDescription;
  final List<BundleTemplateRequirement> requirements;

  int get requiredCount => requirements.where((item) => !item.optional).length;
}

class BundleTemplateRequirement {
  const BundleTemplateRequirement({
    required this.id,
    required this.title,
    required this.description,
    required this.acceptedTypes,
    this.keywords = const <String>[],
    this.minCount = 1,
    this.optional = false,
  }) : assert(minCount > 0);

  final String id;
  final String title;
  final String description;
  final List<BundleItemType> acceptedTypes;
  final List<String> keywords;
  final int minCount;
  final bool optional;

  bool matches(BundleItemRef item) {
    if (acceptedTypes.isNotEmpty && !acceptedTypes.contains(item.type)) {
      return false;
    }
    if (keywords.isEmpty) {
      return true;
    }
    final haystack = _normalizeText(
      '${item.displayName} ${item.subtitle ?? ''}',
    );
    for (final keyword in keywords) {
      final normalizedKeyword = _normalizeText(keyword);
      if (normalizedKeyword.isNotEmpty &&
          haystack.contains(normalizedKeyword)) {
        return true;
      }
    }
    return false;
  }
}

class BundleTemplateRequirementProgress {
  const BundleTemplateRequirementProgress({
    required this.requirement,
    required this.matches,
  });

  final BundleTemplateRequirement requirement;
  final List<BundleItemRef> matches;

  int get matchedCount => matches.length;
  int get missingCount {
    final remaining = requirement.minCount - matchedCount;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isSatisfied => matchedCount >= requirement.minCount;
}

class BundleTemplateProgress {
  const BundleTemplateProgress({
    required this.template,
    required this.requirements,
  });

  final BundleTemplateDefinition template;
  final List<BundleTemplateRequirementProgress> requirements;

  List<BundleTemplateRequirementProgress> get missingRequired => requirements
      .where((item) => !item.requirement.optional && !item.isSatisfied)
      .toList(growable: false);

  List<BundleTemplateRequirementProgress> get optionalRequirements =>
      requirements
          .where((item) => item.requirement.optional)
          .toList(growable: false);

  int get completedRequiredCount => requirements
      .where((item) => !item.requirement.optional && item.isSatisfied)
      .length;

  int get totalRequiredCount => template.requiredCount;

  int get totalMissingRequiredUnits =>
      missingRequired.fold<int>(0, (sum, item) => sum + item.missingCount);

  bool get isReady => missingRequired.isEmpty;
}

class BundleTemplateCatalog {
  const BundleTemplateCatalog._();

  static const List<BundleTemplateDefinition>
  templates = <BundleTemplateDefinition>[
    BundleTemplateDefinition(
      key: 'france_visa',
      title: 'France Visa',
      summary: 'Passport, bookings, insurance, employment, and finance.',
      defaultBundleTitle: 'France Visa Application',
      defaultPurpose: 'Schengen visa application packet',
      defaultDescription:
          'Prebuilt checklist for a France / Schengen visa file.',
      requirements: <BundleTemplateRequirement>[
        BundleTemplateRequirement(
          id: 'passport',
          title: 'Passport',
          description: 'Valid passport scan or passport document.',
          acceptedTypes: <BundleItemType>[
            BundleItemType.document,
            BundleItemType.identityCard,
          ],
          keywords: <String>['passport'],
        ),
        BundleTemplateRequirement(
          id: 'visa_form',
          title: 'Visa Application Form',
          description: 'Completed visa application form.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>[
            'visa application',
            'application form',
            'formulaire visa',
          ],
        ),
        BundleTemplateRequirement(
          id: 'travel_booking',
          title: 'Travel Booking',
          description: 'Flight booking, reservation, or ticket.',
          acceptedTypes: <BundleItemType>[
            BundleItemType.document,
            BundleItemType.collection,
          ],
          keywords: <String>['flight', 'ticket', 'reservation', 'booking'],
        ),
        BundleTemplateRequirement(
          id: 'accommodation',
          title: 'Accommodation Proof',
          description: 'Hotel or accommodation booking.',
          acceptedTypes: <BundleItemType>[
            BundleItemType.document,
            BundleItemType.collection,
          ],
          keywords: <String>['hotel', 'accommodation', 'lodging', 'booking'],
        ),
        BundleTemplateRequirement(
          id: 'insurance',
          title: 'Travel Insurance',
          description: 'Travel medical insurance certificate or policy.',
          acceptedTypes: <BundleItemType>[
            BundleItemType.document,
            BundleItemType.credential,
          ],
          keywords: <String>['insurance', 'assurance', 'medical policy'],
        ),
        BundleTemplateRequirement(
          id: 'employment',
          title: 'Employment Proof',
          description: 'Employment certificate, contract, or employer letter.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>[
            'employment',
            'contract',
            'employer',
            'attestation',
            'work certificate',
          ],
        ),
        BundleTemplateRequirement(
          id: 'payslips',
          title: 'Recent Payslips',
          description: 'Usually the last three payslips.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>[
            'payslip',
            'pay slip',
            'salary',
            'bulletin de paie',
          ],
          minCount: 3,
        ),
        BundleTemplateRequirement(
          id: 'bank_statements',
          title: 'Bank Statements',
          description: 'Recent bank statements showing available funds.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>[
            'bank statement',
            'statement',
            'releve',
            'account statement',
          ],
          minCount: 3,
        ),
      ],
    ),
    BundleTemplateDefinition(
      key: 'apartment_rental',
      title: 'Apartment Rental',
      summary: 'ID, income proof, employment, tax, and rent records.',
      defaultBundleTitle: 'Apartment Rental Application',
      defaultPurpose: 'Rental dossier',
      defaultDescription:
          'Prebuilt checklist for a rental application or apartment file.',
      requirements: <BundleTemplateRequirement>[
        BundleTemplateRequirement(
          id: 'identity',
          title: 'Identity Document',
          description: 'Passport or identity card.',
          acceptedTypes: <BundleItemType>[
            BundleItemType.document,
            BundleItemType.identityCard,
          ],
          keywords: <String>['passport', 'identity', 'id card', 'carte'],
        ),
        BundleTemplateRequirement(
          id: 'income',
          title: 'Proof of Income',
          description: 'Recent payslips or salary records.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>[
            'payslip',
            'pay slip',
            'salary',
            'bulletin de paie',
          ],
          minCount: 3,
        ),
        BundleTemplateRequirement(
          id: 'employment_contract',
          title: 'Employment Contract',
          description: 'Current work contract or employer letter.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>[
            'employment contract',
            'contract',
            'employer',
            'attestation',
          ],
        ),
        BundleTemplateRequirement(
          id: 'bank_statement',
          title: 'Bank Statement',
          description: 'Bank statement or proof of funds.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>['bank statement', 'statement', 'releve', 'iban'],
        ),
        BundleTemplateRequirement(
          id: 'rent_receipts',
          title: 'Rent Receipts / Quittance',
          description: 'Previous rent receipts or quittances.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>['quittance', 'rent receipt', 'rent', 'loyer'],
          minCount: 3,
        ),
        BundleTemplateRequirement(
          id: 'tax_notice',
          title: 'Tax Notice',
          description: 'Latest tax notice or fiscal declaration.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>['tax', 'avis d imposition', 'impot', 'fiscal'],
        ),
      ],
    ),
    BundleTemplateDefinition(
      key: 'job_onboarding',
      title: 'New Job Onboarding',
      summary: 'Contract, ID, bank info, and qualification records.',
      defaultBundleTitle: 'New Job Onboarding',
      defaultPurpose: 'Employee onboarding packet',
      defaultDescription:
          'Prebuilt checklist for documents commonly requested during onboarding.',
      requirements: <BundleTemplateRequirement>[
        BundleTemplateRequirement(
          id: 'signed_contract',
          title: 'Signed Contract',
          description: 'Signed employment contract or offer letter.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>[
            'signed contract',
            'offer letter',
            'employment contract',
            'contract',
          ],
        ),
        BundleTemplateRequirement(
          id: 'identity',
          title: 'Identity Document',
          description: 'Passport or national identity card.',
          acceptedTypes: <BundleItemType>[
            BundleItemType.document,
            BundleItemType.identityCard,
          ],
          keywords: <String>['passport', 'identity', 'id card', 'carte'],
        ),
        BundleTemplateRequirement(
          id: 'bank_details',
          title: 'Bank Details / RIB',
          description: 'RIB, IBAN, or direct-deposit information.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>['rib', 'iban', 'bank details'],
        ),
        BundleTemplateRequirement(
          id: 'social_security',
          title: 'Social Security / National Number',
          description: 'Social security certificate or national number proof.',
          acceptedTypes: <BundleItemType>[
            BundleItemType.document,
            BundleItemType.identityCard,
          ],
          keywords: <String>[
            'social security',
            'security number',
            'cnss',
            'sociale',
          ],
        ),
        BundleTemplateRequirement(
          id: 'diploma',
          title: 'Diploma / Certificate',
          description: 'Relevant diploma, degree, or certificate.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>['diploma', 'degree', 'certificate', 'certificat'],
          optional: true,
        ),
      ],
    ),
    BundleTemplateDefinition(
      key: 'travel_claim',
      title: 'Travel Claim',
      summary: 'Bookings, receipts, invoices, and claim support docs.',
      defaultBundleTitle: 'Travel Claim',
      defaultPurpose: 'Expense or insurance claim packet',
      defaultDescription:
          'Prebuilt checklist for travel reimbursement or insurance claims.',
      requirements: <BundleTemplateRequirement>[
        BundleTemplateRequirement(
          id: 'claim_form',
          title: 'Claim Form',
          description: 'Claim form or reimbursement form.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>['claim form', 'reimbursement form', 'claim'],
        ),
        BundleTemplateRequirement(
          id: 'tickets',
          title: 'Tickets / Booking',
          description: 'Travel tickets, reservation, or booking confirmation.',
          acceptedTypes: <BundleItemType>[
            BundleItemType.document,
            BundleItemType.collection,
          ],
          keywords: <String>['ticket', 'boarding', 'reservation', 'booking'],
        ),
        BundleTemplateRequirement(
          id: 'receipts',
          title: 'Receipts',
          description: 'Expense receipts related to the claim.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>['receipt', 'recu', 'expense'],
          minCount: 2,
        ),
        BundleTemplateRequirement(
          id: 'invoices',
          title: 'Invoices',
          description: 'Invoices or statements for claimed amounts.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>['invoice', 'facture'],
        ),
        BundleTemplateRequirement(
          id: 'proof_of_payment',
          title: 'Proof of Payment',
          description: 'Payment confirmation or card statement.',
          acceptedTypes: <BundleItemType>[BundleItemType.document],
          keywords: <String>[
            'payment',
            'paid',
            'card statement',
            'bank statement',
          ],
        ),
        BundleTemplateRequirement(
          id: 'insurance',
          title: 'Insurance Policy',
          description: 'Insurance policy or claim reference.',
          acceptedTypes: <BundleItemType>[
            BundleItemType.document,
            BundleItemType.credential,
          ],
          keywords: <String>['insurance', 'policy', 'claim reference'],
          optional: true,
        ),
      ],
    ),
  ];

  static BundleTemplateDefinition? byKey(String? key) {
    final normalized = key?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    for (final template in templates) {
      if (template.key == normalized) {
        return template;
      }
    }
    return null;
  }

  static BundleTemplateProgress? progressFor({
    required String? templateKey,
    required List<BundleItemRef> items,
  }) {
    final template = byKey(templateKey);
    if (template == null) {
      return null;
    }
    final progress = template.requirements
        .map(
          (requirement) => BundleTemplateRequirementProgress(
            requirement: requirement,
            matches: items.where(requirement.matches).toList(growable: false),
          ),
        )
        .toList(growable: false);
    return BundleTemplateProgress(template: template, requirements: progress);
  }
}

String _normalizeText(String value) {
  if (value.trim().isEmpty) {
    return '';
  }
  const accents = <String, String>{
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
  };
  var normalized = value.toLowerCase();
  accents.forEach((key, replacement) {
    normalized = normalized.replaceAll(key, replacement);
  });
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
