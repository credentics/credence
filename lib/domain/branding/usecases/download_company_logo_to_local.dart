import 'package:pass_doc_manager/domain/branding/repositories/company_brand_repository.dart';

class DownloadCompanyLogoToLocal {
  DownloadCompanyLogoToLocal(this._repository);

  final CompanyBrandRepository _repository;

  Future<String?> call({required String iconUrl, required String domain}) {
    return _repository.downloadLogoToLocal(iconUrl: iconUrl, domain: domain);
  }
}
