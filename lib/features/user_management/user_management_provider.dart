import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:etl_tamizajes_app/core/models/app_user.dart';
import 'package:etl_tamizajes_app/core/services/firebase_service.dart';

class UserManagementProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  ); // O tu región

  Stream<List<AppUser>> get usersStream => _firebaseService.getUsersStream();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null; // Limpiar errores al iniciar
    notifyListeners();
  }

  /// Llama a una Cloud Function para crear un nuevo usuario.
  Future<bool> createUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String userName,
  }) async {
    _setLoading(true);
    try {
      final callable = _functions.httpsCallable('createUser');
      final result = await callable.call(<String, dynamic>{
        'email': email,
        'password': password,
        'displayName': displayName,
        'role': role,
        'userName': userName,
      });

      if (result.data['error'] != null) {
        _errorMessage = result.data['error'];
        _setLoading(false);
        return false;
      }
      _setLoading(false);
      return true;
    } on FirebaseFunctionsException catch (e) {
      _errorMessage = e.message ?? 'Ocurrió un error desconocido.';
      _setLoading(false);
      return false;
    }
  }

  /// Actualiza los datos de un usuario en Firestore.
  Future<bool> updateUser(AppUser user) async {
    _setLoading(true);
    try {
      await _firebaseService.saveUser(user);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar el usuario.';
      _setLoading(false);
      return false;
    }
  }

  /// Llama a una Cloud Function para eliminar un usuario.
  Future<bool> deleteUser(String uid) async {
    _setLoading(true);
    try {
      final callable = _functions.httpsCallable('deleteUser');
      final result = await callable.call(<String, dynamic>{'uid': uid});

      if (result.data['error'] != null) {
        _errorMessage = result.data['error'];
        _setLoading(false);
        return false;
      }
      _setLoading(false);
      return true;
    } on FirebaseFunctionsException catch (e) {
      _errorMessage = e.message ?? 'Ocurrió un error desconocido.';
      _setLoading(false);
      return false;
    }
  }
}
