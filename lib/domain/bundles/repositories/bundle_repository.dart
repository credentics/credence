import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_status.dart';

abstract class BundleRepository {
  Future<List<BundleEntity>> getBundles();

  Future<BundleEntity> getBundleById({required String bundleId});

  Future<BundleEntity> createBundle({
    required String title,
    String? purpose,
    String? description,
    String? templateKey,
  });

  /// Persists the whole bundle. Callers are responsible for bumping
  /// `updatedAt` and appending any relevant history events before calling.
  Future<BundleEntity> saveBundle(BundleEntity bundle);

  Future<void> deleteBundle({required String bundleId});

  /// Appends an item to the bundle, records an `itemAdded` history event,
  /// and bumps `updatedAt`. Items already present (same type + refId) are
  /// treated as a no-op and the existing bundle is returned.
  Future<BundleEntity> addItem({
    required String bundleId,
    required BundleItemRef item,
  });

  /// Removes the item with the given intra-bundle id. Records an
  /// `itemRemoved` history event and bumps `updatedAt`.
  Future<BundleEntity> removeItem({
    required String bundleId,
    required String itemId,
  });

  /// Updates status and records a `statusChanged` history event.
  Future<BundleEntity> setStatus({
    required String bundleId,
    required BundleStatus status,
  });
}
