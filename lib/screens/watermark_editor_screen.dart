import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';
import '../services/watermark_service.dart';
import '../services/database_service.dart';
import '../models/photo_model.dart';

class WatermarkEditorScreen extends StatefulWidget {
  const WatermarkEditorScreen({super.key});

  @override
  State<WatermarkEditorScreen> createState() => _WatermarkEditorScreenState();
}

class _WatermarkEditorScreenState extends State<WatermarkEditorScreen> {
  final SettingsService _settings = SettingsService();
  final WatermarkService _watermarkService = WatermarkService();
  final DatabaseService _databaseService = DatabaseService();

  late int _selectedLogo;
  late String _watermarkText;
  late int _selectedPosition;
  late double _opacity;
  late double _scale;
  
  Photo? _previewPhoto;
  bool _isExporting = false;

  final List<IconData> _logoOptions = [
    Icons.camera_alt,
    Icons.grid_view,
    Icons.location_on,
    Icons.landscape,
  ];

  @override
  void initState() {
    super.initState();
    // Load saved settings
    _selectedLogo = _settings.watermarkLogo;
    _watermarkText = _settings.watermarkText;
    _selectedPosition = _settings.watermarkPosition;
    _opacity = _settings.watermarkOpacity;
    _scale = _settings.watermarkScale;
    _loadPreviewPhoto();
  }

  Future<void> _loadPreviewPhoto() async {
    final photos = await _databaseService.getAllPhotos();
    if (photos.isNotEmpty && mounted) {
      setState(() {
        _previewPhoto = photos.first;
      });
    }
  }

  void _saveSettings() {
    _settings.watermarkLogo = _selectedLogo;
    _settings.watermarkText = _watermarkText;
    _settings.watermarkPosition = _selectedPosition;
    _settings.watermarkOpacity = _opacity;
    _settings.watermarkScale = _scale;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Watermark settings saved'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _exportWithWatermark() async {
    if (_previewPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No photo to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    final exportPath = await _watermarkService.createWatermarkedImage(
      _previewPhoto!,
      showAddress: true,
      showCoordinates: true,
      showAltitude: true,
      showTemperature: true,
      showDate: true,
      opacity: _opacity,
      saveToGallery: true,
    );

    setState(() => _isExporting = false);

    if (exportPath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Photo exported with watermark!'),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () => Share.shareXFiles([XFile(exportPath)]),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Watermark Editor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // Preview
              Container(
                margin: const EdgeInsets.all(16),
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.cardDark,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Photo preview or placeholder
                    if (_previewPhoto != null && File(_previewPhoto!.imagePath).existsSync())
                      Positioned.fill(
                        child: Image.file(
                          File(_previewPhoto!.imagePath),
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, size: 48, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'Take a photo to preview',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    // Watermark preview overlay
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: _opacity),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _logoOptions[_selectedLogo],
                              color: AppColors.primary,
                              size: 16 * _scale,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _watermarkText,
                                  style: TextStyle(
                                    fontSize: 12 * _scale,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _previewPhoto != null
                                      ? '${_previewPhoto!.latitude.toStringAsFixed(4)}°, ${_previewPhoto!.longitude.toStringAsFixed(4)}°'
                                      : 'lat: 0.0000 • long: 0.0000',
                                  style: TextStyle(
                                    fontSize: 8 * _scale,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Export button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: _previewPhoto != null ? _exportWithWatermark : null,
                  icon: const Icon(Icons.download),
                  label: const Text('Export with Watermark'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Logo Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Logo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedLogo = 0);
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _logoOptions.asMap().entries.map((entry) {
                    final isSelected = entry.key == _selectedLogo;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedLogo = entry.key),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.cardBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              // Text Watermark
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Text Watermark',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: _watermarkText),
                        onChanged: (value) => setState(() => _watermarkText = value),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.edit,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          hintText: 'Enter watermark text',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Position
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Position',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: SizedBox(
                          width: 140,
                          height: 100,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: 9,
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedPosition;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedPosition = index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.cardBorder.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Opacity Slider
              _SliderControl(
                label: 'Opacity',
                value: _opacity,
                valueLabel: '${(_opacity * 100).round()}%',
                onChanged: (v) => setState(() => _opacity = v),
              ),
              const SizedBox(height: 16),
              // Scale Slider
              _SliderControl(
                label: 'Scale',
                value: _scale,
                min: 0.5,
                max: 2.0,
                valueLabel: '${_scale.toStringAsFixed(1)}x',
                onChanged: (v) => setState(() => _scale = v),
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
}

class _SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final String valueLabel;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderControl({
    required this.label,
    required this.value,
    required this.valueLabel,
    this.min = 0,
    this.max = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                valueLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.cardBorder,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
