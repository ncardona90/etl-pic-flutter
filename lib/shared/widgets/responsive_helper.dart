import 'package:flutter/material.dart';

// Define los breakpoints estándar para una UI responsiva.
class AppBreakpoints {
  static const double xs = 0; // Extra pequeño
  static const double sm = 480; // Pequeño (móviles)
  static const double md = 768; // Mediano (tablets)
  static const double lg = 1024; // Grande (laptops pequeñas)
  static const double xl = 1280; // Extra grande (escritorios)
  static const double xxl = 1536; // Ultra (pantallas 2K/4K)
}

// Enum para representar los tamaños de pantalla de forma clara.
enum ScreenSize { xs, sm, md, lg, xl, xxl }

// Clase de ayuda para determinar el tamaño de pantalla actual.
class ResponsiveHelper {
  static ScreenSize getSize(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width >= AppBreakpoints.xxl) return ScreenSize.xxl;
    if (width >= AppBreakpoints.xl) return ScreenSize.xl;
    if (width >= AppBreakpoints.lg) return ScreenSize.lg;
    if (width >= AppBreakpoints.md) return ScreenSize.md;
    if (width >= AppBreakpoints.sm) return ScreenSize.sm;
    return ScreenSize.xs;
  }
}
