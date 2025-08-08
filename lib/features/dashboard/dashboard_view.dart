// // --- lib/features/dashboard/dashboard_view.dart ---

// // Copyright 2025 ESEORIENTE - FORJU. All rights reserved.
// // Use of this source code is governed by a enterprise license that can be
// // found in the LICENSE file.

// /// @file dashboard_view.dart
// /// @brief Implementación de la capa de presentación (UI) para el dashboard de análisis.
// ///
// /// Este archivo define la estructura visual del dashboard, incluyendo la navegación
// /// lateral, el área de visualización de gráficos y los componentes de la tarjeta de
// /// gráficos. Sigue un enfoque de arquitectura limpia, separando el estado de la UI
// /// (`DashboardUIProvider`) del estado de los datos (`DashboardProvider`).

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'package:etl_tamizajes_app/features/dashboard/dashboard_provider.dart';
import 'package:etl_tamizajes_app/features/dashboard/dashboard_ui_provider.dart';
import 'package:etl_tamizajes_app/features/dashboard/analysis_helper.dart';
import 'chart_keys.dart';

// // --- WIDGETS DE ESTRUCTURA PRINCIPAL ---

// /// [DashboardView]
// ///
// /// Widget raíz de la pantalla del dashboard.
// /// Es responsable de inicializar los providers necesarios y de definir el layout
// /// principal de la pantalla, que incluye una `Scaffold` con una `AppBar` y el
// /// cuerpo principal que contiene la lógica de visualización.
// ///
// class DashboardView extends StatefulWidget {
//   const DashboardView({super.key});

//   @override
//   State<DashboardView> createState() => _DashboardViewState();
// }

// class _DashboardViewState extends State<DashboardView> {
//   // Estado local para gestionar la visibilidad del menú lateral (sidebar).
//   bool _isSidebarVisible = true;

//   /// Se utiliza `didChangeDependencies` para ajustar el estado inicial del sidebar
//   /// basándose en el contexto (tamaño de la pantalla), lo cual es más robusto
//   /// que hacerlo en `initState`.
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final isSmallScreen = MediaQuery.of(context).size.width < 800;
//     if (isSmallScreen) {
//       _isSidebarVisible = false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dashboard de Análisis de Datos'),
//         leading: IconButton(
//           icon: const Icon(Icons.menu),
//           tooltip: 'Mostrar/Ocultar Menú',
//           onPressed: () =>
//               setState(() => _isSidebarVisible = !_isSidebarVisible),
//         ),
//       ),
//       body: Row(
//         children: [
//           // El menú lateral se muestra u oculta con una animación para una mejor UX.
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             width: _isSidebarVisible ? 350 : 0,
//             curve: Curves.easeInOut,
//             child: ClipRect(
//               child: SizedBox(
//                 width: 350,
//                 child: _isSidebarVisible ? const SidebarMenu() : null,
//               ),
//             ),
//           ),
//           if (_isSidebarVisible) const VerticalDivider(thickness: 1, width: 1),
//           // El área de contenido principal ocupa el espacio restante.
//           const Expanded(child: ChartDisplayArea()),
//         ],
//       ),
//     );
//   }
// }

// /// [SidebarMenu]
// ///
// /// Componente de navegación que muestra una lista jerárquica de los gráficos
// /// disponibles, agrupados por categorías.
// ///
// /// Interactúa con `DashboardUIProvider` para actualizar el gráfico seleccionado y
// /// con `AuthProvider` para implementar control de acceso basado en roles (RBAC),
// /// asegurando que solo los usuarios autorizados vean ciertos reportes.
// class SidebarMenu extends StatelessWidget {
//   const SidebarMenu({super.key});

