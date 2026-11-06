package com.example.retoindividual_1;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

// SEGUIMIENTO DE REPARACIÓN (09 del mockup). Se abre dentro de la pestaña Taller. De momento vacía.
public class SeguimientoReparacionFragment extends Fragment {

    // Se usará para pedir la reparación a la API: GET /api/reparaciones/{id}
    private static final String ARG_ID_REPARACION = "id_reparacion";

    public static SeguimientoReparacionFragment crear(int idReparacion) {
        SeguimientoReparacionFragment fragment = new SeguimientoReparacionFragment();
        Bundle args = new Bundle();
        args.putInt(ARG_ID_REPARACION, idReparacion);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_seguimiento_reparacion, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        view.findViewById(R.id.ivVolver).setOnClickListener(v ->
                getParentFragmentManager().popBackStack());
    }
}