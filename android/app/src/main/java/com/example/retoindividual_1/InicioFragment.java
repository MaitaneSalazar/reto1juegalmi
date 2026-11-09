package com.example.retoindividual_1;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.AuthFailureError;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.bumptech.glide.Glide;
import com.example.retoindividual_1.adaptadores.ProductoAdapter;
import com.example.retoindividual_1.modelos.Alquiler;
import com.example.retoindividual_1.modelos.Producto;
import com.example.retoindividual_1.modelos.Reparacion;
import com.example.retoindividual_1.network.ApiClient;
import com.example.retoindividual_1.utilidades.FormatosReparacion;
import com.google.android.material.progressindicator.CircularProgressIndicator;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

//INICIO (03 DEL MOCKUP): EL SALUDO, ACCESOS A TALLER Y TIENDA, LO QUE TIENES EN CURSO Y LAS NOVEDADES
public class InicioFragment extends Fragment {

    private TextView tvHola;
    private LinearLayout llReparacion;
    private CircularProgressIndicator cpiReparacion;
    private TextView tvReparacionPaso;
    private TextView tvReparacionTitulo;
    private TextView tvReparacionEstado;
    private LinearLayout llAlquiler;
    private ImageView ivAlquiler;
    private TextView tvAlquilerNombre;
    private TextView tvAlquilerDias;
    private TextView tvAlquilerDiasTexto;
    private LinearLayout llNovedadesTitulo;
    private RecyclerView rvNovedades;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_inicio, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        tvHola = view.findViewById(R.id.tvInicioHola);
        llReparacion = view.findViewById(R.id.llInicioReparacion);
        cpiReparacion = view.findViewById(R.id.cpiInicioReparacion);
        tvReparacionPaso = view.findViewById(R.id.tvInicioReparacionPaso);
        tvReparacionTitulo = view.findViewById(R.id.tvInicioReparacionTitulo);
        tvReparacionEstado = view.findViewById(R.id.tvInicioReparacionEstado);
        llAlquiler = view.findViewById(R.id.llInicioAlquiler);
        ivAlquiler = view.findViewById(R.id.ivInicioAlquiler);
        tvAlquilerNombre = view.findViewById(R.id.tvInicioAlquilerNombre);
        tvAlquilerDias = view.findViewById(R.id.tvInicioAlquilerDias);
        tvAlquilerDiasTexto = view.findViewById(R.id.tvInicioAlquilerDiasTexto);
        llNovedadesTitulo = view.findViewById(R.id.llInicioNovedadesTitulo);
        rvNovedades = view.findViewById(R.id.rvInicioNovedades);

        rvNovedades.setLayoutManager(new LinearLayoutManager(getContext(), LinearLayoutManager.HORIZONTAL, false));

