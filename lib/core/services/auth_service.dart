import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etl_tamizajes_app/core/models/app_user.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream para escuchar los cambios de estado de autenticación de Firebase.
  Stream<AppUser?> get user {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      // Si hay un usuario, obtenemos sus datos de Firestore (incluyendo el rol).
      return await _getUserFromFirestore(firebaseUser.uid);
    });
  }

  /// Inicia sesión con correo y contraseña.
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Éxito
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Devuelve un mensaje de error legible para el usuario.
      if (e.code == 'user-not-found') {
        return 'No se encontró un usuario con ese correo electrónico.';
      } else if (e.code == 'wrong-password') {
        return 'Contraseña incorrecta.';
      } else if (e.code == 'invalid-email') {
        return 'El formato del correo electrónico es inválido.';
      }
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Obtiene los datos de un usuario desde la colección 'users' en Firestore.
  Future<AppUser?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener usuario de Firestore: $e');
      return null;
    }
  }
}
