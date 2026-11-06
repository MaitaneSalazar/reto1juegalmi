package com.example.retoindividual_1;

import android.content.res.ColorStateList;
import android.content.res.TypedArray;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;

//PESTAÑA HISTORIA, LOS HITOS ESTAN EN strings_nosotros PORQUE LA API NO LOS DEVUELVE
public class HistoriaFragment extends Fragment {

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_historia, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        LinearLayout llHistoria = view.findViewById(R.id.llHistoria);
        String[] anios = getResources().getStringArray(R.array.nosotros_hitos_anio);
        String[] titulos = getResources().getStringArray(R.array.nosotros_hitos_titulo);
        String[] textos = getResources().getStringArray(R.array.nosotros_hitos_texto);
        TypedArray iconos = getResources().obtainTypedArray(R.array.nosotros_hitos_icono);

        //CREAMOS UNA TARJETA POR HITO
        for (int i = 0; i < anios.length; i++) {
            View hito = getLayoutInflater().inflate(R.layout.item_hito, llHistoria, false);
            ((TextView) hito.findViewById(R.id.tvHitoAnio)).setText(anios[i]);
            ((TextView) hito.findViewById(R.id.tvHitoTitulo)).setText(titulos[i]);
            ((TextView) hito.findViewById(R.id.tvHitoTexto)).setText(textos[i]);
            ((ImageView) hito.findViewById(R.id.ivHitoIcono)).setImageResource(iconos.getResourceId(i, 0));

            if (i == anios.length - 1) {
                pintarUltimo(hito);
            }
            llHistoria.addView(hito);
        }
        iconos.recycle();
    }

    //EL ULTIMO HITO ES EL DE AHORA: TARJETA DE LA MARCA, PUNTO MAS GRANDE Y LA LINEA ACABA EN EL
    private void pintarUltimo(View hito) {
        int sobreMarca = ContextCompat.getColor(requireContext(), R.color.color_sobre_marca);
        float dp = getResources().getDisplayMetrics().density;

        hito.findViewById(R.id.llHitoTarjeta).setBackgroundResource(R.drawable.bg_hero);
        ((TextView) hito.findViewById(R.id.tvHitoAnio)).setTextColor(sobreMarca);
        ((TextView) hito.findViewById(R.id.tvHitoTitulo)).setTextColor(sobreMarca);
        ((TextView) hito.findViewById(R.id.tvHitoTexto)).setTextColor(sobreMarca);
        ImageView ivIcono = hito.findViewById(R.id.ivHitoIcono);
        ivIcono.setBackgroundTintList(ColorStateList.valueOf(ContextCompat.getColor(requireContext(), R.color.blanco_cristal)));
        ivIcono.setImageTintList(ColorStateList.valueOf(sobreMarca));

        View vPunto = hito.findViewById(R.id.vHitoPunto);
        FrameLayout.LayoutParams punto = (FrameLayout.LayoutParams) vPunto.getLayoutParams();
        punto.width = (int) (18 * dp);
        punto.height = (int) (18 * dp);
        punto.topMargin = (int) (23 * dp);
        vPunto.setBackgroundResource(R.drawable.bg_punto_actual);

        View vLinea = hito.findViewById(R.id.vHitoLinea);
        vLinea.getLayoutParams().height = (int) (30 * dp);
    }
}
