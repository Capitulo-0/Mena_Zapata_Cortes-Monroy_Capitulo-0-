import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../clubs/models/reading_club.dart';
import '../../data/maps_demo_data.dart';
import '../../models/map_point.dart';
import '../../models/map_point_type.dart';
import '../dialogs/location_permission_preview_dialog.dart';
import '../widgets/map_point_card.dart';
import '../widgets/map_point_presentation.dart';
import '../widgets/maps_filters.dart';
import '../widgets/maps_header.dart';
import '../widgets/maps_web_development_view.dart';

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

  List<MapPoint> get _filteredPoints {
    if (_selectedFilter == null) {
      return MapsDemoData.points;
    }

    return MapsDemoData.points
        .where((point) => point.type == _selectedFilter)
        .toList();
  }

  List<ReadingClub> get _joinedClubs => widget.clubs
      .where((club) => widget.joinedClubIds.contains(club.id))
      .toList();

  Set<Marker> get _markers {
    return _filteredPoints.map((point) {
      return Marker(
        markerId: MarkerId(point.id),
        position: point.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          MapPointPresentation.markerHue(point.type),
        ),
        infoWindow: InfoWindow(
          title: point.name,
          snippet: MapPointPresentation.labelForType(point.type),
        ),
        onTap: () {
          setState(() {
            _selectedPoint = point;
          });
        },
      );
    }).toSet();
  }

  Future<void> _focusPoint(MapPoint point) async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: point.position,
          zoom: 16,
        ),
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
            MapsHeader(
              currentName: widget.currentName,
            ),
            MapsFilters(
              scrollController: _filterScrollController,
              hasJoinedClubs: _joinedClubs.isNotEmpty,
              showJoinedClubs: _showJoinedClubs,
              selectedFilter: _selectedFilter,
              onJoinedClubsTap: _selectJoinedClubs,
              onFilterTap: _selectFilter,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildMap(),
                  ),
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
                      child: MapPointCard(
                        point: _selectedPoint!,
                        onClose: () {
                          setState(() {
                            _selectedPoint = null;
                          });
                        },
                        onFocus: () => _focusPoint(_selectedPoint!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (kIsWeb) {
      return MapsWebDevelopmentView(
        resultText: _resultText,
        onOpenMap: () => showLocationPermissionPreviewDialog(
          context: context,
        ),
      );
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

  String get _resultText {
    if (_showJoinedClubs) {
      return '${_joinedClubs.length} '
          '${_joinedClubs.length == 1 ? 'club preparado' : 'clubes preparados'}';
    }

    if (_selectedFilter == null) {
      final total = _filteredPoints.length + _joinedClubs.length;
      return '$total ${total == 1 ? 'punto encontrado' : 'puntos encontrados'}';
    }

    return '${_filteredPoints.length} '
        '${_filteredPoints.length == 1 ? 'punto encontrado' : 'puntos encontrados'}';
  }
}
