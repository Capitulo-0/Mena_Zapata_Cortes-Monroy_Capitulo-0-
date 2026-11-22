import 'book_status.dart';

/// Modelo de edición. El repositorio adapta páginas y formato al contrato REST.
class ReadingRecord {
  const ReadingRecord({
    required this.format,
    required this.currentPage,
    required this.totalPages,
    required this.publisher,
    required this.status,
    this.readerProgress,
  });
  final String format;
  final int currentPage;
  final int totalPages;
  final String publisher;
  final BookStatus status;
  final int? readerProgress;
  int get progress =>
      readerProgress ??
      (totalPages <= 0
          ? (status == BookStatus.leido ? 100 : 0)
          : (currentPage * 100 ~/ totalPages).clamp(0, 100));
  ReadingRecord withProgress(int progress, BookStatus nextStatus) {
    final bounded = progress.clamp(0, 100);
    if (bounded == this.progress && nextStatus == status) return this;
    final simulated = format == 'Lector simulado';
    final target = nextStatus == BookStatus.porLeer
        ? 0
        : nextStatus == BookStatus.leido
        ? 100
        : bounded;
    // Una página entera debe representar al menos el porcentaje solicitado.
    // Usar techo entero evita el doble truncamiento (33% de 3 páginas -> 0).
    final page = totalPages <= 0
        ? 0
        : ((target * totalPages + 99) ~/ 100).clamp(0, totalPages);
    final actualProgress = simulated
        ? target
        : totalPages <= 0
        ? 0
        : (page * 100 ~/ totalPages).clamp(0, 100);
    final actualStatus = nextStatus == BookStatus.porLeer
        ? BookStatus.porLeer
        : actualProgress == 100
        ? BookStatus.leido
        : BookStatus.leyendo;
    return ReadingRecord(
      format: format,
      currentPage: page,
      totalPages: totalPages,
      publisher: publisher,
      status: actualStatus,
      readerProgress: simulated ? target : null,
    );
  }

  /// Cambia el estado sin recalcular páginas intermedias a partir de un porcentaje redondeado.
  ReadingRecord withStatus(BookStatus nextStatus, {ReadingRecord? resume}) {
    if (nextStatus == status) return this;
    var page = currentPage;
    int? scroll = readerProgress;
    if (nextStatus == BookStatus.porLeer) {
      page = 0;
      if (format == 'Lector simulado') scroll = 0;
    } else if (nextStatus == BookStatus.leido) {
      page = totalPages;
      if (format == 'Lector simulado') scroll = 100;
    } else if (progress >= 100) {
      final canResume =
          resume != null &&
          resume.format == format &&
          resume.totalPages == totalPages &&
          resume.progress > 0 &&
          resume.progress < 100;
      page = canResume
          ? resume.currentPage
          : (totalPages - 1).clamp(0, totalPages);
      if (format == 'Lector simulado') {
        scroll = canResume ? resume.progress : 99;
      }
    }
    return ReadingRecord(
      format: format,
      currentPage: page,
      totalPages: totalPages,
      publisher: publisher,
      status: nextStatus,
      readerProgress: scroll,
    );
  }
}
