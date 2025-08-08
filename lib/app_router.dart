import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:etl_tamizajes_app/features/auth/auth_provider.dart';
import 'package:etl_tamizajes_app/features/auth/login_view.dart';
import 'package:etl_tamizajes_app/features/upload/upload_view.dart';
import 'package:etl_tamizajes_app/features/data_management/record_list_view.dart';
import 'package:etl_tamizajes_app/features/dashboard/dashboard_view.dart';
import 'package:etl_tamizajes_app/features/user_management/user_management_view.dart'; // Importar la nueva vista
import 'package:etl_tamizajes_app/main_scaffold.dart';
import 'package:etl_tamizajes_app/features/data_master/data_master_view.dart';

class AppRouter {
  AppRouter(this.authProvider);
  final AuthProvider authProvider;

  late final GoRouter router = GoRouter(
    // El router ahora refresca su estado cuando cambia el AuthProvider
    refreshListenable: authProvider,

    // Ruta inicial por defecto
    initialLocation: '/upload',

    routes: [
      // --- Rutas protegidas (dentro del Shell con el menú de navegación) ---
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/upload',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UploadView()),
          ),
          GoRoute(
            path: '/management', // Ruta para ver lista de tamizajes
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RecordListView()),
          ),
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardView()),
          ),
          // --- NUEVA RUTA PARA GESTIÓN DE USUARIOS ---
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: UserManagementView()),
          ),

          // --- NUEVA RUTA DEL MAESTRO DE DATOS ---
          GoRoute(
            path: '/data-master',
            builder: (context, state) => const DataMasterView(),
          ),
        ],
      ),
      // --- Ruta de Login (fuera del Shell) ---
      GoRoute(path: '/login', builder: (context, state) => const LoginView()),
    ],

    // --- LÓGICA DE REDIRECCIÓN CENTRALIZADA ---
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authProvider.status == AuthStatus.authenticated;
      final location = state.matchedLocation;

      // Si el usuario no está logueado y no está intentando ir a /login, lo redirigimos.
      if (!isLoggedIn && location != '/login') {
        return '/login';
      }

      // Si el usuario ya está logueado y trata de ir a /login, lo mandamos a su home.
      if (isLoggedIn && location == '/login') {
        return '/upload';
      }

      // --- REGLAS DE ACCESO BASADAS EN ROL ---
      if (isLoggedIn) {
        // Regla: Solo los Admins pueden acceder a /users
        if (location == '/users' && !authProvider.isAdmin) {
          return '/upload'; // Ruta de "Acceso Denegado"
        }

        // Regla: Los Auxiliares no pueden acceder a /dashboard
        if (location == '/dashboard' && authProvider.isAuxiliar) {
          return '/upload'; // Ruta de "Acceso Denegado"
        }

        if (location == '/data-master' && !authProvider.isAdmin) {
          return '/upload'; // Si no es admin, no puede entrar
        }
      }

      // Si no se cumple ninguna condición de redirección, permite el acceso.
      return null;
    },
  );
}
