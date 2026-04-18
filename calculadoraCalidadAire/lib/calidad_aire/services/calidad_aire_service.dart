import 'dart:convert';

import 'package:explorador_local/calidad_aire/models/ciudad_colombia.dart';
import 'package:http/http.dart' as http;

class CalidadAireService {
  Future<double> obtenerPromedioPm25({
    required CiudadColombia ciudad,
    required DateTime fecha,
  }) async {
    final fechaFormateada = _formatearFecha(fecha);
    final url = Uri.parse(
      'https://air-quality-api.open-meteo.com/v1/air-quality'
      '?latitude=${ciudad.latitud}'
      '&longitude=${ciudad.longitud}'
      '&hourly=pm2_5'
      '&start_date=$fechaFormateada'
      '&end_date=$fechaFormateada',
    );

    final respuesta = await http.get(url);
    if (respuesta.statusCode != 200) {
      throw Exception('Error HTTP: ${respuesta.statusCode}');
    }

    final data = jsonDecode(respuesta.body) as Map<String, dynamic>;
    final hourly = data['hourly'] as Map<String, dynamic>?;
    final pm25Lista = hourly?['pm2_5'] as List<dynamic>?;

    if (pm25Lista == null || pm25Lista.isEmpty) {
      throw Exception('La API no retorno datos de PM2.5 para la fecha.');
    }

    final valores = pm25Lista
        .where((e) => e != null)
        .map((e) => (e as num).toDouble())
        .toList();

    if (valores.isEmpty) {
      throw Exception('No hay valores validos de PM2.5 para esa consulta.');
    }

    final suma = valores.reduce((a, b) => a + b);
    return suma / valores.length;
  }

  String _formatearFecha(DateTime fecha) {
    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
