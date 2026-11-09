package com.example.retoindividual_1.network;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.Priority;

import java.util.Locale;
import java.util.Map;

// Guarda la última posición del móvil para enviarla en cada llamada a la API (cabeceras X-Lat y X-Lon)
public class Localizador {

    // Precisión "equilibrada" y cada 2 minutos: basta para el reto y gasta poca batería
    private static final long INTERVALO_MS = 2 * 60 * 1000;
    private static final float DISTANCIA_MINIMA_M = 50;

    private static Localizador instancia;

    private final Context contexto;
    private final FusedLocationProviderClient cliente;
    private boolean activo = false;

    // volatile: se escriben en el hilo principal y se leen en los hilos de red de Volley
    private volatile Double latitud;
    private volatile Double longitud;

    private final LocationCallback alCambiar = new LocationCallback() {
        @Override
        public void onLocationResult(@NonNull LocationResult resultado) {
            guardar(resultado.getLastLocation());
        }
    };

    private Localizador(Context context) {
        contexto = context.getApplicationContext();
        cliente = LocationServices.getFusedLocationProviderClient(contexto);
    }

    public static synchronized Localizador getInstance(Context context) {
        if (instancia == null) {
            instancia = new Localizador(context);
        }
        return instancia;
    }

    public static boolean tienePermiso(Context context) {
        return ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                || ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    // El permiso se comprueba justo antes; sin él no se hace nada y la app sigue funcionando
    @SuppressLint("MissingPermission")
    public void iniciar() {
        if (activo || !tienePermiso(contexto)) {
            return;
        }
        activo = true;
        cliente.getLastLocation().addOnSuccessListener(this::guardar);
        LocationRequest peticion = new LocationRequest.Builder(Priority.PRIORITY_BALANCED_POWER_ACCURACY, INTERVALO_MS)
                .setMinUpdateDistanceMeters(DISTANCIA_MINIMA_M)
                .build();
        cliente.requestLocationUpdates(peticion, alCambiar, Looper.getMainLooper());
    }

    public void detener() {
        if (!activo) {
            return;
        }
        activo = false;
        cliente.removeLocationUpdates(alCambiar);
    }

    private void guardar(Location posicion) {
        if (posicion != null) {
            latitud = posicion.getLatitude();
            longitud = posicion.getLongitude();
        }
    }

    // Locale.US para que el decimal sea un punto (43.2614), como pide la API, aunque el móvil esté en español
    public void anadirCabeceras(Map<String, String> cabeceras) {
        Double lat = latitud;
        Double lon = longitud;
        if (lat != null && lon != null) {
            cabeceras.put("X-Lat", String.format(Locale.US, "%.6f", lat));
            cabeceras.put("X-Lon", String.format(Locale.US, "%.6f", lon));
        }
    }
}