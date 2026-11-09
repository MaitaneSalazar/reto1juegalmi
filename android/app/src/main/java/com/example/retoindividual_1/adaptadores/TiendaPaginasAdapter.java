package com.example.retoindividual_1.adaptadores;

import com.example.retoindividual_1.tienda.ListaProductosFragment;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.viewpager2.adapter.FragmentStateAdapter;


import java.util.List;

//UNA PAGINA DEL VIEWPAGER POR CADA PESTAÑA DE LA TIENDA, TODAS SON UNA LISTA DE PRODUCTOS
public class TiendaPaginasAdapter extends FragmentStateAdapter {

    private final boolean alquiler;
    private final List<String> filtros;

    public TiendaPaginasAdapter(@NonNull Fragment fragment, boolean alquiler, List<String> filtros) {
        super(fragment);
        this.alquiler = alquiler;
        this.filtros = filtros;
    }

    @NonNull
    @Override
    public Fragment createFragment(int position) {
        return ListaProductosFragment.nueva(alquiler, filtros.get(position));
    }

    @Override
    public int getItemCount() {
        return filtros.size();
    }
}
