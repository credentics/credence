import 'package:pass_doc_manager/domain/branding/entities/company_brand_search_result_entity.dart';

abstract class CompanyBrandRepository {
  Future<List<CompanyBrandSearchResultEntity>> searchCompanies({
    required String query,
  });

  Future<String?> downloadLogoToLocal({
    required String iconUrl,
    required String domain,
  });
}
