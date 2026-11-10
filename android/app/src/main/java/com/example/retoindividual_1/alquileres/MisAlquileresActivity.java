package com.example.retoindividual_1.alquileres;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.principal.MainActivity;
import com.example.retoindividual_1.principal.PaginaMenuActivity;
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

import com.example.retoindividual_1.adaptadores.AlquilerActivoAdapter;
import com.example.retoindividual_1.adaptadores.AlquilerDevueltoAdapter;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.modelos.Alquiler;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

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

    //LA CREAMOS AL ENTRAR, ANTES DE PEDIR NADA
    private Repositorio datos;

    private Repositorio datos() {
        if (datos == null) {
            datos = new Repositorio(this, this);
        }
        return datos;
    }

    //shortcut: SOLO LOS 50 ULTIMOS, SI ALGUIEN TIENE MAS HABRIA QUE PAGINAR
    private void cargarAlquileres() {
        llAviso.setVisibility(View.GONE);
        pbAlquileres.setVisibility(View.VISIBLE);

        datos().alquileres(50, new Repositorio.Resultado<List<Alquiler>>() {
            @Override
            public void bien(List<Alquiler> alquileres) {
                pbAlquileres.setVisibility(View.GONE);
                pintarAlquileres(alquileres);
            }

            @Override
            public void mal(String mensaje) {
                pbAlquileres.setVisibility(View.GONE);
                mostrarAviso(getString(R.string.alq_error_titulo), mensaje, true);
            }
        });
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

    //SIN ALQUILERES: EL BOTON LLEVA A LA TIENDA. CON ERROR: EL BOTON REINTENTA
    private void mostrarAviso(String titulo, String texto, boolean reintentar) {
        tvAvisoTitulo.setText(titulo);
        tvAvisoTexto.setText(texto);
        btnReintentar.setText(reintentar ? R.string.alq_reintentar : R.string.ir_a_la_tienda);
        btnReintentar.setOnClickListener(v -> {
            if (reintentar) {
                cargarAlquileres();
            } else {
                startActivity(MainActivity.irALaTienda(this));
            }
        });
        btnReintentar.setVisibility(View.VISIBLE);
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
        datos().devolver(alquiler.getId(), new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject respuesta) {
                Toast.makeText(MisAlquileresActivity.this, R.string.alq_devuelto_ok, Toast.LENGTH_SHORT).show();
                cargarAlquileres();
            }

            @Override
            public void mal(String mensaje) {
                Toast.makeText(MisAlquileresActivity.this, mensaje, Toast.LENGTH_LONG).show();
            }
        });
    }
}
