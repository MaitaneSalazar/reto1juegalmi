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

import android.content.Intent;
import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.fragment.app.FragmentManager;
import com.example.retoindividual_1.network.SessionManager;

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

    private DrawerLayout dlMain;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        conectarBotonMenu();
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
        configurarMenuLateral();
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

    // ============================ MENÚ LATERAL ============================

    // El botón ☰ (ivBarraMenu) está en barra_superior.xml, que va DENTRO de cada Fragment.
    // En vez de programarlo en cada Fragment, la Activity se entera de cada Fragment que
    // crea su vista y, si tiene ese botón, le pone el clic para abrir el menú.
    private void conectarBotonMenu() {
        getSupportFragmentManager().registerFragmentLifecycleCallbacks(new FragmentManager.FragmentLifecycleCallbacks() {
            @Override
            public void onFragmentViewCreated(@NonNull FragmentManager fm, @NonNull Fragment f,
                                              @NonNull View v, @Nullable Bundle savedInstanceState) {
                View ivMenu = v.findViewById(R.id.ivBarraMenu);
                if (ivMenu != null) {
                    ivMenu.setOnClickListener(boton -> dlMain.openDrawer(GravityCompat.START));
                }
            }
        }, false);
    }

    private void configurarMenuLateral() {
        dlMain = findViewById(R.id.dlMain);

        // El panel también va a pantalla completa: margen para no quedar debajo de las barras del sistema
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.llMenuLateral), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, 0, systemBars.bottom);
            return insets;
        });

        // Páginas aparte
        findViewById(R.id.tvMenuPedidos).setOnClickListener(v -> abrirPagina(MisPedidosActivity.class));
        findViewById(R.id.tvMenuAlquileres).setOnClickListener(v -> abrirPagina(MisAlquileresActivity.class));
        findViewById(R.id.tvMenuDatos).setOnClickListener(v -> abrirPagina(DatosPersonalesActivity.class));
        findViewById(R.id.tvMenuDirecciones).setOnClickListener(v -> abrirPagina(DireccionesActivity.class));

        // Mis reparaciones está en la pestaña Taller (14 del mockup)
        findViewById(R.id.tvMenuReparaciones).setOnClickListener(v -> {
            dlMain.closeDrawer(GravityCompat.START);
            abrir(TALLER);
        });

        findViewById(R.id.tvMenuCerrarSesion).setOnClickListener(v -> cerrarSesion());

        // Botón atrás del móvil: si el menú está abierto, lo cierra en vez de salir de la app
        OnBackPressedCallback cerrarMenu = new OnBackPressedCallback(false) {
            @Override
            public void handleOnBackPressed() {
                dlMain.closeDrawer(GravityCompat.START);
            }
        };
        getOnBackPressedDispatcher().addCallback(this, cerrarMenu);
        dlMain.addDrawerListener(new DrawerLayout.SimpleDrawerListener() {
            @Override
            public void onDrawerOpened(@NonNull View drawerView) {
                cerrarMenu.setEnabled(true);
            }

            @Override
            public void onDrawerClosed(@NonNull View drawerView) {
                cerrarMenu.setEnabled(false);
            }
        });
    }

    // Cierra el menú y abre la página
    private void abrirPagina(Class<?> pagina) {
        dlMain.closeDrawer(GravityCompat.START);
        startActivity(new Intent(this, pagina));
    }

    // Borra el token y vuelve al login. Los flags vacían el historial de pantallas,
    // para que el botón atrás no pueda volver a la app sin iniciar sesión
    private void cerrarSesion() {
        new SessionManager(this).cerrarSesion();
        Intent intent = new Intent(this, LoginActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
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
