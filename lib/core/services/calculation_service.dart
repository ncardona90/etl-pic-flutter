/// Clase que encapsula toda la lógica de negocio para los cálculos de salud.
/// Centraliza las fórmulas para mantener el código del formulario limpio y reutilizable.
class CalculationService {
  /// Calcula la edad de una persona a partir de su fecha de nacimiento.
  int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  /// Calcula el Índice de Masa Corporal (IMC).
  double calculateIMC(double weight, double heightInMeters) {
    if (heightInMeters <= 0) return 0.0;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Clasifica el IMC según los estándares de la OMS.
  String classifyIMC(double imc) {
    if (imc <= 0) return 'N/A';
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25.0) return 'Normal';
    if (imc < 30.0) return 'Sobrepeso';
    if (imc < 35.0) return 'Obesidad Grado I';
    if (imc < 40.0) return 'Obesidad Grado II';
    return 'Obesidad Grado III (Mórbida)';
  }

  /// Calcula y clasifica el riesgo según la escala FINDRISC.
  Map<String, dynamic> calculateAndClassifyFINDRISC({
    required int? age,
    required double? imc,
    required double? waistCircumference,
    required String? gender,
    required String? physicalActivity,
    required String? eatsFruitsAndVegs,
    required String? htaMedication,
    required String? highGlucoseHistory,
    required String? familyDiabetesHistory,
  }) {
    if ([
      age,
      imc,
      waistCircumference,
      gender,
      physicalActivity,
      eatsFruitsAndVegs,
      htaMedication,
      highGlucoseHistory,
      familyDiabetesHistory,
    ].contains(null)) {
      return {'puntaje': 0, 'clasificacion': 'Datos insuficientes'};
    }

    int score = 0;
    if (age! >= 45 && age <= 54) {
      score += 2;
    } else if (age >= 55 && age <= 64)
      score += 3;
    else if (age > 64)
      score += 4;

    if (imc! >= 25 && imc < 30) {
      score += 1;
    } else if (imc >= 30)
      score += 3;

    final isMale =
        gender?.toLowerCase() == 'hombre' ||
        gender?.toLowerCase() == 'masculino';
    if (isMale) {
      if (waistCircumference! >= 94 && waistCircumference <= 102) {
        score += 3;
      } else if (waistCircumference > 102)
        score += 4;
    } else {
      if (waistCircumference! >= 80 && waistCircumference <= 88) {
        score += 3;
      } else if (waistCircumference > 88)
        score += 4;
    }

    if (physicalActivity == 'No') score += 2;
    if (eatsFruitsAndVegs == 'NO todos los días') score += 1;
    if (htaMedication == 'Sí') score += 2;
    if (highGlucoseHistory == 'Sí') score += 5;

    if (familyDiabetesHistory == 'Sí: padres, hermanos o hijos') {
      score += 5;
    } else if (familyDiabetesHistory == 'Sí: abuelos, tía, tío, primo hermano')
      score += 3;

    String classification;
    if (score < 7) {
      classification = 'Riesgo Bajo';
    } else if (score <= 11)
      classification = 'Ligeramente Elevado';
    else if (score <= 14)
      classification = 'Riesgo Moderado';
    else if (score <= 20)
      classification = 'Riesgo Alto';
    else
      classification = 'Riesgo Muy Alto';

    return {'puntaje': score, 'clasificacion': classification};
  }

