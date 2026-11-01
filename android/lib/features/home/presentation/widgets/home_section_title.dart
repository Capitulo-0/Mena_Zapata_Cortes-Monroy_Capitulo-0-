import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final dividerColor =
        AppColors.textSecondaryOf(context).withValues(alpha: 0.34);

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: GoogleFonts.cinzel(
              color: textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: dividerColor,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 8,
                  color: dividerColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
