package com.example.retoindividual_1.modelos;

import org.json.JSONObject;

// Cada domicilio de GET /api/domicilios
public class Domicilio {

    private final int id;
    private final String calle;
    private final String numero;
    private final String piso;
    private final String codigoPostal;
    private final String ciudad;
    private final String provincia;
    private final String json;

    public Domicilio(JSONObject datos) {
        id = datos.optInt("id");
        JSONObject direccion = datos.optJSONObject("direccion");
        if (direccion == null) {
            direccion = new JSONObject();
        }
        calle = direccion.optString("calle");
        numero = direccion.optString("numero");
        piso = direccion.isNull("piso") ? "" : direccion.optString("piso");
        codigoPostal = direccion.optString("codigo_postal");
        ciudad = direccion.optString("ciudad");
        provincia = direccion.optString("provincia");
        json = datos.toString();
    }

    // "Gran Vía 12, 3ºB"
    public String getLinea1() {
        String linea = (calle + " " + numero).trim();
        return piso.isEmpty() ? linea : linea + ", " + piso;
    }

    public int getId() {
        return id;
    }

    public String getCodigoPostal() {
        return codigoPostal;
    }

    public String getCiudad() {
        return ciudad;
    }

    public String getProvincia() {
        return provincia;
    }

    // El domicilio tal como llegó de la API, para pasárselo a la pantalla de editar
    public String getJson() {
        return json;
    }
}