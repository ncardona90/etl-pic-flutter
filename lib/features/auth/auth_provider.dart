// lib/features/auth/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:etl_tamizajes_app/core/models/app_user.dart';
import 'package:etl_tamizajes_app/core/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {

  AuthProvider() {
    _authService.user.listen((user) {
      _user = user;
      _status = user == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      notifyListeners();
    });
  }
  final AuthService _authService = AuthService();
  AppUser? _user;
  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- GETTERS DE ROLES ESTANDARIZADOS ---
  bool get isAdmin => _user?.role == 'admin';
  bool get isEnfermeraJefe => _user?.role == 'Enfermera Jefe';
  bool get isAuxiliar => _user?.role == 'Auxiliar';

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _setLoading(false);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _errorMessage = null;
    notifyListeners();
  }
}
