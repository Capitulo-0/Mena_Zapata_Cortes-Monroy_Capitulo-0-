import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MapPointType { library, cafe, bookFair, literaryEvent, culturalCenter }

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

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;

  MapPointType? _selectedFilter;
  MapPoint? _selectedPoint;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-33.4489, -70.6693),
    zoom: 12.5,
  );

  final List<MapPoint> _points = const [
    MapPoint(
      id: 'library_1',
      name: 'Biblioteca - Punto demo',
      type: MapPointType.library,
      position: LatLng(-33.4398, -70.6796),
      address: 'Santiago, Región Metropolitana',
      description: 'Espacio de lectura y consulta de libros. Este punto es temporal mientras conectamos los datos reales.',
      schedule: 'Lunes a sábado',
      isFree: true,
    ),
    MapPoint(
      id: 'cafe_1',
      name: 'Café lector - Punto demo',
      type: MapPointType.cafe,
      position: LatLng(-33.4437, -70.6536),
      address: 'Santiago Centro',
      description: 'Cafetería de demostración para representar espacios cómodos donde leer y compartir.',
      schedule: '09:00 - 20:00',
      isFree: false,
    ),
    MapPoint(
      id: 'fair_1',
      name: 'Feria del Libro - Evento demo',
      type: MapPointType.bookFair,
      position: LatLng(-33.4372, -70.6383),
      address: 'Santiago, Región Metropolitana',
      description: 'Ejemplo de feria del libro. Más adelante estos eventos serán obtenidos desde el backend.',
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
      description: 'Actividad literaria de demostración para visualizar encuentros y eventos relacionados con la lectura.',
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
      description: 'Espacio cultural que puede albergar talleres, clubes de lectura, presentaciones y actividades literarias.',
      schedule: '10:00 - 19:00',
      isFree: true,
    ),
  ];

  List<MapPoint> get _filteredPoints {
    if (_selectedFilter == null) {
      return _points;
    }

    return _points.where((point) => point.type == _selectedFilter).toList();
  }

  Set<Marker> get _markers {
    return _filteredPoints.map((point) {
      return Marker(
        markerId: MarkerId(point.id),
        position: point.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(point.type)),
        infoWindow: InfoWindow(
          title: point.name,
          snippet: _labelForType(point.type),
        ),
        onTap: () {
          setState(() {
            _selectedPoint = point;
          });
        },
      );
    }).toSet();
  }

  double _markerHue(MapPointType type) {
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

  IconData _iconForType(MapPointType type) {
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

  String _labelForType(MapPointType type) {
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

  Future<void> _focusPoint(MapPoint point) async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point.position, zoom: 16),
      ),
    );
  }

  Future<void> _resetCamera() async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_initialCameraPosition),
    );

    setState(() {
      _selectedPoint = null;
    });
  }

  void _selectFilter(MapPointType? type) {
    setState(() {
      _selectedFilter = type;
      _selectedPoint = null;
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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
            _buildHeader(context),
            _buildFilters(context),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMap(context)),

                  Positioned(
                    right: 16,
                    bottom: _selectedPoint == null ? 20 : 255,
                    child: FloatingActionButton.small(
                      heroTag: 'reset_map_camera',
                      onPressed: _resetCamera,
                      backgroundColor: isDark
                          ? const Color(0xFF2D1C16)
                          : Colors.white,
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF381D14),
                      child: const Icon(Icons.center_focus_strong),
                    ),
                  ),

                  if (_selectedPoint != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _buildPointCard(context, _selectedPoint!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CABECERA
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PUNTOS LECTORES',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Bibliotecas, cafeterías, ferias y eventos literarios cerca de ti.',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FILTROS
  // ─────────────────────────────────────────────────────────────

  Widget _buildFilters(BuildContext context) {
    return SizedBox(
      height: 55,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 7),
        children: [
          _buildFilterChip(
            context: context,
            label: 'Todos',
            icon: Icons.public,
            selected: _selectedFilter == null,
            onTap: () => _selectFilter(null),
          ),
          _buildFilterChip(
            context: context,
            label: 'Bibliotecas',
            icon: Icons.local_library_outlined,
            selected: _selectedFilter == MapPointType.library,
            onTap: () => _selectFilter(MapPointType.library),
          ),
          _buildFilterChip(
            context: context,
            label: 'Cafés',
            icon: Icons.local_cafe_outlined,
            selected: _selectedFilter == MapPointType.cafe,
            onTap: () => _selectFilter(MapPointType.cafe),
          ),
          _buildFilterChip(
            context: context,
            label: 'Ferias',
            icon: Icons.menu_book_outlined,
            selected: _selectedFilter == MapPointType.bookFair,
            onTap: () => _selectFilter(MapPointType.bookFair),
          ),
          _buildFilterChip(
            context: context,
            label: 'Eventos',
            icon: Icons.auto_stories_outlined,
            selected: _selectedFilter == MapPointType.literaryEvent,
            onTap: () => _selectFilter(MapPointType.literaryEvent),
          ),
          _buildFilterChip(
            context: context,
            label: 'Cultura',
            icon: Icons.account_balance_outlined,
            selected: _selectedFilter == MapPointType.culturalCenter,
            onTap: () => _selectFilter(MapPointType.culturalCenter),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        avatar: Icon(
          icon,
          size: 17,
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary,
        ),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.35),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MAPA
  // ─────────────────────────────────────────────────────────────

  Widget _buildMap(BuildContext context) {
    if (kIsWeb) {
      return _buildWebDevelopmentView(context);
    }

    return GoogleMap(
      initialCameraPosition: _initialCameraPosition,
      markers: _markers,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      buildingsEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      onTap: (_) {
        setState(() {
          _selectedPoint = null;
        });
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // VISTA PARA CHROME
  // ─────────────────────────────────────────────────────────────

  Widget _buildWebDevelopmentView(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.map_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Mapa disponible en Android e IOS',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Chrome se utiliza para probar rápidamente la interfaz. '
                'Abre Capítulo 0 en el emulador Android para visualizar Google Maps.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredPoints.length} puntos preparados',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TARJETA DEL PUNTO SELECCIONADO
  // ─────────────────────────────────────────────────────────────

  Widget _buildPointCard(BuildContext context, MapPoint point) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _iconForType(point.type),
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.name,
                        style: GoogleFonts.merriweather(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _labelForType(point.type),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _selectedPoint = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildInfoRow(context, Icons.location_on_outlined, point.address),

            if (point.date != null)
              _buildInfoRow(
                context,
                Icons.calendar_month_outlined,
                point.date!,
              ),

            if (point.schedule != null)
              _buildInfoRow(context, Icons.schedule_outlined, point.schedule!),

            _buildInfoRow(
              context,
              point.isFree
                  ? Icons.confirmation_number_outlined
                  : Icons.payments_outlined,
              point.isFree
                  ? 'Entrada gratuita'
                  : 'Puede requerir consumo o entrada',
            ),

            const SizedBox(height: 7),

            Text(
              point.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                height: 1.45,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 13),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _focusPoint(point),
                icon: const Icon(Icons.near_me_outlined, size: 18),
                label: Text(
                  'Ver en el mapa',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
