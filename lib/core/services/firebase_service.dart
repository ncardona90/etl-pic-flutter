// --- lib/core/services/firebase_service.dart ---

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';
import 'package:etl_tamizajes_app/core/models/app_user.dart';
import 'package:flutter/foundation.dart';

/// Servicio para interactuar con la base de datos Firestore.
/// Centraliza toda la lógica de acceso a datos para tamizajes, usuarios y archivos.
class FirebaseService {
  FirebaseService() {
    // Inicializa las referencias a las colecciones principales para evitar strings mágicos.
    _tamizajesCollection = _db.collection('tamizajesfull');
    _usersCollection = _db.collection('users');
    _processedFilesCollection = _db.collection('processed_files');
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Referencias a Colecciones ---
  late final CollectionReference<Map<String, dynamic>> _tamizajesCollection;
  late final CollectionReference<Map<String, dynamic>> _usersCollection;
  late final CollectionReference<Map<String, dynamic>>
  _processedFilesCollection;

  // --- Gestión de Tamizajes ---

  /// Obtiene un stream de todos los documentos de la colección 'tamizajesfull'.
  Stream<List<Tamizaje>> getTamizajesStream() {
    return _tamizajesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              // Asume que el modelo Tamizaje tiene un constructor fromMap
              return Tamizaje.fromMap(doc.data());
            } catch (e) {
              debugPrint('Error al parsear el tamizaje ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Tamizaje>()
          .toList(); // Filtra cualquier nulo que haya fallado
    });
  }

  /// Sube una lista de tamizajes a Firestore dividiéndola en lotes de 500.
  ///
  /// Esta función es robusta contra el error "Transaction too big" de Firestore,
  /// ya que procesa la carga en "chunks" o lotes más pequeños.
  Future<void> uploadTamizajesBatch(List<Tamizaje> tamizajes) async {
    if (tamizajes.isEmpty) return;

    const int batchSize =
        500; // Límite máximo de operaciones por lote en Firestore.

    for (int i = 0; i < tamizajes.length; i += batchSize) {
      final int end = (i + batchSize < tamizajes.length)
          ? i + batchSize
          : tamizajes.length;
      final batchList = tamizajes.sublist(i, end);

      final WriteBatch batch = _db.batch();

      for (final tamizaje in batchList) {
        final docRef = _tamizajesCollection.doc(tamizaje.numeroDocumento);
        batch.set(docRef, tamizaje.toMap());
      }

      debugPrint(
        'Subiendo lote de ${batchList.length} registros (desde el índice $i)...',
      );
      await batch.commit();
    }

    debugPrint('Carga completa de ${tamizajes.length} registros finalizada.');
  }

  /// Guarda (crea o actualiza) un único registro de tamizaje.
  Future<void> saveRecord(Tamizaje record) async {
    final docRef = _tamizajesCollection.doc(record.numeroDocumento);
    await docRef.set(record.toMap(), SetOptions(merge: true));
  }

  /// Elimina un registro de tamizaje por su ID (número de documento).
  Future<void> deleteRecord(String recordId) async {
    await _tamizajesCollection.doc(recordId).delete();
  }

  /// Verifica si un documento ya existe, excluyendo opcionalmente el ID actual.
  Future<bool> checkDocumentExists(
    String docNumber, {
    String? currentRecordId,
  }) async {
    if (currentRecordId != null && currentRecordId == docNumber) {
      return false;
    }
    final doc = await _tamizajesCollection.doc(docNumber).get();
    return doc.exists;
  }

  // --- Gestión de Archivos Procesados ---

  /// Verifica si un archivo ya ha sido procesado basado en su hash.
  Future<bool> isFileProcessed(String fileHash) async {
    try {
      final doc = await _processedFilesCollection.doc(fileHash).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error verificando archivo procesado: $e');
      return false;
    }
  }

  /// Registra una lista de hashes de archivos como procesados.
  Future<void> registerProcessedFiles(
    List<String> fileHashes,
    List<String> fileNames,
  ) async {
    if (fileHashes.length != fileNames.length) {
      debugPrint(
        'registerProcessedFiles: fileHashes length (${fileHashes.length}) '
        'does not match fileNames length (${fileNames.length}).',
      );
      throw ArgumentError(
        'fileHashes and fileNames must have the same length',
      );
    }

    final batch = _db.batch();
    for (int i = 0; i < fileHashes.length; i++) {
      final docRef = _processedFilesCollection.doc(fileHashes[i]);
      batch.set(docRef, {
        'fileName':
            fileNames[i], // Corregido de 'filename' a 'fileName' para consistencia
        'processedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // --- CRUD PARA GESTIÓN DE USUARIOS ---

  /// Obtiene un Stream de todos los usuarios autorizados.
  Stream<List<AppUser>> getUsersStream() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Guarda (crea o actualiza) un usuario en la colección 'users'.
  Future<void> saveUser(AppUser user) async {
    final docRef = _usersCollection.doc(user.uid);
    await docRef.set(user.toMap(), SetOptions(merge: true));
  }

  /// Elimina un usuario de la colección 'users' usando su UID.
  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }
}
