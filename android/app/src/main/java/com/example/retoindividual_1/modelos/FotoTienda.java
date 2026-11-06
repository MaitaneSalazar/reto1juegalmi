package com.example.retoindividual_1.modelos;

import org.json.JSONObject;

//CADA FOTO DE LA GALERIA QUE DEVUELVE LA API EN /tienda/fotos
public class FotoTienda {

    private final String titulo;
    private final String url;

    public FotoTienda(JSONObject json) {
        this.titulo = json.optString("titulo");
        this.url = json.isNull("url") ? null : json.optString("url");
    }

    public String getTitulo() {
        return titulo;
    }

    public String getUrl() {
        return url;
    }
}
