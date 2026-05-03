import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Geocodificación vía Nominatim (OpenStreetMap). Requiere User-Agent válido.
class GeocodingService {
  GeocodingService();

  static const _base = 'https://nominatim.openstreetmap.org/search';
  static const _userAgent = 'MapasEventos/1.0 (Flutter; eventos culturales)';

  Future<LatLng?> buscarCiudad(String consulta) async {
    final q = consulta.trim();
    if (q.isEmpty) return null;

    final uri = Uri.parse(_base).replace(queryParameters: {
      'q': q,
      'format': 'json',
      'limit': '1',
    });

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept-Language': 'es,en',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data is! List || data.isEmpty) return null;

    final first = data.first;
    if (first is! Map<String, dynamic>) return null;

    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;

    return LatLng(lat, lon);
  }
}
