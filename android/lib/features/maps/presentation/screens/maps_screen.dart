import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../clubs/models/reading_club.dart';

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
  const MapsScreen({
    super.key,
    required this.clubs,
    required this.joinedClubIds,
    required this.currentUsername,
    required this.currentName,
  });

  final List<ReadingClub> clubs;
  final Set<int> joinedClubIds;
  final String currentUsername;
  final String currentName;

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;

  MapPointType? _selectedFilter;
  MapPoint? _selectedPoint;
  bool _showJoinedClubs = false;

  final ScrollController _filterScrollController = ScrollController();

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

  List<ReadingClub> get _joinedClubs => widget.clubs
      .where((club) => widget.joinedClubIds.contains(club.id))
      .toList();

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
      _showJoinedClubs = false;
      _selectedPoint = null;
    });
  }

  void _selectJoinedClubs() {
    setState(() {
      _selectedFilter = null;
      _showJoinedClubs = true;
      _selectedPoint = null;
    });
  }

  @override
  void dispose() {
    _filterScrollController.dispose();
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
                          ? AppColors.darkSurface
                          : AppColors.surface,
                      foregroundColor: AppColors.deepOf(context),
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
            'Bibliotecas, cafeterías, ferias y eventos literarios cerca de ti,',
            style: GoogleFonts.merriweather(
              fontSize: 8,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.78,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${widget.currentName.trim().toUpperCase()} ✦',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cinzel(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: theme.colorScheme.onSurface,
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
      child: SingleChildScrollView(
        controller: _filterScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 5, 14, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_joinedClubs.isNotEmpty) ...[
              _buildFilterChip(
                context: context,
                label: 'Mis clubes',
                icon: Icons.groups_2_outlined,
                selected: _showJoinedClubs,
                onTap: _selectJoinedClubs,
              ),
              const SizedBox(width: 6),
            ],
            _buildFilterChip(
              context: context,
              label: 'Todos',
              icon: Icons.public,
              selected: !_showJoinedClubs && _selectedFilter == null,
              onTap: () => _selectFilter(null),
            ),
            const SizedBox(width: 6),
            _buildFilterChip(
              context: context,
              label: 'Bibliotecas',
              icon: Icons.local_library_outlined,
              selected: !_showJoinedClubs && _selectedFilter == MapPointType.library,
              onTap: () => _selectFilter(MapPointType.library),
            ),
            const SizedBox(width: 6),
            _buildFilterChip(
              context: context,
              label: 'Cafés',
              icon: Icons.local_cafe_outlined,
              selected: !_showJoinedClubs && _selectedFilter == MapPointType.cafe,
              onTap: () => _selectFilter(MapPointType.cafe),
            ),
            const SizedBox(width: 6),
            _buildFilterChip(
              context: context,
              label: 'Ferias',
              icon: Icons.menu_book_outlined,
              selected: !_showJoinedClubs && _selectedFilter == MapPointType.bookFair,
              onTap: () => _selectFilter(MapPointType.bookFair),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context: context,
              label: 'Eventos',
              icon: Icons.auto_stories_outlined,
              selected: !_showJoinedClubs && _selectedFilter == MapPointType.literaryEvent,
              onTap: () => _selectFilter(MapPointType.literaryEvent),
            ),
            const SizedBox(width: 6),
            _buildFilterChip(
              context: context,
              label: 'Cultura',
              icon: Icons.account_balance_outlined,
              selected: !_showJoinedClubs && _selectedFilter == MapPointType.culturalCenter,
              onTap: () => _selectFilter(MapPointType.culturalCenter),
            ),
          ],
        ),
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
    final chip = ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      avatar: Icon(
        icon,
        size: 16,
        color: selected
            ? AppColors.deepOf(context)
            : AppColors.goldOf(context),
      ),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: selected
              ? AppColors.deepOf(context)
              : AppColors.textPrimaryOf(context),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      selectedColor: AppColors.goldOf(context),
      backgroundColor: AppColors.surfaceOf(context),
      side: BorderSide(
        color: selected
            ? AppColors.goldOf(context)
            : AppColors.goldOf(context).withValues(alpha: 0.28),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );

    return chip;
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
    final gold = AppColors.goldOf(context);
    final deep = AppColors.deepOf(context);

    final resultText = _showJoinedClubs
        ? '${_joinedClubs.length} ${_joinedClubs.length == 1 ? 'club preparado' : 'clubes preparados'}'
        : _selectedFilter == null
            ? '${_filteredPoints.length + _joinedClubs.length} '
                '${(_filteredPoints.length + _joinedClubs.length) == 1 ? 'punto encontrado' : 'puntos encontrados'}'
            : '${_filteredPoints.length} '
                '${_filteredPoints.length == 1 ? 'punto encontrado' : 'puntos encontrados'}';

    final messageCard = Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 390),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gold.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gold.withValues(alpha: 0.24),
              ),
            ),
            child: Icon(
              Icons.map_outlined,
              size: 32,
              color: gold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'MAPA LISTO PARA TU DISPOSITIVO',
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.25,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para visualizar el mapa y utilizar sus diferentes funciones, '
            'deberás permitir el acceso a tu ubicación en Android o iOS.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: () => _showLocationPermissionPreview(context),
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: deep,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(
                Icons.map_rounded,
                size: 17,
              ),
              label: Text(
                'Abrir mapa',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: gold.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: gold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resultText,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Disponibles para visualizar en el mapa',
                        style: GoogleFonts.inter(
                          fontSize: 7.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.phone_android_rounded,
                  size: 18,
                  color: deep.withValues(alpha: 0.78),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceContainerLow,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Align(
                alignment: const Alignment(0, -0.18),
                child: messageCard,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLocationPermissionPreview(
    BuildContext context,
  ) async {
    final theme = Theme.of(context);
    final gold = AppColors.goldOf(context);
    final deep = AppColors.deepOf(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gold.withValues(alpha: 0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: gold.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: gold,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  'PERMITIR UBICACIÓN',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Capítulo 0 necesita acceso a tu ubicación para mostrar puntos lectores cercanos y centrar el mapa en tu zona.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(
                              color: gold.withValues(alpha: 0.38),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Ahora no',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: deep,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Permitir',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
            color: AppColors.goldOf(context).withValues(alpha: 0.28),
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
                    color: AppColors.goldOf(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _iconForType(point.type),
                    color: AppColors.goldOf(context),
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
                          color: AppColors.goldOf(context),
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
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepOf(context),
                  foregroundColor: AppColors.goldOf(context),
                ),
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
          Icon(icon, size: 16, color: AppColors.goldOf(context)),
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
