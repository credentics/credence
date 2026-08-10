import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_structured_field_kind.dart';

extension DocumentFieldLabelPresentationX on String {
  DocumentStructuredFieldKind get structuredFieldKind {
    return documentStructuredFieldKindFromLabel(this);
  }

  IconData get documentFieldIcon {
    return switch (structuredFieldKind) {
      DocumentStructuredFieldKind.identifier => Icons.tag_rounded,
      DocumentStructuredFieldKind.birthDate ||
      DocumentStructuredFieldKind.issueDate ||
      DocumentStructuredFieldKind.expiryDate ||
      DocumentStructuredFieldKind.updated => Icons.calendar_month_rounded,
      DocumentStructuredFieldKind.fullName => Icons.person_outline_rounded,
      DocumentStructuredFieldKind.country ||
      DocumentStructuredFieldKind.nationality => Icons.public_rounded,
      DocumentStructuredFieldKind.issuingAuthority =>
        Icons.account_balance_rounded,
      DocumentStructuredFieldKind.categories ||
      DocumentStructuredFieldKind.category => Icons.directions_car_outlined,
      DocumentStructuredFieldKind.unknown => Icons.info_outline_rounded,
    };
  }

  Color documentFieldTint(BuildContext context) {
    return switch (structuredFieldKind) {
      DocumentStructuredFieldKind.expiryDate => const Color(0xFFEF4444),
      DocumentStructuredFieldKind.issueDate => const Color(0xFF0F9F6E),
      _ => context.appPalette.primary,
    };
  }
}
