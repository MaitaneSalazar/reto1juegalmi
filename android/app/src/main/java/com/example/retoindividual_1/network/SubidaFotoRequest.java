package com.example.retoindividual_1.network;

import com.android.volley.AuthFailureError;
import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.ParseError;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.toolbox.HttpHeaderParser;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

// Petición multipart/form-data para subir una foto. Volley no trae este tipo
public class SubidaFotoRequest extends Request<JSONObject> {

    private static final int TIEMPO_MAXIMO_MS = 30000;

    private final String campo;
    private final String limite = "----JuegAlmi" + System.currentTimeMillis();
    private final File foto;
    private final Map<String, String> cabeceras;
    private final Response.Listener<JSONObject> listener;

    // Fotos de reparaciones: POST y campo "imagen"
    public SubidaFotoRequest(String url, File foto, Map<String, String> cabeceras,
                             Response.Listener<JSONObject> listener, Response.ErrorListener errorListener) {
        this(Method.POST, url, "imagen", foto, cabeceras, listener, errorListener);
    }

    public SubidaFotoRequest(int metodo, String url, String campo, File foto, Map<String, String> cabeceras,
                             Response.Listener<JSONObject> listener, Response.ErrorListener errorListener) {
        super(metodo, url, errorListener);
        this.campo = campo;
        this.foto = foto;
        this.listener = listener;

        // Las cabeceras de ApiClient llevan "Content-Type: application/json". Aquí hay que quitarla:
        // si no, Volley la usaría en lugar de la de multipart y la API no encontraría la foto
        this.cabeceras = new HashMap<>(cabeceras);
        this.cabeceras.remove("Content-Type");

        // 30 segundos y SIN reintentos, para no subir la misma foto dos veces
        setRetryPolicy(new DefaultRetryPolicy(TIEMPO_MAXIMO_MS, 0, DefaultRetryPolicy.DEFAULT_BACKOFF_MULT));
    }

    @Override
    public Map<String, String> getHeaders() {
        return cabeceras;
    }

    @Override
    public String getBodyContentType() {
        return "multipart/form-data; boundary=" + limite;
    }

    @Override
    public byte[] getBody() throws AuthFailureError {
        try {
            ByteArrayOutputStream cuerpo = new ByteArrayOutputStream();
            String inicio = "--" + limite + "\r\n"
                    + "Content-Disposition: form-data; name=\"" + campo + "\"; filename=\"" + foto.getName() + "\"\r\n"
                    + "Content-Type: image/jpeg\r\n\r\n";
            cuerpo.write(inicio.getBytes(StandardCharsets.UTF_8));
            cuerpo.write(leerArchivo(foto));
            cuerpo.write(("\r\n--" + limite + "--\r\n").getBytes(StandardCharsets.UTF_8));
            return cuerpo.toByteArray();
        } catch (IOException e) {
            throw new AuthFailureError("No se ha podido leer la foto", e);
        }
    }

    @Override
    protected Response<JSONObject> parseNetworkResponse(NetworkResponse response) {
        try {
            String json = new String(response.data, HttpHeaderParser.parseCharset(response.headers, "utf-8"));
            return Response.success(new JSONObject(json), HttpHeaderParser.parseCacheHeaders(response));
        } catch (UnsupportedEncodingException | JSONException e) {
            return Response.error(new ParseError(e));
        }
    }

    @Override
    protected void deliverResponse(JSONObject response) {
        listener.onResponse(response);
    }

    private static byte[] leerArchivo(File archivo) throws IOException {
        try (InputStream entrada = new FileInputStream(archivo);
             ByteArrayOutputStream salida = new ByteArrayOutputStream()) {
            byte[] trozo = new byte[8192];
            int leidos;
            while ((leidos = entrada.read(trozo)) != -1) {
                salida.write(trozo, 0, leidos);
            }
            return salida.toByteArray();
        }
    }
}