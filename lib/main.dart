import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:etl_tamizajes_app/firebase_options.dart';

import 'package:etl_tamizajes_app/app_router.dart';
import 'package:etl_tamizajes_app/core/services/firebase_service.dart';
import 'package:etl_tamizajes_app/features/auth/auth_provider.dart';
import 'package:etl_tamizajes_app/features/dashboard/dashboard_provider.dart';
import 'package:etl_tamizajes_app/features/dashboard/dashboard_ui_provider.dart';
import 'package:etl_tamizajes_app/features/upload/upload_provider.dart';
import 'package:etl_tamizajes_app/features/data_management/data_management_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- 1. SERVICIOS SIN DEPENDENCIAS ---
        // Se provee el servicio de Firebase para que esté disponible en toda la app.
        Provider<FirebaseService>(create: (_) => FirebaseService()),

        // --- 2. PROVIDERS DE ESTADO QUE NO DEPENDEN DE OTROS PROVIDERS ---
        // AuthProvider es fundamental y otros providers dependen de él, por eso va primero.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // DashboardUIProvider maneja solo el estado de la UI del dashboard, es independiente.
        ChangeNotifierProvider(create: (_) => DashboardUIProvider()),

        // --- 3. PROVIDERS QUE DEPENDEN DE SERVICIOS O DE OTROS PROVIDERS ---
        // Se usa ChangeNotifierProxyProvider si un provider necesita datos de otro que cambia.
        // Pero en este caso, solo necesitamos leer la instancia al momento de la creación,
        // por lo que `create` con `context.read` es suficiente y más simple.

        // UploadProvider necesita FirebaseService y AuthProvider.
        ChangeNotifierProvider(
          create: (context) => UploadProvider(
            firebaseService: context.read<FirebaseService>(),
            authProvider: context.read<AuthProvider>(),
          ),
        ),

        // DataManagementProvider necesita FirebaseService.
        ChangeNotifierProvider(
          create: (context) => DataManagementProvider(
            firebaseService: context.read<FirebaseService>(),
          ),
        ),

        // DashboardProvider necesita FirebaseService.
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(
            firebaseService: context.read<FirebaseService>(),
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // El router depende del estado de autenticación para las redirecciones.
          final router = AppRouter(authProvider).router;

          return MaterialApp.router(
            title: 'ETL Tamizajes',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
