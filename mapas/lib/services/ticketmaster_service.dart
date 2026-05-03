import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mapas/models/evento_mapa.dart';

class TicketmasterService {
  TicketmasterService({required this.apiKey, this.radioKmMinimo = 5});

  final String apiKey;
  final double radioKmMinimo;

  Future<List<EventoMapa>> buscarEventosCerca({
    required double latitudCentro,
    required double longitudCentro,
    required String ciudad,
    String? nombreClasificacion,
    String? palabraClave,
  }) async {
    final uri = Uri.https('app.ticketmaster.com', '/discovery/v2/events.json', {
      'apikey': apiKey,
      if (ciudad.trim().isNotEmpty) 'city': ciudad.trim(),
      if (nombreClasificacion != null && nombreClasificacion.trim().isNotEmpty)
        'classificationName': nombreClasificacion.trim(),
      if (palabraClave != null && palabraClave.trim().isNotEmpty)
        'keyword': palabraClave.trim(),
      'latlong': '$latitudCentro,$longitudCentro',
      'radius': radioKmMinimo.toStringAsFixed(0),
      'unit': 'km',
      'size': '100',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Ticketmaster HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final eventos = _parsearEventos(json);

    return eventos.where((evento) {
      final metros = Geolocator.distanceBetween(
        latitudCentro,
        longitudCentro,
        evento.latitud,
        evento.longitud,
      );
      return metros <= radioKmMinimo * 1000;
    }).toList();
  }

  List<EventoMapa> _parsearEventos(Map<String, dynamic> body) {
    final embedded = body['_embedded'];
    if (embedded is! Map<String, dynamic>) {
      return const [];
    }
    final events = embedded['events'];
    if (events is! List) {
      return const [];
    }

    final parsed = <EventoMapa>[];
    for (final item in events) {
      if (item is! Map<String, dynamic>) continue;
      final nombre = item['name']?.toString();
      final id = item['id']?.toString();
      final dates = item['dates'] as Map<String, dynamic>?;
      final start = dates?['start'] as Map<String, dynamic>?;
      final fecha = start?['localDate']?.toString() ?? 'Sin fecha';

      final segmento = _extraerSegmento(item);

      final embeddedEvento = item['_embedded'] as Map<String, dynamic>?;
      final venues = embeddedEvento?['venues'];
      if (nombre == null || id == null || venues is! List || venues.isEmpty) {
        continue;
      }

      final venue = venues.first;
      if (venue is! Map<String, dynamic>) continue;
      final location = venue['location'] as Map<String, dynamic>?;
      final lat = double.tryParse(location?['latitude']?.toString() ?? '');
      final lon = double.tryParse(location?['longitude']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      parsed.add(
        EventoMapa(
          id: id,
          nombre: nombre,
          fecha: fecha,
          lugar: venue['name']?.toString() ?? 'Sin venue',
          latitud: lat,
          longitud: lon,
          url: item['url']?.toString() ?? '',
          segmento: segmento,
        ),
      );
    }
    return parsed;
  }

  String? _extraerSegmento(Map<String, dynamic> item) {
    final classifications = item['classifications'];
    if (classifications is! List || classifications.isEmpty) {
      return null;
    }
    final first = classifications.first;
    if (first is! Map<String, dynamic>) return null;
    final segment = first['segment'] as Map<String, dynamic>?;
    return segment?['name']?.toString();
  }
}
