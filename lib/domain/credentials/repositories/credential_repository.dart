import 'package:pass_doc_manager/domain/credentials/entities/credential_detail_entity.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_draft_entity.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_summary_entity.dart';

abstract class CredentialRepository {
  Future<List<CredentialSummaryEntity>> getCredentialSummaries();

  Future<CredentialDetailEntity> getCredentialDetail({required String id});

  Future<CredentialDetailEntity> createCredential({
    required CredentialDraftEntity draft,
  });

  Future<CredentialDetailEntity> updateCredential({
    required String id,
    required CredentialDraftEntity draft,
  });

  Future<void> markCredentialUsed({required String id});

  Future<void> toggleFavorite({required String id});

  Future<void> deleteCredential({required String id});
}
