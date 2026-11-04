package com.example.retoindividual_1;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;

/*
 * =====================================================================================
 *  FICHA DE PRODUCTO (06 del mockup). Una sola página para TODOS los productos.
 *  Los videojuegos tienen además la parte de alquiler; móviles, tablets y consolas no.
 *
 *  Se abre siempre con crearIntent(...), que le pasa:
 *   - el id del producto (para pedirlo a la API)
 *   - si se puede alquilar (para enseñar o no la parte de alquiler)
 * =====================================================================================
 */
public class FichaProductoActivity extends PaginaMenuActivity {

    // Nombres de los datos que recibe la página
    public static final String EXTRA_ID_PRODUCTO = "id_producto";
    public static final String EXTRA_SE_ALQUILA = "se_alquila";

    // Forma de abrir la ficha desde cualquier sitio.
    // Así nadie tiene que acordarse de los nombres de los extras ni equivocarse al escribirlos
    public static Intent crearIntent(Context context, int idProducto, boolean seAlquila) {
        Intent intent = new Intent(context, FichaProductoActivity.class);
        intent.putExtra(EXTRA_ID_PRODUCTO, idProducto);
        intent.putExtra(EXTRA_SE_ALQUILA, seAlquila);
        return intent;
    }

    @Override
    protected int getLayout() {
        return R.layout.activity_ficha_producto;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Primero lo común (layout, márgenes y flecha), que lo hace PaginaMenuActivity
        super.onCreate(savedInstanceState);

        // Datos que llegan de la pantalla anterior.
        // El id se usará para pedir el producto a la API (GET /api/productos/{id})
        int idProducto = getIntent().getIntExtra(EXTRA_ID_PRODUCTO, -1);
        boolean seAlquila = getIntent().getBooleanExtra(EXTRA_SE_ALQUILA, false);

        // La parte de alquiler solo se enseña en los videojuegos
        findViewById(R.id.llFichaAlquiler).setVisibility(seAlquila ? View.VISIBLE : View.GONE);
    }
}