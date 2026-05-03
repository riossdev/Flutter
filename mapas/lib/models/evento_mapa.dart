class EventoMapa {
  const EventoMapa({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.lugar,
    required this.latitud,
    required this.longitud,
    required this.url,
    this.segmento,
  });

  final String id;
  final String nombre;
  final String fecha;
  final String lugar;
  final double latitud;
  final double longitud;
  final String url;

  /// Segmento Ticketmaster (Music, Sports, Arts & Theatre, etc.) para colorear marcadores.
  final String? segmento;
}
