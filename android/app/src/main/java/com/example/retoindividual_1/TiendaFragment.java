package com.example.retoindividual_1;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

public class TiendaFragment extends Fragment {

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_tienda, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // En la tienda sí se busca: se enseña la lupa de la barra superior
        view.findViewById(R.id.ivBarraBuscar).setVisibility(View.VISIBLE);
        // PRUEBA: quitar cuando esté la lista de productos.
        // Los ids son inventados. Más adelante, cada producto de la lista abrirá su ficha
        // con su id real, y seAlquila será true solo si es un videojuego
        view.findViewById(R.id.btnPruebaFichaJuego).setOnClickListener(v ->
                startActivity(FichaProductoActivity.crearIntent(requireContext(), 1, true)));
        view.findViewById(R.id.btnPruebaFichaProducto).setOnClickListener(v ->
                startActivity(FichaProductoActivity.crearIntent(requireContext(), 7, false)));
    }
}
