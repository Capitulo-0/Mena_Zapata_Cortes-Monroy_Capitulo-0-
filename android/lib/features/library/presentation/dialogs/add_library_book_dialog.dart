import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/library_controller.dart';

Future<void> showAddLibraryBookDialog(
  BuildContext context,
  LibraryController controller, {
  bool initialManual = false,
}) => showDialog<void>(
  context: context,
  builder: (_) => _AddLibraryBookDialog(
    controller: controller,
    initialManual: initialManual,
  ),
);

class _AddLibraryBookDialog extends StatefulWidget {
  const _AddLibraryBookDialog({
    required this.controller,
    required this.initialManual,
  });

  final bool initialManual;
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

  late bool manual = widget.initialManual;
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

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    bool optional = false,
  }) {
    final gold = AppColors.goldOf(context);
    return InputDecoration(
      labelText: optional ? '$label (opcional)' : label,
      labelStyle: GoogleFonts.inter(
        color: AppColors.textSecondaryOf(context),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: GoogleFonts.inter(
        color: AppColors.accentOf(context),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, size: 19, color: gold),
      filled: true,
      fillColor: AppColors.backgroundOf(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: gold.withValues(alpha: .53)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: gold.withValues(alpha: .53)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.accentOf(context), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  Widget _formField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
    bool optional = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: TextFormField(
      controller: controller,
      decoration: _fieldDecoration(
        context,
        label: label,
        icon: icon,
        optional: optional,
      ),
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(
        color: AppColors.textPrimaryOf(context),
        fontSize: 13,
      ),
    ),
  );

  Widget _dialogContents(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.goldOf(context).withValues(alpha: .15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              manual ? Icons.menu_book_rounded : Icons.library_books_outlined,
              color: AppColors.deepOf(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manual ? 'Registrar libro' : 'Añadir a Mi Biblioteca',
                  style: GoogleFonts.cinzel(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  manual
                      ? 'Guarda tus lecturas físicas en un solo lugar ✦'
                      : 'Selecciona una obra para llevar tu registro ✦',
                  style: GoogleFonts.merriweather(
                    color: AppColors.textSecondaryOf(context),
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Divider(color: AppColors.goldOf(context).withValues(alpha: .38)),
      const SizedBox(height: 12),
      if (widget.controller.error != null) ...[
        Text(
          widget.controller.error!,
          key: const ValueKey('add-library-error'),
          style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
        ),
        TextButton(
          onPressed: busy ? null : widget.controller.load,
          child: const Text('Recargar catálogo'),
        ),
        const SizedBox(height: 8),
      ],
      if (!manual) ...[
        if (widget.controller.catalog.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'El catálogo está vacío. Puedes registrar los datos de un libro.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondaryOf(context),
                fontSize: 12,
              ),
            ),
          ),
        ...widget.controller.catalog.map(
          (book) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.goldOf(context).withValues(alpha: .42),
              ),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                book.title,
                style: GoogleFonts.merriweather(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              subtitle: Text(
                book.author,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              trailing: Icon(
                widget.controller.entries.containsKey(book.id)
                    ? Icons.check_circle_outline_rounded
                    : Icons.add_circle_outline_rounded,
                color: AppColors.accentOf(context),
              ),
              onTap: busy
                  ? null
                  : () => _save(() => widget.controller.add(book.id)),
            ),
          ),
        ),
      ] else
        Form(
          key: form,
          child: Column(
            children: [
              _formField(
                context,
                controller: title,
                label: 'Título',
                icon: Icons.auto_stories_outlined,
                maxLength: 500,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa el título.'
                    : null,
              ),
              _formField(
                context,
                controller: author,
                label: 'Autor',
                icon: Icons.person_outline_rounded,
                maxLength: 300,
              ),
              _formField(
                context,
                controller: pages,
                label: 'Total de páginas',
                icon: Icons.numbers_rounded,
                optional: true,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        (int.tryParse(value) ?? 0) <= 0
                    ? 'Ingresa un total positivo.'
                    : null,
              ),
              _formField(
                context,
                controller: publisher,
                label: 'Editorial',
                icon: Icons.apartment_outlined,
                maxLength: 300,
              ),
              _formField(
                context,
                controller: isbn,
                label: 'ISBN',
                icon: Icons.qr_code_rounded,
                optional: true,
                maxLength: 32,
              ),
            ],
          ),
        ),
      if (busy) const LinearProgressIndicator(minHeight: 2),
    ],
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => Dialog(
      backgroundColor: AppColors.surfaceOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(
          color: AppColors.goldOf(context).withValues(alpha: .65),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(child: _dialogContents(context)),
              ),
              const SizedBox(height: 8),
              Divider(color: AppColors.goldOf(context).withValues(alpha: .27)),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: busy ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondaryOf(context),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() => manual = !manual),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accentOf(context),
                      ),
                      child: Text(manual ? 'Ver catálogo' : 'Registrar libro'),
                    ),
                  ),
                ],
              ),
              if (manual) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
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
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('Guardar y añadir'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentOf(context),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(47),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
