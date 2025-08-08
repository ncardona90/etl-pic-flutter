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
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:etl_tamizajes_app/core/models/tamizaje_model.dart';
import 'package:etl_tamizajes_app/core/services/firebase_service.dart';

class DashboardProvider with ChangeNotifier {
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

  /// Este es el método central que la UI llamará.
  /// Contiene la lógica para generar los datos de CADA gráfico solicitado.
  dynamic getChartData(String chartTitle) {
    switch (chartTitle) {
      // --- 4.1 Sociodemográficos ---
      case 'Distribución de la población por EAPB':
        return processSingleVariable(_filteredTamizajes, getEps);
      case 'Distribución de la población por género':
        return processSingleVariable(_filteredTamizajes, getGenero);
      case 'Distribución de la población por curso de vida':
        return processSingleVariable(_filteredTamizajes, getAgeGroup);
      case 'Distribución de la población por comuna':
        return processSingleVariable(_filteredTamizajes, getComuna);
      case 'Distribución de la población por estrato socioeconómico':
        return processSingleVariable(_filteredTamizajes, getEstrato);
      case 'Distribución de la población por entorno':
        return processSingleVariable(_filteredTamizajes, getEntorno);

      // --- 4.2 Riesgos: IMC ---
      case 'Distribución de la población según IMC':
        return processSingleVariable(_filteredTamizajes, getImcCategory);
      case 'Distribución de la población según IMC vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getImcCategory,
        );
      case 'Distribución de la población según IMC vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getImcCategory,
        );
      case 'Distribución de la población según IMC vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getImcCategory,
        );
      case 'Distribución de la población según IMC vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getImcCategory,
        );
      case 'Distribución de la población según IMC vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getImcCategory,
        );

      // --- 4.2 Riesgos: Perímetro Abdominal ---
      case 'Distribución de la población según Perímetro Abdominal':
        return processSingleVariable(
          _filteredTamizajes,
          getAbdominalPerimeterCategory,
        );
      case 'Distribución de la población según Perímetro Abdominal vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getAbdominalPerimeterCategory,
        );
      case 'Distribución de la población según Perímetro Abdominal vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getAbdominalPerimeterCategory,
        );
      case 'Distribución de la población según Perímetro Abdominal vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getAbdominalPerimeterCategory,
        );
      case 'Distribución de la población según Perímetro Abdominal vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getAbdominalPerimeterCategory,
        );
      case 'Distribución de la población según Perímetro Abdominal vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getAbdominalPerimeterCategory,
        );

      // --- 4.2 Riesgos: Diabetes ---
      case 'Distribución de la población según riesgo de Diabetes':
        return processSingleVariable(_filteredTamizajes, getRiesgoDiabetes);
      case 'Distribución de la población según riesgo de Diabetes vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getRiesgoDiabetes,
        );
      case 'Distribución de la población según riesgo de Diabetes vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getRiesgoDiabetes,
        );
      case 'Distribución de la población según riesgo de Diabetes vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getRiesgoDiabetes,
        );
      case 'Distribución de la población según riesgo de Diabetes vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getRiesgoDiabetes,
        );
      case 'Distribución de la población según Diabetes vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getRiesgoDiabetes,
        );

      // --- 4.2 Riesgos: Cardiovascular ---
      case 'Distribución de la población según Riesgo Cardiovascular':
        return processSingleVariable(
          _filteredTamizajes,
          getRiesgoCardiovascular,
        );
      case 'Distribución de la población según Riesgo Cardiovascular vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getRiesgoCardiovascular,
        );
      case 'Distribución de la población según Riesgo Cardiovascular vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getRiesgoCardiovascular,
        );
      case 'Distribución de la población según Riesgo Cardiovascular vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getRiesgoCardiovascular,
        );
      case 'Distribución de la población según Riesgo Cardiovascular vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getRiesgoCardiovascular,
        );
      case 'Distribución de la población según Riesgo Cardiovascular vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getRiesgoCardiovascular,
        );

      // --- 4.2 Riesgos: Presión Arterial ---
      case 'Distribución de la población según Presión arterial':
        return processSingleVariable(
          _filteredTamizajes,
          getBloodPressureCategory,
        );
      case 'Distribución de la población según Presión arterial vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getBloodPressureCategory,
        );
      case 'Distribución de la población según Presión arterial vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getBloodPressureCategory,
        );
      case 'Distribución de la población según Presión arterial vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getBloodPressureCategory,
        );
      case 'Distribución de la población según Presión arterial vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getBloodPressureCategory,
        );
      case 'Distribución de la población según Presión arterial vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getBloodPressureCategory,
        );
      case 'Distribución de la población según Presión arterial vs toma de medicamentos para la presión':
        return processBivariateVariable(
          _filteredTamizajes,
          getMedicacionHta,
          getBloodPressureCategory,
        );
      case 'Distribución de la población según Presión arterial vs toma de medicamentos para la presión vs EAPB':
        return processTrivariateVariable(
          _filteredTamizajes,
          getMedicacionHta,
          getEps,
          getBloodPressureCategory,
        );
      case 'Distribución de la población según Presión arterial vs toma de medicamentos para la presión vs género':
        return processTrivariateVariable(
          _filteredTamizajes,
          getMedicacionHta,
          getGenero,
          getBloodPressureCategory,
        );

      // --- 4.3 Comportamentales: Actividad Física ---
      case 'Distribución de la población según actividad física':
        return processSingleVariable(_filteredTamizajes, getActividadFisica);
      case 'Distribución de la población según Actividad Física vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getActividadFisica,
        );
      case 'Distribución de la población según Actividad Física vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getActividadFisica,
        );
      case 'Distribución de la población según Actividad Física vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getActividadFisica,
        );
      case 'Distribución de la población según Actividad Física vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getActividadFisica,
        );
      case 'Distribución de la población según Actividad Física vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getActividadFisica,
        );

      // --- 4.3 Comportamentales: Frutas y Verduras ---
      case 'Distribución de la población según consumo de Frutas y Verduras':
        return processSingleVariable(
          _filteredTamizajes,
          getConsumoFrutasVerduras,
        );
      case 'Distribución de la población según Consumo de frutas y verduras vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getConsumoFrutasVerduras,
        );
      case 'Distribución de la población según Consumo de frutas y verduras vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getConsumoFrutasVerduras,
        );
      case 'Distribución de la población según Consumo de frutas y verduras vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getConsumoFrutasVerduras,
        );
      case 'Distribución de la población según Consumo de frutas y verduras vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getConsumoFrutasVerduras,
        );
      case 'Distribución de la población según Consumo de frutas y verduras vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getConsumoFrutasVerduras,
        );

      // --- 4.3 Comportamentales: Hábito de Fumar ---
      case 'Distribución de la población según hábito de fumar':
        return processSingleVariable(_filteredTamizajes, getHabitoFumar);
      case 'Distribución de la población según Hábito de fumar vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getHabitoFumar,
        );
      case 'Distribución de la población según Hábito de fumar vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getHabitoFumar,
        );
      case 'Distribución de la población según Hábito de fumar vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getHabitoFumar,
        );
      case 'Distribución de la población según Hábito de fumar vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getHabitoFumar,
        );
      case 'Distribución de la población según Hábito de fumar vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getHabitoFumar,
        );

      // --- 4.4 No Modificables: Glucosa ---
      case 'Distribución de la población según antecedentes de valores de glucosa alta':
        return processSingleVariable(_filteredTamizajes, getGlucosaAlta);
      case 'Distribución de la población según Antecedentes de valores de glucosa alta vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getGlucosaAlta,
        );
      case 'Distribución de la población según Antecedentes de valores de glucosa alta vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getGlucosaAlta,
        );
      case 'Distribución de la población según Antecedentes de valores de glucosa alta vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getGlucosaAlta,
        );
      case 'Distribución de la población según Antecedentes de valores de glucosa alta vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getGlucosaAlta,
        );
      case 'Distribución de la población según Antecedentes de valores de glucosa alta vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getGlucosaAlta,
        );

      // --- 4.4 No Modificables: Herencia Diabetes ---
      case 'Distribución de la población según herencia de diabetes':
        return processSingleVariable(_filteredTamizajes, getHerenciaDiabetes);
      case 'Distribución de la población según Herencia de diabetes vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getHerenciaDiabetes,
        );
      case 'Distribución de la población según Herencia de diabetes vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getHerenciaDiabetes,
        );
      case 'Distribución de la población según Herencia de diabetes vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getHerenciaDiabetes,
        );
      case 'Distribución de la población según Herencia de diabetes vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getHerenciaDiabetes,
        );
      case 'Distribución de la población según Herencia de diabetes vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getHerenciaDiabetes,
        );

      // --- 4.4 No Modificables: Sufre Diabetes ---
      case 'Distribución de la población según sufre de diabetes':
        return processSingleVariable(_filteredTamizajes, getSufreDiabetes);
      case 'Distribución de la población según Sufre de diabetes vs género':
        return processBivariateVariable(
          _filteredTamizajes,
          getGenero,
          getSufreDiabetes,
        );
      case 'Distribución de la población según Sufre de diabetes vs grupo de edad':
        return processBivariateVariable(
          _filteredTamizajes,
          getAgeGroup,
          getSufreDiabetes,
        );
      case 'Distribución de la población según Sufre de diabetes vs estrato socioeconómico':
        return processBivariateVariable(
          _filteredTamizajes,
          getEstrato,
          getSufreDiabetes,
        );
      case 'Distribución de la población según Sufre de diabetes vs EAPB':
        return processBivariateVariable(
          _filteredTamizajes,
          getEps,
          getSufreDiabetes,
        );
      case 'Distribución de la población según Sufre de diabetes vs comuna':
        return processBivariateVariable(
          _filteredTamizajes,
          getComuna,
          getSufreDiabetes,
        );

      default:
        return {}; // Devuelve un mapa vacío si el gráfico no está en la lista.
    }
  }

  @override
  void dispose() {
    _tamizajesSubscription.cancel();
    super.dispose();
  }
}
