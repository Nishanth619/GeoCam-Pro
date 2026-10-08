import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/photo_model.dart';
import 'location_service.dart';
import 'settings_service.dart';

/// Builds PDF inspection reports from captured photos.
class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  /// Keeps memory and generation time bounded.
  static const int maxPhotos = 100;

  /// Longest edge of the thumbnails embedded in the PDF.
  static const int _thumbSize = 600;

  /// Generates the report and saves it in the app's temp directory.
  ///
  /// Main isolate: formats metadata (needs settings), downsamples photos with
  /// the native codec, loads fonts. Background isolate (compute): JPEG-encodes
  /// thumbnails and lays out the PDF.
  Future<File> generatePdfReport(
      List<Photo> photos, String projectName, String companyName) async {
    final settings = SettingsService();
    final location = LocationService();
    final coordFormat = settings.templateCoordFormat;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

    final fonts = await _loadFonts();

    final entries = <_ReportEntry>[];
    for (final photo in photos.take(maxPhotos)) {
      final rows = <List<String>>[
        ['Address', photo.address ?? '—'],
        ['Coordinates', location.formatCoordinates(photo.latitude, photo.longitude, coordFormat)],
        if (coordFormat != SettingsService.coordFormatDD)
          ['Lat / Long', location.formatCoordinatesDD(photo.latitude, photo.longitude)],
        ['Altitude', settings.formatAltitude(photo.altitude)],
        ['Date / Time', dateFormat.format(photo.capturedAt)],
      ];
      entries.add(_ReportEntry(rows: rows, thumbnail: await _loadThumbnail(photo.imagePath)));
    }

    final now = DateTime.now();
    final input = _ReportInput(
      companyName: companyName.trim(),
      projectName: projectName.trim(),
      reportDate: DateFormat('dd MMM yyyy, HH:mm').format(now),
      entries: entries,
      regularFont: fonts?.$1,
      boldFont: fonts?.$2,
    );
    final bytes = await compute(_buildReportPdf, input);

    final tempDir = await getTemporaryDirectory();
    final safeName = projectName.trim().isEmpty
        ? 'Report'
        : projectName.trim().replaceAll(RegExp(r'[^\w\- ]'), '').replaceAll(' ', '_');
    final file = File(path.join(
      tempDir.path,
      'GeoCam_${safeName}_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf',
    ));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Noto Sans covers Latin, Cyrillic and Greek (the app's languages).
  /// Fetched once and cached by the printing package; null when offline.
  Future<(ByteData, ByteData)?> _loadFonts() async {
    try {
      final regular = await PdfGoogleFonts.notoSansRegular()
          .timeout(const Duration(seconds: 10));
      final bold = await PdfGoogleFonts.notoSansBold()
          .timeout(const Duration(seconds: 10));
      return ((regular as pw.TtfFont).data, (bold as pw.TtfFont).data);
    } catch (e) {
      debugPrint('Report: Noto Sans unavailable, using built-in font: $e');
      return null;
    }
  }

  /// Decodes [imagePath] downsampled to fit [_thumbSize], as raw RGBA.
  Future<_RawImage?> _loadThumbnail(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final w = descriptor.width, h = descriptor.height;
      final scale = _thumbSize / (w > h ? w : h);
      final codec = await descriptor.instantiateCodec(
        targetWidth: scale < 1 ? (w * scale).round() : w,
        targetHeight: scale < 1 ? (h * scale).round() : h,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final result = rgba == null
          ? null
          : _RawImage(rgba.buffer.asUint8List(), image.width, image.height);
      image.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
      return result;
    } catch (e) {
      debugPrint('Report: could not load $imagePath: $e');
      return null;
    }
  }
}

// ── Isolate payload ─────────────────────────────────────────────────────────

class _RawImage {
  final Uint8List rgba;
  final int width;
  final int height;
  _RawImage(this.rgba, this.width, this.height);
}

class _ReportEntry {
  final List<List<String>> rows; // [label, value]
  final _RawImage? thumbnail;
  _ReportEntry({required this.rows, required this.thumbnail});
}

class _ReportInput {
  final String companyName;
  final String projectName;
  final String reportDate;
  final List<_ReportEntry> entries;
  final ByteData? regularFont;
  final ByteData? boldFont;

  _ReportInput({
    required this.companyName,
    required this.projectName,
    required this.reportDate,
    required this.entries,
    required this.regularFont,
    required this.boldFont,
  });
}

/// Builds a report from plain metadata rows with solid-colour thumbnails.
/// Lets tests exercise the PDF layout without platform channels.
@visibleForTesting
Future<Uint8List> buildReportPdfForTesting({
  required List<List<List<String>>> photoRows,
  String projectName = '',
  String companyName = '',
}) {
  return _buildReportPdf(_ReportInput(
    companyName: companyName,
    projectName: projectName,
    reportDate: '01 Jan 2026, 12:00',
    entries: [
      for (final rows in photoRows)
        _ReportEntry(
          rows: rows,
          thumbnail: _RawImage(Uint8List(40 * 30 * 4)..fillRange(0, 40 * 30 * 4, 200), 40, 30),
        ),
    ],
    regularFont: null,
    boldFont: null,
  ));
}

// ── PDF layout (runs in a background isolate) ──────────────────────────────

const _accent = PdfColor.fromInt(0xFF0EA5E9);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _border = PdfColor.fromInt(0xFFE5E7EB);

final _emoji = RegExp(
  r'[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]',
  unicode: true,
);

Future<Uint8List> _buildReportPdf(_ReportInput input) async {
  final hasUnicodeFont = input.regularFont != null;

  // Emoji (📡, 📍, flags) aren't in Noto Sans; the built-in Helvetica only
  // covers Latin-1, so anything beyond that becomes '?'.
  String clean(String s) {
    var out = s.replaceAll(_emoji, '').replaceFirst(RegExp(r'^[\s•·]+'), '').trim();
    if (!hasUnicodeFont) {
      out = String.fromCharCodes(out.runes.map((r) => r <= 0xFF ? r : 0x3F));
    }
    return out.isEmpty ? (hasUnicodeFont ? '—' : '-') : out;
  }

  final theme = hasUnicodeFont
      ? pw.ThemeData.withFont(
          base: pw.Font.ttf(input.regularFont!),
          bold: pw.Font.ttf(input.boldFont ?? input.regularFont!),
        )
      : pw.ThemeData.base();

  final company = clean(input.companyName);
  final project = clean(input.projectName);
  final hasCompany = input.companyName.trim().isNotEmpty;
  final hasProject = input.projectName.trim().isNotEmpty;

  final doc = pw.Document(
    title: hasProject ? '$project — Inspection Report' : 'Inspection Report',
    author: hasCompany ? company : null,
    creator: 'GeoCam Pro',
  );

  pw.Widget summary() => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        margin: const pw.EdgeInsets.only(bottom: 16),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _accent, width: 2)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (hasCompany)
              pw.Text(company,
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(hasProject ? project : 'Inspection Report',
                style: const pw.TextStyle(fontSize: 14, color: _accent)),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.Text('Report date: ${input.reportDate}',
                  style: const pw.TextStyle(fontSize: 10, color: _muted)),
              pw.SizedBox(width: 24),
              pw.Text('Total photos: ${input.entries.length}',
                  style: const pw.TextStyle(fontSize: 10, color: _muted)),
            ]),
          ],
        ),
      );

  pw.Widget entry(int index, _ReportEntry e) {
    final thumb = e.thumbnail;
    pw.Widget image;
    if (thumb != null) {
      final jpg = img.encodeJpg(
        img.Image.fromBytes(
          width: thumb.width,
          height: thumb.height,
          bytes: thumb.rgba.buffer,
          numChannels: 4,
        ),
        quality: 75,
      );
      image = pw.Image(pw.MemoryImage(jpg), fit: pw.BoxFit.contain);
    } else {
      image = pw.Center(
        child: pw.Text('Image unavailable', style: const pw.TextStyle(fontSize: 9, color: _muted)),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 200, height: 200, child: image),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Photo ${index + 1}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _accent)),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: const {
                    0: pw.FixedColumnWidth(72),
                    1: pw.FlexColumnWidth(),
                  },
                  children: [
                    for (final row in e.rows)
                      pw.TableRow(children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          child: pw.Text(row[0],
                              style: const pw.TextStyle(fontSize: 9, color: _muted)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          child: pw.Text(clean(row[1]), style: const pw.TextStyle(fontSize: 9)),
                        ),
                      ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      theme: theme,
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                [if (hasCompany) company, if (hasProject) project].join('  ·  '),
                style: const pw.TextStyle(fontSize: 9, color: _muted),
              ),
            ),
      footer: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated by GeoCam Pro',
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ],
        ),
      ),
      build: (context) => [
        summary(),
        for (var i = 0; i < input.entries.length; i++) entry(i, input.entries[i]),
      ],
    ),
  );

  return doc.save();
}
