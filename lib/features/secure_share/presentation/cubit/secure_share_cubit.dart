import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/domain/secure_share/entities/share_payload_entity.dart';
import 'package:pass_doc_manager/domain/secure_share/usecases/create_share_link.dart';
import 'package:pass_doc_manager/features/secure_share/presentation/cubit/secure_share_state.dart';

class SecureShareCubit extends Cubit<SecureShareState> {
  SecureShareCubit(this._createShareLink) : super(const SecureShareState());

  final CreateShareLink _createShareLink;

  void toggleFieldSelection(String fieldName) {
    final updated = Set<String>.from(state.selectedFields);
    if (updated.contains(fieldName)) {
      updated.remove(fieldName);
    } else {
      updated.add(fieldName);
    }
    emit(state.copyWith(selectedFields: updated));
  }

  void updatePassphrase(String passphrase) {
    emit(state.copyWith(passphrase: passphrase));
  }

  void generateRandomPassphrase() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random();
    final passphrase = List.generate(
      16,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    emit(state.copyWith(
      generatedPassphrase: passphrase,
      passphrase: passphrase,
    ));
  }

  Future<void> createShareLink({
    required String itemName,
    required ShareItemType itemType,
    required Map<String, String> availableFields,
    required ShareTtl ttl,
  }) async {
    if (state.passphrase.isEmpty) {
      emit(state.copyWith(
        status: SecureShareStatus.error,
        errorMessage: 'Passphrase is required',
      ));
      return;
    }

    if (state.selectedFields.isEmpty) {
      emit(state.copyWith(
        status: SecureShareStatus.error,
        errorMessage: 'Please select at least one field to share',
      ));
      return;
    }

    emit(state.copyWith(status: SecureShareStatus.loading));

    try {
      // Filter fields to only include selected ones
      final fieldsToShare = <String, String>{};
      for (final fieldName in state.selectedFields) {
        if (availableFields.containsKey(fieldName)) {
          fieldsToShare[fieldName] = availableFields[fieldName]!;
        }
      }

      final params = CreateShareLinkParams(
        itemType: itemType,
        itemName: itemName,
        fields: fieldsToShare,
        passphrase: state.passphrase,
        ttl: ttl,
      );

      final result = await _createShareLink(params);

      emit(state.copyWith(
        status: SecureShareStatus.success,
        shareLink: result.link,
        expiresAt: result.expiresAt,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SecureShareStatus.error,
        errorMessage: 'Failed to create share link: $e',
      ));
    }
  }

  void resetState() {
    emit(const SecureShareState());
  }
}
