import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/id_entry_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class AddDocumentPage extends StatefulWidget {
  const AddDocumentPage({super.key});

  @override
  State<AddDocumentPage> createState() => _AddDocumentPageState();
}

class _AddDocumentPageState extends State<AddDocumentPage> {
  DocumentType _selectedType = DocumentType.passport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPalette.background,
      appBar: GenericAppBar(
        backgroundColor: context.appPalette.background,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.addDocumentTitle,
        titleStyle: TextStyle(
          fontSize: 19.5,
          fontWeight: FontWeight.w700,
          color: context.appPalette.textPrimary,
        ),
      ),
      bottomNavigationBar: _securityFooter(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                Text(
                  context.l10n.addDocumentSelectType,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.appPalette.textMuted,
                  ),
                ),
                SizedBox(height: 12),
                Column(
                  children: [
                    _TypeOptionTile(
                      type: DocumentType.passport,
                      icon: Icons.public_rounded,
                      iconColor: context.appPalette.primary,
                      iconBackground: context.appPalette.primarySoft,
                      subtitle: context.l10n.addDocumentPassportSubtitle,
                      active: _selectedType == DocumentType.passport,
                      onTap: () => _select(DocumentType.passport),
                    ),
                    const SizedBox(height: 10),
                    _TypeOptionTile(
                      type: DocumentType.idCard,
                      icon: Icons.badge_outlined,
                      iconColor: const Color(0xFF5A40D3),
                      iconBackground: const Color(0xFFECEBFF),
                      subtitle: context.l10n.addDocumentIdCardSubtitle,
                      active: _selectedType == DocumentType.idCard,
                      onTap: () => _select(DocumentType.idCard),
                    ),
                    const SizedBox(height: 10),
                    _TypeOptionTile(
                      type: DocumentType.driversLicense,
                      icon: Icons.sync_alt_rounded,
                      iconColor: const Color(0xFF008F6B),
                      iconBackground: const Color(0xFFE7F7F2),
                      subtitle: context.l10n.addDocumentDriversLicenseSubtitle,
                      active: _selectedType == DocumentType.driversLicense,
                      onTap: () => _select(DocumentType.driversLicense),
                    ),
                    const SizedBox(height: 10),
                    _TypeOptionTile(
                      type: DocumentType.other,
                      icon: Icons.note_add_outlined,
                      iconColor: const Color(0xFF6E7788),
                      iconBackground: const Color(0xFFF2F4F8),
                      subtitle: context.l10n.addDocumentOtherSubtitle,
                      active: _selectedType == DocumentType.other,
                      onTap: () => _select(DocumentType.other),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: context.appPalette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appPalette.stroke),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: context.appPalette.primary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.addDocumentInfoHint,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: context.appPalette.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityFooter() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: context.appPalette.surfaceSoft,
          border: Border(top: BorderSide(color: context.appPalette.strokeStrong)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A)),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                context.l10n.addDocumentSecurityFooter,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.appPalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(DocumentType type) async {
    setState(() {
      _selectedType = type;
    });
    await _openEntry(type: type);
  }

  Future<void> _openEntry({
    required DocumentType type,
    bool autoStartScan = false,
  }) async {
    final createdId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => IdEntryPage(type: type, autoStartScan: autoStartScan),
      ),
    );

    if (!mounted || createdId == null || createdId.trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop(createdId);
  }
}

class _TypeOptionTile extends StatelessWidget {
  const _TypeOptionTile({
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });

  final DocumentType type;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      DocumentType.driversLicense => "Driver's License",
      DocumentType.other => 'Other',
      _ => type.label,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: active ? context.appPalette.primary : context.appPalette.stroke,
              width: active ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: context.appPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
