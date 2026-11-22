import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../maps/data/services/geoapify_places_service.dart';
import '../../../maps/models/map_point.dart';
import '../../../maps/models/map_point_type.dart';
import 'home_section_title.dart';

/// Muestra el punto real más cercano al GPS del lector; nunca usa datos demo.
class NearbyReadingPointSection extends StatefulWidget {
  const NearbyReadingPointSection({
    super.key,
    required this.onOpenPoints,
    this.onOpenNearbyPoint,
  });

  final VoidCallback onOpenPoints;
  final ValueChanged<MapPoint>? onOpenNearbyPoint;

  @override
  State<NearbyReadingPointSection> createState() =>
      _NearbyReadingPointSectionState();
}

class _NearbyReadingPointSectionState extends State<NearbyReadingPointSection> {
  MapPoint? _nearest;
  double? _distanceMeters;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadNearest();
  }

  // Caché de sesión: resiste el desmontaje del widget al desplazar el Home.
  // Además comparte una única solicitud si varios montajes coinciden.
  static const Duration _cacheLifetime = Duration(minutes: 15);
  static const Duration _failureCooldown = Duration(minutes: 1);
  static _NearbySnapshot? _cached;
  static DateTime? _cachedAt;
  static DateTime? _lastFailureAt;
  static Future<_NearbySnapshot>? _pendingRequest;

  Future<void> _loadNearest({bool forceRefresh = false}) async {
    if (!mounted) return;
    final now = DateTime.now();
    final existing = _cached;
    if (!forceRefresh &&
        existing != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheLifetime) {
      setState(() {
        _nearest = existing.point;
        _distanceMeters = existing.distanceMeters;
        _message = existing.message;
        _loading = false;
      });
      return;
    }
    if (!forceRefresh &&
        existing == null &&
        _lastFailureAt != null &&
        now.difference(_lastFailureAt!) < _failureCooldown) {
      setState(() {
        _message = 'No pudimos actualizar los lugares. Intenta nuevamente.';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final request = _pendingRequest ??= _fetchNearest();
      final result = await request;
      if (!mounted) return;
      setState(() {
        _nearest = result.point;
        _distanceMeters = result.distanceMeters;
        _message = result.message;
      });
    } on _LocationUnavailable catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on GeoapifyException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'No pudimos obtener tu ubicación o los lugares cercanos.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static Future<_NearbySnapshot> _fetchNearest() async {
    final service = GeoapifyPlacesService();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _LocationUnavailable(
          'Activa el GPS para ver lugares cercanos.',
        );
      }
      // Home no solicita permisos; Maps sigue gestionando su concesión.
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw const _LocationUnavailable(
          'Permite la ubicación desde Maps para encontrar el punto más cercano.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final points = await service.findNearby(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      MapPoint? closest;
      double? closestMeters;
      for (final point in points) {
        final meters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          point.position.latitude,
          point.position.longitude,
        );
        if (closestMeters == null || meters < closestMeters) {
          closest = point;
          closestMeters = meters;
        }
      }
      final result = _NearbySnapshot(
        point: closest,
        distanceMeters: closestMeters,
        message: closest == null
            ? 'No encontramos puntos lectores en un radio de 3 km.'
            : null,
      );
      _cached = result;
      _cachedAt = DateTime.now();
      _lastFailureAt = null;
      return result;
    } catch (_) {
      _lastFailureAt = DateTime.now();
      rethrow;
    } finally {
      service.dispose();
      _pendingRequest = null;
    }
  }

  static IconData _iconFor(MapPointType type) {
    switch (type) {
      case MapPointType.library:
        return Icons.local_library_outlined;
      case MapPointType.cafe:
        return Icons.local_cafe_outlined;
      case MapPointType.bookstore:
        return Icons.menu_book_outlined;
      case MapPointType.museum:
        return Icons.museum_outlined;
      case MapPointType.culturalCenter:
        return Icons.account_balance_outlined;
      case MapPointType.park:
        return Icons.park_outlined;
      case MapPointType.bookFair:
        return Icons.collections_bookmark_outlined;
      case MapPointType.literaryEvent:
        return Icons.auto_stories_outlined;
    }
  }

  String _distanceLabel(double meters) =>
      'A ${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km de ti';

  @override
  Widget build(BuildContext context) {
    final deep = AppColors.deepOf(context);
    final gold = AppColors.goldOf(context);
    final onDeep = AppColors.isDark(context)
        ? AppColors.darkTextPrimary
        : AppColors.background;
    final nearest = _nearest;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeSectionTitle('Puntos Lectores Cercanos ☕'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: deep,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: gold.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _loading
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: gold,
                          ),
                        )
                      : Icon(
                          nearest == null
                              ? Icons.location_off_outlined
                              : _iconFor(nearest.type),
                          color: gold,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loading
                            ? 'Buscando tu punto más cercano…'
                            : nearest?.name ?? 'Ubicación no disponible',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cinzel(
                          color: gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _loading
                            ? 'Consultando GPS y lugares reales'
                            : nearest == null
                            ? (_message ?? 'No hay lugares disponibles.')
                            : [
                                if (nearest.commune != null &&
                                    nearest.commune!.trim().isNotEmpty)
                                  nearest.commune!.trim(),
                                _distanceLabel(_distanceMeters!),
                              ].join(' · '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: onDeep,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filled(
                      onPressed: () {
                        if (nearest != null &&
                            widget.onOpenNearbyPoint != null) {
                          widget.onOpenNearbyPoint!(nearest);
                        } else {
                          widget.onOpenPoints();
                        }
                      },
                      tooltip: 'Ver mapa',
                      style: IconButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: AppColors.deep,
                      ),
                      icon: const Icon(Icons.map_outlined),
                    ),
                    if (!_loading && nearest == null)
                      IconButton(
                        onPressed: () => _loadNearest(forceRefresh: true),
                        tooltip: 'Reintentar ubicación',
                        icon: Icon(Icons.refresh, color: gold),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationUnavailable implements Exception {
  const _LocationUnavailable(this.message);
  final String message;
}

class _NearbySnapshot {
  const _NearbySnapshot({
    required this.point,
    required this.distanceMeters,
    this.message,
  });

  final MapPoint? point;
  final double? distanceMeters;
  final String? message;
}
