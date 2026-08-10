import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_chain.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/device_identity.dart';
import 'package:pass_doc_manager/features/backup/domain/repositories/backup_repository.dart';
import 'package:pass_doc_manager/features/collections/presentation/widgets/collections_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class BackupHealthPage extends StatefulWidget {
  const BackupHealthPage({super.key});

  @override
  State<BackupHealthPage> createState() => _BackupHealthPageState();
}

class _BackupHealthPageState extends State<BackupHealthPage> {
  late Future<_HealthData> _dataFuture;
  ChainValidationResult? _validationResult;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_HealthData> _loadData() async {
    final repo = getIt<BackupRepository>();
    final chain = await repo.getActiveChain();
    final backups = await repo.listBackups();
    final device = await repo.getDeviceIdentity();

    int totalStorageBytes = 0;
    for (final b in backups) {
      totalStorageBytes += b.archiveSizeBytes;
    }

    String? encryptionAlgorithm;
    DateTime? lastBackupDate;
    if (backups.isNotEmpty) {
      encryptionAlgorithm = backups.first.encryptionAlgorithm;
      lastBackupDate = backups.first.createdAt;
    }

    return _HealthData(
      chain: chain,
      backupCount: backups.length,
      totalStorageBytes: totalStorageBytes,
      encryptionAlgorithm: encryptionAlgorithm,
      lastBackupDate: lastBackupDate,
      device: device,
    );
  }

  Future<void> _runIntegrityCheck() async {
    setState(() {
      _isValidating = true;
      _validationResult = null;
    });
    try {
      final result = await getIt<BackupRepository>().validateChain();
      if (mounted) {
        setState(() {
          _validationResult = result;
          _isValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationResult = const ChainValidationResult(
            status: ChainValidationStatus.broken,
            message: 'Validation failed unexpectedly.',
          );
          _isValidating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: collectionsBackground,
      appBar: GenericAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        title: context.l10n.backupHealthTitle,
        backgroundColor: collectionsBackground,
        showDivider: false,
      ),
      body: FutureBuilder<_HealthData>(
        future: _dataFuture,
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
                    context.l10n.backupHealthUnableLoad,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _dataFuture = _loadData()),
                    child: Text(context.l10n.backupRetry),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
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
                    // Chain Status
                    CollectionsSectionLabel(label: context.l10n.backupHealthChainStatus),
                    const SizedBox(height: 10),
                    CollectionsSurfaceCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _HealthRow(
                            label: context.l10n.backupHealthStatus,
                            value: data.chain.isEmpty ? context.l10n.backupHealthStatusEmpty : context.l10n.backupHealthStatusActive,
                            valueColor: data.chain.isEmpty
                                ? const Color(0xFFE65100)
                                : const Color(0xFF2E7D32),
                          ),
                          _HealthRow(label: context.l10n.backupHealthChainDepth, value: '${data.chain.depth}'),
                          _HealthRow(
                            label: context.l10n.backupHealthBaseDate,
                            value: data.chain.base != null
                                ? DateFormat('MMM d, y').format(data.chain.base!.createdAt.toLocal())
                                : '--',
                          ),
                          _HealthRow(
                            label: context.l10n.backupHealthHeadDate,
                            value: data.chain.head != null
                                ? DateFormat('MMM d, y').format(data.chain.head!.createdAt.toLocal())
                                : '--',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Backup Stats
                    CollectionsSectionLabel(label: context.l10n.backupHealthStats),
                    const SizedBox(height: 10),
                    CollectionsSurfaceCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _HealthRow(
                            label: context.l10n.backupHealthLastBackup,
                            value: data.lastBackupDate != null
                                ? DateFormat('MMM d, y - hh:mm a').format(data.lastBackupDate!.toLocal())
                                : context.l10n.backupHealthNever,
                          ),
                          _HealthRow(label: context.l10n.backupHealthTotalBackups, value: '${data.backupCount}'),
                          _HealthRow(label: context.l10n.backupHealthStorageUsed, value: _formatBytes(data.totalStorageBytes)),
                          _HealthRow(label: context.l10n.backupHealthEncryption, value: data.encryptionAlgorithm ?? 'None'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Device Info
                    CollectionsSectionLabel(label: context.l10n.backupHealthDevice),
                    const SizedBox(height: 10),
                    CollectionsSurfaceCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _HealthRow(label: context.l10n.backupHealthName, value: data.device.deviceName),
                          _HealthRow(label: context.l10n.backupDevicePlatform, value: data.device.platform),
                          _HealthRow(label: context.l10n.backupDeviceId, value: _truncateId(data.device.deviceId)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Integrity Check
                    CollectionsSectionLabel(label: context.l10n.backupHealthIntegrity),
                    const SizedBox(height: 10),

                    if (_validationResult != null) ...[
                      _IntegrityResultCard(result: _validationResult!),
                      const SizedBox(height: 12),
                    ],

                    CollectionsPrimaryButton(
                      icon: Icons.verified_rounded,
                      label: _isValidating ? context.l10n.backupHealthChecking : context.l10n.backupHealthRunCheck,
                      onPressed: _isValidating ? null : _runIntegrityCheck,
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.backupHealthRebuildNotAvailable),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.build_rounded, size: 20),
                        label: Text(
                          context.l10n.backupHealthRebuildChain,
                          style: const TextStyle(
                            fontSize: 23 / 1.45,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: collectionsPrimary,
                          side: const BorderSide(color: collectionsPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
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
}

class _HealthData {
  const _HealthData({
    required this.chain,
    required this.backupCount,
    required this.totalStorageBytes,
    required this.encryptionAlgorithm,
    required this.lastBackupDate,
    required this.device,
  });

  final BackupChain chain;
  final int backupCount;
  final int totalStorageBytes;
  final String? encryptionAlgorithm;
  final DateTime? lastBackupDate;
  final DeviceIdentity device;
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
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
                color: valueColor ?? context.appPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrityResultCard extends StatelessWidget {
  const _IntegrityResultCard({required this.result});

  final ChainValidationResult result;

  @override
  Widget build(BuildContext context) {
    final isValid = result.isValid;
    final bgColor = isValid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF4F2);
    final fgColor = isValid ? const Color(0xFF2E7D32) : const Color(0xFFB42318);
    final icon = isValid ? Icons.check_circle_rounded : Icons.error_rounded;
    final statusLabel = isValid ? 'Chain is valid' : 'Chain issue detected';
    final message = result.message;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: fgColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: fgColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _truncateId(String id) {
  if (id.length <= 16) return id;
  return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
}
