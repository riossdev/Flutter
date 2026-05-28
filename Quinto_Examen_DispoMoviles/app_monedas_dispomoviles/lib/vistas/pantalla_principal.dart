import 'package:flutter/material.dart';
import '../servicios/autenticacion_servicio.dart';
import '../servicios/moneda_servicio.dart';
import '../modelos/moneda.dart';
import '../modelos/cambio_moneda.dart';
import 'pantalla_login.dart';

class PantallaPrincipal extends StatefulWidget {
  final String token;

  const PantallaPrincipal({super.key, required this.token});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final AutenticacionServicio _authServicio = AutenticacionServicio();
  final MonedaServicio _monedaServicio = MonedaServicio();

  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  List<Moneda> _monedas = [];
  List<CambioMoneda> _resultados = [];
  Moneda? _monedaSeleccionada;
  bool _cargandoMonedas = true;
  bool _consultando = false;

  @override
  void initState() {
    super.initState();
    _cargarMonedas();
  }

  @override
  void dispose() {
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<void> _cargarMonedas() async {
    setState(() => _cargandoMonedas = true);
    try {
      final monedas = await _monedaServicio.listarMonedas(widget.token);
      setState(() {
        _monedas = monedas;
        _cargandoMonedas = false;
        if (_monedas.isNotEmpty) _monedaSeleccionada = _monedas.first;
      });
    } catch (e) {
      setState(() => _cargandoMonedas = false);
      _mostrarError(e.toString());
    }
  }

  Future<void> _consultarCambios() async {
    if (_monedaSeleccionada == null) {
      _mostrarError('Seleccione una moneda');
      return;
    }

    DateTime? fechaInicio;
    DateTime? fechaFin;
    try {
      fechaInicio = DateTime.parse(_fechaInicioController.text.trim());
      fechaFin = DateTime.parse(_fechaFinController.text.trim());
    } catch (_) {
      _mostrarError('Formato de fecha inválido. Use YYYY-MM-DD');
      return;
    }

    if (fechaInicio.isAfter(fechaFin)) {
      _mostrarError('La fecha inicio debe ser anterior a la fecha fin');
      return;
    }

    setState(() => _consultando = true);
    try {
      final cambios = await _monedaServicio.listarCambiosPorPeriodo(
        token: widget.token,
        idMoneda: _monedaSeleccionada!.id,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      setState(() {
        _resultados = cambios;
        _consultando = false;
      });
      if (cambios.isEmpty) {
        _mostrarInfo('No hay registros en el período seleccionado');
      } else {
        _mostrarInfo('${cambios.length} registros encontrados');
      }
    } catch (e) {
      setState(() => _consultando = false);
      _mostrarError(e.toString());
    }
  }

  Future<void> _cerrarSesion() async {
    await _authServicio.cerrarSesion();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaLogin()),
      );
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarInfo(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCampoFecha({
    required TextEditingController controller,
    required String label,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'YYYY-MM-DD',
          prefixIcon: const Icon(Icons.calendar_month, color: Colors.indigo),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        keyboardType: TextInputType.datetime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        title: const Text(
          'Tasas de Cambio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _cargandoMonedas
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.indigo),
                        ),
                      )
                    : DropdownButtonFormField<Moneda>(
                        value: _monedaSeleccionada,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Moneda',
                          prefixIcon: const Icon(Icons.monetization_on_outlined, color: Colors.indigo),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _monedas.map((moneda) {
                          return DropdownMenuItem(
                            value: moneda,
                            child: Text(moneda.moneda),
                          );
                        }).toList(),
                        onChanged: (moneda) {
                          setState(() => _monedaSeleccionada = moneda);
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCampoFecha(controller: _fechaInicioController, label: 'Desde'),
                const SizedBox(width: 12),
                _buildCampoFecha(controller: _fechaFinController, label: 'Hasta'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _consultando ? null : _consultarCambios,
                icon: _consultando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _consultando ? 'Consultando...' : 'Buscar Registros',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_resultados.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_resultados.length} resultados',
                  style: TextStyle(
                    color: Colors.indigo[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            Expanded(
              child: _resultados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart, size: 60, color: Colors.indigo[200]),
                          const SizedBox(height: 12),
                          Text(
                            'Sin resultados',
                            style: TextStyle(fontSize: 16, color: Colors.indigo[300]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seleccione moneda y rango de fechas',
                            style: TextStyle(fontSize: 13, color: Colors.indigo[200]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _resultados.length,
                      itemBuilder: (context, index) {
                        final cambio = _resultados[index];
                        final fechaStr =
                            '${cambio.fecha.day.toString().padLeft(2, '0')}/${cambio.fecha.month.toString().padLeft(2, '0')}/${cambio.fecha.year}';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo[50],
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.indigo[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              fechaStr,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Valor: ${cambio.valor.toStringAsFixed(4)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Icon(
                              cambio.valor > 1
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: cambio.valor > 1 ? Colors.indigo : Colors.orange,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
