// lib/features/data_management/record_list_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';
import 'package:etl_tamizajes_app/core/services/firebase_service.dart';
import 'package:etl_tamizajes_app/features/auth/auth_provider.dart';
import 'package:etl_tamizajes_app/features/data_management/data_management_provider.dart';
import 'package:etl_tamizajes_app/features/data_management/formulario_tamizaje_view.dart';

// --- VISTA PRINCIPAL (SIN CAMBIOS) ---
class RecordListView extends StatelessWidget {
  const RecordListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DataManagementProvider(
        firebaseService: context.read<FirebaseService>(),
      ),
      child: const _RecordListViewBody(),
    );
  }
}

class _RecordListViewBody extends StatefulWidget {
  const _RecordListViewBody();

  @override
  State<_RecordListViewBody> createState() => __RecordListViewBodyState();
}

class __RecordListViewBodyState extends State<_RecordListViewBody> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<DataManagementProvider>().filterRecords(
        _searchController.text,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- MÉTODO _showRecordForm CORREGIDO ---
  void _showRecordForm(BuildContext context, {Tamizaje? record}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Este es el contexto correcto para el Dialog
        return MultiProvider(
          providers: [
            // Se usa context.read porque solo necesitamos la instancia del provider,
            // no necesitamos que este widget se reconstruya si el provider cambia.
            ChangeNotifierProvider.value(
              value: context.read<DataManagementProvider>(),
            ),
            ChangeNotifierProvider.value(value: context.read<AuthProvider>()),
          ],
          child: FormularioTamizajeView(
            initialData: record,
            onSave: (tamizaje) async {
              final provider = context.read<DataManagementProvider>();
              final error = await provider.saveRecord(tamizaje);

              // Usar 'dialogContext' para el ScaffoldMessenger y el Navigator
              if (!dialogContext.mounted) return;

              if (error != null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Registro guardado con éxito.'),
                    backgroundColor: Colors.green,
                  ),
                );
                // CORRECCIÓN CLAVE: Usar dialogContext para cerrar el diálogo
                Navigator.of(dialogContext).pop();
              }
            },
            // CORRECCIÓN CLAVE: Usar dialogContext para el botón de cancelar
            onCancel: () => Navigator.of(dialogContext).pop(),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Tamizaje record) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Estás seguro de que deseas eliminar permanentemente el registro de ${record.nombres} ${record.apellidos}?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final provider = context.read<DataManagementProvider>();
                final success = await provider.deleteRecord(record.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Registro eliminado con éxito.'
                            : 'Error al eliminar el registro.',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataManagementProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Datos'),
        actions: [
          IconButton(
            icon: Icon(
              provider.viewMode == ViewMode.list
                  ? Icons.grid_view
                  : Icons.view_list,
            ),
            tooltip: provider.viewMode == ViewMode.list
                ? 'Vista Mosaico'
                : 'Vista Lista',
            onPressed: () => provider.setViewMode(
              provider.viewMode == ViewMode.list
                  ? ViewMode.grid
                  : ViewMode.list,
            ),
          ),
          if (authProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Añadir Nuevo Registro',
              onPressed: () => _showRecordForm(context),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, documento, creador...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, DataManagementProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }
    if (provider.records.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'No hay registros para mostrar.'
              : 'No se encontraron registros para "${_searchController.text}".',
        ),
      );
    }
    return provider.viewMode == ViewMode.list
        ? _buildListView(context, provider.records)
        : _buildGridView(context, provider.records);
  }

  Widget _buildListView(BuildContext context, List<Tamizaje> tamizajes) {
    final authProvider = context.watch<AuthProvider>();
    return ListView.builder(
      itemCount: tamizajes.length,
      itemBuilder: (context, index) {
        final record = tamizajes[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                record.nombres.isNotEmpty
                    ? record.nombres.substring(0, 1)
                    : '?',
              ),
            ),
            title: Text(
              '${record.nombres} ${record.apellidos}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Doc: ${record.numeroDocumento} | Cargado por: ${record.uploadedBy}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (authProvider.isAdmin || authProvider.isEnfermeraJefe)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showRecordForm(context, record: record),
                  ),
                if (authProvider.isAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(context, record),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context, List<Tamizaje> tamizajes) {
    final authProvider = context.watch<AuthProvider>();
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: tamizajes.length,
      itemBuilder: (context, index) {
        final record = tamizajes[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          child: InkWell(
            onTap: (authProvider.isAdmin || authProvider.isEnfermeraJefe)
                ? () => _showRecordForm(context, record: record)
                : null,
            child: GridTile(
              footer: GridTileBar(
                backgroundColor: Colors.black45,
                title: Text(record.eps, overflow: TextOverflow.ellipsis),
                subtitle: Text('${record.tipoDoc}: ${record.numeroDocumento}'),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, size: 40, color: Colors.indigo),
                    const SizedBox(height: 8),
                    Text(
                      record.nombres,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      record.apellidos,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
