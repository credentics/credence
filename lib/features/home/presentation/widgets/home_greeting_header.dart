import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/credence_ui.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({
    super.key,
    required this.firstName,
    this.photoPath,
    this.onSearchTap,
    this.onSettingsTap,
  });

  final String firstName;
  final String? photoPath;
  final VoidCallback? onSearchTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final name = firstName.trim();

    return CredenceHeader(
      title: name.isEmpty
          ? context.l10n.homeGreetingFallback
          : context.l10n.homeGreetingNamed(name),
      eyebrow: _dateLabel(context),
      padding: EdgeInsets.zero,
      actions: [
        if (onSearchTap != null) ...[
          CredenceIconButton(
            icon: Icons.search_rounded,
            onTap: onSearchTap,
            backgroundColor: palette.surface,
          ),
          const SizedBox(width: 8),
        ],
        if (onSettingsTap != null) ...[
          CredenceIconButton(
            icon: Icons.tune_rounded,
            onTap: onSettingsTap,
            backgroundColor: palette.surface,
          ),
          const SizedBox(width: 8),
        ],
        _avatar(palette, size: 38),
      ],
    );
  }

  Widget _avatar(AppPalette palette, {double size = 52}) {
    final path = photoPath;
    final resolvedPath = path == null
        ? null
        : LocalAssetPathResolver.resolveRuntimePathSync(path);
    if (resolvedPath != null &&
        resolvedPath.isNotEmpty &&
        File(resolvedPath).existsSync()) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.stroke, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Image.file(
            File(resolvedPath),
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: (size * 3).round(),
            cacheHeight: (size * 3).round(),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFDEC7), Color(0xFFF8C9A0)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE8D5C4), width: 1.5),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFFD4956B),
        size: 22,
      ),
    );
  }

  String _dateLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat(
      'EEEE · d MMM',
      locale,
    ).format(DateTime.now()).toUpperCase();
  }
}
