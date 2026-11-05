enum BookStatus { porLeer, leyendo, leido }

extension BookStatusPresentation on BookStatus {
  String get label => switch (this) {
    BookStatus.porLeer => 'Por leer',
    BookStatus.leyendo => 'Leyendo',
    BookStatus.leido => 'Leído',
  };
  String get readingActionLabel => switch (this) {
    BookStatus.porLeer => 'Comenzar a leer',
    BookStatus.leyendo => 'Continuar leyendo',
    BookStatus.leido => 'Abrir libro',
  };
}
