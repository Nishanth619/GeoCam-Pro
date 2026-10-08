import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocam_flutter/services/report_service.dart';

void main() {
  List<List<String>> rows(int i) => [
        ['Address', '📡 Offline • Улица Ленина $i, Москва'],
        ['Coordinates', '37TFJ 00000 4977$i'],
        ['Altitude', '${i}m'],
        ['Date / Time', '01 Jan 2026, 12:0$i:00'],
      ];

  test('builds a multi-page PDF without a Unicode font', () async {
    final bytes = await buildReportPdfForTesting(
      photoRows: [for (var i = 0; i < 9; i++) rows(i)],
      projectName: 'Roof — 12 Oak St',
      companyName: 'Acme Inspections',
    );
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    // 9 entries at ~220pt each cannot fit on one A4 page
    final text = latin1.decode(bytes);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(text).length, greaterThan(1));
  });

  test('builds a report with empty company and project names', () async {
    final bytes = await buildReportPdfForTesting(photoRows: [rows(1)]);
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
