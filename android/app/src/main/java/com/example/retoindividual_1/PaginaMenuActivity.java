package com.example.retoindividual_1;

import android.os.Bundle;

import androidx.activity.EdgeToEdge;
import androidx.annotation.LayoutRes;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

/*
 * BASE de las páginas que se abren desde el menú lateral.
 * Hace lo que tienen en común todas; cada página solo dice qué layout usa.
 * Es "abstract" porque no se abre nunca sola, siempre a través de una página hija.
 */
public abstract class PaginaMenuActivity extends AppCompatActivity {

    // Cada página hija devuelve su layout (R.layout.activity_...)
    @LayoutRes
    protected abstract int getLayout();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(getLayout());
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        // Botón de volver (barra_volver.xml): cierra esta página y vuelve a la anterior
        findViewById(R.id.ivVolver).setOnClickListener(v -> finish());
    }
}