import 'package:intl/intl.dart';

// Moneda en la que se muestran todos los totales
const String monedaBase = 'EUR';

class Gasto {
  final int? id;
  final double importe;
  final String moneda;
  final double importeEur; // equivalente en euros, calculado al guardar
  final String categoria;
  final DateTime fecha;
  final String? nota;

  Gasto({
    this.id,
    required this.importe,
    required this.moneda,
    required this.importeEur,
    required this.categoria,
    required this.fecha,
    this.nota,
  });

  // Copia de este gasto con un id nuevo
  Gasto conId(int nuevoId) {
    return Gasto(
      id: nuevoId,
      importe: importe,
      moneda: moneda,
      importeEur: importeEur,
      categoria: categoria,
      fecha: fecha,
      nota: nota,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'importe': importe,
      'moneda': moneda,
      'importeEur': importeEur,
      'categoria': categoria,
      'fecha': fecha.toIso8601String(),
      'nota': nota,
    };
  }

  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'] as int?,
      importe: (map['importe'] as num).toDouble(),
      moneda: map['moneda'] as String,
      importeEur: (map['importeEur'] as num).toDouble(),
      categoria: map['categoria'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      nota: map['nota'] as String?,
    );
  }
}

const List<String> categorias = [
  'Comida',
  'Transporte',
  'Fiesta',
  'Casa',
  'Salud',
  'Viajes',
  'Ropa',
  'Otros',
];

// Monedas disponibles: código -> símbolo
final Map<String, String> monedas = {  'EUR': '€',
  'PLN': 'zł',
  'USD': '\$',
  'GBP': '£',
  'CZK': 'Kč',
  'HUF': 'Ft',
};

// Cuántas unidades de cada moneda equivalen a 1 euro.
// Son valores de EJEMPLO: ajústalos a los reales en la pantalla de Ajustes.
const Map<String, double> tasasPorDefecto = {
  'EUR': 1.0,
  'PLN': 4.25,
  'USD': 1.10,
  'GBP': 0.85,
  'CZK': 25.0,
  'HUF': 400.0,
};

String formatearImporte(double importe, String moneda) {
  final formato = NumberFormat.currency(
    locale: 'es_ES',
    symbol: monedas[moneda] ?? moneda,
  );
  return formato.format(importe);
}