import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/create_bundle.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/delete_bundle.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/get_bundles.dart';
import 'package:pass_doc_manager/features/bundles/presentation/cubit/bundles_list_state.dart';

class BundlesListCubit extends Cubit<BundlesListState> {
  BundlesListCubit({
    GetBundles? getBundles,
    CreateBundle? createBundle,
    DeleteBundle? deleteBundle,
  }) : _getBundles = getBundles ?? getIt(),
       _createBundle = createBundle ?? getIt(),
       _deleteBundle = deleteBundle ?? getIt(),
       super(const BundlesListState.initial());

  final GetBundles _getBundles;
  final CreateBundle _createBundle;
  final DeleteBundle _deleteBundle;

  Future<void> load() async {
    emit(state.copyWith(status: BundlesListStatus.loading, clearError: true));
    try {
      final items = await _getBundles(const GetBundlesParams());
      emit(
        state.copyWith(
          status: BundlesListStatus.ready,
          bundles: items,
          clearError: true,
        ),
      );
    } catch (error, stack) {
      debugPrint('[Bundles] Failed to load: $error');
      debugPrintStack(stackTrace: stack);
      emit(state.copyWith(status: BundlesListStatus.error));
    }
  }

  Future<BundleEntity?> create({
    required String title,
    String? purpose,
    String? description,
    String? templateKey,
  }) async {
    try {
      final bundle = await _createBundle(
        CreateBundleParams(
          title: title,
          purpose: purpose,
          description: description,
          templateKey: templateKey,
        ),
      );
      await load();
      return bundle;
    } catch (error) {
      debugPrint('[Bundles] Failed to create: $error');
      return null;
    }
  }

  Future<void> delete(String bundleId) async {
    try {
      await _deleteBundle(DeleteBundleParams(bundleId: bundleId));
      await load();
    } catch (error) {
      debugPrint('[Bundles] Failed to delete: $error');
    }
  }
}
