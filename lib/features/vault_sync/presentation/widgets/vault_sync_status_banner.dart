import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/sync/vault_sync_coordinator.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

const _syncFontDisplay = 'Manrope';
const _syncFontMono = 'JetBrains Mono';

class VaultSyncStatusBanner extends StatelessWidget {
  const VaultSyncStatusBanner({super.key, this.desktop = false});

  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final coordinator = getIt<VaultSyncCoordinator>();
    return AnimatedBuilder(
      animation: coordinator,
      builder: (context, _) {
        if (!_shouldShow(coordinator.state)) {
          return const SizedBox.shrink();
        }
        return _SyncStatusSurface(coordinator: coordinator, desktop: desktop);
      },
    );
  }

  bool _shouldShow(VaultSyncCoordinatorState state) {
    return switch (state) {
      VaultSyncCoordinatorState.checking ||
      VaultSyncCoordinatorState.remoteAvailable ||
      VaultSyncCoordinatorState.syncing ||
      VaultSyncCoordinatorState.success ||
      VaultSyncCoordinatorState.error => true,
      VaultSyncCoordinatorState.idle ||
      VaultSyncCoordinatorState.paused => false,
    };
  }
}

class VaultSyncHomeSignalCard extends StatelessWidget {
  const VaultSyncHomeSignalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final coordinator = getIt<VaultSyncCoordinator>();
    return AnimatedBuilder(
      animation: coordinator,
      builder: (context, _) {
        if (!coordinator.hasRemoteChanges) return const SizedBox.shrink();
        final palette = context.appPalette;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.stroke),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.sync_rounded,
                  color: palette.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coordinator.message,
                      style: TextStyle(
                        fontFamily: _syncFontDisplay,
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      coordinator.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _syncFontDisplay,
                        color: palette.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: coordinator.isBusy
                    ? null
                    : coordinator.syncFromRemoteNow,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.textPrimary,
                  foregroundColor: palette.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Sync now',
                  style: TextStyle(
                    fontFamily: _syncFontDisplay,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SyncStatusSurface extends StatelessWidget {
  const _SyncStatusSurface({required this.coordinator, required this.desktop});

  final VaultSyncCoordinator coordinator;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final statusColor = _statusColor(palette, coordinator.state);
    final statusIcon = _statusIcon(coordinator.state);
    final width = desktop ? 460.0 : double.infinity;

    return Align(
      alignment: desktop ? Alignment.bottomRight : Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Material(
          color: palette.surface,
          elevation: 12,
          shadowColor: palette.shadow.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.stroke),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 19),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coordinator.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _syncFontDisplay,
                              color: palette.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.15,
                            ),
                          ),
                          if (coordinator.detail.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              coordinator.detail,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _syncFontDisplay,
                                color: palette.textSecondary,
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SyncActionButton(coordinator: coordinator),
                  ],
                ),
                if (coordinator.progress != null &&
                    (coordinator.state == VaultSyncCoordinatorState.checking ||
                        coordinator.state ==
                            VaultSyncCoordinatorState.syncing)) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: coordinator.progress!.clamp(0, 1).toDouble(),
                      minHeight: 4,
                      color: statusColor,
                      backgroundColor: palette.surfaceSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(AppPalette palette, VaultSyncCoordinatorState state) {
    return switch (state) {
      VaultSyncCoordinatorState.remoteAvailable => palette.primary,
      VaultSyncCoordinatorState.success => palette.success,
      VaultSyncCoordinatorState.error => palette.danger,
      VaultSyncCoordinatorState.checking ||
      VaultSyncCoordinatorState.syncing => palette.primary,
      VaultSyncCoordinatorState.idle ||
      VaultSyncCoordinatorState.paused => palette.textMuted,
    };
  }

  IconData _statusIcon(VaultSyncCoordinatorState state) {
    return switch (state) {
      VaultSyncCoordinatorState.remoteAvailable => Icons.cloud_download_rounded,
      VaultSyncCoordinatorState.success => Icons.check_rounded,
      VaultSyncCoordinatorState.error => Icons.error_outline_rounded,
      VaultSyncCoordinatorState.checking => Icons.sync_rounded,
      VaultSyncCoordinatorState.syncing => Icons.cloud_sync_rounded,
      VaultSyncCoordinatorState.idle ||
      VaultSyncCoordinatorState.paused => Icons.sync_disabled_rounded,
    };
  }
}

class _SyncActionButton extends StatelessWidget {
  const _SyncActionButton({required this.coordinator});

  final VaultSyncCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final label = switch (coordinator.state) {
      VaultSyncCoordinatorState.remoteAvailable => 'Sync now',
      VaultSyncCoordinatorState.error => 'Retry',
      _ => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return TextButton(
      onPressed: coordinator.isBusy
          ? null
          : () {
              if (coordinator.state ==
                  VaultSyncCoordinatorState.remoteAvailable) {
                coordinator.syncFromRemoteNow();
                return;
              }
              coordinator.checkNow(force: true, reason: 'retry');
            },
      style: TextButton.styleFrom(
        foregroundColor: palette.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: _syncFontMono,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.65,
        ),
      ),
    );
  }
}
