import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

const String _sidebarFontDisplay = 'Manrope';
const String _sidebarFontBody = 'Manrope';

/// Sections available in the desktop navigation sidebar.
enum DesktopNavSection {
  home,
  credentials,
  documents,
  collections,
  bundles,
  tasks,
  generator,
  vaultHealth,
  profile,
  settings,
}

/// A collapsible navigation sidebar for desktop layouts.
/// Replaces the mobile bottom navigation bar entirely on macOS/Windows/Linux.
class DesktopNavSidebar extends StatelessWidget {
  const DesktopNavSidebar({
    super.key,
    required this.activeSection,
    required this.onSectionChanged,
    required this.isCollapsed,
    required this.onToggleCollapsed,
  });

  final DesktopNavSection activeSection;
  final ValueChanged<DesktopNavSection> onSectionChanged;
  final bool isCollapsed;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final width = isCollapsed ? 72.0 : 258.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(right: BorderSide(color: palette.stroke, width: 1)),
      ),
      child: Column(
        children: [
          // macOS traffic light inset
          if (DesktopPlatform.isMacOS) const SizedBox(height: 36),

          // App header
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCollapsed ? 12 : 18,
              18,
              isCollapsed ? 12 : 18,
              22,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: palette.shadow,
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 25,
                    color: Colors.white,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Credence',
                      style: TextStyle(
                        fontFamily: _sidebarFontDisplay,
                        fontSize: 21,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 10 : 12),
              child: Column(
                children: [
                  _NavItem(
                    icon: Icons.roofing_rounded,
                    label: l10n.navHome,
                    section: DesktopNavSection.home,
                    activeSection: activeSection,
                    isCollapsed: isCollapsed,
                    onTap: () => onSectionChanged(DesktopNavSection.home),
                    palette: palette,
                  ),
                  _NavItem(
                    icon: Icons.security_rounded,
                    label: l10n.navCredentials,
                    section: DesktopNavSection.credentials,
                    activeSection: activeSection,
                    isCollapsed: isCollapsed,
                    onTap: () =>
                        onSectionChanged(DesktopNavSection.credentials),
                    palette: palette,
                  ),
                  _NavItem(
                    icon: Icons.auto_awesome_mosaic_rounded,
                    label: l10n.navDocuments,
                    section: DesktopNavSection.documents,
                    activeSection: activeSection,
                    isCollapsed: isCollapsed,
                    onTap: () => onSectionChanged(DesktopNavSection.documents),
                    palette: palette,
                  ),
                  _NavItem(
                    icon: Icons.folder_rounded,
                    label: 'Collections',
                    section: DesktopNavSection.collections,
                    activeSection: activeSection,
                    isCollapsed: isCollapsed,
                    onTap: () =>
                        onSectionChanged(DesktopNavSection.collections),
                    palette: palette,
                  ),
                  _NavItem(
                    icon: Icons.folder_zip_rounded,
                    label: l10n.navBundles,
                    section: DesktopNavSection.bundles,
                    activeSection: activeSection,
                    isCollapsed: isCollapsed,
                    onTap: () => onSectionChanged(DesktopNavSection.bundles),
                    palette: palette,
                  ),
                  _NavItem(
                    icon: Icons.checklist_rounded,
                    label: l10n.navTasks,
                    section: DesktopNavSection.tasks,
                    activeSection: activeSection,
                    isCollapsed: isCollapsed,
                    onTap: () => onSectionChanged(DesktopNavSection.tasks),
                    palette: palette,
                  ),
                  const SizedBox(height: 14),
                  _SidebarDivider(palette: palette),
                  const SizedBox(height: 14),
                  _NavItem(
                    icon: Icons.casino_rounded,
                    label: 'Generator',
                    section: DesktopNavSection.generator,
                    activeSection: activeSection,
                    isCollapsed: isCollapsed,
                    onTap: () => onSectionChanged(DesktopNavSection.generator),
                    palette: palette,
                  ),
                  _NavItem(
                    icon: Icons.health_and_safety_rounded,
                    label: 'Vault Health',
                    section: DesktopNavSection.vaultHealth,
                    activeSection: activeSection,
                    isCollapsed: isCollapsed,
                    onTap: () =>
                        onSectionChanged(DesktopNavSection.vaultHealth),
                    palette: palette,
                  ),
                ],
              ),
            ),
          ),

          // Bottom actions
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 10 : 12,
              vertical: 14,
            ),
            child: Column(
              children: [
                _SidebarDivider(palette: palette),
                const SizedBox(height: 14),
                _NavItem(
                  icon: Icons.sentiment_satisfied_rounded,
                  label: l10n.navProfile,
                  section: DesktopNavSection.profile,
                  activeSection: activeSection,
                  isCollapsed: isCollapsed,
                  onTap: () => onSectionChanged(DesktopNavSection.profile),
                  palette: palette,
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  section: DesktopNavSection.settings,
                  activeSection: activeSection,
                  isCollapsed: isCollapsed,
                  onTap: () => onSectionChanged(DesktopNavSection.settings),
                  palette: palette,
                ),
                const SizedBox(height: 8),
                // Collapse toggle
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onToggleCollapsed,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isCollapsed
                            ? Icons.keyboard_double_arrow_right_rounded
                            : Icons.keyboard_double_arrow_left_rounded,
                        size: 20,
                        color: palette.textMuted,
                      ),
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

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, width: double.infinity, color: palette.stroke);
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.section,
    required this.activeSection,
    required this.isCollapsed,
    required this.onTap,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final DesktopNavSection section;
  final DesktopNavSection activeSection;
  final bool isCollapsed;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.section == widget.activeSection;
    final palette = widget.palette;

    final bgColor = isActive
        ? palette.primarySoft
        : _hovered
        ? palette.surfaceSoft
        : Colors.transparent;
    final iconColor = isActive ? palette.primary : palette.textSecondary;
    final textColor = isActive ? palette.primary : palette.textPrimary;
    final fontWeight = isActive ? FontWeight.w800 : FontWeight.w600;

    Widget item = Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? 0 : 16,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: widget.isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 24, color: iconColor),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _sidebarFontBody,
                  fontSize: 16,
                  height: 1.1,
                  fontWeight: fontWeight,
                  letterSpacing: -0.15,
                  color: textColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.isCollapsed) {
      item = Tooltip(
        message: widget.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 400),
        child: item,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: item),
    );
  }
}
