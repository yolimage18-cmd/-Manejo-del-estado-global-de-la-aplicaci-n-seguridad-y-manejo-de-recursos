// Prueba de widget básica (ver Unidad 2, Ejercicio 10 del módulo).
//
// Verifica que la app arranca y muestra el nombre "Fichaje" (en la pantalla
// de carga o en el login, según termine de leer la sesión guardada).

import 'package:flutter_test/flutter_test.dart';

import 'package:fichaje_app/main.dart';

void main() {
  testWidgets('La app inicia y muestra el nombre Fichaje', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Fichaje'), findsWidgets);
  });
}
