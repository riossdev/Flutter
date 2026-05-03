import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapas/models/evento_mapa.dart';
import 'package:mapas/services/geocoding_service.dart';
import 'package:mapas/services/location_service.dart';
import 'package:mapas/services/ticketmaster_service.dart';
import 'package:mapas/utils/marker_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class MapaEventosScreen extends StatefulWidget {
  const MapaEventosScreen({super.key});

  @override
  State<MapaEventosScreen> createState() => _MapaEventosScreenState();
}

class _MapaEventosScreenState extends State<MapaEventosScreen> {
  static const double _radioKmMinimo = 5;
  static const String _ticketmasterApiKey = 'P4B2GiOoGFiF7MF4Kxw9Ngx9Xi7S1KG1';

  final MapController _mapController = MapController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();

  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();
  late final TicketmasterService _ticketmaster = TicketmasterService(
    apiKey: _ticketmasterApiKey,
    radioKmMinimo: _radioKmMinimo,
  );

  Position? _userPosition;
  String? _errorText;
  bool _loadingLocation = false;
  bool _loadingEvents = false;
  List<EventoMapa> _eventos = const [];

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  @override
  void dispose() {
    _ciudadController.dispose();
    _categoriaController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  void _centrarEnUsuario() {
    final p = _userPosition;
    if (p == null) return;
    _mapController.move(LatLng(p.latitude, p.longitude), 13);
  }

  Future<void> _obtenerUbicacionActual() async {
    setState(() {
      _loadingLocation = true;
      _errorText = null;
    });

    final result = await _locationService.obtenerUbicacionActual();
    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _errorText = result.errorMessage;
        _loadingLocation = false;
      });
      return;
    }

    final position = result.position!;
    setState(() {
      _userPosition = position;
      _loadingLocation = false;
    });

    _mapController.move(LatLng(position.latitude, position.longitude), 13);
    await _buscarEventos();
  }

  Future<void> _buscarEventos() async {
    final ciudad = _ciudadController.text.trim();
    double latCentro;
    double lonCentro;

    if (ciudad.isNotEmpty) {
      setState(() {
        _loadingEvents = true;
        _errorText = null;
      });
      final punto = await _geocodingService.buscarCiudad(ciudad);
      if (!mounted) return;
      if (punto == null) {
        setState(() {
          _loadingEvents = false;
          _errorText =
              'No se encontró la ciudad. Prueba el nombre en inglés o más específico (ej. "New York, USA").';
        });
        return;
      }
      latCentro = punto.latitude;
      lonCentro = punto.longitude;
      _mapController.move(punto, 12);
    } else {
      final userPosition = _userPosition;
      if (userPosition == null) {
        setState(() {
          _errorText =
              'Escribe una ciudad o pulsa «Ubicación actual» para usar el GPS.';
        });
        return;
      }
      latCentro = userPosition.latitude;
      lonCentro = userPosition.longitude;
    }

    setState(() {
      _loadingEvents = true;
      _errorText = null;
    });

    try {
      final eventos = await _ticketmaster.buscarEventosCerca(
        latitudCentro: latCentro,
        longitudCentro: lonCentro,
        ciudad: ciudad,
        nombreClasificacion: _categoriaController.text,
        palabraClave: _keywordController.text,
      );
      if (!mounted) return;
      setState(() {
        _eventos = eventos;
        _loadingEvents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEvents = false;
        _errorText = 'Error consultando Ticketmaster: $e';
      });
    }
  }

  Future<void> _abrirUrlEvento(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  void _mostrarDetalleEvento(EventoMapa evento) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                evento.nombre,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Fecha: ${evento.fecha}'),
              Text('Lugar: ${evento.lugar}'),
              if (evento.segmento != null)
                Text('Categoría: ${evento.segmento}'),
              const SizedBox(height: 12),
              if (evento.url.isNotEmpty)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _abrirUrlEvento(evento.url);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ver en Ticketmaster'),
                ),
              if (evento.url.isEmpty)
                Text(
                  'Sin URL pública',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPosition = _userPosition;
    final userLatLng = userPosition != null
        ? LatLng(userPosition.latitude, userPosition.longitude)
        : const LatLng(4.7110, -74.0721);

    final markers = <Marker>[
      if (userPosition != null)
        Marker(
          point: userLatLng,
          width: 56,
          height: 56,
          child: const Icon(Icons.my_location, size: 36, color: Colors.blue),
        ),
      ..._eventos.map((evento) {
        final color = colorParaSegmento(evento.segmento);
        return Marker(
          point: LatLng(evento.latitud, evento.longitud),
          width: 52,
          height: 52,
          child: GestureDetector(
            onTap: () => _mostrarDetalleEvento(evento),
            child: Icon(Icons.location_on, color: color, size: 40),
          ),
        );
      }),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Eventos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Column(
              children: [
                TextField(
                  controller: _ciudadController,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad',
                    hintText: 'Ej: New York',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _categoriaController,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          hintText: 'music, sports...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _keywordController,
                        decoration: const InputDecoration(
                          labelText: 'Keyword',
                          hintText: 'rock, football...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _loadingLocation
                            ? null
                            : _obtenerUbicacionActual,
                        icon: const Icon(Icons.gps_fixed),
                        label: Text(
                          _loadingLocation ? 'Ubicando...' : 'Ubicación actual',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _loadingEvents ? null : _buscarEventos,
                        icon: const Icon(Icons.search),
                        label: Text(
                          _loadingEvents ? 'Buscando...' : 'Buscar eventos',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Eventos en un radio de $_radioKmMinimo km: ${_eventos.length}',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: userLatLng,
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mapas',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton.filledTonal(
                      tooltip: 'Centrar en mi ubicación',
                      onPressed: _userPosition == null
                          ? null
                          : _centrarEnUsuario,
                      icon: const Icon(Icons.my_location),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
