// --- lib/features/data_management/data_management_provider.dart ---

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';
import 'package:etl_tamizajes_app/core/services/firebase_service.dart';

enum ViewMode { list, grid }

class DataManagementProvider with ChangeNotifier {
  DataManagementProvider({required FirebaseService firebaseService})
    : _firebaseService = firebaseService {
    _listenToRecords();
  }

  final FirebaseService _firebaseService;
  StreamSubscription<List<Tamizaje>>? _tamizajesSubscription;

  List<Tamizaje> _allRecords = [];
  List<Tamizaje> _filteredRecords = [];
  List<Tamizaje> get records => _filteredRecords;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ViewMode _viewMode = ViewMode.list;
  ViewMode get viewMode => _viewMode;

  String? _error;
  String? get error => _error;

  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void _listenToRecords() {
    _tamizajesSubscription = _firebaseService.getTamizajesStream().listen(
      (recordsFromDb) {
        _allRecords = recordsFromDb;
        _filteredRecords = recordsFromDb;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Error al cargar los datos: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Filtra los registros basados en un texto de búsqueda universal.
  void filterRecords(String query) {
    if (query.isEmpty) {
      _filteredRecords = _allRecords;
    } else {
      final lowerCaseQuery = query.toLowerCase();
      _filteredRecords = _allRecords.where((record) {
        // --- AJUSTE AQUÍ: Se añade la búsqueda por el campo 'uploadedBy' ---
        return record.nombres.toLowerCase().contains(lowerCaseQuery) ||
            record.apellidos.toLowerCase().contains(lowerCaseQuery) ||
            record.numeroDocumento.toString().contains(lowerCaseQuery) ||
            record.eps.toLowerCase().contains(lowerCaseQuery) ||
            record.uploadedBy.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }
    notifyListeners();
  }

  Future<String?> saveRecord(Tamizaje record) async {
    if (record.id.isEmpty) {
      return 'El ID del registro no puede estar vacío.';
    }
    try {
      await _firebaseService.saveRecord(record);
      return null;
    } catch (e) {
      return 'Error guardando registro: $e';
    }
  }

  Future<bool> deleteRecord(String recordId) async {
    try {
      await _firebaseService.deleteRecord(recordId);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _tamizajesSubscription?.cancel();
    super.dispose();
  }
}
