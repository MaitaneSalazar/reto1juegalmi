package com.example.retoindividual_1.nosotros;

import com.example.retoindividual_1.R;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.viewpager2.widget.ViewPager2;

import com.example.retoindividual_1.adaptadores.NosotrosPaginasAdapter;
import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;

//SOBRE NOSOTROS, CADA PESTAÑA ES UN FRAGMENT: UBICACION, HISTORIA Y GALERIA
public class NosotrosFragment extends Fragment {

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_nosotros, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        TabLayout tlNosotros = view.findViewById(R.id.tlNosotros);
        ViewPager2 vpNosotros = view.findViewById(R.id.vpNosotros);
        String[] pestanas = getResources().getStringArray(R.array.nosotros_pestanas);

        vpNosotros.setAdapter(new NosotrosPaginasAdapter(this));
        //LAS 3 PESTAÑAS SE QUEDAN CREADAS: SI NO, AL VOLVER A UBICACION EL MAPA SE REINICIA Y SE DESCOLOCA
        vpNosotros.setOffscreenPageLimit(2);
        new TabLayoutMediator(tlNosotros, vpNosotros, new TabLayoutMediator.TabConfigurationStrategy() {
            @Override
            public void onConfigureTab(@NonNull TabLayout.Tab tab, int position) {
                tab.setText(pestanas[position]);
            }
        }).attach();
    }
}
