import 'package:json_annotation/json_annotation.dart';

part 'brandfetch_search_item_dto.g.dart';

@JsonSerializable()
class BrandfetchSearchItemDto {
  const BrandfetchSearchItemDto({
    required this.name,
    required this.domain,
    required this.icon,
  });

  final String? name;
  final String? domain;
  final String? icon;

  factory BrandfetchSearchItemDto.fromJson(Map<String, dynamic> json) =>
      _$BrandfetchSearchItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BrandfetchSearchItemDtoToJson(this);
}
