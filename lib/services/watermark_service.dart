import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/photo_model.dart';

/// Service to create watermarked versions of photos with GPS data overlay
class WatermarkService {
  static final WatermarkService _instance = WatermarkService._internal();
  factory WatermarkService() => _instance;
  WatermarkService._internal();

  /// Generate watermarked image with GPS data overlay
  /// This creates a new image file with the watermark burned in
  Future<String?> createWatermarkedImage(
    Photo photo, {
    bool showAddress = true,
    bool showCoordinates = true,
    bool showAltitude = true,
    bool showTemperature = true,
    bool showDate = true,
    bool showMiniMap = false,
    int mapType = 1,
    double opacity = 0.9,
    bool saveToGallery = false, // If true, saves to Pictures/GEOCAM PRO. If false, saves to temp.
  }) async {
    try {
      final File originalFile = File(photo.imagePath);
      if (!await originalFile.exists()) return null;

      final Uint8List imageBytes = await originalFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.Image originalImage = (await codec.getNextFrame()).image;

      // ... (Map logic unchanged) ...

      _MapResult? mapResult;
      if (showMiniMap) {
        mapResult = await _fetchHighPrecisionMap(photo.latitude, photo.longitude, mapType);
      }

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      canvas.drawImage(originalImage, Offset.zero, Paint());

      await _drawWatermarkOverlay(
        canvas,
        originalImage.width.toDouble(),
        originalImage.height.toDouble(),
        photo,
        mapResult: mapResult,
        showAddress: showAddress,
        showCoordinates: showCoordinates,
        showAltitude: showAltitude,
        showTemperature: showTemperature,
        showDate: showDate,
        opacity: opacity,
      );

      final ui.Image watermarkedImage = await recorder.endRecording().toImage(
        originalImage.width,
        originalImage.height,
      );

      // Dispose original image immediately to free memory
      originalImage.dispose();
      mapResult?.image.dispose();

      final ByteData? byteData = await watermarkedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      String exportPath;
      
      if (saveToGallery) {
        // Save to Public Gallery
        // Save to Public Gallery
        final String publicDir = await _getPicturesDirectory() ?? await _getFallbackPicturesDirectory();

        final String exportDir = path.join(publicDir, 'GEOCAM PRO');
        await Directory(exportDir).create(recursive: true);
        exportPath = path.join(exportDir, 'WM_${DateTime.now().millisecondsSinceEpoch}.png');
        await File(exportPath).writeAsBytes(byteData.buffer.asUint8List());

        // Scan file
        try {
          const platform = MethodChannel('com.geocam.geocam_flutter/media_scan');
          await platform.invokeMethod('scanFile', {'path': exportPath});
        } catch (e) {
          debugPrint('Error scanning watermark file: $e');
        }
      } else {
        // Save to Temp (for overwriting later)
        final Directory tempDir = await getTemporaryDirectory();
        final String exportDir = path.join(tempDir.path, 'watermark_temp');
        await Directory(exportDir).create(recursive: true);
        exportPath = path.join(exportDir, 'WM_${DateTime.now().millisecondsSinceEpoch}.png');
        await File(exportPath).writeAsBytes(byteData.buffer.asUint8List());
      }

      // Final cleanup
      watermarkedImage.dispose();

      return exportPath;
    } catch (e) {
      debugPrint('Error creating watermarked image: $e');
      return null;
    }
  }

  /// Fetch a 3x3 grid of tiles and return a stitched image with precise center offsets
  Future<_MapResult?> _fetchHighPrecisionMap(double lat, double lon, int mapType) async {
    try {
      const int zoom = 17; // High Detail
      final double n = math.pow(2, zoom).toDouble();
      
      // Fractional tile coordinates
      final double xFrc = ((lon + 180) / 360) * n;
      final double yFrc = (1 - math.log(math.tan(lat * math.pi / 180) + 1 / math.cos(lat * math.pi / 180)) / math.pi) / 2 * n;
      
      final int centerX = xFrc.floor();
      final int centerY = yFrc.floor();
      
      // 3x3 Grid
      final List<Future<ui.Image?>> tileFutures = [];
      for (int y = centerY - 1; y <= centerY + 1; y++) {
        for (int x = centerX - 1; x <= centerX + 1; x++) {
          tileFutures.add(_fetchSingleTile(x, y, zoom, mapType));
        }
      }

      final List<ui.Image?> tiles = await Future.wait(tileFutures);
      
      // Filter out failures
      if (tiles.any((t) => t == null)) return null;

      // Stitch tiles (3x3 grid of 256x256 = 768x768)
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      for (int i = 0; i < tiles.length; i++) {
        if (tiles[i] == null) continue;
        final double tx = (i % 3) * 256.0;
        final double ty = (i ~/ 3) * 256.0;
        canvas.drawImage(tiles[i]!, Offset(tx, ty), Paint());
      }

      final ui.Image stitched = await recorder.endRecording().toImage(768, 768);
      
      // Cleanup tile images immediately after stitching to prevent memory bloat
      for (final tile in tiles) {
        tile?.dispose();
      }
      
      // Calculate where the exact lat/lon point is in the stitched image
      // centerX-1 starts at pixel 0. So offsetX is (xFrc - (centerX-1)) * 256
      final double exactX = (xFrc - (centerX - 1)) * 256;
      final double exactY = (yFrc - (centerY - 1)) * 256;

      return _MapResult(image: stitched, centerX: exactX, centerY: exactY);
    } catch (e) {
      debugPrint('Error fetching stitched map: $e');
      return null;
    }
  }

