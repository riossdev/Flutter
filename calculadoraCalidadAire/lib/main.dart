import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const CalidadAireApp());
}

class CalidadAireApp extends StatelessWidget {
  const CalidadAireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora Calidad del Aire',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: const CalculadoraCalidadAirePage(),
    );
  }
}

class CiudadColombia {
  const CiudadColombia({
    required this.nombre,
    required this.latitud,
    required this.longitud,
  });

  final String nombre;
  final double latitud;
  final double longitud;
}

class ResultadoCalidadAire {
  const ResultadoCalidadAire({
    required this.promedioPm25,
    required this.indiceExposicion,
    required this.riesgo,
  });

  final double promedioPm25;
  final double indiceExposicion;
  final String riesgo;
}

class CalculadoraCalidadAirePage extends StatefulWidget {
  const CalculadoraCalidadAirePage({super.key});

  @override
  State<CalculadoraCalidadAirePage> createState() =>
      _CalculadoraCalidadAirePageState();
}

class _CalculadoraCalidadAirePageState extends State<CalculadoraCalidadAirePage> {
  static const List<CiudadColombia> ciudades = [
    CiudadColombia(nombre: 'Bogota', latitud: 4.61, longitud: -74.08),
    CiudadColombia(nombre: 'Medellin', latitud: 6.25, longitud: -75.56),
    CiudadColombia(nombre: 'Cali', latitud: 3.44, longitud: -76.52),
    CiudadColombia(nombre: 'Barranquilla', latitud: 10.98, longitud: -74.80),
    CiudadColombia(nombre: 'Cartagena', latitud: 10.40, longitud: -75.51),
  ];

  CiudadColombia _ciudadSeleccionada = ciudades.first;
  DateTime _fechaSeleccionada = DateTime.now();
  final TextEditingController _horasController = TextEditingController(text: '2');
  bool _cargando = false;
  String? _error;
  ResultadoCalidadAire? _resultado;

  @override
  void dispose() {
    _horasController.dispose();
    super.dispose();
  }

  String _formatoFecha(DateTime fecha) {
    final year = fecha.year.toString().padLeft(4, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _clasificarRiesgo(double indice) {
    if (indice < 100) return 'Bajo';
    if (indice <= 200) return 'Moderado';
    return 'Alto';
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(hoy.year - 1),
      lastDate: hoy,
    );
    if (seleccion != null) {
      setState(() => _fechaSeleccionada = seleccion);
    }
  }

  Future<void> _calcularIndice() async {
    final horas = double.tryParse(_horasController.text.replaceAll(',', '.'));
    if (horas == null || horas <= 0) {
      setState(() {
        _error = 'Ingresa un numero de horas valido (mayor a 0).';
        _resultado = null;
      });
      return;
    }

    final fecha = _formatoFecha(_fechaSeleccionada);
    final url = Uri.parse(
      'https://air-quality-api.open-meteo.com/v1/air-quality'
      '?latitude=${_ciudadSeleccionada.latitud}'
      '&longitude=${_ciudadSeleccionada.longitud}'
      '&hourly=pm2_5'
      '&start_date=$fecha'
      '&end_date=$fecha',
    );

    setState(() {
      _cargando = true;
      _error = null;
      _resultado = null;
    });

    try {
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
      final promedio = suma / valores.length;
      final indice = promedio * horas;

      setState(() {
        _resultado = ResultadoCalidadAire(
          promedioPm25: promedio,
          indiceExposicion: indice,
          riesgo: _clasificarRiesgo(indice),
        );
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo consultar la API: $e';
      });
    } finally {
      setState(() => _cargando = false);
    }
  }

  Color _colorRiesgo(String riesgo) {
    switch (riesgo) {
      case 'Bajo':
        return Colors.green.shade700;
      case 'Moderado':
        return Colors.orange.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora de Calidad del Aire')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<CiudadColombia>(
              value: _ciudadSeleccionada,
              decoration: const InputDecoration(labelText: 'Ciudad'),
              items: ciudades
                  .map(
                    (c) => DropdownMenuItem<CiudadColombia>(
                      value: c,
                      child: Text(c.nombre),
                    ),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => _ciudadSeleccionada = valor);
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _seleccionarFecha,
              icon: const Icon(Icons.calendar_month),
              label: Text('Fecha: ${_formatoFecha(_fechaSeleccionada)}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _horasController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Horas promedio al aire libre',
                hintText: 'Ejemplo: 3.5',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _cargando ? null : _calcularIndice,
              icon: const Icon(Icons.calculate),
              label: const Text('Calcular indice de exposicion'),
            ),
            const SizedBox(height: 20),
            if (_cargando) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            if (_resultado != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promedio diario PM2.5: ${_resultado!.promedioPm25.toStringAsFixed(2)} ug/m3',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Indice de exposicion: ${_resultado!.indiceExposicion.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nivel de riesgo: ${_resultado!.riesgo}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _colorRiesgo(_resultado!.riesgo),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
