import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../models/photo_model.dart';
import 'photo_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  
  List<Photo> _photos = [];
  Photo? _selectedPhoto;
  LatLng? _currentLocation;
  bool _isLoading = true;
  bool _showClusters = true;
  int _mapType = 0; // 0: Street, 1: Satellite
  StreamSubscription<void>? _dbSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Listen for database changes
    _dbSubscription = _databaseService.onChange.listen((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load photos from database first (fast operation)
    _photos = await _databaseService.getAllPhotos();
    
    // Set an initial location immediately so map can render
    if (_photos.isNotEmpty) {
      // Center on first photo initially
      _currentLocation = LatLng(_photos.first.latitude, _photos.first.longitude);
    } else {
      // Default to a central location (will be updated when GPS is acquired)
      _currentLocation = const LatLng(20.5937, 78.9629); // India center as default
    }
    
    // Show the map immediately with available data
    if (mounted) {
      setState(() => _isLoading = false);
    }
    
    // Now get accurate current location in background
    _updateCurrentLocation();
  }
  
  Future<void> _updateCurrentLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      debugPrint('Map location updated: ${position.latitude}, ${position.longitude}');
    }
  }

  void _centerOnCurrentLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    }
  }

  void _selectPhoto(Photo photo) {
    setState(() {
      _selectedPhoto = photo;
    });
    _mapController.move(
      LatLng(photo.latitude, photo.longitude),
      15.0,
    );
  }

  void _openPhotoDetail(Photo photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoDetailScreen(
          imagePath: photo.imagePath,
          photo: photo,
        ),
      ),
    ).then((_) => _loadData());
  }

  List<Marker> _buildMarkers() {
    return _photos.map((photo) {
      final isSelected = _selectedPhoto?.id == photo.id;
      return Marker(
        point: LatLng(photo.latitude, photo.longitude),
        width: 60,
        height: 70, // Extra height for the "pointer"
        child: GestureDetector(
          onTap: () => _selectPhoto(photo),
          child: Column(
            children: [
              // Photo Frame
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: File(photo.imagePath).existsSync()
                      ? Image.file(
                          File(photo.imagePath),
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        )
                      : Container(
                          color: AppColors.cardDark,
                          child: const Icon(Icons.photo, color: Colors.white24, size: 20),
                        ),
                ),
              ),
              // Pointer Triangle
              CustomPaint(
                size: const Size(12, 8),
                painter: _PinPointerPainter(color: isSelected ? AppColors.primary : Colors.white),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildClusterMarker(BuildContext context, List<Marker> markers) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          markers.length.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Map
          if (!_isLoading && _currentLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 12.0,
                maxZoom: 18.0,
                minZoom: 3.0,
                onTap: (_, __) {
                  setState(() => _selectedPhoto = null);
                },
              ),
              children: [
                // Map tiles
                TileLayer(
                  urlTemplate: _mapType == 0 
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.geocam.app',
                  maxZoom: 20,
                  retinaMode: true,
                ),
                // Photo markers with clustering
                if (_showClusters && _photos.isNotEmpty)
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 80,
                      size: const Size(50, 50),
                      markers: _buildMarkers(),
                      builder: _buildClusterMarker,
                    ),
                  ),
                // Current location marker
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          // Top toolbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'GEOCAM PRO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'Photo Map',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Toggle clustering
                        IconButton(
                          icon: Icon(
                            _showClusters ? Icons.group_work : Icons.scatter_plot,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() => _showClusters = !_showClusters);
                          },
                          tooltip: _showClusters ? 'Show individual' : 'Show clusters',
                        ),
                        // Photo count
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo, color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${_photos.length}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Map Style Toggle
          Positioned(
            right: 16,
            bottom: _selectedPhoto != null ? 220 : 120,
            child: FloatingActionButton(
              heroTag: 'mapStyleFab',
              mini: true,
              backgroundColor: AppColors.cardDark,
              onPressed: () => setState(() => _mapType = _mapType == 0 ? 1 : 0),
              child: Icon(
                _mapType == 0 ? Icons.satellite_alt : Icons.map_outlined, 
                color: AppColors.primary
              ),
            ),
          ),
          // Center on location button
          Positioned(
            right: 16,
            bottom: _selectedPhoto != null ? 170 : 72,
            child: FloatingActionButton(
              heroTag: 'centerLocationFab',
              mini: true,
              backgroundColor: AppColors.cardDark,
              onPressed: _centerOnCurrentLocation,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
          // Refresh button
          Positioned(
            right: 16,
            bottom: _selectedPhoto != null ? 120 : 24,
            child: FloatingActionButton(
              heroTag: 'refreshMapFab',
              mini: true,
              backgroundColor: AppColors.cardDark,
              onPressed: _loadData,
              child: const Icon(Icons.refresh, color: Colors.white70),
            ),
          ),
          // Selected photo card (Glassmorphic)
          if (_selectedPhoto != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: _buildPhotoCard(_selectedPhoto!),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopup(Photo photo) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: File(photo.imagePath).existsSync()
                ? Image.file(
                    File(photo.imagePath),
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 100,
                    color: AppColors.cardBorder,
                    child: const Icon(Icons.image, color: AppColors.textMuted),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            photo.address ?? 'Unknown location',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _openPhotoDetail(photo),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(Photo photo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Photo thumbnail with subtle shadow
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: File(photo.imagePath).existsSync()
                      ? Image.file(
                          File(photo.imagePath),
                          width: 85,
                          height: 85,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 85,
                          height: 85,
                          color: Colors.white10,
                          child: const Icon(Icons.image, color: Colors.white24),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Photo info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      photo.address ?? 'Unknown location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      photo.coordinatesDD,
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white38, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d • h:mm a').format(photo.capturedAt),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _openPhotoDetail(photo),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'OPEN',
                              style: TextStyle(
                                color: Color(0xFF102219),
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the pin pointer triangle
class _PinPointerPainter extends CustomPainter {
  final Color color;
  _PinPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
