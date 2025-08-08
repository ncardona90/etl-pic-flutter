// --- lib/features/dashboard/dashboard_provider.dart ---

// Copyright 2025 ESEORIENTE - FORJU. All rights reserved.
// Use of this source code is governed by a enterprise license that can be
// found in the LICENSE file.

/// @file dashboard_provider.dart
/// @brief Gestiona el estado y la lógica de negocio para el Dashboard.
///
/// Este provider es la única fuente de verdad para los datos del dashboard.
/// Se encarga de:
/// 1. Escuchar los datos crudos desde Firebase.
/// 2. Aplicar filtros de fecha seleccionados por el usuario.
/// 3. Procesar los datos filtrados para generar las estructuras necesarias para cada gráfico.
/// 4. Aplicar lógica de negocio para agrupar categorías no prioritarias en "Otras".
library dashboard_provider;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';
import 'package:etl_tamizajes_app/core/services/firebase_service.dart';
import 'chart_keys.dart';
import 'processors/processor_registry.dart';
part 'processors/riesgo_diabetes_processor.dart';

class DashboardProvider with ChangeNotifier, RiesgoDiabetesProcessor {
  DashboardProvider({required FirebaseService firebaseService})
    : _firebaseService = firebaseService {
    _listenToTamizajes();
  }
  final FirebaseService _firebaseService;
  late final StreamSubscription<List<Tamizaje>> _tamizajesSubscription;

  // --- ESTADO INTERNO ---
  List<Tamizaje> _allTamizajes = [];
  List<Tamizaje> _filteredTamizajes = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;

  // --- GETTERS PÚBLICOS PARA LA UI ---
  List<Tamizaje> get filteredTamizajes => _filteredTamizajes;
  bool get isLoading => _isLoading;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // --- CONSTANTES DE NEGOCIO ---
  static const String na = 'Sin Dato';

  /// [REGLA DE NEGOCIO]
  /// Define las comunas de interés principal. El resto se agrupará.
  static const Set<String> _allowedComunas = {
    '13',
    '14',
    '15',
    '21',
    'CORREGIMIENTO DE NAVARRO',
  };

  /// [REGLA DE NEGOCIO]
  /// Define las EAPB de interés principal (capitación). El resto se agrupará.
  static const Set<String> _allowedEps = {
    'EMSSANAR',
    'ASMET SALUD',
    'SANITAS',
    'NUEVA EPS',
    'COOSALUD',
  };

