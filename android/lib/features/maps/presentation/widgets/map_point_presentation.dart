import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/map_point_type.dart';

class MapPointPresentation {
  MapPointPresentation._();

  static double markerHue(MapPointType type) {
    switch (type) {
      case MapPointType.library:
        return BitmapDescriptor.hueAzure;
      case MapPointType.cafe:
        return BitmapDescriptor.hueOrange;
      case MapPointType.bookFair:
        return BitmapDescriptor.hueRose;
      case MapPointType.literaryEvent:
        return BitmapDescriptor.hueViolet;
      case MapPointType.culturalCenter:
        return BitmapDescriptor.hueGreen;
    }
  }

  static IconData iconForType(MapPointType type) {
    switch (type) {
      case MapPointType.library:
        return Icons.local_library_outlined;
      case MapPointType.cafe:
        return Icons.local_cafe_outlined;
      case MapPointType.bookFair:
        return Icons.menu_book_outlined;
      case MapPointType.literaryEvent:
        return Icons.auto_stories_outlined;
      case MapPointType.culturalCenter:
        return Icons.account_balance_outlined;
    }
  }

  static String labelForType(MapPointType type) {
    switch (type) {
      case MapPointType.library:
        return 'Biblioteca';
      case MapPointType.cafe:
        return 'Cafetería / espacio lector';
      case MapPointType.bookFair:
        return 'Feria del libro';
      case MapPointType.literaryEvent:
        return 'Evento literario';
      case MapPointType.culturalCenter:
        return 'Centro cultural';
    }
  }
}