//   /// Definición estática y constante de la estructura del menú.
//   /// Centralizar esta configuración facilita el mantenimiento y la actualización
//   /// de los gráficos disponibles.
//   static final Map<String, List<String>> menuItems = {
//     '4.1 Categoría de información general sociodemográfica': [
//       'Distribución de la población por EAPB',
//       'Distribución de la población por género',
//       'Distribución de la población por curso de vida',
//       'Distribución de la población por comuna',
//       'Distribución de la población por estrato socioeconómico',
//       'Distribución de la población por entorno',
//     ],
//     '4.2 Categoría de resultados de información según el riesgo': [
//       'Distribución de la población según IMC',
//       'Distribución de la población según IMC vs género',
//       'Distribución de la población según IMC vs grupo de edad',
//       'Distribución de la población según IMC vs estrato socioeconómico',
//       'Distribución de la población según IMC vs EAPB',
//       'Distribución de la población según IMC vs comuna',
//       'Distribución de la población según Perímetro Abdominal',
//       'Distribución de la población según Perímetro Abdominal vs género',
//       'Distribución de la población según Perímetro Abdominal vs grupo de edad',
//       'Distribución de la población según Perímetro Abdominal vs estrato socioeconómico',
//       'Distribución de la población según Perímetro Abdominal vs EAPB',
//       'Distribución de la población según Perímetro Abdominal vs comuna',
//       'Distribución de la población según riesgo de Diabetes',
//       'Distribución de la población según riesgo de Diabetes vs género',
//       'Distribución de la población según riesgo de Diabetes vs grupo de edad',
//       'Distribución de la población según riesgo de Diabetes vs estrato socioeconómico',
//       'Distribución de la población según riesgo de Diabetes vs EAPB',
//       'Distribución de la población según Diabetes vs comuna',
//       'Distribución de la población según Riesgo Cardiovascular',
//       'Distribución de la población según Riesgo Cardiovascular vs género',
//       'Distribución de la población según Riesgo Cardiovascular vs grupo de edad',
//       'Distribución de la población según Riesgo Cardiovascular vs estrato socioeconómico',
//       'Distribución de la población según Riesgo Cardiovascular vs EAPB',
//       'Distribución de la población según Riesgo Cardiovascular vs comuna',
//       'Distribución de la población según Presión arterial',
//       'Distribución de la población según Presión arterial vs género',
//       'Distribución de la población según Presión arterial vs grupo de edad',
//       'Distribución de la población según Presión arterial vs estrato socioeconómico',
//       'Distribución de la población según Presión arterial vs EAPB',
//       'Distribución de la población según Presión arterial vs comuna',
//       'Distribución de la población según Presión arterial vs toma de medicamentos para la presión',
//       'Distribución de la población según Presión arterial vs toma de medicamentos para la presión vs EAPB',
//       'Distribución de la población según Presión arterial vs toma de medicamentos para la presión vs género',
//     ],
//     '4.3 Categoría de resultados de información según factores de riesgo comportamentales': [
//       'Distribución de la población según actividad física',
//       'Distribución de la población según Actividad Física vs género',
//       'Distribución de la población según Actividad Física vs grupo de edad',
//       'Distribución de la población según Actividad Física vs estrato socioeconómico',
//       'Distribución de la población según Actividad Física vs EAPB',
//       'Distribución de la población según Actividad Física vs comuna',
//       'Distribución de la población según consumo de Frutas y Verduras',
//       'Distribución de la población según Consumo de frutas y verduras vs género',
//       'Distribución de la población según Consumo de frutas y verduras vs grupo de edad',
//       'Distribución de la población según Consumo de frutas y verduras vs estrato socioeconómico',
//       'Distribución de la población según Consumo de frutas y verduras vs EAPB',
//       'Distribución de la población según Consumo de frutas y verduras vs comuna',
//       'Distribución de la población según hábito de fumar',
//       'Distribución de la población según Hábito de fumar vs género',
//       'Distribución de la población según Hábito de fumar vs grupo de edad',
//       'Distribución de la población según Hábito de fumar vs estrato socioeconómico',
//       'Distribución de la población según Hábito de fumar vs EAPB',
//       'Distribución de la población según Hábito de fumar vs comuna',
//     ],
//     '4.4 Categoría de resultados de información según Factores no Modificables': [
//       'Distribución de la población según antecedentes de valores de glucosa alta',
//       'Distribución de la población según Antecedentes de valores de glucosa alta vs género',
//       'Distribución de la población según Antecedentes de valores de glucosa alta vs grupo de edad',
//       'Distribución de la población según Antecedentes de valores de glucosa alta vs estrato socioeconómico',
//       'Distribución de la población según Antecedentes de valores de glucosa alta vs EAPB',
//       'Distribución de la población según Antecedentes de valores de glucosa alta vs comuna',
//       'Distribución de la población según herencia de diabetes',
//       'Distribución de la población según Herencia de diabetes vs género',
//       'Distribución de la población según Herencia de diabetes vs grupo de edad',
//       'Distribución de la población según Herencia de diabetes vs estrato socioeconómico',
//       'Distribución de la población según Herencia de diabetes vs EAPB',
//       'Distribución de la población según Herencia de diabetes vs comuna',
//       'Distribución de la población según sufre de diabetes',
//       'Distribución de la población según Sufre de diabetes vs género',
//       'Distribución de la población según Sufre de diabetes vs grupo de edad',
//       'Distribución de la población según Sufre de diabetes vs estrato socioeconómico',
//       'Distribución de la población según Sufre de diabetes vs EAPB',
//       'Distribución de la población según Sufre de diabetes vs comuna',
//     ],
//   };

