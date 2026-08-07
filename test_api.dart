import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final query = 'london';
  final apiKey = 'AIzaSyAqCQtedhvKMdMr8wp4vk6YlLnTXhIOCsQ';
  
  print('--- Testing Google Places API ---');
  final googleUrl = Uri.parse(
    'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey'
  );
  
  try {
    final response = await http.get(googleUrl);
    print('Google Status Code: ${response.statusCode}');
    print('Google Response: ${response.body}');
  } catch (e) {
    print('Google Error: $e');
  }

  print('\n--- Testing Nominatim Fallback ---');
  final nomUrl = Uri.parse(
    'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=8&accept-language=en,en'
  );
  
  try {
    final response = await http.get(
      nomUrl, 
      headers: {
        'User-Agent': 'GeocamPro/1.0 (contact@geocam.app)',
        'Accept-Language': 'en,en;q=0.9',
      }
    );
    print('Nominatim Status Code: ${response.statusCode}');
    print('Nominatim Response: ${response.body.substring(0, 200)}...'); // Print start of response
  } catch (e) {
    print('Nominatim Error: $e');
  }
}
