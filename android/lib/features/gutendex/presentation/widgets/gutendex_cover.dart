import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class GutendexCover extends StatefulWidget {
  const GutendexCover({
    super.key,
    required this.url,
    this.title,
    this.width = 64,
    this.height = 92,
  });
  final Uri? url;
  final String? title;
  final double width;
  final double height;
  @override
  State<GutendexCover> createState() => _GutendexCoverState();
}

class _GutendexCoverState extends State<GutendexCover> {
  bool _failed = false;
  @override
  void didUpdateWidget(covariant GutendexCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _failed = false;
  }

  Widget _placeholder(BuildContext context) => Semantics(
    label:
        'Portada no disponible${widget.title == null ? "" : ": ${widget.title}"}',
    image: true,
    child: Container(
      key: const ValueKey('gutendex-cover-placeholder'),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftOf(context),
        border: Border.all(
          color: AppColors.goldOf(context).withValues(alpha: .4),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: AppColors.goldOf(context),
            size: 24,
          ),
          if (widget.width >= 100 && widget.title != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.title!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: widget.width,
      height: widget.height,
      child: widget.url == null || _failed
          ? _placeholder(context)
          : Image.network(
              widget.url.toString(),
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, synchronous) =>
                  synchronous || frame != null ? child : _placeholder(context),
              errorBuilder: (context, error, stack) {
                _failed = true;
                return _placeholder(context);
              },
            ),
    ),
  );
}