//   @override
//   Widget build(BuildContext context) {
//     final uiProvider = context.watch<DashboardUIProvider>();
//     // final authProvider = context.watch<AuthProvider>(); // Descomentar para implementar RBAC

//     // Placeholder para la lógica de RBAC. Por ahora, todos ven todos los menús.
//     final accessibleMenuItems = menuItems;

//     return ListView.builder(
//       itemCount: accessibleMenuItems.length,
//       itemBuilder: (context, index) {
//         final category = accessibleMenuItems.keys.elementAt(index);
//         final charts = accessibleMenuItems[category]!;
//         return ExpansionTile(
//           title: Text(
//             category,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//             overflow: TextOverflow.ellipsis,
//           ),
//           initiallyExpanded: true,
//           children: charts.map((chartTitle) {
//             final isSelected = chartTitle == uiProvider.selectedChartTitle;
//             return ListTile(
//               title: Text(chartTitle, style: const TextStyle(fontSize: 14)),
//               selected: isSelected,
//               dense: true,
//               selectedTileColor: Theme.of(
//                 context,
//               ).primaryColor.withOpacity(0.1),
//               onTap: () => uiProvider.selectChart(chartTitle),
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
// }

// /// [ChartDisplayArea]
// ///
// /// Actúa como el "router" de la vista principal. Su única responsabilidad es:
// /// 1. Escuchar el estado de carga y los datos filtrados del `DashboardProvider`.
// /// 2. Escuchar el gráfico seleccionado del `DashboardUIProvider`.
// /// 3. Llamar al método `_getChartWidget` para determinar qué widget de gráfico mostrar.
// /// Esta separación mantiene la lógica de renderizado desacoplada del estado.
// class ChartDisplayArea extends StatelessWidget {
//   const ChartDisplayArea({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final uiProvider = context.watch<DashboardUIProvider>();
//     final dataProvider = context.watch<DashboardProvider>();

//     if (dataProvider.isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     if (dataProvider.filteredTamizajes.isEmpty) {
//       return const Center(
//         child: Text(
//           'No hay datos para mostrar en el rango de fechas seleccionado.',
//         ),
//       );
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: _getChartWidget(uiProvider.selectedChartTitle, dataProvider),
//     );
//   }

//   /// Determina qué `ChartCard` construir basado en el título del gráfico seleccionado.
//   /// Pide los datos ya procesados al `DashboardProvider` y decide el tipo de
//   /// visualización más apropiado.
// 
/// [SidebarMenu]
///
/// Componente de navegación que muestra una lista jerárquica de los gráficos
/// disponibles, agrupados por categorías.
///
/// Interactúa con `DashboardUIProvider` para actualizar el gráfico seleccionado y
/// con `AuthProvider` para implementar control de acceso basado en roles (RBAC),
/// asegurando que solo los usuarios autorizados vean ciertos reportes.
class SidebarMenu extends StatelessWidget {
  const SidebarMenu({super.key});

