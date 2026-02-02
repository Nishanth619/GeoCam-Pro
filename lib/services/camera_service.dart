import 'dart:async';
import 'dart:io';
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:flutter/services.dart';

/// Service to handle camera operations
class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  int _currentCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  List<CameraDescription>? get cameras => _cameras;

  /// Initialize available cameras
  Future<bool> initializeCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras available');
        return false;
      }
      debugPrint('Found ${_cameras!.length} cameras');
      return true;
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      return false;
    }
  }

  /// Initialize camera controller with specified camera
  Future<bool> initializeController({int cameraIndex = 0}) async {
    if (_cameras == null || _cameras!.isEmpty) {
      final success = await initializeCameras();
      if (!success) return false;
    }

    if (_cameras == null || _cameras!.isEmpty) return false;
    
    if (cameraIndex >= _cameras!.length) {
      cameraIndex = 0;
    }

    _currentCameraIndex = cameraIndex;

    try {
      // Dispose previous controller if exists
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      _controller = CameraController(
        _cameras![cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      // Re-apply last flash mode if supported
      if (_controller!.value.description.lensDirection == CameraLensDirection.back) {
        try {
          await _controller!.setFlashMode(_currentFlashMode);
        } catch (_) {}
      } else {
        await _controller!.setFlashMode(FlashMode.off);
      }
      
      _isInitialized = true;
      debugPrint('Camera initialized successfully');
      return true;
    } on CameraException catch (e) {
      debugPrint('CameraException: ${e.code} - ${e.description}');
      _isInitialized = false;
      return false;
    } catch (e) {
      debugPrint('Error initializing camera controller: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Switch between front and back cameras
  Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return false;

    final currentLensDirection = _cameras![_currentCameraIndex].lensDirection;
    final targetLensDirection = currentLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    int newIndex = -1;
    for (int i = 0; i < _cameras!.length; i++) {
      if (_cameras![i].lensDirection == targetLensDirection) {
        newIndex = i;
        break;
      }
    }

    // If no camera with opposite direction found, just cycle to next available
    if (newIndex == -1) {
      newIndex = (_currentCameraIndex + 1) % _cameras!.length;
    }

    _isInitialized = false;
    return initializeController(cameraIndex: newIndex);
  }

  /// Set flash mode
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null || !_isInitialized) return;
    try {
      await _controller!.setFlashMode(mode);
      _currentFlashMode = mode;
    } catch (e) {
      debugPrint('Error setting flash mode: $e');
    }
  }

  /// Check if flash is available
  bool get hasFlash {
    if (_controller == null || !_isInitialized) return false;
    return _controller!.value.description.lensDirection == CameraLensDirection.back;
  }

  /// Toggle flash mode (off -> auto -> on -> torch -> off)
  Future<FlashMode> toggleFlash() async {
    if (_controller == null || !_isInitialized) return FlashMode.off;

    final currentMode = _controller!.value.flashMode;
    FlashMode newMode;

    switch (currentMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }

    await setFlashMode(newMode);
    return newMode;
  }

  /// Set zoom level (0.0 to 1.0)
  Future<void> setZoom(double zoom) async {
    if (_controller == null || !_isInitialized) return;
    try {
      final minZoom = await _controller!.getMinZoomLevel();
      final maxZoom = await _controller!.getMaxZoomLevel();
      final targetZoom = minZoom + (maxZoom - minZoom) * zoom.clamp(0.0, 1.0);
      await _controller!.setZoomLevel(targetZoom);
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  /// Get min and max zoom levels
  Future<(double, double)> getZoomLevels() async {
    if (_controller == null || !_isInitialized) return (1.0, 1.0);
    try {
      final minZoom = await _controller!.getMinZoomLevel();
      final maxZoom = await _controller!.getMaxZoomLevel();
      return (minZoom, maxZoom);
    } catch (e) {
      return (1.0, 1.0);
    }
  }

  /// Set focus point (normalized coordinates 0.0 to 1.0)
  Future<void> setFocusPoint(double x, double y) async {
    if (_controller == null || !_isInitialized) return;
    try {
      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Error setting focus point: $e');
    }
  }

  /// Set exposure point (normalized coordinates 0.0 to 1.0)
  Future<void> setExposurePoint(double x, double y) async {
    if (_controller == null || !_isInitialized) return;
    try {
      await _controller!.setExposurePoint(Offset(x, y));
    } catch (e) {
      debugPrint('Error setting exposure point: $e');
    }
  }

  /// Capture photo and return file path
  Future<String?> capturePhoto() async {
    if (_controller == null || !_isInitialized) {
      debugPrint('Cannot capture: camera not initialized');
      return null;
    }
    if (_controller!.value.isTakingPicture) {
      debugPrint('Already taking picture');
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      
      // Get public directory via native channel
      final String publicDir = await getPicturesDirectory() ?? await _getFallbackPicturesDirectory();
      final String photosDir = path.join(publicDir, 'GEOCAM PRO');
      
      await Directory(photosDir).create(recursive: true);

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String newPath = path.join(photosDir, 'IMG_$timestamp.jpg');

      // Copy to public directory
      await File(image.path).copy(newPath);
      
      // Delete original temp file
      try {
        await File(image.path).delete();
      } catch (_) {}
      
      debugPrint('Photo saved to: $newPath');
      // Trigger media scan
      await scanFile(newPath);
      
      return newPath;
    } on CameraException catch (e) {
      debugPrint('CameraException capturing photo: ${e.code} - ${e.description}');
      return null;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  /// Get current flash mode
  FlashMode get currentFlashMode =>
      _controller?.value.flashMode ?? FlashMode.off;

  /// Check if current camera is front-facing
  bool get isFrontCamera {
    if (_cameras == null || _cameras!.isEmpty) return false;
    return _cameras![_currentCameraIndex].lensDirection ==
        CameraLensDirection.front;
  }

  /// Dispose camera controller
  Future<void> dispose() async {
    _isInitialized = false;
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }


  /// Scan file to make it visible in gallery
  Future<void> scanFile(String path) async {
    try {
      const platform = MethodChannel('com.geocam.geocam_flutter/media_scan');
      await platform.invokeMethod('scanFile', {'path': path});
    } catch (e) {
      debugPrint('Error scanning file: $e');
    }
  }

  /// Get public Pictures directory from native Android
  Future<String?> getPicturesDirectory() async {
    try {
      const platform = MethodChannel('com.geocam.geocam_flutter/media_scan');
      final String? path = await platform.invokeMethod('getPicturesDirectory');
      return path;
    } catch (e) {
      debugPrint('Error getting pictures directory: $e');
      return null;
    }
  }

  /// Fallback to App Documents if native call fails
  Future<String> _getFallbackPicturesDirectory() async {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
  }

  /// Reinitialize camera (useful after permission granted)
  Future<bool> reinitialize() async {
    await dispose();
    return initializeController(cameraIndex: _currentCameraIndex);
  }
}
