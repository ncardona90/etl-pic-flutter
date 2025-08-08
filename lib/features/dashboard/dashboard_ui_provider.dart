// lib/features/dashboard/dashboard_ui_provider.dart
import 'package:flutter/material.dart';

class DashboardUIProvider extends ChangeNotifier {
  String _selectedChartTitle =
      'Distribución de la población por curso de vida'; // Gráfico por defecto

  String get selectedChartTitle => _selectedChartTitle;

  void selectChart(String title) {
    _selectedChartTitle = title;
    notifyListeners();
  }
}
