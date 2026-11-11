import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/library_controller.dart';

Future<void> showAddLibraryBookDialog(
  BuildContext context,
  LibraryController controller,
) => showDialog<void>(
  context: context,
  builder: (_) => _AddLibraryBookDialog(controller: controller),
);

class _AddLibraryBookDialog extends StatefulWidget {
  const _AddLibraryBookDialog({required this.controller});
  final LibraryController controller;
  @override
  State<_AddLibraryBookDialog> createState() => _AddLibraryBookDialogState();
}

class _AddLibraryBookDialogState extends State<_AddLibraryBookDialog> {
  final title = TextEditingController();
  final author = TextEditingController();
  final pages = TextEditingController();
  final publisher = TextEditingController();
  final isbn = TextEditingController();
  final form = GlobalKey<FormState>();
  bool manual = false;
  bool busy = false;
  @override
  void dispose() {
    for (final field in [title, author, pages, publisher, isbn]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save(Future<bool> Function() operation) async {
    if (busy) return;
    setState(() => busy = true);
    final success = await operation();
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      return;
    }
    setState(() => busy = false);
    // Keep catalog retry separate from catalog creation to avoid a duplicate POST.
    if (manual) setState(() => manual = false);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => AlertDialog(
      backgroundColor: AppColors.surfaceOf(context),
      title: Text(manual ? 'Registrar libro' : 'Añadir a Mi Biblioteca'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.controller.error != null)
                Text(
                  widget.controller.error!,
                  key: const ValueKey('add-library-error'),
                ),
              if (widget.controller.error != null)
                TextButton(
                  onPressed: busy ? null : widget.controller.load,
                  child: const Text('Recargar catálogo'),
                ),
              if (!manual) ...[
                if (widget.controller.catalog.isEmpty)
                  const Text(
                    'El catálogo está vacío. Puedes registrar los datos de un libro.',
                  ),
                ...widget.controller.catalog.map(
                  (book) => ListTile(
                    title: Text(book.title),
                    subtitle: Text(book.author),
                    trailing: widget.controller.entries.containsKey(book.id)
                        ? const Icon(Icons.check)
                        : const Icon(Icons.add),
                    onTap: busy
                        ? null
                        : () => _save(() => widget.controller.add(book.id)),
                  ),
                ),
              ] else
                Form(
                  key: form,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: title,
                        decoration: const InputDecoration(labelText: 'Título'),
                        maxLength: 500,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Ingresa el título.'
                            : null,
                      ),
                      TextFormField(
                        controller: author,
                        decoration: const InputDecoration(labelText: 'Autor'),
                        maxLength: 300,
                      ),
                      TextFormField(
                        controller: pages,
                        decoration: const InputDecoration(
                          labelText: 'Total de páginas (opcional)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value != null &&
                                value.trim().isNotEmpty &&
                                (int.tryParse(value) ?? 0) <= 0
                            ? 'Ingresa un total positivo.'
                            : null,
                      ),
                      TextFormField(
                        controller: publisher,
                        decoration: const InputDecoration(
                          labelText: 'Editorial',
                        ),
                        maxLength: 300,
                      ),
                      TextFormField(
                        controller: isbn,
                        decoration: const InputDecoration(
                          labelText: 'ISBN (opcional)',
                        ),
                        maxLength: 32,
                      ),
                    ],
                  ),
                ),
              if (busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: busy ? null : () => setState(() => manual = !manual),
          child: Text(manual ? 'Ver catálogo' : 'Registrar libro'),
        ),
        if (manual)
          FilledButton(
            onPressed: busy
                ? null
                : () {
                    if (!form.currentState!.validate()) return;
                    _save(
                      () => widget.controller.createAndAdd({
                        'title': title.text.trim(),
                        'author': author.text.trim(),
                        'publisher': publisher.text.trim(),
                        'isbn': isbn.text.trim(),
                        if (pages.text.trim().isNotEmpty)
                          'totalPages': int.parse(pages.text.trim()),
                      }),
                    );
                  },
            child: const Text('Guardar y añadir'),
          ),
      ],
    ),
  );
}
