import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class MainHeader extends StatelessWidget {
  const MainHeader({
    super.key,
    required this.compact,
    required this.isGuest,
    required this.onScannerTap,
    required this.onGeminiTap,
  });

  final bool compact;
  final bool isGuest;
  final VoidCallback onScannerTap;
  final VoidCallback onGeminiTap;

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.goldOf(context);
    final deep = AppColors.deepOf(context);
    final deepAlt = AppColors.deepAltOf(context);

    return Material(
      color: deep,
      elevation: compact ? 5 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: SafeArea(
        bottom: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(
            15,
            compact ? 6 : 10,
            13,
            compact ? 6 : 10,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: compact ? 30 : 38,
                height: compact ? 30 : 38,
                child: Image.asset(
                  'assets/images/logo_capitulo0.png',
                  fit: BoxFit.contain,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: compact ? 5 : 7,
              ),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  style: GoogleFonts.cinzel(
                    color: gold,
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: compact ? 1.35 : 1.7,
                  ),
                  child: const Text('CAPÍTULO 0'),
                ),
              ),
              if (isGuest)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    'Invitado',
                    style: GoogleFonts.inter(
                      color: gold,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              _HeaderButton(
                compact: compact,
                icon: Icons.qr_code_scanner_rounded,
                tooltip: 'Escanear ISBN',
                gold: gold,
                background: deepAlt,
                onTap: onScannerTap,
              ),
              const SizedBox(width: 6),
              _HeaderButton(
                compact: compact,
                icon: Icons.auto_awesome_rounded,
                tooltip: 'Asistente Gemini',
                gold: gold,
                background: deepAlt,
                onTap: onGeminiTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.compact,
    required this.icon,
    required this.tooltip,
    required this.gold,
    required this.background,
    required this.onTap,
  });

  final bool compact;
  final IconData icon;
  final String tooltip;
  final Color gold;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 36.0;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 9 : 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 9 : 10),
            border: Border.all(
              color: gold.withValues(alpha: 0.28),
            ),
            color: background,
          ),
          child: Icon(
            icon,
            size: compact ? 16 : 18,
            color: gold,
          ),
        ),
      ),
    );
  }
}
