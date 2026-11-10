package com.example.retoindividual_1.taller;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.principal.MainActivity;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import com.airbnb.lottie.LottieAnimationView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.retoindividual_1.adaptadores.ReparacionAdapter;
import com.example.retoindividual_1.modelos.Reparacion;
import com.example.retoindividual_1.datos.Repositorio;


import java.util.ArrayList;
import java.util.List;

// MIS REPARACIONES (14 del mockup): GET /api/reparaciones, separadas en en curso, entregadas y canceladas
public class MisReparacionesFragment extends Fragment {

    private Repositorio datos;

    private RecyclerView rvReparaciones;
    private LottieAnimationView pbCargando;
    private LinearLayout llAviso;
    private TextView tvAvisoTitulo;
    private TextView tvAvisoTexto;
    private Button btnAviso;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_mis_reparaciones, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        datos = new Repositorio(requireContext(), getViewLifecycleOwner());

        rvReparaciones = view.findViewById(R.id.rvReparaciones);
        pbCargando = view.findViewById(R.id.pbReparaciones);
        llAviso = view.findViewById(R.id.llReparacionesAviso);
        tvAvisoTitulo = view.findViewById(R.id.tvReparacionesAvisoTitulo);
        tvAvisoTexto = view.findViewById(R.id.tvReparacionesAvisoTexto);
        btnAviso = view.findViewById(R.id.btnReparacionesAviso);

        rvReparaciones.setLayoutManager(new LinearLayoutManager(requireContext()));
        cargarReparaciones();
    }

    private void cargarReparaciones() {
        llAviso.setVisibility(View.GONE);
        rvReparaciones.setVisibility(View.GONE);
        pbCargando.setVisibility(View.VISIBLE);

        datos.reparaciones(50, new Repositorio.Resultado<List<Reparacion>>() {
            @Override
            public void bien(List<Reparacion> reparaciones) {
                pbCargando.setVisibility(View.GONE);
                mostrarReparaciones(reparaciones);
            }

            @Override
            public void mal(String mensaje) {
                pbCargando.setVisibility(View.GONE);
                mostrarAviso(getString(R.string.mis_rep_error_titulo), mensaje,
                        getString(R.string.mis_rep_reintentar), v -> cargarReparaciones());
            }
        });
    }

    private void mostrarReparaciones(List<Reparacion> reparaciones) {
        if (reparaciones.isEmpty()) {
            mostrarAviso(getString(R.string.mis_rep_vacia_titulo), getString(R.string.mis_rep_vacia_texto),
                    getString(R.string.mis_rep_pedir), v -> irANuevaReparacion());
            return;
        }

        List<Reparacion> enCurso = new ArrayList<>();
        List<Reparacion> entregadas = new ArrayList<>();
        List<Reparacion> canceladas = new ArrayList<>();
        for (Reparacion reparacion : reparaciones) {
            if (reparacion.estaEnCurso()) {
                enCurso.add(reparacion);
            } else if (reparacion.estaEntregada()) {
                entregadas.add(reparacion);
            } else {
                canceladas.add(reparacion);
            }
        }

        List<Object> filas = new ArrayList<>();
        anadirSeccion(filas, R.string.mis_rep_en_curso, enCurso);
        anadirSeccion(filas, R.string.mis_rep_entregadas, entregadas);
        anadirSeccion(filas, R.string.mis_rep_canceladas, canceladas);

        rvReparaciones.setAdapter(new ReparacionAdapter(filas,
                reparacion -> ((MainActivity) requireActivity()).abrirSeguimiento(reparacion.getId())));
        //LA ANIMACION SOLO SALE SOLA LA PRIMERA VEZ: AL RECARGAR HAY QUE PEDIRLA
        rvReparaciones.scheduleLayoutAnimation();
        rvReparaciones.setVisibility(View.VISIBLE);
    }

    // Las secciones vacías no se enseñan. La primera que aparece lleva el título grande
    private void anadirSeccion(List<Object> filas, int titulo, List<Reparacion> reparaciones) {
        if (reparaciones.isEmpty()) {
            return;
        }
        filas.add(new ReparacionAdapter.Encabezado(getString(titulo), filas.isEmpty()));
        filas.addAll(reparaciones);
    }

    private void irANuevaReparacion() {
        if (getParentFragment() instanceof TallerFragment) {
            ((TallerFragment) getParentFragment()).mostrar(false);
        }
    }

    private void mostrarAviso(String titulo, String texto, String boton, View.OnClickListener alPulsar) {
        tvAvisoTitulo.setText(titulo);
        tvAvisoTexto.setText(texto);
        btnAviso.setText(boton);
        btnAviso.setOnClickListener(alPulsar);
        llAviso.setVisibility(View.VISIBLE);
    }
}