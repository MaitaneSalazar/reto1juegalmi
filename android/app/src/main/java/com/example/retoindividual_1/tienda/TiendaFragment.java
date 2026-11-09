package com.example.retoindividual_1.tienda;

import com.example.retoindividual_1.R;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentResultListener;
import androidx.viewpager2.widget.ViewPager2;

import com.example.retoindividual_1.adaptadores.TiendaPaginasAdapter;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.modelos.Plataforma;
import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class TiendaFragment extends Fragment {

    //AVISO QUE DEJA EL INICIO PARA ABRIR LA TIENDA EN ALQUILAR
    public static final String MODO = "modo_tienda";
    public static final String EMPEZAR_ALQUILANDO = "empezar_alquilando";

    //LO QUE ESPERA LA API EN ?tipo= , EN EL MISMO ORDEN QUE tienda_filtros_comprar
    private static final List<String> TIPOS = Arrays.asList("todo", "videojuego", "consola", "movil", "tablet");

    private TextView tvTitulo;
    private TabLayout tlModo;
    private TabLayout tlFiltros;
    private ViewPager2 vpProductos;
    private TabLayoutMediator mediador;
    private Repositorio datos;

    private boolean alquiler = false;
    private final List<String> plataformas = new ArrayList<>();

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_tienda, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        //EN LA TIENDA SI SE ENSEÑA LA LUPA DE BUSCAR
        View ivBuscar = view.findViewById(R.id.ivBarraBuscar);
        ivBuscar.setVisibility(View.VISIBLE);

        //LA LUPA ABRE EL BUSCADOR ENCIMA DE LA TIENDA, Y CON ATRAS SE VUELVE A ELLA
        ivBuscar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                getParentFragmentManager().beginTransaction()
                        .setCustomAnimations(R.anim.entrar_derecha, R.anim.salir_izquierda,
                                R.anim.entrar_izquierda, R.anim.salir_derecha)
                        .replace(R.id.fcvMain, new BuscarFragment())
                        .addToBackStack(null)
                        .commit();
            }
        });

        datos = new Repositorio(requireContext(), getViewLifecycleOwner());
        tvTitulo = view.findViewById(R.id.tvTiendaTitulo);
        tlModo = view.findViewById(R.id.tlTiendaModo);
        tlFiltros = view.findViewById(R.id.tlTiendaFiltros);
        vpProductos = view.findViewById(R.id.vpTienda);

        //PESTAÑA 0 COMPRAR, PESTAÑA 1 ALQUILAR
        tlModo.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {
                cambiarModo(tab.getPosition() == 1);
            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) {
            }

            @Override
            public void onTabReselected(TabLayout.Tab tab) {
            }
        });

        cambiarModo(false);

        //SI SE VIENE DESDE "ALQUILAR" DEL INICIO, LA TIENDA SE ABRE YA EN ALQUILAR
        getParentFragmentManager().setFragmentResultListener(MODO, getViewLifecycleOwner(), new FragmentResultListener() {
            @Override
            public void onFragmentResult(@NonNull String clave, @NonNull Bundle resultado) {
                TabLayout.Tab tabAlquilar = tlModo.getTabAt(1);
                if (resultado.getBoolean(EMPEZAR_ALQUILANDO) && tabAlquilar != null) {
                    tabAlquilar.select();
                }
            }
        });
    }

    private void cambiarModo(boolean alquilar) {
        alquiler = alquilar;
        tvTitulo.setText(alquiler ? R.string.tienda_alquilar : R.string.tienda);

        //LAS PLATAFORMAS SOLO SE PIDEN LA PRIMERA VEZ QUE SE ENTRA A ALQUILAR
        if (alquiler && plataformas.isEmpty()) {
            cargarPlataformas();
        } else {
            montarPestanas();
        }
    }

    //LAS PLATAFORMAS PARA ALQUILAR SALEN DE LA API, NO ESTAN PUESTAS A MANO
    private void cargarPlataformas() {
        datos.plataformasAlquiler(new Repositorio.Resultado<List<String>>() {
            @Override
            public void bien(List<String> lista) {
                plataformas.addAll(lista);
                montarPestanas();
            }

            @Override
            public void mal(String mensaje) {
                //SIN PLATAFORMAS SALE SOLO "TODAS" Y AHI YA SE VERA EL AVISO DE SIN CONEXION
                montarPestanas();
            }
        });
    }

    private void montarPestanas() {
        List<String> textos = new ArrayList<>();
        List<String> filtros = new ArrayList<>();
        if (alquiler) {
            textos.add(getString(R.string.tienda_todas));
            filtros.add("todas");
            //Multi YA NO ES UNA PESTAÑA, ESOS JUEGOS SON DE TODAS
            for (String codigo : plataformas) {
                if (!codigo.equals("Multi")) {
                    textos.add(Plataforma.nombre(codigo));
                    filtros.add(codigo);
                }
            }
        } else {
            textos.addAll(Arrays.asList(getResources().getStringArray(R.array.tienda_filtros_comprar)));
            filtros.addAll(TIPOS);
        }

        //CADA VEZ QUE SE CAMBIA DE MODO SE QUITAN LAS PESTAÑAS DE ANTES
        if (mediador != null) {
            mediador.detach();
        }
        vpProductos.setAdapter(new TiendaPaginasAdapter(this, alquiler, filtros));
        mediador = new TabLayoutMediator(tlFiltros, vpProductos, (tab, position) -> {
            tab.setText(textos.get(position)); //NOMBRE DE LA PESTAÑA
        });
        mediador.attach();
    }
}
