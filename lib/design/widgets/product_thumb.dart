import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../tokens.dart';
import 'bits.dart';

/// A product's catalog photo, or its woven dye swatch until a photo is added.
class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.palette, this.imageUrl, this.size = 52, this.radius = SutraRadius.sm});

  final String palette;
  final String? imageUrl;
  final double size;
  final Radius radius;

  /// Server paths ("/media/catalog/…") are made absolute against the API host.
  static String absolute(String url) => url.startsWith('http') ? url : '${AppConfig.apiBaseUrl}$url';

  @override
  Widget build(BuildContext context) {
    final swatch = WovenSwatch(palette: palette, size: size);
    if (imageUrl == null) return swatch;
    return ClipRRect(
      borderRadius: BorderRadius.all(radius),
      child: Image.network(
        absolute(imageUrl!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => swatch,
        frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : swatch,
      ),
    );
  }
}
