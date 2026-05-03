import 'package:flutter_test/flutter_test.dart';

import 'package:mapas/main.dart';

void main() {
  testWidgets('App muestra pantalla de mapa', (WidgetTester tester) async {
    await tester.pumpWidget(const MapaEventosApp());
    await tester.pump();

    expect(find.text('Mapa de Eventos'), findsOneWidget);
  });
}
