package com.example.retoindividual_1.modelos;

import android.content.Context;
import android.content.res.ColorStateList;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.core.content.ContextCompat;

import com.example.retoindividual_1.R;

//NOMBRE Y COLOR DE CADA PLATAFORMA, LA API LAS MANDA COMO PlayStation, Xbox Y Switch
public class Plataforma {

    //UN JUEGO "Multi" ES DE TODAS ESTAS
    public static final String[] TODAS = {"PlayStation", "Xbox", "Switch"};

    public static String nombre(String codigo) {
        switch (codigo) {
            case "PS5":
                return "PlayStation";
            case "Switch":
                return "Nintendo Switch";
            default:
                return codigo;
        }
    }

    public static int color(String codigo) {
        switch (codigo) {
            case "PlayStation":
            case "PS5":
                return R.color.plataforma_playstation;
            case "Xbox":
                return R.color.plataforma_xbox;
            case "Switch":
                return R.color.plataforma_switch;
            default:
                return R.color.color_oscuro;
        }
    }

    //CREAMOS LA PILDORA CON EL NOMBRE Y EL COLOR DE LA PLATAFORMA
    public static TextView crearEtiqueta(Context context, String codigo, boolean pequena) {
        float dp = context.getResources().getDisplayMetrics().density;
        TextView etiqueta = new TextView(context);
        etiqueta.setText(nombre(codigo));
        etiqueta.setTextColor(ContextCompat.getColor(context, R.color.white));
        etiqueta.setTextSize(pequena ? 10 : 12);
        etiqueta.setTypeface(etiqueta.getTypeface(), android.graphics.Typeface.BOLD);
        etiqueta.setBackgroundResource(R.drawable.bg_pildora_hoja);
        etiqueta.setBackgroundTintList(ColorStateList.valueOf(ContextCompat.getColor(context, color(codigo))));
        int horizontal = (int) ((pequena ? 8 : 12) * dp);
        int vertical = (int) ((pequena ? 3 : 6) * dp);
        etiqueta.setPadding(horizontal, vertical, horizontal, vertical);

        LinearLayout.LayoutParams margenes = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        margenes.setMarginEnd((int) ((pequena ? 4 : 6) * dp));
        etiqueta.setLayoutParams(margenes);
        return etiqueta;
    }
}
