import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A lightweight static map preview using OSM tiles.
/// Renders a grid of tiles centered on the given coordinates.
class StaticMapPreview extends StatelessWidget {
  const StaticMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 15,
    this.height = 200,
  });

  final double latitude;
  final double longitude;
  final int zoom;
  final double height;

  @override
  Widget build(BuildContext context) {
    final n = 1 << zoom;
    final centerX = (longitude + 180.0) / 360.0 * n;
    final latRad = latitude * math.pi / 180.0;
    final centerY =
        (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            n;

    final tileX = centerX.floor();
    final tileY = centerY.floor();

    // Build a 3x3 grid of tiles centered on the target
    final tiles = <Widget>[];
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final tx = tileX + dx;
        final ty = tileY + dy;
        tiles.add(
          Image.network(
            'https://tile.openstreetmap.org/$zoom/$tx/$ty.png',
            fit: BoxFit.cover,
            headers: const {
              'User-Agent': 'Credence/1.0 (flutter-app; map-preview)',
            },
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE5EDF9),
            ),
          ),
        );
      }
    }

    // Offset to center the pin
    final offsetX = (centerX - tileX) * 256;
    final offsetY = (centerY - tileY) * 256;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: 256 * 3,
          maxHeight: 256 * 3,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(
              -(offsetX - 128),
              -(offsetY - 128),
            ),
            child: SizedBox(
              width: 256 * 3,
              height: 256 * 3,
              child: GridView.count(
                crossAxisCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: tiles,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
