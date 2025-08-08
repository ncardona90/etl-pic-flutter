// lib/features/dashboard/dashboard_ui_provider.dart
import 'package:flutter/material.dart';
import 'chart_keys.dart';

class DashboardUIProvider extends ChangeNotifier {
  ChartKey _selectedChart = ChartKey.cursoVida;

  ChartKey get selectedChart => _selectedChart;

  void selectChart(ChartKey key) {
    _selectedChart = key;
    notifyListeners();
  }
}