  /// Definición estática y constante de la estructura del menú.
  /// Centralizar esta configuración facilita el mantenimiento y la actualización
  /// de los gráficos disponibles.
  static final Map<String, List<ChartKey>> menuItems = {
    '4.1 Categoría de información general sociodemográfica': [
      ChartKey.cursoVida,
    ],
    '4.2 Categoría de resultados de información según el riesgo': [
      ChartKey.riesgoDiabetes,
      ChartKey.riesgoDiabetesGenero,
      ChartKey.riesgoDiabetesEdad,
      ChartKey.riesgoDiabetesEstrato,
      ChartKey.riesgoDiabetesEapb,
      ChartKey.riesgoDiabetesComuna,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final uiProvider = context.watch<DashboardUIProvider>();
    // final authProvider = context.watch<AuthProvider>(); // Descomentar para implementar RBAC

    // Placeholder para la lógica de RBAC. Por ahora, todos ven todos los menús.
    final accessibleMenuItems = menuItems;

    return ListView.builder(
      itemCount: accessibleMenuItems.length,
      itemBuilder: (context, index) {
        final category = accessibleMenuItems.keys.elementAt(index);
        final charts = accessibleMenuItems[category]!;
        return ExpansionTile(
          title: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          initiallyExpanded: true,
          children: charts.map((chartKey) {
            final isSelected = chartKey == uiProvider.selectedChart;
            return ListTile(
              title: Text(chartKey.title, style: const TextStyle(fontSize: 14)),
              selected: isSelected,
              dense: true,
              selectedTileColor:
                  Theme.of(context).primaryColor.withOpacity(0.1),
              onTap: () => uiProvider.selectChart(chartKey),
            );
          }).toList(),
        );
      },
    );
  }
}

/// [ChartDisplayArea]
///
/// Actúa como el "router" de la vista principal. Su única responsabilidad es:
/// 1. Escuchar el estado de carga y los datos filtrados del `DashboardProvider`.
/// 2. Escuchar el gráfico seleccionado del `DashboardUIProvider`.
/// 3. Llamar al método `_getChartWidget` para determinar qué widget de gráfico mostrar.
/// Esta separación mantiene la lógica de renderizado desacoplada del estado.
class ChartDisplayArea extends StatelessWidget {
  const ChartDisplayArea({super.key});

  @override
  Widget build(BuildContext context) {
    final uiProvider = context.watch<DashboardUIProvider>();
    final dataProvider = context.watch<DashboardProvider>();

    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (dataProvider.filteredTamizajes.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos para mostrar en el rango de fechas seleccionado.',
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _getChartWidget(uiProvider.selectedChart, dataProvider),
    );
  }

  /// Determina qué `ChartCard` construir basado en el título del gráfico seleccionado.
  /// Pide los datos ya procesados al `DashboardProvider` y decide el tipo de
  /// visualización más apropiado.


  Widget _getChartWidget(ChartKey chartKey, DashboardProvider dataProvider) {
    final dynamic chartData = dataProvider.getChartData(chartKey);

    if (chartData == null || (chartData is Map && chartData.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No hay datos disponibles para el gráfico:\n"${chartKey.title}"',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (chartData is Map<String, Map<String, double>>) {
      final chartType = {
        ChartKey.riesgoDiabetesEapb,
        ChartKey.riesgoDiabetesComuna,
      }.contains(chartKey)
          ? ChartType.horizontalGroupedBar
          : ChartType.groupedBar;
      return ChartCard.bivariate(
        title: chartKey.title,
        data: chartData,
        type: chartType,
      );
    }

    if (chartData is Map<String, double>) {
      final ChartType selectedType =
          chartData.length <= 6 ? ChartType.pie : ChartType.bar;
      return ChartCard.univariate(
        title: chartKey.title,
        data: chartData,
        type: selectedType,
      );
    }

    return ChartCard.trivariate(
      title: chartKey.title,
      data: chartData,
      type: ChartType.groupedBar,
    );
  }
}

// --- COMPONENTES REUTILIZABLES DE LA UI ---

/// Define los tipos de gráficos que el [ChartCard] puede renderizar.
/// Utilizar un enum mejora la seguridad de tipo y la legibilidad del código.
/// Esto permite que el desarrollador sepa exactamente qué tipos de gráficos están disponibles
/// y evita errores de tipo en tiempo de compilación.

enum ChartType {
  pie,
  bar,
  horizontalBar,
  //stackedBar,
  //horizontalStackedBar,
  groupedBar,
  horizontalGroupedBar,
}

/// [ChartCard]
///
/// Un widget de UI altamente reutilizable y agnóstico de los datos.
/// Su única responsabilidad es renderizar una visualización y su información
/// asociada (título, leyenda, tabla de datos) basado en los datos y el tipo
/// de gráfico que recibe.
///
class ChartCard extends StatefulWidget {
  const ChartCard._({
    required this.title,
    required this.type,
    required this.data,
    this.analysis,
  });

