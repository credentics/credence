import 'package:pass_doc_manager/data/branding/datasources/local/company_logo_local_data_source.dart';
import 'package:pass_doc_manager/data/branding/datasources/remote/brandfetch_search_remote_data_source.dart';
import 'package:pass_doc_manager/data/branding/mappers/brandfetch_search_item_mapper.dart';
import 'package:pass_doc_manager/domain/branding/entities/company_brand_search_result_entity.dart';
import 'package:pass_doc_manager/domain/branding/repositories/company_brand_repository.dart';

class CompanyBrandRepositoryImpl implements CompanyBrandRepository {
  const CompanyBrandRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final BrandfetchSearchRemoteDataSource remoteDataSource;
  final CompanyLogoLocalDataSource localDataSource;

  @override
  Future<List<CompanyBrandSearchResultEntity>> searchCompanies({
    required String query,
  }) async {
    final rows = await remoteDataSource.searchCompanies(query: query);
    return rows
        .map((it) => it.toEntity())
        .where((it) => it.domain.isNotEmpty && it.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<String?> downloadLogoToLocal({
    required String iconUrl,
    required String domain,
  }) {
    return localDataSource.downloadLogoToLocal(
      iconUrl: iconUrl,
      domain: domain,
    );
  }
}
