import 'package:flutter_test/flutter_test.dart';
import 'package:geocam_flutter/services/location_service.dart';
import 'package:geocam_flutter/services/settings_service.dart';

void main() {
  final location = LocationService();

  group('UTM', () {
    test('equator / prime meridian', () {
      expect(location.formatCoordinatesUTM(0, 0), '31N 166021 0');
    });

    test('southern hemisphere uses false northing', () {
      // Sydney Opera House
      expect(location.formatCoordinatesUTM(-33.8568, 151.2153),
          matches(RegExp(r'^56S 3349\d\d 62522\d\d$')));
    });

    test('polar regions fall back to DD', () {
      expect(location.formatCoordinatesUTM(85, 10),
          location.formatCoordinatesDD(85, 10));
    });
  });

  group('MGRS', () {
    test('equator / prime meridian', () {
      expect(location.formatCoordinatesMGRS(0, 0), '31NAA 66021 00000');
    });

    test('Eiffel Tower', () {
      expect(location.formatCoordinatesMGRS(48.8584, 2.2945),
          matches(RegExp(r'^31UDQ 482\d\d 119\d\d$')));
    });
  });

  test('formatCoordinates dispatches on setting value', () {
    expect(location.formatCoordinates(0, 0, SettingsService.coordFormatMGRS),
        '31NAA 66021 00000');
    expect(location.formatCoordinates(0, 0, 'unknown'),
        location.formatCoordinatesDD(0, 0));
  });
}
