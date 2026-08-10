import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/branding/entities/company_brand_search_result_entity.dart';
import 'package:pass_doc_manager/features/credentials/presentation/widgets/company_logo_avatar.dart';

class CompanyBrandAutocompleteField extends StatelessWidget {
  const CompanyBrandAutocompleteField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.placeholder,
    required this.isLoading,
    required this.suggestions,
    required this.onChanged,
    required this.onSuggestionSelected,
  });

  final TextEditingController controller;
  final bool enabled;
  final String placeholder;
  final bool isLoading;
  final List<CompanyBrandSearchResultEntity> suggestions;
  final ValueChanged<String> onChanged;
  final FutureOr<void> Function(CompanyBrandSearchResultEntity item)
  onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'Service',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.appPalette.textPrimary,
              letterSpacing: -0.15,
            ),
            decoration:
                const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ).copyWith(
                  hintText: placeholder,
                  hintStyle: const TextStyle(
                    color: Color(0xFFB3B3BB),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            onChanged: onChanged,
          ),
        ),
        if (enabled && (isLoading || suggestions.isNotEmpty))
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Container(
              decoration: BoxDecoration(
                color: context.appPalette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.appPalette.stroke),
              ),
              child: Column(
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (!isLoading)
                    ...suggestions.map(
                      (item) => InkWell(
                        onTap: () {
                          final result = onSuggestionSelected(item);
                          if (result is Future<void>) {
                            unawaited(result);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          child: Row(
                            children: [
                              CompanyLogoAvatar(
                                serviceName: item.name,
                                serviceUrl: item.domain,
                                imageUrl: item.iconUrl,
                                size: 24,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: context.appPalette.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      item.domain,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8E8E93),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
