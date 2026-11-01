import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HomeNetworkCover extends StatelessWidget {
  const HomeNetworkCover({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final String url;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final deep = AppColors.deepOf(context);
    final gold = AppColors.goldOf(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: deep,
              alignment: Alignment.center,
              child: Icon(Icons.menu_book_rounded, color: gold),
            );
          },
        ),
      ),
    );
  }
}
