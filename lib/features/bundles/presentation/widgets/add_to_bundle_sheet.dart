import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';
import 'package:pass_doc_manager/domain/bundles/usecases/add_item_to_bundle.dart';
import 'package:pass_doc_manager/features/bundles/presentation/cubit/bundles_list_cubit.dart';
import 'package:pass_doc_manager/features/bundles/presentation/cubit/bundles_list_state.dart';
import 'package:pass_doc_manager/features/bundles/presentation/pages/bundle_create_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

/// Candidate that the caller wants to push into a bundle.
class BundleItemCandidate {
  const BundleItemCandidate({
    required this.type,
    required this.refId,
    required this.displayName,
    this.subtitle,
  });

  final BundleItemType type;
  final String refId;
  final String displayName;
  final String? subtitle;
}

/// Opens a modal sheet that lets the user pick an existing bundle (or
/// create a new one) and adds the candidate(s) to it.
///
/// Returns the id of the target bundle on success, null if the user
/// dismissed the sheet.
Future<String?> showAddToBundleSheet(
  BuildContext context, {
  required List<BundleItemCandidate> candidates,
}) {
  if (candidates.isEmpty) return Future.value(null);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider(
      create: (_) => BundlesListCubit()..load(),
      child: _AddToBundleSheet(candidates: candidates),
    ),
  );
}

class _AddToBundleSheet extends StatelessWidget {
  const _AddToBundleSheet({required this.candidates});

  final List<BundleItemCandidate> candidates;

  Future<void> _addTo(BuildContext context, BundleEntity bundle) async {
    final addUsecase = getIt<AddItemToBundle>();
    final now = DateTime.now();
    for (final candidate in candidates) {
      await addUsecase(
        AddItemToBundleParams(
          bundleId: bundle.id,
          item: BundleItemRef(
            id: '',
            type: candidate.type,
            refId: candidate.refId,
            displayName: candidate.displayName,
            subtitle: candidate.subtitle,
            addedAt: now,
          ),
        ),
      );
    }
    if (!context.mounted) return;
    Navigator.of(context).pop(bundle.id);
  }

  Future<void> _createAndAdd(BuildContext context) async {
    final listCubit = context.read<BundlesListCubit>();
    final created = await Navigator.of(context).push<BundleEntity>(
      MaterialPageRoute(
        builder: (_) => BundleCreatePage(listCubit: listCubit),
      ),
    );
    if (created == null || !context.mounted) return;
    await _addTo(context, created);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.bundleAddToTitle,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _createAndAdd(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.bundleAddToNew),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  l10n.bundleAddToSubtitle(candidates.length),
                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                ),
              ),
              Divider(height: 1, color: palette.stroke),
              Expanded(
                child: BlocBuilder<BundlesListCubit, BundlesListState>(
                  builder: (context, state) {
                    if (state.status == BundlesListStatus.loading ||
                        state.status == BundlesListStatus.initial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.bundles.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_zip_rounded,
                                size: 36,
                                color: palette.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.bundleAddToEmpty,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: state.bundles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final bundle = state.bundles[index];
                        return Material(
                          color: palette.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: palette.stroke),
                          ),
                          child: InkWell(
                            onTap: () => _addTo(context, bundle),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: palette.primarySoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.folder_zip_rounded,
                                      color: palette.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bundle.title,
                                          style: TextStyle(
                                            color: palette.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.bundleItemCount(
                                            bundle.itemCount,
                                          ),
                                          style: TextStyle(
                                            color: palette.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: palette.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
