import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/profile_gender_preference.dart';

class HomeWelcomeSection extends StatelessWidget {
  const HomeWelcomeSection({
    super.key,
    required this.isGuest,
    required this.currentName,
  });

  final bool isGuest;
  final String currentName;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<ProfileGender>(
            valueListenable: ProfileGenderStore.notifier,
            builder: (context, gender, _) {
              final name = currentName.trim().isEmpty
                  ? 'lector/a'
                  : currentName.trim();

              final greeting = isGuest
                  ? '¡Qué gusto verte en Capítulo 0! ✦'
                  : switch (gender) {
                      ProfileGender.woman => 'Bienvenida, $name ✦',
                      ProfileGender.man => 'Bienvenido, $name ✦',
                      ProfileGender.preferNotToSay ||
                      ProfileGender.selfDescribe =>
                        '¡Qué gusto verte, $name! ✦',
                    };

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  greeting,
                  key: ValueKey(greeting),
                  style: GoogleFonts.cinzel(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué historia quieres descubrir hoy?',
            style: GoogleFonts.merriweather(
              color: textSecondary,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
