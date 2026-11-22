import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/services/geoapify_places_service.dart';
import '../../models/map_point.dart';
import '../../models/map_point_type.dart';
import '../widgets/map_point_card.dart';
import '../widgets/map_point_presentation.dart';
import '../widgets/maps_filters.dart';
import '../widgets/maps_header.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({
    super.key,
    required this.currentUsername,
    required this.currentName,
    this.highlightedPointId,
    this.highlightedPoint,
  });

  final String currentUsername;
  final String currentName;
  final String? highlightedPointId;
  final MapPoint? highlightedPoint;

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final ScrollController _filterScrollController = ScrollController();

  final GeoapifyPlacesService _geoapifyService = GeoapifyPlacesService();

  StreamSubscription<Position>? _positionSubscription;

  MapPointType? _selectedFilter;
  MapPoint? _selectedPoint;

  List<MapPoint> _realPoints = [];

  osm.LatLng? _userPosition;
  osm.LatLng? _pendingCameraPosition;
  final List<({osm.LatLng center, DateTime timestamp, List<MapPoint> points})>
  _placesCache = [];

  bool _mapReady = false;
  bool _locationLoading = false;
  bool _locationAllowed = false;
  bool _hasCenteredOnUser = false;

  bool _placesLoading = false;
  bool _hasLoadedPlaces = false;

  String? _placesError;

  static const osm.LatLng _initialCenter = osm.LatLng(-33.4489, -70.6693);

  static const double _initialZoom = 12.5;
  static const double _userZoom = 16.0;

  static const int _searchRadiusMeters = 3000;
  static const Duration _cacheDuration = Duration(minutes: 15);
  static const double _cacheDistanceMeters = 500;
  static const int _maxCachedZones = 12;

  static const String _cartoApiKey = String.fromEnvironment(
    'CARTO_API_KEY',
    defaultValue: '',
  );

  static const String _androidPackage = 'com.capitulo0.android';
  static const String _debugSha1 =
      '55:9F:B6:DF:2C:09:46:BC:6F:17:AC:DD:C9:E7:F7:6A:AE:23:B5:41';

  static const String _osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  bool get _useCarto => !kIsWeb && _cartoApiKey.isNotEmpty;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeMapData();
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedPointId != oldWidget.highlightedPointId ||
        widget.highlightedPoint != oldWidget.highlightedPoint) {
      // No dispara solicitudes: utiliza los puntos que Maps ya tiene.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusHighlightedPoint();
      });
    }
  }

  void _focusHighlightedPoint() {
    final id = widget.highlightedPointId;
    if (id == null) return;

    // El punto de Home ya tiene coordenadas reales en su caché de sesión.
    // No dependemos de que Maps vuelva a recibir el mismo resultado de Geoapify.
    final matches = _realPoints.where((point) => point.id == id);
    final point = matches.isNotEmpty ? matches.first : widget.highlightedPoint;
    if (point == null) return;

    if (_selectedFilter != null) {
      setState(() => _selectedFilter = null);
    }
    _focusPoint(point);
  }

  Future<void> _initializeMapData() async {
    // Primero se intenta obtener la posicion del lector.
    await _loadUserLocation(centerMap: widget.highlightedPointId == null);

    if (!mounted) return;
    await _loadNearbyPlaces();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopLocationUpdates();
    } else if (state == AppLifecycleState.resumed && _locationAllowed) {
      _resumeLocationUpdates();
    }
  }

  Future<void> _resumeLocationUpdates() async {
    if (!mounted || _locationLoading) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      final permission = await Geolocator.checkPermission();

      if (!mounted) return;

      final allowed =
          serviceEnabled &&
          (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse);

      _locationAllowed = allowed;

      if (allowed) {
        _startLocationUpdates();
      } else {
        _stopLocationUpdates();

        setState(() {
          _userPosition = null;
        });
      }
    } catch (error) {
      debugPrint('[MAPS] Error al reanudar GPS: $error');
    }
  }

  void _stopLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _stopLocationUpdates();
    _geoapifyService.dispose();
    _filterScrollController.dispose();
    _mapController.dispose();

    super.dispose();
  }

  List<MapPoint> get _filteredPoints {
    // Si Home y Maps reciben resultados ligeramente distintos, conservamos
    // el marcador exacto que Home abrió, sin cambiar el caché ni pedir datos.
    final highlighted = widget.highlightedPoint;
    final points =
        highlighted != null &&
            widget.highlightedPointId == highlighted.id &&
            !_realPoints.any((point) => point.id == highlighted.id)
        ? [..._realPoints, highlighted]
        : _realPoints;
    if (_selectedFilter == null) return points;
    return points.where((point) => point.type == _selectedFilter).toList();
  }

  osm.LatLng _toOsmPosition(MapPoint point) {
    return osm.LatLng(point.position.latitude, point.position.longitude);
  }

  void _selectFilter(MapPointType? type) {
    setState(() {
      _selectedFilter = type;
      _selectedPoint = null;
    });
  }

  void _focusPoint(MapPoint point) {
    _moveCamera(_toOsmPosition(point), 16);
  }

  Future<void> _loadNearbyPlaces({bool forceRefresh = false}) async {
    if (_placesLoading) return;

    final center = _userPosition ?? _initialCenter;
    final now = DateTime.now();

    const distance = osm.Distance();

    _placesCache.removeWhere(
      (entry) => now.difference(entry.timestamp) >= _cacheDuration,
    );

    if (!forceRefresh) {
      int? cachedIndex;
      var closestMeters = double.infinity;

      for (var i = 0; i < _placesCache.length; i++) {
        final entry = _placesCache[i];

        final meters = distance.as(osm.LengthUnit.Meter, center, entry.center);

        if (meters < _cacheDistanceMeters && meters < closestMeters) {
          closestMeters = meters;
          cachedIndex = i;
        }
      }

      if (cachedIndex != null) {
        final cached = _placesCache.removeAt(cachedIndex);

        // Conservar las zonas utilizadas recientemente al final.
        _placesCache.add(cached);

        debugPrint(
          '[GEOAPIFY CACHE] Resultados reutilizados. '
          'Lugares: ${cached.points.length}',
        );

        setState(() {
          _realPoints = cached.points;
          _hasLoadedPlaces = true;
          _selectedPoint = null;
          _placesError = null;
        });
        _focusHighlightedPoint();

        return;
      }
    }

    setState(() {
      _placesLoading = true;
      _placesError = null;
    });

    try {
      final mappedPoints = await _geoapifyService.findNearby(
        latitude: center.latitude,
        longitude: center.longitude,
        radiusMeters: _searchRadiusMeters,
      );

      if (!mounted) return;

      final completedAt = DateTime.now();

      _placesCache.removeWhere((entry) {
        final meters = distance.as(osm.LengthUnit.Meter, center, entry.center);

        return meters < _cacheDistanceMeters ||
            completedAt.difference(entry.timestamp) >= _cacheDuration;
      });

      _placesCache.add((
        center: center,
        timestamp: completedAt,
        points: List<MapPoint>.unmodifiable(mappedPoints),
      ));

      while (_placesCache.length > _maxCachedZones) {
        _placesCache.removeAt(0);
      }

      debugPrint(
        '[GEOAPIFY CACHE] Nueva zona almacenada. '
        'Zonas: ${_placesCache.length}',
      );

      setState(() {
        _realPoints = mappedPoints;
        _hasLoadedPlaces = true;
        _selectedPoint = null;
        _placesError = null;
      });
      _focusHighlightedPoint();
    } on GeoapifyException catch (error) {
      if (!mounted) return;

      setState(() {
        _placesError = error.message;
      });
    } catch (error) {
      debugPrint('[MAPS] Error consultando lugares: $error');

      if (!mounted) return;

      setState(() {
        _placesError = 'No fue posible cargar los lugares cercanos.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _placesLoading = false;
        });
      }
    }
  }

  Future<void> _refreshNearbyPlaces() async {
    await _loadNearbyPlaces(forceRefresh: true);
  }

  Future<void> _loadUserLocation({required bool centerMap}) async {
    if (_locationLoading) return;

    setState(() {
      _locationLoading = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        _showLocationMessage('Activa el GPS para ver tu ubicación.');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        _showLocationMessage(
          'Puedes explorar el mapa sin compartir tu ubicación.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationMessage(
          'Habilita el permiso de ubicación desde '
          'los ajustes de Android.',
        );
        return;
      }

      _locationAllowed = true;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      _updateUserPosition(position, centerMap: centerMap);
    } on TimeoutException {
      _showLocationMessage('No pudimos obtener tu ubicación a tiempo.');
    } catch (error) {
      debugPrint('[MAPS] Error obteniendo GPS: $error');

      _showLocationMessage('No fue posible obtener tu ubicación.');
    } finally {
      if (mounted) {
        setState(() {
          _locationLoading = false;
        });

        if (_locationAllowed) {
          _startLocationUpdates();
        }
      }
    }
  }

  void _startLocationUpdates() {
    if (!mounted || !_locationAllowed) return;
    if (_positionSubscription != null) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (position) {
            if (!mounted) return;

            _updateUserPosition(position, centerMap: false);
          },
          onError: (Object error) {
            debugPrint('[MAPS] Error actualizando GPS: $error');

            _stopLocationUpdates();
          },
        );
  }

  void _updateUserPosition(Position position, {required bool centerMap}) {
    final coordinates = osm.LatLng(position.latitude, position.longitude);

    setState(() {
      _userPosition = coordinates;
    });

    if (centerMap ||
        (!_hasCenteredOnUser && widget.highlightedPointId == null)) {
      _hasCenteredOnUser = true;

      _moveCamera(coordinates, _userZoom);
    }
  }

  Future<void> _recenterOnUser() async {
    if (_locationLoading) return;

    if (_userPosition != null) {
      _moveCamera(_userPosition!, _userZoom);

      setState(() {
        _selectedPoint = null;
      });
    }

    await _loadUserLocation(centerMap: true);
  }

  void _moveCamera(osm.LatLng position, double zoom) {
    if (!_mapReady) {
      _pendingCameraPosition = position;
      return;
    }

    _mapController.move(position, zoom);
  }

  void _changeZoom(double delta) {
    if (!_mapReady) return;

    final camera = _mapController.camera;
    final newZoom = (camera.zoom + delta).clamp(3.0, 19.0).toDouble();

    if (newZoom == camera.zoom) return;

    _mapController.move(camera.center, newZoom);
  }

  void _showLocationMessage(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  List<Marker> get _markers {
    return _filteredPoints.map((point) {
      final isHighlighted = point.id == widget.highlightedPointId;
      return Marker(
        key: ValueKey(point.id),
        point: _toOsmPosition(point),
        width: isHighlighted ? 64 : 48,
        height: isHighlighted ? 64 : 48,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              _selectedPoint = point;
            });
          },
          child: Center(
            child: Container(
              width: isHighlighted ? 54 : 42,
              height: isHighlighted ? 54 : 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHighlighted
                      ? const Color(0xFFAF283D)
                      : AppColors.goldOf(context),
                  width: isHighlighted ? 3 : 2,
                ),
                boxShadow: isHighlighted
                    ? const [
                        BoxShadow(
                          color: Color(0x99B52A43),
                          blurRadius: 24,
                          spreadRadius: 7,
                        ),
                        BoxShadow(
                          color: Color(0x55E04E68),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                MapPointPresentation.iconForType(point.type),
                size: 23,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Marker? _buildUserMarker() {
    final position = _userPosition;

    if (position == null) return null;

    return Marker(
      key: const ValueKey('user_location'),
      point: position,
      width: 68,
      height: 68,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.goldOf(context).withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.goldOf(context),
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 7,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.textPrimaryOf(context),
                  size: 23,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesStatus() {
    final String message;
    final IconData icon;
    final bool showRetry;

    if (_placesLoading) {
      message = 'Buscando lugares cercanos...';
      icon = Icons.travel_explore;
      showRetry = false;
    } else if (_placesError != null) {
      message = _placesError!;
      icon = Icons.warning_amber_rounded;
      showRetry = true;
    } else if (!_hasLoadedPlaces) {
      message = 'Preparando búsqueda de lugares...';
      icon = Icons.hourglass_empty;
      showRetry = false;
    } else if (_filteredPoints.isEmpty) {
      message = 'No se encontraron lugares para este filtro.';
      icon = Icons.search_off;
      showRetry = false;
    } else {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: AppColors.surfaceOf(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_placesLoading)
              const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 18, color: AppColors.goldOf(context)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
            if (showRetry) ...[
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Reintentar búsqueda',
                onPressed: _refreshNearbyPlaces,
                icon: Icon(Icons.refresh, color: AppColors.goldOf(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            MapsHeader(currentName: widget.currentName),
            MapsFilters(
              scrollController: _filterScrollController,
              selectedFilter: _selectedFilter,
              onFilterTap: _selectFilter,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 90),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.goldOf(context)
                                .withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _buildMap(isDark),
                          ),
                        ),
                      ),
                    ),

                    // Estado de la busqueda.
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: _buildPlacesStatus(),
                    ),

                    // Zoom manual: controles situados dentro del mapa.
                    Positioned(
                      top: 85,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.goldOf(context)
                                .withValues(alpha: 0.65),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Acercar mapa',
                              onPressed: () => _changeZoom(1),
                              icon: Icon(
                                Icons.add,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 1,
                              color: AppColors.goldOf(context)
                                  .withValues(alpha: 0.35),
                            ),
                            IconButton(
                              tooltip: 'Alejar mapa',
                              onPressed: () => _changeZoom(-1),
                              icon: Icon(
                                Icons.remove,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actualizar los lugares cercanos.
                    Positioned(
                      right: 16,
                      bottom: _selectedPoint == null ? 98 : 313,
                      child: FloatingActionButton.small(
                        heroTag: 'refresh_nearby_places',
                        tooltip: 'Actualizar lugares cercanos',
                        onPressed: _placesLoading || _locationLoading
                            ? null
                            : _refreshNearbyPlaces,
                        backgroundColor: AppColors.surfaceOf(context),
                        foregroundColor: AppColors.textPrimaryOf(context),
                        child: const Icon(Icons.refresh),
                      ),
                    ),

                    // Centrar el mapa en el lector.
                    Positioned(
                      right: 16,
                      bottom: _selectedPoint == null ? 40 : 255,
                      child: FloatingActionButton.small(
                        heroTag: 'user_location_button',
                        tooltip: 'Mi ubicación',
                        onPressed: _locationLoading ? null : _recenterOnUser,
                        backgroundColor: AppColors.surfaceOf(context),
                        foregroundColor: AppColors.textPrimaryOf(context),
                        child: _locationLoading
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                      ),
                    ),

                    // Tarjeta del lugar seleccionado.
                    if (_selectedPoint != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: MapPointCard(
                          point: _selectedPoint!,
                          onClose: () {
                            setState(() {
                              _selectedPoint = null;
                            });
                          },
                          onFocus: () {
                            final point = _selectedPoint;

                            if (point != null) {
                              _focusPoint(point);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cartoTileUrl(bool isDark) {
    final style = isDark ? 'dark_all' : 'light_all';

    return 'https://basemaps.cartocdn.com/'
        'rastertiles/$style/{z}/{x}/{y}.png'
        '?key=${Uri.encodeQueryComponent(_cartoApiKey)}';
  }

  Widget _buildMap(bool isDark) {
    final useCarto = _useCarto;
    final userMarker = _buildUserMarker();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: _initialZoom,
        minZoom: 3,
        maxZoom: 19,
        onMapReady: () {
          _mapReady = true;

          final pending = _pendingCameraPosition;

          if (pending != null) {
            _pendingCameraPosition = null;

            _mapController.move(pending, _userZoom);
          }
          _focusHighlightedPoint();
        },
        onTap: (_, _) {
          if (_selectedPoint != null) {
            setState(() {
              _selectedPoint = null;
            });
          }
        },
      ),
      children: [
        TileLayer(
          key: ValueKey(
            useCarto ? (isDark ? 'carto_dark' : 'carto_light') : 'osm',
          ),
          urlTemplate: useCarto ? _cartoTileUrl(isDark) : _osmTileUrl,
          userAgentPackageName: _androidPackage,
          maxNativeZoom: 19,
          tileProvider: NetworkTileProvider(
            headers: useCarto
                ? {
                    'X-Android-Package': _androidPackage,
                    'X-Android-Cert': _debugSha1,
                  }
                : {},
          ),
        ),

        MarkerLayer(markers: _markers),

        if (userMarker != null) MarkerLayer(markers: [userMarker]),

        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Material(
              color: AppColors.surfaceOf(context).withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    InkWell(
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                      child: const Text(
                        '© OpenStreetMap',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                    if (useCarto)
                      InkWell(
                        onTap: () => launchUrl(
                          Uri.parse('https://carto.com/attribution/'),
                        ),
                        child: const Text(
                          '© CARTO',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
