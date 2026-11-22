part 'prepared_free_works.dart';

/// An independently identified edition; never assumes identity with a Gutendex ID.
class FreeWork {
  const FreeWork({
    required this.id,
    required this.title,
    required this.author,
    required this.language,
    required this.source,
    required this.edition,
    required this.conditions,
    this.assetPath,
    this.genre,
    this.isComplete = false,
  });
  final String id, title, author, language, source, edition, conditions;
  final String? assetPath;
  final String? genre;
  final bool isComplete;
  bool get available => isComplete && assetPath != null;
}

const freeWorks = [
  FreeWork(
    id: 'wikisource-es-lazarillo-1921',
    title: 'El Lazarillo de Tormes',
    author: 'Anónimo',
    language: 'es',
    source: 'https://es.wikisource.org/wiki/El_Lazarillo_de_Tormes',
    edition: 'Madrid · Tipográfica Renovación / Editorial Calpe · 1921',
    conditions: 'Obra original de dominio público. Transcripción de la comunidad de Wikisource y conversión a texto: CC BY-SA 4.0, cuando corresponda. Incluye prólogo original y siete tratados. Se conservan la ortografía y el texto; no las cursivas ni la paginación impresa. Créditos e historiales al final del texto.\nhttps://creativecommons.org/licenses/by-sa/4.0/',
    assetPath: 'assets/free_works/lazarillo_1921.txt',
    isComplete: true,
  ),
  FreeWork(
    id: 'wikisource-es-vida-sueno-djvu',
    title: 'La vida es sueño',
    author: 'Pedro Calderón de la Barca',
    language: 'es',
    source: 'https://es.wikisource.org/wiki/La_vida_es_sueño',
    edition: 'Ejemplar La vida es sueño.djvu · portada Insel-Verlag, Leipzig · fecha no confirmada',
    conditions: 'Obra original de dominio público (Calderón, 1600–1681). Transcripción de Wikisource y conversión: CC BY-SA 4.0, cuando corresponda. Personajes y tres jornadas completas; sin biografía editorial. El índice del escaneo indica 1900/Pandora, distinto de la portada: no se afirma una fecha editorial. Transcripción corregida, no totalmente validada. Créditos e historiales al final del texto.\nhttps://creativecommons.org/licenses/by-sa/4.0/',
    assetPath: 'assets/free_works/vida_sueno.txt',
    isComplete: true,
  ),
  ...preparedFreeWorks,
];
