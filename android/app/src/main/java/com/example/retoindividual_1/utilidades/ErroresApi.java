package com.example.retoindividual_1.utilidades;

import android.widget.EditText;

import org.json.JSONObject;

import java.util.Iterator;
import java.util.Map;

public final class ErroresApi {

    private ErroresApi() {
    }

    // Error 422: marca en rojo cada campo que venga en "campos" (clave de la API -> su EditText).
    // Devuelve el primer campo marcado, o null si no hay ninguno
    public static EditText marcarCampos(JSONObject errores, Map<String, EditText> campos) {
        EditText primero = null;
        Iterator<String> claves = errores.keys();
        while (claves.hasNext()) {
            String clave = claves.next();
            EditText campo = campos.get(clave);
            if (campo != null) {
                campo.setError(errores.optString(clave));
                if (primero == null) {
                    primero = campo;
                }
            }
        }
        return primero;
    }
}
