import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/permission_card.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../services/export_service.dart';
import 'watermark_editor_screen.dart';
import 'premium_screen.dart';
import 'legal_content_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final SettingsService _settings = SettingsService();
  final ExportService _exportService = ExportService();
  
  // Storage info
  int _photoCount = 0;
  double _usedGB = 0;
  double _totalGB = 128;
  int _percentage = 0;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    // Get photo count
    _photoCount = await _databaseService.getPhotoCount();
    
    // Get storage info
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = await appDir.stat();
      // Estimate used space (rough calculation)
      _usedGB = _photoCount * 3.5 / 1024; // Assume ~3.5MB per photo
      _percentage = ((_usedGB / _totalGB) * 100).clamp(0, 100).toInt();
    } catch (e) {
      debugPrint('Error getting storage: $e');
    }
    
    if (mounted) setState(() {});
  }

  Future<void> _clearAllPhotos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Clear All Photos'),
        content: Text('Delete all $_photoCount photos? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final photos = await _databaseService.getAllPhotos();
      for (final photo in photos) {
        await _databaseService.deletePhoto(photo.id!);
      }
      await _loadStorageInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All photos deleted')),
        );
      }
    }
  }

  Future<void> _exportData(String format) async {
    setState(() => _isExporting = true);
    
    String? filePath;
    switch (format) {
      case 'gpx':
        filePath = await _exportService.exportToGPX();
        break;
      case 'kml':
        filePath = await _exportService.exportToKML();
        break;
      case 'csv':
        filePath = await _exportService.exportToCSV();
        break;
    }

    setState(() => _isExporting = false);

    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to ${format.toUpperCase()}'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => Share.shareXFiles([XFile(filePath!)]),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_photoCount == 0 ? 'No photos to export' : 'Export failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export GPS Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Export $_photoCount photo locations',
                style: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              _ExportOption(
                icon: Icons.map,
                title: 'GPX File',
                subtitle: 'For GPS devices & mapping apps',
                onTap: () {
                  Navigator.pop(context);
                  _exportData('gpx');
                },
              ),
              _ExportOption(
                icon: Icons.public,
                title: 'KML File',
                subtitle: 'For Google Earth',
                onTap: () {
                  Navigator.pop(context);
                  _exportData('kml');
                },
              ),
              _ExportOption(
                icon: Icons.table_chart,
                title: 'CSV Spreadsheet',
                subtitle: 'For Excel & data analysis',
                onTap: () {
                  Navigator.pop(context);
                  _exportData('csv');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Camera Settings Section
              _buildSectionHeader('CAMERA & OVERLAY', Icons.camera_alt_outlined),
              _SettingsToggleTile(
                icon: Icons.grid_on_outlined,
                title: 'Camera Grid Lines',
                subtitle: 'Assist with photo composition',
                value: _settings.gridLinesEnabled,
                onChanged: (value) {
                  setState(() => _settings.gridLinesEnabled = value);
                },
              ),
              _SettingsToggleTile(
                icon: Icons.branding_watermark_outlined,
                title: 'GPS Watermark Overlay',
                subtitle: 'Burn data directly into photo',
                value: _settings.showWatermark,
                onChanged: (value) {
                  setState(() => _settings.showWatermark = value);
                },
              ),

              // Map Style Section
              _buildSectionHeader('WATERMARK MAP STYLE', Icons.map_outlined),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _buildMapTypeCarousel(),
              ),
              
              // Data Fields Section
              _buildSectionHeader('DATA FIELDS VISIBILITY', Icons.view_quilt_outlined),
              _SettingsToggleTile(
                icon: Icons.location_on_outlined,
                title: 'Full Address',
                value: _settings.templateShowAddress,
                onChanged: (v) => setState(() => _settings.templateShowAddress = v),
              ),
              _SettingsToggleTile(
                icon: Icons.my_location_outlined,
                title: 'GPS Coordinates',
                value: _settings.templateShowCoordinates,
                onChanged: (v) => setState(() => _settings.templateShowCoordinates = v),
              ),
              _SettingsToggleTile(
                icon: Icons.explore_outlined,
                title: 'Compass & Heading',
                value: _settings.templateShowCompass,
                onChanged: (v) => setState(() => _settings.templateShowCompass = v),
              ),
              _SettingsToggleTile(
                icon: Icons.calendar_today_outlined,
                title: 'Date & Time Stamp',
                value: _settings.templateShowDateTime,
                onChanged: (v) => setState(() => _settings.templateShowDateTime = v),
              ),
              
              // Formatting Section
              _buildSectionHeader('DISPLAY FORMATS', Icons.settings_outlined),
              _SettingsDropdownTile(
                icon: Icons.calendar_month_outlined,
                title: 'Date Display',
                options: const ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
                value: _settings.templateDateFormat,
                onChanged: (v) => setState(() => _settings.templateDateFormat = v),
              ),
              _SettingsDropdownTile(
                icon: Icons.gps_fixed_outlined,
                title: 'Coordinate Precision',
                options: const ['Decimal Degrees (DD)', 'Degrees Minutes Seconds (DMS)'],
                value: _settings.templateCoordFormat,
                onChanged: (v) => setState(() => _settings.templateCoordFormat = v),
              ),
              
              // Measurement Units Section
              _buildSectionHeader('MEASUREMENT UNITS', Icons.straighten_outlined),
              _SettingsSegmentTile(
                icon: Icons.height_outlined,
                title: 'Altitude & Distance',
                options: const ['Metric', 'Imperial'],
                selectedIndex: _settings.useMetricUnits ? 0 : 1,
                onChanged: (index) {
                  setState(() => _settings.useMetricUnits = index == 0);
                },
              ),
              _SettingsSegmentTile(
                icon: Icons.thermostat_outlined,
                title: 'Temperature',
                options: const ['°C', '°F'],
                selectedIndex: _settings.useCelsius ? 0 : 1,
                onChanged: (index) {
                  setState(() => _settings.useCelsius = index == 0);
                },
              ),
              
              // Storage Section
              _buildSectionHeader('STORAGE & DATA', Icons.storage_outlined),
              _StorageTile(
                photoCount: _photoCount,
                usedGB: _usedGB,
                totalGB: _totalGB,
                percentage: _percentage,
              ),
              _SettingsTile(
                icon: Icons.file_download_outlined,
                title: 'Export GPS Data',
                subtitle: 'GPX, KML, or CSV format',
                trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                iconColor: AppColors.primary,
                onTap: _photoCount > 0 ? _showExportOptions : null,
              ),
              _SettingsTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Clear All Photos',
                subtitle: 'Safe permanent deletion',
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                iconColor: Colors.red,
                onTap: _photoCount > 0 ? _clearAllPhotos : null,
              ),
              
              // Legal Section
              _buildSectionHeader('LEGAL & PRIVACY', Icons.gavel_outlined),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LegalContentScreen(
                        title: 'Terms & Conditions',
                        isPrivacyPolicy: false,
                      ),
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LegalContentScreen(
                        title: 'Privacy Policy',
                        isPrivacyPolicy: true,
                      ),
                    ),
                  );
                },
              ),

              // About Section
              _buildSectionHeader('SYSTEM PERMISSIONS', Icons.security_outlined),
              _SettingsTile(
                icon: Icons.settings_applications_outlined,
                title: 'Manage Permissions',
                subtitle: 'Open system settings',
                trailing: const Icon(Icons.open_in_new_outlined, size: 18, color: AppColors.textMuted),
                onTap: () async {
                  await Geolocator.openAppSettings();
                },
              ),

              _buildSectionHeader('ABOUT GEOCAM PRO', Icons.info_outline),
              _SettingsTile(
                icon: Icons.diamond_outlined,
                title: 'Upgrade to Premium',
                subtitle: 'Unlock tactical map styles',
                iconColor: Colors.amber,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
                },
              ),
              _SettingsTile(
                icon: Icons.verified_user_outlined,
                title: 'App Version',
                subtitle: '1.0.0 PRO',
              ),
              
              const SizedBox(height: 100),
            ],
          ),
          // Loading overlay
          if (_isExporting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Exporting...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypeCarousel() {
    final List<String> mapTypes = ['Normal', 'Satellite', 'Terrain', 'Hybrid'];
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: mapTypes.length,
        itemBuilder: (context, index) {
          final isSelected = index == _settings.templateMapType;
          return GestureDetector(
            onTap: () => setState(() => _settings.templateMapType = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getMapIcon(index),
                    color: isSelected ? Colors.black : Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mapTypes[index].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getMapIcon(int index) {
    switch (index) {
      case 0: return Icons.map_outlined;
      case 1: return Icons.satellite_outlined;
      case 2: return Icons.terrain_outlined;
      case 3: return Icons.layers_outlined;
      default: return Icons.map;
    }
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[400]),
      ),
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: AppColors.textSecondary,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            )
          : null,
      trailing: CustomToggle(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingsSegmentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SettingsSegmentTile({
    required this.icon,
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.textSecondary, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.asMap().entries.map((entry) {
            final isSelected = entry.key == selectedIndex;
            return GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.black : Colors.white60,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SettingsDropdownTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _SettingsDropdownTile({
    required this.icon,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.textSecondary, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.cardDark,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.expand_more, color: AppColors.primary, size: 20),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
        onChanged: (v) { if (v != null) onChanged(v); },
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
      ),
    );
  }
}

class _StorageTile extends StatelessWidget {
  final int photoCount;
  final double usedGB;
  final double totalGB;
  final int percentage;

  const _StorageTile({
    required this.photoCount,
    required this.usedGB,
    required this.totalGB,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.storage,
            color: AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GeoCam Storage',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$photoCount photos',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.cardBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '~${usedGB.toStringAsFixed(1)} GB used',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CustomToggle({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.cardBorder,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
