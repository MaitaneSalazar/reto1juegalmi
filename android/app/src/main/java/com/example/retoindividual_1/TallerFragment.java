package com.example.retoindividual_1;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

public class TallerFragment extends Fragment {

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_taller, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // PRUEBA: quitar cuando esté la lista de "Mis reparaciones".
        // Pide a la Activity que abra el seguimiento dentro de la pestaña
        view.findViewById(R.id.btnPruebaSeguimiento).setOnClickListener(v ->
                ((MainActivity) requireActivity()).abrirSeguimiento());
    }
}
