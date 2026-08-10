import 'package:pass_doc_manager/domain/documents/entities/property_vault_entity.dart';

enum PropertyHubViewStatus { initial, loading, ready, error }

enum PropertyHubFilter { all, owned, rented }

class PropertyHubState {
  const PropertyHubState({
    required this.viewStatus,
    required this.properties,
    required this.filter,
    required this.errorMessage,
  });

  const PropertyHubState.initial()
    : viewStatus = PropertyHubViewStatus.initial,
      properties = const <PropertyVaultEntity>[],
      filter = PropertyHubFilter.all,
      errorMessage = null;

  final PropertyHubViewStatus viewStatus;
  final List<PropertyVaultEntity> properties;
  final PropertyHubFilter filter;
  final String? errorMessage;

  List<PropertyVaultEntity> get visibleProperties {
    switch (filter) {
      case PropertyHubFilter.all:
        return properties;
      case PropertyHubFilter.owned:
        return properties
            .where((property) {
              final normalized = property.ownershipStatusLabel
                  .trim()
                  .toLowerCase();
              return normalized.contains('own');
            })
            .toList(growable: false);
      case PropertyHubFilter.rented:
        return properties
            .where((property) {
              final normalized = property.ownershipStatusLabel
                  .trim()
                  .toLowerCase();
              return normalized.contains('rent') ||
                  normalized.contains('lease');
            })
            .toList(growable: false);
    }
  }

  PropertyHubState copyWith({
    PropertyHubViewStatus? viewStatus,
    List<PropertyVaultEntity>? properties,
    PropertyHubFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PropertyHubState(
      viewStatus: viewStatus ?? this.viewStatus,
      properties: properties ?? this.properties,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
