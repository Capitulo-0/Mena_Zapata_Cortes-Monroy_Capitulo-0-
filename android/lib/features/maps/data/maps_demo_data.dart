import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/map_point.dart';
import '../models/map_point_type.dart';

class MapsDemoData {
  MapsDemoData._();

  static const List<MapPoint> points = [
    MapPoint(
      id: 'library_1',
      name: 'Biblioteca - Punto demo',
      type: MapPointType.library,
      position: LatLng(-33.4398, -70.6796),
      address: 'Santiago, Región Metropolitana',
      description:
          'Espacio de lectura y consulta de libros. Este punto es temporal mientras conectamos los datos reales.',
      schedule: 'Lunes a sábado',
      isFree: true,
    ),
    MapPoint(
      id: 'cafe_1',
      name: 'Café lector - Punto demo',
      type: MapPointType.cafe,
      position: LatLng(-33.4437, -70.6536),
      address: 'Santiago Centro',
      description:
          'Cafetería de demostración para representar espacios cómodos donde leer y compartir.',
      schedule: '09:00 - 20:00',
      isFree: false,
    ),
    MapPoint(
      id: 'fair_1',
      name: 'Feria del Libro - Evento demo',
      type: MapPointType.bookFair,
      position: LatLng(-33.4372, -70.6383),
      address: 'Santiago, Región Metropolitana',
      description:
          'Ejemplo de feria del libro. Más adelante estos eventos serán obtenidos desde el backend.',
      date: 'Fecha por confirmar',
      schedule: '11:00 - 20:00',
      isFree: true,
    ),
    MapPoint(
      id: 'event_1',
      name: 'Encuentro de Lectores - Evento demo',
      type: MapPointType.literaryEvent,
      position: LatLng(-33.4524, -70.6585),
      address: 'Santiago, Región Metropolitana',
      description:
          'Actividad literaria de demostración para visualizar encuentros y eventos relacionados con la lectura.',
      date: 'Próximamente',
      schedule: '18:00',
      isFree: true,
    ),
    MapPoint(
      id: 'cultural_1',
      name: 'Centro Cultural - Punto demo',
      type: MapPointType.culturalCenter,
      position: LatLng(-33.4328, -70.6505),
      address: 'Santiago, Región Metropolitana',
      description:
          'Espacio cultural que puede albergar talleres, clubes de lectura, presentaciones y actividades literarias.',
      schedule: '10:00 - 19:00',
      isFree: true,
    ),
  ];
}
