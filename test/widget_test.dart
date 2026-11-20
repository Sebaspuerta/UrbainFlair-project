import 'package:flutter_test/flutter_test.dart';

import 'package:urbanflair/models/venta.dart';
import 'package:urbanflair/utils/formato.dart';
import 'package:urbanflair/utils/navegacion.dart';

void main() {
  group('Formatos de dinero (lo que se ve en cada pantalla)', () {
    test('comprobante y notificación: con separador de miles', () {
      expect(dinero(350000), r'$350,000.00');
      expect(dinero(1234.5), r'$1,234.50');
      expect(dinero(12.3), r'$12.30');
    });

    test('Mis Ventas, Nueva Venta e Inventario: 2 decimales, sin miles', () {
      expect(dineroSinMiles(350000), r'$350000.00');
      expect(dineroSinMiles(89900.5), r'$89900.50');
    });

    test('Home (Ventas del mes): 0 decimales, sin miles', () {
      expect(dineroSinMiles(441135.4, decimales: 0), r'$441135');
    });
  });

  group('Regreso del login con Google', () {
    test('detecta los parámetros de OAuth en la URL', () {
      expect(esRegresoDeAuth(Uri.parse('http://localhost:5000/?code=abc')), isTrue);
      expect(
          esRegresoDeAuth(
              Uri.parse('http://localhost:5000/#access_token=x&type=bearer')),
          isTrue);
      expect(
          esRegresoDeAuth(Uri.parse('http://localhost:5000/?error=access_denied')),
          isTrue);
    });

    test('una URL normal no es regreso de Google', () {
      expect(esRegresoDeAuth(Uri.parse('http://localhost:5000/')), isFalse);
      expect(esRegresoDeAuth(Uri.parse('http://localhost:5000/#/home')), isFalse);
    });
  });

  test('El total de una venta suma sus líneas', () {
    final venta = Venta(codigo: 'VTA-1', fecha: DateTime(2026), items: const [
      ItemVenta(
          codigoProducto: 'P-1',
          descripcion: 'A',
          cantidad: 2,
          valorUnitario: 175000),
      ItemVenta(
          codigoProducto: 'P-2',
          descripcion: 'B',
          cantidad: 1,
          valorUnitario: 89900.5),
    ]);
    expect(venta.total, 439900.5);
    expect(venta.unidades, 3);
  });
}
