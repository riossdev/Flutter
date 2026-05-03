import 'package:flutter/material.dart';
import 'package:mapas/screens/mapa_eventos_screen.dart';

void main() {
  runApp(const MapaEventosApp());
}

class MapaEventosApp extends StatelessWidget {
  const MapaEventosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eventos Cerca de Ti',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MapaEventosScreen(),
    );
  }
}
