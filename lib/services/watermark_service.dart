import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/photo_model.dart';
import 'settings_service.dart';

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
    double rotationTurns = 0.0, // Used to rotate the image physically into landscape
  }) async {
    try {
      final File originalFile = File(photo.imagePath);
      if (!await originalFile.exists()) return null;

      final Uint8List imageBytes = await originalFile.readAsBytes();

      // ────────────────────────────────────────────────────────────────────────
      // ORIENTATION DETECTION — Sensor-only (simple and reliable)
      // ────────────────────────────────────────────────────────────────────────
      // The accelerometer sensor value was snapshotted at the EXACT moment the
      // shutter was pressed. This is the single source of truth.
      //
      // EXIF and bakeOrientation are unreliable:
      //   - Realme writes EXIF Orientation=0 (non-standard, does nothing)
      //   - bakeOrientation has no effect when Orientation=0
      //   - Both add ~200ms of unnecessary processing
      //
      // Sensor values: 0.0 = portrait, -0.25 or 0.25 = landscape
      // ────────────────────────────────────────────────────────────────────────

      final bool isLandscape = (rotationTurns == -0.25 || rotationTurns == 0.25);
      debugPrint('🖼️ ORIENTATION: rotationTurns=$rotationTurns → isLandscape=$isLandscape');

      // ── BUILD THE CANVAS ──
      // Use Flutter codec for the canvas image (it's fast for drawing),
      // but compute correct dimensions based on our orientation detection.
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.Image originalImage = (await codec.getNextFrame()).image;

      final double rawW = originalImage.width.toDouble();
      final double rawH = originalImage.height.toDouble();

      // If landscape detected but raw image is portrait pixels → swap dimensions
      // and rotate the canvas
      final bool needsRotation = isLandscape && rawW < rawH;
      final double canvasWidth  = needsRotation ? rawH : rawW;
      final double canvasHeight = needsRotation ? rawW : rawH;

      debugPrint('🖼️ WatermarkService: needsRotation=$needsRotation '
          'canvas=${canvasWidth.toInt()}x${canvasHeight.toInt()} '
          'raw=${rawW.toInt()}x${rawH.toInt()}');

      _MapResult? mapResult;
      if (showMiniMap) {
        mapResult = await _fetchHighPrecisionMap(photo.latitude, photo.longitude, mapType);
      }

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw image with rotation if needed
      canvas.save();
      if (needsRotation) {
        // Determine rotation direction from sensor
        if (rotationTurns == 0.25) {
          // 90° CW (phone tilted right)
          canvas.translate(canvasWidth, 0);
          canvas.rotate(math.pi / 2);
        } else {
          // 90° CCW (phone tilted left, default landscape)
          canvas.translate(0, canvasHeight);
          canvas.rotate(-math.pi / 2);
        }
      }
      canvas.drawImage(originalImage, Offset.zero, Paint());
      canvas.restore();

      await _drawWatermarkOverlay(
        canvas,
        canvasWidth,
        canvasHeight,
        photo,
        mapResult: mapResult,
        showAddress: showAddress,
        showCoordinates: showCoordinates,
        showAltitude: showAltitude,
        showTemperature: showTemperature,
        showDate: showDate,
        opacity: opacity,
        isLandscape: isLandscape,
      );

      final ui.Image watermarkedImage = await recorder.endRecording().toImage(
        canvasWidth.toInt(),
        canvasHeight.toInt(),
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
      
      // We do not fail the entire map if a tile fails. We just skip drawing it.
      
      // Stitch tiles (3x3 grid of 256x256 = 768x768)
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Draw a default background in case some tiles are missing
      canvas.drawRect(const Rect.fromLTWH(0, 0, 768, 768), Paint()..color = const Color(0xFFE0E0E0));

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
    bool isLandscape = false,
  }) async {
    // In portrait, scale off the width (the short edge of a tall image).
    // In landscape, scale off the height (the short edge of a wide image).
    final double refEdge = isLandscape ? height : width;
    final double scale = refEdge / 1080;
    final double padding = 32 * scale;

    // Card sizing adapts to orientation
    final double cardWidth = isLandscape
        ? width * 0.60   // Landscape: compact 60% width card
        : width - padding * 2;  // Portrait: full width minus padding
    final double cardHeight = isLandscape ? 190 * scale : 320 * scale;
    final double cardX = (width - cardWidth) / 2; // Center horizontally
    final double cardY = height - cardHeight - padding;
    final double cornerRadius = 24 * scale;

    // Draw Card Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cardX, cardY, cardWidth, cardHeight), Radius.circular(cornerRadius)),
      Paint()..color = Colors.black.withValues(alpha: 0.82 * opacity)
    );

    // 1. Precise Mini Map (On the Right)
    final double mapSize = cardHeight - 20 * scale;
    final double mapX = cardX + cardWidth - mapSize - 10 * scale;
    final double mapY = cardY + 10 * scale;
    final RRect mapBox = RRect.fromRectAndRadius(Rect.fromLTWH(mapX, mapY, mapSize, mapSize), Radius.circular(cornerRadius - 6 * scale));

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
        Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 0.5 * scale
      );

      // Tactical Crosshair Pin (only when map is visible)
      final double pinX = mapX + mapSize / 2;
      final double pinY = mapY + mapSize / 2;
      final Paint crosshairPaint = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * scale;

      // Outer glow for the crosshair
      canvas.drawCircle(Offset(pinX, pinY), 15 * scale, Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 4 * scale);
      
      // Crosshair Lines
      const double lineStart = 10.0;
      const double lineLength = 12.0;
      canvas.drawLine(Offset(pinX, pinY - (lineStart * scale)), Offset(pinX, pinY - ((lineStart + lineLength) * scale)), crosshairPaint);
      canvas.drawLine(Offset(pinX, pinY + (lineStart * scale)), Offset(pinX, pinY + ((lineStart + lineLength) * scale)), crosshairPaint);
      canvas.drawLine(Offset(pinX - (lineStart * scale), pinY), Offset(pinX - ((lineStart + lineLength) * scale), pinY), crosshairPaint);
      canvas.drawLine(Offset(pinX + (lineStart * scale), pinY), Offset(pinX + ((lineStart + lineLength) * scale), pinY), crosshairPaint);

      // Center glowing dot
      canvas.drawCircle(Offset(pinX, pinY), 5 * scale, Paint()..color = const Color(0xFF38BDF8));
      canvas.drawCircle(Offset(pinX, pinY), 8 * scale, Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.3));
    }

    // 2. Text Content
    // When map was loaded, text is on the left. When no map, text spans full width.
    final double textX = cardX + 28 * scale;
    double textY = cardY + 24 * scale;
    final double maxTextWidth = mapResult != null
        ? cardWidth - mapSize - 60 * scale   // leave room for map
        : cardWidth - 56 * scale;            // full card width

    // Scale text sizes based on orientation
    final double titleSize = isLandscape ? 34 * scale : 44 * scale;
    final double bodySize = isLandscape ? 20 * scale : 26 * scale;
    final double metaSize = isLandscape ? 18 * scale : 24 * scale;
    final double brandSize = isLandscape ? 16 * scale : 20 * scale;
    final double lineGap = isLandscape ? 28 * scale : 34 * scale;

    // A. Title
    String title = "LOCATION DETAILS";
    if (photo.address != null) {
      final p = photo.address!.split(',');
      if (p.length >= 3) {
        title = "${p[p.length-3].trim()}, ${p[p.length-2].trim()}, ${p[p.length-1].trim()}";
      } else {
        title = photo.address!;
      }
    }
    if (title.toUpperCase().contains("INDIA")) { title += " 🇮🇳"; }

    _drawText(canvas, title, textX, textY, maxTextWidth, titleSize, Colors.white, fontWeight: FontWeight.bold);
    textY += isLandscape ? 42 * scale : 60 * scale;

    // B. Address
    if (showAddress && photo.address != null) {
      final lines = _splitTextIntoLines(photo.address!, maxTextWidth, bodySize);
      for (final line in lines.take(isLandscape ? 1 : 2)) {
        _drawText(canvas, line, textX, textY, maxTextWidth, bodySize, Colors.white.withValues(alpha: 0.85 * opacity));
        textY += lineGap;
      }
    }
    textY += isLandscape ? 6 * scale : 15 * scale;

    // C. Meta Row
    String meta = "Lat ${photo.latitude.toStringAsFixed(6)}°, Long ${photo.longitude.toStringAsFixed(6)}°";
    if (showAltitude) meta += " | Elev: ${photo.altitude?.toInt() ?? 0}m";
    _drawText(canvas, meta, textX, textY, maxTextWidth, metaSize, Colors.white70, fontWeight: FontWeight.w500);
    textY += isLandscape ? 24 * scale : 38 * scale;

    // D. DateTime
    if (showDate) {
      final appLang = SettingsService().appLanguage;
      final localeCode = appLang == 'auto' ? null : (appLang == 'tl' ? 'en' : appLang);
      final dateStr = DateFormat('EEEE, dd/MM/yyyy • hh:mm a', localeCode).format(photo.capturedAt);
      _drawText(canvas, dateStr, textX, textY, maxTextWidth, metaSize, Colors.white70);
    }

    // E. Footer Branding
    _drawText(canvas, "📍 GEOCAM PRO", textX, cardY + cardHeight - 30 * scale, maxTextWidth, brandSize, const Color(0xFF38BDF8).withValues(alpha: 0.8), fontWeight: FontWeight.bold);
  }

  List<String> _splitTextIntoLines(String text, double maxTextWidth, double fontSize) {
    final int charsPerLine = (maxTextWidth / (fontSize * 0.58)).floor();
    if (text.length <= charsPerLine) return [text];
    final List<String> result = [];
    final List<String> words = text.split(' ');
    String currentLine = "";
    for (var word in words) {
      if ("$currentLine $word".length <= charsPerLine) {
        currentLine = currentLine.isEmpty ? word : "$currentLine $word";
      } else {
        if (currentLine.isNotEmpty) { result.add(currentLine); }
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
