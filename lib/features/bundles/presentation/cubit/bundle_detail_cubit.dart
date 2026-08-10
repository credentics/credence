import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_status.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/add_item_to_bundle.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/get_bundle_detail.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/remove_item_from_bundle.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/save_bundle.dart';
import 'package:pass_doc_manager/features/bundles/presentation/cubit/bundle_detail_state.dart';

class BundleDetailCubit extends Cubit<BundleDetailState> {
  BundleDetailCubit({
    required this.bundleId,
    GetBundleDetail? getBundleDetail,
    SaveBundle? saveBundle,
    AddItemToBundle? addItemToBundle,
    RemoveItemFromBundle? removeItemFromBundle,
    BundleRepository? repository,
  }) : _getBundleDetail = getBundleDetail ?? getIt(),
       _saveBundle = saveBundle ?? getIt(),
       _addItem = addItemToBundle ?? getIt(),
       _removeItem = removeItemFromBundle ?? getIt(),
       _repository = repository ?? getIt(),
       super(const BundleDetailState.initial());

  final String bundleId;
  final GetBundleDetail _getBundleDetail;
  final SaveBundle _saveBundle;
  final AddItemToBundle _addItem;
  final RemoveItemFromBundle _removeItem;
  final BundleRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: BundleDetailStatus.loading, clearError: true));
    try {
      final bundle = await _getBundleDetail(
        GetBundleDetailParams(bundleId: bundleId),
      );
      emit(
        state.copyWith(
          status: BundleDetailStatus.ready,
          bundle: bundle,
          clearError: true,
        ),
      );
    } catch (error, stack) {
      debugPrint('[BundleDetail] Failed to load: $error');
      debugPrintStack(stackTrace: stack);
      emit(state.copyWith(status: BundleDetailStatus.error));
    }
  }

  Future<void> rename({
    required String title,
    String? purpose,
    String? description,
  }) async {
    final current = state.bundle;
    if (current == null) return;
    try {
      final updated = current.copyWith(
        title: title,
        purpose: purpose,
        clearPurpose: purpose == null,
        description: description,
        clearDescription: description == null,
      );
      await _saveBundle(SaveBundleParams(bundle: updated));
      await load();
    } catch (error) {
      debugPrint('[BundleDetail] Failed to rename: $error');
    }
  }

  Future<void> addItem(BundleItemRef item) async {
    try {
      await _addItem(
        AddItemToBundleParams(bundleId: bundleId, item: item),
      );
      await load();
    } catch (error) {
      debugPrint('[BundleDetail] Failed to add item: $error');
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await _removeItem(
        RemoveItemFromBundleParams(bundleId: bundleId, itemId: itemId),
      );
      await load();
    } catch (error) {
      debugPrint('[BundleDetail] Failed to remove item: $error');
    }
  }

  Future<void> setStatus(BundleStatus status) async {
    try {
      await _repository.setStatus(bundleId: bundleId, status: status);
      await load();
    } catch (error) {
      debugPrint('[BundleDetail] Failed to set status: $error');
    }
  }

  Future<void> refresh() => load();
}