  Future<ui.Image?> _fetchSingleTile(int x, int y, int z, int mapType) async {
    try {
      String url;
      switch (mapType) {
        case 1: // Satellite (Esri)
        case 3: // Hybrid (Simplified to Satellite for now)
          url = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/$y/$x';
          break;
        case 2: // Terrain
          url = 'https://a.tile.opentopomap.org/$z/$x/$y.png';
          break;
        case 0: // Normal
        default:
          final subdomain = ['a', 'b', 'c'][math.Random().nextInt(3)];
          url = 'https://$subdomain.tile.openstreetmap.org/$z/$x/$y.png';
      }

      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'GeoCam/1.0'}).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      
      final ui.Codec codec = await ui.instantiateImageCodec(response.bodyBytes);
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  Future<void> _drawWatermarkOverlay(
    Canvas canvas,
    double width,
    double height,
    Photo photo, {
    _MapResult? mapResult,
    required bool showAddress,
    required bool showCoordinates,
    required bool showAltitude,
    required bool showTemperature,
    required bool showDate,
    required double opacity,
  }) async {
    final double scale = width / 1080;
    final double padding = 40 * scale;
    
    final double cardWidth = width - padding * 2;
    final double cardHeight = 320 * scale;
    final double cardX = padding;
    final double cardY = height - cardHeight - padding;
    final double cornerRadius = 30 * scale;

    // Draw Card Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cardX, cardY, cardWidth, cardHeight), Radius.circular(cornerRadius)),
      Paint()..color = Colors.black.withValues(alpha: 0.82 * opacity)
    );

    // 1. Precise Mini Map (On the Right)
    final double mapSize = cardHeight - 24 * scale;
    final double mapX = cardX + cardWidth - mapSize - 12 * scale;
    final double mapY = cardY + 12 * scale;
    final RRect mapBox = RRect.fromRectAndRadius(Rect.fromLTWH(mapX, mapY, mapSize, mapSize), Radius.circular(cornerRadius - 8 * scale));

