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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.goldOf(context).withValues(alpha: .35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final status = Row(
                  children: [
                    Icon(
                      controller.busy
                          ? Icons.sync_rounded
                          : controller.error != null
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                      size: 15,
                      color: AppColors.textSecondaryOf(context),
                    ),
                    const SizedBox(width: 7),
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
                          color: AppColors.textSecondaryOf(context),
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                );
                final shape = RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                );
                final actions = IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: 'Recargar biblioteca',
                          child: OutlinedButton.icon(
                            key: const ValueKey('library-refresh'),
                            onPressed: controller.busy ? null : controller.load,
                            icon: const Icon(Icons.refresh_rounded, size: 17),
                            label: const Text(
                              'Actualizar',
                              textAlign: TextAlign.center,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimaryOf(context),
                              side: BorderSide(
                                color: AppColors.goldOf(context)
                                    .withValues(alpha: .7),
                              ),
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: shape,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey('library-add'),
                          onPressed: controller.canWrite ? onAdd : null,
                          icon: const Icon(Icons.add_rounded, size: 17),
                          label: const Text(
                            'Añadir libro',
                            textAlign: TextAlign.center,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.deep,
                            foregroundColor: AppColors.background,
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: shape,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (constraints.maxWidth < 600) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [status, const SizedBox(height: 10), actions],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: status),
                    const SizedBox(width: 16),
                    SizedBox(width: 320, child: actions),
                  ],
                );
              },
            ),
            if (controller.busy) const LinearProgressIndicator(),
            if (controller.error != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  final error = Text(
                    controller.error!,
                    key: const ValueKey('library-sync-error'),
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 12,
                    ),
                  );
                  final retry = TextButton(
                    onPressed: controller.busy ? null : controller.retry,
                    child: const Text('Reintentar'),
                  );
                  if (constraints.maxWidth < 480) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 96),
                          child: SingleChildScrollView(child: error),
                        ),
                        Align(alignment: Alignment.centerRight, child: retry),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: error),
                      retry,
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    ),
  );
}
