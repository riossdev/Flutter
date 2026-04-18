import 'package:explorador_local/calidad_aire/data/ciudades_colombia.dart';
import 'package:explorador_local/calidad_aire/models/ciudad_colombia.dart';
import 'package:explorador_local/calidad_aire/models/resultado_calidad_aire.dart';
import 'package:explorador_local/calidad_aire/services/calidad_aire_service.dart';
import 'package:flutter/material.dart';

class CalculadoraCalidadAirePage extends StatefulWidget {
  const CalculadoraCalidadAirePage({super.key});

  @override
  State<CalculadoraCalidadAirePage> createState() =>
      _CalculadoraCalidadAirePageState();
}

class _CalculadoraCalidadAirePageState extends State<CalculadoraCalidadAirePage> {
  final CalidadAireService _service = CalidadAireService();
  CiudadColombia _ciudadSeleccionada = ciudadesColombia.first;
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

    setState(() {
      _cargando = true;
      _error = null;
      _resultado = null;
    });

    try {
      final promedio = await _service.obtenerPromedioPm25(
        ciudad: _ciudadSeleccionada,
        fecha: _fechaSeleccionada,
      );
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
              items: ciudadesColombia
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
