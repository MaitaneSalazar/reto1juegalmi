package com.example.retoindividual_1.utilidades;

import android.widget.EditText;

import com.android.volley.VolleyError;

import org.json.JSONException;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.Map;

public final class ErroresApi {

    private ErroresApi() {
    }

    // Error 422: marca en rojo cada campo que venga en "campos" (clave de la API -> su EditText).
    // Devuelve el primer campo marcado, o null si no hay ninguno
    public static EditText marcarCampos(VolleyError error, Map<String, EditText> campos) {
        if (error.networkResponse == null || error.networkResponse.data == null) {
            return null;
        }
        try {
            JSONObject cuerpo = new JSONObject(new String(error.networkResponse.data, StandardCharsets.UTF_8));
            JSONObject errores = cuerpo.optJSONObject("campos");
            if (errores == null) {
                return null;
            }
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
        } catch (JSONException e) {
            return null;
        }
    }
}