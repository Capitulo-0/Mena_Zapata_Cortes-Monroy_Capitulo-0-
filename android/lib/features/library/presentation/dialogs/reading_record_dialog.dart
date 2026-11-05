import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/book_status.dart';
import '../../models/library_book.dart';
import '../../models/reading_record.dart';

Future<ReadingRecord?> showReadingRecordDialog({
  required BuildContext context,
  required LibraryBook book,
  required ReadingRecord? initial,
  required BookStatus status,
  required int progress,
}) => showDialog<ReadingRecord>(
  context: context,
  builder: (_) => _ReadingRecordDialog(
    book: book,
    initial: initial,
    status: status,
    progress: progress,
  ),
);

class _ReadingRecordDialog extends StatefulWidget {
  const _ReadingRecordDialog({
    required this.book,
    required this.initial,
    required this.status,
    required this.progress,
  });
  final LibraryBook book;
  final ReadingRecord? initial;
  final BookStatus status;
  final int progress;
  @override
  State<_ReadingRecordDialog> createState() => _ReadingRecordDialogState();
}

class _ReadingRecordDialogState extends State<_ReadingRecordDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _page;
  late final TextEditingController _total;
  late final TextEditingController _publisher;
  late String _format;
  late BookStatus _status;

  @override
  void initState() {
    super.initState();
    final record = widget.initial;
    final total = record?.totalPages ?? widget.book.totalPages;
    _page = TextEditingController(
      text: '${record?.currentPage ?? widget.progress * total ~/ 100}',
    );
    _total = TextEditingController(text: total > 0 ? '$total' : '');
    _publisher = TextEditingController(
      text: record?.publisher ?? widget.book.publisher,
    );
    _format = record?.format ?? 'Físico';
    _status = record?.status ?? widget.status;
  }

  @override
  void dispose() {
    _page.dispose();
    _total.dispose();
    _publisher.dispose();
    super.dispose();
  }

  Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.backgroundOf(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.goldOf(context).withValues(alpha: .45),
      ),
    ),
  );

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
      context,
      ReadingRecord(
        format: _format,
        currentPage: int.parse(_page.text),
        totalPages: int.parse(_total.text),
        publisher: _publisher.text.trim(),
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = int.tryParse(_total.text) ?? 0;
    final current = int.tryParse(_page.text) ?? 0;
    final percent = count > 0 ? (current * 100 ~/ count).clamp(0, 100) : 0;
    return Dialog(
      backgroundColor: AppColors.surfaceOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.goldOf(context).withValues(alpha: .28),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrar lectura',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.book.title,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 22),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section('Formato', [
                          DropdownButtonFormField<String>(
                            initialValue: _format,
                            decoration: _decoration('¿Cómo estás leyendo?'),
                            isExpanded: true,
                            items: ['Físico', 'Ebook', 'Otra plataforma']
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(
                                      v,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _format = value!),
                          ),
                        ]),
                        _section('Progreso', [
                          TextFormField(
                            key: const ValueKey('total-pages'),
                            controller: _total,
                            style: const TextStyle(fontSize: 14),
                            keyboardType: TextInputType.number,
                            decoration: _decoration('Total de páginas'),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                                ? 'Ingresa un total mayor que cero.'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            key: const ValueKey('current-page'),
                            controller: _page,
                            style: const TextStyle(fontSize: 14),
                            keyboardType: TextInputType.number,
                            decoration: _decoration('Página actual'),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              final t = int.tryParse(_total.text) ?? 0;
                              if (n == null || n < 0 || n > t) {
                                return 'Ingresa una página entre 0 y el total.';
                              }
                              if (_status == BookStatus.porLeer && n != 0) {
                                return 'Por leer requiere página 0.';
                              }
                              if (_status == BookStatus.leido && n != t) {
                                return 'Leído requiere llegar al total.';
                              }
                              if (_status == BookStatus.leyendo && n == t) {
                                return 'Selecciona Leído al completar el libro.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Progreso: $percent%',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percent / 100,
                            color: AppColors.accentOf(context),
                            backgroundColor: AppColors.surfaceSoftOf(context),
                          ),
                        ]),
                        _section('Información del libro', [
                          TextFormField(
                            controller: _publisher,
                            style: const TextStyle(fontSize: 14),
                            decoration: _decoration('Editorial'),
                          ),
                        ]),
                        _section('Estado', [
                          DropdownButtonFormField<BookStatus>(
                            initialValue: _status,
                            decoration: _decoration('Estado de lectura'),
                            isExpanded: true,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimaryOf(context),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: BookStatus.porLeer,
                                child: Text('Por leer'),
                              ),
                              DropdownMenuItem(
                                value: BookStatus.leyendo,
                                child: Text('Leyendo'),
                              ),
                              DropdownMenuItem(
                                value: BookStatus.leido,
                                child: Text('Leído'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _status = value!),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentOf(context),
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimary,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
