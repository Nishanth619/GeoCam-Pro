import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;

import 'package:sensors_plus/sensors_plus.dart';
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
import 'package:geocam_flutter/l10n/app_localizations.dart';
import 'template_customization_sheet.dart';
import 'gallery_screen.dart';
import 'edit_location_screen.dart';
import 'import_geotag_screen.dart';

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
  bool _lastPhotoExists = false; // Cached existsSync() result — avoids disk I/O in build()

  // NOTE: The 1-Hz clock is now managed by _LiveClockWidget below.
  // CameraScreen no longer has a _timeUpdateTimer that rebuilds the whole tree.

  // Focus state
  Offset? _focusPoint;
  bool _isFocusing = false;
  Timer? _focusTimer;

  // HUD orientation — sensor-driven, portrait-locked screen
  double _hudRotationTurns = 0.0; // 0 = portrait, ±0.25 = landscape
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Lock this screen to portrait; HUD rotates via sensor instead
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initializeAll();
    _startSensorOrientation();
  }

  /// Listens to the accelerometer and updates [_hudRotationTurns].
  /// Uses gravity-based detection: when the phone is sideways, the X-axis
  /// gets the bulk of gravity (~9.8 m/s²) while Y-axis drops close to 0.
  /// Threshold: |X| must dominate |Y| **and** exceed 4.5 m/s² (~27° from horizontal).
  void _startSensorOrientation() {
    _sensorSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen((AccelerometerEvent event) {
      double turns;
      if (event.x.abs() > event.y.abs() && event.x.abs() > 3.0) {
        turns = event.x > 0 ? -0.25 : 0.25;
      } else {
        turns = 0.0;
      }
      // Guard debug log behind kDebugMode — toStringAsFixed allocates even in release
      if (kDebugMode) {
        debugPrint('🧭 Sensor → x=${event.x.toStringAsFixed(2)} y=${event.y.toStringAsFixed(2)} → turns=$turns _current=$_hudRotationTurns');
      }
      if (_hudRotationTurns != turns && mounted) {
        setState(() => _hudRotationTurns = turns);
      }
    });
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    _sensorSubscription?.cancel();
    _cameraService.dispose();
    // Restore all orientations when leaving the camera screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(silent: true);
      // If location was never started (e.g. user granted permission via Settings
      // after first-launch denial), restart it now.
      if (_positionSubscription == null) {
        _startLocationUpdates();
      }
    }
  }

  Future<void> _initializeAll() async {
    await _initializeCamera(); // requests camera permission internally
    await _startLocationUpdates(); // requests location permission internally
    _loadLastPhoto();
  }

  Future<void> _loadLastPhoto() async {
    final photos = await _databaseService.getAllPhotos();
    if (photos.isNotEmpty && mounted) {
      final photo = photos.first;
      setState(() {
        _lastPhoto = photo;
        _lastPhotoExists = File(photo.imagePath).existsSync();
      });
    }
  }

  /// Initializes the camera.
  /// [silent] = true: called from lifecycle/auto-resume. Errors are suppressed
  ///   and a quiet retry is attempted. No red overlay is shown for transient failures.
  /// [silent] = false (default): called on first launch or manual retry.
  ///   Shows the error overlay if all retries fail.
  Future<void> _initializeCamera({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isCameraInitializing = true;
        _cameraError = null;
      });
    }

    // ── Permission gate ───────────────────────────────────────────────────────
    // ALWAYS request permissions before init (not just when denied).
    // On a fresh release install the permission is not yet granted and the
    // camera driver returns a grey texture if opened before Android has
    // propagated the grant. We await the dialog result first.
    if (!silent) {
      final cameraGranted = await _permissionService.requestCameraPermission();
      await _permissionService.requestMediaPermission();

      if (!cameraGranted) {
        // User denied camera — show error immediately, no point initialising.
        if (mounted) {
          setState(() {
            _isCameraInitializing = false;
            _cameraError =
                'Camera permission is required.\nPlease enable it in Settings.';
          });
        }
        return;
      }

      // Give Android ~300 ms to propagate the newly-granted camera permission
      // to the camera HAL before we open the device.  Without this delay some
      // devices (especially Xiaomi / MIUI) open the camera before the driver
      // has finished registering the grant and return a grey preview.
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Camera service already has 3-attempt retry logic internally
    final success = await _cameraService.initializeController();

    if (!mounted) return;

    if (success) {
      // Clear any lingering error on successful init
      setState(() {
        _isCameraInitializing = false;
        _cameraError = null;
        _zoomLevel = 0.0;
      });
    } else if (!silent) {
      // Only show the red error overlay if this was an explicit (non-silent) call
      setState(() {
        _isCameraInitializing = false;
        _cameraError = 'Failed to initialize camera.\nPlease check permissions in Settings.';
      });
    }
    // If silent && failed: do nothing — camera will look frozen but no scary red screen
  }

  Future<void> _startLocationUpdates() async {
    // Request permission — on a fresh install it may not be granted yet.
    final hasPermission = await _permissionService.hasLocationPermission();
    if (!hasPermission) {
      final granted = await _permissionService.requestLocationPermission();
      if (!granted) {
        debugPrint('Location permission denied — GPS HUD will be empty.');
        return;
      }
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
          SnackBar(
            content: const Text(
              'Flash not supported on this camera',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: const Color(0xFF1A2332),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
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

    // ⚡ SNAPSHOT both orientation AND datetime NOW at shutter press.
    // capturedAt must be read here — before any async gaps — so the
    // manual override value can't be cleared between press and processing.
    final double shutterRotationTurns = _hudRotationTurns;
    final DateTime shutterCapturedAt = _locationService.effectiveDateTime;
    debugPrint('📸 SHUTTER → rotationTurns=$shutterRotationTurns | capturedAt=$shutterCapturedAt | isManualDT=${_locationService.isManualDateTimeActive}');

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
        // Pass BOTH snapshotted values — rotation AND capturedAt
        unawaited(_processCapturedPhoto(imagePath, shutterRotationTurns, shutterCapturedAt));

        // ONE-SHOT RESET: After stamping the photo with any custom overrides,
        // immediately clear them so the next photo uses real GPS + today's date.
        if (_locationService.isManualOverrideActive) {
          _locationService.clearManualOverride();
          debugPrint('📍 One-shot location override consumed — returning to GPS.');
        }
        if (_locationService.isManualDateTimeActive) {
          _locationService.clearManualDateTime();
          debugPrint('🕐 One-shot datetime override consumed — returning to system time.');
        }
        if (mounted) setState(() {}); // Refresh HUD to remove amber tint

        // Monetization: Trigger Interstitial ad logic
        _adService.onPhotoCaptured();
      }
    } catch (e) {
      debugPrint('Error during shutter action: $e');
      setState(() {
        _isCapturing = false;
      });
    }
  }

  /// Background pipeline for heavy image processing.
  /// [rotationTurns] and [capturedAt] are both snapshotted at shutter-press
  /// time so async gaps cannot affect them.
  Future<void> _processCapturedPhoto(
      String imagePath, double rotationTurns, DateTime capturedAt) async {
    try {
      // All values are snapshotted — no reads from live state after this point.
      final position = _locationService.effectivePosition;
      final address = _locationService.isManualOverrideActive
          ? _locationService.manualOverrideAddress
          : _currentAddress;
      final temp = _temperature;
      final weather = _weatherCondition;
      final currentAspectRatio = _aspectRatio;
      debugPrint('📸 PROCESSING → capturedAt=$capturedAt | rotationTurns=$rotationTurns');
      debugPrint('📍 Using ${_locationService.isManualOverrideActive ? "MANUAL" : "GPS"} position: ${position?.latitude}, ${position?.longitude}');

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
          rotationTurns: rotationTurns,
        );
        debugPrint('🎨 Watermark done. rotationTurns=$rotationTurns → path=${watermarkedPath ?? "FAILED"}');

        if (watermarkedPath != null) {
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
        final savedPhoto = photo.copyWith(id: id);
        setState(() {
          _lastPhoto = savedPhoto;
          _lastPhotoExists = File(savedPhoto.imagePath).existsSync();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Photo processed and saved!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A2332),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
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

    if (_cameraService.isInitialized && 
        _cameraService.controller != null && 
        _cameraService.controller!.value.isInitialized) {
      // Show overlay when switching cameras
      if (_isSwitchingCamera) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.cameraSwitching,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
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
          // Use cached _lastPhotoExists — avoids synchronous disk I/O in build()
          image: _lastPhotoExists
              ? DecorationImage(
                  image: FileImage(File(_lastPhoto!.imagePath)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: !_lastPhotoExists
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildPortraitLayout(),
    );
  }

  // ─── PORTRAIT LAYOUT (original) ────────────────────────────────────────────
  Widget _buildPortraitLayout() {
    return Stack(
      children: [
        // RepaintBoundary isolates the camera texture from UI overlay updates.
        // When the HUD, toolbar, or clock changes, the GPU composites independently
        // and never re-rasterizes the camera video stream.
        RepaintBoundary(child: Positioned.fill(child: _buildCameraPreview())),

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

        // GPS HUD — edge-anchored, sensor-driven orientation
        // Clock ticks and GPS updates won't repaint the camera preview
        _buildOrientedHud(),

        // Bottom controls (shutter row)
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
                  const SizedBox(height: 12),
                  // ── SHUTTER ROW ───────────────────────────────────────
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

  // ─── ORIENTATION-AWARE HUD ───────────────────────────────────────────────────
  // NOTE: We deliberately do NOT use AnimatedSwitcher here.
  // AnimatedSwitcher keeps both the old and new child in the widget tree
  // simultaneously during the cross-fade. This means two GpsHudCard (and thus
  // two FlutterMap) instances are live at once → Flutter throws a
  // "Duplicate GlobalKey" crash. Instant switch is safer.
  Widget _buildOrientedHud() {
    final screenH = MediaQuery.of(context).size.height;
    // Landscape HUD occupies 62% of the long screen edge — wide enough to read, compact enough to not crowd the preview
    final double landscapeHudWidth = screenH * 0.62;

    if (_hudRotationTurns == -0.25) {
      // Tilted LEFT — HUD anchored to left edge, text reads upward
      return Positioned.fill(
        child: Align(
          alignment: Alignment.centerLeft,
          child: RotatedBox(
            quarterTurns: 1,
            child: SizedBox(
              width: landscapeHudWidth,
              child: RepaintBoundary(child: _buildGpsHud(isLandscape: true)),
            ),
          ),
        ),
      );
    } else if (_hudRotationTurns == 0.25) {
      // Tilted RIGHT — HUD anchored to right edge, text reads downward
      return Positioned.fill(
        child: Align(
          alignment: Alignment.centerRight,
          child: RotatedBox(
            quarterTurns: 3,
            child: SizedBox(
              width: landscapeHudWidth,
              child: RepaintBoundary(child: _buildGpsHud(isLandscape: true)),
            ),
          ),
        ),
      );
    } else {
      // Portrait — normal bottom position
      return Positioned(
        left: 0,
        right: 0,
        bottom: 116,
        child: RepaintBoundary(child: _buildGpsHud(isLandscape: false)),
      );
    }
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

  // Static vignette — never changes, so we cache it as a class-level constant
  // to avoid rebuilding a gradient on every setState tick.
  static const Widget _vignette = IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x40000000), // black 25%
            Colors.transparent,
            Colors.transparent,
            Color(0x80000000), // black 50%
          ],
          stops: [0.0, 0.15, 0.8, 1.0],
        ),
      ),
    ),
  );

  Widget _buildVignette() => _vignette;

  Widget _buildTopToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.35),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Import & Geo-Tag button
              _ToolbarButton(
                icon: Icons.add_photo_alternate_outlined,
                onTap: _openImportGeotag,
              ),
              const SizedBox(width: 8),
              // Edit Location button — amber tint when manual override is active
              _EditLocationButton(
                isManualActive: _locationService.isManualOverrideActive,
                onTap: _openEditLocation,
              ),
              const SizedBox(width: 8),
              _ToolbarButton(
                icon: _isSwitchingCamera ? Icons.hourglass_empty : Icons.flip_camera_ios,
                onTap: _isSwitchingCamera ? null : _switchCamera,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openEditLocation() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => const EditLocationScreen(),
        ))
        .then((_) {
      if (!mounted) return;
      setState(() {});
      // Show confirmation SnackBar so the user can verify what was saved.
      if (_locationService.isManualDateTimeActive) {
        final dt = _locationService.effectiveDateTime;
        final label =
            '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}  '
            '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.schedule,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Custom datetime set: $label',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ]),
            backgroundColor: const Color(0xFF1A2332),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _openImportGeotag() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => const ImportGeotagScreen(),
        ))
        .then((_) {
      // Refresh last-photo thumbnail after import
      if (mounted) _loadLastPhoto();
    });
  }

  Widget _buildGpsHud({bool isLandscape = false}) {
    // Camera preview ALWAYS shows live GPS position and current system time.
    // Custom overrides (set in EditLocationScreen) only apply at the moment
    // of capture (shutter press) — not to the live preview HUD.
    final livePosition = _currentPosition;
    final l10n = AppLocalizations.of(context)!;
    final displayAddress = _currentAddress ?? l10n.acquiringLocation;
    return GpsHudCard(
      isLandscape: isLandscape,
      address: displayAddress,
      coordinates: livePosition != null
          ? (_settings.templateCoordFormat == 'Decimal Degrees (DD)'
              ? _locationService.formatCoordinatesDD(
                  livePosition.latitude,
                  livePosition.longitude,
                )
              : _locationService.formatCoordinatesDMS(
                  livePosition.latitude,
                  livePosition.longitude,
                ))
          : l10n.noGpsSignal,
      altitude: livePosition?.altitude != null
          ? _settings.formatAltitude(livePosition!.altitude)
          : '--',
      temperature: _temperature != null
          ? _settings.formatTemperature(_temperature)
          : '--',
      gpsSignal: _locationService.getGpsSignalStrength(_currentPosition?.accuracy),
      dateTime: null,        // null → GpsHudCard owns its own 1-Hz clock timer
      isManualDateTime: false,  // Never show "CUSTOM" badge in live preview
      latitude: livePosition?.latitude,
      longitude: livePosition?.longitude,
      heading: livePosition?.heading,
      showAddress: _settings.templateShowAddress,
      showCoordinates: _settings.templateShowCoordinates,
      showCompass: _settings.templateShowCompass,
      showDateTime: _settings.templateShowDateTime,
      mapType: _settings.templateMapType,
      dateFormat: _settings.templateDateFormat,
      isManualLocation: false, // Never show "MANUAL" badge in live preview
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
        // Sensor captures incoming image as portrait (width < height).
        // For a 16:9 aspect ratio output, the portrait crop must be 9:16.
        ratio = 9 / 16;
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

/// Toolbar button for "Edit Location" — glows amber when override is active.
class _EditLocationButton extends StatelessWidget {
  final bool isManualActive;
  final VoidCallback? onTap;

  const _EditLocationButton({required this.isManualActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isManualActive
              ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: isManualActive
              ? Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                  width: 1.5)
              : null,
          boxShadow: isManualActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    blurRadius: 12,
                  )
                ]
              : null,
        ),
        child: Icon(
          Icons.edit_location_alt_outlined,
          color: isManualActive ? const Color(0xFFF59E0B) : Colors.white,
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
