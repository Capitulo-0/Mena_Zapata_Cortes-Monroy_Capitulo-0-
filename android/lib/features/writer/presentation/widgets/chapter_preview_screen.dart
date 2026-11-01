import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class ChapterPreviewScreen extends StatelessWidget {
  const ChapterPreviewScreen({
    super.key,
    required this.storyTitle,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.content,
    required this.readingMinutes,
    required this.wordCount,
    required this.isDarkMode,
  });

  final String storyTitle;
  final int chapterNumber;
  final String chapterTitle;
  final String content;
  final int readingMinutes;
  final int wordCount;
  final bool isDarkMode;

  Color get _backgroundColor =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;

  Color get _surfaceColor =>
      isDarkMode ? AppColors.darkSurface : AppColors.surface;

  Color get _textPrimaryColor =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get _textSecondaryColor =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get _headingColor =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.deep;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(34, 34),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VISTA PREVIA',
                          style: GoogleFonts.cinzel(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: _headingColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Así verá este capítulo el lector.',
                          style: GoogleFonts.inter(
                            fontSize: 7.5,
                            color: _textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      'BORRADOR',
                      style: GoogleFonts.inter(
                        fontSize: 5.8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.20),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 48),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 620),
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDarkMode ? 0.12 : 0.04,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storyTitle.isEmpty
                              ? 'Historia sin título'
                              : storyTitle.toUpperCase(),
                          style: GoogleFonts.cinzel(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'CAPÍTULO ${chapterNumber.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: _textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          chapterTitle,
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: _textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$readingMinutes min de lectura',
                              style: GoogleFonts.inter(
                                fontSize: 7,
                                color: _textSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '·',
                              style: GoogleFonts.inter(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '$wordCount palabras',
                              style: GoogleFonts.inter(
                                fontSize: 7,
                                color: _textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          height: 1,
                          width: 54,
                          color: AppColors.gold.withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 20),
                        SelectableText(
                          content,
                          style: GoogleFonts.merriweather(
                            fontSize: 11,
                            height: 1.8,
                            color: _textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

