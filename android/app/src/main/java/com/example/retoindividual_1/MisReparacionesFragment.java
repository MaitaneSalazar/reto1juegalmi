package com.example.retoindividual_1;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.Request;
import com.android.volley.toolbox.JsonObjectRequest;
import com.example.retoindividual_1.adaptadores.ReparacionAdapter;
import com.example.retoindividual_1.modelos.Reparacion;
import com.example.retoindividual_1.network.ApiClient;

import org.json.JSONArray;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

// MIS REPARACIONES (14 del mockup): GET /api/reparaciones, separadas en en curso, entregadas y canceladas
public class MisReparacionesFragment extends Fragment {

    private RecyclerView rvReparaciones;
    private ProgressBar pbCargando;
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

        rvReparaciones = view.findViewById(R.id.rvReparaciones);
        pbCargando = view.findViewById(R.id.pbReparaciones);
        llAviso = view.findViewById(R.id.llReparacionesAviso);
        tvAvisoTitulo = view.findViewById(R.id.tvReparacionesAvisoTitulo);
        tvAvisoTexto = view.findViewById(R.id.tvReparacionesAvisoTexto);
        btnAviso = view.findViewById(R.id.btnReparacionesAviso);

        rvReparaciones.setLayoutManager(new LinearLayoutManager(requireContext()));
        cargarReparaciones();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        // Si se sale antes de que responda la API, se cancela la petición
        ApiClient.getInstance(requireContext()).getCola().cancelAll(this);
    }

    private void cargarReparaciones() {
        llAviso.setVisibility(View.GONE);
        rvReparaciones.setVisibility(View.GONE);
        pbCargando.setVisibility(View.VISIBLE);

        ApiClient api = ApiClient.getInstance(requireContext());
        JsonObjectRequest peticion = new JsonObjectRequest(
                Request.Method.GET, ApiClient.BASE_URL + "reparaciones?limit=50", null,
                respuesta -> {
                    pbCargando.setVisibility(View.GONE);
                    JSONArray datos = respuesta.optJSONArray("datos");
                    List<Reparacion> reparaciones = new ArrayList<>();
                    for (int i = 0; datos != null && i < datos.length(); i++) {
                        reparaciones.add(new Reparacion(datos.optJSONObject(i)));
                    }
                    mostrarReparaciones(reparaciones);
                },
                error -> {
                    pbCargando.setVisibility(View.GONE);
                    mostrarAviso(getString(R.string.mis_rep_error_titulo), ApiClient.mensajeDeError(error),
                            getString(R.string.mis_rep_reintentar), v -> cargarReparaciones());
                }) {
            @Override
            public Map<String, String> getHeaders() {
                return api.getCabeceras();
            }
        };
        peticion.setTag(this);
        api.getCola().add(peticion);
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