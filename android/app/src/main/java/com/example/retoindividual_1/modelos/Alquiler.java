package com.example.retoindividual_1.modelos;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

//CADA ALQUILER QUE DEVUELVE LA API EN /alquileres, CON SUS JUEGOS DENTRO
public class Alquiler {

    private final int id;
    private final String fechaInicio;
    private final String fechaFinPrevista;
    private final String estado;
    private final int diasRestantes;
    private final List<Linea> lineas = new ArrayList<>();

    public Alquiler(JSONObject json) {
        this.id = json.optInt("id");
        this.fechaInicio = json.optString("fecha_inicio");
        this.fechaFinPrevista = json.optString("fecha_fin_prevista");
        this.estado = json.optString("estado");
        //POSITIVO SON LOS DIAS QUE QUEDAN, NEGATIVO LOS DIAS DE RETRASO
        this.diasRestantes = json.optInt("dias_restantes");
        JSONArray lista = json.optJSONArray("lineas");
        for (int i = 0; lista != null && i < lista.length(); i++) {
            lineas.add(new Linea(lista.optJSONObject(i)));
        }
    }

    public int getId() {
        return id;
    }

    public String getFechaInicio() {
        return fechaInicio;
    }

    public String getFechaFinPrevista() {
        return fechaFinPrevista;
    }

    public int getDiasRestantes() {
        return diasRestantes;
    }

    public List<Linea> getLineas() {
        return lineas;
    }

    public boolean estaDevuelto() {
        return estado.equals("devuelto");
    }

    public boolean estaRetrasado() {
        return estado.equals("retrasado");
    }

    //CADA JUEGO DEL ALQUILER
    public static class Linea {

        private final Producto videojuego;
        private final String fechaDevolucion;
        private final boolean devuelto;
        private final int dias;
        private final double importe;

        public Linea(JSONObject json) {
            JSONObject juego = json.optJSONObject("videojuego");
            this.videojuego = new Producto(juego != null ? juego : new JSONObject());
            this.fechaDevolucion = json.isNull("fecha_devolucion") ? null : json.optString("fecha_devolucion");
            this.devuelto = json.optBoolean("devuelto");
            this.dias = json.optInt("dias");
            this.importe = json.optDouble("importe");
        }

        public Producto getVideojuego() {
            return videojuego;
        }

        public String getFechaDevolucion() {
            return fechaDevolucion;
        }

        public boolean isDevuelto() {
            return devuelto;
        }

        public int getDias() {
            return dias;
        }

        public double getImporte() {
            return importe;
        }
    }
}
