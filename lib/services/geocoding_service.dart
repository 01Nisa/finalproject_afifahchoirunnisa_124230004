import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple geocoding using OpenStreetMap's Nominatim API.
///
/// This avoids depending on a Google API key and works well for free-text
/// addresses. Nominatim has usage policies; for heavy usage consider a
/// dedicated geocoding provider or a cached server-side service.
class GeocodingService {
  /// Returns a map with 'lat' and 'lng' or null if not found.
  Future<Map<String, double>?> geocode(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    final url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '1',
    });

    // Nominatim requires a valid User-Agent. Provide a simple one.
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
