import 'package:explorador_local/calidad_aire/views/calculadora_calidad_aire_page.dart';
import 'package:flutter/material.dart';

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
