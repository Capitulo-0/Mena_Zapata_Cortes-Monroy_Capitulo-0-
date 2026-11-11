import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/book_status.dart';

class ReadingStatusField extends StatefulWidget {
  const ReadingStatusField({
    super.key,
    required this.status,
    required this.onChanged,
  });
  final BookStatus status;
  final FutureOr<void> Function(BookStatus) onChanged;
  @override
  State<ReadingStatusField> createState() => _ReadingStatusFieldState();
}

class _ReadingStatusFieldState extends State<ReadingStatusField> {
  bool busy = false;
  int revision = 0;
  Future<void> change(BookStatus? value) async {
    if (value == null || value == widget.status || busy) return;
    setState(() => busy = true);
    try {
      await widget.onChanged(value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar el estado. Inténtalo nuevamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          revision++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: DropdownButtonFormField<BookStatus>(
      key: ValueKey('${widget.status}:$revision'),
      initialValue: widget.status,
      isExpanded: true,
      style: TextStyle(fontSize: 13, color: AppColors.textPrimaryOf(context)),
      decoration: InputDecoration(
        labelText: busy ? 'Guardando estado…' : 'Estado de lectura',
        filled: true,
        fillColor: AppColors.surfaceOf(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: BookStatus.values
          .map(
            (value) => DropdownMenuItem(value: value, child: Text(value.label)),
          )
          .toList(),
      onChanged: busy ? null : change,
    ),
  );
}
