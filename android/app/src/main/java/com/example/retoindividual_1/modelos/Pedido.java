package com.example.retoindividual_1.modelos;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

//CADA PEDIDO DEL LISTADO DE /pedidos. LAS FOTOS DE TODOS SUS PRODUCTOS SALEN DEL DETALLE /pedidos/{id}
public class Pedido {

    private final int id;
    private final String fecha;
    private final String estado;
    private final double total;
    private final int unidades;
    private final String primerProducto;
    private final String imagenUrl;
    private final boolean sePuedeCancelar;
    private final List<Miniatura> miniaturas = new ArrayList<>();

    public Pedido(JSONObject json) {
        this.id = json.optInt("id");
        this.fecha = json.optString("fecha");
        this.estado = json.optString("estado");
        this.total = json.optDouble("total");
        this.unidades = json.optInt("unidades");
        this.primerProducto = json.optString("primer_producto");
        this.imagenUrl = json.isNull("imagen_url") ? null : json.optString("imagen_url");
        this.sePuedeCancelar = json.optBoolean("se_puede_cancelar");
        //MIENTRAS NO LLEGA EL DETALLE ENSEÑAMOS LA DEL PRIMER PRODUCTO
        miniaturas.add(new Miniatura(imagenUrl, 1));
    }

    //CON EL DETALLE CAMBIAMOS LA FOTO DEL PRIMERO POR LAS DE TODOS LOS PRODUCTOS DEL PEDIDO, CON SU CANTIDAD
    public void leerFotos(JSONObject detalle) {
        JSONArray lineas = detalle.optJSONArray("lineas");
        if (lineas == null || lineas.length() == 0) {
            return;
        }
        miniaturas.clear();
        for (int i = 0; i < lineas.length(); i++) {
            JSONObject linea = lineas.optJSONObject(i);
            JSONObject producto = linea.optJSONObject("producto");
            String url = null;
            if (producto != null && !producto.isNull("miniatura_url")) {
                url = producto.optString("miniatura_url");
            } else if (producto != null && !producto.isNull("imagen_url")) {
                url = producto.optString("imagen_url");
            }
            miniaturas.add(new Miniatura(url, linea.optInt("cantidad", 1)));
        }
    }

    public List<Miniatura> getMiniaturas() {
        return miniaturas;
    }

    public int getId() {
        return id;
    }

    public String getFecha() {
        return fecha;
    }

    public String getEstado() {
        return estado;
    }

    public double getTotal() {
        return total;
    }

    public int getUnidades() {
        return unidades;
    }

    public String getPrimerProducto() {
        return primerProducto;
    }

    public String getImagenUrl() {
        return imagenUrl;
    }

    public boolean isSePuedeCancelar() {
        return sePuedeCancelar;
    }

    //LA FOTO DE UN PRODUCTO DEL PEDIDO Y CUANTOS SE HAN COGIDO
    public static class Miniatura {

        private final String url;
        private final int cantidad;

        public Miniatura(String url, int cantidad) {
            this.url = url;
            this.cantidad = cantidad;
        }

        public String getUrl() {
            return url;
        }

        public int getCantidad() {
            return cantidad;
        }
    }
}
