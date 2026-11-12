package com.example.retoindividual_1.principal;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.sesion.LoginActivity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;

import androidx.appcompat.app.AppCompatActivity;

//PANTALLA DE CARGA CON EL LOGO Y LAS LETRAS. ES LA PRIMERA QUE SE ABRE Y LUEGO PASA AL LOGIN
public class CargaActivity extends AppCompatActivity {

    private final Handler handler = new Handler(Looper.getMainLooper());

    private final Runnable irAlLogin = new Runnable() {
        @Override
        public void run() {
            startActivity(new Intent(CargaActivity.this, LoginActivity.class));
            finish();
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_carga);
        handler.postDelayed(irAlLogin, getResources().getInteger(R.integer.carga_duracion));
    }

    //SI SE SALE ANTES DE TIEMPO NO SE ABRE EL LOGIN
    @Override
    protected void onDestroy() {
        handler.removeCallbacks(irAlLogin);
        super.onDestroy();
    }
}
