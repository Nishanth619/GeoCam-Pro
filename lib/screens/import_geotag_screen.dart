import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/photo_model.dart';
import '../services/database_service.dart';
import '../services/exif_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../services/watermark_service.dart';
import '../theme/app_theme.dart';
import 'package:geocam_flutter/l10n/app_localizations.dart';
import 'edit_location_screen.dart';

/// Full-screen flow: pick a gallery photo → assign GPS → burn watermark → save.
class ImportGeotagScreen extends StatefulWidget {
  const ImportGeotagScreen({super.key});

  @override
  State<ImportGeotagScreen> createState() => _ImportGeotagScreenState();
}

class _ImportGeotagScreenState extends State<ImportGeotagScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();
  final ExifService _exifService = ExifService();
  final WatermarkService _watermarkService = WatermarkService();
  final DatabaseService _databaseService = DatabaseService();
  final SettingsService _settings = SettingsService();

  // ── State ─────────────────────────────────────────────────────────────────
  File? _pickedFile;
  double? _lat;
  double? _lon;
  String _address = 'No location selected';

  bool _isSaving = false;
  bool _isPickingImage = false;

  // Watermark toggles
  bool _showAddress = true;
  bool _showCoordinates = true;
  bool _showDate = true;
  bool _showMiniMap = true; // fetch satellite mini-map tile for watermark

  // Pin drop animation controller (re-used from EditLocationScreen style)
  late AnimationController _pinAnim;
  late Animation<double> _pinScale;

  @override
  void initState() {
    super.initState();
    _pinAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pinScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pinAnim, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pinAnim.dispose();
    super.dispose();
  }

  // ── Image Picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // keep original quality
      );
      if (xFile == null || !mounted) return;

      // Try to read existing EXIF GPS from the picked image
      final existingGps = await _exifService.readGpsFromImage(xFile.path);

      setState(() {
        _pickedFile = File(xFile.path);
        if (existingGps != null) {
          _lat = existingGps['latitude'];
          _lon = existingGps['longitude'];
          _address = AppLocalizations.of(context)!.importGpsFromPhoto;
        }
      });

      _pinAnim.forward(from: 0);
    } catch (e) {
      debugPrint('ImportGeotag: error picking image: $e');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // ── Location Picking ───────────────────────────────────────────────────────

  Future<void> _pickLocation() async {
    // Push EditLocationScreen and wait for result
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditLocationScreen()),
    );

    if (!mounted) return;

    // Read the override that EditLocationScreen wrote
    if (result == true && _locationService.isManualOverrideActive) {
      final pos = _locationService.effectivePosition;
      setState(() {
        _lat = pos?.latitude;
        _lon = pos?.longitude;
        _address = _locationService.manualOverrideAddress ?? 'Custom location';
      });
      _pinAnim.forward(from: 0);
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_pickedFile == null || _lat == null || _lon == null) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      // 1. Copy the original to our app temp dir (don't mutate gallery original)
      final tmpDir = await getTemporaryDirectory();
      final tmpPath =
          path.join(tmpDir.path, 'geocam_import_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await _pickedFile!.copy(tmpPath);

      // 2. Write GPS EXIF
      await _exifService.writeGpsToImage(
        imagePath: tmpPath,
        latitude: _lat!,
        longitude: _lon!,
        dateTime: _locationService.effectiveDateTime,
      );

      // 3. Build a Photo object so WatermarkService can draw the overlay
      final photo = Photo(
        imagePath: tmpPath,
        latitude: _lat!,
        longitude: _lon!,
        address: _address,
        capturedAt: _locationService.effectiveDateTime,
      );

      // 4. Burn watermark + save to GeoCam gallery folder
      final savedPath = await _watermarkService.createWatermarkedImage(
        photo,
        showAddress: _showAddress,
        showCoordinates: _showCoordinates,
        showDate: _showDate,
        showAltitude: false,
        showTemperature: false,
        showMiniMap: _showMiniMap,
        mapType: _settings.templateMapType, // respect user's map style setting
        saveToGallery: true,
      );

      if (savedPath == null) throw Exception('Watermark service returned null');

      // 5. Insert into database so it appears in Gallery
      final dbPhoto = Photo(
        imagePath: savedPath,
        latitude: _lat!,
        longitude: _lon!,
        address: _address,
        capturedAt: _locationService.effectiveDateTime,
      );
      await _databaseService.insertPhoto(dbPhoto);

      // 6. Clean up tmp copy
      final tmp = File(tmpPath);
      if (await tmp.exists()) await tmp.delete();

      if (!mounted) return;
      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.importSuccess,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ]),
          backgroundColor: AppColors.primary.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pop(true); // true = something was saved
    } catch (e) {
      debugPrint('ImportGeotag: save error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.importSaveFailed(e.toString()),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool locationSet = _lat != null && _lon != null;
    final bool canSave = _pickedFile != null && locationSet && !_isSaving;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageCard(),
                    const SizedBox(height: 20),
                    _buildLocationCard(locationSet),
                    const SizedBox(height: 20),
                    _buildWatermarkToggles(),
                    const SizedBox(height: 28),
                    _buildSaveButton(canSave),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            border: const Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GEOCAM PRO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.importTitle,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  // ─── Image Card ───────────────────────────────────────────────────────────

  Widget _buildImageCard() {
    return GestureDetector(
      onTap: _isPickingImage ? null : _pickImage,
      child: AnimatedBuilder(
        animation: _pinScale,
        builder: (_, child) => Transform.scale(
          scale: _pickedFile != null ? _pinScale.value.clamp(0.97, 1.03) : 1.0,
          child: child,
        ),
        child: Container(
          height: 280,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pickedFile != null
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.white12,
            ),
            boxShadow: _pickedFile != null
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          clipBehavior: Clip.hardEdge,
          child: _pickedFile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_pickedFile!, fit: BoxFit.cover),
                    // Overlay edit hint
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.swap_horiz,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context)!.importChangePhoto,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : _isPickingImage
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.primary, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.importChoosePhoto,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context)!.importChoosePhotoHint,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ─── Location Card ────────────────────────────────────────────────────────

  Widget _buildLocationCard(bool locationSet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: locationSet
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: locationSet
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    locationSet
                        ? Icons.location_on
                        : Icons.location_off_outlined,
                    color:
                        locationSet ? AppColors.primary : Colors.white38,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationSet ? AppLocalizations.of(context)!.importLocationSet : AppLocalizations.of(context)!.importNoLocation,
                        style: TextStyle(
                          color: locationSet
                              ? AppColors.primary
                              : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _address,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Coordinates chip
          if (locationSet) ...[
            const Divider(height: 1, color: Colors.white10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.my_location,
                      color: AppColors.primary, size: 13),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${_lat!.toStringAsFixed(6)}°, ${_lon!.toStringAsFixed(6)}°',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1, color: Colors.white10),
          // Action button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _pickLocation,
              icon: Icon(
                locationSet ? Icons.edit_location_alt : Icons.add_location_alt,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                locationSet ? AppLocalizations.of(context)!.importChangeLocationBtn : AppLocalizations.of(context)!.importSetLocationBtn,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(18)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Watermark Toggles ────────────────────────────────────────────────────

  Widget _buildWatermarkToggles() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.layers_outlined, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.importWatermarkOptions,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.white54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          _buildToggle(
            icon: Icons.map_outlined,
            label: AppLocalizations.of(context)!.importShowMiniMap,
            value: _showMiniMap,
            onChanged: (v) => setState(() => _showMiniMap = v),
          ),
          _buildToggle(
            icon: Icons.location_on_outlined,
            label: AppLocalizations.of(context)!.importShowAddress,
            value: _showAddress,
            onChanged: (v) => setState(() => _showAddress = v),
          ),
          _buildToggle(
            icon: Icons.gps_fixed,
            label: AppLocalizations.of(context)!.importShowCoordinates,
            value: _showCoordinates,
            onChanged: (v) => setState(() => _showCoordinates = v),
          ),
          _buildToggle(
            icon: Icons.calendar_today_outlined,
            label: AppLocalizations.of(context)!.importShowDate,
            value: _showDate,
            onChanged: (v) => setState(() => _showDate = v),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Column(
      children: [
        SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          secondary: Icon(icon, color: Colors.white54, size: 20),
          title: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          inactiveThumbColor: Colors.white30,
          inactiveTrackColor: Colors.white12,
        ),
        if (!isLast) const Divider(height: 1, color: Colors.white10),
      ],
    );
  }

  // ─── Save Button ──────────────────────────────────────────────────────────

  Widget _buildSaveButton(bool canSave) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: canSave ? _save : null,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF0F1A24)),
              )
            : const Icon(Icons.save_alt_outlined, size: 20),
        label: Text(
          _isSaving ? AppLocalizations.of(context)!.importSaving : AppLocalizations.of(context)!.importSaveBtn,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF0F1A24),
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.25),
          disabledForegroundColor: Colors.white30,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
