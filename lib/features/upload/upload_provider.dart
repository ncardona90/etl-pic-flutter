// --- lib/features/upload/upload_provider.dart ---

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:collection/collection.dart';
import 'package:excel/excel.dart';

import 'package:etl_tamizajes_app/core/services/firebase_service.dart';
import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';
import 'package:etl_tamizajes_app/core/models/etl_result.dart';
import 'package:etl_tamizajes_app/features/auth/auth_provider.dart';

class UploadProvider with ChangeNotifier {
  UploadProvider({
    required FirebaseService firebaseService,
    required AuthProvider authProvider,
  }) : _firebaseService = firebaseService,
       _authProvider = authProvider;

  final FirebaseService _firebaseService;
  final AuthProvider _authProvider;

  // --- Estado Interno del Provider ---
  bool _isLoading = false;
  String _loadingMessage = '';
  List<PlatformFile> _selectedFiles = [];
  EtlResult? _lastResult;

  // --- Getters Públicos ---
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  List<PlatformFile> get selectedFiles => _selectedFiles;
  EtlResult? get lastResult => _lastResult;

  /// Campos requeridos para que un registro sea considerado para procesamiento.
  static const Set<String> _requiredFields = {
    'fecha_intervencion',
    'entorno_intervencion',
    'nombres',
    'apellidos',
    'numero_documento',
    'fecha_nacimiento',
    'edad',
    'sexo_asignado_nacimiento',
    'comuna',
    'talla',
    'peso',
    'presion_sistolica',
    'presion_diastolica',
    'circunferencia_abdominal',
    'actividad_fisica',
    'frecuencia_frutas_verduras',
    'medicacion_hipertension',
    'glucosa_alta_historico',
    'antecedentes_familiares_diabetes',
    'es_diabetico',
    'fuma',
    'enfermedad_cardiovascular_renal_colesterol',
  };