  /// Suscripción al stream de datos de Firestore.
  void _listenToTamizajes() {
    _isLoading = true;
    notifyListeners();
    _tamizajesSubscription = _firebaseService.getTamizajesStream().listen(
      (data) {
        _allTamizajes = data;
        _applyFilter(); // Aplica el filtro inicial (solo fecha por ahora).
      },
      onDone: () {
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error en el stream de tamizajes: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // --- LÓGICA DE FILTRADO ---

  void setDateFilter(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    _applyFilter();
  }

  void clearFilters() {
    _startDate = null;
    _endDate = null;
    _applyFilter();
  }

  /// Método central que aplica los filtros.
  /// Ahora, solo filtra por fecha. La lógica de negocio de Comuna/EAPB se
  /// maneja en la capa de categorización (getters).
  void _applyFilter() {
    if (_startDate != null && _endDate != null) {
      final endOfDay = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      _filteredTamizajes = _allTamizajes.where((t) {
        final fecha = t.fechaIntervencion;
        if (fecha == null) return false;
        return !fecha.isBefore(_startDate!) && !fecha.isAfter(endOfDay);
      }).toList();
    } else {
      _filteredTamizajes = List.from(_allTamizajes);
    }
    _isLoading = false;
    notifyListeners();
  }

  // --- LÓGICA DE CATEGORIZACIÓN (GETTERS) ---
  // Aquí se implementa la nueva lógica de negocio.

  /// Devuelve la EAPB del tamizaje. Si no está en la lista de interés,
  /// la agrupa en la categoría "Otras EAPB".
  String getEps(Tamizaje t) {
    if (t.eps.isEmpty) return na;
    return _allowedEps.contains(t.eps) ? t.eps : 'Otras EAPB';
  }

  /// Devuelve la Comuna del tamizaje. Si no está en la lista de interés,
  /// la agrupa en la categoría "Otras Comunas".
  String getComuna(Tamizaje t) {
    if (t.comuna.isEmpty) return na;
    return _allowedComunas.contains(t.comuna) ? t.comuna : 'Otras Comunas';
  }

  String getGenero(Tamizaje t) {
    final genero = t.sexoAsignadoNacimiento.toUpperCase();
    if (genero == 'INTERSEXUAL') return 'MUJER';
    return genero;
  }

  String getAgeGroup(Tamizaje t) {
    final age = t.edad;
    if (age <= 17) return 'Adolescencia (12-18 años)';
    if (age <= 28) return 'Juventud (18-28 años)';
    if (age <= 59) return 'Adultez (27-59 años)';
    return 'Persona Mayor (60+ años)';
  }

  String getEstrato(Tamizaje t) =>
      (t.estratoSocioeconomico?.isNotEmpty ?? false)
      ? t.estratoSocioeconomico!
      : na;
  String getEntorno(Tamizaje t) =>
      (t.entornoIntervencion.isNotEmpty) ? t.entornoIntervencion : na;
  String getImcCategory(Tamizaje t) =>
      (t.clasificacionImc.isNotEmpty) ? t.clasificacionImc : na;
  String getAbdominalPerimeterCategory(Tamizaje t) {
    final gender = getGenero(t);
    final value = t.circunferenciaAbdominal ?? 0;
    if (gender == 'HOMBRE') return value >= 90 ? 'Riesgo Alto' : 'Normal';
    if (gender == 'MUJER') return value >= 80 ? 'Riesgo Alto' : 'Normal';
    return na;
  }

  String getRiesgoDiabetes(Tamizaje t) =>
      (t.riesgoFindrisc?.isNotEmpty ?? false) ? t.riesgoFindrisc! : na;
  String getRiesgoCardiovascular(Tamizaje t) =>
      (t.clasificacionRiesgoCardiovascularOms?.isNotEmpty ?? false)
      ? t.clasificacionRiesgoCardiovascularOms!
      : na;
  String getBloodPressureCategory(Tamizaje t) {
    final sistolica = t.presionSistolica;
    final diastolica = t.presionDiastolica;
    if (sistolica == 0 || diastolica == 0) return na;
    if (t.edad >= 60) {
      if (sistolica >= 150 || diastolica >= 90) return 'Hipertensión';
    } else {
      if (sistolica >= 140 || diastolica >= 90) return 'Hipertensión';
    }
    if (sistolica >= 130 || diastolica >= 85) return 'Normal-Alta';
    if (sistolica >= 120 || diastolica >= 80) return 'Normal';
    return 'Óptima';
  }

  String getMedicacionHta(Tamizaje t) =>
      (t.medicacionHipertension.isNotEmpty) ? t.medicacionHipertension : na;
  String getActividadFisica(Tamizaje t) =>
      (t.actividadFisica.isNotEmpty) ? t.actividadFisica : na;
  String getConsumoFrutasVerduras(Tamizaje t) =>
      (t.frecuenciaFrutasVerduras.isNotEmpty) ? t.frecuenciaFrutasVerduras : na;
  String getHabitoFumar(Tamizaje t) => (t.fuma.isNotEmpty) ? t.fuma : na;
  String getGlucosaAlta(Tamizaje t) =>
      (t.glucosaAltaHistorico.isNotEmpty) ? t.glucosaAltaHistorico : na;
  String getHerenciaDiabetes(Tamizaje t) =>
      (t.antecedentesFamiliaresDiabetes.isNotEmpty)
      ? t.antecedentesFamiliaresDiabetes
      : na;
  String getSufreDiabetes(Tamizaje t) =>
      (t.esDiabetico.isNotEmpty) ? t.esDiabetico : na;

  // --- LÓGICA DE PROCESAMIENTO DE DATOS (GENÉRICA) ---
  Map<String, double> processSingleVariable(
    List<Tamizaje> data,
    String Function(Tamizaje) getField,
  ) {
    if (data.isEmpty) return {};
    return data
        .groupListsBy((t) => getField(t))
        .map((key, value) => MapEntry(key, value.length.toDouble()));
  }

  Map<String, Map<String, double>> processBivariateVariable(
    List<Tamizaje> tamizajes,
    String Function(Tamizaje) getPrimaryCategory,
    String Function(Tamizaje) getSecondaryCategory,
  ) {
    final Map<String, Map<String, double>> result = {};
    for (var tamizaje in tamizajes) {
      final primaryCat = getPrimaryCategory(tamizaje);
      final secondaryCat = getSecondaryCategory(tamizaje);
      result.putIfAbsent(primaryCat, () => {});
      result[primaryCat]!.update(
        secondaryCat,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return result;
  }

  Map<String, Map<String, Map<String, double>>> processTrivariateVariable(
    List<Tamizaje> tamizajes,
    String Function(Tamizaje) getSegment,
    String Function(Tamizaje) getPrimaryCategory,
    String Function(Tamizaje) getSecondaryCategory,
  ) {
    final Map<String, Map<String, Map<String, double>>> result = {};
    for (var tamizaje in tamizajes) {
      final segment = getSegment(tamizaje);
      final primaryCat = getPrimaryCategory(tamizaje);
      final secondaryCat = getSecondaryCategory(tamizaje);
      result.putIfAbsent(segment, () => {});
      result[segment]!.putIfAbsent(primaryCat, () => {});
      result[segment]![primaryCat]!.update(
        secondaryCat,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return result;
  }


  /// Devuelve los datos procesados para el gráfico solicitado.
  dynamic getChartData(ChartKey key) {
    final processor = chartProcessors[key];
    if (processor != null) {
      return processor(this);
    }

    // Fallback para gráficos no migrados al nuevo esquema.
    switch (key) {
      case ChartKey.cursoVida:
        return processSingleVariable(_filteredTamizajes, getAgeGroup);
      default:
        return {};
    }
  }

  @override
  void dispose() {
    _tamizajesSubscription.cancel();
    super.dispose();
  }
}