  /// Calcula y clasifica el riesgo cardiovascular según las tablas de la OMS.
  Map<String, String> calculateAndClassifyWHORisk({
    required int? age,
    required String? gender,
    required int? systolicPressure,
    required String? smokes,
    required String? isDiabetic,
    required String? hasPreviousCVD,
  }) {
    if ([
      age,
      gender,
      systolicPressure,
      smokes,
      isDiabetic,
      hasPreviousCVD,
    ].contains(null)) {
      return {
        'riesgoPorcentaje': 'N/A',
        'clasificacionRiesgo': 'Datos insuficientes',
      };
    }

    if (hasPreviousCVD == 'Sí') {
      return {'riesgoPorcentaje': '≥40%', 'clasificacionRiesgo': 'Muy Alto'};
    }

    final bool isMale = ['Hombre', 'Masculino'].contains(gender);
    final bool isSmoker = smokes == 'Sí';
    final bool hasDiabetes = isDiabetic == 'Sí';

    List<List<int>> table;
    if (isMale) {
      if (hasDiabetes) {
        table = isSmoker
            ? _tablaHombreDiabeticoFumador
            : _tablaHombreDiabeticoNoFumador;
      } else {
        table = isSmoker
            ? _tablaHombreNoDiabeticoFumador
            : _tablaHombreNoDiabeticoNoFumador;
      }
    } else {
      if (hasDiabetes) {
        table = isSmoker
            ? _tablaMujerDiabeticaFumadora
            : _tablaMujerDiabeticaNoFumadora;
      } else {
        table = isSmoker
            ? _tablaMujerNoDiabeticaFumadora
            : _tablaMujerNoDiabeticaNoFumadora;
      }
    }

    final int ageIndex = (age! >= 70)
        ? 3
        : (age >= 60)
        ? 2
        : (age >= 50)
        ? 1
        : 0;
    final int pressureIndex = (systolicPressure! >= 180)
        ? 3
        : (systolicPressure >= 160)
        ? 2
        : (systolicPressure >= 140)
        ? 1
        : 0;
    final int riskCode = table[ageIndex][pressureIndex];

    switch (riskCode) {
      case 1:
        return {'riesgoPorcentaje': '<10%', 'clasificacionRiesgo': 'Bajo'};
      case 2:
        return {
          'riesgoPorcentaje': '10% a <20%',
          'clasificacionRiesgo': 'Moderado',
        };
      case 3:
        return {
          'riesgoPorcentaje': '20% a <30%',
          'clasificacionRiesgo': 'Alto',
        };
      case 4:
        return {
          'riesgoPorcentaje': '30% a <40%',
          'clasificacionRiesgo': 'Alto',
        };
      case 5:
        return {'riesgoPorcentaje': '≥40%', 'clasificacionRiesgo': 'Muy Alto'};
      default:
        return {'riesgoPorcentaje': 'Error', 'clasificacionRiesgo': 'Error'};
    }
  }

  // --- Tablas de riesgo cardiovascular de la OMS ---
  static const _tablaHombreNoDiabeticoNoFumador = [
    [1, 1, 2, 3],
    [1, 2, 3, 4],
    [2, 3, 4, 4],
    [3, 4, 4, 5],
  ];
  static const _tablaHombreNoDiabeticoFumador = [
    [1, 2, 3, 4],
    [2, 3, 4, 4],
    [3, 4, 4, 5],
    [4, 4, 5, 5],
  ];
  static const _tablaHombreDiabeticoNoFumador = [
    [2, 3, 4, 4],
    [3, 4, 4, 5],
    [4, 4, 5, 5],
    [4, 5, 5, 5],
  ];
  static const _tablaHombreDiabeticoFumador = [
    [3, 4, 4, 5],
    [4, 4, 5, 5],
    [4, 5, 5, 5],
    [5, 5, 5, 5],
  ];
  static const _tablaMujerNoDiabeticaNoFumadora = [
    [1, 1, 1, 1],
    [1, 1, 2, 2],
    [1, 2, 3, 3],
    [2, 3, 4, 4],
  ];
  static const _tablaMujerNoDiabeticaFumadora = [
    [1, 1, 2, 2],
    [1, 2, 3, 4],
    [2, 3, 4, 4],
    [3, 4, 4, 5],
  ];
  static const _tablaMujerDiabeticaNoFumadora = [
    [1, 2, 3, 4],
    [2, 3, 4, 4],
    [3, 4, 4, 5],
    [4, 4, 5, 5],
  ];
  static const _tablaMujerDiabeticaFumadora = [
    [2, 3, 4, 4],
    [3, 4, 4, 5],
    [4, 4, 5, 5],
    [4, 5, 5, 5],
  ];
}
