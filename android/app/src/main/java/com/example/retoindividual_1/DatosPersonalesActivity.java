package com.example.retoindividual_1;

import android.content.Intent;
import android.os.Bundle;

// DATOS PERSONALES (se abre desde el menú lateral). De momento vacía.
public class DatosPersonalesActivity extends PaginaMenuActivity {

    @Override
    protected int getLayout() {
        return R.layout.activity_datos_personales;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Primero lo común (layout, márgenes y flecha). Si buscaras el botón antes, aún no existiría
        super.onCreate(savedInstanceState);

        findViewById(R.id.btnEditarDatos).setOnClickListener(v ->
                startActivity(new Intent(this, EditarDatosActivity.class)));
    }
}