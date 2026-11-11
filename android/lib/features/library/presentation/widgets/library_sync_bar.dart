import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/library_controller.dart';

class LibrarySyncBar extends StatelessWidget {
  const LibrarySyncBar({
    super.key,
    required this.controller,
    required this.onAdd,
  });
  final LibraryController controller;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.backgroundOf(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  controller.saving
                      ? 'Guardando en tu biblioteca…'
                      : controller.loading
                      ? 'Cargando biblioteca…'
                      : controller.error != null
                      ? 'Biblioteca pendiente de sincronizar'
                      : 'Mi biblioteca sincronizada',
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Recargar biblioteca',
                onPressed: controller.busy ? null : controller.load,
                icon: const Icon(Icons.refresh),
              ),
              TextButton.icon(
                onPressed: controller.canWrite ? onAdd : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir libro'),
              ),
            ],
          ),
          if (controller.busy) const LinearProgressIndicator(),
          if (controller.error != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.error!,
                    key: const ValueKey('library-sync-error'),
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.busy ? null : controller.retry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
