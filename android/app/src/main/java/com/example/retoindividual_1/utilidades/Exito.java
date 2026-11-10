package com.example.retoindividual_1.utilidades;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.app.Activity;
import android.app.Dialog;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;

import com.airbnb.lottie.LottieAnimationView;
import com.example.retoindividual_1.R;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

//ANIMACION DE "HECHO" CON LOTTIE: UN CHECK QUE SE DIBUJA Y UN TEXTO. AL TERMINAR SE CIERRA SOLA
public final class Exito {

    private static final long PAUSA_MS = 500; //EL CHECK SE QUEDA UN MOMENTO A LA VISTA ANTES DE CERRAR

    private Exito() {
    }

    public static void mostrar(Activity actividad, String texto, Runnable alTerminar) {
        View vista = LayoutInflater.from(actividad).inflate(R.layout.dialogo_exito, null);
        ((TextView) vista.findViewById(R.id.tvExitoTexto)).setText(texto);
        LottieAnimationView animacion = vista.findViewById(R.id.lavExito);

        Dialog dialogo = new MaterialAlertDialogBuilder(actividad)
                .setView(vista)
                .setCancelable(false)
                .create();

        animacion.addAnimatorListener(new AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(Animator animator) {
                animacion.postDelayed(() -> {
                    //SI LA PANTALLA SE HA CERRADO MIENTRAS TANTO, NO SE TOCA NADA
                    if (actividad.isFinishing() || actividad.isDestroyed()) {
                        return;
                    }
                    dialogo.dismiss();
                    if (alTerminar != null) {
                        alTerminar.run();
                    }
                }, PAUSA_MS);
            }
        });
        dialogo.show();
        animacion.playAnimation();
    }
}