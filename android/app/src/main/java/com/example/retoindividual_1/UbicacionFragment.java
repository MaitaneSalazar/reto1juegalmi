package com.example.retoindividual_1;

import android.content.Intent;
import android.net.Uri;
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

import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.example.retoindividual_1.network.ApiClient;

import org.json.JSONObject;

//PESTAÑA UBICACION, LA DIRECCION, EL TELEFONO Y LAS COORDENADAS SALEN DE /tienda
public class UbicacionFragment extends Fragment {

    private ProgressBar pbUbicacion;
    private TextView tvError;
    private LinearLayout llDatos;
    private TextView tvLinea1;
    private TextView tvLinea2;
    private TextView tvTelefono;
    private LinearLayout llTelefono;
    private Button btnComoLlegar;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_ubicacion, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        pbUbicacion = view.findViewById(R.id.pbUbicacion);
        tvError = view.findViewById(R.id.tvUbicacionError);
        llDatos = view.findViewById(R.id.llUbicacionDatos);
        tvLinea1 = view.findViewById(R.id.tvUbicacionLinea1);
        tvLinea2 = view.findViewById(R.id.tvUbicacionLinea2);
        tvTelefono = view.findViewById(R.id.tvUbicacionTelefono);
        llTelefono = view.findViewById(R.id.llUbicacionTelefono);
        btnComoLlegar = view.findViewById(R.id.btnComoLlegar);

        cargarTienda();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        ApiClient.getInstance(requireContext()).getCola().cancelAll(this);
    }

    private void cargarTienda() {
        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.GET, ApiClient.BASE_URL + "tienda", null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject tienda) {
                        pbUbicacion.setVisibility(View.GONE);
                        pintarTienda(tienda);
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        pbUbicacion.setVisibility(View.GONE);
                        tvError.setVisibility(View.VISIBLE);
                    }
                });
        peticion.setTag(this);
        ApiClient.getInstance(requireContext()).getCola().add(peticion);
    }

    private void pintarTienda(JSONObject tienda) {
        String telefono = tienda.optString("telefono");
        double latitud = tienda.optDouble("latitud");
        double longitud = tienda.optDouble("longitud");

        tvLinea1.setText(tienda.optString("direccion_linea1"));
        tvLinea2.setText(tienda.optString("direccion_linea2"));
        tvTelefono.setText(telefono);
        llDatos.setVisibility(View.VISIBLE);

        //ACTION_DIAL SOLO ABRE EL MARCADOR CON EL NUMERO, NO NECESITA PERMISO DE LLAMADAS
        llTelefono.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivity(new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + telefono)));
            }
        });

        //ABRE LA RUTA HASTA LA TIENDA EN GOOGLE MAPS, O EN EL NAVEGADOR SI NO ESTA INSTALADO
        btnComoLlegar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivity(new Intent(Intent.ACTION_VIEW,
                        Uri.parse("https://www.google.com/maps/dir/?api=1&destination=" + latitud + "," + longitud)));
            }
        });
    }
}
