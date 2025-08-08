import 'package:crypto/crypto.dart';
import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';
import 'package:flutter/foundation.dart';

/// Clase que encapsula el resultado del proceso de ETL (Extract, Transform, Load).
class EtlResult {
  EtlResult({
    required this.validRecords,
    required this.failedRecords,
    this.duplicateFileCount = 0,
    this.duplicateFileNames = const [],
  });
  final List<Tamizaje> validRecords;
  final List<Map<String, dynamic>> failedRecords;
  final int duplicateFileCount;
  final List<String> duplicateFileNames;
}

/// Contiene toda la lógica de negocio para la extracción, transformación y carga de datos.
class EtlService {
  /// Procesa y valida una lista de registros JSON crudos.
  ///
  /// Esta función es el corazón del ETL. Aplica las siguientes reglas:
  /// 1. Filtra registros con `numero_documento` nulo o inválido.
  /// 2. Para documentos duplicados dentro del mismo lote, conserva solo el más reciente.
  /// 3. Valida que todos los campos requeridos no sean nulos o vacíos.
  /// 4. Separa los registros en dos listas: válidos para subir y fallidos con su motivo.
  EtlResult processAndValidateData(List<Map<String, dynamic>> records) {
    final List<Map<String, dynamic>> failedRecords = [];
    final Map<int, Map<String, dynamic>> latestRecordByDoc = {};

    // Primero, agrupa por número de documento y quédate con el más reciente.
    for (final record in records) {
      final docNum = _parseInt(record['numero_documento']);
      if (docNum == 0) {
        record['motivo_fallo'] = 'Número de documento faltante o inválido.';
        failedRecords.add(record);
        continue;
      }

      if (!latestRecordByDoc.containsKey(docNum) ||
          _parseDate(record['fecha_registro_bd']).isAfter(
            _parseDate(latestRecordByDoc[docNum]!['fecha_registro_bd']),
          )) {
        // Si el registro actual es más nuevo que uno ya guardado para el mismo doc, se reemplaza.
        if (latestRecordByDoc.containsKey(docNum)) {
          final oldRecord = latestRecordByDoc[docNum]!;
          oldRecord['motivo_fallo'] =
              'Duplicado en el lote (se conservó el más reciente).';
          failedRecords.add(oldRecord);
        }
        latestRecordByDoc[docNum] = record;
      } else {
        // El registro actual es más antiguo que uno ya existente, se descarta.
        record['motivo_fallo'] =
            'Duplicado en el lote (se conservó el más reciente).';
        failedRecords.add(record);
      }
    }

    final List<Tamizaje> validRecords = [];
    final List<String> requiredFields = [
      'fecha_intervencion',
      'entorno_intervencion',
      'nombres',
      'apellidos',
      'numero_documento',
      'fecha_nacimiento',
      'edad',
      'sexo_asignado_nacimiento',
      'comuna',
      'eps',
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
    ];

    // Ahora, valida cada uno de los registros únicos y más recientes.
    for (final record in latestRecordByDoc.values) {
      String? missingField;
      for (final field in requiredFields) {
        if (record[field] == null || record[field].toString().trim().isEmpty) {
          missingField = field;
          break;
        }
      }

      if (missingField != null) {
        record['motivo_fallo'] =
            "Dato faltante o vacío en el campo: '$missingField'.";
        failedRecords.add(record);
      } else {
        try {
          // Intenta convertir el mapa a un objeto Tamizaje.
          // El constructor de Tamizaje puede tener validaciones adicionales.
          validRecords.add(Tamizaje.fromMap(record));
        } catch (e) {
          record['motivo_fallo'] = 'Error de formato interno: ${e.toString()}';
          failedRecords.add(record);
        }
      }
    }

    return EtlResult(validRecords: validRecords, failedRecords: failedRecords);
  }

  /// Calcula el hash SHA-256 de un archivo para identificarlo de forma única.
  String calculateFileHash(Uint8List fileBytes) {
    return sha256.convert(fileBytes).toString();
  }
}

// Funciones auxiliares para parsear datos de forma segura, evitando errores.
DateTime _parseDate(dynamic dateValue) {
  if (dateValue is String) {
    return DateTime.tryParse(dateValue) ?? DateTime(1900);
  }
  return DateTime(1900);
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
