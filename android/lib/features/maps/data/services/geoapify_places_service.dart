import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as osm;

import '../../models/map_point.dart';
import '../../models/map_point_type.dart';

class GeoapifyException implements Exception {
  const GeoapifyException(this.message, {this.retryAfter});

  final String message;
  final Duration? retryAfter;

  @override
  String toString() => message;
}

class GeoapifyPlacesService {
  GeoapifyPlacesService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const String _apiKey = String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: '',
  );

  static const int defaultRadiusMeters = 3000;
  static const int maxRadiusMeters = 5000;
  static const int maxPlaces = 100;

  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _defaultCooldown = Duration(minutes: 2);

  static const List<String> _categories = [
    'education.library',
    'catering.cafe',
    'commercial.books',
    'entertainment.museum',
    'entertainment.culture.arts_centre',
    'leisure.park',
  ];

  final http.Client _client;
  final bool _ownsClient;

  DateTime? _blockedUntil;

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<List<MapPoint>> findNearby({
    required double latitude,
    required double longitude,
    int radiusMeters = defaultRadiusMeters,
  }) async {
    if (_apiKey.isEmpty) {
      throw const GeoapifyException('Falta configurar GEOAPIFY_API_KEY.');
    }

    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const GeoapifyException(
        'Las coordenadas de búsqueda no son válidas.',
      );
    }

    if (radiusMeters < 100 || radiusMeters > maxRadiusMeters) {
      throw const GeoapifyException(
        'El radio debe estar entre 100 y 5000 metros.',
      );
    }

    final blockedUntil = _blockedUntil;
    if (blockedUntil != null) {
      final remaining = blockedUntil.difference(DateTime.now());

      if (remaining > Duration.zero) {
        throw GeoapifyException(
          'Geoapify está limitando las solicitudes. '
          'Intenta nuevamente más tarde.',
          retryAfter: remaining,
        );
      }

      _blockedUntil = null;
    }

    final center = '$longitude,$latitude';

    final uri = Uri.https('api.geoapify.com', '/v2/places', {
      'categories': _categories.join(','),
      'filter': 'circle:$center,$radiusMeters',
      'bias': 'proximity:$center',
      'limit': '$maxPlaces',
      'lang': 'es',
      'apiKey': _apiKey,
    });

    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);

      debugPrint('[GEOAPIFY] HTTP ${response.statusCode}');

      if (response.statusCode == 429) {
        final retryAfter = _parseRetryAfter(response.headers['retry-after']);

        final cooldown = retryAfter ?? _defaultCooldown;
        _blockedUntil = DateTime.now().add(cooldown);

        throw GeoapifyException(
          'Geoapify está limitando las solicitudes (HTTP 429).',
          retryAfter: cooldown,
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const GeoapifyException(
          'Geoapify rechazó la clave API o sus permisos.',
        );
      }

      if (response.statusCode == 502 ||
          response.statusCode == 503 ||
          response.statusCode == 504) {
        throw GeoapifyException(
          'Geoapify no está disponible '
          '(HTTP ${response.statusCode}).',
        );
      }

      if (response.statusCode != 200) {
        throw GeoapifyException(
          'Geoapify respondió con HTTP '
          '${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        throw const GeoapifyException('La respuesta de Geoapify no es válida.');
      }

      final features = decoded['features'];

      if (features is! List) {
        throw const GeoapifyException(
          'Geoapify no devolvió una lista de lugares.',
        );
      }

      final byId = <String, MapPoint>{};

      for (final feature in features) {
        if (feature is! Map) continue;

        final point = _parseFeature(feature);

        if (point != null) {
          byId[point.id] = point;
        }
      }

      final points = byId.values.toList();

      final origin = osm.LatLng(latitude, longitude);
      const distance = osm.Distance();

      points.sort((a, b) {
        final positionA = osm.LatLng(a.position.latitude, a.position.longitude);

        final positionB = osm.LatLng(b.position.latitude, b.position.longitude);

        return distance
            .as(osm.LengthUnit.Meter, origin, positionA)
            .compareTo(distance.as(osm.LengthUnit.Meter, origin, positionB));
      });

      // Diagnóstico de cobertura por categoría.
      // Solo cuenta resultados recibidos: no genera consultas adicionales.
      if (kDebugMode) {
        final counts = <MapPointType, int>{};

        for (final point in points.take(maxPlaces)) {
          counts.update(point.type, (count) => count + 1, ifAbsent: () => 1);
        }

        debugPrint(
          '[GEOAPIFY] Lugares encontrados: '
          '${points.take(maxPlaces).length}',
        );

        for (final type in [
          MapPointType.library,
          MapPointType.cafe,
          MapPointType.bookstore,
          MapPointType.museum,
          MapPointType.culturalCenter,
          MapPointType.park,
        ]) {
          debugPrint(
            '[GEOAPIFY COBERTURA] ${type.name}: '
            '${counts[type] ?? 0}',
          );
        }
      }

      return points.take(maxPlaces).toList();
    } on GeoapifyException {
      rethrow;
    } on TimeoutException {
      throw const GeoapifyException(
        'La búsqueda tardó demasiado. Intenta nuevamente.',
      );
    } on SocketException {
      throw const GeoapifyException('No se pudo conectar con Geoapify.');
    } on http.ClientException {
      throw const GeoapifyException('Error de conexión con Geoapify.');
    } on FormatException {
      throw const GeoapifyException(
        'No fue posible interpretar los datos de Geoapify.',
      );
    }
  }

  MapPoint? _parseFeature(Map feature) {
    final rawProperties = feature['properties'];
    final rawGeometry = feature['geometry'];

    if (rawProperties is! Map || rawGeometry is! Map) {
      return null;
    }

    final categories = rawProperties['categories'];

    if (categories is! List) return null;

    final type = _mapCategory(categories);

    if (type == null) return null;

    final name = _nonEmpty(rawProperties['name']);

    if (name == null) return null;

    final coordinates = rawGeometry['coordinates'];

    if (coordinates is! List || coordinates.length < 2) {
      return null;
    }

    // GeoJSON utiliza [longitud, latitud].
    final longitude = coordinates[0];
    final latitude = coordinates[1];

    if (latitude is! num || longitude is! num) {
      return null;
    }

    final lat = latitude.toDouble();
    final lon = longitude.toDouble();

    if (!lat.isFinite ||
        !lon.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      return null;
    }

    final placeId = _nonEmpty(rawProperties['place_id']);
    if (placeId == null) return null;

    final address =
        _nonEmpty(rawProperties['address_line2']) ??
        _nonEmpty(rawProperties['formatted']) ??
        'Dirección no disponible';

    // La comuna/localidad se obtiene de Geoapify, no del nombre ni de la
    // ubicación del lector. Evitamos mostrar una comuna supuesta.
    final commune =
        _nonEmpty(rawProperties['municipality']) ??
        _nonEmpty(rawProperties['city_district']) ??
        _nonEmpty(rawProperties['suburb']) ??
        _nonEmpty(rawProperties['district']) ??
        _nonEmpty(rawProperties['city']);

    final description =
        _nonEmpty(rawProperties['description']) ??
        'Lugar registrado en OpenStreetMap. '
            'La información disponible puede estar incompleta.';

    return MapPoint(
      id: 'geoapify_$placeId',
      name: name,
      type: type,
      position: LatLng(lat, lon),
      address: address,
      commune: commune,
      description: description,
      schedule: _nonEmpty(rawProperties['opening_hours']),
      showAdmission: false,
      osmUrl: _buildOsmUrl(rawProperties['datasource']),
    );
  }

  MapPointType? _mapCategory(List categories) {
    final values = categories.whereType<String>().toSet();

    if (values.contains('education.library')) {
      return MapPointType.library;
    }

    if (values.contains('catering.cafe')) {
      return MapPointType.cafe;
    }

    if (values.contains('commercial.books')) {
      return MapPointType.bookstore;
    }

    if (values.contains('entertainment.museum')) {
      return MapPointType.museum;
    }

    if (values.contains('entertainment.culture.arts_centre')) {
      return MapPointType.culturalCenter;
    }

    if (values.contains('leisure.park')) {
      return MapPointType.park;
    }

    return null;
  }

  String? _buildOsmUrl(dynamic datasource) {
    if (datasource is! Map) return null;

    final raw = datasource['raw'];
    if (raw is! Map) return null;

    final osmType = raw['osm_type'];
    final osmId = raw['osm_id'];

    const types = {'n': 'node', 'w': 'way', 'r': 'relation'};

    final type = types[osmType];
    final id = int.tryParse('$osmId');

    if (type == null || id == null || id <= 0) {
      return null;
    }

    return 'https://www.openstreetmap.org/$type/$id';
  }

  String? _nonEmpty(dynamic value) {
    if (value is! String) return null;

    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  Duration? _parseRetryAfter(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final seconds = int.tryParse(value.trim());

    if (seconds != null) {
      return Duration(seconds: seconds < 0 ? 0 : seconds);
    }

    try {
      final date = HttpDate.parse(value.trim());
      final remaining = date.difference(DateTime.now().toUtc());

      return remaining > Duration.zero ? remaining : Duration.zero;
    } on FormatException {
      return null;
    }
  }
}
