package com.example.retoindividual_1.adaptadores;

import com.example.retoindividual_1.nosotros.GaleriaFragment;
import com.example.retoindividual_1.nosotros.HistoriaFragment;
import com.example.retoindividual_1.nosotros.UbicacionFragment;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.viewpager2.adapter.FragmentStateAdapter;


//LAS 3 PAGINAS DE SOBRE NOSOTROS, EN EL MISMO ORDEN QUE nosotros_pestanas
public class NosotrosPaginasAdapter extends FragmentStateAdapter {

    public NosotrosPaginasAdapter(@NonNull Fragment fragment) {
        super(fragment);
    }

    @NonNull
    @Override
    public Fragment createFragment(int position) {
        switch (position) {
            case 1:
                return new HistoriaFragment();
            case 2:
                return new GaleriaFragment();
            default:
                return new UbicacionFragment();
        }
    }

    @Override
    public int getItemCount() {
        return 3;
    }
}