    if (mapResult != null) {
      canvas.save();
      canvas.clipRRect(mapBox);
      
      const double viewSize = 300.0;
      final srcRect = Rect.fromLTWH(
        mapResult.centerX - viewSize / 2,
        mapResult.centerY - viewSize / 2,
        viewSize,
        viewSize,
      );
      
      canvas.drawImageRect(mapResult.image, srcRect, Rect.fromLTWH(mapX, mapY, mapSize, mapSize), Paint()..filterQuality = ui.FilterQuality.high);
      
      // Add a soft inner vignette to the map for professional depth
      final Gradient vignette = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.25),
        ],
        stops: const [0.6, 0.85, 1.0],
      );
      canvas.drawRect(Rect.fromLTWH(mapX, mapY, mapSize, mapSize), Paint()..shader = vignette.createShader(Rect.fromLTWH(mapX, mapY, mapSize, mapSize)));
      
      canvas.restore();
      
      // PRO Glass Frame: Outer subtle border and inner glowing border
      canvas.drawRRect(
        mapBox, 
        Paint()..color = Colors.white.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 1.5 * scale
      );
      canvas.drawRRect(
        mapBox.shift(Offset(0.5 * scale, 0.5 * scale)), 
        Paint()..color = const Color(0xFF13ec80).withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 0.5 * scale
      );
    } else {
      canvas.drawRRect(mapBox, Paint()..color = Colors.white10);
      _drawText(canvas, '🛰️ LOADING...', mapX + 30 * scale, mapY + mapSize / 2.5, mapSize, 28 * scale, Colors.white24, fontWeight: FontWeight.bold);
    }
    
    // Tactical Crosshair Pin
    final double pinX = mapX + mapSize / 2;
    final double pinY = mapY + mapSize / 2;
    final Paint crosshairPaint = Paint()
      ..color = const Color(0xFF13ec80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;

    // Outer glow for the crosshair
    canvas.drawCircle(Offset(pinX, pinY), 15 * scale, Paint()..color = const Color(0xFF13ec80).withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 4 * scale);
    
    // Crosshair Lines
    const double lineStart = 10.0;
    const double lineLength = 12.0;
    
    // Top
    canvas.drawLine(Offset(pinX, pinY - (lineStart * scale)), Offset(pinX, pinY - ((lineStart + lineLength) * scale)), crosshairPaint);
    // Bottom
    canvas.drawLine(Offset(pinX, pinY + (lineStart * scale)), Offset(pinX, pinY + ((lineStart + lineLength) * scale)), crosshairPaint);
    // Left
    canvas.drawLine(Offset(pinX - (lineStart * scale), pinY), Offset(pinX - ((lineStart + lineLength) * scale), pinY), crosshairPaint);
    // Right
    canvas.drawLine(Offset(pinX + (lineStart * scale), pinY), Offset(pinX + ((lineStart + lineLength) * scale), pinY), crosshairPaint);

    // Center glowing dot
    canvas.drawCircle(Offset(pinX, pinY), 5 * scale, Paint()..color = const Color(0xFF13ec80));
    canvas.drawCircle(Offset(pinX, pinY), 8 * scale, Paint()..color = const Color(0xFF13ec80).withValues(alpha: 0.3));

    // 2. Text Content (On the Left)
    final double textX = cardX + 35 * scale;
    double textY = cardY + 35 * scale;
    final double maxTextWidth = cardWidth - mapSize - 70 * scale;

    // A. Title
    String title = "LOCATION DETAILS";
    if (photo.address != null) {
      final p = photo.address!.split(',');
      if (p.length >= 3) title = "${p[p.length-3].trim()}, ${p[p.length-2].trim()}, ${p[p.length-1].trim()}";
      else title = photo.address!;
    }
    if (title.toUpperCase().contains("INDIA")) title += " 🇮🇳";

    _drawText(canvas, title, textX, textY, maxTextWidth, 44 * scale, Colors.white, fontWeight: FontWeight.bold);
    textY += 60 * scale;

    // B. Address
    if (showAddress && photo.address != null) {
      final lines = _splitTextIntoLines(photo.address!, maxTextWidth, 26 * scale);
      for (final line in lines.take(2)) {
        _drawText(canvas, line, textX, textY, maxTextWidth, 26 * scale, Colors.white.withValues(alpha: 0.85 * opacity));
        textY += 34 * scale;
      }
    }
    textY += 15 * scale;

    // C. Meta Row
    String meta = "Lat ${photo.latitude.toStringAsFixed(6)}°, Long ${photo.longitude.toStringAsFixed(6)}°";
    if (showAltitude) meta += " | Elev: ${photo.altitude?.toInt() ?? 0}m";
    _drawText(canvas, meta, textX, textY, maxTextWidth, 24 * scale, Colors.white70, fontWeight: FontWeight.w500);
    textY += 38 * scale;

    // D. DateTime
    if (showDate) {
      final dateStr = DateFormat('EEEE, dd/MM/yyyy • hh:mm a').format(photo.capturedAt);
      _drawText(canvas, dateStr, textX, textY, maxTextWidth, 24 * scale, Colors.white70);
    }

    // E. Footer Branding
    _drawText(canvas, "📍 GEOCAM PRO", textX, cardY + cardHeight - 40 * scale, maxTextWidth, 20 * scale, const Color(0xFF13ec80).withValues(alpha: 0.8), fontWeight: FontWeight.bold);
  }

  List<String> _splitTextIntoLines(String text, double maxTextWidth, double fontSize) {
    final int charsPerLine = (maxTextWidth / (fontSize * 0.58)).floor();
    if (text.length <= charsPerLine) return [text];
    final List<String> result = [];
    final List<String> words = text.split(' ');
    String currentLine = "";
    for (var word in words) {
      if ((currentLine + " " + word).length <= charsPerLine) {
        currentLine = currentLine.isEmpty ? word : "$currentLine $word";
      } else {
        if (currentLine.isNotEmpty) result.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) result.add(currentLine);
    return result;
  }

  void _drawText(Canvas canvas, String text, double x, double y, double maxWidth, double fontSize, Color color, {FontWeight fontWeight = FontWeight.normal}) {
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.left, fontSize: fontSize, maxLines: 1, ellipsis: '...'))
      ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight))
      ..addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(paragraph, Offset(x, y));
  }

  Future<String> getExportsDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String exportDir = path.join(appDir.path, 'GeoCam', 'Exports');
    await Directory(exportDir).create(recursive: true);
    return exportDir;
  }

  Future<List<File>> getExportedImages() async {
    final String exportDir = await getExportsDirectory();
    final Directory dir = Directory(exportDir);
    if (!await dir.exists()) return [];
    return dir.listSync().whereType<File>().where((file) => file.path.endsWith('.png') || file.path.endsWith('.jpg')).toList();
  }


  /// Get public Pictures directory from native Android
  Future<String?> _getPicturesDirectory() async {
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
}

class _MapResult {
  final ui.Image image;
  final double centerX;
  final double centerY;
  _MapResult({required this.image, required this.centerX, required this.centerY});
}
