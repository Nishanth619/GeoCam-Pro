import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class GpsHudCard extends StatelessWidget {
  final String address;
  final String coordinates;
  final String altitude;
  final String temperature;
  final String gpsSignal;
  final double? latitude;
  final double? longitude;
  final double? heading;
  final DateTime? dateTime;
  final VoidCallback? onMapTap;
  
  // Template settings
  final bool showAddress;
  final bool showCoordinates;
  final bool showCompass;
  final bool showDateTime;
  final int mapType; // 0: Normal, 1: Satellite, 2: Terrain, 3: Hybrid
  final String dateFormat;

  const GpsHudCard({
    super.key,
    required this.address,
    required this.coordinates,
    required this.altitude,
    required this.temperature,
    required this.gpsSignal,
    this.latitude,
    this.longitude,
    this.heading,
    this.dateTime,
    this.onMapTap,
    this.showAddress = true,
    this.showCoordinates = true,
    this.showCompass = false,
    this.showDateTime = true,
    this.mapType = 0,
    this.dateFormat = 'DD/MM/YYYY',
  });

  @override
  Widget build(BuildContext context) {
    final displayDate = dateTime ?? DateTime.now();
    
    String formattedDate;
    try {
      if (dateFormat == 'DD/MM/YYYY') {
        formattedDate = DateFormat('EEEE, dd/MM/yyyy').format(displayDate);
      } else if (dateFormat == 'MM/DD/YYYY') {
        formattedDate = DateFormat('EEEE, MM/dd/yyyy').format(displayDate);
      } else {
        formattedDate = DateFormat('EEEE, yyyy-MM-dd').format(displayDate);
      }
    } catch (_) {
      formattedDate = DateFormat('EEEE, dd/MM/yyyy').format(displayDate);
    }
    
    final timeStr = DateFormat('hh:mm a').format(displayDate);
    final dateStr = DateFormat('EEEE, dd/MM/yyyy').format(displayDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Text Data Column (On the Left)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title / Main Location
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getShortAddress(address),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.verified, color: AppColors.primary, size: 14),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Detailed Address
                if (showAddress)
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                
                // Lat/Long Row
                Row(
                  children: [
                    const Icon(Icons.my_location, color: AppColors.primary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      coordinates,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Date & Time Row
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white38, size: 9),
                    const SizedBox(width: 4),
                    Text(
                      "$dateStr • $timeStr",
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Bottom Stats Bar
                Row(
                  children: [
                    _HudStat(icon: Icons.landscape_outlined, value: altitude),
                    const SizedBox(width: 12),
                    _HudStat(icon: Icons.wb_sunny_outlined, value: temperature),
                    const Spacer(),
                    _buildGpsSignalIndicator(),
                  ],
                ),
                
                const SizedBox(height: 8),
                const Text(
                  "📍 GEOCAM PRO",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 14),
          
          // 2. Mini Map Preview (On the Right)
          GestureDetector(
            onTap: onMapTap,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: latitude != null && longitude != null
                  ? IgnorePointer(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(latitude!, longitude!),
                          initialZoom: 17.0, // High-Precision
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: _getTileUrl(),
                            userAgentPackageName: 'com.geocam.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(latitude!, longitude!),
                                width: 22,
                                height: 22,
                                child: showCompass && heading != null
                                    ? Transform.rotate(
                                        angle: (heading! * 3.14159 / 180),
                                        child: const Icon(
                                          Icons.navigation,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.location_on,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Container(
                      color: AppColors.cardDark,
                      child: const Center(
                        child: Icon(Icons.satellite_alt, color: Colors.white24, size: 24),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTileUrl() {
    switch (mapType) {
      case 1: // Satellite (Esri)
      case 3: // Hybrid (Esri Satellite)
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 2: // Terrain (OpenTopoMap)
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case 0: // Normal (OSM)
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  String _getCardinalDirection(double heading) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    int index = ((heading + 22.5) % 360 / 45).floor();
    return directions[index];
  }

  String _getShortAddress(String fullAddress) {
    final parts = fullAddress.split(',');
    if (parts.length >= 2) {
      return "${parts[parts.length-2].trim()}, ${parts[parts.length-1].trim()}";
    }
    return fullAddress;
  }

  Widget _buildGpsSignalIndicator() {
    Color signalColor;
    switch (gpsSignal) {
      case 'HIGH': signalColor = const Color(0xFF10B981); break;
      case 'GOOD': signalColor = const Color(0xFF22C55E); break;
      case 'MEDIUM': signalColor = const Color(0xFFF59E0B); break;
      case 'ACQUIRING': signalColor = const Color(0xFF6B7280); break;
      default: signalColor = const Color(0xFFEF4444);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: signalColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: signalColor.withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          gpsSignal,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: signalColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _HudStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _HudStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
