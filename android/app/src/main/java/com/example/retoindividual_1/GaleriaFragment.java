package com.example.retoindividual_1;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonArrayRequest;
import com.example.retoindividual_1.adaptadores.FotoTiendaAdapter;
import com.example.retoindividual_1.modelos.FotoTienda;
import com.example.retoindividual_1.network.ApiClient;

import org.json.JSONArray;

import java.util.ArrayList;
import java.util.List;

//PESTAÑA GALERIA, LAS FOTOS SALEN DE /tienda/fotos
public class GaleriaFragment extends Fragment {

    private RecyclerView rvGaleria;
    private ProgressBar pbGaleria;
    private TextView tvAviso;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_galeria, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        rvGaleria = view.findViewById(R.id.rvGaleria);
        pbGaleria = view.findViewById(R.id.pbGaleria);
        tvAviso = view.findViewById(R.id.tvGaleriaAviso);

        //2 COLUMNAS, LAS FOTOS ANCHAS OCUPAN LAS DOS
        GridLayoutManager columnas = new GridLayoutManager(getContext(), 2);
        columnas.setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
            @Override
            public int getSpanSize(int position) {
                return FotoTiendaAdapter.esAncha(position) ? 2 : 1;
            }
        });
        rvGaleria.setLayoutManager(columnas);

        cargarFotos();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        ApiClient.getInstance(requireContext()).getCola().cancelAll(this);
    }

    private void cargarFotos() {
        JsonArrayRequest peticion = new JsonArrayRequest(Request.Method.GET, ApiClient.BASE_URL + "tienda/fotos", null,
                new Response.Listener<JSONArray>() {
                    @Override
                    public void onResponse(JSONArray respuesta) {
                        pbGaleria.setVisibility(View.GONE);
                        List<FotoTienda> fotos = new ArrayList<>();
                        for (int i = 0; i < respuesta.length(); i++) {
                            fotos.add(new FotoTienda(respuesta.optJSONObject(i)));
                        }

                        if (fotos.isEmpty()) {
                            tvAviso.setText(R.string.nosotros_sin_fotos);
                            tvAviso.setVisibility(View.VISIBLE);
                        } else {
                            rvGaleria.setAdapter(new FotoTiendaAdapter(fotos));
                        }
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        pbGaleria.setVisibility(View.GONE);
                        tvAviso.setText(ApiClient.mensajeDeError(error));
                        tvAviso.setVisibility(View.VISIBLE);
                    }
                });
        peticion.setTag(this);
        ApiClient.getInstance(requireContext()).getCola().add(peticion);
    }
}
