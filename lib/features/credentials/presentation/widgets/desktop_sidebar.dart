import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/credence_icon.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

enum DesktopSidebarSection {
  vault,
  documents,
  generator,
  security,
  importExport,
  settings,
}

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.activeSection,
    this.onVaultTap,
    this.onDocumentsTap,
    this.onGeneratorTap,
    this.onSecurityTap,
    this.onImportExportTap,
    this.onSettingsTap,
  });

  final DesktopSidebarSection activeSection;
  final VoidCallback? onVaultTap;
  final VoidCallback? onDocumentsTap;
  final VoidCallback? onGeneratorTap;
  final VoidCallback? onSecurityTap;
  final VoidCallback? onImportExportTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: 268,
      decoration: BoxDecoration(
        color: context.appPalette.backgroundAlt,
        border: Border(right: BorderSide(color: context.appPalette.strokeStrong)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                const CredenceIcon(size: 36),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      l10n.credentialsDesktopSubtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.appPalette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.appPalette.strokeStrong),
          const SizedBox(height: 6),
          _SidebarItem(
            icon: Icons.lock_outline,
            title: l10n.tabHome,
            active: activeSection == DesktopSidebarSection.vault,
            onTap: onVaultTap,
          ),
          _SidebarItem(
            icon: Icons.folder_open_rounded,
            title: l10n.tabDocuments,
            active: activeSection == DesktopSidebarSection.documents,
            onTap: onDocumentsTap,
          ),
          _SidebarItem(
            icon: Icons.auto_fix_high_rounded,
            title: l10n.tabGenerator,
            active: activeSection == DesktopSidebarSection.generator,
            onTap: onGeneratorTap,
          ),
          _SidebarItem(
            icon: Icons.shield_outlined,
            title: l10n.securitySettingsTitle,
            active: activeSection == DesktopSidebarSection.security,
            onTap: onSecurityTap,
          ),
          _SidebarItem(
            icon: Icons.upload_file_outlined,
            title: l10n.profileExportVaultData,
            active: activeSection == DesktopSidebarSection.importExport,
            onTap: onImportExportTap,
          ),
          _SidebarItem(
            icon: Icons.settings_outlined,
            title: l10n.settingsNavSettings,
            active: activeSection == DesktopSidebarSection.settings,
            onTap: onSettingsTap,
          ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appPalette.strokeStrong),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: context.appPalette.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.desktopLocalDataOnly,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appPalette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.title,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? context.appPalette.primary : context.appPalette.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: active ? context.appPalette.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
