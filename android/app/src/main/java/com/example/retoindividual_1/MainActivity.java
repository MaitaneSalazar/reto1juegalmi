package com.example.retoindividual_1;

import android.content.res.ColorStateList;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.widget.ImageViewCompat;
import androidx.fragment.app.Fragment;

/*
 * =====================================================================================
 *  CONTENEDOR de la app: cada pestaña es un Fragment que se carga en fcvMain.
 *  La barra inferior marca la pestaña activa abriéndola en píldora con su nombre.
 *
 *  Inicio -> InicioFragment      Tienda   -> TiendaFragment     Taller -> TallerFragment
 *  Cesta  -> CestaFragment       Nosotros -> NosotrosFragment   Cuenta -> CuentaFragment
 * =====================================================================================
 */

public class MainActivity extends AppCompatActivity {

    private static final String PESTANA_ACTUAL = "pestana";
    private static final int INICIO = 0;
    private static final int TIENDA = 1;
    private static final int TALLER = 2;
    private static final int CESTA = 3;
    private static final int NOSOTROS = 4;
    private static final int CUENTA = 5;

    private LinearLayout[] llPestanas;
    private ImageView[] ivPestanas;
    private TextView[] tvPestanas;
    private int pestanaActual = INICIO;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        // Mismo orden que en la barra: Inicio, Tienda, Taller, Cesta, Nosotros, Cuenta
        llPestanas = new LinearLayout[]{findViewById(R.id.llNavInicio), findViewById(R.id.llNavTienda), findViewById(R.id.llNavTaller),
                findViewById(R.id.llNavCesta), findViewById(R.id.llNavNosotros), findViewById(R.id.llNavCuenta)};
        ivPestanas = new ImageView[]{findViewById(R.id.ivNavInicio), findViewById(R.id.ivNavTienda), findViewById(R.id.ivNavTaller),
                findViewById(R.id.ivNavCesta), findViewById(R.id.ivNavNosotros), findViewById(R.id.ivNavCuenta)};
        tvPestanas = new TextView[]{findViewById(R.id.tvNavInicio), findViewById(R.id.tvNavTienda), findViewById(R.id.tvNavTaller),
                findViewById(R.id.tvNavCesta), findViewById(R.id.tvNavNosotros), findViewById(R.id.tvNavCuenta)};

        // Cada pestaña abre su Fragment
        for (int i = 0; i < llPestanas.length; i++) {
            final int pestana = i;
            llPestanas[i].setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    abrir(pestana);
                }
            });
        }

        // Al girar la pantalla el Fragment se conserva solo; hay que volver a marcar su pestaña
        if (savedInstanceState != null) {
            pestanaActual = savedInstanceState.getInt(PESTANA_ACTUAL, INICIO);
        }
        marcar(pestanaActual);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putInt(PESTANA_ACTUAL, pestanaActual);
    }

    private void abrir(int pestana) {
        if (pestana == pestanaActual) {
            return;
        }
        getSupportFragmentManager().beginTransaction().replace(R.id.fcvMain, crearFragment(pestana)).commit();
        marcar(pestana);
    }

    private Fragment crearFragment(int pestana) {
        switch (pestana) {
            case TIENDA:
                return new TiendaFragment();
            case TALLER:
                return new TallerFragment();
            case CESTA:
                return new CestaFragment();
            case NOSOTROS:
                return new NosotrosFragment();
            case CUENTA:
                return new CuentaFragment();
            default:
                return new InicioFragment();
        }
    }

    // La activa: píldora calamina con icono y nombre. Las demás: solo el icono, en blanco tenue
    private void marcar(int pestana) {
        pestanaActual = pestana;
        for (int i = 0; i < llPestanas.length; i++) {
            boolean activa = i == pestana;
            LinearLayout.LayoutParams lp = (LinearLayout.LayoutParams) llPestanas[i].getLayoutParams();
            lp.width = activa ? LinearLayout.LayoutParams.WRAP_CONTENT : 0;
            lp.weight = activa ? 0 : 1;
            llPestanas[i].setLayoutParams(lp);
            llPestanas[i].setBackgroundResource(activa ? R.drawable.bg_pildora_marca : 0);
            tvPestanas[i].setVisibility(activa ? View.VISIBLE : View.GONE);
            int color = ContextCompat.getColor(this, activa ? R.color.color_sobre_marca : R.color.blanco_tenue);
            ImageViewCompat.setImageTintList(ivPestanas[i], ColorStateList.valueOf(color));
        }
    }
}
