import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme/app_theme.dart';
import '../widgets/gps_hud_card.dart';
import '../widgets/zoom_slider.dart';
import '../services/ad_service.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../services/database_service.dart';
import '../services/permission_service.dart';
import '../services/settings_service.dart';
import '../services/exif_service.dart';
import '../services/watermark_service.dart';
import '../models/photo_model.dart';
import 'template_customization_sheet.dart';
import 'gallery_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}


class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  final DatabaseService _databaseService = DatabaseService();
  final PermissionService _permissionService = PermissionService();
  final ExifService _exifService = ExifService();
  final SettingsService _settings = SettingsService();
  final WatermarkService _watermarkService = WatermarkService();
  final AdService _adService = AdService();

  // Available aspect ratios for cycling
  static const List<String> _availableAspectRatios = ['4:3', '16:9', '1:1'];
  
  double _zoomLevel = 0.0;
  String _aspectRatio = '4:3';
  FlashMode _flashMode = FlashMode.off;
  bool _isCapturing = false;
  bool _isCameraInitializing = true;
  bool _isSwitchingCamera = false;
  bool _showShutterEffect = false;
  String? _cameraError;

  // Location data
  Position? _currentPosition;
  String? _currentAddress;
  StreamSubscription<Position>? _positionSubscription;

  // Weather data
  double? _temperature;
  String? _weatherCondition;

  // Last captured photo for gallery thumbnail
  Photo? _lastPhoto;

  // Real-time HUD updates
  DateTime _currentTime = DateTime.now();
  Timer? _timeUpdateTimer;

  // Focus state
  Offset? _focusPoint;
  bool _isFocusing = false;
  Timer? _focusTimer;
  


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAll();
    _startTimeUpdates();
  }



  void _startTimeUpdates() {
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _timeUpdateTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeAll() async {
    await _initializeCamera();
    _startLocationUpdates();
    _loadLastPhoto();
  }

  Future<void> _loadLastPhoto() async {
    final photos = await _databaseService.getAllPhotos();
    if (photos.isNotEmpty && mounted) {
      setState(() {
        _lastPhoto = photos.first;
      });
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isCameraInitializing = true;
      _cameraError = null;
    });

    // Try to request permissions if not granted (shouldn't happen if user completed onboarding)
    // But we'll be graceful and request them anyway
    final hasCamera = await _permissionService.hasCameraPermission();
    final hasStorage = await _permissionService.hasStoragePermission();
    
    if (!hasCamera) {
      await _permissionService.requestCameraPermission();
    }
    
    if (!hasStorage) {
      await _permissionService.requestStoragePermission();
    }

    // Initialize camera regardless - let the camera service handle any permission errors
    final success = await _cameraService.initializeController();
    if (mounted) {
      setState(() {
        _isCameraInitializing = false;
        _zoomLevel = 0.0; // Reset zoom on init
        if (!success) {
          _cameraError = 'Failed to initialize camera.\nPlease check permissions in Settings.';
        }
      });
    }
  }

  void _startLocationUpdates() async {
    // Check permission first
    final hasPermission = await _permissionService.hasLocationPermission();
    if (!hasPermission) {
      debugPrint('Location permission not granted');
      return;
    }

    // 1. STAGE 1: Instant Last Known Position (Non-blocking)
    // This allows the app to show data immediately
    final lastKnown = await _locationService.getLastKnownPosition();
    if (lastKnown != null && mounted) {
      setState(() {
        _currentPosition = lastKnown;
      });
      // Try to get address for last known in background
      _locationService.getAddressFromCoordinates(
        lastKnown.latitude,
        lastKnown.longitude,
      ).then((address) {
        if (mounted && address != null) {
          setState(() => _currentAddress = address);
          _fetchWeather();
        }
      });
    }

    // 2. STAGE 2: Start High Accuracy Stream
    // This will upgrade the HUD data as soon as a better fix is available
    final stream = _locationService.getPositionStream();
    if (stream != null) {
      _positionSubscription = stream.listen(
        (Position position) async {
          final isSignificantMove = _currentPosition == null || 
              _locationService.calculateDistance(
                _currentPosition!.latitude, 
                _currentPosition!.longitude, 
                position.latitude, 
                position.longitude
              ) > 5; // Refresh address if moved > 5m

          setState(() {
            _currentPosition = position;
          });

          if (isSignificantMove || _currentAddress == null) {
            final address = await _locationService.getAddressFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (mounted && address != null) {
              setState(() {
                _currentAddress = address;
              });
              _fetchWeather();
            }
          }
        },
        onError: (error) {
          debugPrint('Location stream error: $error');
        },
      );
    }
    
    // 3. Trigger a fresh single-shot accurate fix in background (optional, stream handles it)
    unawaited(_locationService.getCurrentPosition());
  }

  Future<void> _fetchWeather() async {
    if (_currentPosition == null) return;
    final weather = await _weatherService.getWeather(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    if (weather != null && mounted) {
      setState(() {
        _temperature = weather.temperature;
        _weatherCondition = weather.condition;
      });
    }
  }

  Future<void> _toggleFlash() async {
    // Check if flash is supported
    if (!_cameraService.hasFlash) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flash not supported on this camera'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }
    
    final newMode = await _cameraService.toggleFlash();
    if (mounted) {
      setState(() {
        _flashMode = newMode;
      });
    }
  }

  void _cycleAspectRatio() {
    final currentIndex = _availableAspectRatios.indexOf(_aspectRatio);
    final nextIndex = (currentIndex + 1) % _availableAspectRatios.length;
    setState(() {
      _aspectRatio = _availableAspectRatios[nextIndex];
    });
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera) return;
    
    setState(() {
      _isSwitchingCamera = true;
    });
    
    await _cameraService.switchCamera();
    
    if (mounted) {
      setState(() {
        _isSwitchingCamera = false;
        _zoomLevel = 0.0; // Reset zoom on switch
        // Reset flash to off for front camera (most don't support flash)
        if (_cameraService.isFrontCamera) {
          _flashMode = FlashMode.off;
        }
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || !_cameraService.isInitialized) return;

    // 1. INSTANT FEEDBACK: Shutter sound (optional) and Visual Flash
    setState(() {
      _isCapturing = true;
      _showShutterEffect = true;
    });
    
    HapticFeedback.mediumImpact();

    // Hide flash after 50ms for that "mirror slap" feel
    Timer(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _showShutterEffect = false);
    });

    try {
      final imagePath = await _cameraService.capturePhoto();
      
      // SHUTTER RESET: Unlock UI immediately
      setState(() {
        _isCapturing = false;
      });

      if (imagePath != null) {
        // Fire and forget the heavy processing tasks
        unawaited(_processCapturedPhoto(imagePath));
        
        // Monetization: Trigger Interstitial ad logic
        _adService.onPhotoCaptured(showAfterCount: 3);
      }
    } catch (e) {
      debugPrint('Error during shutter action: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  /// Background pipeline for heavy image processing
  Future<void> _processCapturedPhoto(String imagePath) async {
    try {
      // Capture current state to ensure consistency across the background flow
      final capturedAt = DateTime.now();
      final position = _currentPosition;
      final address = _currentAddress;
      final temp = _temperature;
      final weather = _weatherCondition;
      final currentAspectRatio = _aspectRatio;

      // 1. Apply aspect ratio cropping if needed (using Isolate)
      if (currentAspectRatio != '4:3') {
        await _applyAspectRatioCrop(imagePath);
      }

      // 2. Create photo model
      final photo = Photo(
        imagePath: imagePath,
        latitude: position?.latitude ?? 0,
        longitude: position?.longitude ?? 0,
        altitude: position?.altitude,
        speed: position?.speed,
        heading: position?.heading,
        address: address,
        capturedAt: capturedAt,
        temperature: temp,
        weatherCondition: weather,
      );

      // 3. Apply GPS watermark overlay if enabled
      if (_settings.showWatermark && position != null) {
        debugPrint('🎨 Applying GPS watermark overlay (Background)...');
        final watermarkedPath = await _watermarkService.createWatermarkedImage(
          photo,
          showAddress: _settings.templateShowAddress,
          showCoordinates: _settings.templateShowCoordinates,
          showAltitude: true,
          showTemperature: temp != null,
          showDate: _settings.templateShowDateTime,
          showMiniMap: true,
          mapType: _settings.templateMapType,
          opacity: _settings.watermarkOpacity,
        );

        if (watermarkedPath != null) {
          final originalFile = File(imagePath);
          final watermarkedFile = File(watermarkedPath);
          await watermarkedFile.copy(imagePath);
          await watermarkedFile.delete();
          
          // Re-scan the file to ensure the gallery thumbnail is updated with the watermarked version
          await _cameraService.scanFile(imagePath);
        }
      }

      // 4. Write EXIF GPS data
      if (position != null) {
        await _exifService.writeGpsToImage(
          imagePath: imagePath,
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          dateTime: capturedAt,
        );
        
        // RE-SCAN: Ensure Gallery picks up the newly added GPS metadata
        await _cameraService.scanFile(imagePath);
      }

      // 5. Save to database
      final id = await _databaseService.insertPhoto(photo);
      
      // 6. Final UI update (Thumbnails and Feedback)
      if (mounted) {
        setState(() {
          _lastPhoto = photo.copyWith(id: id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text('Photo processed and saved!', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: AppColors.cardDark,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Background processing error: $e');
    }
  }

  Future<void> _applyAspectRatioCrop(String imagePath) async {
    try {
      // Offload heavy image processing (decoding, cropping, encoding) to a background Isolate
      // This prevents the camera UI from freezing
      await compute(_processImageCrop, {
        'path': imagePath,
        'ratio': _aspectRatio,
      });
    } catch (e) {
      debugPrint('Error offloading crop to isolate: $e');
    }
  }

  void _showTemplateSheet() {
    _adService.showInterstitialAd();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TemplateCustomizationSheet(),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openGallery() {
    _adService.showInterstitialAd();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GalleryScreen()),
    ).then((_) => _loadLastPhoto());
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  Widget _buildCameraPreview() {
    if (_isCameraInitializing) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraError != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _cameraError!,
                  style: TextStyle(color: Colors.red[400], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _initializeCamera,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _permissionService.requestAllPermissions();
                      _initializeCamera();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraService.isInitialized && _cameraService.controller != null) {
      // Show overlay when switching cameras
      if (_isSwitchingCamera) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Switching Camera...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      }
      
      // Get aspect ratio value
      double aspectRatioValue;
      switch (_aspectRatio) {
        case '16:9':
          aspectRatioValue = 16 / 9;
          break;
        case '1:1':
          aspectRatioValue = 1.0;
          break;
        case '4:3':
        default:
          aspectRatioValue = 4 / 3;
          break;
      }
      
      // Apply aspect ratio to camera preview
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: AspectRatio(
            aspectRatio: aspectRatioValue,
            child: CameraPreview(_cameraService.controller!),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Camera not available',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildGalleryThumbnail() {
    return GestureDetector(
      onTap: _openGallery,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
          image: _lastPhoto != null && File(_lastPhoto!.imagePath).existsSync()
              ? DecorationImage(
                  image: FileImage(File(_lastPhoto!.imagePath)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _lastPhoto == null || !File(_lastPhoto!.imagePath).existsSync()
            ? const Icon(
                Icons.image,
                color: AppColors.textMuted,
                size: 24,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        return Scaffold(
          backgroundColor: Colors.black,
          body: isLandscape
              ? _buildLandscapeLayout()
              : _buildPortraitLayout(),
        );
      },
    );
  }

  // ─── PORTRAIT LAYOUT (original) ────────────────────────────────────────────
  Widget _buildPortraitLayout() {
    return Stack(
      children: [
        Positioned.fill(child: _buildCameraPreview()),

        // Shutter flash
        if (_showShutterEffect)
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.8)),
          ),

        // Tap-to-focus overlay
        Positioned.fill(child: _buildFocusOverlay()),

        // Focus reticle
        if (_isFocusing && _focusPoint != null)
          Positioned(
            left: _focusPoint!.dx - 35,
            top: _focusPoint!.dy - 35,
            child: const _FocusReticle(),
          ),

        // Vignette
        Positioned.fill(child: _buildVignette()),

        // Top toolbar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: _buildTopToolbar(),
          ),
        ),

        // Zoom slider
        Positioned(
          right: 20,
          top: 0,
          bottom: 120,
          child: Center(
            child: ZoomSlider(
              value: _zoomLevel,
              onChanged: (value) async {
                _zoomLevel = value;
                await _cameraService.setZoom(value);
              },
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.9),
                  Colors.black,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGpsHud(),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildGalleryThumbnail(),
                        _buildShutterButton(),
                        _buildTemplatesButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── LANDSCAPE LAYOUT (iOS/FieldCam-inspired) ───────────────────────────────
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // ── LEFT RAIL: camera controls (flash/ratio/switch) ──
        SafeArea(
          right: false,
          child: Container(
            width: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: _buildLeftRail(),
          ),
        ),

        // ── CENTER: full-bleed preview with GPS chips + zoom overlay ──
        Expanded(
          child: Stack(
            children: [
              // Camera preview fills the entire center
              Positioned.fill(child: _buildCameraPreview()),

              // Shutter flash
              if (_showShutterEffect)
                Positioned.fill(
                  child: Container(color: Colors.white.withValues(alpha: 0.8)),
                ),

              // Tap-to-focus
              Positioned.fill(child: _buildFocusOverlay()),

              // Focus reticle
              if (_isFocusing && _focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 35,
                  top: _focusPoint!.dy - 35,
                  child: const _FocusReticle(),
                ),

              // Vignette (subtle edges)
              Positioned.fill(child: _buildVignette()),

              // Compact GPS info chips — bottom-left corner FieldCam style
              Positioned(
                left: 12,
                bottom: 8,
                child: _buildCompactGpsChips(),
              ),

              // Horizontal zoom slider pinned above the GPS chips
              Positioned(
                left: 12,
                right: 12,
                bottom: 60,
                child: _buildHorizontalZoomSlider(),
              ),
            ],
          ),
        ),

        // ── RIGHT RAIL: gallery / shutter / templates (iOS-style) ──
        SafeArea(
          left: false,
          child: Container(
            width: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGalleryThumbnail(),
                _buildShutterButton(),
                _buildTemplatesButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Left vertical rail with flash / aspect ratio / camera switch — landscape only
  Widget _buildLeftRail() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Flash (disabled for front camera)
        Opacity(
          opacity: _cameraService.isFrontCamera ? 0.35 : 1.0,
          child: _ToolbarButton(
            icon: _getFlashIcon(),
            onTap: _cameraService.isFrontCamera ? null : _toggleFlash,
          ),
        ),
        // Aspect ratio pill
        GestureDetector(
          onTap: _cycleAspectRatio,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Text(
              _aspectRatio,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // Camera switch
        _ToolbarButton(
          icon: _isSwitchingCamera ? Icons.hourglass_empty : Icons.flip_camera_ios,
          onTap: _isSwitchingCamera ? null : _switchCamera,
        ),
      ],
    );
  }

  /// Compact GPS info chips overlaid on the preview — FieldCam / GPS Map Camera style
  Widget _buildCompactGpsChips() {
    final items = <({IconData icon, String label})>[];

    if (_currentPosition != null) {
      final coords = _settings.templateCoordFormat == 'Decimal Degrees (DD)'
          ? _locationService.formatCoordinatesDD(
              _currentPosition!.latitude, _currentPosition!.longitude)
          : _locationService.formatCoordinatesDMS(
              _currentPosition!.latitude, _currentPosition!.longitude);
      items.add((icon: Icons.location_on, label: coords));
    } else {
      items.add((icon: Icons.location_searching, label: 'GPS…'));
    }

    if (_currentAddress != null && _settings.templateShowAddress) {
      final short = _currentAddress!.split(',').take(2).join(', ');
      items.add((icon: Icons.place_outlined, label: short));
    }

    if (_temperature != null) {
      items.add((
        icon: Icons.thermostat_outlined,
        label: _settings.formatTemperature(_temperature),
      ));
    }

    if (_settings.templateShowDateTime) {
      final now = _currentTime;
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      items.add((icon: Icons.schedule, label: timeStr));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: AppColors.primary, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  /// Thin horizontal zoom slider for landscape mode (replaces vertical slider)
  Widget _buildHorizontalZoomSlider() {
    return Row(
      children: [
        const Icon(Icons.zoom_out, color: Colors.white54, size: 16),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white12,
            ),
            child: Slider(
              value: _zoomLevel,
              min: 0.0,
              max: 1.0,
              onChanged: (value) async {
                setState(() => _zoomLevel = value);
                await _cameraService.setZoom(value);
              },
            ),
          ),
        ),
        const Icon(Icons.zoom_in, color: Colors.white54, size: 16),
      ],
    );
  }

  // ─── SHARED SUB-WIDGETS ─────────────────────────────────────────────────────

  Widget _buildFocusOverlay() {
    return GestureDetector(
      onTapUp: (details) async {
        if (!_cameraService.isInitialized) return;
        setState(() {
          _focusPoint = details.localPosition;
          _isFocusing = true;
        });
        HapticFeedback.lightImpact();
        final size = MediaQuery.of(context).size;
        final x = details.localPosition.dx / size.width;
        final y = details.localPosition.dy / size.height;
        _cameraService.setFocusPoint(x, y);
        _cameraService.setExposurePoint(x, y);
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isFocusing = false);
        });
      },
      behavior: HitTestBehavior.translucent,
      child: const SizedBox.expand(),
    );
  }

  Widget _buildVignette() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Opacity(
            opacity: _cameraService.isFrontCamera ? 0.4 : 1.0,
            child: _ToolbarButton(
              icon: _getFlashIcon(),
              onTap: _cameraService.isFrontCamera ? null : _toggleFlash,
            ),
          ),
          GestureDetector(
            onTap: _cycleAspectRatio,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                _aspectRatio,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          _ToolbarButton(
            icon: _isSwitchingCamera ? Icons.hourglass_empty : Icons.flip_camera_ios,
            onTap: _isSwitchingCamera ? null : _switchCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildGpsHud() {
    return GpsHudCard(
      address: _currentAddress ?? 'Acquiring location...',
      coordinates: _currentPosition != null
          ? (_settings.templateCoordFormat == 'Decimal Degrees (DD)'
              ? _locationService.formatCoordinatesDD(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                )
              : _locationService.formatCoordinatesDMS(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ))
          : 'GPS Signal...',
      altitude: _currentPosition?.altitude != null
          ? _settings.formatAltitude(_currentPosition!.altitude)
          : '--',
      temperature: _temperature != null
          ? _settings.formatTemperature(_temperature)
          : '--',
      gpsSignal: _locationService.getGpsSignalStrength(_currentPosition?.accuracy),
      dateTime: _currentTime,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      heading: _currentPosition?.heading,
      showAddress: _settings.templateShowAddress,
      showCoordinates: _settings.templateShowCoordinates,
      showCompass: _settings.templateShowCompass,
      showDateTime: _settings.templateShowDateTime,
      mapType: _settings.templateMapType,
      dateFormat: _settings.templateDateFormat,
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: _isCapturing ? 56 : 64,
            height: _isCapturing ? 56 : 64,
            decoration: BoxDecoration(
              color: _isCapturing
                  ? const Color(0xFFB91C1C)
                  : const Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesButton() {
    return GestureDetector(
      onTap: _showTemplateSheet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.layers, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          const Text(
            'TEMPLATES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}


/// Top-level function for background image processing (Isolate)
void _processImageCrop(Map<String, dynamic> message) {
  final String imagePath = message['path'];
  final String ratioStr = message['ratio'];
  
  try {
    final bytes = File(imagePath).readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    
    if (image == null) return;
    
    double ratio;
    switch (ratioStr) {
      case '1:1':
        ratio = 1.0;
        break;
      case '16:9':
        ratio = 16 / 9;
        break;
      default:
        return;
    }
    
    int targetWidth, targetHeight;
    if (image.width / image.height > ratio) {
      targetHeight = image.height;
      targetWidth = (targetHeight * ratio).toInt();
    } else {
      targetWidth = image.width;
      targetHeight = (targetWidth / ratio).toInt();
    }
    
    final croppedImage = img.copyCrop(
      image,
      x: (image.width - targetWidth) ~/ 2,
      y: (image.height - targetHeight) ~/ 2,
      width: targetWidth,
      height: targetHeight,
    );
    
    File(imagePath).writeAsBytesSync(img.encodeJpg(croppedImage, quality: 90));
  } catch (e) {
    debugPrint('Background Process Error (Crop): $e');
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

/// Private widget for the animated focus reticle
class _FocusReticle extends StatefulWidget {
  const _FocusReticle();

  @override
  State<_FocusReticle> createState() => _FocusReticleState();
}

class _FocusReticleState extends State<_FocusReticle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
