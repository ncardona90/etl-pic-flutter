import '../chart_keys.dart';

/// Function signature for chart processors.
typedef ChartProcessor = dynamic Function(dynamic provider);

/// Registry that maps chart keys to their processing strategy.
final Map<ChartKey, ChartProcessor> chartProcessors = {
  ChartKey.riesgoDiabetes: (p) => p.riesgoDiabetes(),
  ChartKey.riesgoDiabetesGenero: (p) => p.riesgoDiabetesGenero(),
  ChartKey.riesgoDiabetesEdad: (p) => p.riesgoDiabetesEdad(),
  ChartKey.riesgoDiabetesEstrato: (p) => p.riesgoDiabetesEstrato(),
  ChartKey.riesgoDiabetesEapb: (p) => p.riesgoDiabetesEapb(),
  ChartKey.riesgoDiabetesComuna: (p) => p.riesgoDiabetesComuna(),
};

