package com.example.retoindividual_1.principal;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.alquileres.MisAlquileresActivity;
import com.example.retoindividual_1.cesta.CestaFragment;
import com.example.retoindividual_1.cuenta.DatosPersonalesActivity;
import com.example.retoindividual_1.cuenta.DireccionesActivity;
import com.example.retoindividual_1.inicio.InicioFragment;
import com.example.retoindividual_1.nosotros.NosotrosFragment;
import com.example.retoindividual_1.pedidos.MisPedidosActivity;
import com.example.retoindividual_1.sesion.LoginActivity;
import com.example.retoindividual_1.taller.SeguimientoReparacionFragment;
import com.example.retoindividual_1.taller.TallerFragment;
import com.example.retoindividual_1.tienda.TiendaFragment;
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

import com.bumptech.glide.Glide;
import com.example.retoindividual_1.datos.Repositorio;

import org.json.JSONObject;


import android.Manifest;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;

import com.example.retoindividual_1.network.Localizador;

//CONTENEDOR DE LA APP, CADA PESTAÑA DE LA BARRA CARGA SU FRAGMENT EN fcvMain

public class MainActivity extends AppCompatActivity {

    private Repositorio datos;

    private static final String PESTANA_ACTUAL = "pestana";
    private static final int INICIO = 0;
    private static final int TIENDA = 1;
    private static final int TALLER = 2;
    private static final int CESTA = 3;
    private static final int NOSOTROS = 4;

    private LinearLayout[] llPestanas;
    private ImageView[] ivPestanas;
    private TextView[] tvPestanas;
    private int pestanaActual = INICIO;

    private DrawerLayout dlMain;

    // Al responder al permiso (sí o no) se intenta empezar; sin permiso, Localizador no hace nada
    private final ActivityResultLauncher<String[]> pedirUbicacion = registerForActivityResult(
            new ActivityResultContracts.RequestMultiplePermissions(),
            resultado -> Localizador.getInstance(this).iniciar());

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

        //MISMO ORDEN QUE LA BARRA (INICIO, TIENDA, TALLER, CESTA, NOSOTROS)
        llPestanas = new LinearLayout[]{findViewById(R.id.llNavInicio), findViewById(R.id.llNavTienda), findViewById(R.id.llNavTaller),
                findViewById(R.id.llNavCesta), findViewById(R.id.llNavNosotros)};
        ivPestanas = new ImageView[]{findViewById(R.id.ivNavInicio), findViewById(R.id.ivNavTienda), findViewById(R.id.ivNavTaller),
                findViewById(R.id.ivNavCesta), findViewById(R.id.ivNavNosotros)};
        tvPestanas = new TextView[]{findViewById(R.id.tvNavInicio), findViewById(R.id.tvNavTienda), findViewById(R.id.tvNavTaller),
                findViewById(R.id.tvNavCesta), findViewById(R.id.tvNavNosotros)};

