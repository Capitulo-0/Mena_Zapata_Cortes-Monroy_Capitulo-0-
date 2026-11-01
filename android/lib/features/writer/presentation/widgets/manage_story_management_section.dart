part of '../screens/manage_story_screen.dart';

extension _ManageStoryManagementSection on _ManageStoryScreenState {
  Widget _buildStoryManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('OPCIONES DE LA OBRA'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            children: [
              if (_story.isPublished) ...[
                _managementAction(
                  icon: Icons.unpublished_outlined,
                  label: 'Volver a borrador',
                  description:
                      'La obra dejará de mostrarse como publicación activa.',
                  onTap: _isLoading ? null : _toggleStoryPublication,
                ),
                Divider(
                  height: 17,
                  color: AppColors.gold.withValues(alpha: 0.14),
                ),
              ],
              _managementAction(
                icon: Icons.delete_outline_rounded,
                label: _isDeletingStory ? 'Eliminando...' : 'Eliminar historia',
                description: _isDeletingStory
                    ? 'Eliminando la obra y sus capítulos...'
                    : 'Elimina la obra y sus capítulos guardados.',
                destructive: true,
                onTap: _isLoading ? null : _deleteStory,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _managementAction({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback? onTap,
    bool destructive = false,
  }) {
    final actionColor = destructive ? AppColors.accent : _headingColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 7,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: destructive
                    ? AppColors.accent.withValues(alpha: 0.08)
                    : AppColors.gold.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 16,
                color: destructive ? AppColors.accent : AppColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 8.2,
                      fontWeight: FontWeight.w700,
                      color: actionColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 6.6,
                      height: 1.35,
                      color: _textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: _textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
