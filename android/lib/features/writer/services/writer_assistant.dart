enum WriterAssistantTask {
  ideas('Generar ideas'),
  titles('Sugerir títulos'),
  synopsis('Mejorar sinopsis'),
  continueScene('Continuar una escena', 'CONTINUE'),
  next('Qué podría ocurrir después'),
  style('Mejorar redacción'),
  correct('Corregir ortografía y gramática'),
  dialogue('Proponer diálogos'),
  block('Superar un bloqueo creativo');

  const WriterAssistantTask(this.label, [this._wireName]);
  final String label;
  final String? _wireName;
  String get wireName => _wireName ?? name.toUpperCase();

  bool get needsText => switch (this) {
    synopsis || style || correct => true,
    _ => false,
  };

  bool get canInsert => switch (this) {
    continueScene || style || correct || dialogue => true,
    _ => false,
  };
}

abstract interface class WriterAssistantRepository {
  Future<List<String>> suggest({
    required WriterAssistantTask task,
    required String genre,
    required String context,
    required String direction,
    required String tone,
  });
}
