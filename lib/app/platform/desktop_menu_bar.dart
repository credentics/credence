import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

/// Menu action intents for the macOS native menu bar.
class NewCredentialIntent extends Intent {
  const NewCredentialIntent();
}

class NewCollectionIntent extends Intent {
  const NewCollectionIntent();
}

class ImportVaultIntent extends Intent {
  const ImportVaultIntent();
}

class ExportVaultIntent extends Intent {
  const ExportVaultIntent();
}

class LockVaultIntent extends Intent {
  const LockVaultIntent();
}

class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class ToggleSidebarIntent extends Intent {
  const ToggleSidebarIntent();
}

/// Wraps the app in a PlatformMenuBar on macOS.
/// On other platforms, just renders the child directly.
class DesktopMenuBarWrapper extends StatelessWidget {
  const DesktopMenuBarWrapper({
    super.key,
    required this.child,
    this.onNewCredential,
    this.onNewCollection,
    this.onImport,
    this.onExport,
    this.onLockVault,
    this.onSearch,
    this.onSettings,
    this.onToggleSidebar,
  });

  final Widget child;
  final VoidCallback? onNewCredential;
  final VoidCallback? onNewCollection;
  final VoidCallback? onImport;
  final VoidCallback? onExport;
  final VoidCallback? onLockVault;
  final VoidCallback? onSearch;
  final VoidCallback? onSettings;
  final VoidCallback? onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.isMacOS) {
      return child;
    }

    final l10n = context.l10n;

    return PlatformMenuBar(
      menus: [
        // App menu is handled automatically by macOS

        // File menu
        PlatformMenu(
          label: l10n.macMenuFile,
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: l10n.macMenuNewCredential,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyN,
                    meta: true,
                  ),
                  onSelected: onNewCredential,
                ),
                PlatformMenuItem(
                  label: l10n.macMenuNewCollection,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyN,
                    meta: true,
                    shift: true,
                  ),
                  onSelected: onNewCollection,
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: l10n.macMenuImportVault,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyI,
                    meta: true,
                    shift: true,
                  ),
                  onSelected: onImport,
                ),
                PlatformMenuItem(
                  label: l10n.macMenuExportVault,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyE,
                    meta: true,
                    shift: true,
                  ),
                  onSelected: onExport,
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: l10n.macMenuCloseWindow,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyW,
                    meta: true,
                  ),
                  onSelected: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ],
        ),

        // Edit menu
        PlatformMenu(
          label: l10n.macMenuEdit,
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: l10n.macMenuCopy,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyC,
                    meta: true,
                  ),
                  onSelected: () {},
                ),
                PlatformMenuItem(
                  label: l10n.macMenuPaste,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyV,
                    meta: true,
                  ),
                  onSelected: () {},
                ),
                PlatformMenuItem(
                  label: l10n.macMenuSelectAll,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    meta: true,
                  ),
                  onSelected: () {},
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: l10n.macMenuFind,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyF,
                    meta: true,
                  ),
                  onSelected: onSearch,
                ),
              ],
            ),
          ],
        ),

        // View menu
        PlatformMenu(
          label: l10n.macMenuView,
          menus: [
            PlatformMenuItem(
              label: l10n.macMenuToggleSidebar,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyS,
                meta: true,
                control: true,
              ),
              onSelected: onToggleSidebar,
            ),
          ],
        ),

        // Vault menu
        PlatformMenu(
          label: l10n.macMenuVault,
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: l10n.macMenuLockVault,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyL,
                    meta: true,
                  ),
                  onSelected: onLockVault,
                ),
                PlatformMenuItem(
                  label: l10n.macMenuSearchVault,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyF,
                    meta: true,
                  ),
                  onSelected: onSearch,
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: l10n.macMenuSettings,
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  onSelected: onSettings,
                ),
              ],
            ),
          ],
        ),
      ],
      child: child,
    );
  }
}
