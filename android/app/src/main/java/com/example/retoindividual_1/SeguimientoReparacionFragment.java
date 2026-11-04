package com.example.retoindividual_1;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

// SEGUIMIENTO DE REPARACIÓN. Se abre dentro de la pestaña Taller. De momento vacía.
public class SeguimientoReparacionFragment extends Fragment {

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_seguimiento_reparacion, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // Flecha de volver: saca este Fragment de la pila y vuelve a mostrarse el Taller
        view.findViewById(R.id.ivVolver).setOnClickListener(v ->
                getParentFragmentManager().popBackStack());
    }
}