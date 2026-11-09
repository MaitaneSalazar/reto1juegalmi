package com.example.retoindividual_1.utilidades;

import android.view.View;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.OvershootInterpolator;

import com.example.retoindividual_1.R;

//ANIMACIONES DE LAS PANTALLAS CON ViewPropertyAnimator. VAN SOLAS EN EL HILO DE PINTADO (Choreographer),
//NO BLOQUEAN NADA, Y withLayer() PINTA LA VISTA EN LA GPU MIENTRAS DURA PARA NO REDIBUJARLA EN CADA FOTOGRAMA
public class Animaciones {

    //LA VISTA APARECE SUBIENDO UN POCO
    public static void aparecer(View vista) {
        vista.animate().cancel();
        vista.setAlpha(0f);
        vista.setTranslationY(vista.getResources().getDimension(R.dimen.anim_subida));
        vista.setVisibility(View.VISIBLE);
        vista.animate()
                .alpha(1f)
                .translationY(0f)
                .setDuration(vista.getResources().getInteger(android.R.integer.config_mediumAnimTime))
                .setInterpolator(new DecelerateInterpolator())
                .withLayer();
    }

    //LA VISTA CRECE Y VUELVE CON UN REBOTE, PARA CONFIRMAR QUE ALGO HA SALIDO BIEN
    public static void latido(final View vista) {
        final long corta = vista.getResources().getInteger(android.R.integer.config_shortAnimTime);
        vista.animate().cancel();
        vista.animate()
                .scaleX(1.08f)
                .scaleY(1.08f)
                .setDuration(corta / 2)
                .setInterpolator(new DecelerateInterpolator())
                .withLayer()
                .withEndAction(new Runnable() {
                    @Override
                    public void run() {
                        vista.animate()
                                .scaleX(1f)
                                .scaleY(1f)
                                .setDuration(corta)
                                .setInterpolator(new OvershootInterpolator(3f))
                                .withLayer();
                    }
                });
    }
}
