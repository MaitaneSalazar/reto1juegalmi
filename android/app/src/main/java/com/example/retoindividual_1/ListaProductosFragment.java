package com.example.retoindividual_1;

import android.content.res.ColorStateList;
import android.net.Uri;
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

import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.example.retoindividual_1.adaptadores.ProductoAdapter;
import com.example.retoindividual_1.modelos.Plataforma;
import com.example.retoindividual_1.modelos.Producto;
import com.example.retoindividual_1.network.ApiClient;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

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

        rvProductos = view.findViewById(R.id.rvProductos);
        pbCargando = view.findViewById(R.id.pbProductos);
        llAviso = view.findViewById(R.id.llProductosAviso);
        tvAvisoTitulo = view.findViewById(R.id.tvProductosAvisoTitulo);
        tvAvisoTexto = view.findViewById(R.id.tvProductosAvisoTexto);
        btnReintentar = view.findViewById(R.id.btnProductosReintentar);
        hsvPlataformas = view.findViewById(R.id.hsvProductosPlataformas);
        llPlataformas = view.findViewById(R.id.llProductosFiltroPlataformas);

        rvProductos.setLayoutManager(new GridLayoutManager(getContext(), 2));

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

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        //SI SALIMOS ANTES DE QUE RESPONDA LA API SE CANCELA LA PETICION
        ApiClient.getInstance(requireContext()).getCola().cancelAll(this);
    }

    private void cargarProductos() {
        boolean alquiler = requireArguments().getBoolean(ALQUILER);
        String filtro = requireArguments().getString(FILTRO);

        String url;
        if (alquiler) {
            url = ApiClient.BASE_URL + "videojuegos/alquiler?limit=50&plataforma=" + Uri.encode(filtro);
        } else {
            url = ApiClient.BASE_URL + "productos?limit=50&tipo=" + filtro;
            if (!plataforma.isEmpty()) {
                url += "&plataforma=" + Uri.encode(plataforma);
            }
        }

        llAviso.setVisibility(View.GONE);
        pbCargando.setVisibility(View.VISIBLE);

        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.GET, url, null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject respuesta) {
                        pbCargando.setVisibility(View.GONE);
                        JSONArray datos = respuesta.optJSONArray("datos");
                        List<Producto> productos = new ArrayList<>();
                        for (int i = 0; datos != null && i < datos.length(); i++) {
                            productos.add(new Producto(datos.optJSONObject(i)));
                        }

                        if (productos.isEmpty()) {
                            mostrarAviso(getString(R.string.tienda_vacia_titulo), getString(R.string.tienda_vacia_texto), false);
                        } else {
                            rvProductos.setAdapter(new ProductoAdapter(productos, alquiler));
                            //LAS TARJETAS ENTRAN UNA DETRAS DE OTRA (res/anim/lista_entra.xml)
                            rvProductos.scheduleLayoutAnimation();
                        }
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        pbCargando.setVisibility(View.GONE);
                        mostrarAviso(getString(R.string.tienda_error_titulo), ApiClient.mensajeDeError(error), true);
                    }
                });
        peticion.setTag(this);
        ApiClient.getInstance(requireContext()).getCola().add(peticion);
    }

    //LAS PLATAFORMAS SALEN DE LA API, SI FALLA NO SE ENSEÑA LA FILA Y YA
    private void cargarPlataformas() {
        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.GET, ApiClient.BASE_URL + "productos/filtros", null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject respuesta) {
                        JSONArray lista = respuesta.optJSONArray("plataformas");
                        if (lista == null || lista.length() == 0) {
                            return;
                        }
                        anadirPlataforma(getString(R.string.tienda_todas), "");
                        for (int i = 0; i < lista.length(); i++) {
                            anadirPlataforma(Plataforma.nombre(lista.optString(i)), lista.optString(i));
                        }
                        pintarPlataformas();
                        hsvPlataformas.setVisibility(View.VISIBLE);
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                    }
                });
        peticion.setTag(this);
        ApiClient.getInstance(requireContext()).getCola().add(peticion);
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
                rvProductos.setAdapter(null);
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
