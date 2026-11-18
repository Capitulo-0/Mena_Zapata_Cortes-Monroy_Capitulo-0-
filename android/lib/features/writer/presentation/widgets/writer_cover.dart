import 'package:flutter/material.dart';

import '../../../../core/widgets/literary_cover.dart';

class WriterCover extends StatelessWidget {
  const WriterCover({
    super.key,
    required this.coverPath,
    required this.title,
    required this.storyId,
    this.author = '',
    this.width = double.infinity,
    this.height = double.infinity,
    this.radius = 8,
  });
  final String? coverPath;
  final String title, storyId, author;
  final double width, height, radius;

  /// Canonical IDs are preserved in storage; aliases are resolved only for display.
  static String? canonical(String? reference) {
    final value = reference?.trim();
    return switch (value?.toLowerCase()) {
      'preset:blue' || 'preset:azul' => 'preset:night',
      'preset:night' => 'preset:night',
      'preset:classic' => 'preset:classic',
      'preset:gold' => 'preset:gold',
      'preset:forest' => 'preset:forest',
      _ => value,
    };
  }

  static bool isPreset(String? reference) => const {
    'preset:classic',
    'preset:gold',
    'preset:forest',
    'preset:night',
  }.contains(canonical(reference));
  static List<Color> colors(String? reference) =>
      switch (canonical(reference)) {
        'preset:gold' => const [Color(0xFF9A6D2F), Color(0xFF3B2414)],
        'preset:forest' => const [Color(0xFF405A49), Color(0xFF18241E)],
        'preset:night' => const [Color(0xFF34354A), Color(0xFF171821)],
        'preset:classic' => const [Color(0xFF7D2430), Color(0xFF35130F)],
        _ => const [Color(0xFF3D3129), Color(0xFF211C19)],
      };
  @override
  Widget build(BuildContext context) => LiteraryCover(
    reference: isPreset(coverPath) ? null : canonical(coverPath),
    title: title,
    author: author,
    identity: 'writer:$storyId:${canonical(coverPath)}',
    fallbackKey: ValueKey(
      isPreset(coverPath)
          ? 'writer-preset-${canonical(coverPath)}'
          : 'writer-cover-unavailable',
    ),
    colors: colors(coverPath),
    width: width,
    height: height,
    radius: radius,
  );
}
