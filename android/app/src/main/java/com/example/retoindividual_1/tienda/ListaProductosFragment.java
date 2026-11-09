package com.example.retoindividual_1.tienda;

import com.example.retoindividual_1.R;
import android.content.res.ColorStateList;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.retoindividual_1.adaptadores.ProductoAdapter;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.modelos.Plataforma;
import com.example.retoindividual_1.modelos.Producto;

import java.util.ArrayList;
import java.util.List;

import retrofit2.Call;

//CADA PESTAÑA DE LA TIENDA, CARGA SUS PRODUCTOS DE LA API Y LOS ENSEÑA EN 2 COLUMNAS
public class ListaProductosFragment extends Fragment {

    private static final String ALQUILER = "alquiler";
    private static final String FILTRO = "filtro";

    private RecyclerView rvProductos;
    private ProgressBar pbCargando;
    private LinearLayout llAviso;
    private TextView tvAvisoTitulo;
    private TextView tvAvisoTexto;
    private Button btnReintentar;
    private HorizontalScrollView hsvPlataformas;
    private LinearLayout llPlataformas;

    //PLATAFORMA ELEGIDA EN COMPRAR VIDEOJUEGOS, VACIA ES TODAS
    private String plataforma = "";

    //CARGA PROGRESIVA: SE PIDEN DE 10 EN 10 Y LA SIGUIENTE PAGINA AL LLEGAR CERCA DEL FINAL
    private static final int POR_PAGINA = 10;
    private final List<Producto> productos = new ArrayList<>();
    private ProductoAdapter adaptador;
    private Repositorio datos;
    private Call<String> llamadaProductos;
    private boolean cargando;
    private int pagina;
    private int paginas;

    public ListaProductosFragment() {
    }

