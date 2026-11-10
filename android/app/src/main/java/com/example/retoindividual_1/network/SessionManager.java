package com.example.retoindividual_1.network;

import android.content.Context;
import android.content.SharedPreferences;

import com.example.retoindividual_1.modelos.Cesta;

public class SessionManager {

    private static final String PREFS = "juegalmi_sesion";
    private static final String CLAVE_TOKEN = "token";
    private static final String CLAVE_DOMICILIO = "domicilio_elegido";
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

    //LA DIRECCION ELEGIDA PARA LOS PEDIDOS (-1 = NINGUNA)
    public void guardarDomicilio(int id) {
        prefs.edit().putInt(CLAVE_DOMICILIO, id).apply();
    }

    public int getDomicilio() {
        return prefs.getInt(CLAVE_DOMICILIO, -1);
    }

    // Borra el token (cerrar sesión)
    public void cerrarSesion() {
        prefs.edit().clear().apply();
        //LA CESTA ES DEL USUARIO QUE SALE, EL SIGUIENTE LA EMPIEZA VACIA
        Cesta.vaciar();
    }
}