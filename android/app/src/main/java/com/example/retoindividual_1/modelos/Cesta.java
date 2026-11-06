package com.example.retoindividual_1.modelos;

import java.util.ArrayList;
import java.util.List;

//LA CESTA SE GUARDA EN MEMORIA MIENTRAS LA APP ESTA ABIERTA
public class Cesta {

    private static final List<Linea> LINEAS = new ArrayList<>();

    //SI EL PRODUCTO YA ESTA LE SUMAMOS UNO, SI NO LO METEMOS
    //DEVUELVE false SI YA NO QUEDA STOCK PARA AÑADIR MAS
    public static boolean anadir(Producto producto) {
        for (Linea linea : LINEAS) {
            if (linea.getProducto().getId() == producto.getId()) {
                if (linea.getCantidad() >= producto.getStock()) {
                    return false;
                }
                linea.setCantidad(linea.getCantidad() + 1);
                return true;
            }
        }
        if (producto.getStock() <= 0) {
            return false;
        }
        LINEAS.add(new Linea(producto, 1));
        return true;
    }

    public static List<Linea> getLineas() {
        return LINEAS;
    }

    //CADA FILA DE LA CESTA: EL PRODUCTO Y CUANTOS LLEVAMOS
    public static class Linea {

        private final Producto producto;
        private int cantidad;

        public Linea(Producto producto, int cantidad) {
            this.producto = producto;
            this.cantidad = cantidad;
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
    }
}
