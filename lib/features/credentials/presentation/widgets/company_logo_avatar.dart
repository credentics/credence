import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/core/utils/local_svg_picture.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CompanyLogoAvatar extends StatelessWidget {
  const CompanyLogoAvatar({
    super.key,
    required this.serviceName,
    this.serviceUrl,
    this.imageUrl,
    this.localImagePath,
    required this.size,
    required this.borderRadius,
    this.backgroundColor,
    this.fallbackTextColor = Colors.white,
    this.fallbackColor,
  });

  final String serviceName;
  final String? serviceUrl;
  final String? imageUrl;
  final String? localImagePath;
  final double size;
  final BorderRadiusGeometry borderRadius;
  final Color? backgroundColor;
  final Color fallbackTextColor;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final resolvedBackground = backgroundColor ?? palette.surfaceSoft;
    final resolvedFallback = fallbackColor ?? palette.primary;
    final localSvg = resolveLocalSvgPicture(
      localImagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
    final localProvider = resolveLocalFileImageProvider(localImagePath);
    final resolvedImageUrl = imageUrl?.trim();
    final logoUrl = resolvedImageUrl != null && resolvedImageUrl.isNotEmpty
        ? resolvedImageUrl
        : null;
    final isNetworkSvg = _looksLikeSvgUrl(logoUrl);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size,
        height: size,
        color: resolvedBackground,
        alignment: Alignment.center,
        child: localSvg != null
            ? SizedBox(width: size, height: size, child: localSvg)
            : localProvider != null
            ? Image(
                image: localProvider,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _fallbackMonogram(resolvedFallback),
              )
            : logoUrl == null
            ? _fallbackMonogram(resolvedFallback)
            : isNetworkSvg
            ? SvgPicture.network(
                logoUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholderBuilder: (_) => _fallbackMonogram(resolvedFallback),
              )
            : Image.network(
                logoUrl,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _fallbackMonogram(resolvedFallback),
              ),
      ),
    );
  }

  bool _looksLikeSvgUrl(String? url) {
    final value = url?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return false;
    }
    return value.contains('.svg') ||
        value.contains('image/svg') ||
        value.contains('format=svg');
  }

  Widget _fallbackMonogram(Color resolvedFallback) {
    final first = serviceName.trim().isEmpty
        ? '?'
        : serviceName.trim().substring(0, 1).toUpperCase();

    return Container(
      width: size,
      height: size,
      color: resolvedFallback,
      alignment: Alignment.center,
      child: Text(
        first,
        style: TextStyle(
          color: fallbackTextColor,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.46,
        ),
      ),
    );
  }
}
