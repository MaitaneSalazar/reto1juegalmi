package com.example.retoindividual_1.network;

import android.content.Context;
import android.content.SharedPreferences;

public class SessionManager {

    private static final String PREFS = "juegalmi_sesion";
    private static final String CLAVE_TOKEN = "token";
    private final SharedPreferences prefs;

    public SessionManager(Context context) {
        prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    // Guarda el token que devuelve la API al hacer login
    public void guardarToken(String token) {
        prefs.edit().putString(CLAVE_TOKEN, token).apply();
    }

    // Devuelve el token, o null si no hay sesión iniciada
    public String getToken() {
        return prefs.getString(CLAVE_TOKEN, null);
    }

    public boolean haySesion() {
        return getToken() != null;
    }

    // Borra el token (cerrar sesión)
    public void cerrarSesion() {
        prefs.edit().clear().apply();
    }
}