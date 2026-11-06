package com.example.retoindividual_1.modelos;

import org.json.JSONObject;

// Cada reparación del listado GET /api/reparaciones
public class Reparacion {

    private final int id;
    private final String tipoDispositivo;
    private final String marca;
    private final String modelo;
    private final String estado;
    private final String estadoTexto;
    private final int paso;
    private final int totalPasos;
    private final String fecha;
    private final Double presupuesto;
    private final boolean traePresupuesto;
    private final String fechaEntrega;

    public Reparacion(JSONObject json) {
        id = json.optInt("id");
        tipoDispositivo = json.optString("tipo_dispositivo");
        marca = json.optString("marca");
        modelo = json.optString("modelo");
        estado = json.optString("estado");
        estadoTexto = json.optString("estado_texto");
        paso = json.optInt("paso");
        totalPasos = json.optInt("total_pasos", 5);
        fecha = json.optString("fecha");
        // El listado puede no traer el presupuesto (campo ausente) o traerlo a null (aún sin presupuesto)
        traePresupuesto = json.has("presupuesto");
        presupuesto = json.isNull("presupuesto") ? null : json.optDouble("presupuesto");
        fechaEntrega = json.isNull("fecha_entrega") ? null : json.optString("fecha_entrega");
    }

    public boolean estaEntregada() {
        return "entregada".equals(estado);
    }

    public boolean estaCancelada() {
        return "cancelada".equals(estado);
    }

    public boolean estaEnCurso() {
        return !estaEntregada() && !estaCancelada();
    }

    public int getId() {
        return id;
    }

    public String getTipoDispositivo() {
        return tipoDispositivo;
    }

    public String getMarca() {
        return marca;
    }

    public String getModelo() {
        return modelo;
    }

    public String getEstadoTexto() {
        return estadoTexto;
    }

    public int getPaso() {
        return paso;
    }

    public int getTotalPasos() {
        return totalPasos;
    }

    public String getFecha() {
        return fecha;
    }

    public Double getPresupuesto() {
        return presupuesto;
    }

    public boolean traePresupuesto() {
        return traePresupuesto;
    }

    public String getFechaEntrega() {
        return fechaEntrega;
    }
}