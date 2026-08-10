class DocumentMetadataFieldLabels {
  const DocumentMetadataFieldLabels._();

  static const familyName = 'family_name';
  static const givenName = 'given_name';
  static const birthDate = 'birth_date';
  static const nationality = 'nationality';
  static const sex = 'sex';
  static const documentNumber = 'document_number';
  static const issuingCountry = 'issuing_country';
  static const expiryDate = 'expiry_date';
  static const portrait = 'portrait';
  static const ageOver18 = 'age_over_18';
  static const holderRelation = 'holder_relation';
  static const workCompanyId = 'work_company_id';
  static const workCompanyName = 'work_company_name';
  static const workRecordType = 'work_record_type';
  static const workCompanyLogoPath = 'work_company_logo_path';
  static const workFolderType = 'work_folder_type';
  static const workRole = 'work_role';
  static const workLocation = 'work_location';
  static const workEmployeeId = 'work_employee_id';
  static const workStartDate = 'work_start_date';
  static const workEndDate = 'work_end_date';
  static const workContact = 'work_contact';
  static const workAddress = 'work_address';
  static const workLastAccessAt = 'work_last_access_at';
  static const workStatementTitle = 'work_statement_title';
  static const workStatementDate = 'work_statement_date';
  static const workStatementNetAmount = 'work_statement_net_amount';
  static const workStatementCurrency = 'work_statement_currency';
  static const workStatementStatus = 'work_statement_status';
  static const workStatementLabel = 'work_statement_label';
  static const workPinned = 'work_pinned';
  static const workStorageQuotaMb = 'work_storage_quota_mb';
  static const propertyId = 'property_id';
  static const propertyName = 'property_name';
  static const propertyRecordType = 'property_record_type';
  static const propertyType = 'property_type';
  static const propertyOwnershipStatus = 'property_ownership_status';
  static const propertyFullAddress = 'property_full_address';
  static const propertyAddressSuggestionJson =
      'property_address_suggestion_json';
  static const propertyAssetType = 'property_asset_type';
  static const propertyOccupancyStatus = 'property_occupancy_status';
  static const propertyMonthlyAmount = 'property_monthly_amount';
  static const propertyIssueDate = 'property_issue_date';
  static const propertyPaymentAmount = 'property_payment_amount';
  static const propertyPaymentDate = 'property_payment_date';
  static const travelTripId = 'travel_trip_id';
  static const travelRecordType = 'travel_record_type';
  static const travelTripTitle = 'travel_trip_title';
  static const travelDestination = 'travel_destination';
  static const travelStartDate = 'travel_start_date';
  static const travelEndDate = 'travel_end_date';
  static const travelCoverImagePath = 'travel_cover_image_path';
  static const travelEventCategory = 'travel_event_category';
  static const travelEventDate = 'travel_event_date';
  static const travelEventTime = 'travel_event_time';
  static const travelEventLocation = 'travel_event_location';
  static const travelEventProvider = 'travel_event_provider';
  static const travelEventConfirmation = 'travel_event_confirmation';
  static const travelEventDocumentsCount = 'travel_event_documents_count';
  static const travelEventPreviewImagePath = 'travel_event_preview_image_path';
  static const travelExpenseCategory = 'travel_expense_category';
  static const travelExpenseAmount = 'travel_expense_amount';
  static const travelExpenseCurrency = 'travel_expense_currency';
  static const travelExpenseDate = 'travel_expense_date';
  static const travelExpenseTime = 'travel_expense_time';
  static const travelExpenseLocation = 'travel_expense_location';
  static const travelBudgetTotal = 'travel_budget_total';
  static const travelBudgetCurrency = 'travel_budget_currency';
  static const travelBudgetAllocationsJson = 'travel_budget_allocations_json';
  static const travelDocumentType = 'travel_document_type';
  static const travelLinkedEventId = 'travel_linked_event_id';
  static const travelNotes = 'travel_notes';

  static const Set<String> canonicalClaimKeys = <String>{
    familyName,
    givenName,
    birthDate,
    nationality,
    sex,
    documentNumber,
    issuingCountry,
    expiryDate,
    portrait,
    ageOver18,
    holderRelation,
    workCompanyId,
    workCompanyName,
    workRecordType,
    workCompanyLogoPath,
    workFolderType,
    workRole,
    workLocation,
    workEmployeeId,
    workStartDate,
    workEndDate,
    workContact,
    workAddress,
    workLastAccessAt,
    workStatementTitle,
    workStatementDate,
    workStatementNetAmount,
    workStatementCurrency,
    workStatementStatus,
    workStatementLabel,
    workPinned,
    workStorageQuotaMb,
    propertyId,
    propertyName,
    propertyRecordType,
    propertyType,
    propertyOwnershipStatus,
    propertyFullAddress,
    propertyAddressSuggestionJson,
    propertyAssetType,
    propertyOccupancyStatus,
    propertyMonthlyAmount,
    propertyIssueDate,
    propertyPaymentAmount,
    propertyPaymentDate,
    travelTripId,
    travelRecordType,
    travelTripTitle,
    travelDestination,
    travelStartDate,
    travelEndDate,
    travelCoverImagePath,
    travelEventCategory,
    travelEventDate,
    travelEventTime,
    travelEventLocation,
    travelEventProvider,
    travelEventConfirmation,
    travelEventDocumentsCount,
    travelEventPreviewImagePath,
    travelExpenseCategory,
    travelExpenseAmount,
    travelExpenseCurrency,
    travelExpenseDate,
    travelExpenseTime,
    travelExpenseLocation,
    travelBudgetTotal,
    travelBudgetCurrency,
    travelBudgetAllocationsJson,
    travelDocumentType,
    travelLinkedEventId,
    travelNotes,
  };

  static const claimPrefix = 'claim.';
  static const claimFamilyName = '$claimPrefix$familyName';
  static const claimGivenName = '$claimPrefix$givenName';
  static const claimBirthDate = '$claimPrefix$birthDate';
  static const claimNationality = '$claimPrefix$nationality';
  static const claimSex = '$claimPrefix$sex';
  static const claimDocumentNumber = '$claimPrefix$documentNumber';
  static const claimIssuingCountry = '$claimPrefix$issuingCountry';
  static const claimExpiryDate = '$claimPrefix$expiryDate';
  static const claimPortrait = '$claimPrefix$portrait';
  static const claimAgeOver18 = '$claimPrefix$ageOver18';
  static const claimHolderRelation = '$claimPrefix$holderRelation';
  static const claimWorkCompanyId = '$claimPrefix$workCompanyId';
  static const claimWorkCompanyName = '$claimPrefix$workCompanyName';
  static const claimWorkRecordType = '$claimPrefix$workRecordType';
  static const claimWorkCompanyLogoPath = '$claimPrefix$workCompanyLogoPath';
  static const claimWorkFolderType = '$claimPrefix$workFolderType';
  static const claimWorkRole = '$claimPrefix$workRole';
  static const claimWorkLocation = '$claimPrefix$workLocation';
  static const claimWorkEmployeeId = '$claimPrefix$workEmployeeId';
  static const claimWorkStartDate = '$claimPrefix$workStartDate';
  static const claimWorkEndDate = '$claimPrefix$workEndDate';
  static const claimWorkContact = '$claimPrefix$workContact';
  static const claimWorkAddress = '$claimPrefix$workAddress';
  static const claimWorkLastAccessAt = '$claimPrefix$workLastAccessAt';
  static const claimWorkStatementTitle = '$claimPrefix$workStatementTitle';
  static const claimWorkStatementDate = '$claimPrefix$workStatementDate';
  static const claimWorkStatementNetAmount =
      '$claimPrefix$workStatementNetAmount';
  static const claimWorkStatementCurrency =
      '$claimPrefix$workStatementCurrency';
  static const claimWorkStatementStatus = '$claimPrefix$workStatementStatus';
  static const claimWorkStatementLabel = '$claimPrefix$workStatementLabel';
  static const claimWorkPinned = '$claimPrefix$workPinned';
  static const claimWorkStorageQuotaMb = '$claimPrefix$workStorageQuotaMb';
  static const claimPropertyId = '$claimPrefix$propertyId';
  static const claimPropertyName = '$claimPrefix$propertyName';
  static const claimPropertyRecordType = '$claimPrefix$propertyRecordType';
  static const claimPropertyType = '$claimPrefix$propertyType';
  static const claimPropertyOwnershipStatus =
      '$claimPrefix$propertyOwnershipStatus';
  static const claimPropertyFullAddress = '$claimPrefix$propertyFullAddress';
  static const claimPropertyAddressSuggestionJson =
      '$claimPrefix$propertyAddressSuggestionJson';
  static const claimPropertyAssetType = '$claimPrefix$propertyAssetType';
  static const claimPropertyOccupancyStatus =
      '$claimPrefix$propertyOccupancyStatus';
  static const claimPropertyMonthlyAmount =
      '$claimPrefix$propertyMonthlyAmount';
  static const claimPropertyIssueDate = '$claimPrefix$propertyIssueDate';
  static const claimPropertyPaymentAmount =
      '$claimPrefix$propertyPaymentAmount';
  static const claimPropertyPaymentDate = '$claimPrefix$propertyPaymentDate';
  static const claimTravelTripId = '$claimPrefix$travelTripId';
  static const claimTravelRecordType = '$claimPrefix$travelRecordType';
  static const claimTravelTripTitle = '$claimPrefix$travelTripTitle';
  static const claimTravelDestination = '$claimPrefix$travelDestination';
  static const claimTravelStartDate = '$claimPrefix$travelStartDate';
  static const claimTravelEndDate = '$claimPrefix$travelEndDate';
  static const claimTravelCoverImagePath = '$claimPrefix$travelCoverImagePath';
  static const claimTravelEventCategory = '$claimPrefix$travelEventCategory';
  static const claimTravelEventDate = '$claimPrefix$travelEventDate';
  static const claimTravelEventTime = '$claimPrefix$travelEventTime';
  static const claimTravelEventLocation = '$claimPrefix$travelEventLocation';
  static const claimTravelEventProvider = '$claimPrefix$travelEventProvider';
  static const claimTravelEventConfirmation =
      '$claimPrefix$travelEventConfirmation';
  static const claimTravelEventDocumentsCount =
      '$claimPrefix$travelEventDocumentsCount';
  static const claimTravelEventPreviewImagePath =
      '$claimPrefix$travelEventPreviewImagePath';
  static const claimTravelExpenseCategory = '$claimPrefix$travelExpenseCategory';
  static const claimTravelExpenseAmount = '$claimPrefix$travelExpenseAmount';
  static const claimTravelExpenseCurrency =
      '$claimPrefix$travelExpenseCurrency';
  static const claimTravelExpenseDate = '$claimPrefix$travelExpenseDate';
  static const claimTravelExpenseTime = '$claimPrefix$travelExpenseTime';
  static const claimTravelExpenseLocation =
      '$claimPrefix$travelExpenseLocation';
  static const claimTravelBudgetTotal = '$claimPrefix$travelBudgetTotal';
  static const claimTravelBudgetCurrency = '$claimPrefix$travelBudgetCurrency';
  static const claimTravelBudgetAllocationsJson =
      '$claimPrefix$travelBudgetAllocationsJson';
  static const claimTravelDocumentType = '$claimPrefix$travelDocumentType';
  static const claimTravelLinkedEventId = '$claimPrefix$travelLinkedEventId';
  static const claimTravelNotes = '$claimPrefix$travelNotes';

  static const Map<String, String> _legacyClaimAliases = <String, String>{
    'primaryidentifier': familyName,
    'secondaryidentifier': givenName,
    'dateofbirth': birthDate,
    'nationality': nationality,
    'sex': sex,
    'documentnumber': documentNumber,
    'issuingstate': issuingCountry,
    'dateofexpiry': expiryDate,
    'faceimage': portrait,
    'ageover18': ageOver18,
    'isageover18': ageOver18,
    'over18': ageOver18,
    'holderrelation': holderRelation,
    'documentholderrelation': holderRelation,
    'relationship': holderRelation,
    'relation': holderRelation,
    'workcompanyid': workCompanyId,
    'companyid': workCompanyId,
    'workcompanyname': workCompanyName,
    'companyname': workCompanyName,
    'workrecordtype': workRecordType,
    'workrecordkind': workRecordType,
    'recordtype': workRecordType,
    'workcompanylogopath': workCompanyLogoPath,
    'companylogopath': workCompanyLogoPath,
    'logopath': workCompanyLogoPath,
    'workfoldertype': workFolderType,
    'foldertype': workFolderType,
    'workrole': workRole,
    'role': workRole,
    'position': workRole,
    'worklocation': workLocation,
    'location': workLocation,
    'workemployeeid': workEmployeeId,
    'employeeid': workEmployeeId,
    'workstartdate': workStartDate,
    'startdate': workStartDate,
    'workenddate': workEndDate,
    'enddate': workEndDate,
    'workcontact': workContact,
    'contact': workContact,
    'workaddress': workAddress,
    'officeaddress': workAddress,
    'address': workAddress,
    'worklastaccessat': workLastAccessAt,
    'lastaccess': workLastAccessAt,
    'workstatementtitle': workStatementTitle,
    'statementtitle': workStatementTitle,
    'workstatementdate': workStatementDate,
    'statementdate': workStatementDate,
    'workstatementnetamount': workStatementNetAmount,
    'netamount': workStatementNetAmount,
    'workstatementcurrency': workStatementCurrency,
    'currency': workStatementCurrency,
    'workstatementstatus': workStatementStatus,
    'statementstatus': workStatementStatus,
    'workstatementlabel': workStatementLabel,
    'statementlabel': workStatementLabel,
    'worklabel': workStatementLabel,
    'workpinned': workPinned,
    'pinned': workPinned,
    'workstoragequotamb': workStorageQuotaMb,
    'storagequotamb': workStorageQuotaMb,
    'propertyid': propertyId,
    'propertyname': propertyName,
    'propertyrecordtype': propertyRecordType,
    'propertytype': propertyType,
    'propertyownershipstatus': propertyOwnershipStatus,
    'ownershipstatus': propertyOwnershipStatus,
    'ownership': propertyOwnershipStatus,
    'propertystatus': propertyOwnershipStatus,
    'propertyfulladdress': propertyFullAddress,
    'fulladdress': propertyFullAddress,
    'propertyaddresssuggestionjson': propertyAddressSuggestionJson,
    'addresssuggestionjson': propertyAddressSuggestionJson,
    'propertyassettype': propertyAssetType,
    'assettype': propertyAssetType,
    'propertyoccupancystatus': propertyOccupancyStatus,
    'occupancystatus': propertyOccupancyStatus,
    'tenantstatus': propertyOccupancyStatus,
    'residentstatus': propertyOccupancyStatus,
    'propertymonthlyamount': propertyMonthlyAmount,
    'monthlyamount': propertyMonthlyAmount,
    'monthlyrent': propertyMonthlyAmount,
    'rentamount': propertyMonthlyAmount,
    'propertyissuedate': propertyIssueDate,
    'propertypaymentamount': propertyPaymentAmount,
    'paymentamount': propertyPaymentAmount,
    'amountpaid': propertyPaymentAmount,
    'paidamount': propertyPaymentAmount,
    'rentpaymentamount': propertyPaymentAmount,
    'propertypaymentdate': propertyPaymentDate,
    'paymentdate': propertyPaymentDate,
    'rentpaymentdate': propertyPaymentDate,
    'paidon': propertyPaymentDate,
    'traveltripid': travelTripId,
    'tripid': travelTripId,
    'travelrecordtype': travelRecordType,
    'recordkind': travelRecordType,
    'traveltriptitle': travelTripTitle,
    'triptitle': travelTripTitle,
    'traveldestination': travelDestination,
    'travelstartdate': travelStartDate,
    'travelenddate': travelEndDate,
    'travelcoverimagepath': travelCoverImagePath,
    'coverimagepath': travelCoverImagePath,
    'travelcoverpath': travelCoverImagePath,
    'traveleventcategory': travelEventCategory,
    'eventcategory': travelEventCategory,
    'traveleventdate': travelEventDate,
    'eventdate': travelEventDate,
    'traveleventtime': travelEventTime,
    'eventtime': travelEventTime,
    'traveleventlocation': travelEventLocation,
    'eventlocation': travelEventLocation,
    'traveleventprovider': travelEventProvider,
    'eventprovider': travelEventProvider,
    'traveleventconfirmation': travelEventConfirmation,
    'eventconfirmation': travelEventConfirmation,
    'bookingreference': travelEventConfirmation,
    'reservationnumber': travelEventConfirmation,
    'traveleventdocumentscount': travelEventDocumentsCount,
    'documentscount': travelEventDocumentsCount,
    'traveleventpreviewimagepath': travelEventPreviewImagePath,
    'previewimagepath': travelEventPreviewImagePath,
    'travelexpensecategory': travelExpenseCategory,
    'expensecategory': travelExpenseCategory,
    'travelexpenseamount': travelExpenseAmount,
    'expenseamount': travelExpenseAmount,
    'travelexpensecurrency': travelExpenseCurrency,
    'expensecurrency': travelExpenseCurrency,
    'travelexpensedate': travelExpenseDate,
    'expensedate': travelExpenseDate,
    'travelexpensetime': travelExpenseTime,
    'expensetime': travelExpenseTime,
    'travelexpenselocation': travelExpenseLocation,
    'expenselocation': travelExpenseLocation,
    'travelbudgettotal': travelBudgetTotal,
    'budgettotal': travelBudgetTotal,
    'travelbudgetcurrency': travelBudgetCurrency,
    'budgetcurrency': travelBudgetCurrency,
    'travelbudgetallocationsjson': travelBudgetAllocationsJson,
    'budgetallocationsjson': travelBudgetAllocationsJson,
    'traveldocumenttype': travelDocumentType,
    'travellinkedeventid': travelLinkedEventId,
    'linkedeventid': travelLinkedEventId,
    'travelnotes': travelNotes,
  };

  static final RegExp _separatorPattern = RegExp(r'[\s_\-.]');

  static String _compactKey(String rawValue) {
    return rawValue.trim().toLowerCase().replaceAll(_separatorPattern, '');
  }

  static String? toCanonicalClaimKey(String rawLabel) {
    final normalized = rawLabel.trim().toLowerCase();
    if (canonicalClaimKeys.contains(normalized)) {
      return normalized;
    }

    if (normalized.startsWith(claimPrefix)) {
      final withoutPrefix = normalized.substring(claimPrefix.length);
      if (canonicalClaimKeys.contains(withoutPrefix)) {
        return withoutPrefix;
      }
    }

    return _legacyClaimAliases[_compactKey(normalized)];
  }

  static bool isClaimFieldLabel(String rawLabel) {
    return toCanonicalClaimKey(rawLabel) != null;
  }

  static const frontImagePath = 'Front Image Path';
  static const backImagePath = 'Back Image Path';
  static const previewImagePath = 'Preview Image Path';
  static const previewImageEnabled = 'Preview Image Enabled';
  static const referenceAssetName = 'Reference Asset Name';
  static const referenceAssetLabel = 'Reference Asset Label';
  static const referenceAssetPath = 'Reference Asset Path';
  static const referenceAssetMime = 'Reference Asset Mime';
  static const referenceAssetsJson = 'Reference Assets Json';
}
