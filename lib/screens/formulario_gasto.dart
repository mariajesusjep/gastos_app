import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gasto.dart';
import '../providers/gastos_provider.dart';

class FormularioGastoModal extends StatefulWidget {
  final Gasto? gastoParaEditar;
  final DateTime fechaInicial;

  const FormularioGastoModal({
    super.key,
    this.gastoParaEditar,
    required this.fechaInicial,
  });

  @override
  State<FormularioGastoModal> createState() => _FormularioGastoModalState();
}

class _FormularioGastoModalState extends State<FormularioGastoModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _importeController;
  late TextEditingController _notaController;

  late String _moneda;
  late String _categoria;
  late DateTime _fecha;

  @override
  void initState() {
    super.initState();
    final g = widget.gastoParaEditar;
    _importeController = TextEditingController(
      text: g != null ? g.importe.toStringAsFixed(2) : '',
    );
    _notaController = TextEditingController(text: g?.nota ?? '');
    _moneda = g?.moneda ?? 'PLN';
    _categoria = g?.categoria ?? categorias.first;
    _fecha = g?.fecha ?? widget.fechaInicial;
  }

  @override
  void dispose() {
    _importeController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final importe =
        double.tryParse(_importeController.text.replaceAll(',', '.')) ?? 0.0;
    final provider = context.read<GastosProvider>();
    final nota = _notaController.text.trim().isEmpty
        ? null
        : _notaController.text.trim();
    final original = widget.gastoParaEditar;

    // Si editas y no cambias ni el importe ni la moneda, se conserva
    // el equivalente en euros que ya tenía
    final importeEur = (original != null &&
            original.importe == importe &&
            original.moneda == _moneda)
        ? original.importeEur
        : provider.calcularEur(importe, _moneda);

    final gasto = Gasto(
      id: original?.id,
      importe: importe,
      moneda: _moneda,
      importeEur: importeEur,
      categoria: _categoria,
      fecha: _fecha,
      nota: nota,
    );

    if (original == null) {
      provider.anadir(gasto);
    } else {
      provider.editar(gasto);
    }

    Navigator.pop(context);
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.gastoParaEditar == null ? 'Nuevo Gasto' : 'Editar Gasto',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _importeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Importe',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payments),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obligatorio';
                        final valor = double.tryParse(v.replaceAll(',', '.'));
                        if (valor == null || valor <= 0) {
                          return 'Importe no válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _moneda,
                      decoration: const InputDecoration(
                        labelText: 'Moneda',
                        border: OutlineInputBorder(),
                      ),
                      items: monedas.keys
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _moneda = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notaController,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _elegirFecha,
                icon: const Icon(Icons.calendar_today),
                label: Text('${_fecha.day}/${_fecha.month}/${_fecha.year}'),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.check),
                label: Text(
                  widget.gastoParaEditar == null ? 'Añadir' : 'Guardar Cambios',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}