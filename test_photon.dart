import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final query = 'london';
  final url = Uri.parse('https://photon.komoot.io/api/?q=$query&limit=8');
  
  try {
    final response = await http.get(url, headers: {
      'User-Agent': 'GeocamPro/1.0 (contact@geocam.app)'
    });
    print('Status Code: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List<dynamic>;
      for (final f in features) {
        final props = f['properties'];
        final geom = f['geometry'];
        final lat = geom['coordinates'][1];
        final lon = geom['coordinates'][0];
        final name = props['name'] ?? '';
        final state = props['state'] ?? '';
        final country = props['country'] ?? '';
        print('$name, $state, $country -> Lat: $lat, Lon: $lon');
      }
    } else {
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
