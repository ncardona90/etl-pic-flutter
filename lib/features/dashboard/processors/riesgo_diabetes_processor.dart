part of dashboard_provider;

mixin RiesgoDiabetesProcessor on DashboardProvider {
  Map<String, double> riesgoDiabetes() =>
      processSingleVariable(filteredTamizajes, getRiesgoDiabetes);

  Map<String, Map<String, double>> riesgoDiabetesGenero() =>
      processBivariateVariable(
        filteredTamizajes,
        getGenero,
        getRiesgoDiabetes,
      );

  Map<String, Map<String, double>> riesgoDiabetesEdad() =>
      processBivariateVariable(
        filteredTamizajes,
        getAgeGroup,
        getRiesgoDiabetes,
      );

  Map<String, Map<String, double>> riesgoDiabetesEstrato() =>
      processBivariateVariable(
        filteredTamizajes,
        getEstrato,
        getRiesgoDiabetes,
      );

  Map<String, Map<String, double>> riesgoDiabetesEapb() =>
      processBivariateVariable(
        filteredTamizajes,
        getEps,
        getRiesgoDiabetes,
      );

  Map<String, Map<String, double>> riesgoDiabetesComuna() =>
      processBivariateVariable(
        filteredTamizajes,
        getComuna,
        getRiesgoDiabetes,
      );
}

