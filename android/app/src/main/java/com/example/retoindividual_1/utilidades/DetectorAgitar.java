package com.example.retoindividual_1.utilidades;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;

//AVISA CUANDO SE AGITA EL MOVIL (ACELEROMETRO). MISMOS VALORES QUE EN IONIC
public class DetectorAgitar implements SensorEventListener {

    public interface AlAgitar {
        void agitado();
    }

    private static final float UMBRAL = 15f;      //m/s² DE SACUDIDA, SIN CONTAR LA GRAVEDAD
    private static final long ESPERA_MS = 2500;   //UNA MISMA SACUDIDA NO RECARGA VARIAS VECES

    private final SensorManager sensores;
    private final Sensor acelerometro;
    private final AlAgitar alAgitar;
    private long ultimo = 0;

    public DetectorAgitar(Context context, AlAgitar alAgitar) {
        this.sensores = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);
        this.acelerometro = sensores == null ? null : sensores.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        this.alAgitar = alAgitar;
    }

    //EN onResume / onPause: EL SENSOR SOLO ESCUCHA MIENTRAS LA PANTALLA SE VE (AHORRA BATERIA)
    public void iniciar() {
        if (acelerometro != null) {
            sensores.registerListener(this, acelerometro, SensorManager.SENSOR_DELAY_UI);
        }
    }

    public void detener() {
        if (sensores != null) {
            sensores.unregisterListener(this);
        }
    }

    @Override
    public void onSensorChanged(SensorEvent evento) {
        float x = evento.values[0];
        float y = evento.values[1];
        float z = evento.values[2];
        float fuerza = Math.abs((float) Math.sqrt(x * x + y * y + z * z) - SensorManager.GRAVITY_EARTH);
        long ahora = System.currentTimeMillis();
        if (fuerza > UMBRAL && ahora - ultimo > ESPERA_MS) {
            ultimo = ahora;
            alAgitar.agitado();
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int precision) {
    }
}