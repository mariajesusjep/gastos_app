import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/gasto.dart';
import '../providers/gastos_provider.dart';
import '../utils/iconos.dart';

class PantallaResumen extends StatelessWidget {
  const PantallaResumen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GastosProvider>();
    final total = provider.totalMes;
    final porCategoria = provider.totalesPorCategoria;
    final mes = toBeginningOfSentenceCase(
          DateFormat('MMMM yyyy', 'es_ES').format(provider.dia),
        ) ??
        '';

    return Scaffold(
      appBar: AppBar(title: Text('Resumen · $mes')),
      body: porCategoria.isEmpty
          ? const Center(
              child: Text(
                'No hay gastos este mes.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(child: Text('Total del mes')),
                Center(
                  child: Text(
                    formatearImporte(total, monedaBase),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...porCategoria.entries.map((e) {
                  final porcentaje = e.value / total;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(emojiCategoria(e.key), style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${formatearImporte(e.value, monedaBase)}  '
                              '(${(porcentaje * 100).toStringAsFixed(0)}%)',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: porcentaje,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}