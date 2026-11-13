
class ProfileDemoData {
  ProfileDemoData._();

  static const List<Map<String, String>> favoriteQuotes = [
    {
      'text': 'No hay encanto igual a la ternura del corazón.',
      'author': 'Jane Austen',
      'work': 'Emma',
    },
    {
      'text': 'El que lee mucho y anda mucho, ve mucho y sabe mucho.',
      'author': 'Miguel de Cervantes',
      'work': 'Don Quijote de la Mancha',
    },
    {
      'text': 'Una historia puede comenzar en cualquier página.',
      'author': 'Capítulo 0',
      'work': '',
    },
    {
      'text': 'A veces un libro llega justo cuando más lo necesitamos.',
      'author': 'Capítulo 0',
      'work': '',
    },
  ];

  static const List<Map<String, String>> baseMoods = [
    {
      'emoji': '☕',
      'label': 'Leyendo con cafecito',
      'detail': 'Clásicos tranquilos para leer sin prisa',
    },
    {
      'emoji': '🕯️',
      'label': 'Entre sombras y misterio',
      'detail': 'Gótico, misterio y atmósferas intensas',
    },
    {
      'emoji': '💗',
      'label': 'Con el corazón romántico',
      'detail': 'Romance clásico y vínculos inolvidables',
    },
    {
      'emoji': '🌙',
      'label': 'Lecturas para la noche',
      'detail': 'Historias perfectas para el final del día',
    },
  ];

  // Sin datos simulados de relaciones sociales.
  // Las listas reales se conectarán al backend cuando estén disponibles.
  static const List<Map<String, String>> followers = [];

  static const List<Map<String, String>> following = [];
}
