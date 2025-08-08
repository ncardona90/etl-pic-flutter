/// Clase de utilidad para generar textos de análisis automáticos basados en los datos del gráfico.
class AnalysisHelper {
  /// Genera un análisis para datos de una sola variable (usado en gráficos de torta y barras simples).
  ///
  /// Identifica la categoría con el valor más alto y calcula su contribución porcentual.
  static String generateUnivariateAnalysis(
    String title,
    Map<String, double> data,
  ) {
    if (data.isEmpty) return 'No hay datos disponibles para el análisis.';

    // Ordena las categorías de mayor a menor para encontrar la más frecuente.
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calcula el total de registros.
    final total = data.values.reduce((a, b) => a + b);

    final mainCategory = sortedEntries.first.key;
    final mainValue = sortedEntries.first.value;
    // Calcula el porcentaje de la categoría principal.
    final mainPercentage = total > 0
        ? (mainValue / total * 100).toStringAsFixed(1)
        : '0';

    // Construye el texto descriptivo.
    String analysisText =
        "Para la variable '$title', la categoría predominante es '$mainCategory', "
        'representando el $mainPercentage% del total con ${mainValue.toInt()} casos. ';

    if (sortedEntries.length > 1) {
      final secondCategory = sortedEntries[1].key;
      analysisText += "Le sigue en frecuencia la categoría '$secondCategory'.";
    }

    return analysisText;
  }

  /// Genera un análisis para datos de dos variables (usado en gráficos de barras agrupadas y apiladas).
  ///
  /// Para cada grupo principal, identifica la sub-categoría más común.
  static String generateBivariateAnalysis(
    String title,
    Map<String, Map<String, double>> data,
  ) {
    if (data.isEmpty) return 'No hay datos disponibles para el análisis.';

    String insights = "Análisis para '$title':\n\n";

    // Itera sobre cada grupo principal (ej. 'Masculino', 'Femenino').
    for (var entry in data.entries) {
      final primaryCategory = entry.key;
      final secondaryData = entry.value;

      if (secondaryData.isEmpty) continue;

      // Encuentra la sub-categoría más común para ese grupo.
      final sortedSecondary = secondaryData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final mostCommonSubCategory = sortedSecondary.first.key;
      insights +=
          "  • En el grupo '$primaryCategory', la característica más observada es '$mostCommonSubCategory'.\n";
    }
    return insights;
  }
}
