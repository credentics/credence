// ignore_for_file: unused_element_parameter

part of '../backup_settings_page.dart';

class _ICloudSection extends StatelessWidget {
  const _ICloudSection({
    required this.isUploading,
    required this.isBusy,
    required this.hasBackups,
  });

  final bool isUploading;
  final bool isBusy;
  final bool hasBackups;

  @override
  Widget build(BuildContext context) {
    return CollectionsSurfaceCard(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.appPalette.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.cloud_rounded,
                  size: 20,
                  color: Color(0xFF4285F4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'iCloud',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontDisplay,
                        fontSize: 15.5,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.05,
                        color: context.appPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.backupAppleIdAutomatic,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: settingsFontDisplay,
                        fontSize: 13,
                        height: 1.05,
                        fontWeight: FontWeight.w600,
                        color: context.appPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Color(0xFFE8890C),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'iCloud backup is managed by the OS. Make sure you are '
                    'signed into iCloud on this device. No additional '
                    'authentication is needed.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7A5500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasBackups) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: isUploading || isBusy
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.backupICloudComingSoon),
                          ),
                        );
                      },
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: Text(
                  context.l10n.backupUploadToICloud,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4285F4),
                  side: const BorderSide(color: Color(0xFF4285F4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Dropbox Section ──
