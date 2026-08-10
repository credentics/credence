import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/credentials/dtos/credential_create_dto.dart';
import 'package:pass_doc_manager/data/credentials/mappers/credential_detail_mapper.dart';
import 'package:pass_doc_manager/data/credentials/mappers/credential_summary_mapper.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_detail_entity.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_draft_entity.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_summary_entity.dart';
import 'package:pass_doc_manager/domain/credentials/repositories/credential_repository.dart';

class CredentialRepositoryImpl implements CredentialRepository {
  const CredentialRepositoryImpl({required this.localDataSource});

  final CredentialLocalDataSource localDataSource;

  @override
  Future<List<CredentialSummaryEntity>> getCredentialSummaries() async {
    final rows = await localDataSource.getCredentialSummaries();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  @override
  Future<CredentialDetailEntity> getCredentialDetail({
    required String id,
  }) async {
    final dto = await localDataSource.getCredentialDetailById(id: id);
    return dto.toEntity();
  }

  @override
  Future<CredentialDetailEntity> createCredential({
    required CredentialDraftEntity draft,
  }) async {
    final dto = await localDataSource.createCredential(
      draft: CredentialCreateDto(
        serviceName: draft.serviceName,
        accountLabel: draft.accountLabel,
        username: draft.username,
        categoryKey: draft.category.storageKey,
        password: draft.password,
        url: draft.url,
        notes: draft.notes,
        brandHex: draft.brandHex,
        logoPath: draft.logoPath,
      ),
    );

    return dto.toEntity();
  }

  @override
  Future<CredentialDetailEntity> updateCredential({
    required String id,
    required CredentialDraftEntity draft,
  }) async {
    final dto = await localDataSource.updateCredentialById(
      id: id,
      draft: CredentialCreateDto(
        serviceName: draft.serviceName,
        accountLabel: draft.accountLabel,
        username: draft.username,
        categoryKey: draft.category.storageKey,
        password: draft.password,
        url: draft.url,
        notes: draft.notes,
        brandHex: draft.brandHex,
        logoPath: draft.logoPath,
      ),
    );

    return dto.toEntity();
  }

  @override
  Future<void> markCredentialUsed({required String id}) {
    return localDataSource.markCredentialUsedById(id: id);
  }

  @override
  Future<void> toggleFavorite({required String id}) {
    return localDataSource.toggleFavorite(id: id);
  }

  @override
  Future<void> deleteCredential({required String id}) {
    return localDataSource.deleteCredentialById(id: id);
  }
}
