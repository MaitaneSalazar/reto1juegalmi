package com.example.retoindividual_1;

import android.content.Context;
import android.content.Intent;

import com.example.retoindividual_1.modelos.Domicilio;

// NUEVA DIRECCIÓN (20 del mockup). Sin domicilio: crear uno nuevo. Con domicilio: editarlo. De momento vacía.
public class NuevaDireccionActivity extends PaginaMenuActivity {

    public static final String EXTRA_DOMICILIO = "domicilio";

    public static Intent crearIntent(Context context, Domicilio domicilioAEditar) {
        Intent intent = new Intent(context, NuevaDireccionActivity.class);
        if (domicilioAEditar != null) {
            intent.putExtra(EXTRA_DOMICILIO, domicilioAEditar.getJson());
        }
        return intent;
    }

    @Override
    protected int getLayout() {
        return R.layout.activity_nueva_direccion;
    }
}