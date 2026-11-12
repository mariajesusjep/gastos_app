import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/gasto.dart';
import '../providers/gastos_provider.dart';
import '../utils/iconos.dart';
import 'formulario_gasto.dart';
import 'pantalla_ajustes.dart';
import 'pantalla_resumen.dart';

class PantallaGastos extends StatelessWidget {
  const PantallaGastos({super.key});

  // Abre el formulario (nuevo gasto si no se pasa 'gasto', editar si se pasa)
  void _abrirModalGasto(BuildContext context, [Gasto? gasto]) {
    final dia = context.read<GastosProvider>().dia;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FormularioGastoModal(
        gastoParaEditar: gasto,
        fechaInicial: dia,
      ),
    );
  }

  Future<void> _elegirFecha(BuildContext context) async {
    final provider = context.read<GastosProvider>();
    final elegida = await showDatePicker(
      context: context,
      initialDate: provider.dia,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (elegida != null) provider.irAFecha(elegida);
  }

  bool _esHoy(DateTime dia) {
    final hoy = DateTime.now();
    return dia.year == hoy.year && dia.month == hoy.month && dia.day == hoy.day;
  }

  Widget _total(String titulo, double valor) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          formatearImporte(valor, monedaBase),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GastosProvider>();
    final dia = provider.dia;
    final gastos = provider.gastosDelDia;
    final textoDia = toBeginningOfSentenceCase(
          DateFormat('EEEE d MMM', 'es_ES').format(dia),
        ) ??
        '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Gastos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Resumen del mes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaResumen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaAjustes()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de día
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => provider.cambiarDia(-1),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => _elegirFecha(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month, size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    textoDia,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_esHoy(dia))
                          const Text('Hoy', style: TextStyle(fontSize: 12))
                        else
                          InkWell(
                            onTap: provider.irAHoy,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Text(
                                'Volver a hoy',
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => provider.cambiarDia(1),
                  ),
                ],
              ),
            ),
          ),

          // Totales: día, semana y mes (todo en euros)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _total('Día', provider.totalDia),
                    _total('Semana', provider.totalSemana),
                    _total('Mes', provider.totalMes),
                  ],
                ),
              ),
            ),
          ),

          // Aviso de copia de seguridad
          if (provider.avisarCopia)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text(
                    provider.diasDesdeCopia == null
                        ? 'Aún no has hecho ninguna copia de seguridad'
                        : 'Hace ${provider.diasDesdeCopia} días de tu última copia',
                  ),
                  subtitle: const Text('Toca para hacer una ahora'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Recordármelo mañana',
                    onPressed: provider.posponerAviso,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PantallaAjustes()),
                  ),
                ),
              ),
            ),

          // Gastos del día
          Expanded(
            child: gastos.isEmpty
                ? const Center(
                    child: Text(
                      'No hay gastos este día.\nPulsa + para añadir uno.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: gastos.length,
                    itemBuilder: (context, index) {
                      final item = gastos[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red.shade300,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          if (item.id != null) {
                            context.read<GastosProvider>().borrar(item.id!);
                          }
                        },
                        child: ListTile(
                         leading: CircleAvatar(
                            child: Text(
                              emojiCategoria(item.categoria),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(item.categoria),
                          subtitle: item.nota == null ? null : Text(item.nota!),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatearImporte(item.importe, item.moneda),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (item.moneda != monedaBase)
                                Text(
                                  '≈ ${formatearImporte(item.importeEur, monedaBase)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => _abrirModalGasto(context, item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirModalGasto(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}