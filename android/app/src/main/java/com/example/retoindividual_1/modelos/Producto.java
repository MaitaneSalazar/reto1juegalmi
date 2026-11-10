package com.example.retoindividual_1.modelos;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

//CADA PRODUCTO QUE DEVUELVE LA API EN /productos Y EN /videojuegos/alquiler
public class Producto {

    private final int id;
    private final String tipo;
    private final String nombre;
    private final String empresa;
    private final List<String> plataformas = new ArrayList<>();
    private final String miniaturaUrl;
    private final String imagenUrl;
    private final String descripcion;
    private final String genero;
    private final int pegi;
    private final double precioVenta;
    private final double precioAlquilerDia;
    private final int stock;
    private final int copiasDisponibles;
    private final int copiasAlquiler;
    private final boolean disponible;
    //EL JSON CON EL QUE SE CREO, PARA PODER GUARDARLO EN LA CESTA
    private final String json;

    //ABRIMOS EL JSON Y SACAMOS CADA DATO
    public Producto(JSONObject json) {
        this.json = json.toString();
        this.id = json.optInt("id");
        this.tipo = json.optString("tipo");
        this.nombre = json.optString("nombre");
        this.empresa = json.optString("empresa");
        //SI LA API YA MANDA LA LISTA LA USAMOS, SI NO SALE DE "plataforma" Y LOS "Multi" SON DE TODAS
        JSONArray lista = json.optJSONArray("plataformas");
        if (lista != null) {
            for (int i = 0; i < lista.length(); i++) {
                plataformas.add(lista.optString(i));
            }
        } else if (json.optString("plataforma").equals("Multi")) {
            plataformas.addAll(Arrays.asList(Plataforma.TODAS));
        } else if (!json.optString("plataforma").isEmpty()) {
            plataformas.add(json.optString("plataforma"));
        }
        //SI NO TIENE FOTO LA API MANDA null
        this.miniaturaUrl = json.isNull("miniatura_url") ? null : json.optString("miniatura_url");
        this.imagenUrl = json.isNull("imagen_url") ? null : json.optString("imagen_url", null);
        //ESTOS SOLO VIENEN CUANDO PEDIMOS UN PRODUCTO SUELTO
        this.descripcion = json.optString("descripcion");
        this.genero = json.optString("genero");
        this.pegi = json.optInt("pegi");
        this.precioVenta = json.optDouble("precio_venta");
        this.precioAlquilerDia = json.optDouble("precio_alquiler_dia");
        this.stock = json.optInt("stock");
        this.copiasDisponibles = json.optInt("copias_disponibles");
        //0 = ESE JUEGO NO SE ALQUILA
        this.copiasAlquiler = json.optInt("copias_alquiler");
        this.disponible = json.optBoolean("disponible", true);
    }

    public int getId() {
        return id;
    }

    public String getTipo() {
        return tipo;
    }

    public String getNombre() {
        return nombre;
    }

    public String getJson() {
        return json;
    }

    //"Minecraft · Xbox": CON VARIOS JUEGOS IGUALES, LA PLATAFORMA LOS DISTINGUE (LO PIDE LA GUIA DE LA API)
    public String getNombreConPlataforma() {
        if ("videojuego".equals(tipo) && plataformas.size() == 1) {
            return nombre + " · " + Plataforma.nombre(plataformas.get(0));
        }
        return nombre;
    }

    public String getEmpresa() {
        return empresa;
    }

    public List<String> getPlataformas() {
        return plataformas;
    }

    public String getMiniaturaUrl() {
        return miniaturaUrl;
    }

    public String getImagenUrl() {
        return imagenUrl;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public String getGenero() {
        return genero;
    }

    public int getPegi() {
        return pegi;
    }

    public double getPrecioVenta() {
        return precioVenta;
    }

    public double getPrecioAlquilerDia() {
        return precioAlquilerDia;
    }

    public int getStock() {
        return stock;
    }

    public int getCopiasDisponibles() {
        return copiasDisponibles;
    }

    public int getCopiasAlquiler() {
        return copiasAlquiler;
    }

    public boolean isDisponible() {
        return disponible;
    }

    public boolean esVideojuego() {
        return tipo.equals("videojuego");
    }
}
