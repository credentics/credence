import 'package:pass_doc_manager/data/branding/dtos/brandfetch_search_item_dto.dart';
import 'package:pass_doc_manager/domain/branding/entities/company_brand_search_result_entity.dart';

extension BrandfetchSearchItemMapper on BrandfetchSearchItemDto {
  CompanyBrandSearchResultEntity toEntity() {
    return CompanyBrandSearchResultEntity(
      name: (name ?? '').trim().isEmpty ? (domain ?? '').trim() : name!.trim(),
      domain: (domain ?? '').trim(),
      iconUrl: (icon ?? '').trim(),
    );
  }
}
