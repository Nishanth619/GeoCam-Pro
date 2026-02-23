import 'package:flutter/material.dart';
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
    final timeStr = DateFormat('hh:mm a').format(displayDate);

    String formattedDate;
    try {
      if (dateFormat == 'DD/MM/YYYY') {
        formattedDate = DateFormat('dd/MM/yy').format(displayDate);
      } else if (dateFormat == 'MM/DD/YYYY') {
        formattedDate = DateFormat('MM/dd/yy').format(displayDate);
      } else {
        formattedDate = DateFormat('yy-MM-dd').format(displayDate);
      }
    } catch (_) {
      formattedDate = DateFormat('dd/MM/yy').format(displayDate);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // GPS signal dot
          _buildSignalDot(),
          const SizedBox(width: 8),

          // Scrollable chip row — all data in one line
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Location name
                  if (showAddress) ...[
                    _CompactChip(
                      icon: Icons.place_outlined,
                      label: _getShortAddress(address),
                      iconColor: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Coordinates
                  if (showCoordinates) ...[
                    _CompactChip(
                      icon: Icons.my_location,
                      label: coordinates,
                      iconColor: AppColors.primary,
                      mono: true,
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Altitude
                  _CompactChip(
                    icon: Icons.landscape_outlined,
                    label: altitude,
                    iconColor: Colors.white54,
                  ),
                  const SizedBox(width: 6),

                  // Temperature
                  _CompactChip(
                    icon: Icons.wb_sunny_outlined,
                    label: temperature,
                    iconColor: Colors.white54,
                  ),

                  // Date / time
                  if (showDateTime) ...[
                    const SizedBox(width: 6),
                    _CompactChip(
                      icon: Icons.schedule,
                      label: '$formattedDate  $timeStr',
                      iconColor: Colors.white38,
                    ),
                  ],

                  const SizedBox(width: 8),
                  // Brand tag
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
          ),
        ],
      ),
    );
  }

  Widget _buildSignalDot() {
    Color signalColor;
    switch (gpsSignal) {
      case 'HIGH':      signalColor = const Color(0xFF10B981); break;
      case 'GOOD':      signalColor = const Color(0xFF22C55E); break;
      case 'MEDIUM':    signalColor = const Color(0xFFF59E0B); break;
      case 'ACQUIRING': signalColor = const Color(0xFF6B7280); break;
      default:          signalColor = const Color(0xFFEF4444);
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: signalColor,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: signalColor.withValues(alpha: 0.6), blurRadius: 5)],
      ),
    );
  }

  String _getShortAddress(String fullAddress) {
    final parts = fullAddress.split(',');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2].trim()}, ${parts[parts.length - 1].trim()}';
    }
    return fullAddress;
  }
}

/// A small pill-shaped chip used inside the compact HUD row
class _CompactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final bool mono;

  const _CompactChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 11),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontFamily: mono ? 'monospace' : null,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
