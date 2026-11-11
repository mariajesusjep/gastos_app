import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gasto.dart';

class BaseDatos {
  static final BaseDatos instancia = BaseDatos._();
  BaseDatos._();

  static const _claveGastos = 'gastos';
  static const _claveTasas = 'tasas';
  static const _claveSiguienteId = 'siguiente_id';

  // Lee TODOS los gastos guardados
  Future<List<Gasto>> _leerTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveGastos);
    if (texto == null) return [];
    final lista = jsonDecode(texto) as List<dynamic>;
    return lista
        .map((e) => Gasto.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // Guarda TODOS los gastos (como un único texto en formato JSON)
  Future<void> _guardarTodos(List<Gasto> gastos) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = jsonEncode(gastos.map((g) => g.toMap()).toList());
    await prefs.setString(_claveGastos, texto);
  }

  // Inventa un id nuevo: 1, 2, 3...
  Future<int> _nuevoId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = (prefs.getInt(_claveSiguienteId) ?? 0) + 1;
    await prefs.setInt(_claveSiguienteId, id);
    return id;
  }

  Future<void> insertar(Gasto gasto) async {
    final todos = await _leerTodos();
    final id = await _nuevoId();
    todos.add(gasto.conId(id));
    await _guardarTodos(todos);
  }

  // Gastos con fecha desde 'inicio' (incluida) hasta 'fin' (sin incluir)
  Future<List<Gasto>> gastosEntre(DateTime inicio, DateTime fin) async {
    final todos = await _leerTodos();
    final lista = todos
        .where((g) => !g.fecha.isBefore(inicio) && g.fecha.isBefore(fin))
        .toList();
    // Más recientes primero
    lista.sort((a, b) {
      final porFecha = b.fecha.compareTo(a.fecha);
      return porFecha != 0 ? porFecha : (b.id ?? 0).compareTo(a.id ?? 0);
    });
    return lista;
  }

  Future<void> actualizar(Gasto gasto) async {
    final todos = await _leerTodos();
    final i = todos.indexWhere((g) => g.id == gasto.id);
    if (i != -1) todos[i] = gasto;
    await _guardarTodos(todos);
  }

  Future<void> borrar(int id) async {
    final todos = await _leerTodos();
    todos.removeWhere((g) => g.id == id);
    await _guardarTodos(todos);
  }

  // Tipos de cambio: los guardados, y los de ejemplo para los que falten
  Future<Map<String, double>> leerTasas() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveTasas);
    final guardadas = <String, double>{};
    if (texto != null) {
      final mapa = jsonDecode(texto) as Map<String, dynamic>;
      mapa.forEach((moneda, valor) => guardadas[moneda] = (valor as num).toDouble());
    }
    return {...tasasPorDefecto, ...guardadas};
  }

  Future<void> guardarTasas(Map<String, double> tasas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveTasas, jsonEncode(tasas));
  }
    static const _claveMonedas = 'monedas_propias';

  // Monedas que ha añadido la usuaria: código -> símbolo
  Future<Map<String, String>> leerMonedasPropias() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveMonedas);
    if (texto == null) return {};
    final mapa = jsonDecode(texto) as Map<String, dynamic>;
    return mapa.map((codigo, simbolo) => MapEntry(codigo, simbolo as String));
  }

  Future<void> guardarMonedasPropias(Map<String, String> propias) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveMonedas, jsonEncode(propias));
  }

  // ¿Hay algún gasto guardado en esta moneda?
  Future<bool> monedaEnUso(String codigo) async {
    final todos = await _leerTodos();
    return todos.any((g) => g.moneda == codigo);
  }
}