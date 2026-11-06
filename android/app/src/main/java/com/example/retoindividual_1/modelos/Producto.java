package com.example.retoindividual_1.modelos;

import org.json.JSONObject;

//CADA PRODUCTO QUE DEVUELVE LA API EN /productos Y EN /videojuegos/alquiler
public class Producto {

    private final int id;
    private final String tipo;
    private final String nombre;
    private final String empresa;
    private final String plataforma;
    private final String miniaturaUrl;
    private final String imagenUrl;
    private final String descripcion;
    private final String genero;
    private final int pegi;
    private final double precioVenta;
    private final double precioAlquilerDia;
    private final int stock;
    private final int copiasDisponibles;
    private final boolean disponible;

    //ABRIMOS EL JSON Y SACAMOS CADA DATO
    public Producto(JSONObject json) {
        this.id = json.optInt("id");
        this.tipo = json.optString("tipo");
        this.nombre = json.optString("nombre");
        this.empresa = json.optString("empresa");
        this.plataforma = json.optString("plataforma");
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

    public String getEmpresa() {
        return empresa;
    }

    public String getPlataforma() {
        return plataforma;
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

    public boolean isDisponible() {
        return disponible;
    }

    public boolean esVideojuego() {
        return tipo.equals("videojuego");
    }
}
