// Esta clase proporciona acceso a las variables de entorno de forma segura.
// Las credenciales se inyectan durante el proceso de compilación (build)
// y no se almacenan en el código fuente.

class Environment {
  // Clave API de Firebase
  static const firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'No se encontró la clave API',
  );

  // ID de la App
  static const firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: 'No se encontró el ID de la app',
  );

  // ID del Sender de Mensajería
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: 'No se encontró el ID del sender',
  );

  // ID del Proyecto
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'No se encontró el ID del proyecto',
  );
  
  // Dominio de autenticación
   static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'No se encontró el dominio de auth',
  );

  // Bucket de almacenamiento
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'No se encontró el bucket',
  );
}
