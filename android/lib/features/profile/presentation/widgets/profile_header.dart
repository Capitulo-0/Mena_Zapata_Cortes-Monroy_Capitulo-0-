import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import 'profile_privacy_store.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.surface;
    final headingColor =
        isDark ? AppColors.darkTextPrimary : AppColors.deep;

    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: ProfilePrivacyStore.isPrivate,
            builder: (context, isPrivate, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'MI PERFIL LITERARIO',
                      style: GoogleFonts.cinzel(
                        color: headingColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.86,
                            end: 1,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      isPrivate
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      key: ValueKey<bool>(isPrivate),
                      size: 16,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        InkWell(
          onTap: onOpenSettings,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 38,
            height: 36,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold),
            ),
            child: Icon(
              Icons.settings_outlined,
              color: headingColor,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
