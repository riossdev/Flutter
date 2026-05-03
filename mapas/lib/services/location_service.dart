import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({this.position, this.errorMessage});

  final Position? position;
  final String? errorMessage;

  bool get isSuccess => position != null && errorMessage == null;
}

class LocationService {
  Future<LocationResult> obtenerUbicacionActual() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          errorMessage: 'Activa la ubicación del dispositivo.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult(
          errorMessage: 'Permiso de ubicación denegado.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationResult(position: position);
    } catch (e) {
      return LocationResult(
        errorMessage: 'No se pudo obtener la ubicación: $e',
      );
    }
  }
}
