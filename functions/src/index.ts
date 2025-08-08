import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

interface CreateUserData {
    email: string;
    password: string;
    displayName: string;
    role: string;
    userName: string;
}

export const createUser = functions.region("us-central1") // Define la región
    .https.onCall(async (data: CreateUserData, context) => {
        // 1. Validar permisos
        if (context.auth?.token?.role !== "admin") {
            functions.logger.warn("Intento de creación no autorizado",
                { uid: context.auth?.uid });
            throw new functions.https.HttpsError(
                "permission-denied",
                "Solo los administradores pueden crear usuarios."
            );
        }

        // 2. Validar que todos los datos llegaron
        const { email, password, displayName, role, userName } = data;
        if (!email || !password || !displayName || !role || !userName) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "Faltan datos requeridos (email, password, displayName, role, userName)."
            );
        }

        try {
            // 3. Crear usuario en Auth
            const userRecord = await admin.auth().createUser({
                email,
                password,
                displayName,
            });
            functions.logger.info(`Usuario de Auth creado: ${userRecord.uid}`);

            // 4. Asignar rol (Claims)
            await admin.auth().setCustomUserClaims(userRecord.uid, { role });
            functions.logger.info(`Rol '${role}' asignado a ${userRecord.uid}`);

            // 5. Crear documento en Firestore
            await admin.firestore().collection("users").doc(userRecord.uid).set({
                email,
                displayName,
                role,
                userName, // Ahora es seguro que este campo existe
                uid: userRecord.uid, // Guardar el UID es una buena práctica
            });
            functions.logger.info(`Documento en Firestore creado para ${userRecord.uid}`);

            return { success: true, uid: userRecord.uid };
        } catch (error: any) {
            functions.logger.error("Fallo en la creación de usuario:", error);
            if (error.code === "auth/email-already-exists") {
                throw new functions.https.HttpsError(
                    "already-exists",
                    "El correo electrónico ya está en uso."
                );
            }
            throw new functions.https.HttpsError(
                "internal",
                "Ocurrió un error en el servidor al crear el usuario.",
                error.message
            );
        }
    });



export const deleteUser = functions.https.onCall(async (data: { uid: string }, context) => {
    if (context.auth?.token?.role !== "admin") {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Solo los administradores pueden eliminar usuarios."
        );
    }

    try {
        await admin.auth().deleteUser(data.uid);
        await admin.firestore().collection("users").doc(data.uid).delete();
        return { success: true };
    } catch (error: unknown) {
        throw new functions.https.HttpsError(
            "internal",
            "Ocurrió un error al eliminar el usuario.",
            error
        );
    }
});


export const setUserRole = functions.https.onCall(async (data: { uid: string; role: string }, context) => {
    // *** CORRECCIÓN: UID DEL ADMINISTRADOR ACTUALIZADO ***
    const isOwner = context.auth?.uid === "FIz4huk76wQXZjJaTbi8CWVGqJ63";
    const isAdmin = context.auth?.token?.role === "admin";

    if (!isAdmin && !isOwner) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Solo los administradores pueden cambiar roles."
        );
    }

    try {
        await admin.auth().setCustomUserClaims(data.uid, { role: data.role });
        await admin.firestore().collection("users").doc(data.uid).update({ role: data.role });

        return { success: true, message: `Rol "${data.role}" asignado al usuario ${data.uid}` };
    } catch (error: unknown) {
        throw new functions.https.HttpsError(
            "internal",
            "Ocurrió un error al asignar el rol.",
            error
        );
    }
});

// --- NUEVA FUNCIÓN PARA ACTUALIZACIONES MASIVAS ---
export const batchUpdateField = functions.https.onCall(async (data, context) => {
    if (context.auth?.token?.role !== "admin") {
        throw new functions.https.HttpsError("permission-denied", "Solo los administradores pueden realizar esta operación.");
    }

    const { collection, docIds, fieldName, findValue, replaceValue } = data;
    if (!collection || !docIds || !fieldName || findValue == null || replaceValue == null) {
        throw new functions.https.HttpsError("invalid-argument", "Faltan argumentos para la actualización masiva.");
    }

    const db = admin.firestore();
    const batch = db.batch();
    let count = 0;

    for (const docId of docIds) {
        const docRef = db.collection(collection).doc(docId);
        // Aquí se puede añadir lógica para buscar solo donde el campo coincida,
        // pero por simplicidad, actualizamos todos los documentos seleccionados.
        // if(doc.data()[fieldName] === findValue) { ... }
        batch.update(docRef, { [fieldName]: replaceValue });
        count++;
    }

    try {
        await batch.commit();
        return { success: true, message: `${count} registros actualizados correctamente.` };
    } catch (error) {
        throw new functions.https.HttpsError("internal", "Error al ejecutar la actualización masiva.", error);
    }
});
