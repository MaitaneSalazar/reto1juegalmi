package com.example.retoindividual_1;

import android.os.Bundle;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.DefaultRetryPolicy;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.toolbox.HttpHeaderParser;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.StringRequest;
import com.example.retoindividual_1.adaptadores.DomicilioAdapter;
import com.example.retoindividual_1.modelos.Domicilio;
import com.example.retoindividual_1.network.ApiClient;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

// DIRECCIONES (19 del mockup): GET /api/domicilios y DELETE /api/domicilios/{id}
public class DireccionesActivity extends PaginaMenuActivity {

    private RecyclerView rvDomicilios;
    private ProgressBar pbCargando;
    private LinearLayout llAviso;
    private TextView tvAvisoTitulo;
    private TextView tvAvisoTexto;
    private View btnReintentar;

    @Override
    protected int getLayout() {
        return R.layout.activity_direcciones;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        rvDomicilios = findViewById(R.id.rvDomicilios);
        pbCargando = findViewById(R.id.pbDomicilios);
        llAviso = findViewById(R.id.llDomiciliosAviso);
        tvAvisoTitulo = findViewById(R.id.tvDomiciliosAvisoTitulo);
        tvAvisoTexto = findViewById(R.id.tvDomiciliosAvisoTexto);
        btnReintentar = findViewById(R.id.btnDomiciliosReintentar);

        rvDomicilios.setLayoutManager(new LinearLayoutManager(this));
        btnReintentar.setOnClickListener(v -> cargar());
        findViewById(R.id.btnAnadirDireccion).setOnClickListener(v ->
                startActivity(NuevaDireccionActivity.crearIntent(this, null)));
    }

    // En onResume: al volver de añadir o editar una dirección, la lista se actualiza
    @Override
    protected void onResume() {
        super.onResume();
        cargar();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        ApiClient.getInstance(this).getCola().cancelAll(this);
    }

    private void cargar() {
        rvDomicilios.setVisibility(View.GONE);
        llAviso.setVisibility(View.GONE);
        pbCargando.setVisibility(View.VISIBLE);

        ApiClient api = ApiClient.getInstance(this);
        StringRequest peticion = new StringRequest(Request.Method.GET, ApiClient.BASE_URL + "domicilios",
                respuesta -> {
                    pbCargando.setVisibility(View.GONE);
                    try {
                        mostrar(leer(respuesta));
                    } catch (JSONException e) {
                        mostrarAviso(getString(R.string.datos_error_titulo), getString(R.string.dir_error_lectura), true);
                    }
                },
                error -> {
                    pbCargando.setVisibility(View.GONE);
                    mostrarAviso(getString(R.string.datos_error_titulo), ApiClient.mensajeDeError(error), true);
                }) {
            @Override
            public Map<String, String> getHeaders() {
                return api.getCabeceras();
            }

            // StringRequest usa ISO-8859-1 si la API no indica el juego de caracteres, y saldría "VÃ­a"
            @Override
            protected Response<String> parseNetworkResponse(NetworkResponse response) {
                return Response.success(new String(response.data, StandardCharsets.UTF_8),
                        HttpHeaderParser.parseCacheHeaders(response));
            }
        };
        peticion.setTag(this);
        api.getCola().add(peticion);
    }

    // Admite la respuesta como lista [...] o paginada {"datos": [...]}
    private List<Domicilio> leer(String cuerpo) throws JSONException {
        Object json = new JSONTokener(cuerpo).nextValue();
        JSONArray lista = json instanceof JSONArray ? (JSONArray) json : ((JSONObject) json).optJSONArray("datos");
        List<Domicilio> domicilios = new ArrayList<>();
        for (int i = 0; lista != null && i < lista.length(); i++) {
            domicilios.add(new Domicilio(lista.getJSONObject(i)));
        }
        return domicilios;
    }

    private void mostrar(List<Domicilio> domicilios) {
        if (domicilios.isEmpty()) {
            mostrarAviso(getString(R.string.dir_vacia_titulo), getString(R.string.dir_vacia_texto), false);
            return;
        }
        rvDomicilios.setAdapter(new DomicilioAdapter(domicilios, new DomicilioAdapter.Acciones() {
            @Override
            public void editar(Domicilio domicilio) {
                startActivity(NuevaDireccionActivity.crearIntent(DireccionesActivity.this, domicilio));
            }

            @Override
            public void borrar(Domicilio domicilio) {
                preguntarBorrar(domicilio);
            }
        }));
        rvDomicilios.setVisibility(View.VISIBLE);
    }

    private void mostrarAviso(String titulo, String texto, boolean conReintentar) {
        tvAvisoTitulo.setText(titulo);
        tvAvisoTexto.setText(texto);
        btnReintentar.setVisibility(conReintentar ? View.VISIBLE : View.GONE);
        llAviso.setVisibility(View.VISIBLE);
    }

    private void preguntarBorrar(Domicilio domicilio) {
        new MaterialAlertDialogBuilder(this)
                .setTitle(R.string.dir_borrar_titulo)
                .setMessage(R.string.dir_borrar_texto)
                .setPositiveButton(R.string.dir_borrar_si, (dialogo, boton) -> borrar(domicilio))
                .setNegativeButton(R.string.dir_cancelar, null)
                .show();
    }

    private void borrar(Domicilio domicilio) {
        ApiClient api = ApiClient.getInstance(this);
        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.DELETE,
                ApiClient.BASE_URL + "domicilios/" + domicilio.getId(), null,
                respuesta -> {
                    Toast.makeText(this, R.string.dir_borrada, Toast.LENGTH_SHORT).show();
                    cargar();
                },
                error -> Toast.makeText(this, ApiClient.mensajeDeError(error), Toast.LENGTH_LONG).show()) {
            @Override
            public Map<String, String> getHeaders() {
                return api.getCabeceras();
            }
        };
        peticion.setRetryPolicy(new DefaultRetryPolicy(15000, 0, DefaultRetryPolicy.DEFAULT_BACKOFF_MULT));
        peticion.setTag(this);
        api.getCola().add(peticion);
    }
}