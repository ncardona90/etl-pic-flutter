// lib/main_scaffold.dart

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:etl_tamizajes_app/features/auth/auth_provider.dart';
import 'package:etl_tamizajes_app/shared/widgets/responsive_helper.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/upload')) return 0;
    if (location.startsWith('/management')) return 1;
    if (location.startsWith('/dashboard')) return 2;
    if (location.startsWith('/users')) return 3;
    if (location.startsWith('/data-master')) return 4;
    return 0;
  }

  void _onDestinationSelected(int index, BuildContext context) {
    const adminRoutes = [
      '/upload',
      '/management',
      '/dashboard',
      '/users',
      '/data-master',
    ];
    const enfermeraRoutes = ['/upload', '/management', '/dashboard'];
    const auxiliarRoutes = ['/upload', '/management'];

    final authProvider = context.read<AuthProvider>();

    if (authProvider.isAdmin) {
      if (index < adminRoutes.length) context.go(adminRoutes[index]);
    } else if (authProvider.isEnfermeraJefe) {
      if (index < enfermeraRoutes.length) context.go(enfermeraRoutes[index]);
    } else {
      if (index < auxiliarRoutes.length) context.go(auxiliarRoutes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.getSize(context);

    if (screenSize == ScreenSize.xs || screenSize == ScreenSize.sm) {
      return Scaffold(
        body: child,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.appTitle),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        drawer: const _AppDrawer(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          const _AppNavigationRail(),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// --- WIDGETS INTERNOS PARA EL MENÚ DE NAVEGACIÓN ---

class _AppNavigationRail extends StatelessWidget {
  const _AppNavigationRail();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final selectedIndex =
        (context.findAncestorWidgetOfExactType<MainScaffold>())!
            ._calculateSelectedIndex(context);
    final onDestinationSelected =
        (context.findAncestorWidgetOfExactType<MainScaffold>())!
            ._onDestinationSelected;

    final destinations = _buildDestinations(authProvider, context);

    return NavigationRail(
      selectedIndex: selectedIndex < destinations.length ? selectedIndex : 0,
      onDestinationSelected: (index) => onDestinationSelected(index, context),
      labelType: NavigationRailLabelType.all,
      backgroundColor: const Color(0xFFFFFFFF),
      indicatorColor: Colors.indigo.shade50,
      selectedIconTheme: IconThemeData(color: Colors.indigo.shade800),
      unselectedIconTheme: IconThemeData(color: Colors.grey.shade600),
      selectedLabelTextStyle: TextStyle(
        color: Colors.indigo.shade800,
        fontWeight: FontWeight.bold,
      ),
      leading: _buildUserHeader(context, authProvider),
      // --- CORRECCIÓN APLICADA AQUÍ ---
      // Se eliminó el widget `Expanded` que causaba el error de layout.
      // El `Align` es suficiente para posicionar el botón en la parte inferior
      // del espacio restante del NavigationRail.
      trailing: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: _buildLogoutButton(context),
        ),
      ),
      destinations: destinations,
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final selectedIndex =
        (context.findAncestorWidgetOfExactType<MainScaffold>())!
            ._calculateSelectedIndex(context);
    final onDestinationSelected =
        (context.findAncestorWidgetOfExactType<MainScaffold>())!
            ._onDestinationSelected;

    final destinations = _buildDestinations(authProvider, context);

    return Drawer(
      child: Column(
        children: [
          _buildUserHeader(context, authProvider),
          for (int i = 0; i < destinations.length; i++)
            ListTile(
              leading: selectedIndex == i
                  ? destinations[i].selectedIcon
                  : destinations[i].icon,
              title: destinations[i].label,
              selected: selectedIndex == i,
              selectedTileColor: Colors.indigo.shade50,
              selectedColor: Colors.indigo.shade800,
              onTap: () {
                Navigator.pop(context);
                onDestinationSelected(i, context);
              },
            ),
          const Spacer(),
          const Divider(),
          _buildLogoutButton(context, isDrawer: true),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// --- HELPERS COMPARTIDOS ---

List<NavigationRailDestination> _buildDestinations(
    AuthProvider authProvider, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final allDestinations = [
    NavigationRailDestination(
      icon: const Icon(Icons.cloud_upload_outlined),
      selectedIcon: const Icon(Icons.cloud_upload),
      label: Text(l10n.upload),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.folder_copy_outlined),
      selectedIcon: const Icon(Icons.folder_copy),
      label: Text(l10n.records),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.dashboard_outlined),
      selectedIcon: const Icon(Icons.dashboard),
      label: Text(l10n.dashboard),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.people_outline),
      selectedIcon: const Icon(Icons.people),
      label: Text(l10n.users),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.storage_outlined),
      selectedIcon: const Icon(Icons.storage),
      label: Text(l10n.master),
    ),
  ];

  if (authProvider.isAdmin) {
    return allDestinations;
  }
  if (authProvider.isEnfermeraJefe) {
    return allDestinations.sublist(0, 3); // Cargar, Registros, Dashboard
  }
  return allDestinations.sublist(0, 2); // Cargar, Registros
}

Widget _buildUserHeader(BuildContext context, AuthProvider authProvider) {
  final user = authProvider.user;
  final initial = user?.displayName.isNotEmpty == true
      ? user!.displayName[0].toUpperCase()
      : 'U';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
    decoration: BoxDecoration(color: Colors.indigo.shade700),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 28,
              color: Colors.indigo.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user?.displayName ?? AppLocalizations.of(context)!.userPlaceholder,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          user?.email ?? '',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _buildLogoutButton(BuildContext context, {bool isDrawer = false}) {
  final l10n = AppLocalizations.of(context)!;
  final content = Row(
    mainAxisAlignment: isDrawer
        ? MainAxisAlignment.start
        : MainAxisAlignment.center,
    children: [
      const Icon(Icons.logout, color: Colors.redAccent),
      if (isDrawer) ...[
        const SizedBox(width: 16),
        Text(
          l10n.logout,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ],
  );

  if (isDrawer) {
    return ListTile(
      title: content,
      onTap: () {
        Navigator.pop(context);
        context.read<AuthProvider>().signOut();
      },
    );
  }

  return IconButton(
    icon: content,
    onPressed: () => context.read<AuthProvider>().signOut(),
    tooltip: l10n.logout,
  );
}
