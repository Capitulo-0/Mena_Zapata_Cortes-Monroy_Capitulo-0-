import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'map_point_type.dart';

class MapPoint {
  const MapPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.address,
    required this.description,
    this.schedule,
    this.date,
    this.isFree = true,
  });

  final String id;
  final String name;
  final MapPointType type;
  final LatLng position;
  final String address;
  final String description;
  final String? schedule;
  final String? date;
  final bool isFree;
}
