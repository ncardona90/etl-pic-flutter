import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';
import 'package:etl_tamizajes_app/core/services/firebase_service.dart';
import 'package:etl_tamizajes_app/features/auth/auth_provider.dart'; // <-- CORRECCIÓN DE IMPORTACIÓN
import 'package:etl_tamizajes_app/features/data_master/data_master_provider.dart';

class DataMasterView extends StatelessWidget {
  const DataMasterView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          DataMasterProvider(firebaseService: context.read<FirebaseService>()),
      child: const _DataMasterViewBody(),
    );
  }
}

class _DataMasterViewBody extends StatefulWidget {
  const _DataMasterViewBody();
  @override
  State<_DataMasterViewBody> createState() => _DataMasterViewBodyState();
}

class _DataMasterViewBodyState extends State<_DataMasterViewBody> {
  // El StateManager ahora es nulable y se maneja localmente.
  PlutoGridStateManager? gridStateManager;

  // Se inicializan las columnas una sola vez para mejorar el rendimiento.
  late final List<PlutoColumn> columns;

  @override
  void initState() {
    super.initState();
    columns = _buildColumns();
  }

  List<PlutoColumn> _buildColumns() {
    final sampleTamizaje = Tamizaje.fromMap({'numero_documento': '0'});
    final fields = sampleTamizaje.toMap().keys.toList();

    return fields.where((key) => key != '_sourceFile' && key != 'id').map((
      key,
    ) {
      return PlutoColumn(
        title: key
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
            .join(' '),
        field: key,
        type: _getColumnType(key),
      );
    }).toList();
  }

  static PlutoColumnType _getColumnType(String key) {
    if (key.contains('fecha')) return PlutoColumnType.date();
    if (key.contains('edad') ||
        key.contains('imc') ||
        key.contains('peso') ||
        key.contains('talla') ||
        key.contains('puntaje') ||
        key.contains('documento')) {
      return PlutoColumnType.number();
    }
    return PlutoColumnType.text();
  }

  List<PlutoRow> _buildRows(List<Tamizaje> records) {
    return records.map((record) {
      final recordMap = record.toMap();
      return PlutoRow(
        cells: {
          for (var entry in recordMap.entries)
            if (entry.key != '_sourceFile' && entry.key != 'id')
              entry.key: PlutoCell(value: entry.value),
        },
      );
    }).toList();
  }

  void _showFindAndReplaceDialog() {
    if (gridStateManager == null || gridStateManager!.checkedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, seleccione al menos una fila para actualizar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<DataMasterProvider>(),
        child: _FindAndReplaceDialog(stateManager: gridStateManager!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isAdmin) {
      return const Center(
        child: Text('Acceso denegado. Se requieren permisos de administrador.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maestro de Datos de Tamizajes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.find_replace),
            tooltip: 'Buscar y Reemplazar',
            onPressed: _showFindAndReplaceDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar Datos',
            onPressed: () =>
                context.read<DataMasterProvider>().fetchInitialData(),
          ),
        ],
      ),
      body: Consumer<DataMasterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.allRecords.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.allRecords.isEmpty) {
            return const Center(child: Text('No se encontraron registros.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: PlutoGrid(
              columns: columns,
              rows: _buildRows(provider.allRecords),
              onLoaded: (event) {
                gridStateManager = event.stateManager;
                provider.setGridStateManager(event.stateManager);
                gridStateManager?.setShowColumnFilter(true);
              },
              onRowChecked: (event) {
                // Forzamos la reconstrucción para que la UI se entere de los cambios en checkedRows.
                setState(() {});
              },
              mode: PlutoGridMode.multiSelect,
              configuration: const PlutoGridConfiguration(
                localeText: PlutoGridLocaleText.spanish(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FindAndReplaceDialog extends StatefulWidget {
  const _FindAndReplaceDialog({required this.stateManager});
  final PlutoGridStateManager stateManager;

  @override
  State<_FindAndReplaceDialog> createState() => _FindAndReplaceDialogState();
}

class _FindAndReplaceDialogState extends State<_FindAndReplaceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedField;
  final _replaceController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _replaceController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<DataMasterProvider>();
    final docIds = widget.stateManager.checkedRows
        .map((row) => row.cells['numero_documento']!.value.toString())
        .toList();

    // *** CORRECCIÓN: La llamada ahora es consistente con el provider. ***
    final result = await provider.findAndReplace(
      fieldName: _selectedField!,
      replaceValue: _replaceController.text,
      selectedRows: widget.stateManager.checkedRows,
    );

    if (!mounted) return;

    final message = result ?? 'Operación completada con éxito.';
    final color = result == null ? Colors.green : Colors.red;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fieldOptions = widget.stateManager.columns
        .map((c) => c.field)
        .toList();
    final selectedRowCount = widget.stateManager.checkedRows.length;

    return AlertDialog(
      title: const Text('Actualización Masiva'),
      content: _isSaving
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Se actualizarán $selectedRowCount registros seleccionados.',
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _selectedField,
                    decoration: const InputDecoration(
                      labelText: 'Columna a modificar',
                      border: OutlineInputBorder(),
                    ),
                    items: fieldOptions
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedField = value),
                    validator: (v) =>
                        v == null ? 'Seleccione una columna' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _replaceController,
                    decoration: const InputDecoration(
                      labelText: 'Nuevo Valor',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese un valor' : null,
                  ),
                ],
              ),
            ),
      actions: _isSaving
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _onConfirm,
                child: const Text('Ejecutar Reemplazo'),
              ),
            ],
    );
  }
}
