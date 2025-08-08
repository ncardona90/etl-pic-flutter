/**
 * Script para asignar un rol de administrador a un usuario específico.
 * Se ejecuta localmente usando `ts-node` y una llave de servicio.
 */
import * as admin from "firebase-admin";

// Este script ahora toma el UID desde la línea de comandos para evitar errores.
// Ejemplo de uso: npx ts-node scripts/set-admin-claim.ts <UID_DEL_USUARIO>

async function setAdminRole() {
    const uid = process.argv[2]; // Captura el UID del argumento de la terminal
    const roleToSet = "admin";
    const appName = `set-admin-claim-${Date.now()}`; // Nombre único para cada ejecución

    if (!uid) {
        console.error("\x1b[31m%s\x1b[0m", "Error: Debes proporcionar el UID del usuario como argumento.");
        console.log("Ejemplo: npx ts-node scripts/set-admin-claim.ts yYb5ipyfWTdkBlTxjGxacINb4hl1");
        process.exit(1);
    }

    try {
        const serviceAccount = require("../service-account-key.json");
        console.log(`\nInicializando con el proyecto: ${serviceAccount.project_id}...`);

        const app = admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        }, appName); // Usamos un nombre único para garantizar una conexión limpia

        console.log(`Verificando si el usuario con UID: ${uid} existe...`);
        await app.auth().getUser(uid);
        console.log("Usuario encontrado. Asignando rol...");

        await app.auth().setCustomUserClaims(uid, { role: roleToSet });

        console.log("Actualizando rol en Firestore para consistencia...");
        await app.firestore().collection("users").doc(uid).update({ role: roleToSet });

        console.log(`\x1b[32m%s\x1b[0m`, `\n¡ÉXITO! Se asignó el custom claim '${roleToSet}' al usuario.`);
        console.log("El usuario ahora tiene todos los permisos de administrador.");

        await app.delete(); // Limpiamos la conexión de la app
        process.exit(0);

    } catch (error) {
        const errorMessage = (error instanceof Error) ? error.message : "Un error desconocido ocurrió.";
        console.error("\x1b[31m%s\x1b[0m", "\nError asignando el custom claim:", errorMessage);
        process.exit(1);
    }
}

setAdminRole();
