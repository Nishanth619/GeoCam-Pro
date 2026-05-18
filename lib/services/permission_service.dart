import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manages all runtime permissions in a Google Play-compliant way.
///
/// **Google Play Policy notes implemented here:**
/// - Only permissions necessary for core functionality are requested.
/// - No MANAGE_EXTERNAL_STORAGE (broad permission requiring Play approval).
/// - No ACCESS_BACKGROUND_LOCATION.
/// - Storage follows the scoped-storage model:
///     Android 13+ → READ_MEDIA_IMAGES  (Permission.photos)
///     Android 10-12 → WRITE_EXTERNAL_STORAGE (Permission.storage, capped at API 32)
///     Android 10+ MediaStore saves → no runtime permission needed.
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // ─── CAMERA ────────────────────────────────────────────────────────────────

  Future<bool> hasCameraPermission() => Permission.camera.isGranted;

  /// Requests camera permission, opens settings if permanently denied.
  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    status = await Permission.camera.request();
    return status.isGranted;
  }

  // ─── LOCATION ──────────────────────────────────────────────────────────────

  Future<bool> hasLocationPermission() =>
      Permission.locationWhenInUse.isGranted;

  /// Requests location permission. Only locationWhenInUse is requested —
  /// background location is NOT requested (Play policy compliance).
  Future<bool> requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  // ─── STORAGE / MEDIA ───────────────────────────────────────────────────────

  /// Returns true if the app can read/write media.
  /// Checks BOTH Permission.photos (Android 13+) and Permission.storage (Android ≤12)
  /// so that it works regardless of OS version detection.
  Future<bool> hasMediaPermission() async {
    // Accept either modern (photos) or legacy (storage) permission
    final photosStatus = await Permission.photos.status;
    if (photosStatus.isGranted || photosStatus.isLimited) return true;
    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted;
  }

  /// Requests the correct media permission for the current Android version.
  /// Tries modern READ_MEDIA_IMAGES first, falls back to legacy storage if needed.
  Future<bool> requestMediaPermission() async {
    // Try modern photos permission first (Android 13+ / READ_MEDIA_IMAGES)
    var photosStatus = await Permission.photos.status;

    if (photosStatus.isGranted || photosStatus.isLimited) return true;

    if (!photosStatus.isPermanentlyDenied) {
      // Not yet asked — request it
      photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) return true;
    }

    // Fall back to legacy storage permission (Android ≤ 12)
    var storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;

    if (storageStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied) {
      // Both permanently denied — open settings
      await openAppSettings();
      // Re-check after returning
      final p = await Permission.photos.status;
      final s = await Permission.storage.status;
      return p.isGranted || p.isLimited || s.isGranted;
    }

    storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  // ─── COMBINED ──────────────────────────────────────────────────────────────

  /// True only when all required permissions (camera + location + storage) are granted.
  Future<bool> hasRequiredPermissions() async {
    final results = await Future.wait([
      hasCameraPermission(),
      hasLocationPermission(),
      hasMediaPermission(),
    ]);
    return results.every((granted) => granted);
  }

  /// Requests all required permissions sequentially.
  /// Returns a map of { 'camera', 'location', 'media' } → granted bool.
  Future<Map<String, bool>> requestAllPermissions() async {
    final camera = await requestCameraPermission();
    final location = await requestLocationPermission();
    final media = await requestMediaPermission();
    return {'camera': camera, 'location': location, 'media': media};
  }

  /// Returns the current permission status for the UI.
  Future<Map<String, bool>> getPermissionStatus() async {
    final results = await Future.wait([
      hasCameraPermission(),
      hasLocationPermission(),
      hasMediaPermission(),
    ]);
    return {
      'camera': results[0],
      'location': results[1],
      'storage': results[2],
    };
  }

  // ─── INTERNAL ──────────────────────────────────────────────────────────────

  /// Detects Android 13+ (API 33+) using Permission.photos availability.
  ///
  /// How it works:
  ///   - Android 13+: photos starts as [denied], becomes [granted] or [limited]
  ///   - Android 12-: photos maps to legacy storage — returns [granted] immediately
  ///   - iOS / desktop: always returns false (uses different permission model)
  ///
  /// The ONLY case where we fall back to legacy storage is [permanentlyDenied]
  /// or [restricted] — rare edge cases where opening Settings is the right path.
  Future<bool> _isAndroid13Plus() async {
    if (!defaultTargetPlatform.name.toLowerCase().contains('android')) {
      return false;
    }
    final status = await Permission.photos.status;
    // denied  → Android 13+, not yet asked
    // granted → Android 12 (auto-granted) or Android 13+ (user granted)
    // limited → Android 14+ partial access — THIS was the original bug (excluded)
    // permanentlyDenied / restricted → fall back to legacy storage path
    return !status.isPermanentlyDenied && !status.isRestricted;
  }
}