  /// Constructor factory para gráficos univariados.

  factory ChartCard.univariate({
    required String title,
    required Map<String, double> data,
    required ChartType type,
  }) => ChartCard._(
    title: title,
    data: data,
    type: type,
    analysis: AnalysisHelper.generateUnivariateAnalysis(title, data),
  );

  /// Constructor factory para gráficos bivariados.

  factory ChartCard.bivariate({
    required String title,
    required Map<String, Map<String, double>> data,
    required ChartType type,
  }) => ChartCard._(
    title: title,
    data: data,
    type: type,
    analysis: AnalysisHelper.generateBivariateAnalysis(title, data),
  );

  /// Constructor factory para gráficos trivariados (facetados).

  factory ChartCard.trivariate({
    required String title,
    required Map<String, Map<String, Map<String, double>>> data,
    required ChartType type,
  }) => ChartCard._(title: title, data: data, type: type);

  final String title;
  final ChartType type;
  final dynamic data;
  final String? analysis;

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  // Estado para la interactividad del gráfico (ej. resaltar una sección del pie chart).
  int touchedIndex = -1;

  List<String> _primaryCategoriesSortedByKey(
    Map<String, Map<String, double>> data,
  ) {
    return data.keys.toList()..sort();
  }

  List<String> _allSecondaryCategoriesSorted(
    Map<String, Map<String, double>> data,
  ) {
    return data.values.expand((e) => e.keys).toSet().toList()..sort();
  }

