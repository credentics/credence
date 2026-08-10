import 'package:pass_doc_manager/domain/branding/entities/company_brand_search_result_entity.dart';
import 'package:pass_doc_manager/domain/branding/repositories/company_brand_repository.dart';

class SearchCompanyBrands {
  SearchCompanyBrands(this._repository);

  final CompanyBrandRepository _repository;

  Future<List<CompanyBrandSearchResultEntity>> call({required String query}) {
    return _repository.searchCompanies(query: query);
  }
}
