import 'package:flutter/material.dart';

/// Avoids requesting expired S3 URLs that may have been saved in offline data.
Widget safeNetworkImage(
  String url, {
  BoxFit? fit,
  double? width,
  double? height,
  ImageLoadingBuilder? loadingBuilder,
  ImageFrameBuilder? frameBuilder,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  final uri = Uri.tryParse(url);
  final parameters = uri?.queryParameters;
  final date = parameters?['X-Amz-Date'];
  final seconds = int.tryParse(parameters?['X-Amz-Expires'] ?? '');
  final match = date == null ? null : RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$').firstMatch(date);
  if (match != null && seconds != null && seconds >= 0) {
    final parts = List.generate(6, (i) => int.parse(match.group(i + 1)!));
    final signedAt = DateTime.utc(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
    if (!DateTime.now().toUtc().isBefore(signedAt.add(Duration(seconds: seconds)))) {
      return SizedBox(
        width: width,
        height: height,
        child: Builder(builder: (context) => errorBuilder?.call(context, StateError('La imagen ha vencido'), null) ?? const Icon(Icons.broken_image_outlined)),
      );
    }
  }
  return Image.network(url, fit: fit, width: width, height: height,
      loadingBuilder: loadingBuilder, frameBuilder: frameBuilder, errorBuilder: errorBuilder);
}
