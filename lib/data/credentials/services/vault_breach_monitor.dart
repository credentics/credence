import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/credentials/services/breach_check_service.dart';

class VaultBreachMonitor {
  VaultBreachMonitor({
    required BreachCheckService breachCheckService,
    required CredentialLocalDataSource credentialDataSource,
  }) : _breachCheckService = breachCheckService,
       _credentialDataSource = credentialDataSource;

  final BreachCheckService _breachCheckService;
  final CredentialLocalDataSource _credentialDataSource;

  /// Checks all credentials and returns list of breached credential IDs with
  /// counts.
  Future<List<BreachedCredentialResult>> checkAllCredentials() async {
    final summaries = await _credentialDataSource.getCredentialSummaries();
    final results = <BreachedCredentialResult>[];

    for (final summary in summaries) {
      final detail = await _credentialDataSource.getCredentialDetailById(
        id: summary.id,
      );
      final count = await _breachCheckService.checkPassword(detail.password);
      if (count > 0) {
        results.add(
          BreachedCredentialResult(
            credentialId: summary.id,
            serviceName: summary.displayName,
            breachCount: count,
          ),
        );
        // Persist the breach count so it shows in the UI immediately next time.
        await _credentialDataSource.updateBreachedCount(
          id: summary.id,
          breachedCount: count,
        );
      }
    }

    return results;
  }
}

class BreachedCredentialResult {
  const BreachedCredentialResult({
    required this.credentialId,
    required this.serviceName,
    required this.breachCount,
  });

  final String credentialId;
  final String serviceName;
  final int breachCount;
}
