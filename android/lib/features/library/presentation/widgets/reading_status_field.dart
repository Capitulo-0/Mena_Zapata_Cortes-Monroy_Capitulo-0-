import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/book_status.dart';

/// Selector compartido; la normalización de páginas y progreso pertenece al estado local.
class ReadingStatusField extends StatelessWidget {
  const ReadingStatusField({
    super.key,
    required this.status,
    required this.onChanged,
  });
  final BookStatus status;
  final ValueChanged<BookStatus> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: DropdownButtonFormField<BookStatus>(
      key: ValueKey(status),
      initialValue: status,
      isExpanded: true,
      style: TextStyle(fontSize: 13, color: AppColors.textPrimaryOf(context)),
      decoration: InputDecoration(
        labelText: 'Estado de lectura',
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
      onChanged: (value) {
        if (value != null && value != status) onChanged(value);
      },
    ),
  );
}
