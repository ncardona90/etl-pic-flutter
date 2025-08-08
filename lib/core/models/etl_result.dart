import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';

// Modelo para encapsular los resultados del proceso ETL.
// Centralizar este modelo soluciona conflictos de importación.
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

  // Helper para facilitar la actualización del estado de forma inmutable.
  EtlResult copyWith({
    List<Tamizaje>? validRecords,
    List<Map<String, dynamic>>? failedRecords,
    int? duplicateFileCount,
    List<String>? duplicateFileNames,
  }) {
    return EtlResult(
      validRecords: validRecords ?? this.validRecords,
      failedRecords: failedRecords ?? this.failedRecords,
      duplicateFileCount: duplicateFileCount ?? this.duplicateFileCount,
      duplicateFileNames: duplicateFileNames ?? this.duplicateFileNames,
    );
  }
}