  /// Permite al usuario seleccionar uno o más archivos JSON.
  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      _selectedFiles = result.files;
      _lastResult =
          null; // Limpia resultados anteriores al seleccionar nuevos archivos
      notifyListeners();
    }
  }

  /// Limpia la selección de archivos actual.
  void clearSelection() {
    _selectedFiles = [];
    _lastResult = null;
    notifyListeners();
  }

  /// Orquesta todo el proceso de ETL: validación, procesamiento y carga.
  Future<EtlResult?> processAndUploadFiles() async {
    if (_selectedFiles.isEmpty) return null;
    _setLoading(true, 'Iniciando proceso...');

    // 1. Filtrar archivos que ya han sido procesados anteriormente.
    final filesToProcessResult = await _filterNewFiles(_selectedFiles);
    final newFiles = filesToProcessResult['newFiles']!;
    final duplicateFileNames = filesToProcessResult['duplicateNames']!;

    if (newFiles.isEmpty) {
      _lastResult = EtlResult(
        validRecords: [],
        failedRecords: [],
        duplicateFileNames: duplicateFileNames.map((e) => e.name).toList(),
      );
      _setLoading(false);
      return _lastResult;
    }

    // 2. Leer y consolidar todos los registros de los archivos nuevos.
    _setLoading(true, 'Consolidando ${newFiles.length} archivo(s)...');
    final uploaderName = _authProvider.user?.displayName ?? 'Desconocido';

    // --- CORRECCIÓN APLICADA AQUÍ ---
    // Se pasa 'uploaderName' como segundo argumento a la función.
    final allRecords = _consolidateRecordsFromFiles(newFiles, uploaderName);

    // 3. Procesar y validar los datos consolidados.
    _setLoading(true, 'Validando ${allRecords.length} registros...');
    final etlResult = _processAndValidateData(allRecords);

    // 4. Subir el lote de registros válidos a Firebase.
    if (etlResult.validRecords.isNotEmpty) {
      _setLoading(
        true,
        'Guardando ${etlResult.validRecords.length} registros válidos...',
      );
      await _firebaseService.uploadTamizajesBatch(etlResult.validRecords);
    }

    // 5. Registrar los archivos que fueron procesados con éxito.
    await _registerProcessedFiles(newFiles, etlResult.validRecords);

    // 6. Guardar el resultado final para la UI y finalizar la carga.
    _lastResult = EtlResult(
      validRecords: etlResult.validRecords,
      failedRecords: etlResult.failedRecords,
      duplicateFileNames: duplicateFileNames.map((e) => e.name).toList(),
    );
    _setLoading(false);
    return _lastResult;
  }

  // --- MÉTODOS AUXILIARES DEL PROCESO ETL ---

  /// Filtra una lista de archivos para separar los nuevos de los ya procesados.
  Future<Map<String, List<PlatformFile>>> _filterNewFiles(
    List<PlatformFile> files,
  ) async {
    _setLoading(true, 'Verificando archivos procesados...');
    final newFiles = <PlatformFile>[];
    final duplicateNames = <PlatformFile>[];
    for (final file in files) {
      final hash = _calculateFileHash(file.bytes!);
      if (await _firebaseService.isFileProcessed(hash)) {
        duplicateNames.add(file);
      } else {
        newFiles.add(file);
      }
    }
    return {'newFiles': newFiles, 'duplicateNames': duplicateNames};
  }

  /// Lee el contenido de múltiples archivos JSON y los consolida en una sola lista.
  List<Map<String, dynamic>> _consolidateRecordsFromFiles(
    List<PlatformFile> files,
    String uploaderName,
  ) {
    final allRecords = <Map<String, dynamic>>[];
    for (var file in files) {
      try {
        final content = utf8.decode(file.bytes!);
        final jsonData = json.decode(content) as List<dynamic>;
        allRecords.addAll(
          jsonData.cast<Map<String, dynamic>>().map(
            (r) => {
              ...r,
              '_sourceFile': file.name,
              'uploaded_by': uploaderName,
            },
          ),
        );
      } catch (e) {
        debugPrint('Error decodificando el archivo ${file.name}: $e');
      }
    }
    return allRecords;
  }

  /// Lógica principal de validación: duplicados, campos faltantes y conversión de datos.
  EtlResult _processAndValidateData(List<Map<String, dynamic>> records) {
    final validRecords = <Tamizaje>[];
    final failedRecords = <Map<String, dynamic>>[];

    final recordsByDoc = records.groupListsBy(
      (r) => r['numero_documento']?.toString().trim(),
    );

    recordsByDoc.forEach((docNum, group) {
      if (docNum == null || docNum.isEmpty) {
        for (var record in group) {
          failedRecords.add({
            ...record,
            'motivo_fallo': 'Número de documento faltante o inválido.',
          });
        }
        return;
      }

      final idealCandidate = _findBestCandidate(group);

      if (idealCandidate == null) {
        final recordToReport = group.first;
        final missingFields = _getMissingFields(recordToReport);
        failedRecords.add({
          ...recordToReport,
          'motivo_fallo':
              'Datos requeridos faltantes: ${missingFields.join(', ')}.',
        });
        return;
      }

      try {
        final tamizaje = Tamizaje.fromMap(idealCandidate);
        validRecords.add(tamizaje);

        failedRecords.addAll(
          group
              .where((r) => r != idealCandidate)
              .map(
                (r) => {
                  ...r,
                  'motivo_fallo':
                      'Duplicado dentro del lote (se eligió el registro más completo).',
                },
              ),
        );
      } on ArgumentError catch (e) {
        failedRecords.add({...idealCandidate, 'motivo_fallo': e.message});
      } catch (e) {
        failedRecords.add({
          ...idealCandidate,
          'motivo_fallo': 'Error de conversión inesperado: $e',
        });
      }
    });

    return EtlResult(
      validRecords: validRecords,
      failedRecords: failedRecords,
      duplicateFileNames: [],
    );
  }

  /// De un grupo de registros duplicados, encuentra el más completo.
  Map<String, dynamic>? _findBestCandidate(List<Map<String, dynamic>> group) {
    Map<String, dynamic>? bestCandidate;
    int minMissingFields = _requiredFields.length + 1;

    for (final record in group) {
      final missingFieldsCount = _getMissingFields(record).length;
      if (missingFieldsCount < minMissingFields) {
        minMissingFields = missingFieldsCount;
        bestCandidate = record;
      }
      if (minMissingFields == 0) break;
    }
    return (minMissingFields == 0) ? bestCandidate : null;
  }

  /// Devuelve una lista de campos requeridos que faltan en un registro.
  List<String> _getMissingFields(Map<String, dynamic> record) {
    return _requiredFields.where((field) {
      final value = record[field];
      return value == null || (value is String && value.trim().isEmpty);
    }).toList();
  }

  /// Registra en la base de datos los archivos que se procesaron exitosamente.
  Future<void> _registerProcessedFiles(
    List<PlatformFile> processedFiles,
    List<Tamizaje> validRecords,
  ) async {
    if (validRecords.isEmpty) return;

    final validSourceFiles = validRecords.map((r) => r.sourceFile).toSet();
    final filesToRegister = processedFiles
        .where((f) => validSourceFiles.contains(f.name))
        .toList();

    if (filesToRegister.isNotEmpty) {
      _setLoading(true, 'Registrando ${filesToRegister.length} archivo(s)...');
      final newFileHashes = filesToRegister
          .map((f) => _calculateFileHash(f.bytes!))
          .toList();
      await _firebaseService.registerProcessedFiles(
        newFileHashes,
        filesToRegister.map((f) => f.name).toList(),
      );
    }
  }

  /// Calcula el hash SHA-256 de un archivo para una identificación única.
  String _calculateFileHash(Uint8List bytes) =>
      sha256.convert(bytes).toString();

  /// Genera y descarga un reporte en Excel de los registros que fallaron.
  Future<void> downloadFailedRecordsReport() async {
    if (_lastResult == null || _lastResult!.failedRecords.isEmpty) {
      debugPrint('No hay registros con fallos para reportar.');
      return;
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Registros No Cargados'];

      final headers = _lastResult!.failedRecords.first.keys.toList();
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      for (final record in _lastResult!.failedRecords) {
        sheet.appendRow(
          headers
              .map((h) => TextCellValue(record[h]?.toString() ?? ''))
              .toList(),
        );
      }

      excel.save(
        fileName:
            'Reporte_Registros_No_Cargados_${DateTime.now().toIso8601String()}.xlsx',
      );
    } catch (e) {
      debugPrint('Error al generar el reporte de Excel: $e');
    }
  }

  /// Método interno para actualizar el estado de carga y notificar a los listeners.
  void _setLoading(bool value, [String message = '']) {
    _isLoading = value;
    _loadingMessage = message;
    notifyListeners();
  }
}
