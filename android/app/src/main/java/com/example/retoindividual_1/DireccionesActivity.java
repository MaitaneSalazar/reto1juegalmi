package com.example.retoindividual_1;

import android.content.Intent;
import android.os.Bundle;

// DIRECCIONES (se abre desde el menú lateral). De momento vacía.
public class DireccionesActivity extends PaginaMenuActivity {

    @Override
    protected int getLayout() {
        return R.layout.activity_direcciones;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        findViewById(R.id.btnAnadirDireccion).setOnClickListener(v ->
                startActivity(new Intent(this, NuevaDireccionActivity.class)));
    }
}