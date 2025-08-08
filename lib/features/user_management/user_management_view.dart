// lib/features/user_management/user_management_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etl_tamizajes_app/core/models/app_user.dart';
import 'package:etl_tamizajes_app/features/user_management/user_management_provider.dart';

void showUserDialog(BuildContext context, {AppUser? user}) {
  showDialog(
    context: context,
    builder: (_) {
      return ChangeNotifierProvider.value(
        value: context.read<UserManagementProvider>(),
        child: UserEditDialog(user: user),
      );
    },
  );
}

class UserManagementView extends StatelessWidget {
  const UserManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserManagementProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Gestión de Usuarios')),
        body: const UserList(),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () => showUserDialog(context),
              tooltip: 'Añadir Usuario',
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  const UserList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserManagementProvider>();
    return StreamBuilder<List<AppUser>>(
      stream: provider.usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay usuarios para mostrar.'));
        }

        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(user.role.substring(0, 1).toUpperCase()),
              ),
              title: Text(user.displayName),
              subtitle: Text(
                '${user.userName} - ${user.email} - Rol: ${user.role}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => showUserDialog(context, user: user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, user),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${user.displayName}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final provider = context.read<UserManagementProvider>();
              final success = await provider.deleteUser(user.uid);
              Navigator.of(ctx).pop();
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Error al eliminar'),
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class UserEditDialog extends StatefulWidget {
  const UserEditDialog({super.key, this.user});
  final AppUser? user;

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();

  // Usar TextEditingControllers es la mejor práctica para formularios
  late final TextEditingController _displayNameController;
  late final TextEditingController _userNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  late String _role;
  final _roles = ['admin', 'Enfermera Jefe', 'Auxiliar'];

  @override
  void initState() {
    super.initState();
    // Inicializamos los controladores con los datos del usuario (si existe)
    _displayNameController = TextEditingController(
      text: widget.user?.displayName ?? '',
    );
    _userNameController = TextEditingController(
      text: widget.user?.userName ?? '',
    );
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _role = widget.user?.role ?? 'Auxiliar';
  }

  @override
  void dispose() {
    // Es importante desechar los controladores para liberar memoria
    _displayNameController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UserManagementProvider>();
    bool success = false;

    if (widget.user == null) {
      // Creando nuevo usuario
      success = await provider.createUser(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _displayNameController.text,
        role: _role,
        userName: _userNameController.text,
      );
    } else {
      // Actualizando usuario existente
      final updatedUser = AppUser(
        uid: widget.user!.uid,
        email: _emailController.text,
        displayName: _displayNameController.text,
        role: _role,
        userName: _userNameController.text,
      );
      success = await provider.updateUser(updatedUser);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserManagementProvider>();
    final isCreating = widget.user == null;

    return AlertDialog(
      title: Text(isCreating ? 'Añadir Usuario' : 'Editar Usuario'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (val) => val!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Usuario (para login)',
                ),
                validator: (val) => val!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val!.isEmpty || !val.contains('@')
                    ? 'Correo inválido'
                    : null,
              ),
              if (isCreating) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (val) => val!.length < 6
                      ? 'Debe tener al menos 6 caracteres'
                      : null,
                ),
              ],
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: _roles
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _role = val!),
              ),
              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (provider.isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
