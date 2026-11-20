// Formatos de dinero de la app. Cada pantalla conserva el suyo:
// - dinero: comprobante y notificación de venta.
// - dineroSinMiles: Home (0 decimales), Mis Ventas, Nueva Venta e
//   Inventario (2 decimales).

/// Dinero con separador de miles: 1234.5 -> $1,234.50
String dinero(double v) {
  final partes = v.toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return '\$$entero.${partes[1]}';
}

/// Dinero sin separador de miles: 1234.5 -> $1234.50 ($1235 con 0 decimales).
String dineroSinMiles(double v, {int decimales = 2}) =>
    '\$${v.toStringAsFixed(decimales)}';

