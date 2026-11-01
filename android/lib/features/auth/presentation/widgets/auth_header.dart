import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class AuthHeaderDelegate extends SliverPersistentHeaderDelegate {
  AuthHeaderDelegate({required this.topPadding});

  final double topPadding;

  @override
  double get minExtent => topPadding + 118;

  @override
  double get maxExtent => topPadding + 218;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final available = maxExtent - minExtent;
    final progress = available <= 0
        ? 1.0
        : (shrinkOffset / available).clamp(0.0, 1.0);

    return AuthHeaderVisual(
      compact: progress >= 0.70,
      progress: progress,
      topPadding: 0,
      showShadow: overlapsContent || progress > 0.05,
    );
  }

  @override
  bool shouldRebuild(covariant AuthHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding;
  }
}

class AuthHeaderVisual extends StatelessWidget {
  const AuthHeaderVisual({
    super.key,
    required this.compact,
    required this.topPadding,
    this.progress,
    this.showShadow = false,
  });

  final bool compact;
  final double topPadding;
  final double? progress;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final t = progress ?? (compact ? 1.0 : 0.0);

    final logoSize = 92 - (34 * t);
    final titleSize = 22 - (6 * t);
    final headerTop = 22 - (13 * t);
    final headerBottom = 20 - (10 * t);
    final logoRadius = 22 - (5 * t);
    final logoMargin = 12 - (5 * t);
    final lineWidth = 50 - (16 * t);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        topPadding + headerTop,
        24,
        headerBottom,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deep,
            AppColors.deepAlt,
            Color(0xFF2E1510),
          ],
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 4,
            child: Opacity(
              opacity: 0.50,
              child: Text(
                '✦',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12 - (3 * t),
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 34 - (9 * t),
            child: Opacity(
              opacity: 0.30,
              child: Text(
                '✦',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 8 - (1 * t),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(logoRadius),
                    color: Colors.white.withValues(alpha: 0.025),
                    border: Border.all(
                      color: AppColors.gold.withValues(
                        alpha: 0.36 + (0.04 * (1 - t)),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.28 + (0.10 * (1 - t)),
                        ),
                        blurRadius: 14 + (8 * (1 - t)),
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(logoRadius - 1),
                    child: Image.asset(
                      'assets/images/logo_capitulo0.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: logoMargin),
                Text(
                  'CAPÍTULO 0',
                  style: GoogleFonts.cinzel(
                    color: AppColors.gold,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.1 + (0.9 * (1 - t)),
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 4 + (2 * (1 - t))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: lineWidth,
                      height: 1,
                      color: AppColors.gold.withValues(
                        alpha: compact ? 0.50 : 0.72,
                      ),
                    ),
                    SizedBox(width: compact ? 5 : 8),
                    Text(
                      '✦',
                      style: TextStyle(
                        color: AppColors.gold.withValues(
                          alpha: compact ? 0.50 : 0.82,
                        ),
                        fontSize: 7,
                      ),
                    ),
                    SizedBox(width: compact ? 5 : 8),
                    Container(
                      width: lineWidth,
                      height: 1,
                      color: AppColors.gold.withValues(
                        alpha: compact ? 0.50 : 0.72,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
