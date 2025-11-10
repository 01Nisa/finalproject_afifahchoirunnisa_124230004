import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  Future<Map<String, double>?> geocode(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '1',
    });

    final resp = await http.get(url, headers: {
      'User-Agent': 'ARVA-App/1.0 (contact: you@example.com)'
    });

    if (resp.statusCode != 200) return null;

    final data = json.decode(resp.body) as List<dynamic>?;
    if (data == null || data.isEmpty) return null;

    final first = data.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;

    return {'lat': lat, 'lng': lon};
  }
}
