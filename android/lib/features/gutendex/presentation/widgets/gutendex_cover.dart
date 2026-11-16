import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class GutendexCover extends StatelessWidget {
  const GutendexCover({super.key, required this.url, this.width = 64, this.height = 92});
  final Uri? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => ColoredBox(
      key: const ValueKey('gutendex-cover-placeholder'),
      color: AppColors.surfaceSoftOf(context),
      child: Center(child: Icon(Icons.menu_book_outlined,
        color: AppColors.goldOf(context), semanticLabel: 'Portada no disponible')),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: width, height: height,
        child: url == null ? placeholder() : Image.network(
          url.toString(), fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (_, _, _) => placeholder(),
        ),
      ),
    );
  }
}
