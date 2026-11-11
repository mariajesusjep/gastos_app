import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/gastos_provider.dart';
import 'screens/pantalla_gastos.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES'); // para ver las fechas en español
  runApp(
    ChangeNotifierProvider(
      create: (_) => GastosProvider()..cargar(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF48FB1), // rosa pastel
        ).copyWith(
          surface: const Color(0xFFFFF0F5), // fondo rosa muy suave
        ),
      ),
      home: const PantallaGastos(),
    );
  }
}