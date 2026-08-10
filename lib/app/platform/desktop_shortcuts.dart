import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/platform/desktop_menu_bar.dart';

/// Wraps a widget with global keyboard shortcuts for desktop platforms.
/// On mobile, passes through without modification.
class DesktopShortcutsWrapper extends StatelessWidget {
  const DesktopShortcutsWrapper({
    super.key,
    required this.child,
    this.onNewCredential,
    this.onSearch,
    this.onSettings,
    this.onLockVault,
    this.onToggleSidebar,
    this.onDelete,
  });

  final Widget child;
  final VoidCallback? onNewCredential;
  final VoidCallback? onSearch;
  final VoidCallback? onSettings;
  final VoidCallback? onLockVault;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.isDesktop) return child;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
            const NewCredentialIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            const OpenSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.comma, meta: true):
            const OpenSettingsIntent(),
        const SingleActivator(LogicalKeyboardKey.keyL, meta: true):
            const LockVaultIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true, control: true):
            const ToggleSidebarIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const DismissIntent(),
        // Windows/Linux use Ctrl instead of Cmd
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            const NewCredentialIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            const OpenSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
            const OpenSettingsIntent(),
        const SingleActivator(LogicalKeyboardKey.keyL, control: true):
            const LockVaultIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewCredentialIntent: CallbackAction<NewCredentialIntent>(
            onInvoke: (_) {
              onNewCredential?.call();
              return null;
            },
          ),
          OpenSearchIntent: CallbackAction<OpenSearchIntent>(
            onInvoke: (_) {
              onSearch?.call();
              return null;
            },
          ),
          OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
            onInvoke: (_) {
              onSettings?.call();
              return null;
            },
          ),
          LockVaultIntent: CallbackAction<LockVaultIntent>(
            onInvoke: (_) {
              onLockVault?.call();
              return null;
            },
          ),
          ToggleSidebarIntent: CallbackAction<ToggleSidebarIntent>(
            onInvoke: (_) {
              onToggleSidebar?.call();
              return null;
            },
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}