        //LOS ACCESOS PULSAN LA PESTAÑA DE ABAJO, ASI LA BARRA SE MARCA BIEN
        view.findViewById(R.id.btnInicioPedirReparacion).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                irAPestana(R.id.llNavTaller);
            }
        });
        view.findViewById(R.id.llInicioComprar).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                irAPestana(R.id.llNavTienda);
            }
        });
        view.findViewById(R.id.tvInicioVerTodo).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                irAPestana(R.id.llNavTienda);
            }
        });
        //PARA ALQUILAR LE DEJAMOS UN AVISO A LA TIENDA PARA QUE SE ABRA YA EN ALQUILAR
        view.findViewById(R.id.llInicioAlquilar).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Bundle modo = new Bundle();
                modo.putBoolean(TiendaFragment.EMPEZAR_ALQUILANDO, true);
                getParentFragmentManager().setFragmentResult(TiendaFragment.MODO, modo);
                irAPestana(R.id.llNavTienda);
            }
        });
        llAlquiler.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivity(new Intent(requireContext(), MisAlquileresActivity.class));
            }
        });

        cargarUsuario();
        cargarReparacion();
        cargarAlquiler();
        cargarNovedades();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        ApiClient.getInstance(requireContext()).getCola().cancelAll(this);
    }

    private void irAPestana(int idPestana) {
        requireActivity().findViewById(idPestana).performClick();
    }

    //"Hola, Ane". SI FALLA SE QUEDA EN "Hola"
    private void cargarUsuario() {
        pedir(ApiClient.BASE_URL + "yo", true, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject usuario) {
                tvHola.setText(getString(R.string.inicio_hola, usuario.optString("nombre")));
            }
        });
    }

    //LA PRIMERA REPARACION QUE SIGA EN CURSO, CON SU ANILLO DE PASOS
    private void cargarReparacion() {
        pedir(ApiClient.BASE_URL + "reparaciones?limit=20", true, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject respuesta) {
                JSONArray datos = respuesta.optJSONArray("datos");
                for (int i = 0; datos != null && i < datos.length(); i++) {
                    Reparacion reparacion = new Reparacion(datos.optJSONObject(i));
                    if (reparacion.estaEnCurso()) {
                        pintarReparacion(reparacion);
                        return;
                    }
                }
            }
        });
    }

    private void pintarReparacion(Reparacion reparacion) {
        cpiReparacion.setMax(reparacion.getTotalPasos());
        cpiReparacion.setProgress(reparacion.getPaso());
        tvReparacionPaso.setText(getString(R.string.inicio_paso, reparacion.getPaso(), reparacion.getTotalPasos()));
        tvReparacionTitulo.setText(FormatosReparacion.titulo(requireContext(),
                reparacion.getTipoDispositivo(), reparacion.getMarca(), reparacion.getModelo()));
        tvReparacionEstado.setText(reparacion.getEstadoTexto());
        llReparacion.setVisibility(View.VISIBLE);

        //EL SEGUIMIENTO LO ABRE LA ACTIVITY, COMO DESDE EL TALLER
        llReparacion.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                ((MainActivity) requireActivity()).abrirSeguimiento(reparacion.getId());
            }
        });
    }

    //EL PRIMER ALQUILER SIN DEVOLVER, CON LOS DIAS QUE QUEDAN (O LOS DE RETRASO EN ROJO)
    private void cargarAlquiler() {
        pedir(ApiClient.BASE_URL + "alquileres?limit=20", true, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject respuesta) {
                JSONArray datos = respuesta.optJSONArray("datos");
                for (int i = 0; datos != null && i < datos.length(); i++) {
                    Alquiler alquiler = new Alquiler(datos.optJSONObject(i));
                    if (!alquiler.estaDevuelto() && !alquiler.getLineas().isEmpty()) {
                        pintarAlquiler(alquiler);
                        return;
                    }
                }
            }
        });
    }

    private void pintarAlquiler(Alquiler alquiler) {
        Producto juego = alquiler.getLineas().get(0).getVideojuego();
        int dias = Math.abs(alquiler.getDiasRestantes());

        tvAlquilerNombre.setText(juego.getNombre());
        tvAlquilerDias.setText(String.valueOf(dias));
        tvAlquilerDias.setTextColor(ContextCompat.getColor(requireContext(),
                alquiler.estaRetrasado() ? R.color.color_alerta : R.color.color_texto));
        tvAlquilerDiasTexto.setText(getResources().getQuantityString(
                alquiler.estaRetrasado() ? R.plurals.alq_dias_retraso : R.plurals.alq_dias_quedan, dias));
        Glide.with(this).load(juego.getMiniaturaUrl())
                .placeholder(R.drawable.placeholder_producto)
                .error(R.drawable.placeholder_producto)
                .into(ivAlquiler);
        llAlquiler.setVisibility(View.VISIBLE);
    }

    //LOS ULTIMOS PRODUCTOS DE LA TIENDA EN UNA FILA QUE SE DESLIZA
    private void cargarNovedades() {
        pedir(ApiClient.BASE_URL + "productos?limit=8", false, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject respuesta) {
                JSONArray datos = respuesta.optJSONArray("datos");
                List<Producto> productos = new ArrayList<>();
                for (int i = 0; datos != null && i < datos.length(); i++) {
                    productos.add(new Producto(datos.optJSONObject(i)));
                }
                if (!productos.isEmpty()) {
                    rvNovedades.setAdapter(new ProductoAdapter(productos, false));
                    llNovedadesTitulo.setVisibility(View.VISIBLE);
                }
            }
        });
    }

    //GET A LA API. SI FALLA NO SE ENSEÑA ESA PARTE Y YA, EL INICIO NO SE LLENA DE AVISOS
    private void pedir(String url, boolean conToken, Response.Listener<JSONObject> siSaleBien) {
        ApiClient api = ApiClient.getInstance(requireContext());
        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.GET, url, null, siSaleBien,
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                    }
                }) {
            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                return conToken ? api.getCabeceras() : super.getHeaders();
            }
        };
        peticion.setTag(this);
        api.getCola().add(peticion);
    }
}
