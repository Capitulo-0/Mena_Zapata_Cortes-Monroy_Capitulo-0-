import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Presentation only: real explanation, announced accessibly and kept in the page flow.
class RecommendationExplanation extends StatelessWidget {
  const RecommendationExplanation({
    super.key,
    required this.message,
    required this.onClose,
  });
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: 'Explicación de recomendaciones',
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.deep.withValues(alpha: .65)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.deep,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar explicación',
            color: AppColors.deep,
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClose,
          ),
        ],
      ),
    ),
  );
}

/// A local tooltip style; global theme and card constraints stay unchanged.
class RecommendationInfoButton extends StatelessWidget {
  const RecommendationInfoButton({
    super.key,
    required this.message,
    required this.onPressed,
    this.color,
  });
  final String message;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => TooltipTheme(
    data: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.deep),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: AppColors.deep, fontSize: 12),
    ),
    child: IconButton(
      tooltip: message,
      icon: Icon(
        Icons.info_outline,
        size: 18,
        color: color ?? AppColors.textPrimaryOf(context),
      ),
      onPressed: onPressed,
    ),
  );
}
