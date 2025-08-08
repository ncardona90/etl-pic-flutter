import 'dart:async'; // <-- CORRECCIÓN: IMPORT AÑADIDO
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';
import 'package:etl_tamizajes_app/core/services/firebase_service.dart';

class DataMasterProvider with ChangeNotifier {
  DataMasterProvider({required FirebaseService firebaseService})
    : _firebaseService = firebaseService {
    _listenToRecords();
  }
  final FirebaseService _firebaseService;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // Esta variable ahora será reconocida gracias al import.
  late final StreamSubscription<List<Tamizaje>> _recordsSubscription;

  List<Tamizaje> _allRecords = [];
  List<Tamizaje> get allRecords => _allRecords;

  bool _isLoading = true;
  String? _error;
  String? _operationStatus;

  PlutoGridStateManager? stateManager;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get operationStatus => _operationStatus;

  void _listenToRecords() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _recordsSubscription = _firebaseService.getTamizajesStream().listen(
      (records) {
        _allRecords = records;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Ocurrió un error al cargar los datos: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void setGridStateManager(PlutoGridStateManager manager) {
    stateManager = manager;
  }

  Future<void> fetchInitialData() async {
    // La suscripción a streams ya actualiza los datos en tiempo real.
    // Esta función puede usarse para forzar una recarga si fuera necesario.
    notifyListeners();
  }

  Future<String?> findAndReplace({
    required String fieldName,
    required String replaceValue,
    required List<PlutoRow> selectedRows,
  }) async {
    final docIds = selectedRows
        .map((row) => row.cells['numero_documento']!.value.toString())
        .toList();

    _setLoading(true, 'Actualizando ${docIds.length} registros...');

    try {
      final callable = _functions.httpsCallable('batchUpdateField');
      final result = await callable.call({
        'collection': 'tamizajesfull',
        'docIds': docIds,
        'fieldName': fieldName,
        'replaceValue': replaceValue,
      });
      _operationStatus = result.data['message'];
      // No necesitamos llamar a fetchInitialData, el stream lo hará automáticamente.
      return null;
    } on FirebaseFunctionsException catch (e) {
      _operationStatus = 'Error: ${e.message}';
      return 'Error en la operación: ${e.code} - ${e.message}';
    } catch (e) {
      _operationStatus = 'Error inesperado: ${e.toString()}';
      return 'Error inesperado: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value, [String? message]) {
    _isLoading = value;
    _operationStatus = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _recordsSubscription.cancel();
    super.dispose();
  }
}
