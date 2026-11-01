import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    const corner = 26.0;
    final rect = Rect.fromLTWH(22, 22, size.width - 44, size.height - 44);

    final path = Path()
      ..moveTo(rect.left, rect.top + corner)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + corner, rect.top)
      ..moveTo(rect.right - corner, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + corner)
      ..moveTo(rect.left, rect.bottom - corner)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left + corner, rect.bottom)
      ..moveTo(rect.right - corner, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.bottom - corner);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
