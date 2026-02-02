import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/photo_model.dart';
import '../services/database_service.dart';

class PhotoDetailScreen extends StatefulWidget {
  final String? imagePath;
  final Photo? photo;

  const PhotoDetailScreen({
    super.key,
    this.imagePath,
    this.photo,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late Photo? _photo;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _photo = widget.photo;
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ShareBottomSheet(
        photo: _photo,
        imagePath: widget.imagePath ?? _photo?.imagePath,
      ),
    );
  }

  Future<void> _deletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _photo?.id != null) {
      await _databaseService.deletePhoto(_photo!.id!);
      // Also delete the file
      final file = File(_photo!.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath ?? _photo?.imagePath;
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return Scaffold(
      backgroundColor: Colors.black, // Pure black background for photo view
      body: Stack(
        children: [
          // Photo background
          Positioned.fill(
            child: imagePath != null && File(imagePath).existsSync()
                ? InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1A3A2A),
                          AppColors.backgroundDark,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 80,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Image not found',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          
          // Header Overlay (Always show for navigation/actions)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Colors.white),
                      onPressed: _showShareSheet,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: _deletePhoto,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // NOTE: The bottom info overlay has been removed to prevent "ghosting".
          // The GPS metadata is already burned into the image by WatermarkService.
        ],
      ),
    );
  }

  Widget _buildGpsStatsRow() {
    return Row(
      children: [
        _StatItem(
          icon: Icons.height,
          label: 'ALTITUDE',
          value: _photo?.altitudeFormatted ?? '--',
        ),
        const SizedBox(width: 24),
        _StatItem(
          icon: Icons.speed,
          label: 'SPEED',
          value: _photo?.speed != null 
              ? '${_photo!.speed!.toStringAsFixed(1)} m/s' 
              : '--',
        ),
        const SizedBox(width: 24),
        _StatItem(
          icon: Icons.wb_sunny_outlined,
          label: 'TEMP',
          value: _photo?.temperatureFormatted ?? '--',
        ),
      ],
    );
  }

  Widget _buildCoordinatesBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _photo?.coordinatesDD ?? 'No GPS data',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_photo != null) {
                Clipboard.setData(ClipboardData(text: _photo!.coordinatesDD));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coordinates copied')),
                );
              }
            },
            child: const Icon(Icons.copy, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[500], size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ShareBottomSheet extends StatelessWidget {
  final Photo? photo;
  final String? imagePath;

  const _ShareBottomSheet({
    this.photo,
    this.imagePath,
  });

  Future<void> _sharePhoto(BuildContext context) async {
    final path = imagePath ?? photo?.imagePath;
    if (path != null && File(path).existsSync()) {
      await Share.shareXFiles(
        [XFile(path)],
        text: photo != null
            ? 'Photo taken at ${photo!.address ?? photo!.coordinatesDD}'
            : null,
      );
    }
  }

  Future<void> _shareWithGpsData(BuildContext context) async {
    if (photo == null) return;
    
    final text = '''
📍 Location: ${photo!.address ?? 'Unknown'}
🌐 Coordinates: ${photo!.coordinatesDD}
📏 Altitude: ${photo!.altitudeFormatted}
🌡️ Temperature: ${photo!.temperatureFormatted}
📅 Date: ${DateFormat('MMMM d, yyyy • h:mm a').format(photo!.capturedAt)}
''';
    
    final path = imagePath ?? photo!.imagePath;
    if (File(path).existsSync()) {
      await Share.shareXFiles(
        [XFile(path)],
        text: text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Share Photo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _ShareOption(
                  icon: Icons.photo,
                  title: 'Share Photo',
                  subtitle: 'Share the image file',
                  onTap: () => _sharePhoto(context),
                ),
                const SizedBox(height: 12),
                _ShareOption(
                  icon: Icons.location_on,
                  title: 'Share with GPS Data',
                  subtitle: 'Include location info in caption',
                  onTap: () => _shareWithGpsData(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
