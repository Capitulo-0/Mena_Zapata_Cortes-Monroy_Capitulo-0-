import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class LibrarySearchField extends StatelessWidget {
  const LibrarySearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.60),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          color: AppColors.textPrimaryOf(context),
          fontSize: 9.5,
        ),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 7,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.gold.withValues(alpha: 0.88),
            size: 16,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 34,
          ),
          hintText: 'Buscar en mi biblioteca...',
          hintStyle: GoogleFonts.inter(
            color: AppColors.textSecondaryOf(context)
                .withValues(alpha: 0.82),
            fontSize: 9,
          ),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  splashRadius: 15,
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondaryOf(context)
                        .withValues(alpha: 0.72),
                    size: 15,
                  ),
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 34,
          ),
        ),
      ),
    );
  }
}
