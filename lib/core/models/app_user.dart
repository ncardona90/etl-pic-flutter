// lib/core/models/app_user.dart

class AppUser {
  // --- CONSTRUCTOR ---
  AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.role = 'operario', // Rol por defecto
    this.userName = '', // Se asigna un valor por defecto
  });

  // --- FACTORY CONSTRUCTOR ---
  // Crea una instancia de AppUser desde un mapa (ej. datos de Firestore).
  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'operario',
      userName: data['userName'] ?? '', // Se lee el campo userName
    );
  }
  // --- CAMPOS DE LA CLASE ---
  // Se declaran una sola vez.
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String userName;

  // --- MÉTODO toMap ---
  // Convierte la instancia de AppUser a un mapa para guardarlo en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'userName': userName, // Se añade el campo userName al mapa
    };
  }
}
