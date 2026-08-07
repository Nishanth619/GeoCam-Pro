import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final query = 'london';
  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/search'
    '?q=${Uri.encodeComponent(query.trim())}'
    '&format=json'
    '&addressdetails=1'
    '&limit=8'
    '&accept-language=en,en',
  );

  final response = await http.get(url, headers: {
    'User-Agent': 'GeocamPro/1.0 (contact@geocam.app)',
    'Accept-Language': 'en,en;q=0.9',
  });

  if (response.statusCode != 200) {
    print('Failed with status: ${response.statusCode}');
    return;
  }

  final data = json.decode(response.body) as List<dynamic>;
  final results = <Map<String, dynamic>>[];
  final seen = <String>{};

  for (final item in data) {
    final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
    
    // Build standard address parts
    final addr = item['address'] as Map<String, dynamic>? ?? {};
    
    // ... we don't have the full parsing code here.
    print(addr);
  }
}
