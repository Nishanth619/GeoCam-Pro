import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_service.dart';

/// Service to handle location operations with offline fallback
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastPosition;

  // ============= Manual Location Override =============
  // When set, all app features (watermark, EXIF, HUD) use this instead of GPS.
  Position? _manualOverridePosition;
  String? _manualOverrideAddress;

  /// True when the user has manually pinned a location.
  bool get isManualOverrideActive => _manualOverridePosition != null;

  /// The address string for the manual pin (reverse-geocoded by EditLocationScreen).
  String? get manualOverrideAddress => _manualOverrideAddress;

  /// Returns the manual position if active, otherwise the last real GPS fix.
  Position? get effectivePosition =>
      _manualOverridePosition ?? _lastPosition;

  /// Sets a manual location override.
  /// [address] should be the reverse-geocoded address string.
  void setManualOverride(double lat, double lng, String address) {
    // Build a synthetic Position object so the rest of the app treats it uniformly.
    _manualOverridePosition = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    _manualOverrideAddress = address;
    debugPrint('📍 Manual location override set: $lat, $lng — "$address"');
  }

  /// Clears the manual override and returns to live GPS.
  void clearManualOverride() {
    _manualOverridePosition = null;
    _manualOverrideAddress = null;
    debugPrint('📍 Manual location override cleared — returning to GPS');
  }

  // ============= Manual Date/Time Override =============
  // When set, photos are stamped with this date/time instead of DateTime.now().
  DateTime? _manualDateTime;

  static const String _keyManualDateTime = 'manual_datetime_override';

  /// Load persisted manual datetime from SharedPreferences on startup.
  Future<void> loadPersistedDateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_keyManualDateTime);
      if (stored != null) {
        _manualDateTime = DateTime.tryParse(stored);
        debugPrint('🕐 Loaded persisted manual datetime: $_manualDateTime');
      }
    } catch (e) {
      debugPrint('🕐 Could not load persisted datetime: $e');
    }
  }

  /// True when the user has set a custom capture date/time.
  bool get isManualDateTimeActive => _manualDateTime != null;

  /// The manually set date/time override.
  DateTime? get manualDateTime => _manualDateTime;

  /// Returns the manual date/time if set, otherwise the current system time.
  DateTime get effectiveDateTime => _manualDateTime ?? DateTime.now();

  /// Sets a custom date/time that will be stamped on the next captured photo.
  void setManualDateTime(DateTime dt) {
    _manualDateTime = dt;
    debugPrint('🕐 Manual date/time override set: $dt');
    // Persist immediately so it survives any state transitions.
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_keyManualDateTime, dt.toIso8601String()),
    );
  }

  /// Clears the manual date/time override and returns to system time.
  void clearManualDateTime() {
    _manualDateTime = null;
    debugPrint('🕐 Manual date/time override cleared — returning to system time');
    SharedPreferences.getInstance().then(
      (prefs) => prefs.remove(_keyManualDateTime),
    );
  }

  // Offline geocoding cache (store last 100 lookups)
  static final Map<String, String> _geocodeCache = {};
  static const int _maxCacheSize = 100;

  Position? get lastPosition => _lastPosition;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Check and request location permissions
  Future<bool> checkAndRequestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  /// Get the fastest possible position (last known)
  Future<Position?> getLastKnownPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return _lastPosition;

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _lastPosition = lastKnown;
        return lastKnown;
      }
      return _lastPosition;
    } catch (e) {
      debugPrint('Error getting last known: $e');
      return _lastPosition;
    }
  }

  /// Get current position with high accuracy
  Future<Position?> getCurrentPosition({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return _lastPosition;

      // Use platform-specific settings for best accuracy
      LocationSettings locationSettings;
      if (Platform.isAndroid) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 1),
        );
      } else if (Platform.isIOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(timeout);
      
      _lastPosition = position;
      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return _lastPosition;
    }
  }

  /// Stream position updates in real-time with high accuracy
  Stream<Position>? getPositionStream() {
    try {
      LocationSettings locationSettings;
      
      if (Platform.isAndroid) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0, // Update on any movement
          forceLocationManager: false, // Use Fused Location Provider
          intervalDuration: const Duration(seconds: 1),
        );
      } else if (Platform.isIOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
          activityType: ActivityType.other,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        );
      }
      
      return Geolocator.getPositionStream(
        locationSettings: locationSettings,
      );
    } catch (e) {
      debugPrint('Error creating position stream: $e');
      return null;
    }
  }

  /// Convert coordinates to address with offline fallback
  Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    // Generate cache key (rounded to 4 decimal places = ~10m precision)
    final cacheKey = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
    
    // Check cache first (offline fallback)
    if (_geocodeCache.containsKey(cacheKey)) {
      debugPrint('Using cached address for $cacheKey');
      return _geocodeCache[cacheKey];
    }

    try {
      final appLang = SettingsService().appLanguage;
      final localeIdentifier = appLang == 'auto' ? null : (appLang == 'tl' ? 'en_US' : '${appLang}_$appLang'.toUpperCase());

      if (localeIdentifier != null) {
        await setLocaleIdentifier(localeIdentifier);
      }
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        // Debug: Print all available placemark data
        debugPrint('Placemark data:');
        debugPrint('  name: ${place.name}');
        debugPrint('  street: ${place.street}');
        debugPrint('  subThoroughfare: ${place.subThoroughfare}');
        debugPrint('  thoroughfare: ${place.thoroughfare}');
        debugPrint('  subLocality: ${place.subLocality}');
        debugPrint('  locality: ${place.locality}');
        debugPrint('  postalCode: ${place.postalCode}');
        debugPrint('  administrativeArea: ${place.administrativeArea}');
        debugPrint('  country: ${place.country}');
        
        List<String> addressParts = [];
        
        // Building/House number + Street name
        String streetPart = '';
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          streetPart = place.subThoroughfare!;
        }
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          if (streetPart.isNotEmpty) {
            streetPart += ', ${place.thoroughfare}';
          } else {
            streetPart = place.thoroughfare!;
          }
        } else if (place.street != null && place.street!.isNotEmpty && streetPart.isEmpty) {
          streetPart = place.street!;
        }
        
        if (streetPart.isNotEmpty) {
          addressParts.add(streetPart);
        }
        
        // Neighborhood/Sub-locality
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        
        // City
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        
        // State/Province with Postal Code
        String statePostal = '';
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          statePostal = place.administrativeArea!;
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          if (statePostal.isNotEmpty) {
            statePostal += ' ${place.postalCode}';
          } else {
            statePostal = place.postalCode!;
          }
        }
        if (statePostal.isNotEmpty) {
          addressParts.add(statePostal);
        }
        
        // Country
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        
        final address = addressParts.join(', ');
        
        // Cache the result for offline use
        _addToCache(cacheKey, address);
        
        debugPrint('Got address: $address');
        return address;
      }
      return _getOfflineFallbackAddress(lat, lon);
    } catch (e) {
      debugPrint('Error getting address (using fallback): $e');
      return _getOfflineFallbackAddress(lat, lon);
    }
  }

  /// Convert address text to coordinates (Forward Geocoding)
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates from address: $e');
      return null;
    }
  }

  /// Get autocomplete suggestions from Photon (Komoot) API — production grade.
  /// • 8-second network timeout prevents UI hangs on slow connections.
  /// • Deduplicates results by rounded coordinates (~11m precision).
  /// • Builds richly structured display names (street → city → state → country).
  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final appLang = SettingsService().appLanguage;
      final langCode = appLang == 'auto' || appLang == 'tl' ? 'en' : appLang;

      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query.trim())}&limit=10&lang=$langCode',
      );

      final response = await http
          .get(url, headers: {
            'User-Agent': 'GeocamPro/1.0 (geocam.app)',
            'Accept-Language': '$langCode,en;q=0.9',
          })
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> features = data['features'] ?? [];

      final seen = <String>{};
      final results = <Map<String, dynamic>>[];

      for (final item in features) {
        final props = (item['properties'] ?? {}) as Map<String, dynamic>;
        final geometry = item['geometry'];
        if (geometry == null) continue;
        final coords = geometry['coordinates'];
        if (coords == null || coords is! List || coords.length < 2) continue;

        final lat = (coords[1] as num).toDouble();
        final lon = (coords[0] as num).toDouble();

        // Deduplicate by rounded coordinate key (~11m grid)
        final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
        if (seen.contains(key)) continue;
        seen.add(key);

        // Build a rich display name: most specific → least specific
        final street  = props['street']  as String? ?? '';
        final housenr = props['housenumber'] as String? ?? '';
        final name    = props['name']    as String? ?? '';
        final district= props['district'] as String? ?? '';
        final city    = (props['city'] ?? props['town'] ?? props['village'] ?? '') as String;
        final state   = props['state']   as String? ?? '';
        final country = props['country'] as String? ?? '';

        // First part: most specific label
        final primary = [
          if (housenr.isNotEmpty && street.isNotEmpty) '$housenr $street'
          else if (street.isNotEmpty) street
          else if (name.isNotEmpty) name,
        ].join();

        final parts = <String>[
          if (primary.isNotEmpty) primary,
          if (district.isNotEmpty && district != city) district,
          if (city.isNotEmpty) city,
          if (state.isNotEmpty && state != city) state,
          if (country.isNotEmpty) country,
        ];

        // Preserve insertion order — no Set (we already dedup by coords)
        final displayName = parts.isEmpty ? 'Unknown Location' : parts.join(', ');

        results.add({
          'display_name': displayName,
          'lat': lat,
          'lon': lon,
        });

        if (results.length >= 6) break; // cap at 6 clean results
      }

      return results;
    } on TimeoutException {
      debugPrint('Address suggestion request timed out');
      return [];
    } catch (e) {
      debugPrint('Error getting address suggestions: $e');
      return [];
    }
  }

  /// Add to cache with size limit
  void _addToCache(String key, String value) {
    // Remove oldest entries if cache is full
    if (_geocodeCache.length >= _maxCacheSize) {
      final keysToRemove = _geocodeCache.keys.take(20).toList();
      for (final k in keysToRemove) {
        _geocodeCache.remove(k);
      }
    }
    _geocodeCache[key] = value;
  }

  /// Generate offline fallback address from coordinates
  String _getOfflineFallbackAddress(double lat, double lon) {
    // Determine general region based on coordinates
    final latDir = lat >= 0 ? 'N' : 'S';
    final lonDir = lon >= 0 ? 'E' : 'W';
    
    // Rough continent/region detection
    String region = _detectRegion(lat, lon);
    
    return '$region • ${lat.abs().toStringAsFixed(2)}°$latDir, ${lon.abs().toStringAsFixed(2)}°$lonDir';
  }

  /// Detect approximate region from coordinates (offline)
  String _detectRegion(double lat, double lon) {
    // North America
    if (lat >= 15 && lat <= 72 && lon >= -168 && lon <= -52) {
      return 'North America';
    }
    // South America
    if (lat >= -56 && lat < 15 && lon >= -82 && lon <= -35) {
      return 'South America';
    }
    // Europe
    if (lat >= 35 && lat <= 71 && lon >= -10 && lon <= 40) {
      return 'Europe';
    }
    // Africa
    if (lat >= -35 && lat <= 37 && lon >= -18 && lon <= 52) {
      return 'Africa';
    }
    // Asia
    if (lat >= 5 && lat <= 77 && lon >= 40 && lon <= 180) {
      return 'Asia';
    }
    // India subcontinent specifically
    if (lat >= 6 && lat <= 36 && lon >= 68 && lon <= 98) {
      return 'South Asia';
    }
    // Australia
    if (lat >= -47 && lat <= -10 && lon >= 112 && lon <= 154) {
      return 'Australia';
    }
    // Antarctica
    if (lat < -60) {
      return 'Antarctica';
    }
    // Default
    return 'Location';
  }

  /// Format coordinates as Decimal Degrees (6 decimal places for precision)
  String formatCoordinatesDD(double lat, double lon) {
    String latDir = lat >= 0 ? 'N' : 'S';
    String lonDir = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(6)}° $latDir, ${lon.abs().toStringAsFixed(6)}° $lonDir';
  }

  /// Format coordinates as Degrees Minutes Seconds
  String formatCoordinatesDMS(double lat, double lon) {
    String latDir = lat >= 0 ? 'N' : 'S';
    String lonDir = lon >= 0 ? 'E' : 'W';
    
    String latDMS = _decimalToDMS(lat.abs());
    String lonDMS = _decimalToDMS(lon.abs());
    
    return '$latDMS $latDir, $lonDMS $lonDir';
  }

  String _decimalToDMS(double decimal) {
    int degrees = decimal.floor();
    double minutesDecimal = (decimal - degrees) * 60;
    int minutes = minutesDecimal.floor();
    double seconds = (minutesDecimal - minutes) * 60;
    
    return '$degrees°${minutes.toString().padLeft(2, '0')}\'${seconds.toStringAsFixed(1)}"';
  }

  /// Get GPS signal strength description
  String getGpsSignalStrength(double? accuracy) {
    if (accuracy == null) return 'ACQUIRING';
    if (accuracy <= 10) return 'HIGH';
    if (accuracy <= 30) return 'GOOD';
    if (accuracy <= 100) return 'MEDIUM';
    return 'LOW';
  }

  /// Calculate distance between two points in meters
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate bearing between two points
  double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  /// Get compass direction from bearing
  String bearingToCompass(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Clear geocode cache
  void clearCache() {
    _geocodeCache.clear();
    debugPrint('Geocode cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _geocodeCache.length,
      'maxSize': _maxCacheSize,
    };
  }
}
