import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/device_identity.dart';
import 'package:pass_doc_manager/features/backup/domain/repositories/backup_repository.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class BackupDevicePage extends StatelessWidget {
  const BackupDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: collectionsBackground,
      appBar: GenericAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.backupDeviceTitle,
        backgroundColor: collectionsBackground,
        showDivider: false,
      ),
      body: FutureBuilder<DeviceIdentity>(
        future: getIt<BackupRepository>().getDeviceIdentity(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator(radius: 12));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.backupDeviceUnableLoad,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => (context as Element).markNeedsBuild(),
                    child: Text(context.l10n.backupRetry),
                  ),
                ],
              ),
            );
          }

          final device = snapshot.data!;
          return SafeArea(
            top: false,
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    // Device identity card
                    CollectionsSurfaceCard(
                      radius: 22,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: context.appPalette.primarySoft,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _platformIcon(device.platform),
                                  size: 24,
                                  color: collectionsPrimary,
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.deviceName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: context.appPalette.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      device.platform,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: context.appPalette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _DeviceInfoRow(label: context.l10n.backupDeviceId, value: device.deviceId),
                          _DeviceInfoRow(label: context.l10n.backupDevicePlatform, value: device.platform),
                          _DeviceInfoRow(label: context.l10n.backupDeviceAppVersion, value: device.appVersion),
                          _DeviceInfoRow(
                            label: context.l10n.backupDeviceFirstSeen,
                            value: DateFormat('MMM d, y').format(device.firstSeenAt.toLocal()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active writer badge
                    CollectionsSurfaceCard(
                      radius: 16,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 20,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.backupDeviceActiveWriter,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.appPalette.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  context.l10n.backupDeviceActiveWriterDesc,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: context.appPalette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.l10n.commonActive,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _platformIcon(String platform) {
    final lower = platform.toLowerCase();
    if (lower.contains('ios') || lower.contains('iphone') || lower.contains('ipad')) {
      return Icons.phone_iphone_rounded;
    }
    if (lower.contains('android')) {
      return Icons.phone_android_rounded;
    }
    if (lower.contains('macos') || lower.contains('mac')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('windows')) {
      return Icons.laptop_windows_rounded;
    }
    if (lower.contains('linux')) {
      return Icons.computer_rounded;
    }
    return Icons.devices_rounded;
  }
}

class _DeviceInfoRow extends StatelessWidget {
  const _DeviceInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7788A4),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
