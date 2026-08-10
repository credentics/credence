enum WorkDocumentFolderType {
  payslips,
  contracts,
  taxForms,
  offboarding,
  benefits,
  milestones,
  other,
}

extension WorkDocumentFolderTypeX on WorkDocumentFolderType {
  String get key {
    return switch (this) {
      WorkDocumentFolderType.payslips => 'payslips',
      WorkDocumentFolderType.contracts => 'contracts',
      WorkDocumentFolderType.taxForms => 'tax_forms',
      WorkDocumentFolderType.offboarding => 'offboarding',
      WorkDocumentFolderType.benefits => 'benefits',
      WorkDocumentFolderType.milestones => 'milestones',
      WorkDocumentFolderType.other => 'other',
    };
  }

  String get label {
    return switch (this) {
      WorkDocumentFolderType.payslips => 'Payslips',
      WorkDocumentFolderType.contracts => 'Contracts',
      WorkDocumentFolderType.taxForms => 'Tax Forms',
      WorkDocumentFolderType.offboarding => 'Offboarding',
      WorkDocumentFolderType.benefits => 'Benefits',
      WorkDocumentFolderType.milestones => 'Career Milestones',
      WorkDocumentFolderType.other => 'Other',
    };
  }

  String get subtitle {
    return switch (this) {
      WorkDocumentFolderType.payslips =>
        'Salary records and payroll statements',
      WorkDocumentFolderType.contracts => 'Employment and NDA agreements',
      WorkDocumentFolderType.taxForms => 'Tax reports and declarations',
      WorkDocumentFolderType.offboarding => 'Exit letters and handover records',
      WorkDocumentFolderType.benefits => 'Insurance and benefit plans',
      WorkDocumentFolderType.milestones => 'Promotions and performance reviews',
      WorkDocumentFolderType.other => 'Additional work records',
    };
  }
}

WorkDocumentFolderType parseWorkDocumentFolderType(String raw) {
  final normalized = raw.trim().toLowerCase();
  return switch (normalized) {
    'payslips' ||
    'payslip' ||
    'salary' ||
    'payroll' ||
    'salary slip' ||
    'salaryslip' => WorkDocumentFolderType.payslips,
    'contracts' ||
    'contract' ||
    'agreement' ||
    'nda' ||
    'non-compete' ||
    'noncompete' => WorkDocumentFolderType.contracts,
    'offboarding' ||
    'offboard' ||
    'exit' ||
    'resignation' ||
    'termination' ||
    'final settlement' ||
    'finalsettlement' ||
    'end of service' ||
    'endofservice' ||
    'solde' => WorkDocumentFolderType.offboarding,
    'tax_forms' ||
    'taxforms' ||
    'tax' ||
    'w2' ||
    'w-2' => WorkDocumentFolderType.taxForms,
    'benefits' || 'insurance' || 'coverage' => WorkDocumentFolderType.benefits,
    'milestones' ||
    'career' ||
    'promotion' ||
    'review' ||
    'reference' ||
    'training' => WorkDocumentFolderType.milestones,
    'quittance' || 'receipt' => WorkDocumentFolderType.other,
    _ => WorkDocumentFolderType.other,
  };
}