  // Paleta de colores consistente para todos los gráficos.
  final List<Color> colorPalette = [
    Colors.blue.shade600,
    Colors.red.shade600,
    Colors.green.shade600,
    Colors.orange.shade600,
    Colors.purple.shade600,
    Colors.brown.shade600,
    Colors.pink.shade600,
    Colors.teal.shade600,
    Colors.indigo.shade600,
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data == null || (widget.data is Map && widget.data.isEmpty)) {
      return _buildEmptyCard();
    }
    // Lógica para trivariados: renderiza una columna de gráficos bivariados.
    if (widget.data is Map<String, Map<String, Map<String, double>>>) {
      final trivariateData =
          widget.data as Map<String, Map<String, Map<String, double>>>;
      return Column(
        children: trivariateData.entries.map((facetEntry) {
          return ChartCard.bivariate(
            title: '${widget.title} - (${facetEntry.key})',
            data: facetEntry.value,
            type: widget.type,
          );
        }).toList(),
      );
    }
    // Estructura principal de la tarjeta para gráficos univariados y bivariados.

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 400,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildChart(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildChartLegend(),
          ),
          ExpansionTile(
            title: const Text('Ver Análisis y Datos'),
            children: [
              if (widget.analysis != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    widget.analysis!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              _buildDataTable(),
            ],
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS DE CONSTRUCCIÓN DE LA UI ---

  /// Selecciona el método de renderizado de gráfico apropiado.

  Widget _buildChart() {
    switch (widget.type) {
      case ChartType.pie:
        return _buildAdvancedPieChart();
      case ChartType.bar:
        return _buildAdvancedBarChart(isHorizontal: false);
      case ChartType.horizontalBar:
        return _buildAdvancedBarChart(isHorizontal: true);
      case ChartType.groupedBar:
        return _buildGroupedBarChart();
      case ChartType.horizontalGroupedBar:
        return _buildHorizontalGroupedBarChart();
    }
  }

  /// Construye la leyenda del gráfico de manera dinámica.

  Widget _buildChartLegend() {
    switch (widget.type) {
      case ChartType.pie:
      case ChartType.bar:
      case ChartType.horizontalBar:
        final Map<String, double> data = widget.data;
        final legendData = <String, Color>{};

        //Ordenar entradas por valor descendente para asignar colores de manera consistente.
        final entries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (int i = 0; i < entries.length; i++) {
          legendData[entries[i].key] = colorPalette[i % colorPalette.length];
        }
        return _buildLegend(legendData);

      case ChartType.horizontalGroupedBar:
      case ChartType.groupedBar:
        if (widget.data is! Map<String, Map<String, double>>) {
          return const SizedBox.shrink();
        }
        final Map<String, Map<String, double>> data = widget.data;
        // La leyenda para gráficos bivariados se basa en las categorías secundarias,
        // cuyo orden es consistente y no necesita ser ordenado por valor.
        final allSecondaryCategories = data.values
            .expand((e) => e.keys)
            .toSet()
            .toList();
        final legendData = <String, Color>{};
        for (int i = 0; i < allSecondaryCategories.length; i++) {
          legendData[allSecondaryCategories[i]] =
              colorPalette[i % colorPalette.length];
        }
        return _buildLegend(legendData);
    }
  }

  // Widget genérico para renderizar una leyenda.

  Widget _buildLegend(Map<String, Color> legendData) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: legendData.entries
          .map(
            (entry) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: entry.value,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(entry.key),
              ],
            ),
          )
          .toList(),
    );
  }

  // Muestra una tarjeta de mensaje cuando no hay datos para un gráfico.

  Widget _buildEmptyCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'No hay datos suficientes para generar este gráfico.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construye la tabla de datos correspondiente a la visualización.