        //CADA PESTAÑA ABRE SU FRAGMENT
        for (int i = 0; i < llPestanas.length; i++) {
            final int pestana = i;
            llPestanas[i].setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    abrir(pestana);
                }
            });
        }

        //SI SE GIRA LA PANTALLA HAY QUE VOLVER A MARCAR LA PESTAÑA
        if (savedInstanceState != null) {
            pestanaActual = savedInstanceState.getInt(PESTANA_ACTUAL, INICIO);
        }
        marcar(pestanaActual);
        configurarMenuLateral();
        if (!Localizador.tienePermiso(this)) {
            pedirUbicacion.launch(new String[]{
                    Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION});
        }
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putInt(PESTANA_ACTUAL, pestanaActual);
    }

    private void abrir(int pestana) {
        FragmentManager fm = getSupportFragmentManager();
        boolean hayPaginaEncima = fm.getBackStackEntryCount() > 0;
        if (pestana == pestanaActual && !hayPaginaEncima) {
            return;
        }
        // Si había una página abierta dentro de la pestaña (por ejemplo, el seguimiento), se cierra.
        // Si no, al pulsar atrás en otra pestaña volvería a salir el seguimiento
        fm.popBackStack(null, FragmentManager.POP_BACK_STACK_INCLUSIVE);
        fm.beginTransaction().replace(R.id.fcvMain, crearFragment(pestana)).commit();
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
            default:
                return new InicioFragment();
        }
    }

    // Abre el seguimiento DENTRO de la pestaña Taller, sin tapar la barra inferior.
    // addToBackStack hace que la flecha y el botón atrás vuelvan al Taller
    public void abrirSeguimiento(int idReparacion) {
        getSupportFragmentManager().beginTransaction()
                .replace(R.id.fcvMain, SeguimientoReparacionFragment.crear(idReparacion))
                .addToBackStack(null)
                .commit();
    }

    // Abre la pestaña Taller directamente en la sub-pestaña "Mis reparaciones" (desde el menú lateral)
    private void abrirMisReparaciones() {
        FragmentManager fm = getSupportFragmentManager();
        fm.popBackStack(null, FragmentManager.POP_BACK_STACK_INCLUSIVE);
        fm.beginTransaction().replace(R.id.fcvMain, TallerFragment.crear(true)).commit();
        marcar(TALLER);
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

    // En onResume para que el menú se actualice al volver de cualquier pantalla
    @Override
    protected void onResume() {
        super.onResume();
        cargarUsuarioMenu();
        Localizador.getInstance(this).iniciar();
    }

    // Mientras la app no se ve, no se pide la ubicación (ahorra batería). Se sigue enviando la última conocida
    @Override
    protected void onPause() {
        super.onPause();
        Localizador.getInstance(this).detener();
    }

    private void cargarUsuarioMenu() {
        datos().usuario(new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject usuario) {
                pintarUsuarioMenu(usuario);
            }

            //SI FALLA, EL MENU SE QUEDA CON "Mi cuenta": NO MERECE LA PENA MOLESTAR CON UN AVISO
            @Override
            public void mal(String mensaje) {
            }
        });
    }

    private void pintarUsuarioMenu(JSONObject usuario) {
        ((TextView) findViewById(R.id.tvMenuNombre)).setText(usuario.optString("nombre_completo"));
        ((TextView) findViewById(R.id.tvMenuEmail)).setText(usuario.optString("email"));
        ((TextView) findViewById(R.id.tvMenuIniciales)).setText(usuario.optString("iniciales"));

        ImageView ivFoto = findViewById(R.id.ivMenuFoto);
        String foto = !usuario.isNull("foto_perfil_miniatura_url") ? usuario.optString("foto_perfil_miniatura_url")
                : !usuario.isNull("foto_perfil_url") ? usuario.optString("foto_perfil_url")
                : null;
        ivFoto.setVisibility(foto == null ? View.GONE : View.VISIBLE);
        if (foto != null) {
            ivFoto.setClipToOutline(true);
            Glide.with(this).load(foto).into(ivFoto);
        }

        JSONObject contadores = usuario.optJSONObject("contadores");
        pintarContador(R.id.tvMenuContadorPedidos, contadores, "pedidos");
        pintarContador(R.id.tvMenuContadorAlquileres, contadores, "alquileres_activos");
        pintarContador(R.id.tvMenuContadorReparaciones, contadores, "reparaciones_en_curso");
    }

    // Con 0 (o si no viene, como en los trabajadores) el número no se enseña
    private void pintarContador(int idVista, JSONObject contadores, String clave) {
        int valor = contadores == null ? 0 : contadores.optInt(clave);
        TextView tvContador = findViewById(idVista);
        tvContador.setText(String.valueOf(valor));
        tvContador.setVisibility(valor > 0 ? View.VISIBLE : View.GONE);
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
        findViewById(R.id.llMenuUsuario).setOnClickListener(v -> abrirPagina(DatosPersonalesActivity.class));

        // Mis reparaciones está en la pestaña Taller (14 del mockup)
        findViewById(R.id.tvMenuReparaciones).setOnClickListener(v -> {
            dlMain.closeDrawer(GravityCompat.START);
            abrirMisReparaciones();
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

    //LA ACTIVA SE VE EN PILDORA CON SU NOMBRE, LAS DEMAS SOLO EL ICONO
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

    //CAPA DE DATOS, SE CREA LA PRIMERA VEZ QUE SE USA
    private Repositorio datos() {
        if (datos == null) {
            datos = new Repositorio(this, this);
        }
        return datos;
    }
}
