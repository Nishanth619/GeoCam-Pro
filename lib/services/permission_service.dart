import 'package:permission_handler/permission_handler.dart';

/// Service to handle all app permissions
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    return await Permission.location.isGranted ||
        await Permission.locationWhenInUse.isGranted;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      return true;
    }
    
    // If denied, try again or check if permanently denied
    if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  /// Request all required permissions
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return await [
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.storage,
      Permission.photos,
    ].request();
  }

  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    // For Android 13+ (API 33+), we need READ_MEDIA_IMAGES permission
    // For Android 10-12 (API 29-32), we need WRITE_EXTERNAL_STORAGE
    // For Android 9 and below (API 28-), we need WRITE_EXTERNAL_STORAGE
    
    // Check photos permission first (Android 13+)
    if (await Permission.photos.isGranted) {
      return true;
    }
    
    // Check storage permission (Android 12 and below)
    if (await Permission.storage.isGranted) {
      return true;
    }
    
    // If neither is granted, return false
    return false;
  }

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    // Request both to cover different Android versions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
    ].request();
    
    return statuses[Permission.storage] == PermissionStatus.granted || 
           statuses[Permission.photos] == PermissionStatus.granted;
  }

  /// Check if all required permissions are granted
  Future<bool> hasAllRequiredPermissions() async {
    final camera = await hasCameraPermission();
    final location = await hasLocationPermission();
    // Storage is technically optional for core function but required for this feature
    // For now we keep it strict for the "Getting Started" flow
    final storage = await hasStoragePermission(); 
    return camera && location && storage;
  }

  /// Get detailed permission status for UI
  Future<Map<String, bool>> getPermissionStatus() async {
    return {
      'camera': await hasCameraPermission(),
      'location': await hasLocationPermission(),
      'storage': await hasStoragePermission(),
    };
  }
}
