import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/map_point.dart';
import 'map_point_presentation.dart';

class MapPointCard extends StatelessWidget {
  const MapPointCard({
    super.key,
    required this.point,
    required this.onClose,
    required this.onFocus,
  });

  final MapPoint point;
  final VoidCallback onClose;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.goldOf(context).withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.goldOf(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    MapPointPresentation.iconForType(point.type),
                    color: AppColors.goldOf(context),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.name,
                        style: GoogleFonts.merriweather(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        MapPointPresentation.labelForType(point.type),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: point.address,
            ),
            if (point.date != null)
              _InfoRow(
                icon: Icons.calendar_month_outlined,
                text: point.date!,
              ),
            if (point.schedule != null)
              _InfoRow(
                icon: Icons.schedule_outlined,
                text: point.schedule!,
              ),
            _InfoRow(
              icon: point.isFree
                  ? Icons.confirmation_number_outlined
                  : Icons.payments_outlined,
              text: point.isFree
                  ? 'Entrada gratuita'
                  : 'Puede requerir consumo o entrada',
            ),
            const SizedBox(height: 7),
            Text(
              point.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.45,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onFocus,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepOf(context),
                  foregroundColor: AppColors.goldOf(context),
                ),
                icon: const Icon(Icons.near_me_outlined, size: 18),
                label: Text(
                  'Ver en el mapa',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.goldOf(context),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
