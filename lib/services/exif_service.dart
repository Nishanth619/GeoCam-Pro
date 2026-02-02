import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:native_exif/native_exif.dart';
import 'package:intl/intl.dart';

/// Service to write EXIF metadata (GPS, timestamp) to image files
class ExifService {
  static final ExifService _instance = ExifService._internal();
  factory ExifService() => _instance;
  ExifService._internal();

  /// Write GPS coordinates and timestamp to image EXIF data
  Future<bool> writeGpsToImage({
    required String imagePath,
    required double latitude,
    required double longitude,
    double? altitude,
    DateTime? dateTime,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('Image file not found: $imagePath');
        return false;
      }

      final exif = await Exif.fromPath(imagePath);
      
      // Prepare all GPS attributes
      final Map<String, String> gpsAttributes = {
        'GPSLatitude': _formatGpsCoordinate(latitude.abs()),
        'GPSLatitudeRef': latitude >= 0 ? 'N' : 'S',
        'GPSLongitude': _formatGpsCoordinate(longitude.abs()),
        'GPSLongitudeRef': longitude >= 0 ? 'E' : 'W',
        'GPSProcessingMethod': 'GPS', // Indicate GPS was used
      };

      // Add altitude if available
      if (altitude != null) {
        gpsAttributes['GPSAltitude'] = altitude.abs().toString();
        gpsAttributes['GPSAltitudeRef'] = altitude >= 0 ? '0' : '1';
      }

      // Add GPS timestamp
      final dt = dateTime ?? DateTime.now();
      final utcTime = dt.toUtc();
      gpsAttributes['GPSTimeStamp'] = 
          '${utcTime.hour}/1,${utcTime.minute}/1,${utcTime.second}/1';
      gpsAttributes['GPSDateStamp'] = 
          '${utcTime.year}:${utcTime.month.toString().padLeft(2, '0')}:${utcTime.day.toString().padLeft(2, '0')}';

      // Write GPS attributes
      await exif.writeAttributes(gpsAttributes);

      // Write date/time attributes
      final dateFormat = DateFormat('yyyy:MM:dd HH:mm:ss');
      await exif.writeAttributes({
        'DateTimeOriginal': dateFormat.format(dt),
        'DateTimeDigitized': dateFormat.format(dt),
        'DateTime': dateFormat.format(dt),
      });

      await exif.close();
      
      debugPrint('✓ EXIF GPS data written successfully');
      debugPrint('  Lat: $latitude, Lon: $longitude, Alt: ${altitude ?? 'N/A'}');
      return true;
    } catch (e, stackTrace) {
      debugPrint('✗ Error writing EXIF: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Read GPS coordinates from image EXIF data
  Future<Map<String, double>?> readGpsFromImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final exif = await Exif.fromPath(imagePath);
      final coordinates = await exif.getLatLong();
      await exif.close();

      if (coordinates != null) {
        return {
          'latitude': coordinates.latitude,
          'longitude': coordinates.longitude,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error reading EXIF: $e');
      return null;
    }
  }

  /// Read all EXIF attributes from image
  Future<Map<String, Object>?> readAllExif(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final exif = await Exif.fromPath(imagePath);
      final attributes = await exif.getAttributes();
      await exif.close();

      return attributes;
    } catch (e) {
      debugPrint('Error reading EXIF attributes: $e');
      return null;
    }
  }

  /// Format decimal coordinate to EXIF format (degrees/minutes/seconds)
  String _formatGpsCoordinate(double decimal) {
    int degrees = decimal.floor();
    double minutesDecimal = (decimal - degrees) * 60;
    int minutes = minutesDecimal.floor();
    double seconds = (minutesDecimal - minutes) * 60;
    
    // EXIF format: "degrees/1,minutes/1,seconds*10000/10000"
    return '$degrees/1,$minutes/1,${(seconds * 10000).round()}/10000';
  }
}
