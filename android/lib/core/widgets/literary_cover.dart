import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'book_cover_reference.dart';
export 'book_cover_reference.dart';

class LiteraryCover extends StatefulWidget {
  const LiteraryCover({
    super.key,
    this.reference,
    required this.title,
    this.author = '',
    required this.identity,
    this.width = double.infinity,
    this.height = double.infinity,
    this.colors,
    this.radius = 8,
    this.fallbackKey,
  });
  final String? reference;
  final String title, author, identity;
  final double width, height, radius;
  final List<Color>? colors;
  final Key? fallbackKey;
  @visibleForTesting
  static void resetFailures() => _LiteraryCoverState._failedUntil.clear();
  @override
  State<LiteraryCover> createState() => _LiteraryCoverState();
}

class _LiteraryCoverState extends State<LiteraryCover> {
  static final Map<String, DateTime> _failedUntil = {};
  String get _url => BookCoverReference.resolve(widget.reference);
  String get _identity => '${widget.identity}:$_url';
  Widget _fallback() => LayoutBuilder(
    builder: (context, constraints) {
      final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 100.0;
      final font = (h * .085).clamp(6.0, 19.0);
      return Container(
        key: widget.fallbackKey,
        padding: EdgeInsets.all((h * .065).clamp(3.0, 16.0)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.colors ?? const [AppColors.deep, Color(0xFF362D27)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              color: AppColors.gold,
              size: (h * .16).clamp(12.0, 40.0),
            ),
            SizedBox(height: h * .05),
            Flexible(
              child: Text(
                widget.title.trim().isEmpty
                    ? 'SIN TÍTULO'
                    : widget.title.toUpperCase(),
                maxLines: h > 100 ? 4 : 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  color: Colors.white,
                  fontSize: font,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.author.trim().isNotEmpty) ...[
              SizedBox(height: h * .04),
              Flexible(
                child: Text(
                  widget.author,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: (font * .75).clamp(5.0, 13.0),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    _failedUntil.removeWhere((_, until) => until.isBefore(DateTime.now()));
    final identity = _identity;
    final unavailable = _url.isEmpty || _failedUntil.containsKey(identity);
    final image = unavailable
        ? _fallback()
        : _url.startsWith('assets/')
        ? Image.asset(
            _url,
            key: ValueKey(_identity),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : Image.network(
            _url,
            key: ValueKey(_identity),
            fit: BoxFit.cover,
            gaplessPlayback: false,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (_, _, _) {
              if (_failedUntil.length >= 128) { _failedUntil.remove(_failedUntil.keys.first); }
              _failedUntil[identity] = DateTime.now().add(
                const Duration(minutes: 2),
              );
              return _fallback();
            },
          );
    return Semantics(
      image: true,
      label:
          'Portada: ${widget.title}${widget.author.isEmpty ? "" : ", ${widget.author}"}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: image,
        ),
      ),
    );
  }
}
