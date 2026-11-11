import 'package:flutter/foundation.dart';
import '../data/base_datos.dart';
import '../models/gasto.dart';

class GastosProvider extends ChangeNotifier {
  final BaseDatos _bd = BaseDatos.instancia;

  DateTime _dia = _soloFecha(DateTime.now());
  List<Gasto> _gastosDelDia = [];
  List<Gasto> _gastosDeLaSemana = [];
  List<Gasto> _gastosDelMes = [];
  Map<String, double> _tasas = Map.of(tasasPorDefecto);
    Map<String, String> _monedasPropias = {};
  // Quita la hora: 11/11/2026 15:30 -> 11/11/2026 00:00
  static DateTime _soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);

  DateTime get dia => _dia;
  List<Gasto> get gastosDelDia => _gastosDelDia;
  Map<String, double> get tasas => _tasas;
    Map<String, String> get monedasPropias => _monedasPropias;

  double get totalDia => _sumar(_gastosDelDia);
  double get totalSemana => _sumar(_gastosDeLaSemana);
  double get totalMes => _sumar(_gastosDelMes);

  double _sumar(List<Gasto> lista) =>
      lista.fold(0.0, (suma, g) => suma + g.importeEur);

  // Total del mes por categoría (en euros), de mayor a menor
  Map<String, double> get totalesPorCategoria {
    final totales = <String, double>{};
    for (final g in _gastosDelMes) {
      totales[g.categoria] = (totales[g.categoria] ?? 0) + g.importeEur;
    }
    final ordenado = totales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(ordenado);
  }

  // Convierte un importe de cualquier moneda a euros
  double calcularEur(double importe, String moneda) {
    final tasa = _tasas[moneda] ?? 1.0;
    return importe / tasa;
  }

  // Carga de la base de datos el día, la semana y el mes que estás viendo
  Future<void> cargar() async {
    _tasas = await _bd.leerTasas();
    _monedasPropias = await _bd.leerMonedasPropias();
    monedas.addAll(_monedasPropias);

    final lunes = DateTime(_dia.year, _dia.month, _dia.day - (_dia.weekday - 1));
    final finSemana = DateTime(lunes.year, lunes.month, lunes.day + 7);
    final inicioMes = DateTime(_dia.year, _dia.month, 1);
    final finMes = DateTime(_dia.year, _dia.month + 1, 1);
    final diaSiguiente = DateTime(_dia.year, _dia.month, _dia.day + 1);

    _gastosDelDia = await _bd.gastosEntre(_dia, diaSiguiente);
    _gastosDeLaSemana = await _bd.gastosEntre(lunes, finSemana);
    _gastosDelMes = await _bd.gastosEntre(inicioMes, finMes);
    notifyListeners();
  }

  // Cambiar de día: -1 = ayer, +1 = mañana
  Future<void> cambiarDia(int dias) async {
    _dia = DateTime(_dia.year, _dia.month, _dia.day + dias);
    await cargar();
  }

  Future<void> irAFecha(DateTime fecha) async {
    _dia = _soloFecha(fecha);
    await cargar();
  }

  Future<void> irAHoy() => irAFecha(DateTime.now());

  Future<void> anadir(Gasto gasto) async {
    await _bd.insertar(gasto);
    await cargar();
  }

  Future<void> editar(Gasto gasto) async {
    await _bd.actualizar(gasto);
    await cargar();
  }

  Future<void> borrar(int id) async {
    await _bd.borrar(id);
    await cargar();
  }

  Future<void> guardarTasa(String moneda, double tasa) async {
    _tasas[moneda] = tasa;
    await _bd.guardarTasas(_tasas);
    notifyListeners();
  }
    Future<void> anadirMoneda(String codigo, String simbolo, double tasa) async {
    _monedasPropias[codigo] = simbolo;
    monedas[codigo] = simbolo;
    _tasas[codigo] = tasa;
    await _bd.guardarMonedasPropias(_monedasPropias);
    await _bd.guardarTasas(_tasas);
    notifyListeners();
  }

  // Devuelve false si no se puede eliminar porque hay gastos en esa moneda
  Future<bool> eliminarMoneda(String codigo) async {
    if (await _bd.monedaEnUso(codigo)) return false;
    _monedasPropias.remove(codigo);
    monedas.remove(codigo);
    _tasas.remove(codigo);
    await _bd.guardarMonedasPropias(_monedasPropias);
    await _bd.guardarTasas(_tasas);
    notifyListeners();
    return true;
  }
}