    //LE PASAMOS EN UN BUNDLE SI ES DE ALQUILER Y QUE FILTRO TIENE
    public static ListaProductosFragment nueva(boolean alquiler, String filtro) {
        ListaProductosFragment fragment = new ListaProductosFragment();
        Bundle bundle = new Bundle();
        bundle.putBoolean(ALQUILER, alquiler);
        bundle.putString(FILTRO, filtro);
        fragment.setArguments(bundle);
        return fragment;
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_lista_productos, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        datos = new Repositorio(requireContext(), getViewLifecycleOwner());
        rvProductos = view.findViewById(R.id.rvProductos);
        pbCargando = view.findViewById(R.id.pbProductos);
        llAviso = view.findViewById(R.id.llProductosAviso);
        tvAvisoTitulo = view.findViewById(R.id.tvProductosAvisoTitulo);
        tvAvisoTexto = view.findViewById(R.id.tvProductosAvisoTexto);
        btnReintentar = view.findViewById(R.id.btnProductosReintentar);
        hsvPlataformas = view.findViewById(R.id.hsvProductosPlataformas);
        llPlataformas = view.findViewById(R.id.llProductosFiltroPlataformas);

        //EN MOVIL 2 COLUMNAS, EN TABLET O EN HORIZONTAL MAS (res/values-*/integers_tienda.xml)
        GridLayoutManager columnas = new GridLayoutManager(getContext(), getResources().getInteger(R.integer.tienda_columnas));
        rvProductos.setLayoutManager(columnas);

        //CUANDO QUEDAN POCAS TARJETAS POR VER SE PIDE LA SIGUIENTE PAGINA
        rvProductos.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView recyclerView, int dx, int dy) {
                if (columnas.findLastVisibleItemPosition() >= productos.size() - 4) {
                    cargarSiguiente();
                }
            }
        });

        btnReintentar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                cargarProductos();
            }
        });

        //EN COMPRAR VIDEOJUEGOS SE PUEDE FILTRAR TAMBIEN POR PLATAFORMA
        if (!requireArguments().getBoolean(ALQUILER) && "videojuego".equals(requireArguments().getString(FILTRO))) {
            cargarPlataformas();
        }

        cargarProductos();
    }

    //EMPIEZA LA LISTA DE CERO (AL ENTRAR, AL CAMBIAR DE PLATAFORMA O AL REINTENTAR)
    private void cargarProductos() {
        //SI HABIA UNA PAGINA EN CAMINO DE LA PLATAFORMA DE ANTES SE CANCELA
        if (llamadaProductos != null) {
            llamadaProductos.cancel();
        }
        cargando = false;
        productos.clear();
        adaptador = new ProductoAdapter(productos, requireArguments().getBoolean(ALQUILER));
        rvProductos.setAdapter(adaptador);
        pagina = 0;
        paginas = 1;
        llAviso.setVisibility(View.GONE);
        pbCargando.setVisibility(View.VISIBLE);
        cargarSiguiente();
    }

    private void cargarSiguiente() {
        if (cargando || pagina >= paginas) {
            return;
        }
        cargando = true;
        String filtro = requireArguments().getString(FILTRO);
        int siguiente = pagina + 1;

        Repositorio.Resultado<Repositorio.Pagina<Producto>> alLlegar = new Repositorio.Resultado<Repositorio.Pagina<Producto>>() {
            @Override
            public void bien(Repositorio.Pagina<Producto> nueva) {
                cargando = false;
                pbCargando.setVisibility(View.GONE);
                pagina = siguiente;
                paginas = nueva.getPaginas();

                int antes = productos.size();
                productos.addAll(nueva.getLista());
                if (productos.isEmpty()) {
                    mostrarAviso(getString(R.string.tienda_vacia_titulo), getString(R.string.tienda_vacia_texto), false);
                    return;
                }
                adaptador.notifyItemRangeInserted(antes, productos.size() - antes);
                if (antes == 0) {
                    //LAS TARJETAS ENTRAN UNA DETRAS DE OTRA (res/anim/lista_entra.xml)
                    rvProductos.scheduleLayoutAnimation();
                }
                //EN TABLET 10 PUEDEN NO LLENAR LA PANTALLA Y SIN SCROLL NO SE PEDIRIA MAS
                rvProductos.post(new Runnable() {
                    @Override
                    public void run() {
                        if (!rvProductos.canScrollVertically(1)) {
                            cargarSiguiente();
                        }
                    }
                });
            }

            @Override
            public void mal(String mensaje) {
                cargando = false;
                pbCargando.setVisibility(View.GONE);
                //SI FALLA UNA PAGINA DE MAS ABAJO SE DEJA LO QUE YA HAY, SE VOLVERA A PEDIR AL MOVERSE
                if (productos.isEmpty()) {
                    mostrarAviso(getString(R.string.tienda_error_titulo), mensaje, true);
                }
            }
        };

        if (requireArguments().getBoolean(ALQUILER)) {
            llamadaProductos = datos.alquilables(filtro, siguiente, POR_PAGINA, alLlegar);
        } else {
            llamadaProductos = datos.productos(filtro, plataforma.isEmpty() ? null : plataforma, siguiente, POR_PAGINA, alLlegar);
        }
    }

    //LAS PLATAFORMAS SALEN DE LA API, SI FALLA NO SE ENSEÑA LA FILA Y YA
    private void cargarPlataformas() {
        datos.plataformasCompra(new Repositorio.Resultado<List<String>>() {
            @Override
            public void bien(List<String> lista) {
                if (lista.isEmpty()) {
                    return;
                }
                anadirPlataforma(getString(R.string.tienda_todas), "");
                for (String codigo : lista) {
                    anadirPlataforma(Plataforma.nombre(codigo), codigo);
                }
                pintarPlataformas();
                hsvPlataformas.setVisibility(View.VISIBLE);
            }

            @Override
            public void mal(String mensaje) {
            }
        });
    }

    //CREAMOS LA PILDORA, EN EL TAG GUARDAMOS LO QUE SE MANDA A LA API
    private void anadirPlataforma(String texto, String codigo) {
        TextView pildora = Plataforma.crearEtiqueta(requireContext(), codigo, false);
        pildora.setText(texto);
        pildora.setTag(codigo);
        pildora.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                plataforma = (String) v.getTag();
                pintarPlataformas();
                cargarProductos();
            }
        });
        llPlataformas.addView(pildora);
    }

    //LA ELEGIDA CON EL COLOR DE SU PLATAFORMA, EL RESTO EN GRIS
    private void pintarPlataformas() {
        for (int i = 0; i < llPlataformas.getChildCount(); i++) {
            TextView pildora = (TextView) llPlataformas.getChildAt(i);
            String codigo = (String) pildora.getTag();
            boolean elegida = codigo.equals(plataforma);
            int fondo = elegida ? Plataforma.color(codigo) : R.color.color_pozo;
            pildora.setBackgroundTintList(ColorStateList.valueOf(ContextCompat.getColor(requireContext(), fondo)));
            pildora.setTextColor(ContextCompat.getColor(requireContext(), elegida ? R.color.white : R.color.color_texto));
        }
    }

    //SIN PRODUCTOS O SIN CONEXION. SOLO SALE REINTENTAR SI HA FALLADO LA CONEXION
    private void mostrarAviso(String titulo, String texto, boolean reintentar) {
        tvAvisoTitulo.setText(titulo);
        tvAvisoTexto.setText(texto);
        btnReintentar.setVisibility(reintentar ? View.VISIBLE : View.GONE);
        llAviso.setVisibility(View.VISIBLE);
    }
}
