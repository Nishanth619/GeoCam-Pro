import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'database_service.dart';
import '../models/photo_model.dart';

/// Service to export photos with GPS data in various formats
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Export all photos as GPX file
  Future<String?> exportToGPX() async {
    try {
      final photos = await _databaseService.getAllPhotos();
      if (photos.isEmpty) return null;

      // Build the XML string in a background isolate (can be slow for large libraries)
      final content = await compute(_buildGpxString, photos);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = path.join(directory.path, 'GeoCam', 'Exports');
      await Directory(exportDir).create(recursive: true);

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = path.join(exportDir, 'geocam_$timestamp.gpx');
      await File(filePath).writeAsString(content);

      debugPrint('GPX exported to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error exporting GPX: $e');
      return null;
    }
  }

  /// Export all photos as KML file
  Future<String?> exportToKML() async {
    try {
      final photos = await _databaseService.getAllPhotos();
      if (photos.isEmpty) return null;

      final content = await compute(_buildKmlString, photos);

      final directory = await getApplicationDocumentsDirectory();
      final exportDir = path.join(directory.path, 'GeoCam', 'Exports');
      await Directory(exportDir).create(recursive: true);

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = path.join(exportDir, 'geocam_$timestamp.kml');
      await File(filePath).writeAsString(content);

      debugPrint('KML exported to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error exporting KML: $e');
      return null;
    }
  }

  /// Export photos as CSV
  Future<String?> exportToCSV() async {
    try {
      final photos = await _databaseService.getAllPhotos();
      if (photos.isEmpty) return null;

      final content = await compute(_buildCsvString, photos);

      final directory = await getApplicationDocumentsDirectory();
      final exportDir = path.join(directory.path, 'GeoCam', 'Exports');
      await Directory(exportDir).create(recursive: true);

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = path.join(exportDir, 'geocam_$timestamp.csv');
      await File(filePath).writeAsString(content);

      debugPrint('CSV exported to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return null;
    }
  }

  /// Get list of all exported files
  Future<List<File>> getExportedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory(path.join(directory.path, 'GeoCam', 'Exports'));
      if (!await exportDir.exists()) return [];

      return exportDir
          .listSync()
          .whereType<File>()
          .where((f) => 
            f.path.endsWith('.gpx') || 
            f.path.endsWith('.kml') || 
            f.path.endsWith('.csv') ||
            f.path.endsWith('.png'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
    } catch (e) {
      debugPrint('Error listing exports: $e');
      return [];
    }
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

// ─── Top-level isolate entrypoints (must be top-level or static) ────────────

String _buildGpxString(List<Photo> photos) {
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<gpx version="1.1" creator="GeoCam"');
  buffer.writeln('  xmlns="http://www.topografix.com/GPX/1/1"');
  buffer.writeln('  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
  buffer.writeln('  xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">');
  buffer.writeln('  <metadata>');
  buffer.writeln('    <name>GeoCam Photo Export</name>');
  buffer.writeln('    <time>${DateTime.now().toUtc().toIso8601String()}</time>');
  buffer.writeln('  </metadata>');
  for (final photo in photos) {
    final time = photo.capturedAt.toUtc().toIso8601String();
    buffer.writeln('  <wpt lat="${photo.latitude}" lon="${photo.longitude}">');
    if (photo.altitude != null) buffer.writeln('    <ele>${photo.altitude}</ele>');
    buffer.writeln('    <time>$time</time>');
    buffer.writeln('    <name>Photo ${photo.id}</name>');
    if (photo.address != null) buffer.writeln('    <desc>${_escapeXmlIsolate(photo.address!)}</desc>');
    buffer.writeln('  </wpt>');
  }
  buffer.writeln('</gpx>');
  return buffer.toString();
}

String _buildKmlString(List<Photo> photos) {
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
  buffer.writeln('  <Document>');
  buffer.writeln('    <name>GeoCam Photo Export</name>');
  buffer.writeln('    <description>Photos captured with GeoCam</description>');
  buffer.writeln('    <Style id="photoStyle"><IconStyle><Icon><href>http://maps.google.com/mapfiles/kml/shapes/camera.png</href></Icon></IconStyle></Style>');
  for (final photo in photos) {
    buffer.writeln('    <Placemark>');
    buffer.writeln('      <name>Photo ${photo.id}</name>');
    if (photo.address != null) buffer.writeln('      <description>${_escapeXmlIsolate(photo.address!)}</description>');
    buffer.writeln('      <styleUrl>#photoStyle</styleUrl>');
    buffer.writeln('      <TimeStamp><when>${photo.capturedAt.toUtc().toIso8601String()}</when></TimeStamp>');
    buffer.writeln('      <Point>');
    if (photo.altitude != null) {
      buffer.writeln('        <altitudeMode>absolute</altitudeMode>');
      buffer.writeln('        <coordinates>${photo.longitude},${photo.latitude},${photo.altitude}</coordinates>');
    } else {
      buffer.writeln('        <coordinates>${photo.longitude},${photo.latitude},0</coordinates>');
    }
    buffer.writeln('      </Point>');
    buffer.writeln('    </Placemark>');
  }
  buffer.writeln('  </Document>');
  buffer.writeln('</kml>');
  return buffer.toString();
}

String _buildCsvString(List<Photo> photos) {
  final buffer = StringBuffer();
  buffer.writeln('ID,Date,Time,Latitude,Longitude,Altitude,Address,Temperature,Weather,Image Path');
  final dateFormat = DateFormat('yyyy-MM-dd');
  final timeFormat = DateFormat('HH:mm:ss');
  for (final photo in photos) {
    buffer.writeln([
      photo.id ?? '',
      dateFormat.format(photo.capturedAt),
      timeFormat.format(photo.capturedAt),
      photo.latitude,
      photo.longitude,
      photo.altitude?.toStringAsFixed(1) ?? '',
      '"${photo.address?.replaceAll('"', '""') ?? ''}"',
      photo.temperature?.toStringAsFixed(1) ?? '',
      photo.weatherCondition ?? '',
      '"${photo.imagePath.replaceAll('"', '""')}"',
    ].join(','));
  }
  return buffer.toString();
}

String _escapeXmlIsolate(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
