import 'package:flutter/material.dart';

import '../../models/book_status.dart';
import '../../models/library_book.dart';
import '../../models/reading_record.dart';
import '../screens/simulated_reader_screen.dart';

/// Adaptador del punto de entrada anterior: ahora navega a una pantalla completa.
Future<void> showSimulatedReader({
  required BuildContext context,
  required LibraryBook book,
  required int initialPage,
  required ValueChanged<ReadingRecord> onChanged,
}) {
  final progress = ((initialPage + 1) * 25).clamp(0, 100);
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SimulatedReaderScreen(
        book: book,
        initialProgress: progress,
        initialStatus: progress == 100 ? BookStatus.leido : BookStatus.leyendo,
        onChanged: onChanged,
      ),
    ),
  );
}
