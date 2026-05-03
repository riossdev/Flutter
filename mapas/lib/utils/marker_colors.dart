import 'package:flutter/material.dart';

Color colorParaSegmento(String? segmento) {
  final s = (segmento ?? '').toLowerCase();
  if (s.contains('music')) return Colors.deepPurple;
  if (s.contains('sport')) return Colors.green;
  if (s.contains('arts') ||
      s.contains('theatre') ||
      s.contains('theater') ||
      s.contains('cultural')) {
    return Colors.orange;
  }
  if (s.contains('film') || s.contains('movie')) return Colors.blueGrey;
  if (s.contains('family')) return Colors.pink;
  if (s.contains('misc')) return Colors.brown;
  return Colors.redAccent;
}
