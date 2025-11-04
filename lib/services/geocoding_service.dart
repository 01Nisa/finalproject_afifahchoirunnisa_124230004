import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class GeocodingService {
  Future<Map<String, double>?> geocode(String address) async {
    if (address.trim().isEmpty) return null;
    final url = Uri.parse(
        '${ApiConstants.geocodingBaseUrl}?address=${Uri.encodeComponent(address)}&key=${ApiConstants.googleApiKey}');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return null;
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;
    final loc = results.first['geometry']?['location'];
    if (loc == null) return null;
    final lat = (loc['lat'] as num).toDouble();
    final lng = (loc['lng'] as num).toDouble();
    return {'lat': lat, 'lng': lng};
  }
}
