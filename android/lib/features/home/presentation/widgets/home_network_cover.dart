import 'package:flutter/material.dart';

import '../../../../core/widgets/literary_cover.dart';

class HomeNetworkCover extends StatelessWidget {
  const HomeNetworkCover({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = 8,
    this.title = '',
    this.author = '',
  });
  final String url, title, author;
  final double width, height, radius;
  @override
  Widget build(BuildContext context) => LiteraryCover(
    reference: url,
    title: title,
    author: author,
    identity: 'book:$title:$author',
    width: width,
    height: height,
    radius: radius,
  );
}