  Widget _buildDataTable() {
    final data = widget.data;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: (data is Map<String, double>)
            ? _buildUnivariateTable(data)
            : _buildBivariateTable(data as Map<String, Map<String, double>>),
      ),
    );
  }

  DataTable _buildUnivariateTable(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        return cmp != 0 ? cmp : a.key.compareTo(b.key);
      });
    return DataTable(
      columns: const [
        DataColumn(
          label: Text(
            'Categoría',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            'Cantidad',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'Porcentaje (%)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
      ],
      rows: sortedEntries.map((entry) {
        final percentage = total > 0
            ? (entry.value / total * 100).toStringAsFixed(1)
            : '0';
        return DataRow(
          cells: [
            DataCell(Text(entry.key)),
            DataCell(Text(entry.value.toInt().toString())),
            DataCell(Text('$percentage%')),
          ],
        );
      }).toList(),
    );
  }

  DataTable _buildBivariateTable(Map<String, Map<String, double>> data) {
    final primaryCategories = data.keys.toList();
    final allSecondaryCategories =
        data.values.expand((e) => e.keys).toSet().toList()..sort();

    final sortedPrimary = primaryCategories.toList()
      ..sort((a, b) {
        final totalA = data[a]!.values.fold(0.0, (x, y) => x + y);
        final totalB = data[b]!.values.fold(0.0, (x, y) => x + y);
        final cmp = totalB.compareTo(totalA);
        return cmp != 0 ? cmp : a.compareTo(b);
      });

    final columnTotals = <String, double>{};
    double grandTotal = 0;
    for (var primaryCat in sortedPrimary) {
      final rowData = data[primaryCat]!;
      double rowTotal = 0;
      for (var secCat in allSecondaryCategories) {
        final value = rowData[secCat] ?? 0;
        columnTotals[secCat] = (columnTotals[secCat] ?? 0) + value;
        rowTotal += value;
      }
      grandTotal += rowTotal;
    }

    final dataRows = sortedPrimary.map((primaryCat) {
      final rowData = data[primaryCat]!;
      final rowTotal = rowData.values.fold(0.0, (a, b) => a + b);
      return DataRow(
        cells: [
          DataCell(
            Text(
              primaryCat,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...allSecondaryCategories.map(
            (secCat) =>
                DataCell(Text((rowData[secCat] ?? 0).toInt().toString())),
          ),
          DataCell(
            Text(
              rowTotal.toInt().toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }).toList();

    final totalRow = DataRow(
      cells: [
        const DataCell(
          Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...allSecondaryCategories.map(
          (secCat) => DataCell(
            Text(
              (columnTotals[secCat] ?? 0).toInt().toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          Text(
            grandTotal.toInt().toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    return DataTable(
      columns: [
        const DataColumn(
          label: Text('Grupo', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...allSecondaryCategories.map(
          (cat) => DataColumn(
            label: Text(
              cat,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ),
        const DataColumn(
          label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
          numeric: true,
        ),
      ],
      rows: [...dataRows, totalRow],
    );
  }

  // --- MÉTODOS ESPECÍFICOS DE RENDERIZADO DE GRÁFICOS ---

  Widget _buildAdvancedPieChart() {
    final Map<String, double> data = widget.data;
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 80,
        sections: List.generate(data.length, (i) {
          final isTouched = i == touchedIndex;
          final entry = data.entries.elementAt(i);
          final color = colorPalette[i % colorPalette.length];
          final total = data.values.fold(0.0, (a, b) => a + b);
          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
          return PieChartSectionData(
            color: color,
            value: entry.value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: isTouched ? 70.0 : 60.0,
            titleStyle: TextStyle(
              fontSize: isTouched ? 18.0 : 14.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }

  // --- MÉTODOS DE RENDERIZADO DE GRÁFICOS OPTIMIZADOS ---

  Widget _buildAdvancedBarChart({required bool isHorizontal}) {
    final Map<String, double> data = widget.data;
    final chartData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Widget titleWidget(double value, TitleMeta meta) {
      final index = value.toInt();
      if (index >= chartData.length) return const SizedBox.shrink();

      final textWidget = Text(
        chartData[index].key,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: isHorizontal ? TextAlign.right : TextAlign.center,
      );

      return isHorizontal
          ? Container(
              width: 140,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 4),
              child: textWidget,
            )
          : textWidget;
    }

    final barChart = BarChart(
      BarChartData(
        groupsSpace: 12,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${chartData[group.x].key}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: rod.toY.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: List.generate(
          chartData.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: chartData[index].value,
                color: colorPalette[index % colorPalette.length],
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !isHorizontal,
              getTitlesWidget: titleWidget,
              reservedSize: 42,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: isHorizontal,
              getTitlesWidget: titleWidget,
              reservedSize: 150,
            ),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: !isHorizontal,
          drawHorizontalLine: isHorizontal,
        ),
        borderData: FlBorderData(show: false),
      ),
    );

    return isHorizontal
        ? RotatedBox(quarterTurns: -1, child: barChart)
        : barChart;
  }

  /// Construye un gráfico de barras agrupadas vertical.
  Widget _buildGroupedBarChart() {
    final Map<String, Map<String, double>> data = widget.data;
    final primaryCategories = data.keys.toList()..sort();
    final allSecondaryCategories = data.values
        .expand((e) => e.keys)
        .toSet()
        .toList();
    double maxY = 0;

    final Map<String, Map<String, double>> percentageData = {};
    for (var primaryCat in primaryCategories) {
      final groupData = data[primaryCat]!;
      final total = groupData.values.fold(0.0, (sum, item) => sum + item);
      percentageData[primaryCat] = {};
      for (var secondaryCat in allSecondaryCategories) {
        final value = groupData[secondaryCat] ?? 0;
        final percentage = total > 0 ? (value / total * 100) : 0.0;
        percentageData[primaryCat]![secondaryCat] = percentage;
        if (percentage > maxY) {
          maxY = percentage;
        }
      }
    }

    // --- AJUSTE DINÁMICO DE ANCHO Y ESPACIADO ---
    // Se calcula un ancho de barra dinámico para que se ajuste al espacio disponible.
    // El '0.6' representa que el 60% del espacio se usará para las barras.
    // Puedes ajustar este factor (ej. 0.5 o 0.7) para cambiar el grosor.
    final groupWidth = 400 / primaryCategories.length * 0.6;
    final barWidth = groupWidth / allSecondaryCategories.length;

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        // El espaciado entre grupos ahora es dinámico.
        groupsSpace: (400 / primaryCategories.length) * 0.4,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final secondaryCat = allSecondaryCategories[rodIndex];
              return BarTooltipItem(
                '${primaryCategories[group.x]}\n$secondaryCat: ${rod.toY.toStringAsFixed(1)}%',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= primaryCategories.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    primaryCategories[index],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(drawVerticalLine: false),
        barGroups: List.generate(primaryCategories.length, (i) {
          final primaryCat = primaryCategories[i];
          final groupData = percentageData[primaryCat]!;
          return BarChartGroupData(
            x: i,
            barRods: List.generate(allSecondaryCategories.length, (j) {
              final secondaryCat = allSecondaryCategories[j];
              return BarChartRodData(
                toY: groupData[secondaryCat] ?? 0,
                color: colorPalette[j % colorPalette.length],
                width: barWidth, // Ancho dinámico
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  /// Construye un gráfico de barras agrupadas horizontal.
  Widget _buildHorizontalGroupedBarChart() {
    final Map<String, Map<String, double>> data = widget.data;
    final primaryCategories = data.keys.toList()..sort();
    final allSecondaryCategories = data.values
        .expand((e) => e.keys)
        .toSet()
        .toList();
    double maxY = 0;

    final Map<String, Map<String, double>> percentageData = {};
    for (var primaryCat in primaryCategories) {
      final groupData = data[primaryCat]!;
      final total = groupData.values.fold(0.0, (sum, item) => sum + item);
      percentageData[primaryCat] = {};
      for (var secondaryCat in allSecondaryCategories) {
        final value = groupData[secondaryCat] ?? 0;
        final percentage = total > 0 ? (value / total * 100) : 0.0;
        percentageData[primaryCat]![secondaryCat] = percentage;
        if (percentage > maxY) {
          maxY = percentage;
        }
      }
    }

    // --- AJUSTE DINÁMICO DE ANCHO Y ESPACIADO ---
    final groupHeight = 400 / primaryCategories.length * 0.6;
    final barHeight = groupHeight / allSecondaryCategories.length;

    final barChart = BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        // El espaciado entre grupos ahora es dinámico.
        groupsSpace: (400 / primaryCategories.length) * 0.4,
        alignment: BarChartAlignment.spaceEvenly,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final secondaryCat = allSecondaryCategories[rodIndex];
              return BarTooltipItem(
                '${primaryCategories[group.x]}\n$secondaryCat: ${rod.toY.toStringAsFixed(1)}%',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= primaryCategories.length) {
                  return const SizedBox.shrink();
                }
                return RotatedBox(
                  quarterTurns: 1,
                  child: Container(
                    width: 140,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      primaryCategories[index],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                );
              },
              reservedSize: 150,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) =>
                  RotatedBox(quarterTurns: 1, child: Text('${value.toInt()}%')),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(drawVerticalLine: false),
        barGroups: List.generate(primaryCategories.length, (i) {
          final primaryCat = primaryCategories[i];
          final groupData = percentageData[primaryCat]!;
          return BarChartGroupData(
            x: i,
            barRods: List.generate(allSecondaryCategories.length, (j) {
              final secondaryCat = allSecondaryCategories[j];
              return BarChartRodData(
                toY: groupData[secondaryCat] ?? 0,
                color: colorPalette[j % colorPalette.length],
                width: barHeight, // Ancho (altura en este caso) dinámico
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              );
            }),
          );
        }),
      ),
    );

    return RotatedBox(quarterTurns: -1, child: barChart);
  }
}
