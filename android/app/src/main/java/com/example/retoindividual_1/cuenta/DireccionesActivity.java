package com.example.retoindividual_1.cuenta;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.principal.PaginaMenuActivity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.retoindividual_1.adaptadores.DomicilioAdapter;
import com.example.retoindividual_1.modelos.Domicilio;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.network.SessionManager;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

// DIRECCIONES (19 del mockup): GET /api/domicilios y DELETE /api/domicilios/{id}
public class DireccionesActivity extends PaginaMenuActivity {

    private static final String EXTRA_DESDE_CESTA = "desde_cesta";

    private Repositorio datos;
    private SessionManager sesion;
    private boolean desdeCesta;
    private final List<Domicilio> domicilios = new ArrayList<>();

    private RecyclerView rvDomicilios;
    private ProgressBar pbCargando;
    private LinearLayout llAviso;
    private TextView tvAvisoTitulo;
    private TextView tvAvisoTexto;
    private View btnReintentar;

    //DESDE LA CESTA: AL ELEGIR UNA DIRECCION SE VUELVE A LA CESTA
    public static Intent elegirDesdeCesta(Context context) {
        return new Intent(context, DireccionesActivity.class).putExtra(EXTRA_DESDE_CESTA, true);
    }

    @Override
    protected int getLayout() {
        return R.layout.activity_direcciones;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        sesion = new SessionManager(this);
        desdeCesta = getIntent().getBooleanExtra(EXTRA_DESDE_CESTA, false);

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

    private void cargar() {
        rvDomicilios.setVisibility(View.GONE);
        llAviso.setVisibility(View.GONE);
        pbCargando.setVisibility(View.VISIBLE);

        datos().domicilios(new Repositorio.Resultado<List<Domicilio>>() {
            @Override
            public void bien(List<Domicilio> lista) {
                pbCargando.setVisibility(View.GONE);
                domicilios.clear();
                domicilios.addAll(lista);
                mostrar();
                //AQUI Y NO EN mostrar(): AL ELEGIR UNA DIRECCION NO QUEREMOS QUE TODA LA LISTA SE ANIME OTRA VEZ
                rvDomicilios.scheduleLayoutAnimation();
            }

            @Override
            public void mal(String mensaje) {
                pbCargando.setVisibility(View.GONE);
                mostrarAviso(getString(R.string.datos_error_titulo), mensaje, true);
            }
        });
    }

    private void mostrar() {
        if (domicilios.isEmpty()) {
            mostrarAviso(getString(R.string.dir_vacia_titulo), getString(R.string.dir_vacia_texto), false);
            return;
        }
        rvDomicilios.setAdapter(new DomicilioAdapter(domicilios, sesion.getDomicilio(), new DomicilioAdapter.Acciones() {
            @Override
            public void elegir(Domicilio domicilio) {
                DireccionesActivity.this.elegir(domicilio);
            }

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

    //LA DIRECCION TOCADA PASA A SER LA DE LOS PEDIDOS
    private void elegir(Domicilio domicilio) {
        sesion.guardarDomicilio(domicilio.getId());
        Toast.makeText(this, R.string.dir_elegida, Toast.LENGTH_SHORT).show();
        if (desdeCesta) {
            finish();
        } else {
            mostrar();
        }
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
        datos().borrarDomicilio(domicilio.getId(), new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject respuesta) {
                //SI ERA LA ELEGIDA, YA NO HAY NINGUNA ELEGIDA
                if (domicilio.getId() == sesion.getDomicilio()) {
                    sesion.guardarDomicilio(-1);
                }
                Toast.makeText(DireccionesActivity.this, R.string.dir_borrada, Toast.LENGTH_SHORT).show();
                cargar();
            }

            @Override
            public void mal(String mensaje) {
                Toast.makeText(DireccionesActivity.this, mensaje, Toast.LENGTH_LONG).show();
            }
        });
    }

    //CAPA DE DATOS, SE CREA LA PRIMERA VEZ QUE SE USA
    private Repositorio datos() {
        if (datos == null) {
            datos = new Repositorio(this, this);
        }
        return datos;
    }
}