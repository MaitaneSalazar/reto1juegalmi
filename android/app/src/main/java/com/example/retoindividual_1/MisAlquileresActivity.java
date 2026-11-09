package com.example.retoindividual_1;

import android.content.DialogInterface;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.AuthFailureError;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.example.retoindividual_1.adaptadores.AlquilerActivoAdapter;
import com.example.retoindividual_1.adaptadores.AlquilerDevueltoAdapter;
import com.example.retoindividual_1.modelos.Alquiler;
import com.example.retoindividual_1.network.ApiClient;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

//MIS ALQUILERES (16 DEL MOCKUP): GET /alquileres Y PUT /alquileres/{id}/devolver
public class MisAlquileresActivity extends PaginaMenuActivity {

    private ProgressBar pbAlquileres;
    private LinearLayout llAviso;
    private TextView tvAvisoTitulo;
    private TextView tvAvisoTexto;
    private Button btnReintentar;
    private RecyclerView rvActivos;
    private TextView tvDevueltos;
    private RecyclerView rvDevueltos;

    @Override
    protected int getLayout() {
        return R.layout.activity_mis_alquileres;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        pbAlquileres = findViewById(R.id.pbAlquileres);
        llAviso = findViewById(R.id.llAlquileresAviso);
        tvAvisoTitulo = findViewById(R.id.tvAlquileresAvisoTitulo);
        tvAvisoTexto = findViewById(R.id.tvAlquileresAvisoTexto);
        btnReintentar = findViewById(R.id.btnAlquileresReintentar);
        rvActivos = findViewById(R.id.rvAlquileresActivos);
        tvDevueltos = findViewById(R.id.tvAlquileresDevueltos);
        rvDevueltos = findViewById(R.id.rvAlquileresDevueltos);

        rvActivos.setLayoutManager(new LinearLayoutManager(this));
        rvDevueltos.setLayoutManager(new LinearLayoutManager(this));

        btnReintentar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                cargarAlquileres();
            }
        });

        cargarAlquileres();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        ApiClient.getInstance(this).getCola().cancelAll(this);
    }

    //shortcut: SOLO LOS 50 ULTIMOS, SI ALGUIEN TIENE MAS HABRIA QUE PAGINAR
    private void cargarAlquileres() {
        llAviso.setVisibility(View.GONE);
        pbAlquileres.setVisibility(View.VISIBLE);

        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.GET, ApiClient.BASE_URL + "alquileres?limit=50", null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject respuesta) {
                        pbAlquileres.setVisibility(View.GONE);
                        JSONArray datos = respuesta.optJSONArray("datos");
                        List<Alquiler> alquileres = new ArrayList<>();
                        for (int i = 0; datos != null && i < datos.length(); i++) {
                            alquileres.add(new Alquiler(datos.optJSONObject(i)));
                        }
                        pintarAlquileres(alquileres);
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        pbAlquileres.setVisibility(View.GONE);
                        mostrarAviso(getString(R.string.alq_error_titulo), ApiClient.mensajeDeError(error), true);
                    }
                }) {
            //EL TOKEN DE LA SESION VA EN LAS CABECERAS
            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                return ApiClient.getInstance(MisAlquileresActivity.this).getCabeceras();
            }
        };
        peticion.setTag(this);
        ApiClient.getInstance(this).getCola().add(peticion);
    }

    //SEPARAMOS LOS QUE FALTAN POR DEVOLVER DE LOS JUEGOS YA DEVUELTOS
    private void pintarAlquileres(List<Alquiler> alquileres) {
        List<Alquiler> activos = new ArrayList<>();
        List<Alquiler.Linea> devueltos = new ArrayList<>();
        for (Alquiler alquiler : alquileres) {
            if (!alquiler.estaDevuelto() && !alquiler.getLineas().isEmpty()) {
                activos.add(alquiler);
            }
            for (Alquiler.Linea linea : alquiler.getLineas()) {
                if (linea.isDevuelto()) {
                    devueltos.add(linea);
                }
            }
        }

        if (activos.isEmpty() && devueltos.isEmpty()) {
            mostrarAviso(getString(R.string.alq_vacio_titulo), getString(R.string.alq_vacio_texto), false);
        }

        rvActivos.setAdapter(new AlquilerActivoAdapter(activos, new AlquilerActivoAdapter.AlDevolver() {
            @Override
            public void devolver(Alquiler alquiler) {
                preguntarDevolver(alquiler);
            }
        }));
        rvDevueltos.setAdapter(new AlquilerDevueltoAdapter(devueltos));
        rvActivos.scheduleLayoutAnimation();
        rvDevueltos.scheduleLayoutAnimation();
        tvDevueltos.setVisibility(devueltos.isEmpty() ? View.GONE : View.VISIBLE);
    }

    //SIN ALQUILERES O SIN CONEXION. SOLO SALE REINTENTAR SI HA FALLADO LA CONEXION
    private void mostrarAviso(String titulo, String texto, boolean reintentar) {
        tvAvisoTitulo.setText(titulo);
        tvAvisoTexto.setText(texto);
        btnReintentar.setVisibility(reintentar ? View.VISIBLE : View.GONE);
        llAviso.setVisibility(View.VISIBLE);
    }

    private void preguntarDevolver(Alquiler alquiler) {
        String juego = alquiler.getLineas().get(0).getVideojuego().getNombre();
        new MaterialAlertDialogBuilder(this)
                .setTitle(R.string.alq_devolver_titulo)
                .setMessage(getString(R.string.alq_devolver_texto, juego))
                .setPositiveButton(R.string.alq_devolver_si, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogo, int boton) {
                        devolver(alquiler);
                    }
                })
                .setNegativeButton(R.string.alq_cancelar, null)
                .show();
    }

    //SIN CUERPO LA API DEVUELVE TODOS LOS JUEGOS DE ESE ALQUILER
    private void devolver(Alquiler alquiler) {
        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.PUT,
                ApiClient.BASE_URL + "alquileres/" + alquiler.getId() + "/devolver", null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject respuesta) {
                        Toast.makeText(MisAlquileresActivity.this, R.string.alq_devuelto_ok, Toast.LENGTH_SHORT).show();
                        cargarAlquileres();
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        Toast.makeText(MisAlquileresActivity.this, ApiClient.mensajeDeError(error), Toast.LENGTH_LONG).show();
                    }
                }) {
            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                return ApiClient.getInstance(MisAlquileresActivity.this).getCabeceras();
            }
        };
        peticion.setTag(this);
        ApiClient.getInstance(this).getCola().add(peticion);
    }
}
