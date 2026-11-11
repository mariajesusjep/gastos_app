import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/gasto.dart';
import '../providers/gastos_provider.dart';

class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key});

  String _texto(double valor) => NumberFormat('0.####', 'es_ES').format(valor);

  // Cambiar el tipo de cambio de una moneda
  Future<void> _editarTasa(
    BuildContext context,
    String moneda,
    double actual,
  ) async {
    final controller = TextEditingController(text: _texto(actual));
    final nuevo = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tipo de cambio: $moneda'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '1 € = ',
            suffixText: monedas[moneda],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final valor =
                  double.tryParse(controller.text.replaceAll(',', '.'));
              if (valor != null && valor > 0) Navigator.pop(ctx, valor);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nuevo != null && context.mounted) {
      await context.read<GastosProvider>().guardarTasa(moneda, nuevo);
    }
  }

  // Añadir una moneda nueva
  Future<void> _anadirMoneda(BuildContext context) async {
    final provider = context.read<GastosProvider>();
    final codigoCtrl = TextEditingController();
    final simboloCtrl = TextEditingController();
    final tasaCtrl = TextEditingController();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Nueva moneda'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codigoCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 3,
                  decoration: const InputDecoration(
                    labelText: 'Código (ej. JPY)',
                    counterText: '',
                  ),
                ),
                TextField(
                  controller: simboloCtrl,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Símbolo (ej. ¥)',
                    counterText: '',
                  ),
                ),
                TextField(
                  controller: tasaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Unidades que equivalen a 1 €',
                    hintText: 'ej. 160',
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error!,
                      style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final codigo = codigoCtrl.text.trim().toUpperCase();
                final simbolo = simboloCtrl.text.trim();
                final tasa =
                    double.tryParse(tasaCtrl.text.replaceAll(',', '.'));

                String? problema;
                if (!RegExp(r'^[A-Z]{3}$').hasMatch(codigo)) {
                  problema = 'El código debe tener 3 letras (por ejemplo, JPY).';
                } else if (monedas.containsKey(codigo)) {
                  problema = 'Esa moneda ya existe.';
                } else if (simbolo.isEmpty) {
                  problema = 'Escribe un símbolo para la moneda.';
                } else if (tasa == null || tasa <= 0) {
                  problema = 'El tipo de cambio no es válido.';
                }

                if (problema != null) {
                  setStateDialog(() => error = problema);
                  return;
                }

                await provider.anadirMoneda(codigo, simbolo, tasa!);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );
  }

  // Borrar una moneda añadida por ti
  Future<void> _eliminarMoneda(BuildContext context, String codigo) async {
    final provider = context.read<GastosProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final eliminada = await provider.eliminarMoneda(codigo);
    if (!eliminada) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No se puede eliminar $codigo: hay gastos guardados en esa moneda.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GastosProvider>();
    final tasas = provider.tasas;
    final propias = provider.monedasPropias;
    final otras = monedas.keys.where((m) => m != monedaBase).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tipo de cambio: cuántas unidades de cada moneda equivalen a 1 €. '
              'Se usa al guardar un gasto para calcular su valor en euros. '
              'Si lo cambias, los gastos ya guardados no se modifican.\n\n'
              'Si te falta una moneda, añádela con el botón de abajo.',
            ),
          ),
          ...otras.map((m) {
            final esPropia = propias.containsKey(m);
            return ListTile(
              title: Text('$m  (${monedas[m]})'),
              subtitle: Text('1 € = ${_texto(tasas[m] ?? 1)} ${monedas[m]}'),
              trailing: esPropia
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Eliminar moneda',
                      onPressed: () => _eliminarMoneda(context, m),
                    )
                  : const Icon(Icons.edit),
              onTap: () => _editarTasa(context, m, tasas[m] ?? 1),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _anadirMoneda(context),
        icon: const Icon(Icons.add),
        label: const Text('Añadir moneda'),
      ),
    );
  }
}