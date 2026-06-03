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
  final bool isLandscape;

  /// When true an amber "MANUAL" badge is shown instead of the verified icon.
  final bool isManualLocation;

  /// When true an amber "CUSTOM TIME" badge is shown next to the date/time row.
  final bool isManualDateTime;



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
    this.isLandscape = false,
    this.isManualLocation = false,
    this.isManualDateTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return _buildPortraitHud();
  }

  // ─── PORTRAIT HUD (full card with tall mini map on the right) ───────────────
  Widget _buildPortraitHud() {
    final displayDate = dateTime ?? DateTime.now();


    final timeStr = DateFormat('hh:mm a').format(displayDate);
    final dateStr = DateFormat('EEEE, dd/MM/yyyy').format(displayDate);


    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: isLandscape ? 1 : 3),
      padding: EdgeInsets.all(isLandscape ? 6 : 8),
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
          // 1. Text Data Column (left)
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
                        style: TextStyle(
                          fontSize: isLandscape ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isManualLocation)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                              width: 0.8),
                        ),
                        child: const Text(
                          'MANUAL',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      )
                    else
                      Icon(Icons.verified,
                          color: AppColors.primary,
                          size: isLandscape ? 12 : 14),
                  ],
                ),
                const SizedBox(height: 2),

                // Detailed Address
                if (showAddress)
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: isLandscape ? 8 : 9,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),

                // Lat/Long Row
                if (showCoordinates)
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.primary, size: 10),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          coordinates,
                          style: TextStyle(
                            fontSize: isLandscape ? 8 : 9,
                            fontFamily: 'monospace',
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 3),

                // Date & Time Row
                if (showDateTime)
                  Row(
                    children: [
                      Icon(
                        isManualDateTime
                            ? Icons.edit_calendar
                            : Icons.calendar_today,
                        color: isManualDateTime
                            ? const Color(0xFFF59E0B)
                            : Colors.white38,
                        size: 9,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$dateStr \u2022 $timeStr',
                          style: TextStyle(
                            fontSize: isLandscape ? 8 : 9,
                            color: isManualDateTime
                                ? const Color(0xFFF59E0B)
                                : Colors.white60,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // CUSTOM TIME badge
                      if (isManualDateTime)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'CUSTOM',
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 5),

                // Bottom Stats Bar
                Row(
                  children: [
                    _HudStat(icon: Icons.landscape_outlined, value: altitude),
                    const SizedBox(width: 8),
                    _HudStat(icon: Icons.wb_sunny_outlined, value: temperature),
                    const Spacer(),
                    Flexible(child: _buildGpsSignalIndicator()),
                  ],
                ),

                const SizedBox(height: 5),
                const Text(
                  '📍 GEOCAM PRO',
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

          const SizedBox(width: 10),

          // 2. Mini Map Preview (right)
          GestureDetector(
            onTap: onMapTap,
            child: Container(
              width: isLandscape ? 56 : 70,
              height: isLandscape ? 56 : 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildMapWidget(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHARED HELPERS ──────────────────────────────────────────────────────────

  Widget _buildMapWidget() {
    if (latitude != null && longitude != null) {
      return IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(latitude!, longitude!),
            initialZoom: 17.0,
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
                          angle: heading! * 3.14159 / 180,
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
      );
    }
    return Container(
      color: AppColors.cardDark,
      child: const Center(
        child: Icon(Icons.satellite_alt, color: Colors.white24, size: 20),
      ),
    );
  }

  Widget _buildGpsSignalIndicator() {
    Color signalColor;
    switch (gpsSignal) {
      case 'HIGH':      signalColor = const Color(0xFF10B981); break;
      case 'GOOD':      signalColor = const Color(0xFF22C55E); break;
      case 'MEDIUM':    signalColor = const Color(0xFFF59E0B); break;
      case 'ACQUIRING': signalColor = const Color(0xFF6B7280); break;
      case 'MANUAL':    signalColor = const Color(0xFFF59E0B); break; // amber
      default:          signalColor = const Color(0xFFEF4444);
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

  String _getShortAddress(String fullAddress) {
    final parts = fullAddress.split(',');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2].trim()}, ${parts[parts.length - 1].trim()}';
    }
    return fullAddress;
  }
}

// ─── PORTRAIT sub-widget ─────────────────────────────────────────────────────
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
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


