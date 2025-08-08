// --- lib/features/upload/upload_view.dart ---

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Se eliminan imports innecesarios como firebase_service
import 'package:etl_tamizajes_app/core/models/etl_result.dart';
import 'package:etl_tamizajes_app/features/upload/upload_provider.dart';

class UploadView extends StatelessWidget {
  const UploadView({super.key});

  @override
  Widget build(BuildContext context) {
    // --- CORRECCIÓN APLICADA ---
    // Se eliminó el ChangeNotifierProvider que envolvía el Scaffold.
    // La vista ahora usará la instancia de UploadProvider creada en main.dart.
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Stack(children: [UploadBody(), LoadingOverlay()]),
    );
  }
}

// --- WIDGET AJUSTADO PARA SER RESPONSIVE ---
class UploadBody extends StatelessWidget {
  const UploadBody({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Se define un punto de quiebre para pantallas pequeñas (móviles)
        final bool isMobile = constraints.maxWidth < 650;

        // En pantallas grandes, se centra el contenido con un ancho máximo
        if (!isMobile) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 2560),
              child: const _UploadContent(),
            ),
          );
        } else {
          // En pantallas pequeñas, el contenido ocupa todo el ancho
          return const _UploadContent();
        }
      },
    );
  }
}

// Widget interno que contiene la lógica de la UI para evitar duplicación
class _UploadContent extends StatelessWidget {
  const _UploadContent();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 32.0, // Menos padding en móviles
        vertical: 24.0,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Header(),
          SizedBox(height: 32),
          FilePickerArea(),
          SizedBox(height: 24),
          SelectedFilesList(),
          SizedBox(height: 24),
          ProcessButton(),
          SizedBox(height: 32),
          ResultSection(),
          SizedBox(height: 48),
          Footer(),
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});
  @override
  Widget build(BuildContext context) => Consumer<UploadProvider>(
    builder: (context, provider, child) {
      if (!provider.isLoading) return const SizedBox.shrink();
      return Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                provider.loadingMessage,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class Header extends StatelessWidget {
  const Header({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        'Plataforma de Consolidación de Datos',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'Carga, valida y consolida los datos de tamizajes en la base de datos central.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: Colors.black54),
      ),
    ],
  );
}

class FilePickerArea extends StatelessWidget {
  const FilePickerArea({super.key});
  @override
  Widget build(BuildContext context) => Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () => context.read<UploadProvider>().pickFiles(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: const Column(
            children: [
              Icon(Icons.cloud_upload_outlined, size: 60, color: Colors.indigo),
              SizedBox(height: 16),
              Text(
                'Haz clic para cargar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Puedes seleccionar múltiples archivos JSON',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SelectedFilesList extends StatelessWidget {
  const SelectedFilesList({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UploadProvider>();
    if (provider.selectedFiles.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Archivos Seleccionados:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: () =>
                      context.read<UploadProvider>().clearSelection(),
                  tooltip: 'Limpiar selección',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: provider.selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = provider.selectedFiles[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                      color: Colors.blue,
                    ),
                    title: Text(
                      file.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${(file.size / 1024).toStringAsFixed(2)} KB',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessButton extends StatelessWidget {
  const ProcessButton({super.key});
  void _showDuplicateWarning(BuildContext context, EtlResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivos Ya Procesados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Algunos de los archivos seleccionados ya fueron procesados y serán omitidos:',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              width: 300,
              child: ListView(
                children: result.duplicateFileNames
                    .map((name) => Text('• $name'))
                    .toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.settings_applications_outlined),
      label: const Text('Procesar y Cargar a la Base de Datos'),
      onPressed: context.watch<UploadProvider>().selectedFiles.isNotEmpty
          ? () async {
              final provider = context.read<UploadProvider>();
              final result = await provider.processAndUploadFiles();
              if (context.mounted &&
                  result != null &&
                  result.duplicateFileNames.isNotEmpty) {
                _showDuplicateWarning(context, result);
              }
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class ResultSection extends StatelessWidget {
  const ResultSection({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UploadProvider>();
    final result = provider.lastResult;
    if (result == null) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reporte del Lote Procesado',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            _buildResultRow(
              'Archivos Omitidos (Duplicados)',
              result.duplicateFileCount.toString(),
              Colors.orange.shade700,
            ),
            _buildResultRow(
              'Registros Válidos Cargados',
              result.validRecords.length.toString(),
              Colors.green.shade700,
            ),
            _buildResultRow(
              'Registros con Fallos',
              result.failedRecords.length.toString(),
              Colors.red.shade700,
            ),
            if (result.failedRecords.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                spacing: 20,
                children: [
                  Text(
                    'Detalle de Registros No Cargados',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.download_for_offline_outlined,
                      size: 20,
                    ),
                    label: const Text('Descargar Reporte'),
                    onPressed: () => provider.downloadFailedRecordsReport(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFailedRecordsTable(result.failedRecords),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String title, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
      ],
    ),
  );

  // --- TABLA DE ERRORES MEJORADA Y RESPONSIVA ---
  Widget _buildFailedRecordsTable(List<Map<String, dynamic>> failedRecords) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
              columns: const [
                DataColumn(
                  label: Text(
                    'Archivo Origen',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'N° Documento',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Nombre',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Motivo del Rechazo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: failedRecords
                  .map(
                    (record) => DataRow(
                      cells: [
                        DataCell(Text(record['_sourceFile'] ?? 'N/A')),
                        DataCell(
                          Text(record['numero_documento']?.toString() ?? 'N/A'),
                        ),
                        DataCell(
                          Text(
                            "${record['nombres'] ?? ''} ${record['apellidos'] ?? ''}",
                          ),
                        ),
                        DataCell(
                          Text(record['motivo_fallo'] ?? 'Error desconocido'),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 24.0),
    child: Text(
      '© 2025 Plataforma de Consolidación de Datos. ESEORIENTE - FORJU.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey),
    ),
  );
}
