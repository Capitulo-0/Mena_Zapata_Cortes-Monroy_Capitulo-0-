import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/free_work.dart';

/// Original vector compositions. No network, commercial covers or new raster assets.
class FreeWorkCover extends StatelessWidget {
  const FreeWorkCover({super.key, required this.work});
  final FreeWork work;
  static int hash(String value) {
    var result = 17;
    for (final unit in value.codeUnits) {
      result = (result * 31 + unit) & 0x7fffffff;
    }
    return result;
  }

  static FreeWork? fromBook(Map<String, dynamic> book) {
    final id = book['freeWorkId'];
    for (final work in freeWorks) {
      if (work.id == id &&
          work.title == book['title'] &&
          work.author == book['author']) {
        return work;
      }
    }
    return null;
  }

  static const palettes = [
    Color(0xFF512731),
    Color(0xFF233D3D),
    Color(0xFF30344F),
    Color(0xFF5B4030),
    Color(0xFF3C3544),
    Color(0xFF2E4334),
  ];
  static String signature(FreeWork work) =>
      '${work.id}:${hash(work.author) % palettes.length}:${hash(work.id) % 4}:${hash(work.id)}';
  @override
  Widget build(BuildContext context) {
    final seed = hash(work.id), family = hash(work.author) % palettes.length;
    final ordinal = freeWorks.indexWhere((w) => w.id == work.id) + 1;
    return Semantics(
      image: true,
      label:
          'Portada original de Capítulo 0: ${work.title}, ${work.author}. ID ${work.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 160.0;
            final inset = (h * .07).clamp(5.0, 20.0);
            return CustomPaint(
              key: ValueKey('free-cover-${work.id}'),
              painter: _LiteraryComposition(seed, palettes[family], ordinal),
              child: Padding(
                padding: EdgeInsets.fromLTRB(inset + 3, inset, inset, inset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'CAPÍTULO 0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFE5CB91),
                        fontSize: (h * .04).clamp(5.0, 10.0),
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: h * .12),
                    Expanded(
                      child: Center(
                        child: Text(
                          work.title.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'serif',
                            color: const Color(0xFFFFF6E7),
                            fontSize: (h * .082).clamp(7.5, 20.0),
                            height: 1.16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: h * .04),
                    Text(
                      work.author.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFE5CB91),
                        fontSize: (h * .047).clamp(5.5, 12.0),
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: h * .045),
                    Text(
                      ordinal > 0
                          ? 'COLECCIÓN · ${ordinal.toString().padLeft(2, '0')}'
                          : 'COLECCIÓN LITERARIA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFE5CB91),
                        fontSize: (h * .033).clamp(4.5, 8.0),
                        letterSpacing: .7,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LiteraryComposition extends CustomPainter {
  _LiteraryComposition(this.seed, this.base, this.ordinal);
  final int seed;
  final int ordinal;
  final Color base;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, .04 * (seed % 3))!,
            Color.lerp(base, Colors.black, .48)!,
          ],
        ).createShader(rect),
    );
    final gold = Paint()
      ..color = const Color(0xFFC6A567).withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65;
    canvas.drawLine(Offset(5, 0), Offset(5, size.height), gold);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          9,
          5,
          math.max(0, size.width - 14),
          math.max(0, size.height - 10),
        ),
        const Radius.circular(3),
      ),
      gold,
    );
    for (var bit = 0; bit < 6; bit++) {
      final mark = Rect.fromLTWH(
        1.5,
        size.height * (.32 + bit * .065),
        2,
        size.height * .018,
      );
      final ink = Paint()
        ..color = const Color(0xFFE5CB91)
        ..strokeWidth = .4
        ..style = ((ordinal >> bit) & 1) == 1
            ? PaintingStyle.fill
            : PaintingStyle.stroke;
      canvas.drawRect(mark, ink);
    }
    final center = Offset(size.width * .52, size.height * .22),
        r = math.min(size.width * .22, size.height * .075);
    switch (ordinal > 0 ? (ordinal - 1) % 4 : seed % 4) {
      case 0:
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(center, r * (i + 1) / 3, gold);
        }
        canvas.drawLine(
          center - Offset(r * 1.4, 0),
          center + Offset(r * 1.4, 0),
          gold,
        );
      case 1:
        for (var i = 0; i < 5; i++) {
          final x = (i - 2) * r * .48;
          canvas.drawArc(
            Rect.fromCenter(
              center: center + Offset(x, 0),
              width: r,
              height: r * 2,
            ),
            math.pi,
            math.pi,
            false,
            gold,
          );
        }
      case 2:
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r * 1.5, center.dy)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r * 1.5, center.dy)
          ..close();
        canvas.drawPath(path, gold);
        canvas.drawCircle(center, r * .4, gold);
      case 3:
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final direction = Offset(math.cos(angle), math.sin(angle));
          canvas.drawLine(
            center + direction * r * .4,
            center + direction * r,
            gold,
          );
        }
        canvas.drawCircle(center, r * .25, gold);
    }
    // Original imprint derived from all ID bits: poems in one family remain distinguishable.
    for (var i = 0; i < 16; i++) {
      final height = size.height * (.005 + .004 * ((seed >> (i * 2)) & 3));
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * (.24 + i * .56 / 15),
          size.height * .77 - height / 2,
          .8,
          height,
        ),
        gold..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_LiteraryComposition old) =>
      old.seed != seed || old.base != base;
}
