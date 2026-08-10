import 'package:pass_doc_manager/data/branding/dtos/brandfetch_search_item_dto.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'brandfetch_search_api.g.dart';

@RestApi(baseUrl: 'https://api.brandfetch.io')
abstract class BrandfetchSearchApi {
  factory BrandfetchSearchApi(Dio dio, {String baseUrl}) = _BrandfetchSearchApi;

  @GET('/v2/search/{query}')
  Future<List<BrandfetchSearchItemDto>> searchCompanies({
    @Path('query') required String query,
    @Query('c') required String clientId,
  });
}
