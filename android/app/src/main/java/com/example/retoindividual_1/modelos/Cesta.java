package com.example.retoindividual_1.modelos;

import android.content.Context;
import android.content.SharedPreferences;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

//LA CESTA SE GUARDA EN EL MOVIL CADA VEZ QUE CAMBIA. SOLO LLEVA COMPRAS: LOS ALQUILERES SE HACEN DESDE LA FICHA
public class Cesta {

    private static final List<Linea> LINEAS = new ArrayList<>();
    private static SharedPreferences prefs;
    private static Runnable alCambiar;

    //SE LLAMA AL ARRANCAR: CARGA LA CESTA GUARDADA. LAS SIGUIENTES VECES NO HACE NADA
    public static void iniciar(Context context) {
        if (prefs != null) {
            return;
        }
        prefs = context.getApplicationContext().getSharedPreferences("juegalmi_cesta", Context.MODE_PRIVATE);
        try {
            JSONArray guardadas = new JSONArray(prefs.getString("lineas", "[]"));
            for (int i = 0; i < guardadas.length(); i++) {
                JSONObject linea = guardadas.getJSONObject(i);
                LINEAS.add(new Linea(new Producto(linea.getJSONObject("producto")), linea.getInt("cantidad"), false, 0));
            }
        } catch (JSONException e) {
            LINEAS.clear(); //SI LO GUARDADO ESTA ROTO, SE EMPIEZA CON LA CESTA VACIA
        }
    }

    private static void guardar() {
        if (prefs == null) {
            return;
        }
        JSONArray lineas = new JSONArray();
        try {
            for (Linea linea : LINEAS) {
                lineas.put(new JSONObject()
                        .put("producto", new JSONObject(linea.getProducto().getJson()))
                        .put("cantidad", linea.getCantidad()));
            }
        } catch (JSONException e) {
            return;
        }
        prefs.edit().putString("lineas", lineas.toString()).apply();
    }

    //LA PANTALLA PRINCIPAL SE APUNTA PARA REPINTAR EL NUMERO DE LA BARRA (null PARA DESAPUNTARSE)
    public static void setAlCambiar(Runnable aviso) {
        alCambiar = aviso;
    }

    //CUANTAS UNIDADES HAY EN TOTAL (EL NUMERO DE LA BARRA)
    public static int getUnidades() {
        int total = 0;
        for (Linea linea : LINEAS) {
            total += linea.getCantidad();
        }
        return total;
    }

    //CADA VEZ QUE LA CESTA CAMBIA: SE GUARDA Y SE AVISA A LA BARRA
    private static void cambio() {
        guardar();
        if (alCambiar != null) {
            alCambiar.run();
        }
    }

    //SI YA HAY UNA LINEA IGUAL (MISMO PRODUCTO, MISMO MODO Y MISMOS DIAS) LE SUMAMOS, SI NO LA CREAMOS
    //DEVUELVE false SI NO QUEDAN UNIDADES (O COPIAS) PARA TANTAS, Y ENTONCES NO AÑADE NADA
    public static boolean anadir(Producto producto, int cantidad, boolean alquiler, int dias) {
        if (enCesta(producto, alquiler) + cantidad > Linea.limite(producto, alquiler)) {
            return false;
        }
        for (Linea linea : LINEAS) {
            if (linea.getProducto().getId() == producto.getId() && linea.isAlquiler() == alquiler && linea.getDias() == dias) {
                linea.setCantidad(linea.getCantidad() + cantidad);
                cambio();
                return true;
            }
        }
        LINEAS.add(new Linea(producto, cantidad, alquiler, dias));
        cambio();
        return true;
    }

    //UNA MAS DE UNA LINEA QUE YA ESTA EN LA CESTA
    public static boolean sumar(Linea linea) {
        return anadir(linea.getProducto(), 1, linea.isAlquiler(), linea.getDias());
    }

    //LE QUITAMOS UNO, Y SI SE QUEDA EN 0 SALE DE LA CESTA
    public static void restar(Linea linea) {
        if (linea.getCantidad() <= 1) {
            LINEAS.remove(linea);
        } else {
            linea.setCantidad(linea.getCantidad() - 1);
        }
        cambio();
    }

    //CUANTAS UNIDADES DE ESE PRODUCTO HAY YA EN LA CESTA, CONTANDO TODAS SUS LINEAS DE ESE MODO
    public static int enCesta(Producto producto, boolean alquiler) {
        int total = 0;
        for (Linea linea : LINEAS) {
            if (linea.getProducto().getId() == producto.getId() && linea.isAlquiler() == alquiler) {
                total += linea.getCantidad();
            }
        }
        return total;
    }

    public static double getTotal() {
        double total = 0;
        for (Linea linea : LINEAS) {
            total += linea.getSubtotal();
        }
        return total;
    }

    public static void vaciar() {
        LINEAS.clear();
        cambio();
    }

    public static List<Linea> getLineas() {
        return LINEAS;
    }

    //CADA FILA DE LA CESTA: EL PRODUCTO, CUANTOS, Y SI ES ALQUILER POR CUANTOS DIAS
    public static class Linea {

        private final Producto producto;
        private int cantidad;
        private final boolean alquiler;
        private final int dias;

        public Linea(Producto producto, int cantidad, boolean alquiler, int dias) {
            this.producto = producto;
            this.cantidad = cantidad;
            this.alquiler = alquiler;
            this.dias = alquiler ? dias : 0;
        }

        //COMPRANDO MANDA EL STOCK, ALQUILANDO LAS COPIAS LIBRES
        public static int limite(Producto producto, boolean alquiler) {
            return alquiler ? producto.getCopiasDisponibles() : producto.getStock();
        }

        public Producto getProducto() {
            return producto;
        }

        public int getCantidad() {
            return cantidad;
        }

        public void setCantidad(int cantidad) {
            this.cantidad = cantidad;
        }

        public boolean isAlquiler() {
            return alquiler;
        }

        public int getDias() {
            return dias;
        }

        //PRECIO DE UNA UNIDAD: EL DE VENTA, O EL DEL DIA POR LOS DIAS
        public double getPrecio() {
            return alquiler ? producto.getPrecioAlquilerDia() * dias : producto.getPrecioVenta();
        }

        public double getSubtotal() {
            return getPrecio() * cantidad;
        }
    }
}
