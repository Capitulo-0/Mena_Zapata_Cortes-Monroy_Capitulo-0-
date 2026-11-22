import 'package:flutter/material.dart';

import '../../../../core/widgets/literary_cover.dart';

class GutendexCover extends StatelessWidget {
  const GutendexCover({
    super.key,
    required this.url,
    this.title,
    this.author = '',
    this.width = 64,
    this.height = 92,
  });
  final Uri? url;
  final String? title;
  final String author;
  final double width, height;
  @override
  Widget build(BuildContext context) => LiteraryCover(
    reference: url?.toString(),
    identity: 'gutenberg:$url:$title:$author',
    title: title ?? 'Título no disponible',
    author: author.toUpperCase(),
    width: width,
    height: height,
    fallbackKey: const ValueKey('gutendex-cover-placeholder'),
  );
}
