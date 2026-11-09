package com.example.retoindividual_1.modelos;

import java.util.ArrayList;
import java.util.List;

//LA CESTA SE GUARDA EN MEMORIA MIENTRAS LA APP ESTA ABIERTA. LLEVA COMPRAS Y ALQUILERES
public class Cesta {

    private static final List<Linea> LINEAS = new ArrayList<>();

    //SI YA HAY UNA LINEA IGUAL (MISMO PRODUCTO, MISMO MODO Y MISMOS DIAS) LE SUMAMOS, SI NO LA CREAMOS
    //DEVUELVE false SI NO QUEDAN UNIDADES (O COPIAS) PARA TANTAS, Y ENTONCES NO AÑADE NADA
    public static boolean anadir(Producto producto, int cantidad, boolean alquiler, int dias) {
        if (enCesta(producto, alquiler) + cantidad > Linea.limite(producto, alquiler)) {
            return false;
        }
        for (Linea linea : LINEAS) {
            if (linea.getProducto().getId() == producto.getId() && linea.isAlquiler() == alquiler && linea.getDias() == dias) {
                linea.setCantidad(linea.getCantidad() + cantidad);
                return true;
            }
        }
        LINEAS.add(new Linea(producto, cantidad, alquiler, dias));
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
