package com.example.retoindividual_1.network;

import android.content.Context;

import com.android.volley.RequestQueue;
import com.android.volley.toolbox.Volley;
import com.example.retoindividual_1.BuildConfig;

import java.util.HashMap;
import java.util.Map;

import com.android.volley.VolleyError;
import org.json.JSONException;
import org.json.JSONObject;
import java.nio.charset.StandardCharsets;

public class ApiClient {

    // La URL sale de build.gradle.kts (debug → VM de Ubuntu, release → AWS)
    public static final String BASE_URL = BuildConfig.API_URL;

    // Única instancia para toda la app (patrón singleton)
    private static ApiClient instancia;

    // Cola donde Volley guarda y ejecuta las peticiones
    private final RequestQueue cola;
    private final SessionManager sesion;

    // Constructor privado: nadie puede hacer "new ApiClient()" desde fuera
    private ApiClient(Context context) {
        cola = Volley.newRequestQueue(context.getApplicationContext());
        sesion = new SessionManager(context.getApplicationContext());
    }

    // La forma de obtener el ApiClient desde cualquier pantalla
    public static synchronized ApiClient getInstance(Context context) {
        if (instancia == null) {
            instancia = new ApiClient(context);
        }
        return instancia;
    }

    public RequestQueue getCola() {
        return cola;
    }

    // Cabeceras de cada petición: JSON y, si hay sesión, el token
    public Map<String, String> getCabeceras() {
        Map<String, String> cabeceras = new HashMap<>();
        cabeceras.put("Content-Type", "application/json");
        String token = sesion.getToken();
        if (token != null) {
            cabeceras.put("Authorization", "Bearer " + token);
        }
        return cabeceras;
    }

    // Extrae el campo "mensaje" de los errores de la API
    public static String mensajeDeError(VolleyError error) {
        if (error.networkResponse != null && error.networkResponse.data != null) {
            try {
                String cuerpo = new String(error.networkResponse.data, StandardCharsets.UTF_8);
                JSONObject json = new JSONObject(cuerpo);
                return json.optString("mensaje", "Error " + error.networkResponse.statusCode);
            } catch (JSONException e) {
                return "Error " + error.networkResponse.statusCode;
            }
        }
        // No hubo respuesta: el servidor no está encendido o no es accesible
        return "No se puede conectar con el servidor";
    }
}