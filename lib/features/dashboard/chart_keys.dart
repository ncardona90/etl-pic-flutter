enum ChartKey {
  cursoVida,
  riesgoDiabetes,
  riesgoDiabetesGenero,
  riesgoDiabetesEdad,
  riesgoDiabetesEstrato,
  riesgoDiabetesEapb,
  riesgoDiabetesComuna,
}

const Map<ChartKey, String> chartTitles = {
  ChartKey.cursoVida: 'Distribución de la población por curso de vida',
  ChartKey.riesgoDiabetes: 'Distribución de la población según riesgo de Diabetes',
  ChartKey.riesgoDiabetesGenero: 'Distribución de la población según riesgo de Diabetes vs género',
  ChartKey.riesgoDiabetesEdad: 'Distribución de la población según riesgo de Diabetes vs grupo de edad',
  ChartKey.riesgoDiabetesEstrato: 'Distribución de la población según riesgo de Diabetes vs estrato socioeconómico',
  ChartKey.riesgoDiabetesEapb: 'Distribución de la población según riesgo de Diabetes vs EAPB',
  ChartKey.riesgoDiabetesComuna: 'Distribución de la población según Diabetes vs comuna',
};

extension ChartKeyTitle on ChartKey {
  String get title => chartTitles[this] ?? name;
}

